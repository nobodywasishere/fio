--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  top.vhdl
--  Charles DePalma | Micheal Riegart | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top is
    port (
        CLK_100M : in std_logic;
        CPU_RESET_N : in std_logic;
        SWS : in std_logic_vector(15 downto 0);
        BTNS : in std_logic_vector(4 downto 0);
        LEDS : out std_logic_vector(15 downto 0);
        SEVSEG_LEDS : out std_logic_vector(6 downto 0);
        SEVSEG_ANODE : out std_logic_vector(7 downto 0)
    );
end entity top;

architecture rtl of top is

    constant CLK_ITER : integer := 19;

    component PipelinedCPU3 is
        port(
            clk             : in std_logic;
            rst             : in std_logic;
            --IMEM ports
            IMEM_ADDR       : out std_logic_vector(63 downto 0);
            IMEM_DATA       : in  std_logic_vector(31 downto 0);
            --DMEM ports
            DMEM_ADDR       : out std_logic_vector(63 downto 0);
            DMEM_WRITE_DATA : out std_logic_vector(63 downto 0);
            DMEM_READ_DATA  : in  std_logic_vector(63 downto 0);
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
        port(
            Clock    : in  std_logic;
            Address  : in  STD_LOGIC_VECTOR(63 downto 0); -- Address to read from
            ReadData : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    component DMEM is
        port(
            Clock              : in  STD_LOGIC;
            Address            : in  STD_LOGIC_VECTOR(63 downto 0);
            MemRead            : in  STD_LOGIC;
            MemWrite           : in  STD_LOGIC;
            ReadData           : out STD_LOGIC_VECTOR(63 downto 0);
            WriteData          : in  STD_LOGIC_VECTOR(63 downto 0);
            SWS : in std_logic_vector(15 downto 0);
            BTNS : in std_logic_vector(4 downto 0);
            LEDS : out std_logic_vector(15 downto 0);
            SEVSEG_LEDS : out std_logic_vector(6 downto 0);
            SEVSEG_ANODE : out std_logic_vector(7 downto 0)
        );
    end component DMEM;

    signal counter : std_logic_vector(31 downto 0) := (others => '0');
    signal CPU_RESET : std_logic := '0';

    signal IMEM_ADDR : std_logic_vector(63 downto 0) := (others => '0');
    signal IMEM_DATA : std_logic_vector(31 downto 0) := (others => '0');

    signal DMEM_ADDR        : std_logic_vector(63 downto 0) := (others => '0');
    signal DMEM_WRITE_DATA  : std_logic_vector(63 downto 0) := (others => '0');
    signal DMEM_READ_DATA   : std_logic_vector(63 downto 0) := (others => '0');
    signal DMEM_READ        : std_logic := '0';
    signal DMEM_WRITE       : std_logic := '0';

    signal LEDS_OUT : std_logic_vector(15 downto 0) := (others => '0');

    signal DEBUG_PC : std_logic_vector(63 downto 0) := (others => '0');
    signal DEBUG_INSTRUCTION : std_logic_vector(31 downto 0) := (others => '0');

begin

    CPU_RESET <= not CPU_RESET_N;

    process (CLK_100M) begin
        if rising_edge(CLK_100M) then
            counter <= std_logic_vector(unsigned(counter) + to_unsigned(1, 31));
        end if;
    end process;

    cpu1 : PipelinedCPU3 port map (
        clk => counter(CLK_ITER),
        rst => CPU_RESET,

        IMEM_ADDR   => IMEM_ADDR,
        IMEM_DATA   => IMEM_DATA,

        DMEM_ADDR   => DMEM_ADDR,
        DMEM_WRITE_DATA => DMEM_WRITE_DATA,
        DMEM_READ_DATA  => DMEM_READ_DATA,
        DMEM_READ   => DMEM_READ,
        DMEM_WRITE  => DMEM_WRITE,

        DEBUG_IF_FLUSH  => open,
        DEBUG_REG_EQUAL => open,
        DEBUG_FORWARDA  => open,
        DEBUG_FORWARDB  => open,
        DEBUG_PC    => DEBUG_PC,
        DEBUG_PC_WRITE_ENABLE   => open,
        DEBUG_INSTRUCTION   => DEBUG_INSTRUCTION,
        DEBUG_TMP_REGS  => open,
        DEBUG_SAVED_REGS    => open,
        DEBUG_MEM_CONTENTS  => open
    );

    LEDS <= DEBUG_PC(17 downto 2) when BTNS(0) = '1' else LEDS_OUT;

    imem1 : IMEM port map (
        Clock => counter(CLK_ITER),
        Address => IMEM_ADDR,
        ReadData => IMEM_DATA
    );

    dmem1 : DMEM port map (
        Clock        => counter(16),
        Address      => DMEM_ADDR,
        MemRead      => DMEM_READ,
        MemWrite     => DMEM_WRITE,
        ReadData     => DMEM_READ_DATA,
        WriteData    => DMEM_WRITE_DATA,
        SWS          => SWS,
        BTNS         => BTNS,
        LEDS         => LEDS_OUT,
        SEVSEG_LEDS  => SEVSEG_LEDS,
        SEVSEG_ANODE => SEVSEG_ANODE
    );

end rtl;