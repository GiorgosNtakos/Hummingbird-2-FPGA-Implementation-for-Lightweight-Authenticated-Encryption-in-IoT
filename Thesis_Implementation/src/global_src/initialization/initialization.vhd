-- This entity defines the initialization process in the cryptographic algorithm.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY Initialization IS

	PORT(

		clk 		   : IN  STD_LOGIC; -- Clock signal
		rst		       : IN  STD_LOGIC; -- Reset signal (active high)
        start_init     : IN  STD_LOGIC_VECTOR (  2  DOWNTO 0); -- Start signal for initialization
		iv    		   : IN  STD_LOGIC_VECTOR ( 63  DOWNTO 0); -- Initialization vector (64 bits)
		key 		   : IN  STD_LOGIC_VECTOR (127  DOWNTO 0); -- Secret key (128 bits)
		R_output       : OUT STD_LOGIC_VECTOR (127  DOWNTO 0) -- Output of the initialization

	);

END Initialization;

ARCHITECTURE Behavioral OF Initialization IS


TYPE my_array  IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(15 DOWNTO 0);

-- Signals to hold intermediate and pipeline results during initialization
    SIGNAL R_in     : my_array (1 TO  8);  -- Holds input values for each round of initialization
    SIGNAL R        : my_array (1 TO 32); -- Holds the 128-bit internal state of the cipher
    SIGNAL wd_input : my_array (1 TO 4); -- Holds input to wd_16 modules
    SIGNAL t        : my_array (1 TO 4);  -- Holds output from wd_16 modules
    SIGNAL start      : STD_LOGIC;
    SIGNAL done_1, done_2, done_3, done_4 : STD_LOGIC;

    -- Additional pipeline signals for R_temp
    SIGNAL add_result_rtemp : my_array (1 TO 4); -- Result of addition operations
    SIGNAL mod_result_rtemp : my_array (1 TO 4); -- Result of modulo operations
    SIGNAL add_result_wd  : my_array (1 TO 4); -- Result of wd_16 addition
    SIGNAL mod_result_wd  : my_array (1 TO 4); -- Result of wd_16 modulo operation
    SIGNAL i_counter      : INTEGER RANGE 0 TO 4;
    SIGNAL start_counter  : INTEGER RANGE 0 TO 16;
    SIGNAL start_round    : STD_LOGIC;

    SIGNAL prev_iv  : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL prev_key : STD_LOGIC_VECTOR(127 DOWNTO 0);

BEGIN

start <= '1' WHEN start_init = "001" ELSE
         '0';


    -- Initialize R_in for the first round (i = 0) using the initialization vector (IV)
    R_in(1) <= iv(63 DOWNTO 48);
    R_in(2) <= iv(47 DOWNTO 32);
    R_in(3) <= iv(31 DOWNTO 16);
    R_in(4) <= iv(15 DOWNTO  0);
    -- Repeat the IV values for the other part of the internal state
    R_in(5) <= iv(63 DOWNTO 48); 
    R_in(6) <= iv(47 DOWNTO 32);
    R_in(7) <= iv(31 DOWNTO 16);
    R_in(8) <= iv(15 DOWNTO  0);

    PROCESS (clk,rst) 
    BEGIN
    IF rst = '1' THEN

        prev_iv <= (OTHERS => '0');
        prev_key <= (OTHERS => '0');

        R <= (OTHERS => (OTHERS => '0'));
        R_output <= (OTHERS => '0');

        add_result_wd(1) <= (OTHERS => '0');
        add_result_wd(2) <= (OTHERS => '0');
        add_result_wd(3) <= (OTHERS => '0');
        add_result_wd(4) <= (OTHERS => '0');

        mod_result_wd(1) <= (OTHERS => '0');
        mod_result_wd(2) <= (OTHERS => '0');
        mod_result_wd(3) <= (OTHERS => '0');
        mod_result_wd(4) <= (OTHERS => '0');

        wd_input(1) <= (OTHERS => '0');
        wd_input(2) <= (OTHERS => '0');
        wd_input(3) <= (OTHERS => '0');
        wd_input(4) <= (OTHERS => '0');

        add_result_rtemp(1) <= (OTHERS => '0');
        add_result_rtemp(2) <= (OTHERS => '0');
        add_result_rtemp(3) <= (OTHERS => '0');
        add_result_rtemp(4) <= (OTHERS => '0');

        mod_result_rtemp(1) <= (OTHERS => '0');
        mod_result_rtemp(2) <= (OTHERS => '0');
        mod_result_rtemp(3) <= (OTHERS => '0');
        mod_result_rtemp(4) <= (OTHERS => '0');


        start_round <= '0';

    ELSIF RISING_EDGE(clk) THEN
    
        CASE i_counter IS

        WHEN 0 =>
            start_round <= start;
            add_result_wd(1) <= STD_LOGIC_VECTOR(UNSIGNED(R_in(1)) + UNSIGNED(TO_UNSIGNED(i_counter, 16)));
            add_result_wd(2) <= STD_LOGIC_VECTOR(UNSIGNED(R_in(2)) + UNSIGNED(t(1)));
            add_result_wd(3) <= STD_LOGIC_VECTOR(UNSIGNED(R_in(3)) + UNSIGNED(t(2)));
            add_result_wd(4) <= STD_LOGIC_VECTOR(UNSIGNED(R_in(4)) + UNSIGNED(t(3)));

            mod_result_wd(1) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_wd(1)) MOD 65536);
            mod_result_wd(2) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_wd(2)) MOD 65536);
            mod_result_wd(3) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_wd(3)) MOD 65536);
            mod_result_wd(4) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_wd(4)) MOD 65536);

            add_result_rtemp(1) <= STD_LOGIC_VECTOR(UNSIGNED(R_in(1)) + UNSIGNED(t(4)));
            add_result_rtemp(2) <= STD_LOGIC_VECTOR(UNSIGNED(R_in(2)) + UNSIGNED(t(1)));
            add_result_rtemp(3) <= STD_LOGIC_VECTOR(UNSIGNED(R_in(3)) + UNSIGNED(t(2)));
            add_result_rtemp(4) <= STD_LOGIC_VECTOR(UNSIGNED(R_in(4)) + UNSIGNED(t(3)));

            mod_result_rtemp(1) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_rtemp(1)) MOD 65536);
            mod_result_rtemp(2) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_rtemp(2)) MOD 65536);
            mod_result_rtemp(3) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_rtemp(3)) MOD 65536);
            mod_result_rtemp(4) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_rtemp(4)) MOD 65536);

            wd_input(1) <= mod_result_wd(1);
            wd_input(2) <= mod_result_wd(2);
            wd_input(3) <= mod_result_wd(3);
            wd_input(4) <= mod_result_wd(4);

                R(1) <= mod_result_rtemp(1)(12 DOWNTO 0) & mod_result_rtemp(1)(15 DOWNTO 13);
                R(2) <= mod_result_rtemp(2)(          0) & mod_result_rtemp(2)(15 DOWNTO  1);
                R(3) <= mod_result_rtemp(3)( 7 DOWNTO 0) & mod_result_rtemp(3)(15 DOWNTO  8);
                R(4) <= mod_result_rtemp(4)(14 DOWNTO 0) & mod_result_rtemp(4)(          15);
                R(5) <= R_in(5) XOR R(1);
                R(6) <= R_in(6) XOR R(2);
                R(7) <= R_in(7) XOR R(3);
                R(8) <= R_in(8) XOR R(4);

        WHEN 1 TO 3 =>
            start_round <= start; 
            add_result_wd(1) <= STD_LOGIC_VECTOR(UNSIGNED(R(1 + 8*(i_counter-1))) + UNSIGNED(TO_UNSIGNED(i_counter, 16)));
            add_result_wd(2) <= STD_LOGIC_VECTOR(UNSIGNED(R(2 + 8*(i_counter-1))) + UNSIGNED(t(1)));
            add_result_wd(3) <= STD_LOGIC_VECTOR(UNSIGNED(R(3 + 8*(i_counter-1))) + UNSIGNED(t(2)));
            add_result_wd(4) <= STD_LOGIC_VECTOR(UNSIGNED(R(4 + 8*(i_counter-1))) + UNSIGNED(t(3)));

            mod_result_wd(1) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_wd(1)) MOD 65536);
            mod_result_wd(2) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_wd(2)) MOD 65536);
            mod_result_wd(3) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_wd(3)) MOD 65536);
            mod_result_wd(4) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_wd(4)) MOD 65536);

            add_result_rtemp(1) <= STD_LOGIC_VECTOR(UNSIGNED(R(1 + 8*(i_counter-1))) + UNSIGNED(t(4)));
            add_result_rtemp(2) <= STD_LOGIC_VECTOR(UNSIGNED(R(2 + 8*(i_counter-1))) + UNSIGNED(t(1)));
            add_result_rtemp(3) <= STD_LOGIC_VECTOR(UNSIGNED(R(3 + 8*(i_counter-1))) + UNSIGNED(t(2)));
            add_result_rtemp(4) <= STD_LOGIC_VECTOR(UNSIGNED(R(4 + 8*(i_counter-1))) + UNSIGNED(t(3)));

            mod_result_rtemp(1) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_rtemp(1)) MOD 65536);
            mod_result_rtemp(2) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_rtemp(2)) MOD 65536);
            mod_result_rtemp(3) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_rtemp(3)) MOD 65536);
            mod_result_rtemp(4) <= STD_LOGIC_VECTOR(UNSIGNED(add_result_rtemp(4)) MOD 65536);

            wd_input(1) <= mod_result_wd(1);
            wd_input(2) <= mod_result_wd(2);
            wd_input(3) <= mod_result_wd(3);
            wd_input(4) <= mod_result_wd(4);

                R(9 + 8*(i_counter-1))  <= mod_result_rtemp(1)(12 DOWNTO 0) & mod_result_rtemp(1)(15 DOWNTO 13);
                R(10 + 8*(i_counter-1)) <= mod_result_rtemp(2)(          0) & mod_result_rtemp(2)(15 DOWNTO  1);
                R(11 + 8*(i_counter-1)) <= mod_result_rtemp(3)( 7 DOWNTO 0) & mod_result_rtemp(3)(15 DOWNTO  8);
                R(12 + 8*(i_counter-1)) <= mod_result_rtemp(4)(14 DOWNTO 0) & mod_result_rtemp(4)(          15);
                R(13 + 8*(i_counter-1)) <= R(5 + 8*(i_counter-1)) XOR R(9 + 8*(i_counter-1));
                R(14 + 8*(i_counter-1)) <= R(6 + 8*(i_counter-1)) XOR R(10 + 8*(i_counter-1));
                R(15 + 8*(i_counter-1)) <= R(7 + 8*(i_counter-1)) XOR R(11 + 8*(i_counter-1));
                R(16 + 8*(i_counter-1)) <= R(8 + 8*(i_counter-1)) XOR R(12 + 8*(i_counter-1));

        WHEN 4 =>

        IF (iv /= prev_iv) OR (key /= prev_key) THEN
        -- Αποθήκευση νέων τιμών των εισόδων
        prev_iv <= iv;
        prev_key <= key;

        -- Μηδενισμός του i_counter και έναρξη νέων υπολογισμών
        i_counter <= 0;

   
        END IF;
        

        WITH start_init SELECT
                R_output <= R(25) & R(26) & R(27) & R(28) & R(29) & R(30) & R(31) & R(32) WHEN "001", -- Complete initialization
                    UNAFFECTED                                                   WHEN OTHERS; -- Keep the value unchanged otherwise

        END CASE;

        IF done_4 = '1' THEN
                start_round <= '0';

                IF start_counter < 16 THEN 

                    start_counter <= start_counter + 1;

                ELSE 

                    i_counter <= i_counter + 1;
                    start_counter <= 0;
                
                END IF;
        END IF;


   END IF;

END PROCESS;





wd_16_t1 : ENTITY work.wd_16

PORT MAP (

    clk         => clk,
    rst         => rst,
    data_input  => wd_input(1),
    key         => key(127 DOWNTO 64),
    data_output => t(1),
    start       => start_round,
    done        => done_1

);

wd_16_t2 : ENTITY work.wd_16

        PORT MAP (

            clk         => clk,
            rst         => rst,
            data_input  => wd_input(2),
            key         => key(63 DOWNTO 0),
            data_output => t(2),
            done        => done_2,
            start       => done_1

        );

    wd_16_t3 : ENTITY work.wd_16

        PORT MAP (

            clk         => clk,
            rst         => rst,
            data_input  => wd_input(3),
            key         => key(127 DOWNTO 64),
            data_output => t(3),
            done        => done_3,
            start       => done_2

        );

    wd_16_t4 : ENTITY work.wd_16

        PORT MAP (

            clk         => clk,
            rst         => rst,
            data_input  => wd_input(4),
            key         => key(63 DOWNTO 0),
            data_output => t(4),
            done        => done_4,
            start       => done_3

        );
        END ARCHITECTURE Behavioral;