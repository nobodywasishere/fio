library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registers is
-- This component is described in the textbook, starting on section 4.3
-- The indices of each of the registers can be found on the LEGv8 Green Card
-- Keep in mind that register 0(zero) has a constant value of 0 and cannot be overwritten

-- This should only write on the negative edge of Clock when RegWrite is asserted.
-- Reads should be purely combinatorial, i.e. they don't depend on Clock
-- HINT: Use the provided dmem.vhd as a starting point
port(RR1      : in  STD_LOGIC_VECTOR (4 downto 0);
     RR2      : in  STD_LOGIC_VECTOR (4 downto 0);
     WR       : in  STD_LOGIC_VECTOR (4 downto 0);
     WD       : in  STD_LOGIC_VECTOR (63 downto 0);
     RegWrite : in  STD_LOGIC;
     Clock    : in  STD_LOGIC;
     RD1      : out STD_LOGIC_VECTOR (63 downto 0);
     RD2      : out STD_LOGIC_VECTOR (63 downto 0);
     --Probe ports used for testing.
     -- Notice the width of the port means that you are
     --      reading only part of the register file.
     -- This is only for debugging
     -- You are debugging a sebset of registers here
     -- Temp registers: $X9 & $X10 & X11 & X12
     -- 4 refers to number of registers you are debugging
     DEBUG_TMP_REGS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0);
     -- Saved Registers X19 & $X20 & X21 & X22
     DEBUG_SAVED_REGS : out STD_LOGIC_VECTOR(64*4 - 1 downto 0)
);
end registers;

architecture behav of registers is

type RegArray is array (0 to 31) of STD_LOGIC_VECTOR(63 downto 0);
signal regs:RegArray := (
    X"0000_0000_0000_0000", -- 0
    X"0000_0000_0000_0000", -- 1
    X"0000_0000_0000_0000", -- 2
    X"0000_0000_0000_0000", -- 3
    X"0000_0000_0000_0000", -- 4
    X"0000_0000_0000_0000", -- 5
    X"0000_0000_0000_0000", -- 6
    X"0000_0000_0000_0000", -- 7
    X"0000_0000_0000_0000", -- 8
    X"0000_0000_0000_0000", -- 9
    X"0000_0000_0000_0000", -- 10
    X"0000_0000_0000_0000", -- 11
    X"0000_0000_0000_0000", -- 12
    X"0000_0000_0000_0000", -- 13
    X"0000_0000_0000_0000", -- 14
    X"0000_0000_0000_0000", -- 15
    X"0000_0000_0000_0000", -- 16
    X"0000_0000_0000_0000", -- 17
    X"0000_0000_0000_0000", -- 18
    X"0000_0000_0000_0000", -- 19
    X"0000_0000_0000_0100", -- 20
    X"0000_0000_0000_0110", -- 21
    X"0000_0000_0000_0120", -- 22
    X"0000_0000_0000_0130", -- 23
    X"0000_0000_0000_0000", -- 24
    X"0000_0000_0000_0000", -- 25
    X"0000_0000_0000_0000", -- 26
    X"0000_0000_0000_0000", -- 27
    X"0000_0000_0000_0000", -- 28
    X"0000_0000_0000_0000", -- 29
    X"0000_0000_0000_0000", -- 30
    X"0000_0000_0000_0000"  -- 31
);

begin

    RD1 <= regs(to_integer(unsigned(RR1)));
    RD2 <= regs(to_integer(unsigned(RR2)));

    process(Clock, RR1, RR2, WR, WD) begin
        if(falling_edge(Clock)) then
            if RegWrite = '1' and WR /= "11111" then
                regs(to_integer(unsigned(WR))) <= WD;
            end if;
        end if;
    end process;

    --Debugging contents
    DEBUG_TMP_REGS <= regs(9) & regs(10) & regs (11) & regs(12);
    DEBUG_SAVED_REGS <= regs(19) & regs(20) & regs(21) & regs(22);

end;
