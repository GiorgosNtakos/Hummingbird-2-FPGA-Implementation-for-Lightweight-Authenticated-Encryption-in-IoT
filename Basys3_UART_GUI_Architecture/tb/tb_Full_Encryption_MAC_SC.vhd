LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_Full_Encryption_MAC_SC IS
END ENTITY;

ARCHITECTURE Behavioral of tb_Full_Encryption_MAC_SC IS

    ------------------------------------------------------
    -- CLOCK PERIOD
    ------------------------------------------------------
    CONSTANT clk_period : TIME := 10 ns;

    -----------------------------------------------------
    -- DUT SIGNALS
    -----------------------------------------------------
    SIGNAL clk   : STD_LOGIC := '0';
    SIGNAL rst   : STD_LOGIC := '0';

    SIGNAL start : STD_LOGIC := '0';

    ------------------------------------------------------
    -- MODES
    -- '0' -> Encryption
    -- '1' -> MAC Generation
    ------------------------------------------------------
    SIGNAL mode : STD_LOGIC := '0';
    
    SIGNAL integrity : STD_LOGIC := '0';

    SIGNAL plaintext : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL text_len  : INTEGER RANGE 1 TO 128;

    SIGNAL key : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL iv  : STD_LOGIC_VECTOR( 63 DOWNTO 0);

    SIGNAL R_input  : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL R_output : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL result_output : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL is_decryption : STD_LOGIC := '0';

    SIGNAL done : STD_LOGIC;
    SIGNAL busy : STD_LOGIC;

    --------------------------------------------------------
    -- EXPECTED VALUES
    --------------------------------------------------------
    SIGNAL expected_cipher : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL expected_mac    : STD_LOGIC_VECTOR(127 DOWNTO 0);

BEGIN
    ---------------------------------------------------------
    -- DUT
    ---------------------------------------------------------
    dut : ENTITY work.Full_Encryption_MAC_SC
        PORT MAP(
            clk => clk,
            rst => rst,

            start => start,

            mode  => mode,

            integrity => integrity,
            is_decryption => is_decryption,

            plaintext => plaintext,
            text_len  => text_len,

            key => key,
            iv  => iv,

            R_input  => R_input,
            R_output => R_output,

            result_output => result_output,

            done => done,
            busy => busy
        );

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

    ---------------------------------------------------------
    -- MAIN TEST PROCESS
    --------------------------------------------------------
    stim_proc : PROCESS
    BEGIN
        --------------------------------------------------
        --RESET
        --------------------------------------------------
        rst <= '1';
        WAIT FOR 50 ns;

        rst <= '0';
        WAIT FOR clk_period;

        ---------------------------------------------------
        -- TEST VECTOR 1
        -- ALL ZERO
        ---------------------------------------------------
        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|      TEST VECTOR 1 - ENCRYPTION        |" & LF &
        "+----------------------------------------+";

        mode <= '0';
        integrity <= '0';

        key <= x"00000000000000000000000000000000";
        iv  <= x"0000000000000000";

        ----------------------------------------------------
        -- LITTLE INDIAN WORD ORDER (HB2 works like this)
        ----------------------------------------------------
        plaintext <= x"00000000000000000000000000000000";

        expected_cipher <= x"EFC4A887054F91A946578144256ECF3A";
        text_len         <= 128;

        -----------------------------------------------------
        -- INITIAL INTERNAL STATE
        -----------------------------------------------------
        R_input <= x"3DD095167311FA1B128F630E2B7D06B8";

        -----------------------------------------------------
        -- START
        -----------------------------------------------------
        WAIT UNTIL RISING_EDGE(clk);
        start <= '1';

        WAIT UNTIL RISING_EDGE(clk);
        start <= '0';

        -----------------------------------------------------
        -- WAIT FOR DONE
        -----------------------------------------------------
        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        -----------------------------------------------------
        -- ASSERT
        -----------------------------------------------------
        ASSERT result_output = expected_cipher
            REPORT "TEST VECTOR 1 ENCRYPTION FAILED" 
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 1 ENCRYPTION PASSED";

        -----------------------------------------------------
        -- INTERNAL STATE R AFTER FULL ENCRYPTION
        -----------------------------------------------------
        R_input <= x"76ACF9A0BF67FBC5519B83941C0A745F";

        ---------------------------------------------------
        -- TEST VECTOR 1 MAC
        ---------------------------------------------------
        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|            TEST VECTOR 1 - MAC         |" & LF &
        "+----------------------------------------+";

        mode <= '1';

        expected_mac <= x"EDBAF040B0673CE1F3764159B2A235D1";
        WAIT UNTIL RISING_EDGE(clk);

        start <= '1';

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '0';
        
        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT result_output = expected_mac
            REPORT "TEST VECTOR 1 MAC FAILED"
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 1 MAC PASSED";

        
        ---------------------------------------------------
        -- TEST VECTOR 2
        ---------------------------------------------------
        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|      TEST VECTOR 2 - ENCRYPTION        |" & LF &
        "+----------------------------------------+";

        mode <= '0';
        integrity <= '0';

        key <= x"23016745AB89EFCDDCFE98BA54761032";
        iv  <= x"34127856BC9AF0DE";

        plaintext <= x"11003322554477669988BBAADDCCFFEE";

        expected_cipher <= x"D15BADF81423F420B1BAC2542945383D";
        text_len         <= 128;

        R_input <= x"77F6CC4130777C6D7B399536AFFBCCD6";

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '1';
        WAIT UNTIL RISING_EDGE(clk);

        start <= '0';

        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT result_output = expected_cipher
            REPORT "TEST VECTOR 2 ENCRYPTION FAILED" 
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 2 ENCRYPTION PASSED";

        ---------------------------------------------------
        -- TEST VECTOR 2 MAC
        ---------------------------------------------------
        R_input <= x"BC8D14CD63091581BF2F7BBC79107C3E";

        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|            TEST VECTOR 2 - MAC         |" & LF &
        "+----------------------------------------+";

        mode <= '1';

        expected_mac <= x"F6C4C0744BF6E721243776DC6CA61939";
        WAIT UNTIL RISING_EDGE(clk);

        start <= '1';

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '0';
        
        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT result_output = expected_mac
            REPORT "TEST VECTOR 2 MAC FAILED"
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 2 MAC PASSED";


        ---------------------------------------------------
        -- STREAM CIPHER WORD TEST (1 word of 13 bits only)
        ---------------------------------------------------
        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|   STREAM CIPHER TEST 1 - ENCRYPTION    |" & LF &
        "+----------------------------------------+";

        mode <= '0';
        integrity <= '0';

        key <= x"00000000000000000000000000000000";
        iv  <= x"0000000000000000";

        plaintext <= x"00000000000000000000000000000000";

        expected_cipher <= x"00000000000000000000000000000FC4";
        text_len         <= 13;

        R_input <= x"3DD095167311FA1B128F630E2B7D06B8";

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '1';
        WAIT UNTIL RISING_EDGE(clk);

        start <= '0';

        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT result_output = expected_cipher
            REPORT "TEST VECTOR 1 ENCRYPTION STREAM CIPHER FAILED" 
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 1 ENCRYPTION STREAM CIPHER PASSED";

        ---------------------------------------------------
        -- TEST VECTOR 1 MAC AFTER ENCRYPTION WITH SC
        ---------------------------------------------------
        R_input <= x"5BF97184CD6A32824976128AE617343A";

        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|       TEST VECTOR 1 - MAC WITH SC      |" & LF &
        "+----------------------------------------+";

        mode <= '1';

        expected_mac <= x"0000000000000000000000000000BF78";
        WAIT UNTIL RISING_EDGE(clk);

        start <= '1';

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '0';
        
        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT result_output = expected_mac
            REPORT "TEST VECTOR 1 MAC WITH SC FAILED"
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 1 MAC WITH SC PASSED";

         ------------------------------------------------------------------
        -- STREAM CIPHER WORD WITH INTEGRITY TEST (1 word of 13 bits only)
        -------------------------------------------------------------------
        REPORT LF & 
        "+-------------------------------------------------------+" & LF &
        "|   STREAM CIPHER WITH INTEGRITY TEST 1 - ENCRYPTION    |" & LF &
        "+-------------------------------------------------------+";

        mode <= '0';
        integrity <= '1';

        key <= x"00000000000000000000000000000000";
        iv  <= x"0000000000000000";

        plaintext <= x"00000000000000000000000000000000";

        expected_cipher <= x"000000000000000000000000000000C4";
        text_len         <= 8;

        R_input <= x"3DD095167311FA1B128F630E2B7D06B8";

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '1';
        WAIT UNTIL RISING_EDGE(clk);

        start <= '0';

        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT result_output = expected_cipher
            REPORT "TEST VECTOR 1 ENCRYPTION STREAM CIPHER FAILED" 
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 1 ENCRYPTION STREAM CIPHER PASSED";


        -------------------------------------------------------------
        -- TEST VECTOR 1 MAC AFTER ENCRYPTION WITH SC AND INTEGRITY
        -------------------------------------------------------------
        R_input <= x"B27EC77C26263AF8FB08D5F6C0310EC2";

        REPORT LF & 
        "+-----------------------------------------------------+" & LF &
        "|       TEST VECTOR 1 - MAC WITH SC AND INTEGRITY     |" & LF &
        "+-----------------------------------------------------+";

        mode <= '1';

        expected_mac <= x"00000000000000000000000000000824";
        WAIT UNTIL RISING_EDGE(clk);

        start <= '1';

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '0';
        
        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT result_output = expected_mac
            REPORT "TEST VECTOR 1 MAC WITH SC FAILED"
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 1 MAC WITH SC PASSED";

            mode <= '0';
        integrity <= '0';

        key <= x"23016745AB89EFCDDCFE98BA54761032";
        iv  <= x"34127856BC9AF0DE";

        plaintext <= x"11003322554477669988BBAADDCCFFEE";

        expected_cipher <= x"D15BADF81423F420B1BAC2542945383D";
        text_len         <= 83;

        R_input <= x"77F6CC4130777C6D7B399536AFFBCCD6";

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '1';
        WAIT UNTIL RISING_EDGE(clk);

        start <= '0';

        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT result_output = expected_cipher
            REPORT "TEST VECTOR 2 ENCRYPTION FAILED" 
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 2 ENCRYPTION PASSED";


        

        ----------------------------------------------------
        -- END SIMULATION
        ----------------------------------------------------
        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|             ALL TESTS PASSED           |" & LF &
        "+----------------------------------------+";

        WAIT;
    END PROCESS;
END ARCHITECTURE Behavioral;