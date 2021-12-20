library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DMEM is
    port(
        Clock              : in  STD_LOGIC;
        Address            : in  STD_LOGIC_VECTOR(63 downto 0);
        MemRead            : in  STD_LOGIC;
        MemWrite           : in  STD_LOGIC;
        ReadData           : out STD_LOGIC_VECTOR(63 downto 0);
        WriteData          : in  STD_LOGIC_VECTOR(63 downto 0);
        SWS          : in  std_logic_vector(15 downto 0);
        BTNS         : in  std_logic_vector( 4 downto 0);
        LEDS         : out std_logic_vector(15 downto 0);
        SEVSEG_LEDS  : out std_logic_vector( 6 downto 0);
        SEVSEG_ANODE : out std_logic_vector( 7 downto 0)
    );
end entity DMEM;

architecture arch of DMEM is

    component sevensegdigit is
        port (
            I : in std_logic_vector(3 downto 0);
            D : out std_logic_vector(7 downto 0)
        );
	end component;

    constant RAM_L : unsigned(11 downto 0) := x"000";
    constant RAM_H : unsigned(11 downto 0) := x"0FF";
    constant SWS_L : unsigned(11 downto 0) := x"100";
    constant SWS_H : unsigned(11 downto 0) := x"10F";
    constant LED_L : unsigned(11 downto 0) := x"110";
    constant LED_H : unsigned(11 downto 0) := x"11F";
    constant SEG_L : unsigned(11 downto 0) := x"120";
    constant SEG_H : unsigned(11 downto 0) := x"127";
    constant BTN_L : unsigned(11 downto 0) := x"130";
    constant BTN_H : unsigned(11 downto 0) := x"134";

    type RAM_ARR_TYPE is array (255 downto 0) of std_logic_vector(63 downto 0);
    type SEG_ARR_TYPE is array (  7 downto 0) of std_logic_vector( 3 downto 0);

    signal LED_ARR : std_logic_vector(15 downto 0) := (others => '0');
    signal RAM_ARR : RAM_ARR_TYPE := (others => (others => '0'));
    signal SEG_ARR : SEG_ARR_TYPE := (others => (others => '0'));

    -- signal 
    signal SEG_I : std_logic_vector(3 downto 0) := (others => '0');
    signal SEG_D : std_logic_vector(7 downto 0) := (others => '0');
    signal SEG_A : std_logic_vector(7 downto 0) := not "00000001";
    signal SEG_C : integer := 1;

begin

    digit : sevensegdigit port map (
        I => SEG_I,
        D => SEG_D
    );

    LEDS <= LED_ARR;

    process (Clock) 
        variable uaddr : unsigned(11 downto 0) := x"000";
    begin
        if rising_edge(Clock) then
            uaddr := unsigned(Address(11 downto 0));
            ReadData <= 64x"0";

            if    RAM_L <= uaddr and uaddr <= RAM_H then
                if    MemRead = '1' and MemWrite = '0' then
                    ReadData <= RAM_ARR(to_integer(uaddr(7 downto 0)));
                elsif MemRead = '0' and MemWrite = '1' then
                    RAM_ARR(to_integer(uaddr(7 downto 0))) <= WriteData;
                end if;
            elsif SWS_L <= uaddr and uaddr <= SWS_H then
                if    MemRead = '1' and MemWrite = '0' then
                    ReadData <= (1 => SWS(to_integer(uaddr(2 downto 0))), others => '0');
                end if;
            elsif LED_L <= uaddr and uaddr <= LED_H then
                if    MemRead = '0' and MemWrite = '1' then
                    LED_ARR(to_integer(uaddr(3 downto 0))) <= WriteData(0);
                end if;
            elsif SEG_L <= uaddr and uaddr <= SEG_H then
                if    MemRead = '0' and MemWrite = '1' then
                    SEG_ARR(to_integer(uaddr(2 downto 0))) <= WriteData(3 downto 0);
                end if;
            elsif BTN_L <= uaddr and uaddr <= BTN_H then
                if    MemRead = '1' and MemWrite = '0' then
                    ReadData <= (1 => BTNS(to_integer(uaddr(2 downto 0))), others => '0');
                end if;
            end if;
        end if;
    end process;

    SEVSEG_ANODE <= SEG_A;
    SEVSEG_LEDS  <= SEG_D(7 downto 1);

    process (Clock) begin
        if rising_edge(Clock) then
            SEG_I <= SEG_ARR(SEG_C);

            if SEG_C = 7 then
                SEG_C <= 0;
            else
                SEG_C <= SEG_C + 1;
            end if;

		    SEG_A <= SEG_A( 6 downto 0 ) & SEG_A( 7 );
        end if;
    end process;

end arch ; -- arch