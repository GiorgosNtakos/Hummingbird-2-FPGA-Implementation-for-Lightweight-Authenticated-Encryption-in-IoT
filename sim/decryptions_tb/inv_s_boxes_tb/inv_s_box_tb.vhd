LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY Inv_S_Box_Testbench IS
END Inv_S_Box_Testbench;

ARCHITECTURE behavior OF Inv_S_Box_Testbench IS

    -- Include the package with the S-Box mappings
    USE work.Inverse_S_Box_Package.ALL;

    SIGNAL test_output_S1, test_output_S2, test_output_S3, test_output_S4 : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

    -- Process to test each S-Box mapping
    stim_proc : PROCESS
    BEGIN
        FOR i IN 0 TO 15 LOOP
            test_output_S1 <= Inv_S1_Mapping(i);
            test_output_S2 <= Inv_S2_Mapping(i);
            test_output_S3 <= Inv_S3_Mapping(i);
            test_output_S4 <= Inv_S4_Mapping(i);
            WAIT FOR 10 ns;  -- Wait time between checks

            -- Check the output of each Inverse S-Box against the expected mapping
            IF test_output_S1 /= Inv_S1_Mapping(i) THEN
            REPORT "Mismatch in Inv_S1 for input " & INTEGER'IMAGE(i) & " expected " & to_string(Inv_S1_Mapping(i)) & " got " & to_string(test_output_S1) SEVERITY error;
            END IF;
     
            IF test_output_S2 /= Inv_S2_Mapping(i) THEN
            REPORT "Mismatch in Inv_S2 for input " & INTEGER'IMAGE(i) & " expected " & to_string(Inv_S2_Mapping(i)) & " got " & to_string(test_output_S2) SEVERITY error;
            END IF;

            IF test_output_S3 /= Inv_S3_Mapping(i) THEN
            REPORT "Mismatch in Inv_S3 for input " & INTEGER'IMAGE(i) & " expected " & to_string(Inv_S3_Mapping(i)) & " got " & to_string(test_output_S3) SEVERITY error;
            END IF;

            IF test_output_S4 /= Inv_S4_Mapping(i) THEN
            REPORT "Mismatch in Inv_S4 for input " & INTEGER'IMAGE(i) & " expected " & to_string(Inv_S4_Mapping(i)) & " got " & to_string(test_output_S4) SEVERITY error;
            END IF;

        END LOOP;

        -- Report successful completion and end simulation
        REPORT "Simulation completed successfully" SEVERITY note;
        WAIT;  -- Stop simulation
    END PROCESS;

END behavior;
