--       _/\/\/\/\/\/\_     _/\/\/\/\_     ___/\/\/\/\___ 
--      _/\/\_________     ___/\/\___     _/\/\____/\/\_  
--     _/\/\/\/\/\___     ___/\/\___     _/\/\____/\/\_   
--    _/\/\_________     ___/\/\___     _/\/\____/\/\_    
--   _/\/\_________     _/\/\/\/\_     ___/\/\/\/\___     
--  ______________     __________     ______________      
--  LEGv8 CPU Assembler, CPU, and I/O System
--  "I want to take responsibility for my work to the very end" --Fio Piccolo
-- 
--  FILE.EXTENSION
--  Charles DePalma | Michael Riegert | Zev Pogrebin

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity IMEM is
    port(
        Clock    : in  std_logic;
        Address  : in  STD_LOGIC_VECTOR(63 downto 0); -- Address to read from
        ReadData : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity;

architecture rtl of IMEM is

    -- component blk_mem_gen_0 IS
    --     port (
    --         clka : IN STD_LOGIC;
    --         ena : IN STD_LOGIC;
    --         wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    --         addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    --         dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    --         douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    --     );
    -- end component;

    type rom_array is array (1023 downto 0) of std_logic_vector(31 downto 0);

    signal rom : rom_array := (
         0 => "10010001000000001010111111110000",
         1 => "10010001000000000000001111100101",
         2 => "10010001000000000000011111100110",
         3 => "10010001000000000000001111111000",
         4 => "10001011000001010000000011000111",
         5 => "10010001000000000000000011000101",
         6 => "10010001000000000000000011100110",
         7 => "11010001000000000000011000010000",
         8 => "10010001000000000000000010100000",
         9 => "10010001000000000010000100101001",
        10 => "10010001000000000000001011001010",
        11 => "11111000000000000000000101000000",
        12 => "11010001000000000000010100101001",
        13 => "10010001000000000000010101001010",
        14 => "11010011010000000001000000000000",
        15 => "10110101111111111111111110001001",
        16 => "11111000010000000001001011111001",
        17 => "10110101000000000000000001111001",
        18 => "10010001000000000000001100111000",
        19 => "00010111111111111111111111111101",
        20 => "10110100000000000000000001111000",
        21 => "10010001000000000000001100111000",
        22 => "00010111111111111111111111111010",
        23 => "10110101111111111111110110110000",
        24 => "00010100000000000000000000000000",
        others => (others => '0')
    );

begin

    -- mem1 : blk_mem_gen_0 port map (
    --     clka    =>  Clock,
    --     ena     =>  '1',
    --     wea     =>  "0",
    --     addra   =>  Address(9 downto 0),
    --     dina    =>  "00000000000000000000000000000000",
    --     douta   =>  ReadData
    -- );

    ReadData <= rom(to_integer(unsigned(Address(63 downto 2))));
    -- process (Clock) begin
    --     if rising_edge(Clock) then
    --     end if;
    -- end process;

end;