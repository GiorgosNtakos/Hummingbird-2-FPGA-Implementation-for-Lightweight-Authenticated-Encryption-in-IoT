LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY HummingBird2_tb IS
END HummingBird2_tb;

ARCHITECTURE behavior OF HummingBird2_tb IS 

    -- Component Declaration for the UUT
    COMPONENT HummingBird2
        
        PORT(

                clk            : IN  STD_LOGIC;
                rst            : IN  STD_LOGIC;
                text           : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
                text_len       : IN  INTEGER RANGE 1 TO 128;
                integrity      : IN  STD_LOGIC;
                iv             : IN  STD_LOGIC_VECTOR( 63 DOWNTO 0);
                key            : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
                mode           : IN  STD_LOGIC_VECTOR(  2 DOWNTO 0);
                output         : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
                mac_flag_equal : OUT STD_LOGIC

            );

    END COMPONENT;

    --Inputs
    SIGNAL clk            : STD_LOGIC := '0';
    SIGNAL rst            : STD_LOGIC := '0';
    SIGNAL text           : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL iv             : STD_LOGIC_VECTOR( 63 DOWNTO 0) := (OTHERS => '0');
    SIGNAL key            : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL text_len       : INTEGER RANGE 1 TO 128         := 128;
    SIGNAL mode           : STD_LOGIC_VECTOR(  2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL integrity      : STD_LOGIC                      := '0';                 

    --Outputs
    SIGNAL output         : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL mac_flag_equal : STD_LOGIC;

    -- Clock period definitions
    CONSTANT clk_period : TIME := 20 ns;

BEGIN

    -- Instantiate the UUT
    uut: HummingBird2 PORT MAP (

        clk            => clk,
        rst            => rst,
        text           => text,
        text_len       => text_len,
        integrity      => integrity,
        iv             => iv,
        key            => key,
        mode           => mode,
        output         => output,
        mac_flag_equal => mac_flag_equal 

    );

    -- Clock process definitions
    clk_process : PROCESS
    BEGIN

        clk <= '0';
        WAIT FOR clk_period/2;
        clk <= '1';
        WAIT FOR clk_period/2;

    END PROCESS;

    -- Stimulus process
    stim_proc: PROCESS
    BEGIN        
        -- hold reset state for 20 ns.
        rst <= '1';
        WAIT FOR clk_period;  
        rst <= '0';
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------* FIRST TEST VECTOR *-------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------    
        --! INITIALIZATION MODE
        iv        <= X"0000000000000000";
        key       <= X"00000000000000000000000000000000";
        text_len  <= 128;
        integrity <= '0';
        text      <= X"00000000000000000000000000000000";
        mode      <= "001";

        WAIT FOR 500*clk_period;

        --! ENCRYPTION MODE
        mode     <= "010";

        WAIT FOR 600*clk_period;

        --! MAC MODE
        mode     <= "100";

        WAIT FOR 590*clk_period;

        --! INITIALIZATION MODE(NOW FOR DECRYPTION)
        mode     <= "001";

        WAIT FOR 500*clk_period;

        --! DECRYPTION MODE
        text     <= X"EFC4A887054F91A946578144256ECF3A";
        mode     <= "011";

        WAIT FOR 620*clk_period;

        --! MAC MODE (NOW FOR DECRYPTION)
        mode     <= "100";

        WAIT FOR 590 * clk_period;

         --! MAC MODE CHECKER(NOW FOR DECRYPTION)
         mode <= "101";
         text <= X"EDBAF040B0673CE1F3764159B2A235D1";

         WAIT FOR 3*clk_period;

        ASSERT ( mac_flag_equal = '1')
        REPORT "Test case 1 failed" SEVERITY error;

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------* SECOND TEST VECTOR *-------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------

        --! INITIALIZATION MODE
        iv        <= X"34127856BC9AF0DE";
        key       <= X"23016745AB89EFCDDCFE98BA54761032";
        text_len  <= 128;
        integrity <= '0';
        text      <= X"11003322554477669988BBAADDCCFFEE";
        mode      <= "001";

        WAIT FOR 500*clk_period;

        --! ENCRYPTION MODE
        mode     <= "010";

         WAIT FOR 600*clk_period;

        --! MAC MODE
        mode     <= "100";

        WAIT FOR 590*clk_period;

        --! INITIALIZATION MODE(NOW FOR DECRYPTION)
        mode     <= "001";

        WAIT FOR 500*clk_period;

        --! DECRYPTION MODE
        text     <= X"D15BADF81423F420B1BAC2542945383D";
        mode     <= "011";

        WAIT FOR 620*clk_period;

        --! MAC MODE (NOW FOR DECRYPTION)
        mode     <= "100";

        WAIT FOR 590*clk_period;

        --! MAC MODE CHECKER(NOW FOR DECRYPTION)
        mode <= "101";
        text <= X"F6C4C0744BF6E721243776DC6CA61939";

        WAIT FOR 3*clk_period;

        ASSERT ( mac_flag_equal = '1')
        REPORT "Test case 1 failed" SEVERITY error;

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------* THIRD TEST VECTOR *-------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------

        --! INITIALIZATION MODE
        iv        <= X"0000000000000000";
        key       <= X"00000000000000000000000000000000";
        text_len  <= 16;
        integrity <= '0';
        text      <= X"00000000000000000000000000000000";
        mode      <= "001";

        WAIT FOR 500*clk_period;

        --! ENCRYPTION MODE
        mode     <= "010";

         WAIT FOR 240*clk_period;

        --! MAC MODE
        mode     <= "100";

        WAIT FOR 300*clk_period;

        --! INITIALIZATION MODE(NOW FOR DECRYPTION)
        mode     <= "001";

        WAIT FOR 500*clk_period;

        --! DECRYPTION MODE
        text     <= X"0000000000000000000000000000EFC4";
        mode     <= "011";

        WAIT FOR 240*clk_period;

        --! MAC MODE (NOW FOR DECRYPTION)
        mode     <= "100";

        WAIT FOR 300*clk_period;

       --! MAC MODE CHECKER(NOW FOR DECRYPTION)
       mode <= "101";
       text <= X"BF780000000000000000000000000000";

       WAIT FOR 3*clk_period;

       ASSERT ( mac_flag_equal = '1')
       REPORT "Test case 1 failed" SEVERITY error;

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------* FOURTH TEST VECTOR *-------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    
        --! INITIALIZATION MODE
        iv        <= X"34127856BC9AF0DE";
        key       <= X"23016745AB89EFCDDCFE98BA54761032";
        text_len  <= 16;
        integrity <= '0';
        text      <= X"11003322554477669988BBAADDCCFFEE";
        mode      <= "001";

        WAIT FOR 500*clk_period;

        --! ENCRYPTION MODE
        mode     <= "010";

         WAIT FOR 240*clk_period;

        --! MAC MODE
        mode     <= "100";

        WAIT FOR 300*clk_period;

        --! INITIALIZATION MODE(NOW FOR DECRYPTION)
        mode     <= "001";

        WAIT FOR 500*clk_period;

        --! DECRYPTION MODE
        text     <= X"00000000000000000000000000004AE9";
        mode     <= "011";

        WAIT FOR 240*clk_period;

        --! MAC MODE (NOW FOR DECRYPTION)
        mode     <= "100";

        WAIT FOR 300*clk_period;

        --! MAC MODE CHECKER(NOW FOR DECRYPTION)
       mode <= "101";
       text <= X"F2D30000000000000000000000000000";

       WAIT FOR 3*clk_period;

       ASSERT ( mac_flag_equal = '1')
       REPORT "Test case 1 failed" SEVERITY error;

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------* FIFTH TEST VECTOR *-------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    
        --! INITIALIZATION MODE
        iv        <= X"0000000000000000";
        key       <= X"00000000000000000000000000000000";
        text_len  <= 8;
        integrity <= '0';
        text      <= X"00000000000000000000000000000000";
        mode      <= "001";

        WAIT FOR 500*clk_period;

        --! ENCRYPTION MODE
        mode     <= "010";

         WAIT FOR 340*clk_period;

        --! MAC MODE
        mode     <= "100";

        WAIT FOR 400*clk_period;

        --! INITIALIZATION MODE(NOW FOR DECRYPTION)
        mode     <= "001";

        WAIT FOR 500*clk_period;

        --! DECRYPTION MODE
        text     <= X"000000000000000000000000000000C4";
        mode     <= "011";

        WAIT FOR 340*clk_period;

        --! MAC MODE (NOW FOR DECRYPTION)
        mode     <= "100";

        WAIT FOR 300*clk_period;

       --! MAC MODE CHECKER(NOW FOR DECRYPTION)
       mode <= "101";
       text <= X"BF780000000000000000000000000000";

       WAIT FOR 3*clk_period;

       ASSERT ( mac_flag_equal = '1')
       REPORT "Test case 1 failed" SEVERITY error;

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------* SIXTH TEST VECTOR *-------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    
        --! INITIALIZATION MODE
        iv        <= X"34127856BC9AF0DE";
        key       <= X"23016745AB89EFCDDCFE98BA54761032";
        text_len  <= 8;
        integrity <= '0';
        text      <= X"11003322554477669988BBAADDCCFFEE";
        mode      <= "001";

        WAIT FOR 500*clk_period;

        --! ENCRYPTION MODE
        mode     <= "010";

         WAIT FOR 340*clk_period;

        --! MAC MODE
        mode     <= "100";

        WAIT FOR 400*clk_period;

        --! INITIALIZATION MODE(NOW FOR DECRYPTION)
        mode     <= "001";

        WAIT FOR 500*clk_period;

        --! DECRYPTION MODE
        text     <= X"000000000000000000000000000000B5";
        mode     <= "011";

        WAIT FOR 340*clk_period;

        --! MAC MODE (NOW FOR DECRYPTION)
        mode     <= "100";

        WAIT FOR 400*clk_period;

        --! MAC MODE CHECKER(NOW FOR DECRYPTION)
       mode <= "101";
       text <= X"A3150000000000000000000000000000";

       WAIT FOR 3*clk_period;

       ASSERT ( mac_flag_equal = '1')
       REPORT "Test case 1 failed" SEVERITY error;

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------* SEVENTH TEST VECTOR *-------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    
        --! INITIALIZATION MODE
        iv        <= X"0000000000000000";
        key       <= X"00000000000000000000000000000000";
        text_len  <= 8;
        integrity <= '1';
        text      <= X"00000000000000000000000000000000";
        mode      <= "001";

        WAIT FOR 500*clk_period;

        --! ENCRYPTION MODE
        mode     <= "010";

         WAIT FOR 440*clk_period;

        --! MAC MODE
        mode     <= "100";

        WAIT FOR 450*clk_period;

        --! INITIALIZATION MODE(NOW FOR DECRYPTION)
        mode     <= "001";

        WAIT FOR 500*clk_period;

        --! DECRYPTION MODE
        text     <= X"000000000000000000000000000000C4";
        mode     <= "011";

        WAIT FOR 340*clk_period;

        --! MAC MODE (NOW FOR DECRYPTION)
        mode     <= "100";

        WAIT FOR 450*clk_period;

         --! MAC MODE CHECKER(NOW FOR DECRYPTION)
       mode <= "101";
       text <= X"08240000000000000000000000000000";

       WAIT FOR 3*clk_period;

       ASSERT ( mac_flag_equal = '1')
       REPORT "Test case 1 failed" SEVERITY error;

    ------------------------------------------------------------------------------------------------------------------------------------------------------
    --------------------------------------------* EIGHTH TEST VECTOR *-------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    
        --! INITIALIZATION MODE
        iv        <= X"34127856BC9AF0DE";
        key       <= X"23016745AB89EFCDDCFE98BA54761032";
        text_len  <= 8;
        integrity <= '1';
        text      <= X"11003322554477669988BBAADDCC00EE";
        mode      <= "001";

        WAIT FOR 500*clk_period;

        --! ENCRYPTION MODE
        mode     <= "010";

         WAIT FOR 440*clk_period;

        --! MAC MODE
        mode     <= "100";

        WAIT FOR 600*clk_period;

        --! INITIALIZATION MODE(NOW FOR DECRYPTION)
        mode     <= "001";

        WAIT FOR 500*clk_period;

        --! DECRYPTION MODE
        text     <= X"000000000000000000000000000000B5";
        mode     <= "011";

        WAIT FOR 400*clk_period;

        --! MAC MODE (NOW FOR DECRYPTION)
        mode     <= "100";

        WAIT FOR 600*clk_period;

         --! MAC MODE CHECKER(NOW FOR DECRYPTION)
       mode <= "101";
       text <= X"88B70000000000000000000000000000";

       WAIT FOR 3*clk_period;

       ASSERT ( mac_flag_equal = '1')
       REPORT "Test case 1 failed" SEVERITY error;

       WAIT;

    END PROCESS;

END;