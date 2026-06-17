LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY Full_Decryption IS
    PORT(
        clk   : IN STD_LOGIC;
        rst   : IN STD_LOGIC;

        start : IN STD_LOGIC;

        ciphertext : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        text_len   : IN INTEGER RANGE 1 TO 128;
        key        : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        R_input    : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        plaintext : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        R_output  : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        
        done : OUT STD_LOGIC;
        busy : OUT STD_LOGIC
    );
END ENTITY Full_Decryption;

ARCHITECTURE Behavioral OF Full_Decryption IS

    --------------------------------------------
    -- FSM STATES
    --------------------------------------------
    TYPE fsm_state_t IS(
        IDLE,

        ---------------------------------------
        -- DECRYPTION
        ---------------------------------------
        LOAD_WORD,

        START_DEC,
        WAIT_DEC,

        STORE_WORD,
        NEXT_WORD,

        -------------------------------------
        -- FINISHED
        -------------------------------------
        FINISHED
    );

    SIGNAL current_state : fsm_state_t := IDLE;

    -----------------------------------------
    -- SHARED Decryption CORE
    -----------------------------------------
    SIGNAL dec_start : STD_LOGIC := '0';

    SIGNAL dec_input  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL dec_output : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL dec_R_in   : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL dec_R_out  : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL dec_done : STD_LOGIC;
    SIGNAL dec_busy : STD_LOGIC;

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
    SIGNAL effective_words_reg : INTEGER RANGE 0 TO 8;
    SIGNAL last_word_bits_reg : INTEGER RANGE 0 TO 15;
    SIGNAL current_word : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL target_word_reg : UNSIGNED(3 DOWNTO 0);

    --------------------------------------------
    -- STATUS
    --------------------------------------------
    SIGNAL done_reg : STD_LOGIC := '0';
    SIGNAL busy_reg : STD_LOGIC := '0';


BEGIN

    --------------------------------------------
    -- CURRENT WORD SELECT
    --------------------------------------------
    PROCESS(ciphertext, word_counter, full_words_reg, last_word_bits_reg, effective_words_reg)
        VARIABLE target_word     : INTEGER RANGE 0 TO 8;

    BEGIN
         current_word <= (OTHERS => '0');


        IF effective_words_reg > 0 THEN
            IF TO_INTEGER(word_counter) < effective_words_reg THEN

                target_word := 8 - effective_words_reg + TO_INTEGER(word_counter);
                
                CASE target_word IS

                    WHEN 0 =>
                        current_word <= ciphertext(127 DOWNTO 112);

                    WHEN 1 =>
                        current_word <= ciphertext(111 DOWNTO 96);

                    WHEN 2 =>
                        current_word <= ciphertext(95 DOWNTO 80);

                    WHEN 3 =>
                        current_word <= ciphertext(79 DOWNTO 64);

                    WHEN 4 =>
                        current_word <= ciphertext(63 DOWNTO 48);

                    WHEN 5 =>
                        current_word <= ciphertext(47 DOWNTO 32);

                    WHEN 6 =>
                        current_word <= ciphertext(31 DOWNTO 16);

                    WHEN 7 =>
                        current_word <= ciphertext(15 DOWNTO 0);

                    WHEN OTHERS =>
                        current_word <= (OTHERS => '0');

                END CASE;    
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------
    -- SHARED ENCRYPTION CORE
    --------------------------------------------
    dec_core : ENTITY work.Decryption_Core
        PORT MAP(
            clk => clk,
            rst => rst,

            start => dec_start,

            ct_input => dec_input,

            R_input => dec_R_in,
            key     => key,

            pt_output => dec_output,
            R_output  => dec_R_out,
            
            done => dec_done,
            busy => dec_busy
        );

    --------------------------------------------
    -- MAIN FSM
    --------------------------------------------
    PROCESS(clk)

        VARIABLE target_word     : INTEGER RANGE 0 TO 8;

    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                current_state <= IDLE;

                dec_start <= '0';
                done_reg  <= '0';
                busy_reg  <= '0';

                word_counter <= (OTHERS => '0');

            ELSE
                --------------------------------
                -- DEFAULTS
                --------------------------------
                dec_start <= '0';
                done_reg  <= '0';

                --------------------------------
                -- FSM
                --------------------------------
                CASE current_state IS
                    --------------------------------------
                    -- IDLE
                    --------------------------------------
                    WHEN IDLE =>
                        busy_reg <= '0';
                        word_counter <= (OTHERS => '0');
                        target_word_reg <= TO_UNSIGNED(8 - effective_words_reg, 4);

                        IF start = '1' THEN

                            full_words_reg     <= text_len / 16;
                            last_word_bits_reg <= text_len MOD 16;
                            IF(text_len MOD 16) = 0 THEN
                                effective_words_reg <= text_len / 16;

                            ELSE
                                effective_words_reg <= (text_len / 16) + 1;
                            
                            END IF;

                            busy_reg <= '1';

                            internal_R <= R_input;
                            output_reg <= (OTHERS => '0');

                            word_counter <= (OTHERS => '0');

                            current_state <= LOAD_WORD;

                        END IF;

                    --------------------------------------
                    -- LOAD WORD
                    --------------------------------------
                    WHEN LOAD_WORD =>
                        dec_input <= current_word;
                        dec_R_in  <= internal_R;

                        current_state <= START_DEC;

                    ----------------------------------------------
                    -- START DECRYPTION
                    ----------------------------------------------
                    WHEN START_DEC =>
                        dec_start <= '1';

                        current_state <= WAIT_DEC;

                    ----------------------------------------------
                    -- WAIT DECRYPTION
                    ----------------------------------------------
                    WHEN WAIT_DEC =>
                        IF dec_done = '1' THEN
                            internal_R <= dec_R_out;

                            current_state <= STORE_WORD;

                        END IF;

                    --------------------------------------------
                    -- STORE WORD
                    --------------------------------------------
                    WHEN STORE_WORD =>
                        target_word := 8 - effective_words_reg + TO_INTEGER(word_counter);

                        CASE target_word IS

                            WHEN 0 =>
                                output_reg(127 DOWNTO 112) <= dec_output;

                            WHEN 1 =>
                                output_reg(111 DOWNTO  96) <= dec_output;

                            WHEN 2 =>
                                output_reg( 95 DOWNTO  80) <= dec_output;

                            WHEN 3 =>
                                output_reg( 79 DOWNTO  64) <= dec_output;

                            WHEN 4 =>
                                output_reg( 63 DOWNTO  48) <= dec_output;

                            WHEN 5 =>
                                output_reg( 47 DOWNTO  32)  <= dec_output;

                            WHEN 6 =>
                                output_reg( 31 DOWNTO  16) <= dec_output;

                            WHEN 7 =>
                                output_reg( 15 DOWNTO   0) <= dec_output;

                            WHEN OTHERS =>
                                NULL;

                        END CASE;
                        
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
                                target_word_reg <= target_word_reg + 1;

                                current_state <= LOAD_WORD;
                            
                            END IF;
                        ELSE

                            IF word_counter = TO_UNSIGNED(full_words_reg-1,3) THEN
                                current_state <= FINISHED;

                            ELSE
                                word_counter <= word_counter + 1;
                                
                                current_state <= LOAD_WORD;

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
            END IF;
        END IF;
    END PROCESS;

    --------------------------------------------
    -- OUTPUTS
    --------------------------------------------
    plaintext <= output_reg;
    R_output  <= internal_R;

    done <= done_reg;
    busy <= busy_reg;

END ARCHITECTURE Behavioral;