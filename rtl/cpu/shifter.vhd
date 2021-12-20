library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity shifter is
    port (
        shamt       : in std_logic_vector(5 downto 0);
        Rnin        : in std_logic_vector(63 downto 0);
        Rnout       : out std_logic_vector(63 downto 0);
        enable      : in std_logic;
        direction   : in std_logic
    );
end shifter ;

architecture dataflow of shifter is

signal shifterd : std_logic_vector(63 downto 0);
signal shamtint : integer;

begin

    shamtint <= to_integer(unsigned(shamt));

    with direction select shifterd <=
        std_logic_vector(shift_right(unsigned(Rnin), shamtint)) when '0',
        std_logic_vector(shift_left(unsigned(Rnin), shamtint)) when '1',
        -- (shamtint - 1 downto 0 => '0') & Rnin(63 downto shamtint) when '0',
        -- Rnin(63 - shamtint downto 0) & (shamtint - 1 downto 0 => '0') when '1',
        (others => '0') when others;
        -- Rnin when others;

    with enable select Rnout <=
        shifterd when '1',
        Rnin     when others;
        

end architecture; -- arch