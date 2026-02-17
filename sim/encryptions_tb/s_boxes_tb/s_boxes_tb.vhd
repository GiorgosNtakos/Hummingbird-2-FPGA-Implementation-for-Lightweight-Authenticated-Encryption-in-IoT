LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.S_Box_Package.all;

ENTITY tb_All_S_Boxes IS
END tb_All_S_Boxes;

ARCHITECTURE behavior OF tb_All_S_Boxes IS 

-- Component declaration for the Generic S-Box.
    COMPONENT Generic_S_Box

    GENERIC(s_box_mapping: S_Box_Array);

    PORT(
        input  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        output : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    END COMPONENT;
   
   -- Declare a signal for input and for each S-Box output. Initialize input to 0.
    SIGNAL input : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
    SIGNAL S1_output, S2_output, S3_output, S4_output : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

-- Instantiate the S-Boxes with their respective mappings
    S1: Generic_S_Box GENERIC MAP (s_box_mapping => S1_Mapping) PORT MAP (input => input, output => S1_output);
    S2: Generic_S_Box GENERIC MAP (s_box_mapping => S2_Mapping) PORT MAP (input => input, output => S2_output);
    S3: Generic_S_Box GENERIC MAP (s_box_mapping => S3_Mapping) PORT MAP (input => input, output => S3_output);
    S4: Generic_S_Box GENERIC MAP (s_box_mapping => S4_Mapping) PORT MAP (input => input, output => S4_output);

-- Stimulus process: generate inputs and check outputs
    stim_proc: PROCESS
    BEGIN   
-- Loop through all possible 4-bit inputs	
        FOR i IN 0 TO 15 LOOP
            input <= STD_LOGIC_VECTOR(TO_UNSIGNED(i, 4));
            WAIT FOR 10 ns; -- Wait for outputs to stabilize
            
            -- Check the output of each S-Box against the expected mapping
            IF S1_output /= S1_Mapping(i) THEN
                REPORT "Mismatch in S1 for input " & INTEGER'IMAGE(i) & " expected " & to_string(S1_Mapping(i)) & " got " & to_string(S1_output) SEVERITY error;
            END IF;
			
			IF S2_output /= S2_Mapping(i) THEN
                REPORT "Mismatch in S2 for input " & INTEGER'IMAGE(i) & " expected " & to_string(S2_Mapping(i)) & " got " & to_string(S2_output) SEVERITY error;
            END IF;
			
			IF S3_output /= S3_Mapping(i) THEN
                REPORT "Mismatch in S3 for input " & INTEGER'IMAGE(i) & " expected " & to_string(S3_Mapping(i)) & " got " & to_string(S3_output) SEVERITY error;
            END IF;
			
			IF S4_output /= S4_Mapping(i) THEN
                REPORT "Mismatch in S4 for input " & INTEGER'IMAGE(i) & " expected " & to_string(S4_Mapping(i)) & " got " & to_string(S4_output) SEVERITY error;
            END IF;
                      
        END LOOP;
        
		-- Report successful completion and end simulation
        REPORT "Simulation completed successfully" SEVERITY note;
        WAIT;
    END PROCESS;

END behavior;
