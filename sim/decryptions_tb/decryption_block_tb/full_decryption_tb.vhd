LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Full_Decryption_tb IS
END Full_Decryption_tb;

ARCHITECTURE behavior OF Full_Decryption_tb IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT Full_Decryption
    PORT(

        clk            : IN  STD_LOGIC;
        rst            : IN  STD_LOGIC;
        dec_start      : IN  STD_LOGIC_VECTOR (  2 DOWNTO 0);
        ciphertext     : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        R_input        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        R_Output       : OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
        key            : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
        plaintext      : OUT STD_LOGIC_VECTOR (127 DOWNTO 0);
        Enable_Signals : IN  STD_LOGIC_VECTOR(7 DOWNTO 0)

        );
    END COMPONENT;
    
    -- Signals for testbench
    SIGNAL clk            : STD_LOGIC := '0';
    SIGNAL rst            : STD_LOGIC := '0';
    SIGNAL dec_start      : STD_LOGIC_VECTOR (2 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ciphertext     : STD_LOGIC_VECTOR (127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_input        : STD_LOGIC_VECTOR (127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_Output       : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL key            : STD_LOGIC_VECTOR (127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL plaintext      : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL Enable_Signals : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');

    -- Clock generation
    CONSTANT clk_period : TIME := 20 ns;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: Full_Decryption PORT MAP (

          clk => clk,
          rst => rst,
          dec_start => dec_start,
          ciphertext => ciphertext,
          R_input => R_input,
          R_Output => R_Output,
          key => key,
          plaintext => plaintext,
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
        
        ciphertext     <= X"EFC4A887054F91A946578144256ECF3A";
        R_input        <= X"3DD095167311FA1B128F630E2B7D06B8";
        key            <= (OTHERS => '0');
        Enable_Signals <= "11111111";
        dec_start      <= "011";
        
       
        WAIT FOR 800*clk_period;

        ciphertext     <= X"D15BADF81423F420B1BAC2542945383D";
        R_input        <= X"77F6CC4130777C6D7B399536AFFBCCD6";
        key            <= X"23016745AB89EFCDDCFE98BA54761032";
        Enable_Signals <= "11111111";
        dec_start      <= "011";

        WAIT FOR 800*clk_period; 

        ciphertext     <= X"0000000000000000000000000000EFC4";
        R_input        <= X"3DD095167311FA1B128F630E2B7D06B8";
        key            <= (OTHERS => '0');
        Enable_Signals <= "00000001";
        dec_start      <= "011";

        WAIT FOR 500*clk_period;

        ciphertext     <= X"0000000000000000000000000000D15B";
        R_input        <= X"77F6CC4130777C6D7B399536AFFBCCD6";
        key            <= X"23016745AB89EFCDDCFE98BA54761032";

        WAIT;

    END PROCESS;

END;
