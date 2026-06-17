-- This entity defines the decryption core process in the cryptographic algorithm.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Decryption_Core IS
    PORT(
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        start : IN STD_LOGIC;

        ct_input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        R_input  : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        pt_output : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        R_output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);

        done : OUT STD_LOGIC;
        busy : OUT STD_LOGIC
    );
END ENTITY Decryption_Core;

ARCHITECTURE Behavioral OF Decryption_Core IS

    --------------------------------------------
    -- FSM STATES
    --------------------------------------------
    TYPE enc_state_t IS(
        IDLE,
        
        LOAD_WD,
        WAIT_WD,

        UPDATE_STATE_PREP,
        UPDATE_STATE,

        FINISHED
    );

    SIGNAL current_state : enc_state_t := IDLE;

    SIGNAL wd_round : UNSIGNED(1 DOWNTO 0);

    ----------------------------------------------
    -- Internal state registers
    ----------------------------------------------
    SIGNAL R1, R2, R3, R4 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R5, R6, R7, R8 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    ----------------------------------------------
    -- Intermediate values
    ----------------------------------------------
    SIGNAL u1,u2,u3 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL t1,t2,t3 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    -----------------------------------------------
    -- R1-R4 next states
    -----------------------------------------------
    SIGNAL R1_next, R2_next, R3_next, R4_next : STD_LOGIC_VECTOR(15 DOWNTO 0);

    --------------------------------------------------
    -- Next REG R1-R4 states -> performance ↑
    --------------------------------------------------
    SIGNAL R1_next_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL R2_next_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL R3_next_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL R4_next_reg : STD_LOGIC_VECTOR(15 DOWNTO 0);


    ----------------------------------------------
    -- Inv_WD16 shared interface
    ----------------------------------------------
    SIGNAl inv_wd_start : STD_LOGIC := '0';

    SIGNAL inv_wd_input : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL inv_wd_key   : STD_LOGIC_VECTOR(63 DOWNTO 0);

    SIGNAL inv_wd_output : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL inv_wd_done : STD_LOGIC;
    SIGNAL inv_wd_busy : STD_LOGIC;

    ----------------------------------------------
    -- Output Registers
    ----------------------------------------------
    SIGNAL plaintext_reg : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    SIGNAL done_reg : STD_LOGIC := '0';
    SIGNAL busy_reg : STD_LOGIC := '0';

BEGIN

    ----------------------------------------------
    -- Shared WD16 engine
    ----------------------------------------------
    inv_wd16_inst : ENTITY work.inv_wd16
        PORT MAP(
            clk          => clk,
            rst          => rst,
            
            start        => inv_wd_start,

            inv_data_input  => inv_wd_input,
            key         => inv_wd_key,

            inv_data_output => inv_wd_output,

            done        => inv_wd_done,
            busy        => inv_wd_busy
        );

    --------------------------------------------------
    -- Next R1-R4 states (Same as Encryption Core)
    --------------------------------------------------
    R1_next <= STD_LOGIC_VECTOR(UNSIGNED(R1) + UNSIGNED(t3));
    R2_next <= STD_LOGIC_VECTOR(UNSIGNED(R2) + UNSIGNED(t1));
    R3_next <= STD_LOGIC_VECTOR(UNSIGNED(R3) + UNSIGNED(t2));
    R4_next <= STD_LOGIC_VECTOR(UNSIGNED(R4) + UNSIGNED(R1) + UNSIGNED(t1) + UNSIGNED(t3));

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
                wd_round <= (OTHERS => '0');

                done_reg      <= '0';
                busy_reg      <= '0';

                inv_wd_start      <= '0';

            ELSE
                -------------------------
                -- Defaults
                -------------------------
                inv_wd_start <= '0';
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

                            --current_state <= START_U3;
                            wd_round <= "00";
                            current_state <= LOAD_WD;

                        END IF;

                    WHEN LOAD_WD =>

                        CASE wd_round IS

                            WHEN "00" =>

                                inv_wd_input <=
                                    STD_LOGIC_VECTOR(
                                        UNSIGNED(ct_input) -
                                        UNSIGNED(R1)
                                    );

                                inv_wd_key <= key(63 DOWNTO 0);

                            WHEN "01" =>

                                inv_wd_input <= t3;

                                inv_wd_key <=
                                    (key(127 DOWNTO 112) XOR R5) &
                                    (key(111 DOWNTO  96) XOR R6) &
                                    (key( 95 DOWNTO  80) XOR R7) &
                                    (key( 79 DOWNTO  64) XOR R8);

                            WHEN "10" =>

                                inv_wd_input <= t2;

                                inv_wd_key <=
                                    (key(63 DOWNTO 48) XOR R5) &
                                    (key(47 DOWNTO 32) XOR R6) &
                                    (key(31 DOWNTO 16) XOR R7) &
                                    (key(15 DOWNTO  0) XOR R8);

                            WHEN OTHERS =>

                                inv_wd_input <= t1;

                                inv_wd_key <= key(127 DOWNTO 64);

                        END CASE;

                        inv_wd_start <= '1';

                        current_state <= WAIT_WD;

                    WHEN WAIT_WD =>

                        IF inv_wd_done='1' THEN

                            CASE wd_round IS

                                WHEN "00" =>

                                    u3 <= inv_wd_output;

                                    t3 <=
                                        STD_LOGIC_VECTOR(
                                            UNSIGNED(inv_wd_output)
                                            -
                                            UNSIGNED(R4)
                                        );

                                    wd_round <= "01";

                                    current_state <= LOAD_WD;

                                WHEN "01" =>

                                    u2 <= inv_wd_output;

                                    t2 <=
                                        STD_LOGIC_VECTOR(
                                            UNSIGNED(inv_wd_output)
                                            -
                                            UNSIGNED(R3)
                                        );

                                    wd_round <= "10";

                                    current_state <= LOAD_WD;

                                WHEN "10" =>

                                    u1 <= inv_wd_output;

                                    t1 <=
                                        STD_LOGIC_VECTOR(
                                            UNSIGNED(inv_wd_output)
                                            -
                                            UNSIGNED(R2)
                                        );

                                    wd_round <= "11";

                                    current_state <= LOAD_WD;

                                WHEN OTHERS =>

                                    plaintext_reg <=
                                        STD_LOGIC_VECTOR(
                                            UNSIGNED(inv_wd_output)
                                            -
                                            UNSIGNED(R1)
                                        );

                                    current_state <= UPDATE_STATE_PREP;

                            END CASE;

                        END IF;

                    WHEN UPDATE_STATE_PREP =>
                        R1_next_reg <= R1_next;
                        R2_next_reg <= R2_next;
                        R3_next_reg <= R3_next;
                        R4_next_reg <= R4_next;

                        current_state <= UPDATE_STATE;

                    WHEN UPDATE_STATE =>

                        -- Update R1-R4
                        R1 <= R1_next_reg;
                        R2 <= R2_next_reg;
                        R3 <= R3_next_reg;
                        R4 <= R4_next_reg;

                        -- Accumulative Xor state
                        R5 <= R5 XOR R1_next_reg;
                        R6 <= R6 XOR R2_next_reg;
                        R7 <= R7 XOR R3_next_reg;
                        R8 <= R8 XOR R4_next_reg;

                        current_state <= FINISHED;

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

    ----------------------------------------------
    -- Outputs
    ----------------------------------------------
    pt_output <= plaintext_reg;
    
    done <= done_reg;
    busy <= busy_reg;

    R_output <= R1 & R2 & R3 & R4 &
                R5 & R6 & R7 & R8;

END ARCHITECTURE Behavioral;
