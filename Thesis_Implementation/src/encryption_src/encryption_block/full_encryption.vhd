-- This module handles the complete encryption process, including message authentication, message integrity checks and streaming cipher operations.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Full_Encryption IS
PORT(

    clk            : IN  STD_LOGIC; -- Clock signal
    rst            : IN  STD_LOGIC; -- Reset signal (active high)
    enc_mac_start  : IN  STD_LOGIC_VECTOR (  2 DOWNTO 0); -- Signal to initiate encryption or MAC generation
    text_len       : IN INTEGER RANGE 1 TO 128; -- Text length 
    plaintext      : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- 128-bit plaintext input
    R_input        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- R Internal state input for encryption
    R_dec_input    : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- R Internal state input for decryption (for MAC check)
    key            : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- 128-bit secret key
    ciphertext     : OUT STD_LOGIC_VECTOR (127 DOWNTO 0);  -- 128-bit ciphertext output
    Enable_Signals : IN STD_LOGIC_VECTOR(7 DOWNTO 0); -- Enable signals for various encryption/mac stages
    integrity      : IN STD_LOGIC; -- Signal for integrity checks
    n              : IN INTEGER RANGE 1 TO 8; -- Parameter for mac rounds
    iv             : IN STD_LOGIC_VECTOR(63 DOWNTO 0); -- Initialization vector for mac operation
    text_mod       : IN INTEGER RANGE 0 TO 15; -- Text modulus (modulo value used in encryption)
    streamchipher_input : IN STD_LOGIC_VECTOR(15 DOWNTO 0); -- Input for stream cipher
    sc_ct_zero     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- Stream cipher output
    R_integrity    : OUT STD_LOGIC_VECTOR(127 DOWNTO 0) -- Internal state for integrity checks


);

END Full_Encryption;

ARCHITECTURE Structure of Full_Encryption IS

TYPE Ri_array IS ARRAY (1 TO 11) OF STD_LOGIC_VECTOR(127 DOWNTO 0);
TYPE Ro_array IS ARRAY (1 TO 11) OF STD_LOGIC_VECTOR(127 DOWNTO 0);

-- Signals for storing intermediate states
SIGNAL R_i : Ri_array; -- Internal state before encryption/mac
SIGNAL R_o : Ro_array; -- Internal state after encryption/mac
SIGNAL interior_ciphertext : STD_LOGIC_VECTOR(127 DOWNTO 0); -- Internal ciphertext storage
SIGNAL E_1, E_2, E_3, E_4, E_5, E_6, E_7, E_8, E_9, E_10, E_11 : STD_LOGIC_VECTOR(15 DOWNTO 0); --Inputs of Encryptions blocks (E_4-E_11 used to compute the final outputs for encryption/mac, E_1 used only for MAC, E_2 used for MAC or Streamchipher & E_3 used for MAC or for Integrity
SIGNAL enable_signal_buf : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Buffer for enable signals

-- Pipeline registers
SIGNAL R_i_reg   : Ri_array;

-- Signals for stream cipher control
SIGNAL enable_sc : STD_LOGIC; -- Enable signal for stream cipher
SIGNAL sc_interior_zero : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Stream cipher internal result
SIGNAL No_output        : STD_LOGIC_VECTOR(15 DOWNTO 0); -- Placeholder for unused ciphertext output
SIGNAL R_mac_input      : STD_LOGIC_VECTOR(127 DOWNTO 0); -- Signal for MAC's R input

BEGIN

-- Buffer process for enable signals
    process(clk, rst)
    BEGIN

        IF rst = '1' THEN

            enable_signal_buf <= (OTHERS => '0'); -- Reset enable signal buffer

        ELSIF RISING_EDGE(clk) THEN

            enable_signal_buf <= Enable_Signals; -- Update buffer with enable signals

        END IF;

    END PROCESS;

 -- Process to handle internal state (R_i) and MAC generation during encryption
    process_mac_enc_R : PROCESS (clk, rst, enc_mac_start, enable_signal_buf, R_o(1), R_o(2), R_o(3), R_o(4), R_o(5), R_o(6), R_o(7),R_o(8),R_o(9), R_o(10), text_mod, text_len, integrity, R_input,R_dec_input)
    BEGIN

        IF rst = '1' THEN

            R_i <= (OTHERS => (OTHERS => '0')); -- Reset internal state
            R_mac_input <= (OTHERS => '0'); -- Reset MAC input

        ELSIF RISING_EDGE(clk) THEN
-- Handle different encryption and MAC start signals

            CASE enc_mac_start IS
-- Encryption start (mac is included)

                WHEN "010" =>
-- Update internal state based on the current state, enable signals, and integrity
                        R_i(2) <= R_input WHEN text_mod /= 0 ELSE
                                  (OTHERS => '0');

                        R_i(3) <= R_o(2) WHEN integrity = '1' ELSE
                                  (OTHERS => '0');

                        R_i(4) <= R_input WHEN enable_signal_buf = "11111111" ELSE
                                (OTHERS => '0');
            
                        R_i(5) <= R_Input WHEN (enable_signal_buf = "01111111" AND text_mod = 0) ELSE
                                  R_o(4) WHEN (enable_signal_buf = "11111111") ELSE
                                  R_o(2) WHEN (enable_signal_buf = "01111111" AND text_mod /= 0 AND integrity = '0') ELSE
                                  R_o(3) WHEN (enable_signal_buf = "01111111" AND integrity = '1') ELSE
                                  (OTHERS => '0');
            
                        R_i(6) <= R_Input WHEN (enable_signal_buf = "00111111" AND text_mod = 0) ELSE
                                  R_o(5)  WHEN (enable_signal_buf = "01111111" OR enable_signal_buf = "11111111") ELSE
                                  R_o(2)  WHEN (enable_signal_buf ="00111111" AND integrity = '0' AND text_mod /= 0) ELSE
                                  R_o(3)  WHEN (enable_signal_buf = "00111111" AND integrity = '1') ELSE
                                  (OTHERS => '0');
            
                        R_i(7) <= R_Input WHEN (enable_signal_buf = "00011111" AND text_mod = 0) ELSE
                                R_o(6)  WHEN (enable_signal_buf = "00111111" OR enable_signal_buf = "11111111" OR enable_signal_buf = "01111111") ELSE
                                R_o(2)  WHEN (enable_signal_buf = "00011111" AND integrity = '0' AND text_mod /= 0) ELSE
                                R_o(3)  WHEN ( enable_signal_buf = "00011111" AND integrity = '1') ELSE
                                (OTHERS => '0');
            
                        R_i(8) <= R_Input WHEN (enable_signal_buf = "00001111" AND text_mod = 0) ELSE
                                R_o(7)  WHEN (enable_signal_buf = "00111111" OR enable_signal_buf = "11111111" OR enable_signal_buf = "01111111" OR enable_signal_buf = "00011111") ELSE
                                R_o(2)  WHEN (enable_signal_buf = "00001111" AND integrity = '0' AND text_mod /= 0) ELSE
                                R_o(3)  WHEN (enable_signal_buf = "00001111" AND integrity = '1') ELSE
                                (OTHERS => '0');
            
                        R_i(9) <= R_Input WHEN (enable_signal_buf = "00000111" AND text_mod = 0) ELSE
                                R_o(8)  WHEN (enable_signal_buf = "00111111" OR enable_signal_buf = "11111111" OR enable_signal_buf = "01111111" OR enable_signal_buf = "00011111" OR enable_signal_buf = "00001111") ELSE
                                R_o(2)  WHEN (enable_signal_buf = "00000111" AND integrity = '0' AND text_mod /= 0) ELSE
                                R_o(3)  WHEN (enable_signal_buf = "00000111" AND integrity = '1') ELSE
                                (OTHERS => '0');
            
                        R_i(10) <= R_Input WHEN (enable_signal_buf = "00000011" AND text_mod = 0) ELSE
                                R_o(9)  WHEN (enable_signal_buf = "00111111" OR enable_signal_buf = "11111111" OR enable_signal_buf = "01111111" OR enable_signal_buf = "00011111" OR enable_signal_buf = "00001111" OR enable_signal_buf = "00000111") ELSE
                                R_o(2)  WHEN (enable_signal_buf = "00000011" AND integrity = '0' AND text_mod /= 0) ELSE
                                R_o(3)  WHEN (enable_signal_buf = "00000011" AND integrity = '1') ELSE
                                (OTHERS => '0');
            
                        R_i(11) <= R_Input WHEN (enable_signal_buf = "00000001" AND text_mod = 0) ELSE
                                R_o(10)  WHEN (enable_signal_buf = "00111111" OR enable_signal_buf = "11111111" OR enable_signal_buf = "01111111" OR enable_signal_buf = "00011111" OR enable_signal_buf = "00001111" OR enable_signal_buf = "00000111" OR enable_signal_buf = "00000011") ELSE
                                R_o(2)   WHEN (enable_signal_buf = "00000001" AND integrity = '0' AND text_mod /= 0) ELSE
                                R_o(3)  WHEN (enable_signal_buf = "00000001" AND integrity = '1') ELSE
                                (OTHERS => '0');

                        R_mac_input <= R_o(2)  WHEN (enable_signal_buf = "00000000" AND integrity = '0') ELSE
                                       R_o(3) WHEN (enable_signal_buf = "00000000" AND integrity = '1' ) ELSE
                                       R_o(11) WHEN (enable_signal_buf = "11111111" OR enable_signal_buf = "01111111" OR enable_signal_buf = "00111111" OR enable_signal_buf = "00011111" OR enable_signal_buf = "00001111" OR enable_signal_buf = "00000111" OR enable_signal_buf = "00000011" OR enable_signal_buf = "00000001") ELSE
                                       (OTHERS => '0'); 

-- Decryption start for integrity check
                WHEN "011" => 
-- Update MAC input based on integrity and text length
                        R_mac_input <= R_dec_input WHEN (128 >= text_len AND integrity = '0') ELSE
                                       R_o(3) WHEN (text_len < 16 AND integrity = '1') ELSE
                                       (OTHERS => '0');
                                       
                        R_i(2) <= R_input WHEN text_mod /= 0 ELSE
                                  (OTHERS => '0');

                        R_i(3) <= R_o(2) WHEN integrity = '1' ELSE 
                                  (OTHERS => '0');

                WHEN "100" => 
                -- Update the internal state from the stored MAC input
                    R_i(1)  <= R_mac_input;

                    R_i(2)  <= R_o(1);
                    R_i(3)  <= R_o(2);
                    R_i(4)  <= R_o(3);
                    R_i(5)  <= R_o(4);
                    R_i(6)  <= R_o(5);
                    R_i(7)  <= R_o(6);
                    R_i(8)  <= R_o(7);
                    R_i(9)  <= R_o(8);
                    R_i(10) <= R_o(9);
                    R_i(11) <= R_o(10);

                WHEN "101" =>

                    R_i <= UNAFFECTED;

                WHEN OTHERS =>

                    R_i <= (OTHERS => (OTHERS => '0'));

            END CASE;

            -- Registering the R_i values
            R_i_reg <= R_i;

        END IF;

    END PROCESS;

 -- Process to manage stream cipher and MAC generation inputs
    process_sc_mac_enc : PROCESS(enc_mac_start, text_len, R_i(2), iv)
    BEGIN

        IF enc_mac_start = "010" OR enc_mac_start = "011" THEN

            enable_sc <= '1'; -- Enable stream cipher
            E_2       <= (OTHERS => '0'); -- Clear E_2

        ELSIF enc_mac_start = "100" THEN

            enable_sc <= '0'; -- Disable stream cipher
            E_2 <= STD_LOGIC_VECTOR((UNSIGNED(iv(47 DOWNTO 32)) + UNSIGNED(R_i(2)    (127 DOWNTO 112)) + UNSIGNED(R_i(2)    (95 DOWNTO 80))) MOD 65536);

        ELSE

            E_2 <= (OTHERS => '0');
            enable_sc <= '0';

        END IF;

    END PROCESS;

-- Process to generate inputs for MAC and encryption blocks based on plaintext and internal state
    process_mac_enc_inputs : PROCESS (plaintext,enc_mac_start,iv(63 DOWNTO 48), iv(15 DOWNTO 0), R_i(1), R_i(4),R_i(5),R_i(6),R_i(7),R_i(8),R_i(9),R_i(10),R_i(11),n)
    BEGIN
 -- Handle the MAC and encryption process for different enc_mac_start values
        CASE enc_mac_start IS

            WHEN "010" =>

                E_1 <= (OTHERS => '0');

                -- Assign plaintext values to encryption block inputs E_4 to E_11
                E_4 <= plaintext(127 DOWNTO 112);
                E_5 <= plaintext(111 DOWNTO  96);
                E_6 <= plaintext( 95 DOWNTO  80);
                E_7 <= plaintext( 79 DOWNTO  64);
                E_8 <= plaintext( 63 DOWNTO  48);
                E_9 <= plaintext( 47 DOWNTO  32);
                E_10 <= plaintext( 31 DOWNTO  16);
                E_11 <= plaintext( 15 DOWNTO   0);

            WHEN "100" =>

                E_1 <= STD_LOGIC_VECTOR((UNSIGNED(iv(63 DOWNTO 48)) + UNSIGNED(R_i(1) (127 DOWNTO 112)) + UNSIGNED(R_i(1) (95 DOWNTO 80)) + UNSIGNED(TO_UNSIGNED(n, 16))) MOD 65536);

            -- Assign E values to mac block inputs E_4 to E_11
                E_4 <= STD_LOGIC_VECTOR((UNSIGNED(iv(15 DOWNTO  0)) + UNSIGNED(R_i(4) (  127 DOWNTO 112)) + UNSIGNED(R_i(4)    (95 DOWNTO 80))) MOD 65536);
                E_5 <= STD_LOGIC_VECTOR((UNSIGNED(R_i(5)     (127 DOWNTO 112)) + UNSIGNED(R_i(5)    (95 DOWNTO 80))) MOD 65536);
                E_6 <= STD_LOGIC_VECTOR((UNSIGNED(R_i(6)     (127 DOWNTO 112)) + UNSIGNED(R_i(6)    (95 DOWNTO 80))) MOD 65536);
                E_7 <= STD_LOGIC_VECTOR((UNSIGNED(R_i(7)     (127 DOWNTO 112)) + UNSIGNED(R_i(7)    (95 DOWNTO 80))) MOD 65536);
                E_8 <= STD_LOGIC_VECTOR((UNSIGNED(R_i(8)     (127 DOWNTO 112)) + UNSIGNED(R_i(8)    (95 DOWNTO 80))) MOD 65536);
                E_9 <= STD_LOGIC_VECTOR((UNSIGNED(R_i(9)     (127 DOWNTO 112)) + UNSIGNED(R_i(9)    (95 DOWNTO 80))) MOD 65536);
                E_10 <= STD_LOGIC_VECTOR((UNSIGNED(R_i(10)     (127 DOWNTO 112)) + UNSIGNED(R_i(10)    (95 DOWNTO 80))) MOD 65536);
                E_11 <= STD_LOGIC_VECTOR((UNSIGNED(R_i(11)     (127 DOWNTO 112)) + UNSIGNED(R_i(11)    (95 DOWNTO 80))) MOD 65536);

            WHEN OTHERS =>

                E_1 <= (OTHERS => '0');
                E_4 <= (OTHERS => '0');
                E_5 <= (OTHERS => '0');
                E_6 <= (OTHERS => '0');
                E_7 <= (OTHERS => '0');
                E_8 <= (OTHERS => '0');
                E_9 <= (OTHERS => '0');
                E_10 <= (OTHERS => '0');
                E_11 <= (OTHERS => '0');

        END CASE;

    END PROCESS;

 -- Process for handling stream cipher and MAC integrity checks
    process_integrity_input : PROCESS(plaintext,streamchipher_input,integrity,enc_mac_start,text_len,iv(31 DOWNTO 16), R_i(3))
    BEGIN

-- Handle different cases for integrity checks
            CASE enc_mac_start IS
            
                WHEN "010" =>

                    IF integrity = '0' THEN

                        E_3 <= (OTHERS => '0'); -- No integrity check, clear E_3

                    ELSIF integrity = '1' THEN

-- Assign appropriate plaintext based on the length for integrity check
                        CASE text_len IS 

                            WHEN 113 TO 127 =>

                                E_3 <= plaintext(127 DOWNTO 112);

                            WHEN 97 TO 111 =>

                                E_3 <= plaintext(111 DOWNTO 96);

                            WHEN 81 TO 95 =>

                                E_3 <= plaintext(95 DOWNTO 80);

                            WHEN 65 TO 79 =>

                                E_3 <= plaintext(79 DOWNTO 64);

                            WHEN 49 TO 63 =>

                                E_3 <= plaintext(63 DOWNTO 48);

                            WHEN 33 TO 47 =>

                                E_3 <= plaintext(47 DOWNTO 32);

                            WHEN 17 TO 31 =>

                                E_3 <= plaintext(31 DOWNTO 16);

                            WHEN 1 TO 15 =>

                                E_3 <= plaintext(15 DOWNTO 0);

                            WHEN OTHERS =>

                                E_3 <= (OTHERS => '0');

                        END CASE;

                    END IF;

                WHEN "011" =>

                    IF integrity = '1' THEN 

                        E_3 <= streamchipher_input;

                    ELSIF integrity = '0' THEN
                        
                        E_3 <= (OTHERS => '0');

                    END IF;

                WHEN "100" =>

                    E_3 <= STD_LOGIC_VECTOR((UNSIGNED(iv(31 DOWNTO 16)) + UNSIGNED(R_i(3)    (127 DOWNTO 112)) + UNSIGNED(R_i(3)    (95 DOWNTO 80))) MOD 65536);

                WHEN OTHERS =>

                    E_3 <= (OTHERS => '0');

            END CASE;

    END PROCESS;
  
 -- Encryption block instantiation for 1st step of MAC
    Encryption_block_mac : ENTITY work.Encryption
        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => '0',
            pt_input   => E_1,
            R_input    => R_i_reg(1),  
            key        => key,
            ct_output  => No_output,
            R_output   => R_o(1)

        );

 -- Encryption block instantiation for 2nd step of MAC or for StreamChipher use
        Encryption_block_sc : ENTITY work.Encryption
        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => enable_sc,
            pt_input   => E_2,
            R_input    => R_i_reg(2),  
            key        => key,
            ct_output  => sc_interior_zero,
            R_output   => R_o(2)

        );

 -- Encryption block instantiation for 3d step of MAC or for Integrity use
        Encryption_block_int : ENTITY work.Encryption
        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => '0',
            pt_input   => E_3,
            R_input    => R_i_reg(3),  
            key        => key,
            ct_output  => No_output,
            R_output   => R_o(3)

        );
    
-- Encryption block instantiations for each word (1 to 8)

-- Encryption block of the 1st word/T1
    Encryption_block_1 : ENTITY work.Encryption
        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => Enable_Signals(7),
            pt_input   => E_4,
            R_input    => R_i_reg(4),  
            key        => key,
            ct_output  => interior_ciphertext(127 DOWNTO 112),
            R_output   => R_o(4)

        );

    -- Encryption block of the 2nd word/T2
    Encryption_block_2 : ENTITY work.Encryption
        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => Enable_Signals(6),
            pt_input   => E_5,
            R_input    => R_i_reg(5),  
            key        => key,
            ct_output  => interior_ciphertext(111 DOWNTO 96),
            R_output   => R_o(5)

        );

    --Encryption block of the 3rd word/T3
    Encryption_block_3 : ENTITY work.Encryption

        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => Enable_Signals(5),
            pt_input   => E_6,
            R_input    => R_i_reg(6),
            key        => key,
            ct_output  => interior_ciphertext(95 DOWNTO 80),
            R_output   => R_o(6)

        );

    --Encryption block of the 4th word/T4
    Encryption_block_4 : ENTITY work.Encryption

        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => Enable_Signals(4),
            pt_input   => E_7,
            R_input    => R_i_reg(7),
            key        => key,
            ct_output  => interior_ciphertext(79 DOWNTO 64),
            R_output   => R_o(7)

        );
    
    --Encryption block of the 5th word/T5
    Encryption_block_5 : ENTITY work.Encryption

        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => Enable_Signals(3),
            pt_input   => E_8,
            R_input    => R_i_reg(8),
            key        => key,
            ct_output  => interior_ciphertext(63 DOWNTO 48),
            R_output   => R_o(8)

        );    

    --Encryption block of the 6th word/T6
    Encryption_block_6 : ENTITY work.Encryption

        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => Enable_Signals(2),
            pt_input   => E_9,
            R_input    => R_i_reg(9),
            key        => key,
            ct_output  => interior_ciphertext(47 DOWNTO 32),
            R_output   => R_o(9)

        );

    --Encryption block of the 7th word/T7
    Encryption_block_7 : ENTITY work.Encryption

        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => Enable_Signals(1),
            pt_input   => E_10,
            R_input    => R_i_reg(10),
            key        => key,
            ct_output  => interior_ciphertext(31 DOWNTO 16),
            R_output   => R_o(10)

        );

    --Encryption block of the 8th word/T8
    Encryption_block_8 : ENTITY work.Encryption

        PORT MAP(

            clk        => clk,
            rst        => rst,
            enable_out => Enable_Signals(0),
            pt_input   => E_11,
            R_input    => R_i_reg(11),
            key        => key,
            ct_output  => interior_ciphertext(15 DOWNTO 0),
            R_output   => R_o(11)

        );

  -- Process to handle final ciphertext output
    ct_output_process : PROCESS(clk, rst)
    
    BEGIN 

        IF rst = '1' THEN

            ciphertext <= (OTHERS => '0');

        ELSIF RISING_EDGE(clk) THEN

            IF (enc_mac_start = "010" OR enc_mac_start = "100") THEN
-- Output the final ciphertext when encryption is active
                ciphertext <= interior_ciphertext(127 DOWNTO 0);

            ELSE
                
                ciphertext <= (OTHERS => '0');

            END IF;

        END IF;

    END PROCESS;

-- Process to output internal state for integrity check
    R_int_output_process : PROCESS(clk, rst)
    
    BEGIN 

        IF rst = '1' THEN

            R_integrity <= (OTHERS => '0'); -- Reset integrity state

        ELSIF RISING_EDGE(clk) THEN

            R_integrity <= R_o(3); -- Output integrity state

        END IF;

    END PROCESS;

  -- Process to handle stream cipher zeroing
    SC_output_process : PROCESS(clk, rst)
    
    BEGIN 

        IF rst = '1' THEN

            sc_ct_zero <= (OTHERS => '0'); -- Reset stream cipher output

        ELSIF RISING_EDGE(clk) THEN

            sc_ct_zero <= sc_interior_zero; -- Output stream cipher result

        END IF;

    END PROCESS;


END Structure;