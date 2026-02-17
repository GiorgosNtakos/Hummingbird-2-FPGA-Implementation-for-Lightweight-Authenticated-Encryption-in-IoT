LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Decryption_tb IS
END Decryption_tb;

ARCHITECTURE behavior OF Decryption_tb IS 

    -- Component Declaration for the UUT
    COMPONENT Decryption
    PORT(

        clk         :   IN  STD_LOGIC;
        rst         :   IN  STD_LOGIC;
        enable_out  :   IN  STD_LOGIC;
        ct_input    :   IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
        R_input     :   IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        key         :   IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        pt_output   :   OUT STD_LOGIC_VECTOR( 15 DOWNTO 0);
        R_output    :   OUT STD_LOGIC_VECTOR(127 DOWNTO 0)

    );

    END COMPONENT;

    --Inputs
    SIGNAL clk        : STD_LOGIC := '0';
    SIGNAL rst        : STD_LOGIC := '1';
    SIGNAL ct_input   : STD_LOGIC_VECTOR( 15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_input    : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL key        : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL enable_out : STD_LOGIC := '0';

    --Outputs
    SIGNAL pt_output : STD_LOGIC_VECTOR( 15 DOWNTO 0);
    SIGNAL R_output  : STD_LOGIC_VECTOR(127 DOWNTO 0);

    -- Clock period definitions
    CONSTANT clk_period : TIME := 20 ns;
 
BEGIN

    -- Instantiate the UUT
    uut: Decryption PORT MAP (

        clk        => clk,
        rst        => rst,
        enable_out => enable_out,
        ct_input   => ct_input,
        R_input    => R_input,
        key        => key,
        pt_output  => pt_output,
        R_output   => R_output

    );

    -- Clock process definitions
    clk_process : PROCESS

    BEGIN

        clk <= '0';
        WAIT FOR clk_period/2;
        clk <= '1';
        WAIT FOR clk_period/2;

    end PROCESS;

    -- Testbench Statements
    stim_proc: PROCESS

    BEGIN

        -- Reset
        rst           <= '1';
        WAIT FOR 20 ns;

        rst <= '0';
        WAIT FOR 20 ns;

--!----------------------------------------------------------------------------------------------! Test case 1: ct_len = 16 bits !----------------------------------------------------------------------------------------------!--

        enable_out <= '1';
        -- Initialize Inputs
        ct_input <= X"EFC4"; -- Example plaintext
        R_input  <= X"3DD095167311FA1B128F630E2B7D06B8";
        key      <= (OTHERS => '0'); -- Example key

        WAIT FOR 145 * clk_period;

        REPORT "Test case 1: ct_len = 16 bits";
        REPORT "The value of signal ct_input  is : " & to_hex_string(ct_input) & ", the value of signal key is : " & to_hex_string(key) & ", the value of signal R_input is : " & to_hex_string(R_input) & " & the value of signal pt_output is : " & to_hex_string(pt_output) SEVERITY note;
	    ASSERT pt_output = X"0000"
        REPORT "Mismatch detected" SEVERITY error;

--!-----------------------------------------------------------------------------------------------! Test case 2: ct_len = 16 bits !-----------------------------------------------------------------------------------------------!--
        
        ct_input <= X"D15B"; -- Example plaintext
        R_input  <= X"77F6CC4130777C6D7B399536AFFBCCD6";
        key      <= X"23016745AB89EFCDDCFE98BA54761032"; -- Example key

        WAIT FOR 145 * clk_period;

        REPORT "Test case 2: ct_len = 16 bits";
        REPORT "The value of signal ct_input  is : " & to_hex_string(ct_input) & ", the value of signal key is : " & to_hex_string(key) & ", the value of signal R_input is : " & to_hex_string(R_input) & " & the value of signal pt_output is : " & to_hex_string(pt_output) SEVERITY note;
	    ASSERT pt_output = X"1100"
        REPORT "Mismatch detected" SEVERITY error;


        WAIT; -- will hold the simulation
    END PROCESS;

END behavior;
