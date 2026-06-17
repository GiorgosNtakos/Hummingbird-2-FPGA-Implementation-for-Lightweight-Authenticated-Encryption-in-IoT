LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_Full_Decryption IS
END ENTITY;

ARCHITECTURE Behavioral of tb_Full_Decryption IS

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

    SIGNAL ciphertext : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL text_len  : INTEGER RANGE 1 TO 128;

    SIGNAL key : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL R_input  : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL R_output : STD_LOGIC_VECTOR(127 DOWNTO 0);

     SIGNAL plaintext : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL done : STD_LOGIC;
    SIGNAL busy : STD_LOGIC;

    --------------------------------------------------------
    -- EXPECTED VALUES
    --------------------------------------------------------
    SIGNAL expected_plaintext : STD_LOGIC_VECTOR(127 DOWNTO 0);

BEGIN
    ---------------------------------------------------------
    -- DUT
    ---------------------------------------------------------
    dut : ENTITY work.Full_Decryption
        PORT MAP(
            clk => clk,
            rst => rst,

            start => start,

            ciphertext => ciphertext,
            text_len  => text_len,

            key => key,

            R_input  => R_input,
            R_output => R_output,

            plaintext => plaintext,

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
        ---------------------------------------------------
        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|      TEST VECTOR 1 - Decryption        |" & LF &
        "+----------------------------------------+";


        key <= x"00000000000000000000000000000000";

        ----------------------------------------------------
        -- LITTLE INDIAN WORD ORDER (HB2 works like this)
        ----------------------------------------------------
        ciphertext <= x"EFC4A887054F91A946578144256ECF3A";

        expected_plaintext <= x"00000000000000000000000000000000";
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
        ASSERT plaintext = expected_plaintext
            REPORT "TEST VECTOR 1 DECRYPTION FAILED" 
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 1 DECRYPTION PASSED";
        
        ---------------------------------------------------
        -- TEST VECTOR 2
        ---------------------------------------------------
        REPORT LF & 
        "+----------------------------------------+" & LF &
        "|      TEST VECTOR 2 - ENCRYPTION        |" & LF &
        "+----------------------------------------+";

        key <= x"23016745AB89EFCDDCFE98BA54761032";

        ciphertext <= x"D15BADF81423F420B1BAC2542945383D";

        expected_plaintext <= x"11003322554477669988BBAADDCCFFEE";
        text_len         <= 128;

        R_input <= x"77F6CC4130777C6D7B399536AFFBCCD6";

        WAIT UNTIL RISING_EDGE(clk);
        
        start <= '1';
        WAIT UNTIL RISING_EDGE(clk);

        start <= '0';

        WAIT UNTIL done = '1';
        WAIT UNTIL RISING_EDGE(clk);

        ASSERT plaintext = expected_plaintext
            REPORT "TEST VECTOR 2 DECRYPTION FAILED" 
                SEVERITY FAILURE;

            REPORT "TEST VECTOR 2 DECRYPTION PASSED";

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