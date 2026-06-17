LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Streamchipher IS
PORT(
    text_input      : IN  STD_LOGIC_VECTOR (15 DOWNTO 0);  -- Input text (16 bits)
    text_len        : IN  INTEGER RANGE 1 TO 16;           -- Length of valid text (range 1 to 16)
    sc_zero         : IN  STD_LOGIC_VECTOR (15 DOWNTO 0);  -- Stream cipher output to be XORed with text
    text_xor_output : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)   -- XORed output (final encrypted/decrypted text)
);
END Streamchipher;

ARCHITECTURE Combinational OF Streamchipher IS
    SIGNAL internal_xor_text : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Intermediate signal holding XORed result
BEGIN

    -- XOR operation between stream cipher output (`sc_zero`) and input text (`text_input`)
    -- This operation is performed on all 16 bits of input text.
    internal_xor_text <= sc_zero XOR text_input;

    -- Combinational assignment for the `text_xor_output` based on `text_len`
    -- For valid bits, assign the XOR result. For remaining bits, assign '0'.
    PROCESS (internal_xor_text, text_len)
    BEGIN
        FOR i IN 0 TO 15 LOOP
            IF i < text_len THEN
                text_xor_output(i) <= internal_xor_text(i);
            ELSE
                text_xor_output(i) <= '0';
            END IF;
        END LOOP;
    END PROCESS;

END Combinational;
