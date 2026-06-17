LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY UART_Crypto_Wrapper IS
    PORT(
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        uart_rx_pin : IN STD_LOGIC;
        uart_tx_pin : OUT STD_LOGIC;
        
        led : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE Behavioral OF UART_Crypto_Wrapper IS

    -------------------------------
    -- UART RX SIGNALS
    -------------------------------
    SIGNAL rx_data  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rx_valid : STD_LOGIC;

    -------------------------------
    -- UART TX SIGNALS
    -------------------------------
    SIGNAL tx_data  : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tx_start : STD_LOGIC;
    SIGNAL tx_busy  : STD_LOGIC;

    ---------------------------------
    -- CONTROLLER <--> WRAPPER
    ---------------------------------
    SIGNAL operation_sig  : STD_LOGIC;
    SIGNAL verify_mac_sig : STD_LOGIC;
    SIGNAL integrity_sig  : STD_LOGIC;

    SIGNAL key_sig : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL iv_sig  : STD_LOGIC_VECTOR( 63 DOWNTO 0);

    SIGNAL data_input_sig : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL received_mac_sig : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL start_crypto_sig : STD_LOGIC;

    SIGNAL text_len_sig : INTEGER RANGE 1 TO 128;

    SIGNAL data_output_sig : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL mac_tag_sig     : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL mac_valid_sig   : STD_LOGIC;

    SIGNAL done_sig        : STD_LOGIC;
    SIGNAL busy_sig        : STD_LOGIC;

    ---------------------------------
    -- LEDS DEBUGGING SIGNALS
    ---------------------------------
    SIGNAL packet_received_dbg : STD_LOGIC;
    SIGNAL crypto_done_dbg     : STD_LOGIC;
    SIGNAL rx_byte_counter_dbg : STD_LOGIC_VECTOR(7 DOWNTO 0);

    ----------------------------------
    -- SIGNALS FOR CDC
    ----------------------------------
    SIGNAL clk_uart : STD_LOGIC;
    SIGNAL clk_hb2 : STD_LOGIC;
    SIGNAL clk_locked : STD_LOGIC;
    
    ------------------------------------
    -- HB2 DOMAIN SNAPSHOT REGISTERS
    ------------------------------------
    SIGNAL operation_hb2  : STD_LOGIC;
    SIGNAL verify_mac_hb2 : STD_LOGIC;
    SIGNAL integrity_hb2  : STD_LOGIC;

    SIGNAL key_hb2 : STD_LOGIC_VECTOR(127 DOWNTO 0);
    SIGNAL iv_hb2  : STD_LOGIC_VECTOR( 63 DOWNTO 0);   
    
    SIGNAL data_input_hb2 : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL received_mac_hb2 : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL text_len_hb2     : INTEGER RANGE 1 TO 128;

    -----------------------------------
    -- UART DOMAIN SNAPSHOT REGISTERS
    -----------------------------------
    SIGNAL data_output_uart : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL mac_tag_uart : STD_LOGIC_VECTOR(127 DOWNTO 0);

    SIGNAL latency_cycles_uart : STD_LOGIC_VECTOR(15 DOWNTO 0);

    SIGNAL mac_valid_uart : STD_LOGIC;

    SIGNAL done_uart : STD_LOGIC;
    


    ----------------------------------------------
    -- CDC HANDSHAKE - REQUEST PATH UART -> HB2
    ----------------------------------------------
    SIGNAL start_req_uart : STD_LOGIC := '0';

    SIGNAL req_sync1      : STD_LOGIC := '0';
    SIGNAL req_sync2      : STD_LOGIC := '0';

    SIGNAL req_prev       : STD_LOGIC := '0';

    SIGNAL req_pulse_hb2  : STD_LOGIC := '0';

    ----------------------------------------------
    -- CDC HANDSHAKE - ACK PATH HB2 -> UART
    ----------------------------------------------
    SIGNAL ack_hb2        : STD_LOGIC := '0';

    SIGNAL ack_sync1      : STD_LOGIC := '0';
    SIGNAL ack_sync2      : STD_LOGIC := '0'; 

    -----------------------------------------------------
    -- CDC RESULT HANDSHAKE - REQUEST PATH HB2 -> UART
    -----------------------------------------------------
    SIGNAL result_req_hb2     : STD_LOGIC := '0';

    SIGNAL result_req_sync1   : STD_LOGIC := '0';
    SIGNAL result_req_sync2   : STD_LOGIC := '0';

    SIGNAL result_req_prev    : STD_LOGIC := '0';

    SIGNAL result_req_pulse_uart  : STD_LOGIC := '0';

    -----------------------------------------------------
    -- CDC RESULT HANDSHAKE - ACK PATH UART -> HB2
    -----------------------------------------------------
    SIGNAL result_ack_uart : STD_LOGIC := '0';
    
    SIGNAL result_ack_sync1 : STD_LOGIC := '0';
    SIGNAL result_ack_sync2 : STD_LOGIC := '0';

    SIGNAL latency_cycles_sig : STD_LOGIC_VECTOR(15 DOWNTO 0);


BEGIN

    uart_rx_inst :ENTITY work.UART_RX
    PORT MAP(

        clk => clk_uart,
        rst => rst,

        rx => uart_rx_pin,

        rx_data  => rx_data,
        rx_valid => rx_valid
    );

    uart_tx_inst :ENTITY work.UART_TX
    PORT MAP(

        clk => clk_uart,
        rst => rst,

        tx_start => tx_start,
        tx_data  => tx_data,

        tx => uart_tx_pin,

        tx_busy => tx_busy
    );

    controller_inst : ENTITY work.UART_PACKET_CONTROLLER
    PORT MAP(
        clk => clk_uart,
        rst => rst,

        --------------------------------
        -- UART RX
        --------------------------------
        rx_data  => rx_data,
        rx_valid => rx_valid,

        -------------------------------
        -- UART TX
        -------------------------------
        tx_busy  => tx_busy,
        tx_data  => tx_data,
        tx_start => tx_start,

        -------------------------------
        -- TO WRAPPER
        -------------------------------
        operation_out  => operation_sig,
        verify_mac_out => verify_mac_sig,
        integrity_out  => integrity_sig,

        text_len_out   => text_len_sig,

        key_out => key_sig,
        iv_out  => iv_sig,

        data_input_out => data_input_sig,

        received_mac_out => received_mac_sig,

        start_crypto => start_crypto_sig,

        --------------------------------
        -- FROM WRAPPER
        --------------------------------
        data_output_in => data_output_uart,

        mac_tag_in     => mac_tag_uart,

        latency_cycles_in => latency_cycles_uart,

        mac_valid_in   => mac_valid_uart,

        done_crypto    => done_uart,

        ------------------------------
        -- DEBUG LED SIGNALS
        ------------------------------
        packet_received_out => packet_received_dbg,
        crypto_done_out     => crypto_done_dbg
      --  rx_byte_counter_dbg => rx_byte_counter_dbg
    );

    ----------------------------------------
    -- REQUEST GENERATION UART
    ----------------------------------------
    PROCESS(clk_uart)
    BEGIN
        IF RISING_EDGE(clk_uart) THEN
            IF rst = '1' THEN
                start_req_uart <= '0';
            
            ELSIF start_crypto_sig = '1' THEN
                start_req_uart <= '1';

            ELSIF ack_sync2 = '1' THEN
                start_req_uart <= '0';

            END IF;
        END IF;
    END PROCESS;

    ----------------------------------------
    -- REQUEST GENERATION HB2
    ----------------------------------------
    PROCESS(clk_hb2)
    BEGIN
        IF RISING_EDGE(clk_hb2) THEN
            IF rst = '1' THEN
                result_req_hb2 <= '0';
            
            ELSIF done_sig = '1' THEN
                result_req_hb2 <= '1';

            ELSIF result_ack_sync2 = '1' THEN
                result_req_hb2 <= '0';

            END IF;
        END IF;
    END PROCESS;

    -------------------------------------------
    -- PROCESS for REQUEST Sychronizers(2-ff)
    -------------------------------------------
    PROCESS(clk_hb2)
    BEGIN
        IF RISING_EDGE(clk_hb2) THEN

            IF rst = '1' THEN
                req_sync1 <= '0';
                req_sync2 <= '0';
                req_prev  <= '0';

            ELSE
                req_sync1 <= start_req_uart;
                req_sync2 <= req_sync1;

                req_prev <= req_sync2;

            END IF;
        END IF;
    END PROCESS;

    PROCESS(clk_uart)
    BEGIN
        IF RISING_EDGE(clk_uart) THEN

            IF rst = '1' THEN
                result_req_sync1 <= '0';
                result_req_sync2 <= '0';
                result_req_prev  <= '0';

            ELSE
                result_req_sync1 <= result_req_hb2;
                result_req_sync2 <= result_req_sync1;

                result_req_prev <= result_req_sync2;

            END IF;
        END IF;
    END PROCESS;

    result_req_pulse_uart <= result_req_sync2 AND (NOT result_req_prev);
    
    req_pulse_hb2 <= req_sync2 AND (NOT req_prev);

    ------------------------------------
    -- ACK SYNCHRONIZER
    ------------------------------------
    PROCESS(clk_uart)
    BEGIN
        IF RISING_EDGE(clk_uart) THEN

            IF rst = '1' THEN
                ack_sync1 <= '0';
                ack_sync2 <= '0';

            ELSE
                ack_sync1 <= ack_hb2;
                ack_sync2 <= ack_sync1;

            END IF;
        END IF;
    END PROCESS;

    PROCESS(clk_hb2)
    BEGIN
        IF RISING_EDGE(clk_hb2) THEN
            IF rst = '1' THEN
                result_ack_sync1 <= '0';
                result_ack_sync2 <= '0';

            ELSE
                result_ack_sync1 <= result_ack_uart;
                result_ack_sync2 <= result_ack_sync1;
            
            END IF;
        END IF;
    END PROCESS;

    ----------------------------------
    -- SNAPSHOT INTO HB2 DOMAIN
    ----------------------------------
    PROCESS(clk_hb2)
    BEGIN
        IF RISING_EDGE(clk_hb2) THEN

            IF rst = '1' THEN
                ack_hb2 <= '0';

            

            ELSIF req_pulse_hb2 = '1' THEN
                operation_hb2  <= operation_sig;
                verify_mac_hb2 <= verify_mac_sig;
                integrity_hb2  <= integrity_sig;

                key_hb2 <= key_sig;
                iv_hb2  <= iv_sig;
                
                data_input_hb2 <= data_input_sig;

                received_mac_hb2 <= received_mac_sig;

                text_len_hb2 <= text_len_sig;

                ack_hb2 <= '1';

            ELSIF done_sig = '1' THEN
                ack_hb2 <= '0';

            END IF;
        END IF;
    END PROCESS;

    ----------------------------------
    -- SNAPSHOT INTO UART DOMAIN
    ----------------------------------
    PROCESS(clk_uart)
    BEGIN
        IF RISING_EDGE(clk_uart) THEN

            IF rst = '1' THEN
                done_uart <= '0';
                result_ack_uart <= '0';

            ELSIF result_req_pulse_uart = '1' THEN        
                data_output_uart <= data_output_sig;

                mac_tag_uart <= mac_tag_sig;

                mac_valid_uart <= mac_valid_sig;

                latency_cycles_uart <= latency_cycles_sig;

                done_uart <= '1';

                result_ack_uart <= '1';

            ELSE
                done_uart <= '0';
                result_ack_uart <= '0';

            END IF;
        END IF;
    END PROCESS;

    HB2_wrapper_inst : ENTITY work.Top_Wrapper
    PORT MAP(
        clk => clk_hb2,
        rst => rst,

        start => req_pulse_hb2,

        operation  => operation_hb2,
        verify_mac => verify_mac_hb2,
        integrity  => integrity_hb2,

        data_input => data_input_hb2,

        received_mac => received_mac_hb2,

        text_len   => text_len_hb2,

        key => key_hb2,
        iv  => iv_hb2,

        data_output => data_output_sig,

        latency_cycles => latency_cycles_sig,

        mac_tag     => mac_tag_sig,

        mac_valid   => mac_valid_sig,

        done    => done_sig,
        busy    => busy_sig
    );

    -----------------------------
    -- CLK_WIZ INSTANCE (CDC)
    -----------------------------
    clkgen_inst : ENTITY work.clk_wiz_0
        PORT MAP(
            clk_in1 => clk,
            reset   => rst,

            clk_uart => clk_uart,
            clk_hb2  => clk_hb2,

            locked => clk_locked
        );

    led(0)           <= packet_received_dbg;
    led(1)           <= busy_sig;
    led(2)           <= crypto_done_dbg;
    led(3)           <= mac_valid_sig;
    led(4)           <= operation_sig;
    led(5)           <= done_sig;
    led(6)           <= verify_mac_sig;
    led(7)           <= start_crypto_sig;
    -- DEBUG COUNTER
    -- led(15 DOWNTO 8) <= rx_byte_counter_dbg;
    led(15 DOWNTO 8) <= (OTHERS => '0');

END ARCHITECTURE;