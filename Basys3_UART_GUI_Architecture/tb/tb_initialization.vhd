LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_initialization IS
END ENTITY;

ARCHITECTURE sim OF tb_initialization IS

    ------------------------------------
    -- DUT Signals
    ------------------------------------
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '1';

    SIGNAL start_init : STD_LOGIC := '0';

    SIGNAL iv  : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL key : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL R_output : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL done : STD_LOGIC;
    SIGNAL busy : STD_LOGIC;

    CONSTANT clk_period : TIME := 10 ns;

BEGIN

    ------------------------------------
    -- Clock
    ------------------------------------
    clk_process : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR clk_period/2;

        clk <= '1';
        WAIT FOR clk_period/2;
    END PROCESS;

    ------------------------------------
    -- DUT
    ------------------------------------
    DUT : ENTITY work.Initialization
    PORT MAP(
        clk        => clk,
        rst        => rst,

        start_init => start_init,

        iv         => iv,
        key        => key,

        R_output   => R_output,

        done       => done,
        busy       => busy
    );

    ------------------------------------
    -- Stimulus
    ------------------------------------
    PROCESS
    BEGIN

        --------------------------------
        -- ΒΑΛΕ ΤΑ ΙΔΙΑ VECTORS
        -- ΠΟΥ ΧΡΗΣΙΜΟΠΟΙΕΙΣ ΣΤΟ TOP
        --------------------------------
        key <= (OTHERS => '0');
        iv  <= (OTHERS => '0');

        --------------------------------
        -- Reset
        --------------------------------
        rst <= '1';

        WAIT FOR 50 ns;

        rst <= '0';

        WAIT FOR 20 ns;

        --------------------------------
        -- Start
        --------------------------------
        start_init <= '1';

        WAIT FOR clk_period;

        start_init <= '0';

        --------------------------------
        -- Wait
        --------------------------------
        WAIT UNTIL done = '1';

        REPORT "INITIALIZATION FINISHED";

        WAIT FOR 50 ns;

        --------------------------------
        -- CHECK EXPECTED VALUE
        --------------------------------

        ASSERT R_output =
        x"3DD095167311FA1B128F630E2B7D06B8"
        REPORT "R_OUTPUT MISMATCH"
        SEVERITY ERROR;

        WAIT;

    END PROCESS;

END ARCHITECTURE;