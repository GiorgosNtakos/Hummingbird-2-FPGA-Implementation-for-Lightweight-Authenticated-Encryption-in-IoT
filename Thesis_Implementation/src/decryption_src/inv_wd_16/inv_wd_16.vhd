-- This entity defines the inverse of the wd_16 operation.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY inv_wd_16 IS

    PORT(

        clk         :   IN  STD_LOGIC; -- Clock signal
        rst         :   IN  STD_LOGIC; -- Reset signal (active high)
        inv_data_input  :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16-bit mixed input data (encrypted data)
        key         :   IN  STD_LOGIC_VECTOR(63 DOWNTO 0); -- 64-bit key used for decryption
        inv_data_output :   OUT STD_LOGIC_VECTOR(15 DOWNTO 0) -- 16-bit output (decrypted data)

    );
END ENTITY inv_wd_16;


ARCHITECTURE Behavioral OF inv_wd_16 IS
     
  --Internal signals
  --Internal_data_in: Signal of the internal data in a of the non linear mix functions(inv_nmf)
  --Internal_data_out: Signal of the internal outputs of inv_nmf
  --Reg_data_out : Signal of the internal ouput of the registed that holds the output of each inv_nmf

    SIGNAL inv_internal_data_in  : STD_LOGIC_VECTOR(47 DOWNTO 0); -- Holds intermediate 48-bit data
    SIGNAL inv_internal_data_out : STD_LOGIC_VECTOR(63 DOWNTO 0); -- Holds 64-bit output of inv_nmf functions
    SIGNAL inv_reg_data_out      : STD_LOGIC_VECTOR(63 DOWNTO 0);  -- Holds registered output for final result

BEGIN

    PROCESS(clk,rst)
    BEGIN

        IF rst = '1' THEN

        -- Reset all internal signals to zero
            inv_internal_data_in <= (OTHERS => '0');
            inv_reg_data_out     <= (OTHERS => '0');

        ELSIF RISING_EDGE(clk) THEN
        -- XOR operation between the internal output and key at each stage

        -- Stage 1: XOR the output of inv_nmf_1 with part of the key
            inv_internal_data_in(15 DOWNTO  0)  <= inv_internal_data_out(15 DOWNTO  0) XOR key(15 DOWNTO  0);

        -- Stage 2: XOR the output of inv_nmf_2 with part of the key
            inv_internal_data_in(31 DOWNTO 16)  <= inv_internal_data_out(31 DOWNTO 16) XOR key(31 DOWNTO 16);

        -- Stage 3: XOR the output of inv_nmf_3 with part of the key
            inv_internal_data_in(47 DOWNTO 32)  <= inv_internal_data_out(47 DOWNTO 32) XOR key(47 DOWNTO 32);

        END IF;
    END PROCESS;

 -- Instantiate the first inv_nmf (inverse nonlinear mixing function) for the first 16 bits
    inv_nmf_1 : ENTITY work.inv_nmf
        
            PORT MAP(

                clk               => clk,
                rst               => rst,
                mixed_word_input  => inv_data_input, -- Input to the first inv_nmf stage (16 bits)
                word_output       => inv_internal_data_out (15 DOWNTO 0) -- Output from the first inv_nmf stage (16 bits)

            );

 -- Instantiate the second inv_nmf for the next 16 bits
    inv_nmf_2 : ENTITY work.inv_nmf
        
            PORT MAP(

                clk               => clk,
                rst               => rst,
                mixed_word_input  => inv_internal_data_in  (15 DOWNTO  0), -- Input to the second inv_nmf stage
                word_output       => inv_internal_data_out (31 DOWNTO 16)  -- Output from the second inv_nmf stage

            );

    inv_nmf_3 : ENTITY work.inv_nmf
        
            PORT MAP(

                clk               => clk,
                rst               => rst,
                mixed_word_input  => inv_internal_data_in  (31 DOWNTO 16), -- Input to the third inv_nmf stage
                word_output       => inv_internal_data_out (47 DOWNTO 32)  -- Output from the third inv_nmf stage

            );

    inv_nmf_4 : ENTITY work.inv_nmf
        
            PORT MAP(

                clk               => clk,
                rst               => rst,
                mixed_word_input  => inv_internal_data_in  (47 DOWNTO 32), -- Input to the fourth inv_nmf stage
                word_output       => inv_internal_data_out (63 DOWNTO 48) -- Output from the fourth inv_nmf stage

            );

-- Final XOR operation between the output of the last stage and the final part of the key
    inv_data_output <= inv_internal_data_out(63 DOWNTO  48) XOR key(63 DOWNTO 48);
            
END ARCHITECTURE Behavioral;