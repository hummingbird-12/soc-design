library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity T_FF is port (
    T : in std_logic;
    reset : in std_logic;
    clk : in std_logic;
    Q : out std_logic);
end T_FF;

architecture Mixed of T_FF is
    component D_FF is port (
        D, reset, clk : in std_logic;
        Q : out std_logic);
    end component;
    signal D_in, QI: std_logic;
begin
    Q <= QI; -- Output cannot be used internally
    D_in <= QI xor T;
    DFFforT: D_FF port map ( -- called => caller
        D => D_in, Q => QI, reset => reset, clk => clk
    );
end Mixed;
