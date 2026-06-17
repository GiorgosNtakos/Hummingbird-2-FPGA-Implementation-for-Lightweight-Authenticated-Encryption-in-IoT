LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY mac_checker_tb IS
END mac_checker_tb;

ARCHITECTURE behavior OF mac_checker_tb IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT mac_checker
    PORT(

        clk             : IN  STD_LOGIC;
        rst             : IN  STD_LOGIC;
        mac_check_start : IN  STD_LOGIC_VECTOR (2 DOWNTO 0);
        T_sender        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        T_recipient     : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        flag_equal      : OUT STD_LOGIC

    );
    END COMPONENT;
    
    --Inputs
    SIGNAL clk             : STD_LOGIC                       := '0';
    SIGNAL rst             : STD_LOGIC                       := '0';
    SIGNAL mac_check_start : STD_LOGIC_VECTOR (  2 DOWNTO 0) := (others => '0');
    SIGNAL T_sender        : STD_LOGIC_VECTOR (127 DOWNTO 0) := (others => '0');
    SIGNAL T_recipient     : STD_LOGIC_VECTOR (127 DOWNTO 0) := (others => '0');

    --Outputs
    SIGNAL flag_equal      : STD_LOGIC;

    -- Clock period definitions
    CONSTANT clk_period : TIME := 20 ns;

BEGIN

    -- Instantiate the UUT
    uut: mac_checker PORT MAP (

          clk             => clk,
          rst             => rst,
          mac_check_start => mac_check_start,
          T_sender        => T_sender,
          T_recipient     => T_recipient,
          flag_equal      => flag_equal

        );

    -- Clock process definitions
    clk_process :PROCESS

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
        WAIT FOR clk_period;
        
        -- Test case 1: MAC addresses are equal
        T_sender <= X"0123456789ABCDEF0123456789ABCDEF";
        T_recipient <= X"0123456789ABCDEF0123456789ABCDEF";
        mac_check_start <= "101";
        WAIT FOR clk_period * 2;
        
        ASSERT (flag_equal = '1')
        REPORT "Test case 1 failed" SEVERITY error;
        
        -- Test case 2: MAC addresses are not equal
        T_sender <= X"0123456789ABCDEF0123456789ABCDEF";
        T_recipient <= X"FEDCBA9876543210FEDCBA9876543210";
        mac_check_start <= "101";
        WAIT FOR clk_period * 2;
        
        ASSERT (flag_equal = '0')
        REPORT "Test case 2 failed" SEVERITY error;
        
        -- Test case 3: Different mac_check_start signal
        T_sender <= X"0123456789ABCDEF0123456789ABCDEF";
        T_recipient <= X"0123456789ABCDEF0123456789ABCDEF";
        mac_check_start <= "100";
        WAIT FOR clk_period * 2;
        
        ASSERT (flag_equal = '0')
        REPORT "Test case 3 failed" SEVERITY error;
        
        -- Test case 4: Different MAC addresses with different mac_check_start signal
        T_sender <= X"0123456789ABCDEF0123456789ABCDEF";
        T_recipient <= X"FEDCBA9876543210FEDCBA9876543210";
        mac_check_start <= "100";
        WAIT FOR clk_period * 2;
        
        ASSERT (flag_equal = '0')
        REPORT "Test case 4 failed" SEVERITY error;
        
        WAIT;

    END PROCESS;

END;
