-- This entity describes a hardware module that applies nonlinear transformations using S-Boxes

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.S_Box_Package.ALL;

ENTITY nmf IS
    
    PORT (

        --inputs
        clk               :  IN STD_ULOGIC; -- Clock signal
        rst               :  IN STD_ULOGIC; -- Reset signal (active high)
        word_input        :  IN STD_ULOGIC_VECTOR (15 DOWNTO 0); -- 16-bit input word
        start             :  IN STD_ULOGIC;

        --outputs
        mixed_word_output :  OUT STD_ULOGIC_VECTOR (15 DOWNTO 0); -- 16-bit transformed output
        done              :  OUT STD_ULOGIC

    );

END nmf;

ARCHITECTURE Behavioral OF nmf IS

    -- Internal signal to hold the output of the 4 S-Boxes.
    -- The 16-bit signal is split into four 4-bit sections, each representing the output of an S-Box. 
    SIGNAL Sbox_out: STD_ULOGIC_VECTOR(15 DOWNTO 0);

    BEGIN

        PROCESS (clk, rst)
        BEGIN

            IF rst = '1' THEN
                done <= '0';
                Sbox_out <= (OTHERS => '0'); -- Reset all bits of Sbox_out to '0'
                
            ELSIF RISING_EDGE(clk) THEN
            IF start = '1' THEN

                -- For each 4-bit nibble of the input, apply the corresponding S-Box mapping
            
            -- S1_Mapping: Substitutes the 4 most significant bits (15 down to 12)
                Sbox_out(15 DOWNTO 12) <= S1_Mapping(TO_INTEGER(UNSIGNED(word_input(15 DOWNTO 12))));

            -- S2_Mapping: Substitutes the next 4 bits (11 down to 8)
                Sbox_out(11 DOWNTO  8) <= S2_Mapping(TO_INTEGER(UNSIGNED(word_input(11 DOWNTO  8))));

            -- S3_Mapping: Substitutes the next 4 bits (7 down to 4)
                Sbox_out( 7 DOWNTO  4) <= S3_Mapping(TO_INTEGER(UNSIGNED(word_input( 7 DOWNTO  4))));

            -- S4_Mapping: Substitutes the 4 least significant bits (3 down to 0)
                Sbox_out( 3 DOWNTO  0) <= S4_Mapping(TO_INTEGER(UNSIGNED(word_input( 3 DOWNTO  0))));

                done <= '1';
            ELSE 
            
                done <= '0';

            END IF;

        END IF;

        END PROCESS;

        -- Perform mixing operation on the output of the S-Boxes
        -- The output is a combination of the S-Box results XORed with two rotated versions of itself
        -- ROL 6: Circular left shift  by 6 bits
        -- ROL 10: Circular left shift  by 10 bits
        mixed_word_output <= Sbox_out XOR (Sbox_out ROL 6) XOR (Sbox_out ROL 10);

END Behavioral;