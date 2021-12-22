--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  forwardunit.vhd
--  Charles DePalma | Michael Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity forwardUnit is
port(
    MM_WR       : in std_logic_vector(4  downto 0);
    WB_WR       : in std_logic_vector(4  downto 0);
    MM_regwrite : in std_logic;
    WB_regwrite : in std_logic;
    EX_RR1      : in std_logic_vector(4  downto 0);
    EX_RR2      : in std_logic_vector(4  downto 0);
    forwardA    : out std_logic_vector(1 downto 0);
    forwardB    : out std_logic_vector(1 downto 0)
);
end forwardUnit;

-- Forward coding
-- forward 0 if no forward
-- forward 2 if forward from MEM
-- forward 1 if forward from WB

architecture dataflow of forwardUnit is

signal MM_fw : boolean;
signal WB_fw : boolean;

begin

    WB_fw <= WB_regwrite = '1' and not (WB_WR = "11111");
    MM_fw <= MM_regwrite = '1' and not (MM_WR = "11111");

    forwardA <= "10" when EX_RR1 = MM_WR and MM_fw else
                "01" when EX_RR1 = WB_WR and WB_fw else
                "00";

    forwardB <= "10" when EX_RR2 = MM_WR and MM_fw else --forward from MM
                "01" when EX_RR2 = WB_WR and WB_fw else --forward from WB
                "00";

end;
