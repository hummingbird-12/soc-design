library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity D_FF is port(
    D : in std_logic;
    reset : in std_logic;
    clk : in std_logic;
    Q : out std_logic);
end D_FF;

architecture Behavioral of D_FF is
begin
    process (clk) begin
        if clk'event and clk = '1' then
            if reset = '1' then
                Q <= '0';
            else
                Q <= D;
            end if;
        end if;
    end process;
end Behavioral;
