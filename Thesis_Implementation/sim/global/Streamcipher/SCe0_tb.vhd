LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.S_Box_Package.ALL;

ENTITY Streamchipher_tb IS
END Streamchipher_tb;

ARCHITECTURE behavior OF Streamchipher_tb IS

    -- Component Declaration for the UUT
    COMPONENT Streamchipher
    PORT(

        clk             : IN  STD_LOGIC;
        rst             : IN  STD_LOGIC;
        text_input      : IN  STD_LOGIC_VECTOR (15 DOWNTO 0);
        text_len        : IN  INTEGER RANGE 1 TO 16;
        R_input         : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        key             : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        text_xor_output : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        R_output        : OUT STD_LOGIC_VECTOR (127 DOWNTO 0)

    );
    END COMPONENT;

    -- Signals to connect to UUT
    SIGNAL clk             : STD_LOGIC := '0';
    SIGNAL rst             : STD_LOGIC := '0';
    SIGNAL text_input      : STD_LOGIC_VECTOR( 15 DOWNTO 0) := (OTHERS => '0');
    SIGNAL text_len        : INTEGER RANGE 1 TO 16 := 16;
    SIGNAL R_input         : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL key             : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL text_xor_output : STD_LOGIC_VECTOR( 15 DOWNTO 0);
    SIGNAL R_output        : STD_LOGIC_VECTOR(127 DOWNTO 0);

    -- Clock period definitions
    CONSTANT clk_period : TIME := 20 ns;

BEGIN

    -- Instantiate the UUT
    uut: Streamchipher PORT MAP (

          clk             => clk,
          rst             => rst,
          text_input      => text_input,
          text_len        => text_len,
          R_input         => R_input,
          key             => key,
          text_xor_output => text_xor_output,
          R_output        => R_output
          
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
        WAIT FOR 20 ns;  
        
        rst <= '0';
        WAIT FOR clk_period*2;
        
        -- insert stimulus here
        text_input <= X"0000";
        text_len   <= 15;
        R_input  <= X"3DD095167311FA1B128F630E2B7D06B8";
        key      <= (OTHERS => '0');
        
        WAIT FOR clk_period*60;

        text_input <= X"1100";
        text_len <= 15;
        R_input <= X"77F6CC4130777C6D7B399536AFFBCCD6";
        key <= X"23016745AB89EFCDDCFE98BA54761032";
        
        WAIT FOR clk_period*60;

        text_input <= X"6FC4";
        text_len <= 15;
        R_input <= X"3DD095167311FA1B128F630E2B7D06B8";
        key <= (OTHERS => '0');
        
        WAIT FOR clk_period*60;

        text_input <= X"5B5B";
        text_len <= 15;
        R_input <= X"77F6CC4130777C6D7B399536AFFBCCD6";
        key <= X"23016745AB89EFCDDCFE98BA54761032";
        
        -- Add more test vectors as needed
        WAIT;
    END PROCESS;

END;
