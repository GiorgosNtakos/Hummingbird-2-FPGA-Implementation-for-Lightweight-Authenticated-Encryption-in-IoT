LIBRARY IEEE; 
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY wd_16 IS

    PORT(

        clk         :   IN  STD_LOGIC; -- Clock signal
        rst         :   IN  STD_LOGIC; -- Reset signal (active high)
        data_input  :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16-bit input data to be processed
        start       :   IN  STD_LOGIC;
        key         :   IN  STD_LOGIC_VECTOR(63 DOWNTO 0); -- 64-bit key input for permutation
        data_output :   OUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- 16-bit output after permutation
        done        :   OUT STD_LOGIC

    );
END ENTITY wd_16;


ARCHITECTURE Behavioral OF wd_16 IS


    -- Internal signals to hold intermediate data for the 64-bit input block and output of 48 bits 
    SIGNAL internal_data_in  : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL internal_data_out : STD_LOGIC_VECTOR(47 DOWNTO 0);
    SIGNAL done_1, done_2, done_3: STD_LOGIC := '0';

BEGIN

    -- Process to XOR the input data and key for 4 stages (16 bits each)
    -- The XOR is applied in chunks of 16 bits using parts of the 64-bit key
    -- The internal_data_in signal is filled by XORing the input data with parts of the key


    -- Step 1: XOR the 16-bit data_input with the uppermost part of the key (bits 63 to 48)
            internal_data_in(15 DOWNTO  0) <= data_input                 XOR key(63 DOWNTO 48);

    -- Step 2: XOR the output of the first nmf stage with the next part of the key (bits 47 to 32)
            internal_data_in(31 DOWNTO 16) <= internal_data_out(15 DOWNTO  0) XOR key(47 DOWNTO 32);

    -- Step 3: XOR the output of the second nmf stage with the next part of the key (bits 31 to 16)
            internal_data_in(47 DOWNTO 32) <= internal_data_out(31 DOWNTO 16) XOR key(31 DOWNTO 16);

    -- Step 4: XOR the output of the third nmf stage with the last part of the key (bits 15 to 0)
            internal_data_in(63 DOWNTO 48) <= internal_data_out(47 DOWNTO 32) XOR key(15 DOWNTO  0);


-- Instantiate the first nmf (nonlinear mixing function) for the first 16 bits
    nmf_1 : ENTITY work.nmf
        
            PORT MAP(

                clk               => clk,
                rst               => rst,
                start             => start,
                word_input        => internal_data_in  (15 DOWNTO 0), -- Input to the first nmf stage
                mixed_word_output => internal_data_out (15 DOWNTO 0),  -- Output from the first nmf stage
                done              => done_1

            );


-- Instantiate the second nmf for the next 16 bits
    nmf_2 : ENTITY work.nmf
        
            PORT MAP(

                clk               => clk,
                rst               => rst,
                start             => done_1,
                word_input        => internal_data_in  (31 DOWNTO 16), -- Input to the second nmf stage
                mixed_word_output => internal_data_out (31 DOWNTO 16), -- Output from the second nmf stage
                done              => done_2

            );


-- Instantiate the third nmf for the next 16 bits
    nmf_3 : ENTITY work.nmf

            PORT MAP(

                start             => done_2, 
                clk               => clk,
                rst               => rst,
                word_input        => internal_data_in  (47 DOWNTO 32), -- Input to the third nmf stage
                mixed_word_output => internal_data_out (47 DOWNTO 32),  -- Output from the third nmf stage
                done              => done_3

            );


-- Instantiate the fourth nmf for the final 16 bits
    nmf_4 : ENTITY work.nmf
    
            PORT MAP(

                start             => done_3,
                clk               => clk,
                rst               => rst,
                word_input        => internal_data_in  (63 DOWNTO 48), -- Input to the fourth nmf stage
                mixed_word_output => data_output,  -- Final output after the fourth nmf stage
                done              => done

            );

END ARCHITECTURE Behavioral;
