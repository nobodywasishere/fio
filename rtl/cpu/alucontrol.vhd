--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  alucontrol.vhd
--  Charles DePalma | Micheal Riegart | Zev Pogrebin

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ALUControl is
-- Functionality should match truth table shown in Figure 4.13 in the textbook.
-- Check table on page2 of ISA.pdf on canvas. Pay attention to opcode of operations and type of operations.
-- If an operation doesn't use ALU, you don't need to check for its case in the ALU control implemenetation.
--  To ensure proper functionality, you must implement the "don't-care" values in the funct field,
-- for example when ALUOp = '00", Operation must be "0010" regardless of what Funct is.
port(
     ALUOp     : in  STD_LOGIC_VECTOR(1 downto 0);
     Opcode    : in  STD_LOGIC_VECTOR(10 downto 0);
     Operation : out STD_LOGIC_VECTOR(3 downto 0)
    );
end ALUControl;

architecture dataflow of ALUControl is

begin
    Operation <= "0010" when ALUOp = "00" else
                 "0111" when ALUOp = "01" else
                 "1110" when ALUOp = "11" else
                 --R-type cases
                 "0010" when ALUOp(1) = '1' and Opcode = "10001011000" else
                 "0110" when ALUOp(1) = '1' and Opcode = "11001011000" else
                 "0000" when ALUOp(1) = '1' and Opcode = "10001010000" else
                 "0001" when ALUOp(1) = '1' and Opcode = "10101010000" else
                 "1010" when ALUOp(1) = '1' and Opcode = "11001010000" else
                 --I-type cases
                 "0010" when ALUOp(1) = '1' and (Opcode and "11111111110") = "10010001000" else -- ADDI
                 "0110" when ALUOp(1) = '1' and (Opcode and "11111111110") = "11010001000" else -- SUBI
                 "0000" when ALUOp(1) = '1' and (Opcode and "11111111110") = "10010010000" else -- ANDI
                 "0001" when ALUOp(1) = '1' and (Opcode and "11111111110") = "10110010000" else
                    -- ORRI
                 "1010" when ALUOp(1) = '1' and (Opcode and "11111111110") = "11010010000" else
                    -- EORI
                 "UUUU";
end;
