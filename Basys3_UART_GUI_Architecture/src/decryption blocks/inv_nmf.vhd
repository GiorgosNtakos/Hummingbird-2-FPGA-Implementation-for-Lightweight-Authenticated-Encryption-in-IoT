LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.Inverse_S_Box_Package.ALL;

ENTITY inv_nmf IS
    PORT(

        mixed_word_input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        word_output      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)

    );
END ENTITY inv_nmf;

ARCHITECTURE Behavioral OF inv_nmf IS

    SIGNAL x0 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL x1 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL x2 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL x3 : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL inv_sbox_out : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

    -------------------------------------------------
    -- INVERSE LINEAR MIXING
    -------------------------------------------------

    x0 <= mixed_word_input;
    x1 <= x0 XOR (x0 ROR 6) XOR (x0 ROR 10);
    x2 <= x1 XOR (x1 ROR 6) XOR (x1 ROR 10);
    x3 <= x2 XOR (x2 ROR 6) XOR (x2 ROR 10);

    -------------------------------------------------
    -- INVERSE S-BOXES
    -------------------------------------------------
    inv_sbox_out(15 DOWNTO 12) <= Inv_S1_Mapping(TO_INTEGER(UNSIGNED(x3(15 DOWNTO 12)))); -- Apply Inv_S1 
    inv_sbox_out(11 DOWNTO  8) <= Inv_S2_Mapping(TO_INTEGER(UNSIGNED(x3(11 DOWNTO  8)))); -- Apply Inv_S2
    inv_sbox_out( 7 DOWNTO  4) <= Inv_S3_Mapping(TO_INTEGER(UNSIGNED(x3( 7 DOWNTO  4)))); -- Apply Inv_S3
    inv_sbox_out( 3 DOWNTO  0) <= Inv_S4_Mapping(TO_INTEGER(UNSIGNED(x3( 3 DOWNTO  0)))); -- Apply Inv_S4

    -------------------------------------------------
    -- OUTPUT
    -------------------------------------------------
    word_output <= inv_sbox_out;

END ARCHITECTURE Behavioral;