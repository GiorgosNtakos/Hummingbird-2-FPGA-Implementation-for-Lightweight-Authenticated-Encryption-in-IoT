-- This entity defines a finite state machine (FSM) controller that controls different modes of operation 
-- such as idle(000), initialization(001), encryption(010), decryption(011), MAC generation(100), and MAC check(101).

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY FSM_Controller IS

    PORT (

        clk            : IN  STD_LOGIC; -- Clock signal
        rst            : IN  STD_LOGIC; -- Reset signal (active high)
        mode           : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);   -- Mode signal indicating the operation mode
        current_state  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)   -- Output signal showing the current state of the FSM

    );

END FSM_Controller;

ARCHITECTURE Behavioral OF FSM_Controller IS

-- Define the states for the FSM
    TYPE state_type IS (Idle, Initialization, Encryption, Decryption, MAC_Generation, MAC_Check);
    SIGNAL state, next_state : state_type; -- Signals to hold the current and next state
    SIGNAL prev_state : state_type := Idle; -- Signal to hold the previous state, initialized to Idle
    SIGNAL update_prev_state : STD_LOGIC := '0'; -- Control signal for updating the previous state

    -- Pipeline register signals for state and next_state
    SIGNAL state_reg : state_type;
    SIGNAL next_state_reg : state_type;

BEGIN

    PROCESS(clk, rst)
    BEGIN

        IF rst = '1' THEN
        -- When reset is active, set the state and previous state to Idle

            state <= Idle;
            prev_state <= Idle;

        ELSIF RISING_EDGE(clk) THEN
-- On the rising edge of the clock, update the current state with the next state

            state <= next_state_reg;
            state_reg <= state;  -- Register the current state for pipelining

             -- Update the previous state when the control signal is active
            IF update_prev_state = '1' THEN

                prev_state <= state_reg;  -- Store the current state as the previous state

            END IF;

        END IF;

    END PROCESS;

    -- Combinational process to determine the next state based on the current state and mode
    PROCESS(state, mode, prev_state, next_state)
    BEGIN

    -- Default value for update_prev_state
        update_prev_state <= '0';

        -- State transition logic
        CASE state IS

            WHEN Idle =>
-- In Idle state, transition to Initialization if mode is "001"

                IF mode = "001" THEN

                    next_state <= Initialization;

                ELSE

                    next_state <= Idle;

                END IF;

            WHEN Initialization =>
-- In Initialization, move to Encryption or Decryption based on mode

                IF mode = "010" THEN

                    next_state <= Encryption;

                ELSIF mode = "011" THEN

                    next_state <= Decryption;

                ELSE

                    next_state <= Initialization;

                END IF;

            WHEN Encryption =>
-- In Encryption, move to MAC_Generation if mode is "100"

                IF mode = "100" THEN

                    next_state <= MAC_Generation;

                    update_prev_state <= '1';

                ELSE

                    next_state <= Encryption;

                END IF;

            WHEN Decryption =>
-- In Decryption, move to MAC_Generation if mode is "100"

                IF mode = "100" THEN

                    next_state <= MAC_Generation;

                    update_prev_state <= '1';

                ELSE

                    next_state <= Decryption;

                END IF;

            WHEN MAC_Generation =>
-- MAC_Generation state transitions based on previous state (Encryption or Decryption)

                IF prev_state = Encryption THEN

                    IF mode = "000" THEN

                        next_state <= Idle;

                    ELSIF mode = "001" THEN

                        next_state <= Initialization;

                    ELSE 

                        next_state <= MAC_Generation;

                    END IF;

                ELSIF prev_state = Decryption THEN

                    IF mode = "101" THEN

                        next_state <= MAC_Check;

                    ELSE

                        next_state <= MAC_Generation;

                    END IF;

                ELSE

                    next_state <= MAC_Generation;

                END IF;

            WHEN MAC_Check =>
-- MAC_Check state returns to Idle or Initialization based on mode

                IF mode = "000" THEN

                    next_state <= Idle;

                ELSIF mode = "001" THEN

                    next_state <= Initialization;

                ELSE 

                    next_state <= MAC_Check;

                END IF;

            WHEN OTHERS =>
-- Default transition to Idle state

                next_state <= Idle;

        END CASE;

        -- Register the next state for pipelining
        next_state_reg <= next_state;

    END PROCESS;

-- Process to output the current state in STD_LOGIC_VECTOR format
    PROCESS(state_reg)
    BEGIN

     -- Assign a 3-bit binary encoding to represent each state
        CASE state_reg IS

            WHEN Idle =>

                current_state <= "000";

            WHEN Initialization =>

                current_state <= "001";

            WHEN Encryption =>

                current_state <= "010";

            WHEN Decryption =>

                current_state <= "011";

            WHEN MAC_Generation =>

                current_state <= "100";

            WHEN MAC_Check =>

                current_state <= "101";

            WHEN OTHERS =>

                current_state <= "000"; -- Default to Idle for undefined states

        END CASE;

    END PROCESS;
END Behavioral;
