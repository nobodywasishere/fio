--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  hazarddetect.vhd
--  Charles DePalma | Michael Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity HazardDetectionUnit is
port(
    clk             : in std_logic;
    rst             : in std_logic;
    ID_branch       : in std_logic;
    EX_MemRead      : in std_logic;
    EX_WR           : in std_logic_vector(4 downto 0);
    MM_WR           : in std_logic_vector(4 downto 0);
    ID_RR1          : in std_logic_vector(4 downto 0);
    ID_RR2          : in std_logic_vector(4 downto 0);
    EX_regwrite     : in std_logic;
    ID_cbranch      : in std_logic;
    MM_memread      : in std_logic;
    --outputs
    Stall       : out std_logic;
    Flush       : out std_logic
);
end HazardDetectionUnit;

architecture dataflow of HazardDetectionUnit is

    signal Stall_i : std_logic := '0';

begin
    Flush <= ID_branch;

    -- Making the HDU latch due to bugs
    process (clk, rst, EX_memread, EX_regwrite, MM_memread, 
             ID_cbranch, ID_RR1, ID_RR2, EX_WR) begin

        if rising_edge(clk) or rst = '1' then
            Stall <= '0';
        end if;

        if EX_MemRead = '1' and EX_WR = ID_RR1 then
            Stall <= '1';
        elsif EX_MemRead = '1' and EX_WR = ID_RR2 then
            Stall <= '1';
        elsif EX_WR = ID_RR2 and (EX_regwrite and ID_cbranch) = '1' then
            Stall <= '1';
        elsif MM_WR = ID_RR2 and (MM_memread and ID_cbranch) = '1' then
            Stall <= '1';
        end if;
    
    -- Stall <= --Load/Use
    --          '1' when EX_MemRead = '1' and EX_WR = ID_RR1 else 
    --          '1' when EX_MemRead = '1' and EX_WR = ID_RR2 else 
    --          --Branch Req
    --          '1' when EX_WR = ID_RR2 and (EX_regwrite and ID_cbranch) = '1' else 
    --          '1' when MM_WR = ID_RR2 and (MM_memread and ID_cbranch) = '1' else
    --          '0';

    end process;
end;
