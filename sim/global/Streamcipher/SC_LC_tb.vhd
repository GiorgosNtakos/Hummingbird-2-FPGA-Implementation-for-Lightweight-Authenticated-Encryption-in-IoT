LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY SC_LC_TB IS
END SC_LC_TB;

ARCHITECTURE behavior OF SC_LC_TB IS 

    COMPONENT SC_LC
    PORT(

        text_len         : IN  INTEGER RANGE 1 TO 128;
        Enable_Signals   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        n                : OUT INTEGER RANGE 1 TO  8

    );
    END COMPONENT;

    --Inputs
    SIGNAL text_len : INTEGER RANGE 1 TO 128 := 1;

    --Outputs
    SIGNAL Enable_Signals : STD_LOGIC_VECTOR( 7 DOWNTO 0);
    SIGNAL n              : INTEGER RANGE 1 TO  8;

BEGIN

    uut: SC_LC PORT MAP (

        text_len         => text_len,
        Enable_Signals   => Enable_Signals,
        n                => n
    );

    stim_proc: PROCESS
    BEGIN        
        -- hold for 20 ns.
        WAIT FOR 20 ns;  

        -- Test different values for text_len
        text_len    <= 1;
        WAIT FOR 20 ns;
        
        text_len <= 17;
        WAIT FOR 20 ns;

        text_len <= 33;
        WAIT FOR 20 ns;
        
        text_len <= 49;
        WAIT FOR 20 ns;

        text_len <= 65;
        WAIT FOR 20 ns;

        text_len <= 81;
        WAIT FOR 20 ns;

        text_len <= 97;
        WAIT FOR 20 ns;

        text_len <= 113;
        WAIT FOR 20 ns;

        text_len <= 16;
        WAIT FOR 20 ns;
        
        text_len <= 32;
        WAIT FOR 20 ns;
        
        text_len <= 48;
        WAIT FOR 20 ns;

        text_len <= 64;
        WAIT FOR 20 ns;

        text_len <= 80;
        WAIT FOR 20 ns;

        text_len <= 96;
        WAIT FOR 20 ns;

        text_len <= 112;
        WAIT FOR 20 ns;

        text_len <= 128;
        WAIT FOR 20 ns;

        text_len <= 2;
        WAIT FOR 20 ns;

        text_len <= 18;
        WAIT FOR 20 ns;

        text_len <= 34;
        WAIT FOR 20 ns;

        text_len <= 50;
        WAIT FOR 20 ns;

        text_len <= 66;
        WAIT FOR 20 ns;

        text_len <= 82;
        WAIT FOR 20 ns;

        text_len <= 98;
        WAIT FOR 20 ns;

        text_len <= 114;
        WAIT FOR 20 ns;

        -- Stop the simulation
        WAIT;

    END PROCESS;
END;
