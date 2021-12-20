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
     MemWrite : out STD_LOGIC;
     ALUSrc   : out STD_LOGIC;
     RegWrite : out STD_LOGIC;
     UBranch  : out STD_LOGIC; -- This is unconditional
     ALUOp    : out STD_LOGIC_VECTOR(1 downto 0);
     Shift    : out STD_LOGIC
);
end CPUControl;

architecture dataflow of CPUControl is

type INSTTYPE is (RF, LD, ST, CB, UB, SH, IT, NONE);
signal op : INSTTYPE;

begin
    op <= NONE when stall = '1' else
          CB   when Opcode(10 downto 4) = "1011010" else
          UB   when Opcode(10 downto 5) = "000101" else
          LD   when Opcode = "11111000010" else
          ST   when Opcode = "11111000000" else
          RF   when (Opcode and "10011110111") = "10001010000" else
          IT   when (Opcode and "10011100110") = "10010000000" else
          SH   when (Opcode and "11111111110") = "11010011010" else
	     NONE;

    RegDst   <= '0' when op = RF else '1';
    ALUSrc   <= '0' when op = RF or op = CB or op = NONE else '1';
    MemtoReg <= '0' when op = RF or op = SH or op = IT or op = NONE else '1';
    RegWrite <= '1' when op = RF or op = LD or op = SH or op = IT else '0';
    MemRead  <= '1' when op = LD else '0';
    MemWrite <= '1' when op = ST else '0';
    CBranch  <= '1' when op = CB else '0';
    UBranch  <= '1' when op = UB else '0';
    Shift    <= '1' when op = SH or op = RF else '0';
    ALUOp    <= "10" when op = RF or op = IT else 
                "11" when op = SH else
                "01" when op = CB else 
                "00";
end;
