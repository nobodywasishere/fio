--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___
--  ______________     __________     ______________
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
--
--  singlecyclecpu.vhd
--  Charles DePalma | Margret Riegert | Zev Pogrebin

-- DEPRECIATED FILE

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SingleCycleCPU is
port(clk :in STD_LOGIC;
     rst :in STD_LOGIC;
     --Probe ports used for testing
     --The current address (AddressOut from the PC)
     DEBUG_PC : out STD_LOGIC_VECTOR(63 downto 0);
     --The current instruction (Instruction output of IMEM)
     DEBUG_INSTRUCTION : out STD_LOGIC_VECTOR(31 downto 0);
     --DEBUG ports from other components
     DEBUG_TMP_REGS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0);
     DEBUG_SAVED_REGS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0);
     DEBUG_MEM_CONTENTS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0)
);
end SingleCycleCPU;

architecture structural of SingleCycleCPU is
----Initialize Signals----
signal I_DEBUG_TMP_REGS   : std_logic_vector(64*4-1 downto 0);
signal I_DEBUG_SAVED_REGS : std_logic_vector(64*4-1 downto 0);

--Data Lines
signal instruction      : std_logic_vector(31 downto 0) := (others => '0');
signal reg2_in          : std_logic_vector( 4 downto 0) := (others => '0');
signal reg_data_1       : std_logic_vector(63 downto 0) := (others => '0');
signal reg_data_2       : std_logic_vector(63 downto 0) := (others => '0');
signal reg_wr_data      : std_logic_vector(63 downto 0) := (others => '0');
signal ALU_B            : std_logic_vector(63 downto 0) := (others => '0');
signal ALU_result       : std_logic_vector(63 downto 0) := (others => '0');
signal ALU_zero         : std_logic := '0';
signal ALU_overflow     : std_logic := '0';
signal dmem_read_data   : std_logic_vector(63 downto 0) := (others => '0');
signal immediate        : std_logic_vector(63 downto 0) := (others => '0');

--Control Lines
signal regdst   : std_logic := '0';
signal ubranch  : std_logic := '0';
signal cbranch  : std_logic := '0';
signal memread  : std_logic := '0';
signal memwrite : std_logic := '0';
signal memtoreg : std_logic := '0';
signal ALUsrc   : std_logic := '0';
signal regwrite : std_logic := '0';
signal branch   : std_logic := '0';
signal opcode   : std_logic_vector(10 downto 0);

signal ALUOpShort : std_logic_vector(1 downto 0);
signal ALUOpLong  : std_logic_vector(3 downto 0);

----Temporary Signals----
signal DEBUG_X09 : std_logic_vector(63 downto 0);
signal DEBUG_X10 : std_logic_vector(63 downto 0);
signal DEBUG_X11 : std_logic_vector(63 downto 0);
signal DEBUG_X12 : std_logic_vector(63 downto 0);

signal DEBUG_X19 : std_logic_vector(63 downto 0);
signal DEBUG_X20 : std_logic_vector(63 downto 0);
signal DEBUG_X21 : std_logic_vector(63 downto 0);
signal DEBUG_X22 : std_logic_vector(63 downto 0);

--Branch Control
signal pc_in : std_logic_vector(63 downto 0) := (others => '0');
signal pc_address : std_logic_vector(63 downto 0) := (others => '0');

----Initialize Components----
--Initialize Memory
component IMEM is
    port(
         address  : in  std_logic_vector(63 downto 0); -- address to read from
         readdata : out std_logic_vector(31 downto 0)
    );
end component;

component DMEM is
    port(
         WriteData          : in  STD_LOGIC_VECTOR(63 downto 0); -- Input data
         Address            : in  STD_LOGIC_VECTOR(63 downto 0); -- Read/Write addr
         MemRead            : in  STD_LOGIC; -- Indicates a read operation
         MemWrite           : in  STD_LOGIC; -- Indicates a write operation
         Clock              : in  STD_LOGIC; -- Writes are triggered by a rising edge
         ReadData           : out STD_LOGIC_VECTOR(63 downto 0); -- Output data
         DEBUG_MEM_CONTENTS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0)
    );
end component;

--Initialize Control Stages
component CPUControl is
    port(Opcode   : in  STD_LOGIC_VECTOR(10 downto 0);
         RegDst   : out STD_LOGIC;
         CBranch  : out STD_LOGIC;  --conditional
         MemRead  : out STD_LOGIC;
         MemtoReg : out STD_LOGIC;
         MemWrite : out STD_LOGIC;
         ALUSrc   : out STD_LOGIC;
         RegWrite : out STD_LOGIC;
         UBranch  : out STD_LOGIC; -- This is unconditional
         ALUOp    : out STD_LOGIC_VECTOR(1 downto 0)
    );
end component;

component ALUControl is
    port(
         ALUOp     : in  STD_LOGIC_VECTOR(1 downto 0);
         Opcode    : in  STD_LOGIC_VECTOR(10 downto 0);
         Operation : out STD_LOGIC_VECTOR(3 downto 0)
    );
end component;

--Initialize Other Components
component PC is
    port(
         clk          : in  STD_LOGIC;
         write_enable : in  STD_LOGIC;
         rst          : in  STD_LOGIC;
         AddressIn    : in  STD_LOGIC_VECTOR(63 downto 0); -- Next PC address
         AddressOut   : out STD_LOGIC_VECTOR(63 downto 0) -- Current PC address
    );
end component;

component registers is
    port(RR1      : in  STD_LOGIC_VECTOR (4 downto 0);
         RR2      : in  STD_LOGIC_VECTOR (4 downto 0);
         WR       : in  STD_LOGIC_VECTOR (4 downto 0);
         WD       : in  STD_LOGIC_VECTOR (63 downto 0);
         RegWrite : in  STD_LOGIC;
         Clock    : in  STD_LOGIC;
         RD1      : out STD_LOGIC_VECTOR (63 downto 0);
         RD2      : out STD_LOGIC_VECTOR (63 downto 0);
         DEBUG_TMP_REGS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0);
         DEBUG_SAVED_REGS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0)
    );
end component;

component ALU is
    port(
         in0       : in     STD_LOGIC_VECTOR(63 downto 0);
         in1       : in     STD_LOGIC_VECTOR(63 downto 0);
         operation : in     STD_LOGIC_VECTOR(3 downto 0);
         result    : buffer STD_LOGIC_VECTOR(63 downto 0);
         zero      : buffer STD_LOGIC;
         overflow  : buffer STD_LOGIC
    );
end component;

begin
----Memory Compoonents----
    IMEM_0 : IMEM port map(
        address         => pc_address,
        readdata        => instruction
    );

    DMEM_0 : DMEM port map(
        WriteData       => reg_data_2,
        Address         => ALU_result,
        MemRead         => memread,
        MemWrite        => memwrite,
        Clock           => clk,
        ReadData        => dmem_read_data,
        DEBUG_MEM_CONTENTS => DEBUG_MEM_CONTENTS
    );

----Map All Components----
    PC_0 : PC port map(
        clk             => clk,
        write_enable    => '1',
        rst             => rst,
        addressIn       => pc_in,
        addressOut      => pc_address
    );

    registers_0 : registers port map(
        RR1             => instruction(9 downto 5),
        RR2             => reg2_in,
        WR              => instruction(4 downto 0),
        WD              => reg_wr_data,
        RegWrite        => regwrite,
        Clock           => clk,
        RD1             => reg_data_1,
        RD2             => reg_data_2,
        DEBUG_TMP_REGS  => I_DEBUG_TMP_REGS,
        DEBUG_SAVED_REGS=> I_DEBUG_SAVED_REGS
    );

    CPUControl_0 : CPUControl port map(
        Opcode          => opcode,
        RegDst          => RegDst,
        CBranch         => cbranch,
        MemRead         => memread,
        MemtoReg        => memtoreg,
        MemWrite        => memwrite,
        ALUSrc          => ALUsrc,
        RegWrite        => regwrite,
        ALUOp           => ALUOpShort,
        Ubranch         => ubranch
    );

    ALU_0 : ALU port map(
        in0             => reg_data_1,
        in1             => ALU_B,
        operation       => ALUOpLong,
        result          => ALU_result,
        zero            => ALU_zero,
        overflow        => ALU_overflow
    );

    ALUControl_0 : ALUControl port map(
        ALUOp           => ALUOpShort,
        Opcode          => opcode,
        Operation       => ALUOpLong
    );

----Setup Multiplexers----
    reg2_in <= instruction(20 downto 16) when RegDst = '0' else
               instruction(4  downto  0);

    ALU_B <= reg_data_2 when ALUSrc = '0' else
             immediate;

    reg_wr_data <= ALU_result when MemtoReg = '0' else
                   dmem_read_data;

    branch <= (ALU_zero and cbranch) or ubranch;

    pc_in <= std_logic_vector(unsigned(pc_address) + to_unsigned(4, 64)) when branch = '0' else
             std_logic_vector(unsigned(pc_address) + shift_left(unsigned(immediate), 2));

    immediate <= std_logic_vector(resize(signed(instruction(25 downto 0)), 64))
                    when (ubranch and not cbranch) = '1' else
                 std_logic_vector(resize(signed(instruction(23 downto 5)), 64))
                    when (cbranch and not ubranch) = '1' else
                 std_logic_vector(resize(unsigned(instruction(21 downto 10)), 64));

----Assignment----
    DEBUG_PC <= pc_address;
    DEBUG_INSTRUCTION <= instruction;
    opcode <= instruction(31 downto 21);

----Internal Debug Signals----
    DEBUG_X12 <= I_DEBUG_TMP_REGS(63  downto 0  );
    DEBUG_X11 <= I_DEBUG_TMP_REGS(127 downto 64 );
    DEBUG_X10 <= I_DEBUG_TMP_REGS(191 downto 128);
    DEBUG_X09 <= I_DEBUG_TMP_REGS(255 downto 192);

    DEBUG_X22 <= I_DEBUG_SAVED_REGS(63  downto 0  );
    DEBUG_X21 <= I_DEBUG_SAVED_REGS(127 downto 64 );
    DEBUG_X20 <= I_DEBUG_SAVED_REGS(191 downto 128);
    DEBUG_X19 <= I_DEBUG_SAVED_REGS(255 downto 192);

    DEBUG_TMP_REGS <= I_DEBUG_TMP_REGS;
    DEBUG_SAVED_REGS <= I_DEBUG_SAVED_REGS;
end;
