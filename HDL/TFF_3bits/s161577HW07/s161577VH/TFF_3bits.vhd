library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TFF_3bits is port (
    btn : in std_logic_vector (3 downto 0);
    led : out std_logic_vector (3 downto 0);
    sysclk : in std_logic);
end TFF_3bits;

architecture Structural of TFF_3bits is
    component D_FF is port (
        D, reset, clk : in std_logic;
        Q : out std_logic);
    end component;
    component T_FF is port (
        T, reset, clk : in std_logic;
        Q : out std_logic);
    end component;
    component T_gen is port (
        inTg, reset, clk : in std_logic;
        outTg : out std_logic);
    end component;
    signal T : std_logic_vector(2 downto 0);
begin
    TIN2: T_gen port map (inTg => btn(2), outTg => T(2), clk => sysclk, reset => btn(3));
    TIN1: T_gen port map (inTg => btn(1), outTg => T(1), clk => sysclk, reset => btn(3));
    TIN0: T_gen port map (inTg => btn(0), outTg => T(0), clk => sysclk, reset => btn(3));
    
    TFF2: T_FF port map (T => T(2), Q => led(2), clk => sysclk, reset => btn(3));
    TFF1: T_FF port map (T => T(1), Q => led(1), clk => sysclk, reset => btn(3));
    TFF0: T_FF port map (T => T(0), Q => led(0), clk => sysclk, reset => btn(3));
    
    Delay_Reset: D_FF port map ( D => btn(3), Q => led(3), clk => sysclk, reset => '0'); -- reset is not used
end Structural;
