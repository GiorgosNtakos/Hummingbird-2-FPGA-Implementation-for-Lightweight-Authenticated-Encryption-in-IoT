-- This module handles the decryption process using a block cipher.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY Decryption IS
PORT(

    clk            : IN  STD_LOGIC; -- Clock signal
    rst            : IN  STD_LOGIC;  -- Reset signal (active high)
    enable_out     : IN  STD_LOGIC; -- Enable signal for output control
    ct_input       : IN  STD_LOGIC_VECTOR ( 15 DOWNTO 0); -- 16-bit ciphertext input
    R_input        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- 128-bit R internal state
    key            : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- 128-bit key
    pt_output      : OUT STD_LOGIC_VECTOR ( 15 DOWNTO 0); -- 16-bit plaintext output
    R_output       : OUT STD_LOGIC_VECTOR (127 DOWNTO 0) -- Updated 128-bit R internal state

);

END Decryption;

ARCHITECTURE Behavioral OF Decryption IS

    TYPE my_array_1  IS ARRAY (1 TO 4) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    TYPE my_array_2  IS ARRAY (1 TO 2) OF STD_LOGIC_VECTOR(63 DOWNTO 0);

-- Signals for inv_wd inputs and outputs (inv_t)
    SIGNAL inv_wd_input : my_array_1;
    SIGNAL inv_t        : my_array_1;

-- Signals for XOR outputs between Key segments and R_input segments
    SIGNAL inv_KxR      : my_array_2;

-- Signals for internal plaintext output and R_output
    SIGNAL R_internal         : STD_LOGIC_VECTOR (127 DOWNTO 0);
    SIGNAL internal_pt_output : STD_LOGIC_VECTOR ( 15 DOWNTO 0);

-- Signals for addition and modulo results
    SIGNAL add_result1, add_result2, add_result3, add_result4 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL mod_result1, mod_result2, mod_result3, mod_result4 : STD_LOGIC_VECTOR(15 DOWNTO 0);


    BEGIN 

-- XOR between the upper half of the key and R_input (reverse of encryption)
                inv_KxR(1) <= key(127 DOWNTO 64) XOR R_input(63 DOWNTO 0);

-- XOR between the lower half of the key and R_input (reverse of encryption)
                inv_KxR(2) <= key( 63 DOWNTO  0) XOR R_input(63 DOWNTO 0);

-- Process to compute the inputs for the inv_wd_16 modules
        process_reg_inv_wd_inputs : PROCESS(clk, rst)
        BEGIN

            IF rst = '1' THEN
 -- Reset the inv_wd_input signals

                inv_wd_input <= (OTHERS => (OTHERS => '0'));

            ELSIF RISING_EDGE(clk) THEN
-- Compute inv_wd_input based on the ciphertext and internal state

                        inv_wd_input(1) <= STD_LOGIC_VECTOR(UNSIGNED(ct_input) - UNSIGNED(R_input(127 DOWNTO 112)) MOD 65536);
                        inv_wd_input(2) <= STD_LOGIC_VECTOR(UNSIGNED(inv_t(1)) - UNSIGNED(R_input( 79 DOWNTO  64)) MOD 65536);
                        inv_wd_input(3) <= STD_LOGIC_VECTOR(UNSIGNED(inv_t(2)) - UNSIGNED(R_input( 95 DOWNTO  80)) MOD 65536);
                        inv_wd_input(4) <= STD_LOGIC_VECTOR(UNSIGNED(inv_t(3)) - UNSIGNED(R_input(111 DOWNTO  96)) MOD 65536);

            END IF;

        END PROCESS;

 -- Instantiate inv_wd_16 modules for inverse nonlinear transformations
        inv_wd_16_dec_t1 : ENTITY work.inv_wd_16

        PORT MAP (

            clk             => clk,
            rst             => rst,
            inv_data_input  => inv_wd_input(1),
            key             => key(63 DOWNTO 0),
            inv_data_output => inv_t(1)

        );

        inv_wd_16_dec_t2 : ENTITY work.inv_wd_16

        PORT MAP (

            clk             => clk,
            rst             => rst,
            inv_data_input  => inv_wd_input(2),
            key             => inv_KxR(1),
            inv_data_output => inv_t(2)

        );

        inv_wd_16_dec_t3 : ENTITY work.inv_wd_16

        PORT MAP (

            clk             => clk,
            rst             => rst,
            inv_data_input  => inv_wd_input(3),
            key             => inv_KxR(2),
            inv_data_output => inv_t(3)

        );

        inv_wd_16_dec_t4 : ENTITY work.inv_wd_16

        PORT MAP (

            clk             => clk,
            rst             => rst,
            inv_data_input  => inv_wd_input(4),
            key             => key(127 DOWNTO 64),
            inv_data_output => inv_t(4)

        );

-- Process to compute the addition of internal state and inv_wd_input values
        process_additions : PROCESS(clk, rst)
        BEGIN

            IF rst = '1' THEN
-- Reset the addition results

                add_result1 <= (OTHERS => '0');
                add_result2 <= (OTHERS => '0');
                add_result3 <= (OTHERS => '0');
                add_result4 <= (OTHERS => '0');

            ELSIF RISING_EDGE(clk) THEN
-- Perform additions for each internal state segment and inv_wd_input values

                add_result1 <= STD_LOGIC_VECTOR(UNSIGNED(R_input(127 DOWNTO 112)) + UNSIGNED(inv_wd_input(2)));
                add_result2 <= STD_LOGIC_VECTOR(UNSIGNED(R_input(111 DOWNTO 96)) + UNSIGNED(inv_wd_input(4)));
                add_result3 <= STD_LOGIC_VECTOR(UNSIGNED(R_input(95 DOWNTO 80)) + UNSIGNED(inv_wd_input(3)));
                add_result4 <= STD_LOGIC_VECTOR(UNSIGNED(R_input(79 DOWNTO 64)) + UNSIGNED(R_input(127 DOWNTO 112)) + UNSIGNED(inv_wd_input(2)) + UNSIGNED(inv_wd_input(4)));

            END IF;

        END PROCESS;

 -- Process to compute the modulo 65536 results for each addition result
        process_modulo : PROCESS(clk, rst)
        BEGIN
        
            IF rst = '1' THEN
-- Reset the modulo results

                mod_result1 <= (OTHERS => '0');
                mod_result2 <= (OTHERS => '0');
                mod_result3 <= (OTHERS => '0');
                mod_result4 <= (OTHERS => '0');

            ELSIF RISING_EDGE(clk) THEN
-- Perform modulo 65536 operations on the addition results

                mod_result1 <= STD_LOGIC_VECTOR(UNSIGNED(add_result1) MOD 65536);
                mod_result2 <= STD_LOGIC_VECTOR(UNSIGNED(add_result2) MOD 65536);
                mod_result3 <= STD_LOGIC_VECTOR(UNSIGNED(add_result3) MOD 65536);
                mod_result4 <= STD_LOGIC_VECTOR(UNSIGNED(add_result4) MOD 65536);

            END IF;
            
        END PROCESS;

-- Update the internal state (R_internal) with the modulo results
        R_internal(127 DOWNTO 112) <= mod_result1;
        R_internal(111 DOWNTO 96)  <= mod_result2;
        R_internal(95 DOWNTO 80)   <= mod_result3;
        R_internal(79 DOWNTO 64)   <= mod_result4;

-- XOR the remaining internal state segments with the modulo results
        R_internal(63 DOWNTO 48) <= R_input(63 DOWNTO 48) XOR mod_result1; 
        R_internal(47 DOWNTO 32) <= R_input(47 DOWNTO 32) XOR mod_result2;
        R_internal(31 DOWNTO 16) <= R_input(31 DOWNTO 16) XOR mod_result3;
        R_internal(15 DOWNTO 0)  <= R_input(15 DOWNTO 0) XOR mod_result4;

        
-- Compute the internal plaintext output using inv_t(4) and internal state
        internal_pt_output <= STD_LOGIC_VECTOR((UNSIGNED(inv_t(4)) - UNSIGNED(R_input(127 DOWNTO 112))) MOD 65536);

        enable_pt_output_process : PROCESS (clk,rst)
        BEGIN
            
            IF rst = '1' THEN
-- Reset the plaintext output

                pt_output <= (OTHERS => '0');

            ELSIF RISING_EDGE(clk) THEN
 -- Enable or disable the plaintext output based on enable_out signal

                IF enable_out = '1' THEN

                    pt_output <= internal_pt_output;

                ELSIF enable_out = '0' THEN

                    pt_output <= (OTHERS => '0');
                
                END IF;

            END IF;
        
        END PROCESS;

-- Process to update the 128-bit R_output based on the internal state (R_internal)
        integrity_R_state_update_process : PROCESS (clk, rst)
        BEGIN

            IF rst = '1' THEN
 -- Reset the R_output on reset

                R_output <= (OTHERS => '0');

            ELSIF RISING_EDGE(clk) THEN
-- Update the R_output with the computed internal state

                    R_output <= R_internal;

            END IF;

 END PROCESS;

END Behavioral;