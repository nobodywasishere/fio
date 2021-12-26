--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  cpucontrol.vhd
--  Charles DePalma | Michael Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CPUControl is
-- Functionality should match the truth table shown in Figure 4.22 of the textbook, inlcuding the
--    output 'X' values.
-- The truth table in Figure 4.22 omits the unconditional branch instruction:
--    UBranch = '1'
--    MemWrite = RegWrite = '0'
--    all other outputs = 'X'
port(Opcode   : in  STD_LOGIC_VECTOR(10 downto 0);
     Stall    : in  STD_LOGIC;
     RegDst   : out STD_LOGIC;
     CBranch  : out STD_LOGIC;  --conditional
     MemRead  : out STD_LOGIC;
     MemtoReg : out STD_LOGIC;
     MultoReg : out STD_LOGIC;
     MemWrite : out STD_LOGIC;
     ALUSrc   : out STD_LOGIC;
     RegWrite : out STD_LOGIC;
     UBranch  : out STD_LOGIC; -- This is unconditional
     ALUOp    : out STD_LOGIC_VECTOR(1 downto 0);
     Shift    : out STD_LOGIC;
     MEMOp    : out STD_LOGIC;
     MEMExt   : out STD_LOGIC
);
end CPUControl;

architecture dataflow of CPUControl is

type INSTTYPE is (RF, LD, ST, CB, UB, SH, IT, NONE);
signal op    : INSTTYPE;
signal load  : boolean;
signal arith : boolean;

begin
    op <= NONE when stall = '1' else
          CB   when Opcode(10 downto 4) = "1011010" else
          UB   when Opcode(10 downto 5) = "000101" else
          DT   when (Opcode and "00111111001") = "11111000000" else
          RF   when (Opcode and "10011110111") = "10001010000" else
          IT   when (Opcode and "10011100110") = "10010000000" else
          SH   when (Opcode and "11111111110") = "11010011010" else
	      NONE;

    -- Special case assignments
    load     <= op = DT and (Opcode(2) or Opcode(1) = '1');
    arith    <= op = RF and ((Opcode and "11111110000") = "10011010000")  ;
    RegDst   <= '0' when op = RF else '1';
    ALUSrc   <= '0' when op = RF or op = CB or op = NONE else '1';
    MemtoReg <= '0' when op = RF or op = SH or op = IT or op = NONE else '1';
    MultoReg <= '1' when arith else '0';
    RegWrite <= '1' when op = RF or load or op = SH 
                or op = IT else '0';
    MemRead  <= '1' when op = DT and load = '1' else '0';
    MemWrite <= '1' when op = DT and load = '0' else '0';
    CBranch  <= '1' when op = CB else '0';
    UBranch  <= '1' when op = UB else '0';
    Shift    <= '1' when op = SH or op = RF else '0';
    ALUOp    <= "10" when op = RF or op = IT else 
                "11" when op = SH else
                "01" when op = CB else 
                "00";
    MEMOp    <= Opcode(10 downto 9); --00 byte, 01 hw, 10 w, 11 64b
    MEMExt   <= Opcode(2);
end;
