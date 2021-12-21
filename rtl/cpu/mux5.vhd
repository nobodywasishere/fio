--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  mux5.vhd
--  Charles DePalma | Micheal Riegart | Zev Pogrebin

library ieee;
use ieee.std_logic_1164.all;

entity MUX5 is -- Two by one mux with 5 bit inputs/outputs
port(
    in0    : in STD_LOGIC_VECTOR(4 downto 0); -- sel == 0
    in1    : in STD_LOGIC_VECTOR(4 downto 0); -- sel == 1
    sel    : in STD_LOGIC; -- selects in0 or in1
    output : out STD_LOGIC_VECTOR(4 downto 0)
);
end MUX5;

architecture struct of MUX5 is
begin
	output <= in0 when sel = '0' else
		      in1;
end;

library ieee;
use ieee.std_logic_1164.all;

entity MUX5TESTBENCH is
end;

--testbench
architecture testbench of MUX5TESTBENCH is

	component MUX5 is
		port(
			in0    : in STD_LOGIC_VECTOR(4 downto 0); -- sel == 0
			in1    : in STD_LOGIC_VECTOR(4 downto 0); -- sel == 1
			sel    : in STD_LOGIC; -- selects in0 or in1
			output : out STD_LOGIC_VECTOR(4 downto 0)
		);
	end component;
	signal a : STD_LOGIC_VECTOR(4 downto 0);
	signal b : STD_LOGIC_VECTOR(4 downto 0);
	signal s : STD_LOGIC;
	signal o : STD_LOGIC_VECTOR(4 downto 0);

begin

	DUT : MUX5 port map(a, b, s, o);
	process begin
		--We will only test a few values each for each
		--There are practically no edge cases here. We just need to
		--Ensure that the input propogates to the output properly.
		a <= (others => '0');
		b <= (others => '1');
		s <= '0';
		wait for 5 ns;
		assert o = "00000" report "FAILED" severity error;
		s <= '1';
		wait for 5 ns;
		assert o = "11111" report "FAILED" severity error;
		a <= (others => '1');
		b <= (others => '0');
		wait for 5 ns;
		assert o = "00000" report "FAILED" severity error;
		s <= '0';
		wait for 5 ns;
		assert o = "11111" report "FAILED" severity error;
		report "TEST COMPLTETED" severity note;
		wait;
	end process;
end;
