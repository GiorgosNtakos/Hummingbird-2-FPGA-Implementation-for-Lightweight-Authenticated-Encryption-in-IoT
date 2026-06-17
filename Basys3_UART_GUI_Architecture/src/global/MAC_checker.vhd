LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY MAC_checker IS
    PORT(
        generated_mac : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
        received_mac  : IN STD_LOGIC_VECTOR(127 DOWNTO 0);

        valid : OUT STD_LOGIC
    );
END ENTITY MAC_checker;

ARCHITECTURE Behavioral OF MAC_checker IS
    SIGNAL cmp0, cmp1, cmp2, cmp3 : STD_LOGIC;

BEGIN
    cmp0 <= '1' WHEN generated_mac(31 DOWNTO 0) = received_mac(31 DOWNTO 0)
       ELSE '0';

    cmp1 <= '1' WHEN generated_mac(63 DOWNTO 32) = received_mac(63 DOWNTO 32)
       ELSE '0';

    cmp2 <= '1' WHEN generated_mac(95 DOWNTO 64) = received_mac(95 DOWNTO 64)
       ELSE '0';

    cmp3 <= '1' WHEN generated_mac(127 DOWNTO 96) = received_mac(127 DOWNTO 96)
       ELSE '0';

    valid <= cmp0 AND cmp1 AND cmp2 AND cmp3;

END ARCHITECTURE Behavioral;