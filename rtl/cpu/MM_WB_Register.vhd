--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  MM_WB_Register.vhd
--  Charles DePalma | Michael Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity MMWBRegister is
port(
    --clk/reset 
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;
    --inputs
    MM_memtoreg     : in std_logic;
    MM_multoreg     : in std_logic;
    MM_regwrite     : in std_logic;
    MM_WR           : in std_logic_vector(4  downto 0);
    MM_ALU_result   : in std_logic_vector(63 downto 0);
    MM_memory_data  : in std_logic_vector(63 downto 0);
    --outputs      
    WB_memtoreg     : out std_logic;
    WB_multoreg     : out std_logic;
    WB_regwrite     : out std_logic;
    WB_WR           : out std_logic_vector(4  downto 0);
    WB_ALU_result   : out std_logic_vector(63 downto 0);
    WB_memory_data  : out std_logic_vector(63 downto 0)
);
end MMWBRegister;

architecture behavioral of MMWBRegister is
begin
    process(clk, rst) is 
    begin
        if rst = '1' then 
            WB_memtoreg     <= '0';
            WB_multoreg     <= '0';
            WB_regwrite     <= '0';
            WB_WR           <= (others => '0');
            WB_ALU_result   <= (others => '0');
            WB_memory_data  <= (others => '0');
        elsif rising_edge(clk) then 
            WB_memtoreg     <= MM_memtoreg;
            WB_multoreg     <= MM_multoreg;
            WB_regwrite     <= MM_regwrite;
            WB_WR           <= MM_WR;
            WB_ALU_result   <= MM_ALU_result;
            WB_memory_data  <= MM_memory_data;
        end if;
    end process;
end;