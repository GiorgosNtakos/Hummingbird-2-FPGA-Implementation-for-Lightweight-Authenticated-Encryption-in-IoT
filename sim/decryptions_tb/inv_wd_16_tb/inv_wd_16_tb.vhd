LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY inv_wd_16_tb IS
END inv_wd_16_tb;

ARCHITECTURE behavior OF inv_wd_16_tb IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT inv_wd_16
    PORT(

         clk             : IN  STD_LOGIC;
         rst             : IN  STD_LOGIC;
         inv_data_input  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
         key             : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
         inv_data_output : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)

        );
    END COMPONENT;
    
   --Inputs
   SIGNAL clk            : STD_LOGIC := '0';
   SIGNAL rst            : STD_LOGIC := '0';
   SIGNAL inv_data_input : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
   SIGNAL key            : STD_LOGIC_VECTOR(63 DOWNTO 0) := (others => '0');

   --Outputs
   SIGNAL inv_data_output : STD_LOGIC_VECTOR(15 DOWNTO 0);

   --Clock period definitions
   CONSTANT clk_period : TIME := 20 ns;

BEGIN 

	-- Instantiate the UUT
   uut: inv_wd_16 PORT MAP (

          clk             => clk,
          rst             => rst,
          inv_data_input  => inv_data_input,
          key             => key,
          inv_data_output => inv_data_output

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
      -- hold reset state for 100 ns.
      rst <= '1';
      WAIT FOR 20 ns;  
      rst <= '0';  
      
      -- Insert stimulus here 
      key <= X"0000000000000000";
      inv_data_input <= X"A8AE";
      WAIT FOR 28*clk_period;

      REPORT "The value of signal inv_data_input  is : " & to_hex_string(inv_data_input) & ", the value of signal key is : " & to_hex_string(key) & " & the value of signal inv_data_output is : " & to_hex_string(inv_data_output) SEVERITY note;
	   ASSERT inv_data_output = X"0000"
      REPORT "Mismatch detected" SEVERITY error;
      
      key <= X"0123456789ABCDEF";
      inv_data_input <= X"727B";
      WAIT FOR 28*clk_period;

      REPORT "The value of signal inv_data_input  is : " & to_hex_string(inv_data_input) & ", the value of signal key is : " & to_hex_string(key) & " & the value of signal inv_data_output is : " & to_hex_string(inv_data_output) SEVERITY note;
	   ASSERT inv_data_output = X"1234"
      REPORT "Mismatch detected" SEVERITY error;
      
      REPORT "Simulation completed successfully" SEVERITY note;

      WAIT;
   END PROCESS;

END;