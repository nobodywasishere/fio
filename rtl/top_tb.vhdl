library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_tb is

end entity;

architecture tb of top_tb is

    component top is
        port (
            CLK_100M : in std_logic;
            CPU_RESET_N : in std_logic;
            SWS : in std_logic_vector(15 downto 0);
            BTNS : in std_logic_vector(4 downto 0);
            LEDS : out std_logic_vector(15 downto 0);
            SEVSEG_LEDS : out std_logic_vector(6 downto 0);
            SEVSEG_ANODE : out std_logic_vector(7 downto 0)
        );
    end component top;

    signal CLK_100M :   std_logic;
    signal CPU_RESET_N :    std_logic;
    signal SWS :    std_logic_vector(15 downto 0);
    signal BTNS :   std_logic_vector(4 downto 0);
    signal LEDS :   std_logic_vector(15 downto 0);
    signal SEVSEG_LEDS :    std_logic_vector(6 downto 0);
    signal SEVSEG_ANODE :   std_logic_vector(7 downto 0);

begin

    dut1 : top port map (
        CLK_100M,
        CPU_RESET_N,
        SWS,
        BTNS,
        LEDS,
        SEVSEG_LEDS,
        SEVSEG_ANODE
    );

    process begin
        CLK_100M <= '1';
        CPU_RESET_N <= '0';
        wait for 5 ns;
        CPU_RESET_N <= '1';
        wait for 5 ns;
        for i in 0 to 1023 loop
            CLK_100M <= not CLK_100M;
            wait for 5 ns;
        end loop;
        wait for 100 ms;
    end process;

end;