LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY UART_TX IS
    PORT(
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        tx_start : IN STD_LOGIC;
        tx_data  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

        tx       : OUT STD_LOGIC;
        tx_busy  : OUT STD_LOGIC

    );
END ENTITY UART_TX;

ARCHITECTURE Behavioral OF UART_TX IS

    CONSTANT BAUD_TICKS : INTEGER := 868;

    TYPE state_t IS(
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    );

    SIGNAL current_state : state_t := IDLE;
    SIGNAL baud_counter  : INTEGER RANGE 0 TO BAUD_TICKS - 1 := 0;
    SIGNAL bit_counter   : INTEGER RANGE 0 TO 7 := 0;
    SIGNAL tx_shift_reg  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL tx_reg   : STD_LOGIC := '1';
    SIGNAL busy_reg : STD_LOGIC := '0';

BEGIN
    
    PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                current_state <= IDLE;

                baud_counter <= 0;
                bit_counter  <= 0;
                
                tx_shift_reg <= (OTHERS => '0');

                tx_reg   <= '1';
                busy_reg <= '0';

            ELSE
                CASE current_state IS
                    --------------------------------
                    -- IDLE
                    --------------------------------
                    WHEN IDLE =>
                        tx_reg <= '1';
                        busy_reg <= '0';

                        baud_counter <= 0;
                        bit_counter  <= 0;

                        IF tx_start = '1' THEN
                            tx_shift_reg <= tx_data;
                            busy_reg <= '1';

                            current_state <= START_BIT;

                        END IF;

                    ----------------------------------
                    -- START BIT
                    ----------------------------------
                    WHEN START_BIT =>
                        tx_reg <= '0';

                        IF baud_counter = BAUD_TICKS - 1 THEN
                            baud_counter <= 0;
                            current_state <= DATA_BITS;

                        ELSE
                            baud_counter <= baud_counter + 1;

                        END IF;

                    ---------------------------------
                    -- DATA BITS
                    ---------------------------------
                    WHEN DATA_BITS =>
                        tx_reg <= tx_shift_reg(bit_counter);

                        IF baud_counter = BAUD_TICKS - 1 THEN
                            baud_counter <= 0;

                            IF bit_counter = 7 THEN
                                bit_counter <= 0;

                                current_state <= STOP_BIT;

                            ELSE
                                bit_counter <= bit_counter + 1;

                            END IF;

                        ELSE
                            baud_counter <= baud_counter + 1;

                        END IF;

                    ----------------------------------------
                    -- STOP BIT
                    ----------------------------------------
                    WHEN STOP_BIT =>
                        tx_reg <= '1';

                        IF baud_counter = BAUD_TICKS - 1 THEN
                            baud_counter <= 0;

                            current_state <= IDLE;

                        ELSE
                            baud_counter <= baud_counter + 1; 

                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    tx      <= tx_reg;
    tx_busy <= busy_reg;

END ARCHITECTURE Behavioral;
