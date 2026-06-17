LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY UART_RX IS
    PORT(
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        rx : IN STD_LOGIC;

        rx_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rx_valid : OUT STD_LOGIC

    );
END ENTITY UART_RX;

ARCHITECTURE Behavioral OF UART_RX IS

    CONSTANT BAUD_TICKS : INTEGER := 868;
    CONSTANT HALF_BAUD  : INTEGER := 434;

    TYPE state_t IS(
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    );

    SIGNAL current_state : state_t := IDLE;

    SIGNAL baud_counter : INTEGER RANGE 0 TO BAUD_TICKS-1 := 0;
    SIGNAL bit_counter  : INTEGER RANGE 0 TO 7 := 0;

    SIGNAL rx_shift_reg : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL rx_data_reg : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL rx_valid_reg : STD_LOGIC := '0';

BEGIN

    PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                current_state <= IDLE;

                baud_counter <= 0;
                bit_counter  <= 0;

                rx_shift_reg <= (OTHERS => '0');

                rx_data_reg <= (OTHERS => '0');
                rx_valid_reg <= '0';

            ELSE
                rx_valid_reg <= '0';

                CASE current_state IS
                    WHEN IDLE =>
                        baud_counter <= 0;
                        bit_counter <= 0;

                        IF rx = '0' THEN
                            current_state <= START_BIT;

                        END IF;

                    WHEN START_BIT =>
                        IF baud_counter = HALF_BAUD - 1 THEN
                            baud_counter <= 0;

                            IF rx = '0' THEN
                                current_state <= DATA_BITS;

                            ELSE
                                current_state <= IDLE;

                            END IF;

                        ELSE
                            baud_counter <= baud_counter + 1;

                        END IF;

                    WHEN DATA_BITS =>
                        IF baud_counter = BAUD_TICKS - 1 THEN
                            baud_counter <= 0;

                            rx_shift_reg(bit_counter) <= rx;

                            IF bit_counter = 7 THEN
                                bit_counter <= 0;

                                current_state <= STOP_BIT;

                            ELSE
                                bit_counter <= bit_counter + 1;

                            END IF;

                        ELSE
                            baud_counter <= baud_counter + 1;

                        END IF;

                    WHEN STOP_BIT =>
                        IF baud_counter = BAUD_TICKS - 1 THEN
                            baud_counter <= 0;

                            rx_data_reg <= rx_shift_reg;
                            rx_valid_reg <= '1';

                            current_state <= IDLE;

                        ELSE
                            baud_counter <= baud_counter + 1;

                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    rx_data <= rx_data_reg;
    rx_valid <= rx_valid_reg;

END ARCHITECTURE Behavioral;