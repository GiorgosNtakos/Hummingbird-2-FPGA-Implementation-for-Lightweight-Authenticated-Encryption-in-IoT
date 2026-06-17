-- This entity defines the encyption core process in the cryptographic algorithm.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Encryption_Core IS
    PORT(
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        start : IN STD_LOGIC;

        pt_input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        R_input  : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        ct_output : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        R_output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);

        done : OUT STD_LOGIC;
        busy : OUT STD_LOGIC
    );
END ENTITY Encryption_Core;

ARCHITECTURE Behavioral OF Encryption_Core IS

    --------------------------------------------
    -- FSM STATES
    --------------------------------------------
    TYPE enc_state_t IS(
        IDLE,

        START_T1,
        WAIT_T1,

        START_T2,
        WAIT_T2,

        START_T3,
        WAIT_T3, 

        PREPARE_T4,
        START_T4,
        WAIT_T4,

        -- SPLIT UPDATE_STATE for better performance
        CALC_NEXT_STATE,

        UPDATE_STATES,

        FINISHED
    );

    SIGNAL current_state : enc_state_t := IDLE;

    ----------------------------------------------
    -- Internal state registers
    ----------------------------------------------
    SIGNAL R1, R2, R3, R4 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R5, R6, R7, R8 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    ----------------------------------------------
    -- Intermediate values
    ----------------------------------------------
    SIGNAL t1,t2,t3,t4 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL t4_input_reg : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    -----------------------------------------------
    -- R1-R4 next states
    -----------------------------------------------
    SIGNAL R1_next, R2_next, R3_next, R4_next : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL R4_partial, R4_final : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL ct_calc : STD_LOGIC_VECTOR(15 DOWNTO 0);

    ----------------------------------------------
    -- WD16 shared interface
    ----------------------------------------------
    SIGNAl wd_start : STD_LOGIC := '0';

    SIGNAL wd_input : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL wd_key   : STD_LOGIC_VECTOR(63 DOWNTO 0);

    SIGNAL wd_output : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL wd_done : STD_LOGIC;
    SIGNAL wd_busy : STD_LOGIC;

    ----------------------------------------------
    -- Output Registers
    ----------------------------------------------
    SIGNAL ciphertext_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL done_reg : STD_LOGIC := '0';
    SIGNAL busy_reg : STD_LOGIC := '0';

BEGIN

    ----------------------------------------------
    -- Shared WD16 engine
    ----------------------------------------------
    wd16_inst : ENTITY work.wd_16
        PORT MAP(
            clk          => clk,
            rst          => rst,
            
            start        => wd_start,

            data_input  => wd_input,
            key         => wd_key,

            data_output => wd_output,

            done        => wd_done,
            busy        => wd_busy
        );

    --------------------------------------------------
    -- Next R1-R4 states
    --------------------------------------------------
    R1_next <= STD_LOGIC_VECTOR(UNSIGNED(R1) + UNSIGNED(t3));
    R2_next <= STD_LOGIC_VECTOR(UNSIGNED(R2) + UNSIGNED(t1));
    R3_next <= STD_LOGIC_VECTOR(UNSIGNED(R3) + UNSIGNED(t2));

    --------------------------------------
    -- Main FSM
    --------------------------------------
    PROCESS(clk)
    BEGIN

        IF RISING_EDGE(clk) THEN
            -----------------------------
            -- Reset
            -----------------------------
            IF rst = '1' THEN
                current_state <= IDLE;

                done_reg      <= '0';
                busy_reg      <= '0';

                wd_start      <= '0';

            ELSE
                -------------------------
                -- Defaults
                -------------------------
                wd_start <= '0';
                done_reg <= '0';

                -------------------------------------------------
                -- FSM
                -------------------------------------------------
                CASE current_state IS
                    
                    -----------------------------------------------
                    -- IDLE
                    -----------------------------------------------
                    WHEN IDLE =>
                        busy_reg <= '0';

                        IF start = '1' THEN
                            busy_reg <= '1';

                            -- LOAD internal state
                            R1 <= R_input(127 DOWNTO 112);
                            R2 <= R_input(111 DOWNTO  96);
                            R3 <= R_input( 95 DOWNTO  80);
                            R4 <= R_input( 79 DOWNTO  64);

                            R5 <= R_input( 63 DOWNTO  48);
                            R6 <= R_input( 47 DOWNTO  32);
                            R7 <= R_input( 31 DOWNTO  16);
                            R8 <= R_input( 15 DOWNTO   0);

                            current_state <= START_T1;

                        END IF;

                    -----------------------------------------
                    -- T1
                    -----------------------------------------
                    WHEN START_T1 =>
                        wd_input <= STD_LOGIC_VECTOR(UNSIGNED(R1) + UNSIGNED(pt_input));
                        
                        wd_key <= key(127 DOWNTO 64);

                        wd_start <= '1';

                        current_state <= WAIT_T1;

                    WHEN WAIT_T1 =>

                        IF wd_done = '1' THEN
                            t1 <= wd_output;

                            current_state <= START_T2;

                        END IF;

                    -----------------------------------------
                    -- T2
                    -----------------------------------------
                    WHEN START_T2 =>
                        wd_input <= STD_LOGIC_VECTOR(UNSIGNED(R2) + UNSIGNED(t1));
                        
                        wd_key <= (key(63 DOWNTO 48) XOR R5) & 
                                  (key(47 DOWNTO 32) XOR R6) & 
                                  (key(31 DOWNTO 16) XOR R7) & 
                                  (key(15 DOWNTO  0) XOR R8); 

                        wd_start <= '1';

                        current_state <= WAIT_T2;

                    WHEN WAIT_T2 =>

                        IF wd_done = '1' THEN
                            t2 <= wd_output;

                            current_state <= START_T3;

                        END IF;

                        

                    -----------------------------------------
                    -- T3
                    -----------------------------------------
                    WHEN START_T3 =>
                        wd_input <= STD_LOGIC_VECTOR(UNSIGNED(R3) + UNSIGNED(t2));
                        
                        wd_key <= (key(127 DOWNTO 112) XOR R5) & 
                                  (key(111 DOWNTO  96) XOR R6) & 
                                  (key( 95 DOWNTO  80) XOR R7) & 
                                  (key( 79 DOWNTO  64) XOR R8);

                        wd_start <= '1';

                        current_state <= WAIT_T3;

                    WHEN WAIT_T3 =>

                        IF wd_done = '1' THEN
                            t3 <= wd_output;

                            current_state <= PREPARE_T4;

                        END IF;

                    -----------------------------------------
                    -- T4
                    -----------------------------------------
                    WHEN PREPARE_T4 =>
                        t4_input_reg <= STD_LOGIC_VECTOR(UNSIGNED(R4) + UNSIGNED(t3));
                        current_state <= START_T4;

                    WHEN START_T4 =>
                        wd_input <= t4_input_reg;
                        
                        wd_key <= key(63 DOWNTO 0);

                        wd_start <= '1';

                        current_state <= WAIT_T4;

                    WHEN WAIT_T4 =>

                        IF wd_done = '1' THEN
                            t4 <= wd_output;

                            current_state <= CALC_NEXT_STATE;

                        END IF;

                    -- SPLIT UPDATE_STATE for better performance
                    WHEN CALC_NEXT_STATE =>
                        ct_calc <= STD_LOGIC_VECTOR(UNSIGNED(t4) + UNSIGNED(R1));
                        R4_partial <= STD_LOGIC_VECTOR(UNSIGNED(R4) + UNSIGNED(R1));

                        current_state <= UPDATE_STATES;

                    WHEN UPDATE_STATES =>

                        ciphertext_reg <= ct_calc;
                        R4_final <= STD_LOGIC_VECTOR(UNSIGNED(R4_partial) +
                                    UNSIGNED(t1) +
                                    UNSIGNED(t3));

                        current_state <= FINISHED;

                    ----------------------------------------------------
                    -- Finished
                    ----------------------------------------------------
                    WHEN FINISHED =>
                        R1 <= R1_next;
                        R2 <= R2_next;
                        R3 <= R3_next;
                        R4 <= R4_final;

                        -- Accumulative Xor state
                        R5 <= R5 XOR R1_next;
                        R6 <= R6 XOR R2_next;
                        R7 <= R7 XOR R3_next;
                        R8 <= R8 XOR R4_final;
                        busy_reg      <= '0';
                        done_reg      <= '1';
                        current_state <= IDLE;

                END CASE;
            END IF;
        END IF;
    END PROCESS;

    ----------------------------------------------
    -- Outputs
    ----------------------------------------------
    ct_output <= ciphertext_reg;
    
    done <= done_reg;
    busy <= busy_reg;

    R_output <= R1 & R2 & R3 & R4 &
                R5 & R6 & R7 & R8;

END ARCHITECTURE Behavioral;