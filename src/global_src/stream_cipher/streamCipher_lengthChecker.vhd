-- SC_LC (Signal Control - Length Control) handles the control of signal enables and text length segmentation
-- based on the input text length and integrity signal.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY SC_LC IS
PORT(

    text_len           : IN  INTEGER RANGE 1 TO 128; -- Text length input 
    integrity          : IN  STD_LOGIC; -- Integrity signal (used for integrity checks)
    Enable_Signals_Enc : OUT STD_LOGIC_VECTOR(  7 DOWNTO 0); -- Enable signals for encryption blocks
    Enable_Signals_Dec : OUT STD_LOGIC_VECTOR(  7 DOWNTO 0); -- Enable signals for decryption blocks
    Enable_Signals_Mac : OUT STD_LOGIC_VECTOR(  7 DOWNTO 0); -- Enable signals for MAC generation
    n                  : OUT INTEGER RANGE 1 TO  8; -- Number for n MAC Tags to compute

-- Outputs to represent lengths of each 16-bit block
    text_len_1         : OUT INTEGER RANGE 1 TO 16;
    text_len_2         : OUT INTEGER RANGE 1 TO 16;
    text_len_3         : OUT INTEGER RANGE 1 TO 16;
    text_len_4         : OUT INTEGER RANGE 1 TO 16;
    text_len_5         : OUT INTEGER RANGE 1 TO 16;
    text_len_6         : OUT INTEGER RANGE 1 TO 16;
    text_len_7         : OUT INTEGER RANGE 1 TO 16;
    text_len_8         : OUT INTEGER RANGE 1 TO 16;

-- Output to represent modulus of the text length divided by 16 (used for partial block handling)
    text_mod           : OUT INTEGER RANGE 0 TO 15

);

END SC_LC;

ARCHITECTURE Behavioral OF SC_LC IS
BEGIN

 -- Calculate the modulus of the text length with respect to 16 
text_mod <=  text_len mod 16;

-- Main process that evaluates the text length and integrity signal to set the enable signals, 
    -- block lengths, and the number of tags (n).
    PROCESS(text_len, integrity)
    BEGIN

        CASE text_len IS

            WHEN 113 TO 128 =>
                Enable_Signals_Mac <= "11111111";
                n <= 8;
                text_len_1       <= 16;
                text_len_2       <= 16;
                text_len_3       <= 16;
                text_len_4       <= 16;
                text_len_5       <= 16;
                text_len_6       <= 16;
                text_len_7       <= 16;
                text_len_8       <= (text_len - 112);

                IF integrity = '0' THEN

                    Enable_Signals_Dec <= "11111111";

                ELSIF integrity = '1' THEN

                    Enable_Signals_Dec <= "01111111";

                END IF;
                
                IF text_len = 128 THEN

                    Enable_Signals_Enc <= (OTHERS => '1');

                ELSE

                    Enable_Signals_Enc <= "01111111";

                END IF;

            WHEN 97 TO 112 =>
                Enable_Signals_Mac <= "11111110";
                n <= 7;
                text_len_1       <= 16;
                text_len_2       <= 16;
                text_len_3       <= 16;
                text_len_4       <= 16;
                text_len_5       <= 16;
                text_len_6       <= 16;
                text_len_7       <= (text_len - 96);
                text_len_8       <= 16;

                IF integrity = '0' THEN

                    Enable_Signals_Dec <= "01111111";

                ELSIF integrity = '1' THEN

                    Enable_Signals_Dec <= "00111111";

                END IF;

                IF text_len = 112 THEN

                    Enable_Signals_Enc <= "01111111";

                ELSE

                    Enable_Signals_Enc <= "00111111";

                END IF;

            WHEN 81 TO 96 =>
                Enable_Signals_Mac <= "11111100";
                n <= 6;
                text_len_1       <= 16;
                text_len_2       <= 16;
                text_len_3       <= 16;
                text_len_4       <= 16;
                text_len_5       <= 16;
                text_len_6       <= (text_len - 80);
                text_len_7       <= 16;
                text_len_8       <= 16;

                IF integrity = '0' THEN

                    Enable_Signals_Dec <= "00111111";

                ELSIF integrity = '1' THEN

                    Enable_Signals_Dec <= "00011111";

                END IF;

                IF text_len = 96 THEN

                    Enable_Signals_Enc <= "00111111";

                ELSE

                    Enable_Signals_Enc <= "00011111";

                END IF;


            WHEN 65 TO 80 =>
                Enable_Signals_Mac <= "11111000";
                n <= 5;
                text_len_1       <= 16;
                text_len_2       <= 16;
                text_len_3       <= 16;
                text_len_4       <= 16;
                text_len_5       <= (text_len - 64);
                text_len_6       <= 16;
                text_len_7       <= 16;
                text_len_8       <= 16;

                IF integrity = '0' THEN

                    Enable_Signals_Dec <= "00011111";

                ELSIF integrity = '1' THEN

                    Enable_Signals_Dec <= "00001111";

                END IF;

                IF text_len = 80 THEN

                    Enable_Signals_Enc <= "00011111";

                ELSE

                    Enable_Signals_Enc <= "00001111";

                END IF;

            WHEN 49 TO 64 =>
                Enable_Signals_Mac <= "11110000";
                n <= 4;
                text_len_1       <= 16;
                text_len_2       <= 16;
                text_len_3       <= 16;
                text_len_4       <= (text_len - 48);
                text_len_5       <= 16;
                text_len_6       <= 16;
                text_len_7       <= 16;
                text_len_8       <= 16;

                IF integrity = '0' THEN

                    Enable_Signals_Dec <= "00001111";

                ELSIF integrity = '1' THEN

                    Enable_Signals_Dec <= "00000111";

                END IF;

                
                IF text_len = 64 THEN

                    Enable_Signals_Enc <= "00001111";

                ELSE

                    Enable_Signals_Enc <= "00000111";

                END IF;

            WHEN 33 TO 48 =>
                Enable_Signals_Mac <= "11100000";
                n <= 3;
                text_len_1       <= 16;
                text_len_2       <= 16;
                text_len_3       <= (text_len - 32);
                text_len_4       <= 16;
                text_len_5       <= 16;
                text_len_6       <= 16;
                text_len_7       <= 16;
                text_len_8       <= 16;

                IF integrity = '0' THEN

                    Enable_Signals_Dec <= "00000111";

                ELSIF integrity = '1' THEN

                    Enable_Signals_Dec <= "00000011";

                END IF;

                IF text_len = 48 THEN

                    Enable_Signals_Enc <= "00000111";

                ELSE

                    Enable_Signals_Enc <= "00000011";

                END IF;

            WHEN 17 TO 32 =>
                Enable_Signals_Mac <= "11000000";
                n <= 2;
                text_len_1       <= 16;
                text_len_2       <= (text_len - 16);
                text_len_3       <= 16;
                text_len_4       <= 16;
                text_len_5       <= 16;
                text_len_6       <= 16;
                text_len_7       <= 16;
                text_len_8       <= 16;

                IF integrity = '0' THEN

                    Enable_Signals_Dec <= "00000011";

                ELSIF integrity = '1' THEN

                    Enable_Signals_Dec <= "00000001";

                END IF;

                IF text_len = 32 THEN

                    Enable_Signals_Enc <= "00000011";

                ELSE

                    Enable_Signals_Enc <= "00000001";

                END IF;

            WHEN 1 TO 16 =>
                Enable_Signals_Mac <= "10000000";
                n <= 1;
                text_len_1       <= text_len;
                text_len_2       <= 16;
                text_len_3       <= 16;
                text_len_4       <= 16;
                text_len_5       <= 16;
                text_len_6       <= 16;
                text_len_7       <= 16;
                text_len_8       <= 16;

                IF integrity = '0' THEN

                    Enable_Signals_Dec <= "00000001";

                ELSIF integrity = '1' THEN

                    Enable_Signals_Dec <= "00000000";

                END IF;

                IF text_len = 16 THEN

                    Enable_Signals_Enc <= "00000001";

                ELSE

                    Enable_Signals_Enc <= "00000000";

                END IF;

            WHEN OTHERS =>
                Enable_Signals_Mac <= "00000000";
                Enable_Signals_Enc <= "00000000";
                Enable_Signals_Dec <= "00000000";
                n <= 8;
                text_len_1       <= 16;
                text_len_2       <= 16;
                text_len_3       <= 16;
                text_len_4       <= 16;
                text_len_5       <= 16;
                text_len_6       <= 16;
                text_len_7       <= 16;
                text_len_8       <= 16;

        END CASE;

    END PROCESS;

END Behavioral;
