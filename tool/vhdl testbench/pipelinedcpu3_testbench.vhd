--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___
--  ______________     __________     ______________
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
--
--  pipelinedcpu3_testbench.vhd
--  Charles DePalma | Margret Riegert | Zev Pogrebin

library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity PipelinedCPU3Testbench is
end;

architecture tesbench of PipelinedCPU3Testbench is

signal DEBUG_PC             : std_logic_vector(63 downto 0);
signal DEBUG_INSTRUCTION    : std_logic_vector(31 downto 0);
signal clk                  : std_logic := '1';
signal rst                  : std_logic := '1';
signal X09                  : std_logic_vector(63 downto 0);
signal X10                  : std_logic_vector(63 downto 0);
signal X11                  : std_logic_vector(63 downto 0);
signal X12                  : std_logic_vector(63 downto 0);
signal X19                  : std_logic_vector(63 downto 0);
signal X20                  : std_logic_vector(63 downto 0);
signal X21                  : std_logic_vector(63 downto 0);
signal X22                  : std_logic_vector(63 downto 0);
signal DEBUG_TEMPS          : std_logic_vector(64*4-1 downto 0);
signal DEBUG_SAVED          : std_logic_vector(64*4-1 downto 0);
signal DEBUG_MEM            : std_logic_vector(64*4-1 downto 0);
signal DEBUG_FORWARDA       : std_logic_vector(1  downto 0);
signal DEBUG_FORWARDB       : std_logic_vector(1  downto 0);
signal MEM_00               : std_logic_vector(63 downto 0);
signal MEM_08               : std_logic_vector(63 downto 0);
signal MEM_16               : std_logic_vector(63 downto 0);
signal MEM_24               : std_logic_vector(63 downto 0);

signal DMEM_ADDR            : std_logic_vector(63 downto 0);
signal DMEM_READ_DATA       : std_logic_vector(63 downto 0);
signal DMEM_WRITE_DATA      : std_logic_vector(63 downto 0);
signal DMEM_READ            : std_logic;
signal DMEM_WRITE           : std_logic;

signal IMEM_ADDR            : std_logic_vector(63 downto 0);
signal IMEM_DATA            : std_logic_vector(31 downto 0);

component PipelinedCPU3 is
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
    end component;

    component IMEM is
        -- The instruction memory is a byte addressable, big-endian, read-only memory
        -- Reads occur continuously
        generic(NUM_BYTES : integer := 256);
        -- NUM_BYTES is the number of bytes in the memory (small to save computation resources)
        port(
             Address  : in  STD_LOGIC_VECTOR(63 downto 0); -- Address to read from
             ReadData : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component DMEM is
        -- The data memory is a byte addressble, big-endian, read/write memory with a single address port
        -- It may not read and write at the same time
        generic(NUM_BYTES : integer := 512);
        -- NUM_BYTES is the number of bytes in the memory (small to save computation resources)
        port(
             WriteData          : in  STD_LOGIC_VECTOR(63 downto 0); -- Input data
             Address            : in  STD_LOGIC_VECTOR(63 downto 0); -- Read/Write address
             MemRead            : in  STD_LOGIC; -- Indicates a read operation
             MemWrite           : in  STD_LOGIC; -- Indicates a write operation
             Clock              : in  STD_LOGIC; -- Writes are triggered by a rising edge
             ReadData           : out STD_LOGIC_VECTOR(63 downto 0); -- Output data
             --Probe ports used for testing
             -- Four 64-bit words: DMEM(0) & DMEM(4) & DMEM(8) & DMEM(12)
             DEBUG_MEM_CONTENTS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0)
        );
    end component;

begin

    DUT : PipelinedCPU3 port map(
        clk                => clk,
        rst                => rst,
        --IMEM ports
        IMEM_ADDR          => IMEM_ADDR,
        IMEM_DATA          => IMEM_DATA,
        --DMEM ports
        DMEM_ADDR          => DMEM_ADDR,
        DMEM_WRITE_DATA    => DMEM_WRITE_DATA,
        DMEM_READ_DATA     => DMEM_READ_DATA,
        DMEM_READ          => DMEM_READ,
        DMEM_WRITE         => DMEM_WRITE,
        DEBUG_FORWARDA     => DEBUG_FORWARDA,
        DEBUG_FORWARDB     => DEBUG_FORWARDB,
        DEBUG_PC           => DEBUG_PC,
        DEBUG_INSTRUCTION  => DEBUG_INSTRUCTION,
        DEBUG_TMP_REGS     => DEBUG_TEMPS,
        DEBUG_SAVED_REGS   => DEBUG_SAVED
    );

    DMEM_0 : DMEM port map(
        WriteData          => DMEM_WRITE_DATA,
        Address            => DMEM_ADDR,
        MemRead            => DMEM_READ,
        MemWrite           => DMEM_WRITE,
        Clock              => clk,
        ReadData           => DMEM_READ_DATA,
        DEBUG_MEM_CONTENTS => DEBUG_MEM
    );

    IMEM_0 : IMEM port map(
        Address            => IMEM_ADDR,
        ReadData           => IMEM_DATA
    );

    MEM_24 <=   DEBUG_MEM(8* 1-1 downto 8* 0) &
                DEBUG_MEM(8* 2-1 downto 8* 1) &
                DEBUG_MEM(8* 3-1 downto 8* 2) &
                DEBUG_MEM(8* 4-1 downto 8* 3) &
                DEBUG_MEM(8* 5-1 downto 8* 4) &
                DEBUG_MEM(8* 6-1 downto 8* 5) &
                DEBUG_MEM(8* 7-1 downto 8* 6) &
                DEBUG_MEM(8* 8-1 downto 8* 7);

    MEM_16 <=   DEBUG_MEM(8* 9-1 downto 8* 8) &
                DEBUG_MEM(8*10-1 downto 8* 9) &
                DEBUG_MEM(8*11-1 downto 8*10) &
                DEBUG_MEM(8*12-1 downto 8*11) &
                DEBUG_MEM(8*13-1 downto 8*12) &
                DEBUG_MEM(8*14-1 downto 8*13) &
                DEBUG_MEM(8*15-1 downto 8*14) &
                DEBUG_MEM(8*16-1 downto 8*15);

    MEM_08 <=   DEBUG_MEM(8*17-1 downto 8*16) &
                DEBUG_MEM(8*18-1 downto 8*17) &
                DEBUG_MEM(8*19-1 downto 8*18) &
                DEBUG_MEM(8*20-1 downto 8*19) &
                DEBUG_MEM(8*21-1 downto 8*20) &
                DEBUG_MEM(8*22-1 downto 8*21) &
                DEBUG_MEM(8*23-1 downto 8*22) &
                DEBUG_MEM(8*24-1 downto 8*23);

    MEM_00 <=   DEBUG_MEM(8*25-1 downto 8*24) &
                DEBUG_MEM(8*26-1 downto 8*25) &
                DEBUG_MEM(8*27-1 downto 8*26) &
                DEBUG_MEM(8*28-1 downto 8*27) &
                DEBUG_MEM(8*29-1 downto 8*28) &
                DEBUG_MEM(8*30-1 downto 8*29) &
                DEBUG_MEM(8*31-1 downto 8*30) &
                DEBUG_MEM(8*32-1 downto 8*31);

    X12 <= DEBUG_TEMPS(63  downto 0  );
    X11 <= DEBUG_TEMPS(127 downto 64 );
    X10 <= DEBUG_TEMPS(191 downto 128);
    X09 <= DEBUG_TEMPS(255 downto 192);
    X22 <= DEBUG_SAVED(63  downto 0  );
    X21 <= DEBUG_SAVED(127 downto 64 );
    X20 <= DEBUG_SAVED(191 downto 128);
    X19 <= DEBUG_SAVED(255 downto 192);

    process begin
        wait for 5 ns;
        clk <= not clk;
        wait for 5 ns;
        clk <= not clk;
    end process;

    process begin
        wait for 7.5 ns;
        rst <= '0';
        wait;
    end process;


end;
