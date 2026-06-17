LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Full_Encryption_MAC_SC IS
    PORT(
        clk   : IN STD_LOGIC;
        rst   : IN STD_LOGIC;

        start : IN STD_LOGIC;

        -----------------------------
        -- MODES
        -- "0" -> FULL ENCRYPTION
        -- "1" -> MAC GENERATION
        -----------------------------
        mode : IN STD_LOGIC;
        
        integrity : IN STD_LOGIC;
        is_decryption : IN STD_LOGIC;

        plaintext : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        text_len  : IN INTEGER RANGE 1 TO 128;
        key       : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        R_input   : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        iv        : IN STD_LOGIC_VECTOR( 63 DOWNTO 0);

        result_output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        R_output      : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        
        done : OUT STD_LOGIC;
        busy : OUT STD_LOGIC
    );
END ENTITY Full_Encryption_MAC_SC;

ARCHITECTURE Behavioral OF Full_Encryption_MAC_SC IS

    --------------------------------------------
    -- FSM STATES
    --------------------------------------------
    TYPE fsm_state_t IS(
        IDLE,

        ---------------------------------------
        -- ENCRYPTION
        ---------------------------------------
        LOAD_WORD,
        PREPARE_ENC,

        START_ENC,
        WAIT_ENC,

        STORE_WORD,
        NEXT_WORD,

        --------------------------------------
        -- PARTIAL WORD STREAM MODE
        --------------------------------------
        STREAM_E0,
        STREAM_WAIT_E0,

        STREAM_INTEGRITY,
        STREAM_WAIT_INTEGRITY,

        --------------------------------------
        -- MAC FINALIZATION
        --------------------------------------
        MAC_FINALIZE_1,
        PREPARE_MAC_1,
        MAC_WAIT_1,

        MAC_FINALIZE_2,
        PREPARE_MAC_2,
        MAC_WAIT_2,

        MAC_FINALIZE_3,
        PREPARE_MAC_3,
        MAC_WAIT_3,

        --------------------------------------
        -- MAC TAG GENERATION
        --------------------------------------
        MAC_T1,
        MAC_PREPARE_T1,
        MAC_WAIT_T1,

        MAC_TN,
        MAC_PREPARE_TN,
        MAC_WAIT_TN,


        -------------------------------------
        -- FINISHED
        -------------------------------------
        FINISHED
    );

    SIGNAL current_state : fsm_state_t := IDLE;

    ATTRIBUTE fsm_encoding : string;
    ATTRIBUTE fsm_encoding of current_state : SIGNAL IS "one_hot";

    -----------------------------------------
    -- SHARED ENCRYPTION CORE
    -----------------------------------------
    SIGNAL enc_start : STD_LOGIC := '0';

    SIGNAL enc_input  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL enc_output : STD_LOGIC_VECTOR(15 DOWNTO 0);

   -- SIGNAL enc_R_in   : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL enc_R_out  : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL enc_done : STD_LOGIC;
    SIGNAL enc_busy : STD_LOGIC;

    --------------------------------------------
    -- INTERNAL STATE
    --------------------------------------------
    SIGNAL internal_R : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL output_reg : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');

    ---------------------------------------------
    -- WORD PROCESSING
    ---------------------------------------------
    SIGNAL word_counter : UNSIGNED(2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL full_words_reg   : INTEGER RANGE 0 TO 8;
    SIGNAL last_word_bits_reg : INTEGER RANGE 0 TO 15;
    SIGNAL effective_words_reg : INTEGER RANGE 0 TO 8;

    TYPE word_array_t IS ARRAY(0 TO 7) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL words : word_array_t;
    -- Register current word -> performance ↑
    SIGNAL current_word_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);
    
    ---------------------------------------------
    -- STREAM CIPHER
    ---------------------------------------------
    SIGNAL stream_mask : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL stream_xor  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL partial_word : STD_LOGIC_VECTOR(15 DOWNTO 0);

    --------------------------------------------
    -- STATUS
    --------------------------------------------
    SIGNAL done_reg : STD_LOGIC := '0';
    SIGNAL busy_reg : STD_LOGIC := '0';

    -- REG to hold results for first 3 step of MAC -> performance ↑ 
    SIGNAL mac_input_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);

    ---------------------------------------------------------------
    -- SIGNALS to reduce huge logic of CE of 128 FF to output_reg
    ---------------------------------------------------------------
    SIGNAL output_word_reg  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAl output_index_reg : UNSIGNED(2 DOWNTO 0);
    SIGNAL output_write_reg : STD_LOGIC;

BEGIN

    enc_core : ENTITY work.Encryption_Core
        PORT MAP(
            clk => clk,
            rst => rst,

            start => enc_start,

            pt_input => enc_input,

            R_input => internal_R,--enc_R_in,
            key     => key,

            ct_output => enc_output,
            R_output  => enc_R_out,
            
            done => enc_done,
            busy => enc_busy
        );

    --------------------------------------------
    -- STREAM MASK
    --------------------------------------------
    PROCESS(last_word_bits_reg)
    BEGIN
        
        stream_mask <= (OTHERS => '0');

        FOR i IN 0 TO 14 LOOP
            IF i < last_word_bits_reg THEN
                stream_mask(i) <= '1';
            END IF;
        END LOOP;
    
    END PROCESS;

    --------------------------------------------
    -- STREAM CIPHER XOR
    --------------------------------------------
    PROCESS(plaintext, last_word_bits_reg)
    BEGIN
        partial_word <= (OTHERS => '0');

        FOR i IN 0 TO 14 LOOP
            IF i < last_word_bits_reg THEN
                partial_word(i) <= plaintext(i);

            END IF;
        END LOOP;
    END PROCESS;
    
    stream_xor <= (partial_word XOR enc_output) 
                                AND stream_mask;

    --------------------------------------------
    -- MAIN FSM
    --------------------------------------------
    PROCESS(clk)
        VARIABLE temp_mac_input  : UNSIGNED(15 DOWNTO 0);

        VARIABLE target_word     : INTEGER RANGE 0 TO 8;

    BEGIN
        
        IF RISING_EDGE(clk) THEN
            ------------------------------------
            -- RESET
            ------------------------------------
            IF rst = '1' THEN
                current_state <= IDLE;
                
                enc_start <= '0';
                done_reg  <= '0';
                busy_reg  <= '0';
                output_write_reg <= '0';

                word_counter <= (OTHERS => '0');

            ELSE
                --------------------------------
                -- DEFAULTS
                --------------------------------
                enc_start <= '0';
                done_reg  <= '0';
                output_write_reg <= '0';

                --------------------------------
                -- FSM
                --------------------------------
                CASE current_state IS

                    --------------------------------------
                    -- IDLE
                    --------------------------------------
                    WHEN IDLE =>
                        busy_reg <= '0';
                        
                        IF start = '1' THEN
                            full_words_reg <= text_len / 16;
                            last_word_bits_reg <= text_len MOD 16;

                            IF(text_len MOD 16) = 0 THEN
                                effective_words_reg <= text_len / 16;

                            ELSE
                                effective_words_reg <= (text_len / 16) + 1;
                            
                            END IF;

                            words(0) <= plaintext(127 DOWNTO 112);
                            words(1) <= plaintext(111 DOWNTO  96);
                            words(2) <= plaintext( 95 DOWNTO  80);
                            words(3) <= plaintext( 79 DOWNTO  64);
                            words(4) <= plaintext( 63 DOWNTO  48);
                            words(5) <= plaintext( 47 DOWNTO  32);
                            words(6) <= plaintext( 31 DOWNTO  16);
                            words(7) <= plaintext( 15 DOWNTO   0);


                            busy_reg <= '1';

                            internal_R <= R_input;
                            output_reg <=(OTHERS => '0');

                            word_counter <= (OTHERS => '0');
                        
                            CASE mode IS

                                ------------------------------------------
                                -- ENCRYPTION
                                ------------------------------------------
                                WHEN '0' =>
                                    current_state <= LOAD_WORD;

                                ------------------------------------------
                                -- MAC GENERATION
                                ------------------------------------------
                                WHEN '1' =>
                                    current_state <= MAC_FINALIZE_1;

                                WHEN OTHERS =>
                                    current_state <= IDLE;

                            END CASE;
                        END IF;
                    
                    --------------------------------------
                    -- LOAD WORD
                    --------------------------------------
                    WHEN LOAD_WORD =>
                        ------------------------------------
                        -- PARTIAL LAST WORD
                        ------------------------------------
                        target_word := 8 - effective_words_reg + TO_INTEGER(word_counter);
                        IF (TO_INTEGER(word_counter) = full_words_reg) AND
                           (last_word_bits_reg /= 0) THEN
                           
                           current_state <= STREAM_E0;

                        ELSE
                            current_word_reg <= words(target_word);
                            --enc_R_in  <= internal_R;

                            current_state <= PREPARE_ENC;

                        END IF;

                    WHEN PREPARE_ENC =>
                        enc_input <= current_word_reg;

                        current_state <= START_ENC;

                    ----------------------------------------------
                    -- START ENCRYPTION
                    ----------------------------------------------
                    WHEN START_ENC =>
                        enc_start <= '1';

                        current_state <= WAIT_ENC;

                    ----------------------------------------------
                    -- WAIT ENCRYPTION
                    ----------------------------------------------
                    WHEN WAIT_ENC =>
                        IF enc_done = '1' THEN
                            internal_R <= enc_R_out;

                            current_state <= STORE_WORD;

                        END IF;

                    --------------------------------------------
                    -- STORE WORD
                    --------------------------------------------
                    WHEN STORE_WORD =>
                        target_word := 8 - effective_words_reg + TO_INTEGER(word_counter);

                        output_word_reg <= enc_output;
                        output_index_reg <= TO_UNSIGNED(target_word,3);
                        output_write_reg <= '1';

                        current_state <= NEXT_WORD;

                    ------------------------------------------------------
                    -- NEXT WORD
                    ------------------------------------------------------
                    WHEN NEXT_WORD =>
                        IF last_word_bits_reg = 0 THEN
                            IF word_counter = TO_UNSIGNED(full_words_reg-1,3) THEN
                                current_state <= FINISHED;

                            ELSE
                                word_counter <= word_counter + 1;

                                current_state <= LOAD_WORD;
                            
                            END IF;
                        ELSE

                            IF word_counter = TO_UNSIGNED(full_words_reg,3) THEN
                                current_state <= FINISHED;

                            ELSE
                                word_counter <= word_counter + 1;
                                
                                current_state <= LOAD_WORD;

                            END IF;
                        END IF;

                    -------------------------------------------------
                    -- STREAM CIPHER
                    -------------------------------------------------
                    WHEN STREAM_E0 =>
                        enc_input <= (OTHERS => '0');
                       -- enc_R_in <= internal_R;

                        enc_start <= '1';
                        current_state <= STREAM_WAIT_E0;

                    WHEN STREAM_WAIT_E0 =>
                        IF enc_done = '1' THEN
                            internal_R <= enc_R_out;

                            target_word := 8 - effective_words_reg + TO_INTEGER(word_counter);

                            output_word_reg <= stream_xor;
                            output_index_reg <= TO_UNSIGNED(target_word,3);
                            output_write_reg <= '1';

                            IF integrity = '1' THEN
                                current_state <= STREAM_INTEGRITY;

                            ELSE
                                current_state <= FINISHED;
                        
                            END IF;
                        END IF;

                    -----------------------------------------
                    -- PARTIAL_WAIT_INTEGRITY
                    -----------------------------------------
                    WHEN STREAM_INTEGRITY =>
                        IF is_decryption = '1' THEN
                            enc_input <= stream_xor;
                        
                        ELSE
                            enc_input <= partial_word;

                        END IF;

                        --enc_R_in  <= internal_R;
                        
                        enc_start <= '1';
                        current_state <= STREAM_WAIT_INTEGRITY;

                    WHEN STREAM_WAIT_INTEGRITY =>
                        IF enc_done = '1' THEN
                            internal_R <= enc_R_out;
                            current_state <= FINISHED;

                        END IF;

                    ------------------------------------------
                    -- MAC FINALIZATION 1
                    ------------------------------------------
                    WHEN MAC_FINALIZE_1 =>
                        temp_mac_input := 
                            UNSIGNED(iv(63 DOWNTO 48)) +
                            UNSIGNED(internal_R(127 DOWNTO 112)) +
                            UNSIGNED(internal_R( 95 DOWNTO  80)) +
                            TO_UNSIGNED(effective_words_reg, 16);

                        mac_input_reg <= STD_LOGIC_VECTOR(temp_mac_input);

                        current_state <= PREPARE_MAC_1;

                    WHEN PREPARE_MAC_1 =>
                        enc_input <= mac_input_reg;

                       -- enc_R_in <= internal_R;

                        enc_start <= '1';

                        current_state <= MAC_WAIT_1;

                    WHEN MAC_WAIT_1 =>
                        IF enc_done = '1' THEN
                            internal_R <= enc_R_out;

                            current_state <= MAC_FINALIZE_2;

                        END IF;

                    --------------------------------------------
                    -- MAC FINALIZATION 2
                    --------------------------------------------
                    WHEN MAC_FINALIZE_2 =>
                        temp_mac_input := 
                            UNSIGNED(iv(47 DOWNTO 32)) +
                            UNSIGNED(internal_R(127 DOWNTO 112)) +
                            UNSIGNED(internal_R( 95 DOWNTO  80));

                        mac_input_reg <= STD_LOGIC_VECTOR(temp_mac_input);

                        current_state <= PREPARE_MAC_2;

                    WHEN PREPARE_MAC_2 =>
                        enc_input <= mac_input_reg;

                       -- enc_R_in <= internal_R;

                        enc_start <= '1';

                        current_state <= MAC_WAIT_2;

                    WHEN MAC_WAIT_2 =>
                        IF enc_done = '1' THEN
                            internal_R <= enc_R_out;

                            current_state <= MAC_FINALIZE_3;

                        END IF;

                    --------------------------------------------
                    -- MAC FINALIZATION 3
                    --------------------------------------------
                    WHEN MAC_FINALIZE_3 =>
                        temp_mac_input := 
                            UNSIGNED(iv(31 DOWNTO 16)) +
                            UNSIGNED(internal_R(127 DOWNTO 112)) +
                            UNSIGNED(internal_R( 95 DOWNTO  80));

                        mac_input_reg <= STD_LOGIC_VECTOR(temp_mac_input);

                        current_state <= PREPARE_MAC_3;

                    WHEN PREPARE_MAC_3 =>
                        enc_input <= mac_input_reg;

                       -- enc_R_in <= internal_R;

                        enc_start <= '1';

                        current_state <= MAC_WAIT_3;

                    WHEN MAC_WAIT_3 =>
                        IF enc_done = '1' THEN
                            internal_R <= enc_R_out;

                            current_state <= MAC_T1;

                        END IF;

                    --------------------------------------------
                    -- MAC T1
                    --------------------------------------------
                    WHEN MAC_T1 =>
                        temp_mac_input := 
                            UNSIGNED(iv(15 DOWNTO 0)) +
                            UNSIGNED(internal_R(127 DOWNTO 112)) +
                            UNSIGNED(internal_R( 95 DOWNTO  80));

                        mac_input_reg <= STD_LOGIC_VECTOR(temp_mac_input);

                        current_state <= MAC_PREPARE_T1;

                    WHEN MAC_PREPARE_T1 =>
                        enc_input <= mac_input_reg;

                       -- enc_R_in <= internal_R;

                        enc_start <= '1';

                        current_state <= MAC_WAIT_T1;

                    WHEN MAC_WAIT_T1 =>
                        IF enc_done = '1' THEN
                            internal_R <= enc_R_out;

                            target_word := 8 - effective_words_reg;

                            output_word_reg <= enc_output;
                            output_index_reg <= TO_UNSIGNED(target_word,3);
                            output_write_reg <= '1';

                            word_counter <= TO_UNSIGNED(0,3);
                            
                            IF effective_words_reg = 1 THEN
                                current_state <= FINISHED;

                            ELSE

                                current_state <= MAC_TN;
                                word_counter <= TO_UNSIGNED(1,3);

                            END IF;
                        END IF;

                    ----------------------------------------------
                    -- MAC T2...TN
                    ----------------------------------------------
                    WHEN MAC_TN =>
                        mac_input_reg <= STD_LOGIC_VECTOR(
                            UNSIGNED(internal_R(127 DOWNTO 112)) +
                            UNSIGNED(internal_R( 95 DOWNTO  80))
                        );

                        current_state <= MAC_PREPARE_TN;

                    WHEN MAC_PREPARE_TN =>
                        enc_input <= mac_input_reg;

                       -- enc_R_in <= internal_R;

                        enc_start <= '1';

                        current_state <= MAC_WAIT_TN;

                    WHEN MAC_WAIT_TN =>
                        IF enc_done = '1' THEN
                            internal_R <= enc_R_out;

                            target_word := 8 - full_words_reg + TO_INTEGER(word_counter);

                            output_word_reg <= enc_output;
                            output_index_reg <= TO_UNSIGNED(target_word,3);
                            output_write_reg <= '1';

                            IF word_counter = TO_UNSIGNED(full_words_reg-1,3) THEN
                                current_state <= FINISHED;

                            ELSE
                                word_counter <= word_counter + 1;
                                current_state <= MAC_TN;

                            END IF;
                        END IF;

                    ----------------------------------------
                    -- FINISHED
                    ----------------------------------------
                    WHEN FINISHED =>
                        busy_reg <= '0';
                        done_reg <= '1';
                        current_state <= IDLE;

                END CASE;

                IF output_write_reg = '1' THEN
                    CASE output_index_reg IS
                        WHEN "000" =>
                            output_reg(127 DOWNTO 112) <= output_word_reg;

                        WHEN "001" =>
                            output_reg(111 DOWNTO  96) <= output_word_reg;

                        WHEN "010" =>
                            output_reg( 95 DOWNTO  80) <= output_word_reg;

                        WHEN "011" =>
                            output_reg( 79 DOWNTO  64) <= output_word_reg;

                        WHEN "100" =>
                            output_reg( 63 DOWNTO  48) <= output_word_reg;

                        WHEN "101" =>
                            output_reg( 47 DOWNTO  32) <= output_word_reg;

                        WHEN "110" =>
                            output_reg( 31 DOWNTO  16) <= output_word_reg;

                        WHEN OTHERS =>
                            output_reg( 15 DOWNTO   0) <= output_word_reg;

                    END CASE;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------
    -- OUTPUTS
    --------------------------------------------
    result_output <= output_reg;
    R_output      <= internal_R;

    done <= done_reg;
    busy <= busy_reg;

END ARCHITECTURE Behavioral;