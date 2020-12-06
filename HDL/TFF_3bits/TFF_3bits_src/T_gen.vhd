library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity T_gen is port (
    inTg : in std_logic;
    reset : in std_logic;
    clk : in std_logic;
    outTg : out std_logic);
end T_gen;

architecture Mixed of T_gen is
    component D_FF is port (
        D, reset, clk : in std_logic;
        Q : out std_logic);
    end component;
    signal inC, inD : std_logic;
begin
    outTg <= inC and (not inD);
    
    DFF1: D_FF port map ( -- called => caller
        D => inTg, Q => inC,
        reset => reset, clk => clk
    );
    
    DFF2: D_FF port map (
        D => inC, Q => inD,
        reset => reset, clk => clk
    );
end Mixed;
