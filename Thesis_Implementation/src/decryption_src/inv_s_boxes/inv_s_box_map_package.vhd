library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

PACKAGE Inverse_S_Box_Package IS


-- Define a type 'Inv_S_Box_Array' that represents an array of 16 elements (0 to 15) where each element is a 4-bit binary value.
TYPE Inv_S_Box_Array is array (0 to 15) of STD_LOGIC_VECTOR (3 DOWNTO 0);


-- Declaration of the inverse S-Box (Inv_S1) mapping.
-- Inv_S1_Mapping contains 16 entries where each 4-bit binary string represents the inverse substituted value for its corresponding index (0 to 15).
CONSTANT Inv_S1_Mapping : Inv_S_Box_Array :=(

    "1011", "0101", "0100", "1111", -- Inverse mapping for inputs 0 to 3
    "1100", "0110", "1001", "0000", -- Inverse mapping for inputs 4 to 7
    "1101", "0011", "1110", "1000", -- Inverse mapping for inputs 8 to 11
    "0001", "1010", "0010", "0111"  -- Inverse mapping for inputs 12 to 15

);

-- Declaration of the inverse S-Box (Inv_S2) mapping.
-- Inv_S2_Mapping defines the inverse of the second substitution table (S2) similar to Inv_S1.
CONSTANT Inv_S2_Mapping : Inv_S_Box_Array :=(

    "1001", "0010", "1111", "1000", -- Inverse mapping for inputs 0 to 3
    "0000", "1100", "0011", "0110", -- Inverse mapping for inputs 4 to 7
    "0100", "1101", "0001", "1110", -- Inverse mapping for inputs 8 to 11
    "0111", "1011", "1010", "0101"  -- Inverse mapping for inputs 12 to 15

);

-- Declaration of the inverse S-Box (Inv_S3) mapping.
-- Inv_S3_Mapping provides the inverse substitution for the third substitution table (S3).
CONSTANT Inv_S3_Mapping : Inv_S_Box_Array :=(

    "1100", "0011", "0000", "1010", -- Inverse mapping for inputs 0 to 3
    "1011", "0100", "0101", "1111", -- Inverse mapping for inputs 4 to 7
    "1001", "1110", "0110", "1101", -- Inverse mapping for inputs 8 to 11
    "0010", "0111", "1000", "0001"  -- Inverse mapping for inputs 12 to 15

);

-- Declaration of the inverse S-Box (Inv_S4) mapping.
-- Inv_S4_Mapping completes the set of inverse S-Boxes, providing another set of inverse substitutions.
CONSTANT Inv_S4_Mapping : Inv_S_Box_Array :=(

    "1010", "0111", "0110", "1001", -- Inverse mapping for inputs 0 to 3
    "0001", "0010", "1100", "0101", -- Inverse mapping for inputs 4 to 7
    "0011", "0100", "1000", "1111", -- Inverse mapping for inputs 8 to 11
    "1101", "1110", "1011", "0000"  -- Inverse mapping for inputs 12 to 15

);

END PACKAGE Inverse_S_Box_Package;