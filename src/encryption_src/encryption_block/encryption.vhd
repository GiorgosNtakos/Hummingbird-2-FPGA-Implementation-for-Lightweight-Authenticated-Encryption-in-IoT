-- This module handles the encryption process using a block cipher.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Encryption IS
PORT(

    clk            : IN  STD_LOGIC; -- Clock signal
    rst            : IN  STD_LOGIC; -- Reset signal (active high)
    enable_out     : IN  STD_LOGIC; -- Enable signal for output control
    pt_input       : IN  STD_LOGIC_VECTOR ( 15 DOWNTO 0); -- 16-bit plaintext input
    R_input        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- 128-bit R internal state
    key            : IN  STD_LOGIC_VECTOR (127 DOWNTO 0); -- 128-bit key
    ct_output      : OUT STD_LOGIC_VECTOR ( 15 DOWNTO 0); -- 16-bit ciphertext output
    R_output       : OUT STD_LOGIC_VECTOR (127 DOWNTO 0) -- Updated 128-bit R internal state

);

END Encryption;

ARCHITECTURE Behavioral OF Encryption IS

-- Signals for wd_16 inputs, outputs, and intermediate results
    SIGNAL wd_input_1, wd_input_2, wd_input_3, wd_input_4 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL t_1, t_2, t_3, t_4       :                       STD_LOGIC_VECTOR(15 DOWNTO 0);

-- XOR outputs of key segments and R_input segments
    SIGNAL KxR_1, KxR_2      : STD_LOGIC_VECTOR(63 DOWNTO 0);
    
-- Signals for addition and modulo results
    SIGNAL add_result1, add_result2, add_result3, add_result4 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL mod_result1, mod_result2, mod_result3, mod_result4 : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL done_1, done_2, done_3, done_4 : STD_LOGIC;


    BEGIN

-- Perform first XOR between key(63:0) and R_input(63:0)
                KxR_1 <= key(63 DOWNTO 0) XOR R_input(63 DOWNTO 0);

-- Perform second XOR between key(127:64) and R_input(63:0)
                KxR_2 <= key(127 DOWNTO 64) XOR R_input(63 DOWNTO 0);

-- Process to handle wd_input signals based on R_input and plaintext input
        process_reg_wd_inputs : PROCESS(clk, rst)
        BEGIN
            
            IF rst = '1' THEN
-- Reset all wd_input values on reset

                wd_input_1    <= (OTHERS => '0');
                wd_input_2    <= (OTHERS => '0');
                wd_input_3    <= (OTHERS => '0');
                wd_input_4    <= (OTHERS => '0');
                

            ELSIF RISING_EDGE(clk) THEN
-- Calculate wd_input values using R_input and t outputs

                        wd_input_1 <= STD_LOGIC_VECTOR((UNSIGNED(R_input(127 DOWNTO 112)) + UNSIGNED(pt_input)) MOD 65536);
                        wd_input_2 <= STD_LOGIC_VECTOR((UNSIGNED(R_input(111 DOWNTO  96)) + UNSIGNED(t_1)) MOD 65536);
                        wd_input_3 <= STD_LOGIC_VECTOR((UNSIGNED(R_input( 95 DOWNTO  80)) + UNSIGNED(t_2)) MOD 65536);
                        wd_input_4 <= STD_LOGIC_VECTOR((UNSIGNED(R_input( 79 DOWNTO  64)) + UNSIGNED(t_3)) MOD 65536);

            END IF;

        END PROCESS;

-- Instantiate wd_16 modules to perform nonlinear transformations

        wd_16_enc_t1 : ENTITY work.wd_16

        PORT MAP (

            clk         => clk,
            rst         => rst,
            data_input  => wd_input_1,
            key         => key(127 DOWNTO 64),
            data_output => t_1,
            start       => '1',
            done        => done_1

        );

        wd_16_enc_t2 : ENTITY work.wd_16

        PORT MAP (

            clk         => clk,
            rst         => rst,
            data_input  => wd_input_2,
            key         => KxR_1,
            data_output => t_2,
            start       => '1',
            done        => done_2

        );

        wd_16_enc_t3 : ENTITY work.wd_16

        PORT MAP (

            clk         => clk,
            rst         => rst,
            data_input  => wd_input_3,
            key         => KxR_2,
            data_output => t_3,
            start       => '1',
            done        => done_3

        );

        wd_16_enc_t4 : ENTITY work.wd_16

        PORT MAP (

            clk         => clk,
            rst         => rst,
            data_input  => wd_input_4,
            key         => key(63 DOWNTO 0),
            data_output => t_4,
            start       => '1',
            done        => done_4

        );

 -- Process to handle addition of R_input segments with t outputs
        process_additions : PROCESS(clk, rst)
        BEGIN

            IF rst = '1' THEN
 -- Reset addition results on reset

                add_result1 <= (OTHERS => '0');
                add_result2 <= (OTHERS => '0');
                add_result3 <= (OTHERS => '0');
                add_result4 <= (OTHERS => '0');

                mod_result1 <= (OTHERS => '0');
                mod_result2 <= (OTHERS => '0');
                mod_result3 <= (OTHERS => '0');
                mod_result4 <= (OTHERS => '0');

            ELSIF RISING_EDGE(clk) THEN
-- Perform addition operations for each R_input segment and t outputs

                add_result1 <= STD_LOGIC_VECTOR(UNSIGNED(R_input(127 DOWNTO 112)) + UNSIGNED(t_3));
                add_result2 <= STD_LOGIC_VECTOR(UNSIGNED(R_input(111 DOWNTO 96)) + UNSIGNED(t_1));
                add_result3 <= STD_LOGIC_VECTOR(UNSIGNED(R_input(95 DOWNTO 80)) + UNSIGNED(t_2));
                add_result4 <= STD_LOGIC_VECTOR(UNSIGNED(R_input(79 DOWNTO 64)) + UNSIGNED(R_input(127 DOWNTO 112)) + UNSIGNED(t_3) + UNSIGNED(t_1));

                mod_result1 <= STD_LOGIC_VECTOR(UNSIGNED(add_result1) MOD 65536);
                mod_result2 <= STD_LOGIC_VECTOR(UNSIGNED(add_result2) MOD 65536);
                mod_result3 <= STD_LOGIC_VECTOR(UNSIGNED(add_result3) MOD 65536);
                mod_result4 <= STD_LOGIC_VECTOR(UNSIGNED(add_result4) MOD 65536);

            END IF;

        END PROCESS;

-- Assign results of modulo operations to R_output
        R_output(127 DOWNTO 112) <= mod_result1;
        R_output(111 DOWNTO 96) <= mod_result2;
        R_output(95 DOWNTO 80)  <= mod_result3;
        R_output(79 DOWNTO 64)  <= mod_result4;

-- XOR remaining R_input segments with modulo results to update R_output
        R_output(63 DOWNTO 48) <= R_input(63 DOWNTO 48) XOR mod_result1; 
        R_output(47 DOWNTO 32) <= R_input(47 DOWNTO 32) XOR mod_result2;
        R_output(31 DOWNTO 16) <= R_input(31 DOWNTO 16) XOR mod_result3;
        R_output(15 DOWNTO 0)  <= R_input(15 DOWNTO 0) XOR mod_result4;

 -- Calculate internal ciphertext (internal_ct) based on t_4 and R_input
    WITH enable_out SELECT
    ct_output <= STD_LOGIC_VECTOR((UNSIGNED(t_4) + UNSIGNED(R_input(127 DOWNTO 112))) MOD 65536) WHEN '1',
                (OTHERS => '0') WHEN OTHERS;
                
END Behavioral;