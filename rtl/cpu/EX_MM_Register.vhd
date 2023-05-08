--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___
--  ______________     __________     ______________
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
--
--  EX_MM_Register.vhd
--  Charles DePalma | Margret Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity EXMMRegister is
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
    EX_multoreg     : in std_logic;
    EX_regwrite     : in std_logic;
    EX_WR           : in std_logic_vector(4  downto 0);
    EX_RD2          : in std_logic_vector(63 downto 0);
    EX_ALU_zero     : in std_logic;
    EX_ALU_result   : in std_logic_vector(63 downto 0);
    EX_branch_PC    : in std_logic_vector(63 downto 0);
    EX_MEMOp        : in std_logic_vector(1  downto 0);
    EX_MEMExt       : in std_logic;
    --outputs
    MM_ubranch      : out std_logic;
    MM_cbranch      : out std_logic;
    MM_memread      : out std_logic;
    MM_memwrite     : out std_logic;
    MM_memtoreg     : out std_logic;
    MM_multoreg     : out std_logic;
    MM_regwrite     : out std_logic;
    MM_WR           : out std_logic_vector(4  downto 0);
    MM_RD2          : out std_logic_vector(63 downto 0);
    MM_ALU_zero     : out std_logic;
    MM_ALU_result   : out std_logic_vector(63 downto 0);
    MM_branch_PC    : out std_logic_vector(63 downto 0);
    MM_MEMOp        : out std_logic_vector(1  downto 0);
    MM_MEMExt       : out std_logic
);
end EXMMRegister;

architecture behavioral of EXMMRegister is
begin
    process(clk, rst) is
    begin
        if rst = '1' then
            MM_ubranch      <= '0';
            MM_cbranch      <= '0';
            MM_memread      <= '0';
            MM_memwrite     <= '0';
            MM_memtoreg     <= '0';
            MM_multoreg     <= '0';
            MM_regwrite     <= '0';
            MM_WR           <= (others => '0');
            MM_RD2          <= (others => '0');
            MM_ALU_zero     <= '0';
            MM_ALU_result   <= (others => '0');
            MM_branch_PC    <= (others => '0');
            MM_MEMOp        <= (others => '0');
            MM_MEMExt       <= '0';
        elsif rising_edge(clk) then
            MM_ubranch      <= EX_ubranch;
            MM_cbranch      <= EX_cbranch;
            MM_memread      <= EX_memread;
            MM_memwrite     <= EX_memwrite;
            MM_memtoreg     <= EX_memtoreg;
            MM_multoreg     <= EX_multoreg;
            MM_regwrite     <= EX_regwrite;
            MM_WR           <= EX_WR;
            MM_RD2          <= EX_RD2;
            MM_ALU_zero     <= EX_ALU_zero;
            MM_ALU_result   <= EX_ALU_result;
            MM_branch_PC    <= EX_branch_PC;
            MM_MEMOp        <= EX_MEMOp;
            MM_MEMExt       <= EX_MEMExt;
        end if;
    end process;
end;
