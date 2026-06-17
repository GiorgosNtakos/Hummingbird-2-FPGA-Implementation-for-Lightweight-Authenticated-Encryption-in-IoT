LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY inv_nmf_tb IS
END inv_nmf_tb;

ARCHITECTURE behavior OF inv_nmf_tb IS 

    --Component Declaration for the UUT
    COMPONENT inv_nmf

    PORT(

         clk               : IN  STD_LOGIC;
         rst               : IN  STD_LOGIC;
         mixed_word_input  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
         word_output       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)

        );

    END COMPONENT;


       --Inputs
   SIGNAL clk : STD_LOGIC := '0';
   SIGNAL rst : STD_LOGIC := '0';
   SIGNAL mixed_word_input : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');

   --Outputs
   SIGNAL word_output : STD_LOGIC_VECTOR(15 DOWNTO 0);

   --Clock period definitions
   CONSTANT clk_period : TIME := 20 ns;

BEGIN 

	--Instantiate the UUT
   uut: inv_nmf PORT MAP (

          clk              => clk,
          rst              => rst,
          mixed_word_input => mixed_word_input,
          word_output      => word_output

        );

   --Clock process definitions
   clk_process : PROCESS
   BEGIN

		clk <= '0';
		WAIT FOR clk_period/2;
		clk <= '1';
		WAIT FOR clk_period/2;

   END PROCESS;

    --Stimulus process
    stim_proc: PROCESS
    BEGIN      
   
         --hold reset state for 1 clock period.
         rst <= '1';
         WAIT FOR clk_period;  
         rst <= '0';  
         
         --Insert stimulus 
         mixed_word_input <= X"C222";
         WAIT FOR 6*clk_period; 
   
         REPORT "The value of signal mixed_word_input  is : " & to_hex_string(mixed_word_input) & " & the value of signal word_output is : " & to_hex_string(word_output) SEVERITY note;
         ASSERT word_output = X"0000"
         REPORT "Mismatch detected" SEVERITY error;
         
         mixed_word_input <= X"E06D";
         WAIT FOR 6*clk_period;
   
         REPORT "The value of signal mixed_word_input  is : " & to_hex_string(mixed_word_input) & " & the value of signal word_output is : " & to_hex_string(word_output) SEVERITY note;
         ASSERT word_output = X"1234"
         REPORT "Mismatch detected" SEVERITY error;
         
         REPORT "Simulation completed successfully" SEVERITY note;
         WAIT;

    END PROCESS;

END;