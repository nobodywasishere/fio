--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___
--  ______________     __________     ______________
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
--
--  mux64.vhd
--  Charles DePalma | Margret Riegert | Zev Pogrebin

library ieee;
use ieee.std_logic_1164.all;

entity MUX64 is -- Two by one mux with 32 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(63 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(63 downto 0); -- sel == 1
    sel    : in STD_LOGIC; -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(63 downto 0)
);
end MUX64;

architecture struct of MUX64 is
begin
	output <= in0 when sel = '0' else
		  in1;
end;

library ieee;
use ieee.std_logic_1164.all;

entity MUX64TESTBENCH is
end MUX64TESTBENCH;

--testbench
architecture testbench of MUX64TESTBENCH is

	component MUX64 is
		port(
			in0    : in STD_LOGIC_VECTOR(63 downto 0); -- sel == 0
			in1    : in STD_LOGIC_VECTOR(63 downto 0); -- sel == 1
			sel    : in STD_LOGIC; -- selects in0 or in1
			output : out STD_LOGIC_VECTOR(63 downto 0)
		);
	end component;
	signal a : STD_LOGIC_VECTOR(63 downto 0);
	signal b : STD_LOGIC_VECTOR(63 downto 0);
	signal s : STD_LOGIC;
	signal o : STD_LOGIC_VECTOR(63 downto 0);

begin

	DUT : MUX64 port map(a, b, s, o);
	process begin
		--We will only test a few values each for each
		--There are practically no edge cases here. We just need to
		--Ensure that the input propogates to the output properly.
		a <= (others => '0');
		b <= (others => '1');
		s <= '0';
		wait for 5 ns;
		assert o = X"0000_0000_0000_0000" report "FAILED" severity error;
        s <= '1';
		wait for 5 ns;
		assert o = X"FFFF_FFFF_FFFF_FFFF" report "FAILED" severity error;
		a <= (others => '1');
		b <= (others => '0');
		wait for 5 ns;
		assert o = X"0000_0000_0000_0000" report "FAILED" severity error;
		s <= '0';
		wait for 5 ns;
		assert o = X"FFFF_FFFF_FFFF_FFFF" report "FAILED" severity error;
		report "TEST COMPLTETED" severity note;
		wait;
	end process;
end;
