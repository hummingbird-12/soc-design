library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.all;

entity TFF_3bits_fileIO_tb is
end TFF_3bits_fileIO_tb;

architecture Behavioral of TFF_3bits_fileIO_tb is
    component TFF_3bits port (
        sysclk : in std_logic;
        btn : in std_logic_vector (3 downto 0);
        led : out std_logic_vector (3 downto 0));
    end component;
    signal clk : std_logic := '1';
    signal s161577fr_en, eof_flag : std_logic := '0';
    signal s161577eof : integer := 0;
    signal fwrite_en, fwrite_en_d : std_logic := '0';
    signal btn : std_logic_vector(3 downto 0) := "0000";
    signal led : std_logic_vector(3 downto 0);
begin
    -- module instantiation (can be .vhd or .v)
    UUT : TFF_3bits port map (
        sysclk => clk, btn => btn, led => led
    );
    
    clk_gen : process begin
        wait for 10 ns; -- 50MHz clock
        clk <= not clk;
    end process;
    
    s161577fr_en <= '1' after 30ns; -- Start sim
    
    fwrite_en_Gen : process (clk) begin
        if clk = '1' and clk'event then
            fwrite_en <= s161577fr_en; -- 1 clk delay
            fwrite_en_d <= fwrite_en; -- 2 clk delay
        end if;
    end process;
    
    eof_flag_Gen : process (clk) begin
        if clk = '1' and clk'event then
            if s161577eof = 1 and fwrite_en = '1' then
                eof_flag <= '1'; -- Will stop simulation
            end if;
        end if;
    end process;

    READ_FILE : process (clk)
        variable a_line : line;
        variable indata : std_logic_vector(3 downto 0);
        FILE fp_in : TEXT OPEN READ_MODE IS -- File open for read in
            "C:\SoC\TFF_3bits_in.txt";  -- VHDL'93 style
    begin
        if clk = '1' and clk'event and s161577fr_en = '1' then -- Start read when s161577fr_en
            if ENDFILE(fp_in) then -- If nothing to read
                s161577eof <= 1;
            else
                READLINE(fp_in, a_line); -- Read a line from the file
                READ(a_line, indata);    -- Get the first data(btn) from the line
                btn <= indata;           -- Note: the 2nd data can be ignored (0011 3)
            end if;
        end if;
    end process;
    
    WRITE_FILE : process (clk)
        variable a_line : line; -- line is like a string buffer (variable size)
        FILE fp_out : TEXT OPEN WRITE_MODE IS -- File open in
            "C:\SoC\TFF_3bits_oH.txt";  -- VHDL'93 style
    begin
        if clk = '1' and clk'event then
            if fwrite_en_d = '1' or eof_flag = '1' then -- Condition for write a line
                WRITE(a_line, led); -- Insert led[3:0] values to a_line
                WRITE(a_line, ' '); -- Insert blank char to a_line
                if IS_X(led) then  -- Check if led[3:0] have any invalid value
                    WRITE(a_line, string'("X")); -- Have one or more invalid values(add 'X')
                else
                    WRITE(a_line, conv_integer(led)); -- led values are all '0' or '1'
                end if;
                WRITELINE(fp_out, a_line); -- Write a line to file
                if eof_flag = '1' then
                    FILE_CLOSE(fp_out); -- If eof_flag='1', last line to write->close file
                    assert false
                        report "End of Simulation"
                        severity FAILURE; -- Stop simulation
                end if;
            end if;
        end if;
    end process;
end Behavioral;
