LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Full_Encryption_tb IS
END Full_Encryption_tb;

ARCHITECTURE behavior OF Full_Encryption_tb IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT Full_Encryption
    PORT(

        clk            : IN  STD_LOGIC;
        rst            : IN  STD_LOGIC;
        enc_start      : IN  STD_LOGIC_VECTOR (  2 DOWNTO 0);
        plaintext      : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        R_input        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        R_Output       : OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
        key            : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        ciphertext     : OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
        Enable_Signals : IN  STD_LOGIC_VECTOR(7 DOWNTO 0)

        );
    END COMPONENT;
    
    -- Signals for testbench
    SIGNAL clk            : STD_LOGIC := '0';
    SIGNAL rst            : STD_LOGIC := '0';
    SIGNAL enc_start      : STD_LOGIC_VECTOR (2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL plaintext      : STD_LOGIC_VECTOR (127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_input        : STD_LOGIC_VECTOR (127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_Output       : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL key            : STD_LOGIC_VECTOR (127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ciphertext     : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL Enable_Signals : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');

    -- Clock generation
    CONSTANT clk_period : TIME := 20 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: Full_Encryption PORT MAP (

          clk => clk,
          rst => rst,
          enc_start => enc_start,
          plaintext => plaintext,
          R_input => R_input,
          R_Output => R_Output,
          key => key,
          ciphertext => ciphertext,
          Enable_Signals => Enable_Signals

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
    stim_proc: process
    BEGIN
        -- reset process
        rst <= '1';
        WAIT FOR clk_period*2;
        rst <= '0';
        
        plaintext      <= (OTHERS => '0');
        R_input        <= X"3DD095167311FA1B128F630E2B7D06B8";
        key            <= (OTHERS => '0');
        Enable_Signals <= "11111111";
        enc_start      <= "010";
        
        WAIT FOR 620*clk_period;

        plaintext      <= X"11003322554477669988BBAADDCCFFEE";
        R_input        <= X"77F6CC4130777C6D7B399536AFFBCCD6";
        key            <= X"23016745AB89EFCDDCFE98BA54761032";

        WAIT FOR 620*clk_period;

        plaintext      <= (OTHERS => '0');
        R_input        <= X"3DD095167311FA1B128F630E2B7D06B8";
        key            <= (OTHERS => '0');
        Enable_Signals <= "00000001";
        enc_start      <= "010";

        WAIT FOR 102*clk_period;

        plaintext      <= X"00000000000000000000000000001100";
        R_input        <= X"77F6CC4130777C6D7B399536AFFBCCD6";
        key            <= X"23016745AB89EFCDDCFE98BA54761032";

        WAIT;

    END PROCESS;

END;
