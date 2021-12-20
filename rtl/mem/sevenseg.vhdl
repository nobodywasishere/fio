library IEEE;
use IEEE.std_logic_1164.all;

entity sevensegdigit is
    port (
        I : in std_logic_vector(3 downto 0);
        D : out std_logic_vector(7 downto 0)
    );
end sevensegdigit;

architecture rtl of sevensegdigit is
begin
	with I select D <=
		not "11111100" when "0000", -- 0
		not "01100000" when "0001", -- 1
		not "11011010" when "0010", -- 2
		not "11110010" when "0011", -- 3
		not "01100110" when "0100", -- 4
		not "10110110" when "0101", -- 5
		not "10111110" when "0110", -- 6
		not "11100000" when "0111", -- 7
		not "11111110" when "1000", -- 8
		not "11110110" when "1001", -- 9
		not "11101110" when "1010", -- A
		not "00111110" when "1011", -- b
		not "10011100" when "1100", -- C
		not "01111010" when "1101", -- d
		not "10011110" when "1110", -- E
		not "10001110" when "1111", -- F
		not "00000010" when others;
end;
