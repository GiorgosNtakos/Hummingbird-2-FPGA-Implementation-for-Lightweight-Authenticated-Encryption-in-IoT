LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY inv_wd16 IS
    PORT(
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        start : IN STD_LOGIC;

        inv_data_input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        key            : IN STD_LOGIC_VECTOR(63 DOWNTO 0);

        inv_data_output : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

        done : OUT STD_LOGIC;
        busy : OUT STD_LOGIC

    );
END ENTITY inv_wd16;

ARCHITECTURE Behavioral OF inv_wd16 IS
    ------------------------------------
    -- INTERNAL STATE
    ------------------------------------
    SIGNAL state_reg : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL round_counter : UNSIGNED(1 DOWNTO 0) := (OTHERS => '0');

    SIGNAL busy_reg : STD_LOGIC := '0';
    SIGNAL done_reg : STD_LOGIC := '0';

    -------------------------------------
    -- DATAPATH
    -------------------------------------
    SIGNAL current_key    : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL inv_nmf_output : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL next_state     : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN
    --------------------------------------
    -- REVERSE KEY ORDER
    --------------------------------------
    WITH round_counter SELECT
        current_key <=
            key(15 DOWNTO  0) WHEN   "00", --K4
            key(31 DOWNTO 16) WHEN   "01", --K3
            key(47 DOWNTO 32) WHEN   "10", --K2
            key(63 DOWNTO 48) WHEN   "11", --K1
            (OTHERS => '0')   WHEN OTHERS;

    ----------------------------------------
    -- INVERSE ROUND
    ----------------------------------------
    next_state <= inv_nmf_output XOR current_key;

    ----------------------------------------
    -- INV NMF
    ----------------------------------------
    inv_nmf_inst : ENTITY work.inv_nmf
        
            PORT MAP(

                mixed_word_input  => state_reg,
                word_output       => inv_nmf_output

            );

    ---------------------------------------
    -- FSM
    ---------------------------------------
    PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            -------------------------------
            -- RESET
            -------------------------------
            IF rst = '1' THEN
                state_reg <= (OTHERS => '0');
                round_counter <= (OTHERS => '0');

                busy_reg <= '0';
                done_reg <= '0';

            ELSE
                -- default
                done_reg <= '0';

                --------------------------
                -- START
                --------------------------
                IF start = '1' AND busy_reg = '0' THEN
                    state_reg <= inv_data_input;
                    round_counter <= (OTHERS => '0');
                    busy_reg <= '1';

                --------------------------
                -- ROUNDS
                --------------------------
                ELSIF busy_reg = '1' THEN
                    state_reg <= next_state;

                    IF round_counter = 3 THEN 
                        busy_reg <= '0';
                        done_reg <= '1';

                    ELSE
                        round_counter <= round_counter + 1;

                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -----------------------------------
    -- OUTPUTS
    -----------------------------------
    done <= done_reg;
    busy <= busy_reg;

    inv_data_output <= state_reg;
END ARCHITECTURE Behavioral;