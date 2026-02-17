-- This entity describes the inverse nonlinear mixing and inverse S-Box transformations.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.Inverse_S_Box_Package.ALL;


ENTITY inv_nmf IS

    PORT (

        clk               : IN STD_LOGIC; -- Clock signal
        rst               : IN STD_LOGIC; -- Reset signal (active high)
        mixed_word_input  : IN  STD_LOGIC_VECTOR (15 DOWNTO 0); -- 16-bit mixed input word (result of the forward process)
        word_output       : OUT STD_LOGIC_VECTOR (15 DOWNTO 0) -- 16-bit output word after inverse S-Box and transformation
    );

END inv_nmf;

ARCHITECTURE Behavioral OF inv_nmf IS

-- Internal signal to hold intermediate XOR and rotated results
    SIGNAL x : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN

    PROCESS (clk, rst)
    BEGIN
    
        IF rst = '1' THEN

            word_output <= (OTHERS => '0'); -- Reset output word to zero
            x           <= (OTHERS => '0'); -- Reset internal signal x to zero

        ELSIF RISING_EDGE(clk) THEN

         -- Store the mixed input word in signal 'x'
            x <= mixed_word_input;

        -- Apply the reverse of the XOR and rotations performed in the forward transformation
        -- Perform this loop 3 times to "undo" the mixing effect
            FOR i IN 0 TO 2 LOOP

            -- ROR (Circural right shift) by 6 and 10 bits, followed by XOR operations to reverse the mixing
                x <= mixed_word_input XOR (x ROR 6) XOR (x ROR 10);

            END LOOP;

        -- After the mixing is reversed, apply the inverse S-Box transformations to each 4-bit segment of x
            word_output(15 DOWNTO 12) <= Inv_S1_Mapping(TO_INTEGER(UNSIGNED(x(15 DOWNTO 12)))); -- Apply Inv_S1 
            word_output(11 DOWNTO  8) <= Inv_S2_Mapping(TO_INTEGER(UNSIGNED(x(11 DOWNTO  8)))); -- Apply Inv_S2
            word_output( 7 DOWNTO  4) <= Inv_S3_Mapping(TO_INTEGER(UNSIGNED(x( 7 DOWNTO  4)))); -- Apply Inv_S3
            word_output( 3 DOWNTO  0) <= Inv_S4_Mapping(TO_INTEGER(UNSIGNED(x( 3 DOWNTO  0)))); -- Apply Inv_S4

        END IF;

    END PROCESS;

END Behavioral;
