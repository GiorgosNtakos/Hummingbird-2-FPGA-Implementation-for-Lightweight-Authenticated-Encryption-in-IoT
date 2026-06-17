LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY wd_16_tb IS
END wd_16_tb;

ARCHITECTURE behavior OF wd_16_tb IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT wd_16
    PORT(

         clk         : IN  STD_LOGIC;
         rst         : IN  STD_LOGIC;
         data_input  : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
         key         : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
         data_output : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
         start       : IN STD_LOGIC;
         done        : OUT STD_LOGIC

         );
    END COMPONENT;
    
   --Inputs
   SIGNAL clk        : STD_LOGIC := '0';
   SIGNAL rst        : STD_LOGIC := '0';
   SIGNAL data_input : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
   SIGNAL key        : STD_LOGIC_VECTOR(63 DOWNTO 0) := (others => '0');
   SIGNAL start      : STD_LOGIC := '0';
   --Outputs
   SIGNAL data_output : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL done        : STD_LOGIC;
   --Clock period definitions
   CONSTANT clk_period : TIME := 20 ns;

BEGIN 

	-- Instantiate the UUT
   uut: wd_16 PORT MAP (

          clk         => clk,
          rst         => rst,
          data_input  => data_input,
          key         => key,
          data_output => data_output,
          start       => start,
          done        => done

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
      start <= '1';
      key <= X"0000000000000000";
      data_input <= X"0000";
      WAIT FOR 30*clk_period;
      start <= '0';
      WAIT FOR clk_period;

      REPORT "The value of signal data_input  is : " & to_hex_string(data_input) & ", the value of signal key is : " & to_hex_string(key) & " & the value of signal data_output is : " & to_hex_string(data_output) SEVERITY note;
	   ASSERT data_output = X"A8AE"
      REPORT "Mismatch detected" SEVERITY error;

      start <= '1';
      key <= X"0123456789ABCDEF";
      data_input <= X"1234";
      WAIT FOR 30*clk_period;
      start <= '0';  
      WAIT FOR clk_period;
      REPORT "The value of signal data_input  is : " & to_hex_string(data_input) & ", the value of signal key is : " & to_hex_string(key) & " & the value of signal data_output is : " & to_hex_string(data_output) SEVERITY note;
	   ASSERT data_output = X"727B"
      REPORT "Mismatch detected" SEVERITY error;
      
      REPORT "Simulation completed successfully" SEVERITY note;

      WAIT;
   END PROCESS;

END;