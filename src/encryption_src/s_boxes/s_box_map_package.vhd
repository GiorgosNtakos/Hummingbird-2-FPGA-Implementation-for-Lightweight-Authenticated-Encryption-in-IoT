LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE S_Box_Package IS

-- Define a type 'S_Box_Array' that represents an array of 16 elements (0 to 15) where each element is a 4-bit binary value.
TYPE S_Box_Array is array (0 to 15) of STD_LOGIC_VECTOR (3 DOWNTO 0);

-- Declaration of the first S-Box (S1) mapping.
-- S1_Mapping contains 16 entries where each 4-bit binary string represents the substituted value for its corresponding index (0 to 15).

CONSTANT S1_Mapping: S_Box_Array :=(
    -- Mapping for inputs 0 to 3
	"0111", "1100", "1110", "1001", 

	-- Mapping for inputs 4 to 7
	"0010", "0001", "0101", "1111", 
	
	-- Mapping for inputs 8 to 11
	"1011", "0110", "1101", "0000", 
	
	-- Mapping for inputs 12 to 15
	"0100", "1000", "1010", "0011"  
);

-- Declaration of the second S-Box (S2) mapping.
-- S2_Mapping defines another substitution table similar to S1 but with different values for each index (0 to 15).

CONSTANT S2_Mapping: S_Box_Array :=(
    -- Mapping for inputs 0 to 3
	"0100", "1010", "0001", "0110",
	
	-- Mapping for inputs 4 to 7
	"1000", "1111", "0111", "1100",
	
	-- Mapping for inputs 8 to 11
	"0011", "0000", "1110", "1101",
	
	-- Mapping for inputs 12 to 15
	"0101", "1001", "1011", "0010" 
);

-- Declaration of the third S-Box (S3) mapping.
-- S3_Mapping provides a different substitution for cryptographic purposes. Each index (0 to 15) has its unique substituted 4-bit value.

CONSTANT S3_Mapping: S_Box_Array :=(
    -- Mapping for inputs 0 to 3
	"0010", "1111", "1100", "0001",
	
	-- Mapping for inputs 4 to 7
	"0101", "0110", "1010", "1101", 
	
	-- Mapping for inputs 8 to 11
	"1110", "1000", "0011", "0100",
	
	-- Mapping for inputs 12 to 15
	"0000", "1011", "1001", "0111"  
);

-- Declaration of the fourth S-Box (S4) mapping.
-- S4_Mapping completes the set of S-Boxes, providing another set of substitutions. Each index has a corresponding 4-bit substituted value.

CONSTANT S4_Mapping: S_Box_Array :=(
    -- Mapping for inputs 0 to 3
	"1111", "0100", "0101", "1000", 
	
	-- Mapping for inputs 4 to 7
	"1001", "0111", "0010", "0001", 
	
	-- Mapping for inputs 8 to 11
	"1010", "0011", "0000", "1110",
	
	-- Mapping for inputs 12 to 15
	"0110", "1100", "1101", "1011"  
);

END PACKAGE S_Box_Package;
