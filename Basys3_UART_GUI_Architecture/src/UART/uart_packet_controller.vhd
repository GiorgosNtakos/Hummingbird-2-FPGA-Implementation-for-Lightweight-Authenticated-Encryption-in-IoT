LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY UART_PACKET_CONTROLLER IS
    PORT(
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        ------------------------------
        -- UART RX
        ------------------------------
        rx_data  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        rx_valid : IN STD_LOGIC;

        ------------------------------
        -- UART TX
        -----------------------------
        tx_busy  : IN  STD_LOGIC;
        tx_data  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        tx_start : OUT STD_LOGIC;

        ---------------------------
        -- TO TOP WRAPPER
        ---------------------------
        operation_out  : OUT STD_LOGIC;
        verify_mac_out : OUT STD_LOGIC;
        integrity_out  : OUT STD_LOGIC;

        text_len_out   : OUT INTEGER RANGE 1 TO 128;

        key_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        iv_out  : OUT STD_LOGIC_VECTOR( 63 DOWNTO 0);

        data_input_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);

        received_mac_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);

        start_crypto : OUT STD_LOGIC;

        -----------------------------
        -- FROM TOP WRAPPER
        -----------------------------
        data_output_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        mac_tag_in     : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        latency_cycles_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);

        mac_valid_in   : IN STD_LOGIC;

        done_crypto  : IN STD_LOGIC;
        --busy_crypto  : IN STD_LOGIC;

        --------------------------
        -- LED DEBUGGING SIGNALS
        --------------------------
        packet_received_out : OUT STD_LOGIC;
        crypto_done_out     : OUT STD_LOGIC
     --   rx_byte_counter_dbg : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)

    );
END ENTITY;

ARCHITECTURE Behavioral OF UART_PACKET_CONTROLLER IS
    
    TYPE state_t IS(
        IDLE,

        RX_TEXTLEN_PACKET,
        RX_KEY_PACKET,
        RX_IV_PACKET,
        RX_DATA_PACKET,
        RX_MAC_PACKET,

        START_CRYPTO_STATE,
        WAIT_CRYPTO_STATE,

        TX_PREPARE_BYTE,
        TX_SEND_BYTE,
        TX_WAIT_BUSY_HIGH,
        TX_WAIT_BUSY_LOW
    );

    SIGNAL current_state : state_t := IDLE;

    SIGNAL start_crypto_reg : STD_LOGIC := '0';

    ----------------------------------------------
    -- RX PACKET REGISTERS
    ----------------------------------------------
    SIGNAL flags_reg        : STD_LOGIC_VECTOR(  7 DOWNTO 0);    
    SIGNAL text_len_reg     : STD_LOGIC_VECTOR(  7 DOWNTO 0);
    SIGNAL key_reg          : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL iv_reg           : STD_LOGIC_VECTOR( 63 DOWNTO 0) := (OTHERS => '0');   
    SIGNAL data_reg         : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
    SIGNAL received_mac_reg : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');

    ------------------------------------------------
    -- COUNTERS
    ------------------------------------------------
    SIGNAL rx_byte_counter : INTEGER RANGE 0 TO 57 := 0;
    SIGNAL tx_byte_counter : INTEGER RANGE 0 TO 34 := 0;

    ----------------------------------------------
    -- TX  REGISTERS 
    ----------------------------------------------
    SIGNAL tx_byte_selected : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tx_data_reg     : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tx_start_reg    : STD_LOGIC := '0';

    -------------------------------------
    -- LED DEBUGGING SIGNALS
    ------------------------------------
    SIGNAL packet_received_dbg : STD_LOGIC := '0';
    SIGNAL crypto_done_dbg     : STD_LOGIC := '0';
   -- signal tx_sent_counter_dbg : integer range 0 to 255 := 0;

BEGIN

    PROCESS(clk)
    BEGIN

        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                current_state <= IDLE;
              --  tx_sent_counter_dbg <= 0;

                rx_byte_counter <= 0;
                tx_byte_counter <= 0;

                tx_start_reg <= '0';

                start_crypto_reg <= '0';

                flags_reg <= (OTHERS => '0');
                text_len_reg <= (OTHERS => '0');

                packet_received_dbg <= '0';
                crypto_done_dbg <= '0';

            ELSE
                ------------------------------
                -- DEFAULTS
                ------------------------------
                tx_start_reg <= '0';
                start_crypto_reg <= '0';

                ---------------------------
                -- FSM
                ---------------------------
                CASE current_state IS
                    WHEN IDLE =>
                        rx_byte_counter <= 0;
                        tx_byte_counter <= 0;
                        
                        IF rx_valid = '1' THEN
                            ------------------------------
                            -- BYTE 0 = FLAGS
                            ------------------------------
                            flags_reg <= rx_data;

                            rx_byte_counter <= 1;

                            current_state <= RX_TEXTLEN_PACKET;
                        
                        END IF;

                    WHEN RX_TEXTLEN_PACKET =>
                        IF rx_valid = '1' THEN
                            text_len_reg <= rx_data;
                            rx_byte_counter <= 0;
                            current_state <= RX_KEY_PACKET;

                        END IF;

                    WHEN RX_KEY_PACKET =>
                        IF rx_valid = '1' THEN
                            key_reg <= key_reg(119 DOWNTO 0) & rx_data;

                            IF rx_byte_counter = 15 THEN
                                rx_byte_counter <= 0;

                                current_state <= RX_IV_PACKET;

                            ELSE
                                rx_byte_counter <= rx_byte_counter + 1;

                            END IF;

                        END IF;

                    WHEN RX_IV_PACKET =>
                        IF rx_valid = '1' THEN
                            iv_reg <= iv_reg(55 DOWNTO 0) & rx_data;

                            IF rx_byte_counter = 7 THEN
                                rx_byte_counter <= 0;

                                current_state <= RX_DATA_PACKET;

                            ELSE
                                rx_byte_counter <= rx_byte_counter + 1;

                            END IF;

                        END IF;

                    WHEN RX_DATA_PACKET =>
                        IF rx_valid = '1' THEN
                            data_reg <= data_reg(119 DOWNTO 0) & rx_data;

                            IF rx_byte_counter = 15 THEN
                                rx_byte_counter <= 0;

                                current_state <= RX_MAC_PACKET;

                            ELSE
                                rx_byte_counter <= rx_byte_counter + 1;

                            END IF;
                        END IF;

                    WHEN RX_MAC_PACKET =>
                        IF rx_valid = '1' THEN
                            received_mac_reg <= received_mac_reg(119 DOWNTO 0) & rx_data;

                            IF rx_byte_counter = 15 THEN

                                packet_received_dbg <= '1';
                                current_state <= START_CRYPTO_STATE;

                            ELSE
                                rx_byte_counter <= rx_byte_counter + 1;

                            END IF;

                        END IF;


                    WHEN START_CRYPTO_STATE =>
                        start_crypto_reg <= '1';

                        tx_byte_counter  <= 0;
                        current_state <= WAIT_CRYPTO_STATE;

                    WHEN WAIT_CRYPTO_STATE =>
                        IF done_crypto = '1' THEN
                            crypto_done_dbg <= '1';

                            tx_byte_counter <= 0;

                            current_state <= TX_PREPARE_BYTE;

                        END IF;

                    WHEN TX_PREPARE_BYTE =>
                        CASE tx_byte_counter IS
                            ------------------------------
                            -- DATA OUTPUT
                            ------------------------------
                            WHEN 0 TO 15 =>
                                tx_byte_selected <= data_output_in(127 - 8*tx_byte_counter DOWNTO 120 - 8*tx_byte_counter);
                                
                            -----------------------------
                            -- MAC TAG
                            -----------------------------
                            WHEN 16 TO 31 =>
                                tx_byte_selected <= mac_tag_in(127 - 8*(tx_byte_counter - 16) DOWNTO 120 - 8*(tx_byte_counter - 16));

                            ------------------------------
                            -- MAC VALID
                            ------------------------------
                            WHEN 32 =>
                                tx_byte_selected <= "0000000" & mac_valid_in;

                            WHEN 33 =>
                                tx_byte_selected <= latency_cycles_in(15 DOWNTO 8);
                            
                            WHEN 34 =>
                                tx_byte_selected <= latency_cycles_in( 7 DOWNTO 0);

                            WHEN OTHERS =>
                                tx_byte_selected <= x"00";

                        END CASE;

                        current_state <= TX_SEND_BYTE;

                    WHEN TX_SEND_BYTE =>
                        tx_data_reg <= tx_byte_selected;
                        tx_start_reg <= '1';
                        current_state <= TX_WAIT_BUSY_HIGH;

                    WHEN TX_WAIT_BUSY_HIGH =>
                        IF tx_busy = '1' THEN
                            current_state <= TX_WAIT_BUSY_LOW;

                        END IF;

                    WHEN TX_WAIT_BUSY_LOW =>
                        IF tx_busy = '0' THEN
                            IF tx_byte_counter = 34 THEN
                                current_state <= IDLE;

                            ELSE
                                tx_byte_counter <= tx_byte_counter + 1;

                                current_state <= TX_PREPARE_BYTE;
                            END IF;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

    tx_data      <= tx_data_reg;
    tx_start     <= tx_start_reg;
    start_crypto <= start_crypto_reg;

    operation_out  <= flags_reg(0);
    integrity_out  <= flags_reg(1);
    verify_mac_out <= flags_reg(2);

    key_out <= key_reg;
    iv_out  <= iv_reg;
    data_input_out <= data_reg;
    received_mac_out <= received_mac_reg;
    
    text_len_out <= 1 WHEN TO_INTEGER(UNSIGNED(text_len_reg)) = 0
            ELSE    TO_INTEGER(UNSIGNED(text_len_reg));

    packet_received_out <= packet_received_dbg;
    crypto_done_out     <= crypto_done_dbg;
   -- rx_byte_counter_dbg <= STD_LOGIC_VECTOR(TO_UNSIGNED(tx_sent_counter_dbg, 8));
END ARCHITECTURE;

