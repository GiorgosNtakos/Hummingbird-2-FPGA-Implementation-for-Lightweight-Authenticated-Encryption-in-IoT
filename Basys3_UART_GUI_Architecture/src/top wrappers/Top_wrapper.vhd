LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Top_Wrapper IS
    Port(
        --------------------------
        -- SYSTEM
        --------------------------
        clk   : IN STD_LOGIC;
        rst   : IN STD_LOGIC;

        start : IN STD_LOGIC;

        ----------------------------
        -- OPERATION
        ----------------------------
        operation : IN STD_LOGIC;

        -- 0 -> ENCRYPTION
        -- 1 -> DECRYPTION

        verify_mac : IN STD_LOGIC;

        integrity : IN STD_LOGIC;

        ----------------------------
        -- DATA
        ----------------------------
        data_input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        received_mac : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        text_len : IN INTEGER RANGE 1 TO 128;

        ---------------------------------
        -- CRYPTO MATERIAL
        ---------------------------------
        key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        iv  : IN STD_LOGIC_VECTOR( 63 DOWNTO 0);

        ---------------------------------
        -- OUTPUTS
        ---------------------------------
        data_output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        mac_tag     : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);

        latency_cycles : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        mac_valid : OUT STD_LOGIC;
        done      : OUT STD_LOGIC;
        busy      : OUT STD_LOGIC

    );
END ENTITY Top_Wrapper;

ARCHITECTURE Behavioral OF Top_Wrapper IS
    TYPE top_state_t IS(
        -----------------------------
        -- IDLE
        -----------------------------
        IDLE,

        ------------------------------
        -- INITILIZATION
        ------------------------------
        START_INIT,
        WAIT_INIT,

        --------------------------------
        -- ENCRYPTION
        --------------------------------
        START_ENCRYPTION,
        WAIT_ENCRYPTION,

        --------------------------------
        -- DECRYPTION
        --------------------------------
        START_DECRYPTION,
        WAIT_DECRYPTION,

        --------------------------------
        -- STREAM CIPHER DECRYPTION
        --------------------------------
        START_E0,
        WAIT_E0,

        ---------------------------------
        -- MAC GENERATION
        ---------------------------------
        START_MAC,
        WAIT_MAC,

        ---------------------------------
        -- MAC VERIFICATIOn
        ---------------------------------
        CHECK_MAC,

        ----------------------------------
        -- FINISHED
        ----------------------------------
        FINISHED
    );

    --------------------------------------
    -- INTERNAL CONTROL SIGNALS
    --------------------------------------
    SIGNAL current_state : top_state_t := IDLE;

    SIGNAL done_reg : STD_LOGIC := '0';
    SIGNAL busy_reg : STD_LOGIC := '0';

    ----------------------------------------
    -- INITIALIZATION BLOCK SIGNALS
    ----------------------------------------
    SIGNAL init_start : STD_LOGIC := '0';

    SIGNAL init_done : STD_LOGIC;
    SIGNAL init_busy : STD_LOGIC;

    SIGNAL init_R_out : STD_LOGIC_VECTOR(127 DOWNTO 0);

    -----------------------------------------
    -- ENCRYPTION SIGNALS
    -----------------------------------------
    SIGNAL enc_start : STD_LOGIC := '0';
    SIGNAL enc_mode  : STD_LOGIC := '0';
    SIGNAL enc_integrity : STD_LOGIC := '0';

    SIGNAL enc_plaintext : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL enc_R_input   : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL enc_text_len  : INTEGER RANGE 1 TO 128;

    SIGNAL enc_result    : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL enc_R_output  : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL enc_is_decryption : STD_LOGIC;

    SIGNAL enc_done : STD_LOGIC;
    SIGNAL enc_busy : STD_LOGIC; 

    -----------------------------------------
    -- DECRYPTION SIGNALS
    -----------------------------------------
    SIGNAL dec_start : STD_LOGIC := '0';

    SIGNAL dec_ciphertext : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL dec_R_input   : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL dec_text_len  : INTEGER RANGE 1 TO 128;

    SIGNAL dec_plaintext    : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL stream_input     : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL last_word_bits : INTEGER RANGE 0 TO 15;

    SIGNAL dec_R_output  : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL dec_done : STD_LOGIC;
    SIGNAL dec_busy : STD_LOGIC;
    
    -----------------------------------------
    -- MAC SIGNALS
    -----------------------------------------
    SIGNAL generated_mac_reg : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    
    SIGNAL mac_valid_reg     : STD_LOGIC;
    SIGNAL flag_mac_valid    : STD_LOGIC;

    ------------------------------------------
    -- INTERNAL DATA REGISTERS
    -------------------------------------------
    SIGNAL data_output_reg : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL current_R : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL next_R : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL load_R : STD_LOGIC;

    --------------------------------------
    -- LATENCY COUNTER
    --------------------------------------
    SIGNAL latency_counter    : UNSIGNED(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL latency_cycles_reg : UNSIGNED(15 DOWNTO 0) := (OTHERS => '0');

BEGIN

    --------------------------------------------
    -- LENGTH LOGIC
    --------------------------------------------
    last_word_bits <= text_len MOD 16;

    init_inst : ENTITY work.Initialization
    PORT MAP(
        clk => clk,
        rst => rst,

        start_init => init_start,

        key => key,
        iv  => iv,

        R_output => init_R_out,

        done => init_done,
        busy => init_busy
    );

    enc_inst : ENTITY work.Full_Encryption_MAC_SC
    PORT MAP(
        clk => clk,
        rst => rst,

        start => enc_start,
        mode  => enc_mode,
        integrity => enc_integrity,
        is_decryption => enc_is_decryption,

        plaintext => enc_plaintext,

        text_len  => enc_text_len,

        key => key,
        iv  => iv,

        result_output => enc_result,

        R_input =>  enc_R_input,
        R_output => enc_R_output,

        done => enc_done,
        busy => enc_busy
    );

    dec_inst : ENTITY work.Full_Decryption
    PORT MAP(
        clk => clk,
        rst => rst,

        start => dec_start,

        ciphertext => dec_ciphertext,

        text_len => dec_text_len,
        key => key,

        plaintext => dec_plaintext,

        R_input => dec_R_input,
        R_output => dec_R_output,

        done => dec_done,
        busy => dec_busy
    );

    mac_checker_inst : ENTITY work.MAC_Checker
    PORT MAP(
        generated_mac => generated_mac_reg,
        received_mac  => received_mac,

        valid => flag_mac_valid
    );

    PROCESS(dec_ciphertext, last_word_bits, stream_input)
    BEGIN
        stream_input <= (OTHERS => '0');

        IF last_word_bits /= 0 THEN
            stream_input(last_word_bits-1 DOWNTO 0) <= dec_ciphertext(last_word_bits-1 DOWNTO 0);

        END IF;
    END PROCESS;

    -- TO BREAK DOWN THE HUGE CE fanout
    PROCESS(all)
    BEGIN
        load_R <= '0';
        next_R <= (OTHERS => '0');
        
        CASE current_state IS
            WHEN WAIT_INIT =>
                IF init_done = '1' THEN
                    next_R <= init_R_out;
                    load_R <= '1';

                END IF;

            WHEN WAIT_ENCRYPTION | WAIT_E0 =>
                IF enc_done = '1' THEN
                    next_R <= enc_R_output;
                    load_R <= '1';

                END IF;

            WHEN WAIT_DECRYPTION =>
                IF dec_done = '1' THEN
                    next_R <= dec_R_output;
                    load_R <= '1';
                
                END IF;

            WHEN OTHERS =>
                NULL;

        END CASE;
    END PROCESS;


    PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                current_state <= IDLE;

                done_reg <= '0';
                busy_reg <= '0';

                init_start <= '0';
                enc_start  <= '0';
                dec_start  <= '0';
                mac_valid_reg <= '0';

            ELSE
                -------------------------------------
                 -- COUNTING LATENCY CYCLES
                 ------------------------------------ 
                IF busy_reg = '1' THEN
                    latency_counter <= latency_counter + 1;
                
                END IF;
                ----------------------------------
                -- Defaults
                ----------------------------------
                done_reg <= '0';

                init_start <= '0';
                enc_start  <= '0';
                dec_start  <= '0';
                
                IF load_R = '1' THEN
                    current_R <= next_R;
                END IF;

                CASE current_state IS
                    -------------------------------------
                    -- IDLE 
                    -------------------------------------
                    WHEN IDLE =>
                        busy_reg <= '0';

                        IF start = '1' THEN
                            latency_counter <= (OTHERS => '0');

                            mac_valid_reg <= '0';
                            busy_reg <= '1';
                            current_state <= START_INIT;

                        END IF;

                    -------------------------------------
                    -- INIT
                    -------------------------------------
                    WHEN START_INIT =>
                        init_start <= '1';
                        current_state <= WAIT_INIT;

                    WHEN WAIT_INIT =>
                        IF init_done = '1' THEN
                        current_R <= init_R_out;

                            IF operation = '0' THEN
                                current_state <= START_ENCRYPTION;

                            ELSE
                                IF text_len < 16 THEN
                                    dec_ciphertext <= data_input;
                                    current_state <= START_E0;

                                ELSE
                                    current_state <= START_DECRYPTION;

                                END IF;
                            END IF;
                        END IF;

                    -----------------------------------------
                    -- ENCRYPTION
                    -----------------------------------------
                    WHEN START_ENCRYPTION =>
                        enc_mode <= '0';

                        enc_is_decryption <= '0';

                        enc_integrity <= integrity;
                        enc_plaintext <= data_input;

                        enc_text_len  <= text_len;
                        
                        enc_R_input   <= current_R;

                        enc_start <= '1';

                        current_state <= WAIT_ENCRYPTION;

                    WHEN WAIT_ENCRYPTION =>
                        IF enc_done = '1' THEN
                            data_output_reg <= enc_result;

                            current_state <= START_MAC;

                        END IF;

                    ----------------------------------------
                    -- DECRYPTION
                    ---------------------------------------
                    WHEN START_DECRYPTION =>
                        dec_ciphertext <= data_input;
                        dec_text_len   <= text_len;

                        dec_R_input <= current_R;

                        dec_start <= '1';
                        
                        current_state <= WAIT_DECRYPTION;

                    WHEN WAIT_DECRYPTION =>
                        IF dec_done = '1' THEN
                           data_output_reg <= dec_plaintext;

                            IF(text_len MOD 16) /= 0 THEN
                                -------------------------------
                                -- NEED STREAM CIPHER FOR THE
                                -- REMAINING BITS
                                -------------------------------
                                current_state <= START_E0;

                            ELSE
                                -------------------------------
                                -- FULL DECRYPTION COMPLETED
                                -------------------------------
                                current_state <= START_MAC;
                            
                            END IF;
                        END IF;

                    WHEN START_E0 =>
                        IF operation = '1' AND text_len < 16 THEN
                            data_output_reg <= (OTHERS => '0');
                        END IF;

                        enc_mode <= '0';
                        enc_integrity <= integrity;
                        enc_is_decryption <= '1';

                        enc_plaintext <= stream_input;
                        enc_text_len  <= last_word_bits;

                        enc_R_input   <= current_R;

                        enc_start     <=  '1';

                        current_state <= WAIT_E0;

                    WHEN WAIT_E0 =>
                        IF enc_done = '1' THEN
                            data_output_reg(last_word_bits -1 DOWNTO 0) <= enc_result(last_word_bits - 1 DOWNTO 0);

                            current_state <= START_MAC;

                        END IF;

                    WHEN START_MAC =>
                        --------------------------------
                        -- MAC MODE
                        --------------------------------
                        enc_mode <= '1';

                        enc_integrity <= '0';

                        enc_text_len  <= text_len;

                        enc_R_input  <= current_R;

                        enc_start <= '1';

                        current_state <= WAIT_MAC;

                        enc_plaintext <= (OTHERS => '0');

                    WHEN WAIT_MAC =>
                        IF enc_done = '1' THEN
                            generated_mac_reg <= enc_result;

                            ----------------------------------
                            -- VERIFY ?
                            ----------------------------------
                            IF(operation = '1') AND (verify_mac = '1') THEN
                                current_state <= CHECK_MAC;

                            ELSE
                                current_state <= FINISHED;

                            END IF;
                        END IF;

                    WHEN CHECK_MAC =>
                         mac_valid_reg <= flag_mac_valid;
                        current_state <= FINISHED;

                    WHEN FINISHED =>
                        latency_cycles_reg <= latency_counter;

                        busy_reg <= '0';

                        done_reg <= '1';

                        current_state <= IDLE;

                END CASE;
            END IF;
        END IF;
    END PROCESS;

    ----------------------------------------
    -- OUTPUTS
    ----------------------------------------
    data_output <= data_output_reg;

    mac_tag   <= generated_mac_reg;
    mac_valid <= mac_valid_reg;

    latency_cycles <= STD_LOGIC_VECTOR(latency_cycles_reg);

    done <= done_reg;
    busy <= busy_reg;

END ARCHITECTURE Behavioral;
