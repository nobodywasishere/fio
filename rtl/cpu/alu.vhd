--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  alu.vhd
--  Charles DePalma | Michael Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ALU is
-- Implement: AND, OR, ADD (signed), SUBTRACT (signed)
--    as described in Section 4.4 in the textbook.
-- The functionality of each instruction can be found on the 'ARM Reference Data' sheet at the
--    front of the textbook (or the ISA pdf on Canvas).
port(
     in0       : in     STD_LOGIC_VECTOR(63 downto 0);
     in1       : in     STD_LOGIC_VECTOR(63 downto 0);
     operation : in     STD_LOGIC_VECTOR(3 downto 0);
     result    : buffer STD_LOGIC_VECTOR(63 downto 0);
     zero      : buffer STD_LOGIC;
     overflow  : buffer STD_LOGIC
    );
end ALU;

architecture data of ALU is

begin
    with operation select
        result <= in0 and in1 when "0000",
                  in0 or  in1 when "0001",
                          in1 when "0111",
                  in0 nor in1 when "1100",
                          in0 when "1110",
                  in0 xor in1 when "1010",
                  std_logic_vector(unsigned(in0) + unsigned(in1)) when "0010",
                  std_logic_vector(unsigned(in0) - unsigned(in1)) when "0110",
                  X"0000_0000_0000_0000" when others;
    with operation select
        overflow <= (in0(63) and in1(63) and not result(63)) or
                    (not in0(63) and not in1(63) and result(63)) when "0010",
                    (in0(63) and not in1(63) and not result(63)) or
                    (not in0(63) and in1(63) and result(63)) when "0110",
                    '0' when others;
    zero <= '1' when result = X"0000_0000_0000_0000" else '0';
end;
