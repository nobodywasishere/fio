--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  ID_EX_register.vhd
--  Charles DePalma | Michael Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity IDEXRegister is
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
end IDEXRegister;

architecture behavioral of IDEXRegister is
begin
    process(clk, rst) is
    begin
        if rst = '1' then
            EX_ubranch    <= '0';
            EX_cbranch    <= '0';
            EX_memread    <= '0';
            EX_memwrite   <= '0';
            EX_memtoreg   <= '0';
            EX_ALUsrc     <= '0';
            EX_regwrite   <= '0';
            EX_shift      <= '0';
            EX_opcode     <= (others => '0');
            EX_ALUOpShort <= (others => '0');
            EX_WR         <= (others => '0');
            EX_RR1        <= (others => '0');
            EX_RR2        <= (others => '0');
            EX_RD1        <= (others => '0');
            EX_RD2        <= (others => '0');
            EX_immediate  <= (others => '0');
            EX_curr_PC    <= (others => '0');
            EX_shamt      <= (others => '0');
        elsif rising_edge(clk) then
            EX_ubranch    <= ID_ubranch;
            EX_cbranch    <= ID_cbranch;
            EX_memread    <= ID_memread;
            EX_memwrite   <= ID_memwrite;
            EX_memtoreg   <= ID_memtoreg;
            EX_ALUsrc     <= ID_ALUsrc;
            EX_regwrite   <= ID_regwrite;
            EX_opcode     <= ID_opcode;
            EX_ALUOpShort <= ID_ALUOpShort;
            EX_WR         <= ID_WR;
            EX_RR1        <= ID_RR1;
            EX_RR2        <= ID_RR2;
            EX_RD1        <= ID_RD1;
            EX_RD2        <= ID_RD2;
            EX_immediate  <= ID_immediate;
            EX_curr_PC    <= ID_curr_PC;
            EX_shift      <= ID_shift;
            EX_shamt      <= ID_shamt;
        end if;
    end process;
end;
