LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Initialization_tb IS
END Initialization_tb;

ARCHITECTURE behavior OF Initialization_tb IS

    -- Component Declaration for the UUT
    COMPONENT Initialization_new

    PORT(

        clk        : IN  STD_LOGIC;
        rst        : IN  STD_LOGIC;
        start_init : IN  STD_LOGIC_VECTOR(  2 DOWNTO 0);
        iv         : IN  STD_LOGIC_VECTOR( 63 DOWNTO 0);
        key        : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        R_output   : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)

    );
    END COMPONENT;

    --Inputs
    SIGNAL clk        : STD_LOGIC := '0';
    SIGNAL rst        : STD_LOGIC := '0';
    SIGNAL start_init : STD_LOGIC_VECTOR(  2 DOWNTO 0) := "000";
    SIGNAL iv         : STD_LOGIC_VECTOR( 63 DOWNTO 0) := (OTHERS => '0');
    SIGNAL key        : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');

    --Outputs
    SIGNAL R_output   : STD_LOGIC_VECTOR(127 DOWNTO 0);

    -- Clock period definitions
    CONSTANT clk_period : TIME := 20 ns;

BEGIN

    -- Instantiate the UUT
    uut: Initialization_new PORT MAP (

        clk        => clk,
        rst        => rst,
        start_init => start_init,
        iv         => iv,
        key        => key,
        R_output   => R_output

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
        rst <= '1';
        WAIT FOR 20 ns;
        rst <= '0';  

        -- Initialize Inputs
        iv         <= X"0000000000000000";
        key        <= X"00000000000000000000000000000000";
        start_init <= "001";

       /* WAIT FOR 500 * clk_period;

        REPORT "The value of signal IV  is : " & to_hex_string(iv) & ", the value of signal key is : " & to_hex_string(key) & " & the value of signal R_output is : " & to_hex_string(R_output) SEVERITY note;
	    ASSERT R_output = X"3DD095167311FA1B128F630E2B7D06B8"
        REPORT "Mismatch detected" SEVERITY error;
        
        iv <= X"34127856BC9AF0DE";
        key <= X"23016745AB89EFCDDCFE98BA54761032";

        WAIT FOR 500 * clk_period;
        
        REPORT "The value of signal IV  is : " & to_hex_string(iv) & ", the value of signal key is : " & to_hex_string(key) & " & the value of signal R_output is : " & to_hex_string(R_output) SEVERITY note;
	    ASSERT R_output = X"77F6CC4130777C6D7B399536AFFBCCD6"
        REPORT "Mismatch detected" SEVERITY error;*/

        WAIT;
    END PROCESS;

END behavior;
