--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___
--  ______________     __________     ______________
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
--
--  IF_ID_register.vhd
--  Charles DePalma | Margret Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity IFIDRegister is
port(
    --clk/reset
    clk     : in STD_LOGIC;
    en      : in STD_LOGIC;
    rst     : in STD_LOGIC;
    flush   : in STD_LOGIC;
    --inputs
    IF_curr_PC      : in std_logic_vector(63 downto 0);
    IF_instruction  : in std_logic_vector(31 downto 0);
    --outputs
    ID_instruction  : out std_logic_vector(31 downto 0);
    ID_curr_PC      : out std_logic_vector(63 downto 0)
);
end IFIDRegister;

architecture behavioral of IFIDRegister is

signal intFlush : std_logic := '0';

begin
    -- process(clk, en, rst, flush) is
    -- begin
    --     if rst= '1' then
    --         ID_curr_PC <= (others => '0');
    --         ID_instruction <= (others => '0');
    --     elsif rising_edge(clk) and en = '1' then
    --         ID_curr_PC <= IF_curr_PC;
    --         ID_instruction <= IF_instruction;
    --         if intFlush = '1' then
    --             ID_curr_PC <= (others => '0');
    --             ID_instruction <= (others => '0');
    --             intflush <= '0';
    --         end if;
    --     elsif flush = '1' and falling_edge(clk) then intflush <= '1';
    --     end if;
    -- end process;

    process (clk, en, rst, flush)
    begin
        if rst = '1' then
            ID_curr_PC <= (others => '0');
            ID_instruction <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                if flush = '0' then
                    ID_curr_PC <= IF_curr_PC;
                    ID_instruction <= IF_instruction;
                elsif flush = '1' then
                    ID_curr_PC <= (others => '0');
                    ID_instruction <= (others => '0');
                end if;
            end if;
        end if;
    end process;
end;
