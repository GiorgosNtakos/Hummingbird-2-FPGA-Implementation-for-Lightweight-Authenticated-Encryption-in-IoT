LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY FSM_Controller_tb IS
END FSM_Controller_tb;

ARCHITECTURE behavior OF FSM_Controller_tb IS 

    -- Component Declaration for the Unit Under Test (UUT)
    COMPONENT FSM_Controller
    PORT(

         clk           : IN  STD_LOGIC;
         rst           : IN  STD_LOGIC;
         mode          : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
         current_state : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)

        );
    END COMPONENT;
    
    -- Inputs
    SIGNAL clk  : STD_LOGIC := '0';
    SIGNAL rst  : STD_LOGIC := '0';
    SIGNAL mode : STD_LOGIC_VECTOR(2 DOWNTO 0) := (others => '0');

    -- Outputs
    SIGNAL current_state : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- Internal signal to hold the state name
    SIGNAL state_name : STRING(1 TO 15);

    -- Clock period definitions
    CONSTANT clk_period : TIME := 20 ns;

    -- Define state_type enumeration in testbench
    TYPE state_type IS (Idle, Initialization, Encryption, Decryption, MAC_Generation, MAC_Check);

    -- Function to convert state_type to string
     FUNCTION state_to_string(state : state_type) RETURN STRING IS

        VARIABLE padded_string : STRING(1 TO 15);
        VARIABLE tmp_string : STRING(1 TO 15);

    BEGIN
        -- Initialize tmp_string to spaces
        tmp_string := (OTHERS => ' ');

        -- Assign the state name to tmp_string
        CASE state IS

            WHEN Idle => tmp_string(1 TO 4)            := "Idle";
            WHEN Initialization => tmp_string(1 TO 14) := "Initialization";
            WHEN Encryption => tmp_string(1 TO 10)     := "Encryption";
            WHEN Decryption => tmp_string(1 TO 10)     := "Decryption";
            WHEN MAC_Generation => tmp_string(1 TO 14) := "MAC_Generation";
            WHEN MAC_Check => tmp_string(1 TO 9)       := "MAC_Check";

        END CASE;

        -- Copy tmp_string to padded_string with correct length
        FOR i IN tmp_string'RANGE LOOP

            padded_string(i) := tmp_string(i);

        END LOOP;

        RETURN padded_string;

    END FUNCTION;

    -- Function to convert STD_LOGIC_VECTOR to state_type
    FUNCTION slv_to_state(slv : STD_LOGIC_VECTOR(2 DOWNTO 0)) RETURN state_type IS
    BEGIN

        CASE slv IS

            WHEN "000" => RETURN Idle;
            WHEN "001" => RETURN Initialization;
            WHEN "010" => RETURN Encryption;
            WHEN "011" => RETURN Decryption;
            WHEN "100" => RETURN MAC_Generation;
            WHEN "101" => RETURN MAC_Check;
            WHEN OTHERS => RETURN Idle;

        END CASE;
    END FUNCTION;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut: FSM_Controller PORT MAP (

          clk => clk,
          rst => rst,
          mode => mode,
          current_state => current_state

        );

    -- Clock process definitions
    clk_process : PROCESS
    BEGIN

        clk <= '0';
        WAIT FOR clk_period/2;
        clk <= '1';
        WAIT FOR clk_period/2;

    END PROCESS;

    -- Convert current_state to state_name
    PROCESS(current_state)

    VARIABLE state_str : STRING(1 TO 15);

    BEGIN

        state_str := state_to_string(slv_to_state(current_state));
        state_name <= state_str;

    END PROCESS;

    -- Stimulus process
    stim_proc: PROCESS
    BEGIN		
        -- hold reset state for 100 ns.
        rst <= '1';
        WAIT FOR 20 ns;	
        
        rst <= '0';

        -- Initialize Inputs
        WAIT FOR clk_period*2;
        
        -- Test mode "000" - Idle
        mode <= "000";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "000"
        REPORT "Mismatch detected" SEVERITY error;
        
        -- Test mode "001" - Initialization
        mode <= "001";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "001"
        REPORT "Mismatch detected" SEVERITY error;
        
        -- Test mode "010" - Encryption
        mode <= "010";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "010"
        REPORT "Mismatch detected" SEVERITY error;
        
        -- Test mode "011" - Decryption --!false (need to genarate mac then go to idle then to init and then decryption)
        mode <= "011";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "010"
        REPORT "Mismatch detected" SEVERITY error;
        
        -- Test mode "100" - MAC Generation
        mode <= "100";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "100"
        REPORT "Mismatch detected" SEVERITY error;
        
        -- Test mode "101" - MAC Check --!false (prev state was encryption and on ecnryption we do not have mac_check)
        mode <= "101";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "100"
        REPORT "Mismatch detected" SEVERITY error;

        -- Test mode "000" - Idle
        mode <= "000";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "000"
        REPORT "Mismatch detected" SEVERITY error;
        
        -- Test mode "001" - Initialization
        mode <= "001";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "001"
        REPORT "Mismatch detected" SEVERITY error;

        -- Test mode "011" - Decryption
        mode <= "011";
        WAIT FOR clk_period*2;
 
        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
        ASSERT current_state = "011"
        REPORT "Mismatch detected" SEVERITY error;
         
        -- Test mode "100" - MAC Generation
        mode <= "100";
        WAIT FOR clk_period*2;
 
        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
        ASSERT current_state = "100"
        REPORT "Mismatch detected" SEVERITY error;
         
        -- Test mode "101" - MAC Check
        mode <= "101";
        WAIT FOR clk_period*2;
 
        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
        ASSERT current_state = "101"
        REPORT "Mismatch detected" SEVERITY error;
        

        mode <= "110";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "101"
        REPORT "Mismatch detected" SEVERITY error;

        mode <= "111";
        WAIT FOR clk_period*2;

        REPORT "The value of signal mode  is : " & to_string(mode) & " & the value of signal current_state is : " & to_string(current_state) SEVERITY note;
	    ASSERT current_state = "101"
        REPORT "Mismatch detected" SEVERITY error;
        
        -- Insert stimulus here
        WAIT;

    END PROCESS;

END;
