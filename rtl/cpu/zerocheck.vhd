--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  zerocheck.vhd
--  Charles DePalma | Micheal Riegart | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity zerocheck is
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
end zerocheck;

architecture dataflow of zerocheck is

signal RD_check : std_logic_vector(63 downto 0) := (others=>'1');
signal MM_fw : boolean;
signal WB_fw : boolean;

begin

    WB_fw <= WB_regwrite = '1' and not (WB_WR = "11111");
    MM_fw <= MM_regwrite = '1' and not (MM_WR = "11111");

    RD_check <= MM_WD when ID_RR2 = MM_WR and MM_fw else
                WB_WD when ID_RR2 = WB_WR and WB_fw else
                ID_RD2;

    ID_zero <= '1' when RD_check = (63 downto 0 => '0') else '0';

end;