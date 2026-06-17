LIBRARY IEEE; 
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY wd_16 IS

    PORT(

        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        -- Control
        start : IN STD_LOGIC;

        --Inputs
        data_input  :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16-bit input data to be processed
        key         :   IN  STD_LOGIC_VECTOR(63 DOWNTO 0); -- 64-bit key input for permutation

        --Outputs
        data_output :  OUT STD_LOGIC_VECTOR(15 DOWNTO 0);  -- 16-bit output after permutation
        done        :  OUT STD_LOGIC;
        busy        :  OUT STD_LOGIC

    );
END ENTITY wd_16;


ARCHITECTURE Behavioral OF wd_16 IS

    ----------------------------------
    -- Internal State
    ----------------------------------

    SIGNAL state_reg : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

    SIGNAL round_counter : UNSIGNED(1 DOWNTO 0) := (OTHERS => '0');

    SIGNAL busy_reg : STD_LOGIC := '0';
    SIGNAL done_reg : STD_LOGIC := '0';

    ---------------------------------
    -- Datapath Signals
    ---------------------------------

    SIGNAL current_key : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL nmf_input   : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL nmf_output  : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

   -------------------------------
   -- Key Selection
   -------------------------------
   WITH round_counter SELECT

    current_key <=
        key(63 DOWNTO 48) WHEN "00",
        key(47 DOWNTO 32) WHEN "01",
        key(31 DOWNTO 16) WHEN "10",
        key(15 DOWNTO  0) WHEN "11",
        (OTHERS => '0'  ) WHEN OTHERS;
        
    --------------------------------
    -- Combinational Input to NMF
    --------------------------------
    nmf_input <= state_reg XOR current_key;

    -------------------------------
    -- NMF instance
    -------------------------------
    nmf_inst : ENTITY work.nmf
        
            PORT MAP(

                word_input        => nmf_input,
                mixed_word_output => nmf_output

            );

    -----------------------------
    -- Main FSM / Control
    -----------------------------
    PROCESS(clk)

    BEGIN

        IF RISING_EDGE(clk) THEN

            --------------------
            -- Reset
            --------------------
            IF rst = '1' THEN
                state_reg     <= (OTHERS => '0');
                round_counter <= (OTHERS => '0');
                busy_reg      <= '0';
                done_reg      <= '0';

            ----------------------
            -- Normal Operation
            ----------------------
            ELSE
                -- default
                done_reg <= '0';

                -------------------------
                -- Start new operation
                -------------------------
                IF start = '1' AND busy_reg = '0' THEN
                    state_reg     <= data_input;
                    round_counter <= (OTHERS => '0');
                    busy_reg      <= '1';

                ---------------------------
                -- Iterative WD16 Rounds
                ---------------------------
                ELSIF busy_reg = '1' THEN
                    --apply one nmf stage per cycle
                    state_reg <= nmf_output;

                    ----------------------
                    -- Final round
                    ----------------------
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

   -------------------------------
   -- Outputs
   -------------------------------
   done <= done_reg;
   busy <= busy_reg;

   data_output <= state_reg;

END ARCHITECTURE Behavioral;
