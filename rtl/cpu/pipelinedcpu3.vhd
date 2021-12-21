--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  pipelinedcpu3.vhd
--  Charles DePalma | Micheal Riegart | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity PipelinedCPU3 is
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        --IMEM ports
        IMEM_ADDR       : out std_logic_vector(63 downto 0);
        IMEM_DATA       : in std_logic_vector(31 downto 0);
        --DMEM ports
        DMEM_ADDR       : out std_logic_vector(63 downto 0);
        DMEM_WRITE_DATA : out std_logic_vector(63 downto 0);
        DMEM_READ_DATA  : in std_logic_vector(63 downto 0);
        DMEM_READ       : out std_logic;
        DMEM_WRITE      : out std_logic;
        --Probe ports used for testing
        DEBUG_IF_FLUSH  : out std_logic;
        DEBUG_REG_EQUAL : out std_logic;
        -- Forwarding control signals
        DEBUG_FORWARDA  : out std_logic_vector(1 downto 0);
        DEBUG_FORWARDB  : out std_logic_vector(1 downto 0);
        --The current address (AddressOut from the PC)
        DEBUG_PC        : out std_logic_vector(63 downto 0);
        --Value of PC.write_enable
        DEBUG_PC_WRITE_ENABLE   : out STD_LOGIC;
        --The current instruction (Instruction output of IMEM)
        DEBUG_INSTRUCTION       : out std_logic_vector(31 downto 0);
        --DEBUG ports from other components
        DEBUG_TMP_REGS          : out std_logic_vector(64*4 - 1 downto 0);
        DEBUG_SAVED_REGS        : out std_logic_vector(64*4 - 1 downto 0);
        DEBUG_MEM_CONTENTS      : out std_logic_vector(64*4 - 1 downto 0)
    );
    end PipelinedCPU3;

architecture structural of PipelinedCPU3 is
----Initialize Signals----
signal I_DEBUG_TMP_REGS   : std_logic_vector(64*4-1 downto 0);
signal I_DEBUG_SAVED_REGS : std_logic_vector(64*4-1 downto 0);

----Data Lines by pipeline stage----
--IF Stage
signal IF_new_PC       : std_logic_vector(63 downto 0);
signal IF_curr_PC      : std_logic_vector(63 downto 0);
signal IF_instruction  : std_logic_vector(31 downto 0);
signal IF_flush        : std_logic;

--ID Stage
signal ID_instruction  : std_logic_vector(31 downto 0);
signal ID_immediate    : std_logic_vector(63 downto 0);
signal ID_RR2          : std_logic_vector(4  downto 0);
signal ID_RD1          : std_logic_vector(63 downto 0);
signal ID_RD2          : std_logic_vector(63 downto 0);
signal ID_WR           : std_logic_vector(4  downto 0);
signal ID_shamt        : std_logic_vector(5  downto 0) := (others => '0');

--ID Branch lines
signal ID_ubranch      : std_logic := '0';
signal ID_cbranch      : std_logic := '0';
signal ID_curr_PC      : std_logic_vector(63 downto 0);
signal ID_branch_PC    : std_logic_vector(63 downto 0);
signal ID_branch       : std_logic := '0';
signal ID_zero         : std_logic := '0';

--EX Stage
signal EX_immediate    : std_logic_vector(63 downto 0);
signal EX_RD1          : std_logic_vector(63 downto 0);
signal EX_RD2          : std_logic_vector(63 downto 0);
signal EX_RR1          : std_logic_vector(4  downto 0);
signal EX_RR2          : std_logic_vector(4  downto 0);
signal EX_FWDED_RD2    : std_logic_vector(63 downto 0);
signal EX_WR           : std_logic_vector(4  downto 0);
signal EX_ALU_A        : std_logic_vector(63 downto 0);
signal EX_ALU_A_SH     : std_logic_vector(63 downto 0);
signal EX_ALU_B        : std_logic_vector(63 downto 0);
signal EX_ALU_zero     : std_logic;
signal EX_ALU_overflow : std_logic;
signal EX_ALU_result   : std_logic_vector(63 downto 0);
signal EX_shamt        : std_logic_vector(5  downto 0);

--MEM Stage
signal MM_WR           : std_logic_vector(4  downto 0);
signal MM_RD2          : std_logic_vector(63 downto 0);
signal MM_ALU_zero     : std_logic;
signal MM_ALU_result   : std_logic_vector(63 downto 0);
signal MM_memory_data  : std_logic_vector(63 downto 0);

--WB Stage
signal WB_WR           : std_logic_vector(4  downto 0);
signal WB_WD           : std_logic_vector(63 downto 0);
signal WB_ALU_result   : std_logic_vector(63 downto 0);
signal WB_memory_data  : std_logic_vector(63 downto 0);

----Control Lines by pipeline stage----

--ID Stage
signal ID_regdst   : std_logic := '0';
signal ID_memread  : std_logic := '0';
signal ID_memwrite : std_logic := '0';
signal ID_memtoreg : std_logic := '0';
signal ID_ALUsrc   : std_logic := '0';
signal ID_regwrite : std_logic := '0';
signal ID_opcode   : std_logic_vector(10 downto 0);
signal ID_ALUOpShort : std_logic_vector(1 downto 0);
signal ID_Stall      : std_logic;
signal ID_shift      : std_logic := '0';

--EX Stage
signal EX_ubranch  : std_logic := '0';
signal EX_cbranch  : std_logic := '0';
signal EX_memread  : std_logic := '0';
signal EX_memwrite : std_logic := '0';
signal EX_memtoreg : std_logic := '0';
signal EX_ALUsrc   : std_logic := '0';
signal EX_regwrite : std_logic := '0';
signal EX_opcode   : std_logic_vector(10 downto 0);
signal EX_ALUOpShort : std_logic_vector(1 downto 0);
signal EX_ALUOpLong  : std_logic_vector(3 downto 0);
signal EX_forwardA   : std_logic_vector(1 downto 0);
signal EX_forwardB   : std_logic_vector(1 downto 0);
signal EX_shift      : std_logic := '1';

--MEM Stage
signal MM_memread  : std_logic := '0';
signal MM_memwrite : std_logic := '0';
signal MM_memtoreg : std_logic := '0';
signal MM_regwrite : std_logic := '0';

--WB Stage
signal WB_memtoreg : std_logic := '0';
signal WB_regwrite : std_logic := '0';

----Initialize Components----
--Initialize Control Stages
component CPUControl is
    port(
        Opcode   : in  STD_LOGIC_VECTOR(10 downto 0);
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
    port(
        RR1              : in  STD_LOGIC_VECTOR (4 downto 0);
        RR2              : in  STD_LOGIC_VECTOR (4 downto 0);
        WR               : in  STD_LOGIC_VECTOR (4 downto 0);
        WD               : in  STD_LOGIC_VECTOR (63 downto 0);
        RegWrite         : in  STD_LOGIC;
        Clock            : in  STD_LOGIC;
        RD1              : out STD_LOGIC_VECTOR (63 downto 0);
        RD2              : out STD_LOGIC_VECTOR (63 downto 0);
        DEBUG_TMP_REGS   : out STD_LOGIC_VECTOR(64*4 - 1 downto 0);
        DEBUG_SAVED_REGS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0)
    );
end component;

component ALU is
    port(
        in0       : in     STD_LOGIC_VECTOR(63 downto 0);
        in1       : in     STD_LOGIC_VECTOR(63 downto 0);
        operation : in     STD_LOGIC_VECTOR(3  downto 0);
        result    : buffer STD_LOGIC_VECTOR(63 downto 0);
        zero      : buffer STD_LOGIC;
        overflow  : buffer STD_LOGIC
    );
end component;

component shifter is
    port (
        shamt       : in std_logic_vector(5 downto 0);
        Rnin        : in std_logic_vector(63 downto 0);
        Rnout       : out std_logic_vector(63 downto 0);
        enable      : in std_logic;
        direction   : in std_logic
    );
end component;

component forwardUnit is
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
end component;

component hazardDetectionUnit is
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        ID_branch   : in std_logic;
        EX_MemRead  : in std_logic;
        EX_WR       : in std_logic_vector(4 downto 0);
        MM_WR       : in std_logic_vector(4 downto 0);
        ID_RR1      : in std_logic_vector(4 downto 0);
        ID_RR2      : in std_logic_vector(4 downto 0);
        EX_regwrite : in std_logic;
        ID_cbranch  : in std_logic;
        MM_memread  : in std_logic;
        --outputs
        Stall       : out std_logic;
        Flush       : out std_logic
    );
end component;

component zeroCheck is
    port (
        --input
        ID_RD2      : in std_logic_vector(63 downto 0); -- standard input
        MM_WD       : in std_logic_vector(63 downto 0);
        WB_WD       : in std_logic_vector(63 downto 0);
        ID_RR2      : in std_logic_vector(4 downto 0); -- for forwarding check
        MM_WR       : in std_logic_vector(4 downto 0);
        WB_WR       : in std_logic_vector(4 downto 0);
        MM_regwrite : in std_logic;
        WB_regwrite : in std_logic;
        --output
        ID_zero     : out std_logic
    );
end component;

--Initialize Pipeline Registers
component IFIDRegister is
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
end component;

component IDEXRegister is
    port(
        --clk/reset
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        --inputs
        ID_ubranch    : in std_logic;
        ID_cbranch    : in std_logic;
        ID_memread    : in std_logic;
        ID_memwrite   : in std_logic;
        ID_memtoreg   : in std_logic;
        ID_ALUsrc     : in std_logic;
        ID_regwrite   : in std_logic;
        ID_opcode     : in std_logic_vector(10 downto 0);
        ID_ALUOpShort : in std_logic_vector(1 downto 0);
        ID_WR         : in std_logic_vector(4 downto 0);
        ID_RR1        : in std_logic_vector(4 downto 0);
        ID_RR2        : in std_logic_vector(4 downto 0);
        ID_RD1        : in std_logic_vector(63 downto 0);
        ID_RD2        : in std_logic_vector(63 downto 0);
        ID_immediate  : in std_logic_vector(63 downto 0);
        ID_curr_PC    : in std_logic_vector(63 downto 0);
        ID_shift      : in std_logic;
        ID_shamt      : in std_logic_vector(5 downto 0) := (others => '0');
        --outputs
        EX_ubranch    : out std_logic;
        EX_cbranch    : out std_logic;
        EX_memread    : out std_logic;
        EX_memwrite   : out std_logic;
        EX_memtoreg   : out std_logic;
        EX_ALUsrc     : out std_logic;
        EX_regwrite   : out std_logic;
        EX_opcode     : out std_logic_vector(10 downto 0);
        EX_ALUOpShort : out std_logic_vector(1 downto 0);
        EX_WR         : out std_logic_vector(4 downto 0);
        EX_RR1        : out std_logic_vector(4 downto 0);
        EX_RR2        : out std_logic_vector(4 downto 0);
        EX_RD1        : out std_logic_vector(63 downto 0);
        EX_RD2        : out std_logic_vector(63 downto 0);
        EX_immediate  : out std_logic_vector(63 downto 0);
        EX_curr_PC    : out std_logic_vector(63 downto 0);
        EX_shift      : out std_logic;
        EX_shamt      : out std_logic_vector(5 downto 0)
    );
end component;

component EXMMRegister is
    port(
        --clk/reset
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        --inputs
        EX_ubranch      : in std_logic;
        EX_cbranch      : in std_logic;
        EX_memread      : in std_logic;
        EX_memwrite     : in std_logic;
        EX_memtoreg     : in std_logic;
        EX_regwrite     : in std_logic;
        EX_WR           : in std_logic_vector(4  downto 0);
        EX_RD2          : in std_logic_vector(63 downto 0);
        EX_ALU_zero     : in std_logic;
        EX_ALU_result   : in std_logic_vector(63 downto 0);
        EX_branch_PC    : in std_logic_vector(63 downto 0);
        --outputs
        MM_ubranch      : out std_logic;
        MM_cbranch      : out std_logic;
        MM_memread      : out std_logic;
        MM_memwrite     : out std_logic;
        MM_memtoreg     : out std_logic;
        MM_regwrite     : out std_logic;
        MM_WR           : out std_logic_vector(4  downto 0);
        MM_RD2          : out std_logic_vector(63 downto 0);
        MM_ALU_zero     : out std_logic;
        MM_ALU_result   : out std_logic_vector(63 downto 0);
        MM_branch_PC    : out std_logic_vector(63 downto 0)
    );
end component;

component MMWBRegister is
    port(
        --clk/reset
        clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        --inputs
        MM_memtoreg     : in std_logic;
        MM_regwrite     : in std_logic;
        MM_WR           : in std_logic_vector(4  downto 0);
        MM_ALU_result   : in std_logic_vector(63 downto 0);
        MM_memory_data  : in std_logic_vector(63 downto 0);
        --outputs
        WB_memtoreg     : out std_logic;
        WB_regwrite     : out std_logic;
        WB_WR           : out std_logic_vector(4  downto 0);
        WB_ALU_result   : out std_logic_vector(63 downto 0);
        WB_memory_data  : out std_logic_vector(63 downto 0)
    );
end component;

begin
----Memory Compoonents----
    MM_memory_data  <= DMEM_READ_DATA;
    DMEM_WRITE_DATA <= MM_RD2;
    DMEM_READ       <= MM_memread;
    DMEM_WRITE      <= MM_memwrite;
    DMEM_ADDR       <= MM_ALU_result;

    IF_instruction  <= IMEM_DATA;
    IMEM_ADDR       <= IF_curr_PC;

----Map All Components----
    PC_0 : PC port map(
        clk             => clk,
        write_enable    => "not"(ID_stall),
        rst             => rst,
        addressIn       => IF_new_PC,
        addressOut      => IF_curr_PC
    );

    registers_0 : registers port map(
        RR1             => ID_instruction(9 downto 5),
        RR2             => ID_RR2,
        WR              => WB_WR,
        WD              => WB_WD,
        RegWrite        => WB_regwrite,
        Clock           => clk,
        RD1             => ID_RD1,
        RD2             => ID_RD2,
        DEBUG_TMP_REGS  => I_DEBUG_TMP_REGS,
        DEBUG_SAVED_REGS=> I_DEBUG_SAVED_REGS
    );

    CPUControl_0 : CPUControl port map(
        Opcode          => ID_opcode,
        Stall           => ID_stall,
        RegDst          => ID_RegDst,
        CBranch         => ID_cbranch,
        MemRead         => ID_memread,
        MemtoReg        => ID_memtoreg,
        MemWrite        => ID_memwrite,
        ALUSrc          => ID_ALUsrc,
        RegWrite        => ID_regwrite,
        ALUOp           => ID_ALUOpShort,
        Ubranch         => ID_ubranch,
        Shift           => ID_shift
    );

    ALU_0 : ALU port map(
        in0             => EX_ALU_A_SH,
        in1             => EX_ALU_B,
        operation       => EX_ALUOpLong,
        result          => EX_ALU_result,
        zero            => EX_ALU_zero,
        overflow        => EX_ALU_overflow
    );

    SH_0 : shifter port map(
        shamt       => EX_shamt,
        Rnin        => EX_ALU_A,
        Rnout       => EX_ALU_A_SH,
        enable      => EX_shift,
        direction   => EX_opcode(0)
    );

    ALUControl_0 : ALUControl port map(
        ALUOp           => EX_ALUOpShort,
        Opcode          => EX_opcode,
        Operation       => EX_ALUOpLong
    );

    FWUnit_0 : forwardUnit port map(
        MM_WR           => MM_WR,
        WB_WR           => WB_WR,
        MM_regwrite     => MM_regwrite,
        WB_regwrite     => WB_regwrite,
        EX_RR1          => EX_RR1,
        EX_RR2          => EX_RR2,
        forwardA        => EX_forwardA,
        forwardB        => EX_forwardB
    );

    HDU_0 : hazardDetectionUnit port map(
        clk             => clk,
        rst             => rst,
        ID_branch       => ID_branch,
        EX_memread      => EX_memread,
        EX_WR           => EX_WR,
        MM_WR           => MM_WR,
        ID_RR1          => ID_instruction(9 downto 5),
        ID_RR2          => ID_RR2,
        EX_regwrite     => EX_regwrite,
        ID_cbranch      => ID_cbranch,
        MM_memread      => MM_memread,
        Stall           => ID_Stall,
        Flush           => IF_flush
    );

    ZC_0 : zeroCheck port map (
        ID_RD2      => ID_RD2,
        MM_WD       => MM_ALU_Result,
        WB_WD       => WB_WD,
        ID_RR2      => ID_RR2,
        MM_WR       => MM_WR,
        WB_WR       => WB_WR,
        MM_regwrite => MM_regwrite,
        WB_regwrite => WB_regwrite,
        ID_zero     => ID_zero
    );

    --Mapping pipeline registers
    IFID_0 : IFIDRegister port map(
        clk             => clk,
        en              => "not"(ID_stall),
        rst             => rst,
        flush           => IF_flush,
        IF_curr_PC      => IF_curr_PC,
        IF_instruction  => IF_instruction,
        --outputs
        ID_instruction  => ID_instruction,
        ID_curr_PC      => ID_curr_PC
    );

    IDEX_0 : IDEXRegister port map(
        clk           => clk,
        rst           => rst,
        ID_ubranch    => ID_ubranch,
        ID_cbranch    => ID_cbranch,
        ID_memread    => ID_memread,
        ID_memwrite   => ID_memwrite,
        ID_memtoreg   => ID_memtoreg,
        ID_ALUsrc     => ID_ALUsrc,
        ID_regwrite   => ID_regwrite,
        ID_opcode     => ID_opcode,
        ID_ALUOpShort => ID_ALUOpShort,
        ID_WR         => ID_WR,
        ID_RR1        => ID_instruction(9 downto 5),
        ID_RR2        => ID_RR2,
        ID_RD1        => ID_RD1,
        ID_RD2        => ID_RD2,
        ID_immediate  => ID_immediate,
        ID_curr_PC    => (others => '0'),
        ID_shift      => ID_shift,
        ID_shamt      => ID_shamt,
        EX_ubranch    => EX_ubranch,
        EX_cbranch    => EX_cbranch,
        EX_memread    => EX_memread,
        EX_memwrite   => EX_memwrite,
        EX_memtoreg   => EX_memtoreg,
        EX_ALUsrc     => EX_ALUsrc,
        EX_regwrite   => EX_regwrite,
        EX_opcode     => EX_opcode,
        EX_ALUOpShort => EX_ALUOpShort,
        EX_WR         => EX_WR,
        EX_RR1        => EX_RR1,
        EX_RR2        => EX_RR2,
        EX_RD1        => EX_RD1,
        EX_RD2        => EX_RD2,
        EX_immediate  => EX_immediate,
        EX_shift      => EX_shift,
        EX_shamt      => EX_shamt
    );

    EXMM_0 : EXMMRegister port map(
        clk             => clk,
        rst             => rst,
        EX_ubranch      => '0',
        EX_cbranch      => '0',
        EX_memread      => EX_memread,
        EX_memwrite     => EX_memwrite,
        EX_memtoreg     => EX_memtoreg,
        EX_regwrite     => EX_regwrite,
        EX_WR           => EX_WR,
        EX_RD2          => EX_FWDED_RD2,
        EX_ALU_zero     => EX_ALU_zero,
        EX_ALU_result   => EX_ALU_result,
        EX_branch_PC    => (others => '0'),
        MM_memread      => MM_memread,
        MM_memwrite     => MM_memwrite,
        MM_memtoreg     => MM_memtoreg,
        MM_regwrite     => MM_regwrite,
        MM_WR           => MM_WR,
        MM_RD2          => MM_RD2,
        MM_ALU_zero     => MM_ALU_zero,
        MM_ALU_result   => MM_ALU_result
    );

    MMWB_0 : MMWBRegister port map(
        clk             => clk,
        rst             => rst,
        MM_memtoreg     => MM_memtoreg,
        MM_regwrite     => MM_regwrite,
        MM_WR           => MM_WR,
        MM_ALU_result   => MM_ALU_result,
        MM_memory_data  => MM_memory_data,
        WB_memtoreg     => WB_memtoreg,
        WB_regwrite     => WB_regwrite,
        WB_WR           => WB_WR,
        WB_ALU_result   => WB_ALU_result,
        WB_memory_data  => WB_memory_data
    );

----Setup Combinational Programming----
    --Reg 2 selection
    ID_RR2 <= ID_instruction(20 downto 16) when ID_RegDst = '0' else
              ID_instruction(4  downto  0);

    --ALU Op B Selection
    EX_ALU_B <= EX_FWDED_RD2 when EX_ALUSrc = '0' else
                EX_immediate;

    --Register read data
    WB_WD <= WB_ALU_result when WB_memtoreg = '0' else
             WB_memory_data;

    --Branch Combinational Logic --TODO May need forwarding
    ID_branch <= ((ID_zero and ID_cbranch and (not ID_opcode(3))) or --CBZ
                ((not ID_zero) and ID_cbranch and ID_opcode(3)) or   --CBNZ
                ID_ubranch);

    --PC Calculation
    ID_branch_PC <= std_logic_vector(unsigned(ID_curr_PC)
                    + shift_left(unsigned(ID_immediate), 2));

    --PC Selection
    IF_new_PC <= std_logic_vector(unsigned(IF_curr_PC) + to_unsigned(4, 64))
                 when ID_branch = '0' else ID_branch_PC;

    --Immediate Logic
    ID_immediate <= std_logic_vector(resize(signed(ID_instruction(25 downto 0)), 64))
                    when (ID_ubranch and not ID_cbranch) = '1' else
                    std_logic_vector(resize(signed(ID_instruction(23 downto 5)), 64))
                    when (ID_cbranch and not ID_ubranch) = '1' else
                    std_logic_vector(resize(unsigned(ID_instruction(20 downto 12)), 64))
                    when (ID_memread or ID_memwrite) = '1' else
                    std_logic_vector(resize(signed(ID_instruction(21 downto 10)), 64));

    --Forwarding
    with EX_forwardA select
        EX_ALU_A <= MM_ALU_result       when "10",
                    WB_WD               when "01",
                    EX_RD1              when others;

    with EX_forwardB select
        EX_FWDED_RD2 <= MM_ALU_result   when "10",
                        WB_WD           when "01",
                        EX_RD2          when others;

    --Connect outputs


----Assignment----
    DEBUG_PC <= IF_curr_PC;
    DEBUG_INSTRUCTION <= IF_instruction;
    ID_opcode <= ID_instruction(31 downto 21);
    ID_WR <= ID_instruction(4 downto 0);
    DEBUG_FORWARDA <= EX_forwardA;
    DEBUG_FORWARDB <= EX_forwardB;
    ID_shamt <= ID_instruction(15 downto 10);

----Internal Debug Signals----

    DEBUG_IF_FLUSH  <= IF_flush;
    DEBUG_REG_EQUAL <= ID_zero;

    DEBUG_PC_WRITE_ENABLE <= not ID_stall;

    DEBUG_TMP_REGS <= I_DEBUG_TMP_REGS;
    DEBUG_SAVED_REGS <= I_DEBUG_SAVED_REGS;
end;
