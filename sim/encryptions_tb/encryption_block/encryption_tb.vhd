LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Encryption_tb IS
END Encryption_tb;

ARCHITECTURE behavior OF Encryption_tb IS 

    -- Component Declaration for the UUT
    COMPONENT Encryption
    PORT(

        clk         :   IN  STD_LOGIC;
        rst         :   IN  STD_LOGIC;
        enable_out  :   IN  STD_LOGIC;
        pt_input    :   IN  STD_LOGIC_VECTOR( 15 DOWNTO 0);
        R_input     :   IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        key         :   IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        ct_output   :   OUT STD_LOGIC_VECTOR( 15 DOWNTO 0);
        R_output    :   OUT STD_LOGIC_VECTOR(127 DOWNTO 0)

    );

    END COMPONENT;

    --Inputs
    SIGNAL clk        : STD_LOGIC := '0';
    SIGNAL rst        : STD_LOGIC := '1';
    SIGNAL pt_input   : STD_LOGIC_VECTOR( 15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_input    : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL key        : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL enable_out : STD_LOGIC := '0' ;


    --Outputs
    SIGNAL ct_output : STD_LOGIC_VECTOR( 15 DOWNTO 0);
    SIGNAL R_output  : STD_LOGIC_VECTOR(127 DOWNTO 0);

    -- Clock period definitions
    CONSTANT clk_period : TIME := 20 ns;
 
BEGIN

    -- Instantiate the UUT
    uut: Encryption PORT MAP (

        clk        => clk,
        rst        => rst,
        enable_out => enable_out,
        pt_input   => pt_input,
        R_input    => R_input,
        key        => key,
        ct_output  => ct_output,
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

--!----------------------------------------------------------------------------------------------! Test case 1: pt_len = 16 bits !----------------------------------------------------------------------------------------------!--


        enable_out <= '1';
        -- Initialize Inputs
        pt_input <= X"0000"; -- Example plaintext
        R_input  <= X"3DD095167311FA1B128F630E2B7D06B8";
        key      <= (OTHERS => '0'); -- Example key

        WAIT FOR 140 * clk_period;

        REPORT "Test case 1: pt_len = 16 bits";
        REPORT "The value of signal pt_input  is : " & to_hex_string(pt_input) & ", the value of signal key is : " & to_hex_string(key) & ", the value of signal R_input is : " & to_hex_string(R_input) & " & the value of signal ct_output is : " & to_hex_string(ct_output) SEVERITY note;
	    ASSERT ct_output = X"EFC4"
        REPORT "Mismatch detected" SEVERITY error;

--!-----------------------------------------------------------------------------------------------! Test case 2: pt_len = 16 bits !-----------------------------------------------------------------------------------------------!--
        
        pt_input <= X"1100"; -- Example plaintext
        R_input  <= X"77F6CC4130777C6D7B399536AFFBCCD6";
        key      <= X"23016745AB89EFCDDCFE98BA54761032"; -- Example key

        WAIT FOR 140 * clk_period;
        REPORT "Test case 2: pt_len = 16 bits";
        REPORT "The value of signal pt_input  is : " & to_hex_string(pt_input) & ", the value of signal key is : " & to_hex_string(key) & ", the value of signal R_input is : " & to_hex_string(R_input) & " & the value of signal ct_output is : " & to_hex_string(ct_output) SEVERITY note;
	    ASSERT ct_output = X"D15B"
        REPORT "Mismatch detected" SEVERITY error;

        WAIT; -- will hold the simulation
    END PROCESS;

END behavior;
