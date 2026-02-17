-- The Full_Decryption module performs decryption on the ciphertext using multiple decryption blocks.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY Full_Decryption IS
PORT(

    clk            : IN  STD_LOGIC;  -- Clock signal
    rst            : IN  STD_LOGIC; -- Reset signal (active high)
    dec_start      : IN  STD_LOGIC_VECTOR (  2 DOWNTO 0); -- Decryption start signal
    ciphertext     : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- Input ciphertext (128 bits)
    R_input        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- Input R for decryption
    R_Output       : OUT STD_LOGIC_VECTOR (127 DOWNTO 0); -- Output R after decryption
    key            : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- 128-bit secret key
    plaintext      : OUT STD_LOGIC_VECTOR (127 DOWNTO 0); -- Decrypted plaintext (128 bits)

    Enable_Signals : IN  STD_LOGIC_VECTOR(7 DOWNTO 0) -- Control signals to enable each decryption block

);

END Full_Decryption;

ARCHITECTURE Structure of Full_Decryption IS

TYPE Ri_array IS ARRAY (1 TO 8) OF STD_LOGIC_VECTOR(127 DOWNTO 0);  
TYPE Ro_array IS ARRAY (1 TO 8) OF STD_LOGIC_VECTOR(127 DOWNTO 0); 

SIGNAL R_i : Ri_array; -- Internal signal for input to decryption blocks
SIGNAL R_o : Ro_array; -- Internal signal for output from decryption blocks
SIGNAL interior_plaintext : STD_LOGIC_VECTOR(127 DOWNTO 0); -- Stores intermediate plaintext result during decryption

BEGIN
-- Logic to control the input to each decryption block based on the enable signals

    R_i(1) <= R_input WHEN Enable_Signals = "11111111" ELSE
              (OTHERS => '0');

    R_i(2) <= R_Input WHEN Enable_Signals = "01111111" ELSE
              R_o(1)  WHEN Enable_Signals = "11111111" ELSE
              (OTHERS => '0');

    R_i(3) <= R_Input WHEN Enable_Signals = "00111111" ELSE
              R_o(2)  WHEN (Enable_Signals = "01111111" OR Enable_Signals = "11111111") ELSE
              (OTHERS => '0');

    R_i(4) <= R_Input WHEN Enable_Signals = "00011111" ELSE
              R_o(3)  WHEN (Enable_Signals = "00111111" OR Enable_Signals = "11111111" OR Enable_Signals = "01111111") ELSE
              (OTHERS => '0');

    R_i(5) <= R_Input WHEN Enable_Signals = "00001111" ELSE
              R_o(4)  WHEN (Enable_Signals = "00111111" OR Enable_Signals = "11111111" OR Enable_Signals = "01111111" OR Enable_Signals = "00011111") ELSE
              (OTHERS => '0');

    R_i(6) <= R_Input WHEN Enable_Signals = "00000111" ELSE
              R_o(5)  WHEN (Enable_Signals = "00111111" OR Enable_Signals = "11111111" OR Enable_Signals = "01111111" OR Enable_Signals = "00011111" OR Enable_Signals = "00001111") ELSE
              (OTHERS => '0');

    R_i(7) <= R_Input WHEN Enable_Signals = "00000011" ELSE
              R_o(6)  WHEN (Enable_Signals = "00111111" OR Enable_Signals = "11111111" OR Enable_Signals = "01111111" OR Enable_Signals = "00011111" OR Enable_Signals = "00001111" OR Enable_Signals = "00000111") ELSE
              (OTHERS => '0');

    R_i(8) <= R_Input WHEN Enable_Signals = "00000001" ELSE
              R_o(7)  WHEN (Enable_Signals = "00111111" OR Enable_Signals = "11111111" OR Enable_Signals = "01111111" OR Enable_Signals = "00011111" OR Enable_Signals = "00001111" OR Enable_Signals = "00000111" OR Enable_Signals = "00000011") ELSE
              (OTHERS => '0');

-- Instantiation of each decryption block, one for each word (16 bits) of the ciphertext
-- The enable signals control which decryption block is active

     --Decryption block of the 1st word
     Decryption_block_1 : ENTITY work.Decryption

     PORT MAP(

         clk        => clk,
         rst        => rst,
         enable_out => Enable_Signals(7),
         ct_input   => ciphertext(127 DOWNTO 112),
         R_input    => R_i(1),
         key        => key,
         pt_output  => interior_plaintext(127 DOWNTO 112),
         R_output   => R_o(1)

     );

     --Decryption block of the 2nd word
 Decryption_block_2 : ENTITY work.Decryption

 PORT MAP(

     clk        => clk,
     rst        => rst,
     enable_out => Enable_Signals(6),
     ct_input   => ciphertext(111 DOWNTO 96),
     R_input    => R_i(2),
     key        => key,
     pt_output  => interior_plaintext(111 DOWNTO 96),
     R_output   => R_o(2)

 );

 --Decryption block of the 3rd word
 Decryption_block_3 : ENTITY work.Decryption

     PORT MAP(

         clk        => clk,
         rst        => rst,
         enable_out => Enable_Signals(5),
         ct_input   => ciphertext(95 DOWNTO 80),
         R_input    => R_i(3),
         key        => key,
         pt_output  => interior_plaintext(95 DOWNTO 80),
         R_output   => R_o(3)

 );

 --Decryption block of the 4th word
 Decryption_block_4 : ENTITY work.Decryption

     PORT MAP(

         clk        => clk,
         rst        => rst,
         enable_out => Enable_Signals(4),
         ct_input   => ciphertext(79 DOWNTO 64),
         R_input    => R_i(4),
         key        => key,
         pt_output  => interior_plaintext(79 DOWNTO 64),
         R_output   => R_o(4)

 );
 
 --Decryption block of the 5th word
 Decryption_block_5 : ENTITY work.Decryption

     PORT MAP(

         clk        => clk,
         rst        => rst,
         enable_out => Enable_Signals(3),
         ct_input   => ciphertext(63 DOWNTO 48),
         R_input    => R_i(5),
         key        => key,
         pt_output  => interior_plaintext(63 DOWNTO 48),
         R_output   => R_o(5)

 );    

 --Decryption block of the 6th word
 Decryption_block_6 : ENTITY work.Decryption

     PORT MAP(

         clk        => clk,
         rst        => rst,
         enable_out => Enable_Signals(2),
         ct_input   => ciphertext(47 DOWNTO 32),
         R_input    => R_i(6),
         key        => key,
         pt_output  => interior_plaintext(47 DOWNTO 32),
         R_output   => R_o(6)

 );

 --Decryption block of the 7th word
 Decryption_block_7 : ENTITY work.Decryption

     PORT MAP(

         clk        => clk,
         rst        => rst,
         enable_out => Enable_Signals(1),
         ct_input   => ciphertext(31 DOWNTO 16),
         R_input    => R_i(7),
         key        => key,
         pt_output  => interior_plaintext(31 DOWNTO 16),
         R_output   => R_o(7)

 );

 --Decryption block of the 8th word
 Decryption_block_8 : ENTITY work.Decryption

     PORT MAP(

         clk        => clk,
         rst        => rst,
         enable_out => Enable_Signals(0),
         ct_input   => ciphertext(15 DOWNTO 0),
         R_input    => R_i(8),
         key        => key,
         pt_output  => interior_plaintext(15 DOWNTO 0),
         R_output   => R_o(8)

 );

 -- Process to assign the decrypted plaintext after all decryption blocks have completed
 pt_output_process : PROCESS(clk, rst)
    
    BEGIN 

        IF rst = '1' THEN

            plaintext <= (OTHERS => '0'); -- Reset the plaintext to zero

        ELSIF RISING_EDGE(clk) THEN
-- Assign the decrypted plaintext if decryption start signal is active
            IF dec_start = "011" THEN

                plaintext <= interior_plaintext(127 DOWNTO 0);

            ELSE
                
                plaintext <= (OTHERS => '0');

            END IF;

        END IF;

    END PROCESS;

-- Process to assign the final R output after decryption
    R_output_process : PROCESS(clk, rst)
    
    BEGIN 

        IF rst = '1' THEN

            R_Output  <= (OTHERS => '0'); -- Reset the output R to zero

        ELSIF RISING_EDGE(clk) THEN
-- Assign the output R based on the last round of decryption

            IF dec_start = "011" THEN

               R_Output  <= R_o(8);

            ELSE
                
                R_Output  <= UNAFFECTED; -- No change if decryption not started

            END IF;

        END IF;

    END PROCESS;

 END Structure;