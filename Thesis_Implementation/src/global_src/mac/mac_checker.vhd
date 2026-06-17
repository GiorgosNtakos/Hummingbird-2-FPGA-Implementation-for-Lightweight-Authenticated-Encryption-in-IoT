
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY mac_checker IS
PORT(

    clk             : IN  STD_LOGIC;
    rst             : IN  STD_LOGIC;
    mac_check_start : IN  STD_LOGIC_VECTOR (  2 DOWNTO 0);
    T_sender        : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
    T_recipient     : IN  STD_LOGIC_VECTOR (127 DOWNTO 0);
    flag_equal      : OUT  STD_LOGIC

);

END mac_checker;

ARCHITECTURE Behavioral OF mac_checker IS

    SIGNAL mc_flag : STD_LOGIC;

    BEGIN 

        mc_flag <= '1' WHEN T_sender = T_recipient ELSE
                   '0';

        PROCESS(clk, rst,mac_check_start)
        BEGIN 

            IF rst = '1' THEN

                flag_equal <= '0';

            ELSIF RISING_EDGE(clk) THEN

                IF mac_check_start = "101" THEN

                    flag_equal <= mc_flag;

                ELSE

                    flag_equal <= '0';

                END IF;
            
            END IF;

        END PROCESS;

END Behavioral;

        

