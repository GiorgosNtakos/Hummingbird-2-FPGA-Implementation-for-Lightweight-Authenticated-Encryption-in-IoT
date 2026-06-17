-- This entity defines the initialization process in the cryptographic algorithm.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY Initialization IS

	PORT(

		clk 		   : IN  STD_LOGIC; -- Clock signal
		rst		       : IN  STD_LOGIC; -- Reset signal

        start_init     : IN  STD_LOGIC; -- Start signal for initialization

		iv    		   : IN  STD_LOGIC_VECTOR ( 63  DOWNTO 0); -- Initialization vector (64 bits)
		key 		   : IN  STD_LOGIC_VECTOR (127  DOWNTO 0); -- Secret key (128 bits)

		R_output       : OUT STD_LOGIC_VECTOR (127  DOWNTO 0); -- Output of the initialization

        done           : OUT STD_LOGIC;
        busy           : OUT STD_LOGIC

	);

END Initialization;

ARCHITECTURE Behavioral OF Initialization IS

    -------------------------------
    -- FSM States
    -------------------------------
    TYPE init_state_t IS (
        IDLE,

        START_T1,
        WAIT_T1,

        START_T2,
        WAIT_T2,

        START_T3,
        WAIT_T3,

        START_T4,
        WAIT_T4,

        UPDATE_STATE,

        NEXT_ROUND,

        FINISHED
    );

    SIGNAL current_state : init_state_t := IDLE;

    ----------------------------------------
    -- HB2 internal state registers(R1-R8)
    ----------------------------------------
    SIGNAL R1,R2,R3,R4 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R5,R6,R7,R8 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    ----------------------------------------
    -- Next ROR/ROL R1-R4 state signals
    ----------------------------------------
    SIGNAL R1_rol, R2_ror, R3_rol, R4_rol : STD_LOGIC_VECTOR(15 DOWNTO 0);

    ----------------------------------------
    -- Reused adder results
    ----------------------------------------
    SIGNAL sum_t1, sum_t2, sum_t3, sum_t4, sum_t5 : STD_LOGIC_VECTOR(15 DOWNTO 0);

    ----------------------------------------
    -- Temp results
    ----------------------------------------
    SIGNAL t1,t2,t3,t4 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    ----------------------------------------
    -- Round counter
    ----------------------------------------
    SIGNAL init_round_counter : UNSIGNED(1 DOWNTO 0) := (OTHERS => '0');

    ----------------------------------------
    -- WD16 interface
    ----------------------------------------
    SIGNAL wd_start : STD_LOGIC := '0';

    SIGNAL wd_input : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL wd_key : STD_LOGIC_VECTOR(63 DOWNTO 0);

    SIGNAL wd_output : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL wd_done   : STD_LOGIC;
    SIGNAL wd_busy   : STD_LOGIC;

    ---------------------------------------
    -- Status Registers                 
    ---------------------------------------
    SIGNAL done_reg : STD_LOGIC := '0';
    SIGNAL busy_reg : STD_LOGIC := '0';

BEGIN

    ------------------------------------------
    -- Combinational additions
    ------------------------------------------
    sum_t1 <= STD_LOGIC_VECTOR(UNSIGNED(R1) + 
              RESIZE(init_round_counter, 16));
            
    sum_t2 <= STD_LOGIC_VECTOR(UNSIGNED(R2) + 
              UNSIGNED(t1));

    sum_t3 <= STD_LOGIC_VECTOR(UNSIGNED(R3) + 
              UNSIGNED(t2));

    sum_t4 <= STD_LOGIC_VECTOR(UNSIGNED(R4) + 
              UNSIGNED(t3));

    sum_t5 <= STD_LOGIC_VECTOR(UNSIGNED(R1) + 
              UNSIGNED(t4));

    -------------------------------------------
    -- ROR / ROL Operations on R1-R4 & t1-t4
    -------------------------------------------
    R1_rol <= sum_t5 ROL 3;
    R2_ror <= sum_t2 ROR 1;
    R3_rol <= sum_t3 ROL 8;
    R4_rol <= sum_t4 ROL 1;

    --------------------------------------
    -- Shared WD16 Engine
    --------------------------------------
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

    --------------------------------------
    -- Main FSM
    --------------------------------------
    PROCESS(clk)
    BEGIN

        IF rising_edge(clk) THEN
            -----------------------------
            -- Reset
            -----------------------------
            IF rst = '1' THEN
                current_state <= IDLE;

                done_reg      <= '0';
                busy_reg      <= '0';

                init_round_counter <= (OTHERS => '0');

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

                        IF start_init = '1' THEN
                            busy_reg <= '1';
                            init_round_counter <= (OTHERS => '0');

                            -- LOAD IV into state registers
                            R1 <= IV(63 DOWNTO 48);
                            R2 <= IV(47 DOWNTO 32);
                            R3 <= IV(31 DOWNTO 16);
                            R4 <= IV(15 DOWNTO  0);

                            R5 <= IV(63 DOWNTO 48);
                            R6 <= IV(47 DOWNTO 32);
                            R7 <= IV(31 DOWNTO 16);
                            R8 <= IV(15 DOWNTO  0);

                            current_state <= START_T1;

                        END IF;

                    -----------------------------------------
                    -- T1
                    -----------------------------------------
                    WHEN START_T1 =>
                        wd_input <= sum_t1;
                        
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
                        wd_input <= sum_t2;
                        
                        wd_key <= key(63 DOWNTO 0);

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
                        wd_input <= sum_t3;
                        
                        wd_key <= key(127 DOWNTO 64);

                        wd_start <= '1';

                        current_state <= WAIT_T3;

                    WHEN WAIT_T3 =>

                        IF wd_done = '1' THEN
                            t3 <= wd_output;

                            current_state <= START_T4;

                        END IF;

                    -----------------------------------------
                    -- T4
                    -----------------------------------------
                    WHEN START_T4 =>
                        wd_input <= sum_t4;
                        
                        wd_key <= key(63 DOWNTO 0);

                        wd_start <= '1';

                        current_state <= WAIT_T4;

                    WHEN WAIT_T4 =>

                        IF wd_done = '1' THEN
                            t4 <= wd_output;

                            current_state <= UPDATE_STATE;

                        END IF;

                    WHEN UPDATE_STATE =>

                        -- Update R1-R4
                        R1 <= R1_rol;
                        R2 <= R2_ror;
                        R3 <= R3_rol;
                        R4 <= R4_rol;

                        -- Update R5-R8
                        R5 <= R5 XOR R1_rol;
                        R6 <= R6 XOR R2_ror;
                        R7 <= R7 XOR R3_rol;
                        R8 <= R8 XOR R4_rol;

                        current_state <= NEXT_ROUND;

                    -------------------------------------------------
                    -- Next INITIALIZATION round
                    -------------------------------------------------
                    WHEN NEXT_ROUND =>

                        IF init_round_counter = "11" THEN
                            current_state <= FINISHED;

                        ELSE
                            init_round_counter <= init_round_counter + 1;
                            current_state <= START_T1;

                        END IF;

                    ----------------------------------------------------
                    -- Finished
                    ----------------------------------------------------
                    WHEN FINISHED =>
                        busy_reg      <= '0';
                        done_reg      <= '1';
                        current_state <= IDLE;

                END CASE;
            END IF;
        END IF;
    END PROCESS;


    --------------------------------------
    -- Outputs
    --------------------------------------
        done <= done_reg;
        busy <= busy_reg;

        R_output <= R1 & R2 & R3 & R4 & 
                    R5 & R6 & R7 & R8;

END ARCHITECTURE Behavioral;