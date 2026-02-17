-- This entity encapsulates the functionality of the HummingBird2 encryption and decryption operations.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY HummingBird2 IS
PORT(

    clk            : IN  STD_LOGIC;  -- Clock signal
    rst            : IN  STD_LOGIC; -- Reset signal (active high)
    text           : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- Input plaintext or ciphertext (128 bits)
    text_len       : IN  INTEGER RANGE 1 TO 128;  -- Length of the input text
    integrity      : IN  STD_LOGIC;  -- Integrity flag to indicate whether integrity check is used
    iv             : IN  STD_LOGIC_VECTOR ( 63 DOWNTO 0); -- Initialization vector for encryption/decryption (64 bits)
    key            : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- Encryption/Decryption key (128 bits)
    mode           : IN  STD_LOGIC_VECTOR (  2 DOWNTO 0); -- Mode of operation (Idle/InitializationEncryption/Decryption/MAC/MAC_check)
    output         : OUT STD_LOGIC_VECTOR (127 DOWNTO 0); -- Final output ciphertext or plaintext or MAC Tags (128 bits)
    mac_flag_equal : OUT STD_LOGIC -- Flag indicating MAC Tags from Entity1 & Entity2 are equals

);

END HummingBird2;

ARCHITECTURE Structure OF HummingBird2 IS

    --SIGNALS for Initialization
    SIGNAL R_input                : STD_LOGIC_VECTOR(127 DOWNTO 0);

    --STREAMCHIPHER SIGNALS
    SIGNAL streamchipher_input  : STD_LOGIC_VECTOR( 15 DOWNTO 0); -- Input block to the stream cipher (16 bits)
    SIGNAL streamchipher_output : STD_LOGIC_VECTOR( 15 DOWNTO 0); -- Output of the stream cipher
    SIGNAL sc_text_len          : INTEGER RANGE 1 TO 16; -- Length of text for the stream cipher (1 to 16 )
    SIGNAL sc_ct_zero           : STD_LOGIC_VECTOR( 15 DOWNTO 0); -- Zero output from stream cipher

    -- SIGNALS FOR INTEGRITY CHECK
    SIGNAL R_output_integrity_dec   : STD_LOGIC_VECTOR(127 DOWNTO 0);

    -- SIGNALS FOR FULL ENCRYPTION
    SIGNAl R_Dec_EF_input     : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL Encryption_Output  : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL Enable_Signals_enc : STD_LOGIC_VECTOR(  7 DOWNTO 0);
    SIGNAL temp_enc_output    : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL Enable_Signals_choose     : STD_LOGIC_VECTOR(  7 DOWNTO 0);

    -- SIGNALS FOR FULL DECRYPTION
    SIGNAL R_DF_input         : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL R_DF_output        : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL text_dec_input     : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL Decryption_Output  : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL Enable_Signals_dec : STD_LOGIC_VECTOR(  7 DOWNTO 0);
    SIGNAL temp_dec_output    : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL n                  : INTEGER RANGE 1 TO 8; -- Number of Words Encrypted/Decrypted
    SIGNAL Enable_Signals_mac : STD_LOGIC_VECTOR(  7 DOWNTO 0); -- Enable signals for MAC operation

    --GLOBAL SIGNALS
    SIGNAL current_state : STD_LOGIC_VECTOR(  2 DOWNTO 0); -- Current FSM state
    SIGNAL text_len_1    : INTEGER RANGE 1 TO 16; -- Text length for first 16-bit block
    SIGNAL text_len_2    : INTEGER RANGE 1 TO 16; -- Text length for second 16-bit block
    SIGNAL text_len_3    : INTEGER RANGE 1 TO 16; -- Text length for third 16-bit block
    SIGNAL text_len_4    : INTEGER RANGE 1 TO 16; -- Text length for forth 16-bit block
    SIGNAL text_len_5    : INTEGER RANGE 1 TO 16; -- Text length for fifth 16-bit block
    SIGNAL text_len_6    : INTEGER RANGE 1 TO 16; -- Text length for sixth 16-bit block
    SIGNAL text_len_7    : INTEGER RANGE 1 TO 16; -- Text length for seventh 16-bit block
    SIGNAL text_len_8    : INTEGER RANGE 1 TO 16; -- Text length for eighth 16-bit block
    SIGNAL text_mod      : INTEGER RANGE 0 TO 15; -- Modulo result for text length

BEGIN


    -- FSM Controller Block
    FSM_Controller_block : ENTITY work.FSM_Controller

        PORT MAP(

            clk            => clk,
            rst            => rst,
            mode           => mode,
            current_state  => current_state

        );

    


    -- Signal Control - Length Control Block: Calculates enable signals and partition sizes based on text length and integrity flag.
    SC_LC_block : ENTITY work.SC_LC

        PORT MAP(

            text_len           => text_len,
            integrity          => integrity,          
            Enable_Signals_Enc => Enable_Signals_enc,
            Enable_Signals_Dec => Enable_Signals_dec,
            Enable_Signals_Mac => Enable_Signals_mac,  
            n                      => n,
            text_len_1             => text_len_1,  
            text_len_2             => text_len_2,
            text_len_3             => text_len_3, 
            text_len_4             => text_len_4, 
            text_len_5             => text_len_5, 
            text_len_6             => text_len_6, 
            text_len_7             => text_len_7, 
            text_len_8             => text_len_8,

            text_mod               =>  text_mod
        );

    -- Initialization block
    Initialization_block : ENTITY work.Initialization

        PORT MAP(

            clk        => clk,
            rst        => rst,
            start_init => current_state,
            iv         => iv,
            key        => key,
            R_output   => R_input 

        );

-- Process to handle input selection for the stream cipher based on text length
        SC_text_inputs_Process : PROCESS (text_len,text,text_len_8,text_len_7,text_len_6,text_len_5,text_len_4,text_len_3,text_len_2,text_len_1)
        BEGIN

            CASE text_len IS 

                WHEN 113 TO 127 =>

                        streamchipher_input <= text(127 DOWNTO 112);
                        sc_text_len         <= text_len_8;

                    WHEN 97 TO 111 =>
                        
                        streamchipher_input <= text(111 DOWNTO 96);
                        sc_text_len         <= text_len_7;

                    WHEN 81 TO 95 =>

                        streamchipher_input <= text(95 DOWNTO 80);
                        sc_text_len         <= text_len_6;

                    WHEN 65 TO 79 =>

                        streamchipher_input <= text(79 DOWNTO 64);
                        sc_text_len         <= text_len_5;

                    WHEN 49 TO 63 =>

                        streamchipher_input <= text(63 DOWNTO 48);
                        sc_text_len         <= text_len_4;

                    WHEN 33 TO 47 =>

                        streamchipher_input <= text(47 DOWNTO 32);
                        sc_text_len         <= text_len_3;

                    WHEN 17 TO 31 =>

                        streamchipher_input <= text(31 DOWNTO 16);
                        sc_text_len         <= text_len_2;

                    WHEN 1 TO 15 =>

                        streamchipher_input <= text(15 DOWNTO 0);
                        sc_text_len         <= text_len_1;

                    WHEN OTHERS =>

                        streamchipher_input <= (OTHERS => '0');
                        sc_text_len         <= 16;

            END CASE;

        END PROCESS;

    -- Stream Chipher Block
    StreamChipher_block : ENTITY work.Streamchipher

        PORT MAP (

            text_input      => streamchipher_input,
            text_len        => sc_text_len,
            sc_zero         =>  sc_ct_zero,
            text_xor_output => streamchipher_output

        );

-- Process to select enable signals for encryption or MAC based on the current state.
        process_enc_inputs : PROCESS (clk,rst,current_state,Enable_Signals_enc,Enable_Signals_mac) 
        BEGIN

        IF rst = '1' THEN

            Enable_Signals_choose <= (OTHERS => '0');

        ELSIF RISING_EDGE(clk) THEN

            CASE current_state IS

                WHEN "010" =>

                    Enable_Signals_choose <= Enable_Signals_enc;

                WHEN "100" =>

                    Enable_Signals_choose <= Enable_Signals_mac;

                WHEN OTHERS => 

                    Enable_Signals_choose <= (OTHERS => '0');

            END CASE;

        END IF;

        END PROCESS;

 -- Process to handle decryption state R input for Full Encryption Block.
        process_dec_R_o : PROCESS(clk, rst, current_state, R_DF_output)
        BEGIN

            IF rst = '1' THEN

                R_Dec_EF_input <= (OTHERS => '0');
 
            ELSIF RISING_EDGE(clk) THEN

                CASE current_state IS

                    WHEN "011" | "100" | "101" =>

                        R_Dec_EF_input <= R_DF_output;

                    WHEN OTHERS =>

                        R_Dec_EF_input <= (OTHERS => '0');

                END CASE;

            END IF;

        END PROCESS;

    --Encryption/MAC block
    Full_Encryption_block : ENTITY work.Full_Encryption

        PORT MAP(

            clk            => clk,
            rst            => rst,
            enc_mac_start  => current_state,
            iv             => iv,
            text_len       => text_len,
            plaintext      => text,
            R_input        => R_input,
            R_dec_input    => R_Dec_EF_input,
            integrity      => integrity,
            n              => n,
            text_mod       => text_mod,
            streamchipher_input => streamchipher_output,
            key            => key,
            ciphertext     => Encryption_Output,
            Enable_Signals => Enable_Signals_choose,
            sc_ct_zero     => sc_ct_zero,
            R_integrity => R_output_integrity_dec

        );

-- Process to handle decryption R & text inputs for Full Dencryption Block.
        Decryption_Block_inputs_Process : PROCESS (integrity, text_len, R_input,  text, sc_ct_zero, R_output_integrity_dec)
        BEGIN

                IF integrity = '0' THEN

                    R_DF_input     <= R_input;

                    CASE text_len IS 

                        WHEN 113 TO 128 =>

                            IF text_len = 128 THEN

                                text_dec_input <= text;

                            ELSE 

                                text_dec_input <= sc_ct_zero & text(111 DOWNTO 0);

                            END IF;

                        WHEN 97 TO 112 =>

                            IF text_len = 112 THEN

                                text_dec_input <= text;

                            ELSE 

                                text_dec_input <= text(127 DOWNTO 112) & sc_ct_zero & text(95 DOWNTO 0);

                            END IF;

                            WHEN 81 TO 96 =>

                                IF text_len = 96 THEN

                                    text_dec_input <= text;

                                ELSE 

                                    text_dec_input <= text(127 DOWNTO 96) & sc_ct_zero & text(79 DOWNTO 0);

                                END IF;

                            WHEN 65 TO 80 =>

                                IF text_len = 80 THEN

                                    text_dec_input <= text;

                                ELSE 

                                    text_dec_input <= text(127 DOWNTO 80) & sc_ct_zero & text(63 DOWNTO 0);

                                END IF;

                            WHEN 49 TO 64 =>

                                IF text_len = 64 THEN

                                    text_dec_input <= text;

                                ELSE 

                                    text_dec_input <= text(127 DOWNTO 64) & sc_ct_zero & text(47 DOWNTO 0);

                                END IF;

                            WHEN 33 TO 48 =>

                                IF text_len = 48 THEN

                                    text_dec_input <= text;

                                ELSE 

                                    text_dec_input <= text(127 DOWNTO 48) & sc_ct_zero & text(31 DOWNTO 0);

                                END IF;

                            WHEN 17 TO 32 =>

                                IF text_len = 32 THEN

                                    text_dec_input <= text;

                                ELSE 

                                    text_dec_input <= text(127 DOWNTO 32) & sc_ct_zero & text(15 DOWNTO 0);

                                END IF;

                            WHEN 1 TO 16 =>

                                IF text_len = 16 THEN

                                    text_dec_input <= text;

                                ELSE 

                                    text_dec_input <= text(127 DOWNTO 16) & sc_ct_zero;

                                END IF;
                            
                        END CASE;

                ELSIF integrity = '1' THEN

                    R_DF_input     <= R_output_integrity_dec;
                    text_dec_input <= text;

                END IF;

        END PROCESS;



    -- Decryption block
   Full_Decryption_block : ENTITY work.Full_Decryption

        PORT MAP(

            clk            => clk,
            rst            => rst,
            dec_start      => current_state,
            ciphertext     => text_dec_input,
            R_input        => R_input,
            R_Output       => R_DF_output,
            key            => key,
            plaintext      => Decryption_Output,
            Enable_Signals => Enable_Signals_dec

        );

        

    -- MAC CHECKER BLOCK
    MAC_Checker_block : ENTITY work.mac_checker

        PORT MAP(
            
            clk             => clk,
            rst             => rst,
            mac_check_start => current_state,
            T_sender        => text,
            T_recipient     => Encryption_Output,
            flag_equal      => mac_flag_equal

        );

-- Process to handle encryption output.
        output_enc_process : PROCESS (text_len,text,Encryption_Output,streamchipher_output)
        BEGIN

            CASE text_len IS

                WHEN 113 TO 128 =>

                    IF text_len = 128 THEN

                        temp_enc_output <= Encryption_Output;

                    ELSE

                        temp_enc_output <= streamchipher_output & Encryption_Output(111 DOWNTO 0);

                    END IF;

                WHEN 97 TO 112 =>

                    IF text_len = 112 THEN

                        temp_enc_output <= Encryption_Output;

                    ELSE

                        temp_enc_output <= Encryption_Output(127 DOWNTO 112) & streamchipher_output & Encryption_Output(95 DOWNTO 0);

                    END IF;

                WHEN 81 TO 96 =>

                    IF text_len = 96 THEN

                        temp_enc_output <= Encryption_Output;

                    ELSE

                        temp_enc_output <= Encryption_Output(127 DOWNTO 96) & streamchipher_output & Encryption_Output(79 DOWNTO 0);

                    END IF;

                WHEN 65 TO 80 =>

                    IF text_len = 80 THEN

                        temp_enc_output <= Encryption_Output;

                    ELSE

                        temp_enc_output <= Encryption_Output(127 DOWNTO 80) & streamchipher_output & Encryption_Output(63 DOWNTO 0);

                    END IF;

                WHEN 49 TO 64 =>

                    IF text_len = 64 THEN

                        temp_enc_output <= Encryption_Output;

                    ELSE

                        temp_enc_output <= Encryption_Output(127 DOWNTO 64) & streamchipher_output & Encryption_Output(47 DOWNTO 0);

                    END IF;

                WHEN 33 TO 48 =>

                    IF text_len = 48 THEN

                        temp_enc_output <= Encryption_Output;

                    ELSE

                        temp_enc_output <= Encryption_Output(127 DOWNTO 48) & streamchipher_output & Encryption_Output(31 DOWNTO 0);

                    END IF;

                WHEN 17 TO 32 =>

                    IF text_len = 32 THEN

                        temp_enc_output <= Encryption_Output;

                    ELSE

                        temp_enc_output <= Encryption_Output(127 DOWNTO 32) & streamchipher_output & Encryption_Output(15 DOWNTO 0);

                    END IF;

                WHEN 1 TO 16 =>

                    IF text_len = 16 THEN

                        temp_enc_output <= Encryption_Output;

                    ELSE

                        temp_enc_output <= Encryption_Output(127 DOWNTO 16) & streamchipher_output;

                    END IF;

                WHEN OTHERS =>

                    temp_enc_output <= (OTHERS => '0');

                END CASE;

            END PROCESS;

-- Process to handle decryption output.
        output_dec_process : PROCESS (text_len,text,Decryption_Output,streamchipher_output)
        BEGIN

            CASE text_len IS

                WHEN 113 TO 128 =>

                    IF text_len = 128 THEN

                        temp_dec_output <= Decryption_Output;

                    ELSE

                        temp_dec_output <= streamchipher_output & Decryption_Output(111 DOWNTO 0);

                    END IF;

                WHEN 97 TO 112 =>

                    IF text_len = 112 THEN

                        temp_dec_output <= Decryption_Output;

                    ELSE

                        temp_dec_output <= Decryption_Output(127 DOWNTO 112) & streamchipher_output & Decryption_Output(95 DOWNTO 0);

                    END IF;

                WHEN 81 TO 96 =>

                    IF text_len = 96 THEN

                        temp_dec_output <= Decryption_Output;

                    ELSE

                        temp_dec_output <= Decryption_Output(127 DOWNTO 96) & streamchipher_output & Decryption_Output(79 DOWNTO 0);

                    END IF;

                WHEN 65 TO 80 =>

                    IF text_len = 80 THEN

                        temp_dec_output <= Decryption_Output;

                    ELSE

                        temp_dec_output <= Decryption_Output(127 DOWNTO 80) & streamchipher_output & Decryption_Output(63 DOWNTO 0);

                    END IF;

                WHEN 49 TO 64 =>

                    IF text_len = 64 THEN

                        temp_dec_output <= Decryption_Output;

                    ELSE

                        temp_dec_output <= Decryption_Output(127 DOWNTO 64) & streamchipher_output & Decryption_Output(47 DOWNTO 0);

                    END IF;

                WHEN 33 TO 48 =>

                    IF text_len = 48 THEN

                        temp_dec_output <= Decryption_Output;

                    ELSE

                        temp_dec_output <= Decryption_Output(127 DOWNTO 48) & streamchipher_output & Decryption_Output(31 DOWNTO 0);

                    END IF;

                WHEN 17 TO 32 =>

                    IF text_len = 32 THEN

                        temp_dec_output <= Decryption_Output;

                    ELSE

                        temp_dec_output <= Decryption_Output(127 DOWNTO 32) & streamchipher_output & Decryption_Output(15 DOWNTO 0);

                    END IF;

                WHEN 1 TO 16 =>

                    IF text_len = 16 THEN

                        temp_dec_output <= Decryption_Output;

                    ELSE

                        temp_dec_output <= Decryption_Output(127 DOWNTO 16) & streamchipher_output;

                    END IF;

                WHEN OTHERS =>

                    temp_dec_output <= (OTHERS => '0');

                END CASE;

            END PROCESS;
                    
-- Output Selection Process: Selects the correct output based on encryption or decryption or MAC mode.
    WITH current_state SELECT

        output <= temp_enc_output   WHEN "010",
                  temp_dec_output   WHEN "011",
                  Encryption_Output WHEN "100",
                  (OTHERS => '0') WHEN OTHERS;

END Structure;