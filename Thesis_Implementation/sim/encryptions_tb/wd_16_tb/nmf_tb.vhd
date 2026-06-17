LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY nmf_tb IS
END nmf_tb;

ARCHITECTURE behavior OF nmf_tb IS 

    --Component Declaration for the UUT
    COMPONENT nmf

    PORT(

         clk               : IN  STD_LOGIC;
         rst               : IN  STD_LOGIC;
         word_input        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
         mixed_word_output : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
         start             : IN  STD_LOGIC;
         done              : OUT STD_LOGIC

        );

    END COMPONENT;
    
   --Inputs
   SIGNAL clk : STD_LOGIC := '0';
   SIGNAL rst : STD_LOGIC := '0';
   SIGNAL word_input : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
   SIGNAL start     : STD_LOGIC := '0';

   --Outputs
   SIGNAL mixed_word_output : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL done : STD_LOGIC;
   --Clock period definitions
   CONSTANT clk_period : TIME := 20 ns;

BEGIN 

	--Instantiate the UUT
   uut: nmf PORT MAP (

          clk => clk,
          rst => rst,
          word_input => word_input,
          mixed_word_output => mixed_word_output,
          start => start,
          done => done

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
      word_input <= X"0000";
      start <= '1';
      WAIT FOR 8*clk_period; 
      start <= '0';
      WAIT FOR clk_period;


      REPORT "The value of signal word_input  is : " & to_hex_string(word_input) & " & the value of signal mixed_word_output is : " & to_hex_string(mixed_word_output) SEVERITY note;
	  ASSERT mixed_word_output = X"C222"
      REPORT "Mismatch detected" SEVERITY error;
      
      word_input <= X"1234";
      WAIT FOR 8*clk_period;

      REPORT "The value of signal word_input  is : " & to_hex_string(word_input) & " & the value of signal mixed_word_output is : " & to_hex_string(mixed_word_output) SEVERITY note;
	  ASSERT mixed_word_output = X"E06D"
      REPORT "Mismatch detected" SEVERITY error;
      
      REPORT "Simulation completed successfully" SEVERITY note;
      WAIT;
   END PROCESS;

END;