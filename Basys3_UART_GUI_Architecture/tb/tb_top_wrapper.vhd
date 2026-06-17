LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_top_wrapper IS
END ENTITY;

ARCHITECTURE sim OF tb_top_wrapper IS
    ------------------------------------------------------
    -- CLOCK PERIOD
    ------------------------------------------------------
    CONSTANT clk_period : TIME := 10 ns;

    ------------------------------------
    -- CLOCK/RESET/START
    ------------------------------------
    SIGNAL clk   : STD_LOGIC := '0';
    SIGNAL rst   : STD_LOGIC := '0';

    SIGNAL start : STD_LOGIC := '0';

    ------------------------------------
    -- DUT INPUTS
    ------------------------------------
    SIGNAL operation  : STD_LOGIC := '0';
    SIGNAL verify_mac : STD_LOGIC := '0';

    SIGNAL integrity  : STD_LOGIC := '0';

    SIGNAL data_input : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL received_mac : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');

    SIGNAL text_len : INTEGER RANGE 1 TO 128 := 128;

    SIGNAL key : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL iv  : STD_LOGIC_VECTOR( 63 DOWNTO 0);

    ------------------------------------
    -- DUT OUTPUTS
    ------------------------------------
    SIGNAL data_output : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL mac_tag     : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL mac_valid   : STD_LOGIC;

    SIGNAL done : STD_LOGIC;
    SIGNAL busy : STD_LOGIC;

    ----------------------------------
    -- SAVED RESULTS
    ----------------------------------
    SIGNAL ct_full  : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL mac_full : STD_LOGIC_VECTOR(127 DOWNTO 0);

    ---------------------------------
    -- latency counter signals
    ---------------------------------
    signal cycle_counter : integer := 0;

    signal start_cycle : integer := 0;
    signal end_cycle   : integer := 0;

    signal start_d : std_logic := '0';
    signal done_d  : std_logic := '0';

    BEGIN
        ----------------------------------------------------------
        -- CLOCK GENERATION
        ---------------------------------------------------------
        clk_process : PROCESS
        BEGIN
            clk <= '0';
            WAIT FOR clk_period/2;

            clk <= '1';
            WAIT FOR clk_period/2;

        END PROCESS;

        process(clk)
        begin
            if rising_edge(clk) then
                cycle_counter <= cycle_counter + 1;
            end if;
        end process;

        process(clk)
        begin
            if rising_edge(clk) then

                start_d <= start;
                done_d  <= done;

                ------------------------------------------------
                -- START EDGE
                ------------------------------------------------
                if start = '1' and start_d = '0' then

                    start_cycle <= cycle_counter;

                end if;

                ------------------------------------------------
                -- DONE EDGE
                ------------------------------------------------
                if done = '1' and done_d = '0' then

                    end_cycle <= cycle_counter;

                    report "Latency cycles = " &
                        integer'image(cycle_counter - start_cycle);

                end if;

            end if;
        end process;

        dut : ENTITY work.Top_Wrapper
            PORT MAP(
                clk => clk,
                rst => rst,

                start => start,

                operation => operation,
                verify_mac => verify_mac,
                integrity => integrity,

                data_input => data_input,
                received_mac => received_mac,

                text_len => text_len,

                key => key,
                iv  => iv,

                data_output => data_output,
                mac_tag     => mac_tag,
                mac_valid   => mac_valid,

                done => done,
                busy => busy
            );

        --------------------------------------
        -- STIMULUS
        --------------------------------------
        stim_proc : PROCESS
        BEGIN
            -----------------------------------------
            -- RESET
            -----------------------------------------
            rst <= '1';

            WAIT FOR 50 ns;

            rst <= '0';

            WAIT FOR 50 ns;

            ------------------------------------------
            -- TEST 1 
            -- ENCRYPT 128 BITS
            ------------------------------------------
            REPORT LF & 
            "+----------------------------------------+" & LF &
            "|      TEST VECTOR 1 - ENCRYPTION        |" & LF &
            "+----------------------------------------+";

            ----------------------------------------
            -- KEY/IV
            ----------------------------------------
            key <= x"23016745AB89EFCDDCFE98BA54761032";
            iv  <= x"34127856BC9AF0DE";

            operation <= '0';
            verify_mac <= '0';
            integrity <= '0';

            text_len <= 128;

            data_input <= x"11003322554477669988BBAADDCCFFEE";

            WAIT UNTIL RISING_EDGE(clk);
            start <= '1';
            WAIT UNTIL RISING_EDGE(clk);
            
            start <= '0';

            WAIT UNTIL done = '1';
            WAIT UNTIL RISING_EDGE(clk);

            ct_full <= data_output;
            mac_full <= mac_tag;

            WAIT UNTIL rising_edge(clk);

            ASSERT data_output = x"D15BADF81423F420B1BAC2542945383D"
                REPORT "TEST VECTOR 1 ENCRYPTION FAILED" 
                SEVERITY FAILURE;

                REPORT "TEST VECTOR 1 ENCRYPTION PASSED";

            WAIT FOR 100 ns;

            ------------------------------------------
            -- TEST 1 
            -- DECRYPTION 128 BITS
            ------------------------------------------
            REPORT LF & 
            "+----------------------------------------+" & LF &
            "|      TEST VECTOR 2 - DECRYPTION        |" & LF &
            "+----------------------------------------+";

            operation <= '1';
            verify_mac <= '1';
            integrity <= '0';

            text_len <= 128;

            data_input <= ct_full;
            received_mac <= mac_full;

            WAIT UNTIL RISING_EDGE(clk);
            start <= '1';

            WAIT UNTIL RISING_EDGE(clk);
            start <= '0';

            WAIT UNTIL done = '1';
            WAIT UNTIL RISING_EDGE(clk);

            ASSERT data_output = x"11003322554477669988BBAADDCCFFEE"
                REPORT "TEST VECTOR 1 DECRYPTION FAILED" 
                SEVERITY FAILURE;

                REPORT "TEST VECTOR 1 DECRYPTION PASSED";

            ASSERT mac_valid = '1'
                REPORT "FULL MAC VERIFICATION FAILED"
                SEVERITY ERROR;
            WAIT FOR 100 ns;

            REPORT LF & 
            "+----------------------------------------+" & LF &
            "|   STREAM CIPHER TEST 3 - ENCRYPTION    |" & LF &
            "+----------------------------------------+";
            key <= x"00000000000000000000000000000000";
            iv  <= x"0000000000000000";

            operation <= '0';
            verify_mac <= '0';
            integrity <= '0';

            text_len <= 13;

            data_input <= x"00000000000000000000000000000000";

            WAIT UNTIL RISING_EDGE(clk);
            start <= '1';
            WAIT UNTIL RISING_EDGE(clk);
            
            start <= '0';

            WAIT UNTIL done = '1';
            WAIT UNTIL RISING_EDGE(clk);

            ct_full <= data_output;
            mac_full <= mac_tag;

            WAIT UNTIL rising_edge(clk);

            ASSERT data_output = x"00000000000000000000000000000FC4"
                REPORT "TEST VECTOR 3 STREAM CIPHER FAILED" 
                SEVERITY FAILURE;

                REPORT "TEST VECTOR 3 STREAM CIPHER PASSED";

            WAIT FOR 100 ns;

            REPORT LF & 
            "+----------------------------------------+" & LF &
            "|    STREAM CIPHER TEST 4 - DECRYPTION   |" & LF &
            "+----------------------------------------+";

            operation <= '1';
            verify_mac <= '1';
            integrity <= '0';

            text_len <= 13;

            data_input <= ct_full;
            received_mac <= mac_full;

            WAIT UNTIL RISING_EDGE(clk);
            start <= '1';

            WAIT UNTIL RISING_EDGE(clk);
            start <= '0';

            WAIT UNTIL done = '1';
            WAIT UNTIL RISING_EDGE(clk);

            ASSERT data_output = x"00000000000000000000000000000000"
                REPORT "TEST VECTOR 4 DECRYPTION STREAM CIPHER FAILED" 
                SEVERITY FAILURE;

                REPORT "TEST VECTOR 4 DECRYPTION STREAM CIPHER PASSED";

            ASSERT mac_valid = '1'
                REPORT "FULL MAC VERIFICATION FAILED"
                SEVERITY ERROR;
            WAIT FOR 100 ns;

            REPORT LF & 
            "+----------------------------------------+" & LF &
            "|   STREAM CIPHER TEST 5 - ENCRYPTION    |" & LF &
            "+----------------------------------------+";
            key <= x"23016745AB89EFCDDCFE98BA54761032";
            iv  <= x"34127856BC9AF0DE";

            operation <= '0';
            verify_mac <= '0';
            integrity <= '1';

            text_len <= 83;

            data_input <= x"11003322554477669988BBAADDCCFFEE";

            WAIT UNTIL RISING_EDGE(clk);
            start <= '1';
            WAIT UNTIL RISING_EDGE(clk);
            
            start <= '0';

            WAIT UNTIL done = '1';
            WAIT UNTIL RISING_EDGE(clk);

            ct_full <= data_output;
            mac_full <= mac_tag;

            WAIT UNTIL rising_edge(clk);

            WAIT FOR 100 ns;

            REPORT LF & 
            "+----------------------------------------+" & LF &
            "|    STREAM CIPHER TEST 6 - DECRYPTION   |" & LF &
            "+----------------------------------------+";

            operation <= '1';
            verify_mac <= '1';
            integrity <= '1';

            text_len <= 83;

            data_input <= ct_full;
            received_mac <= mac_full;

            WAIT UNTIL RISING_EDGE(clk);
            start <= '1';

            WAIT UNTIL RISING_EDGE(clk);
            start <= '0';

            WAIT UNTIL done = '1';
            WAIT UNTIL RISING_EDGE(clk);

            WAIT FOR 100 ns;

            ----------------------------------------
            -- END
            ----------------------------------------
            REPORT "ALL TESTS PASSED";

            WAIT;

        END PROCESS;
END ARCHITECTURE sim;
    


