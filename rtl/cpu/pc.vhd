--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___
--  ______________     __________     ______________
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
--
--  pc.vhd
--  Charles DePalma | Margret Riegert | Zev Pogrebin

library ieee;
use ieee.std_logic_1164.all;

entity PC is -- 32-bit rising-edge triggered register with write-enable and synchronous reset
-- For more information on what the PC does, see page 251 in the textbook
port(
     clk          : in  STD_LOGIC; -- Propogate AddressIn to AddressOut on rising edge of clock
     write_enable : in  STD_LOGIC; -- Only write if '1'
     rst          : in  STD_LOGIC; -- Asynchronous reset! Sets AddressOut to 0x0
     AddressIn    : in  STD_LOGIC_VECTOR(63 downto 0); -- Next PC address
     AddressOut   : out STD_LOGIC_VECTOR(63 downto 0) -- Current PC address
);
end PC;


architecture behav of PC is

begin
	process(clk, rst) begin
		if rst = '1' then AddressOut <= (others => '0');
		elsif (rising_edge(clk) and write_enable = '1') then
			AddressOut <= AddressIn;
		end if;
	end process;
end;
