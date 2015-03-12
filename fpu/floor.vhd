library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity floor is

  port (
    CLK : in  std_logic;
    stall : in std_logic;
    A   : in  std_logic_vector (31 downto 0);
    Q   : out std_logic_vector (31 downto 0));

end entity floor;

architecture rtl of floor is
  signal sign : std_logic := '0';
  signal expr : std_logic_vector (7 downto 0) := (others => '0');
  signal mantissa_in : std_logic_vector (23 downto 0) := (others => '0');
  signal mantissa_out : std_logic_vector (23 downto 0) := (others => '0');

  signal ret0 : std_logic_vector (31 downto 0) := (others => '0');
  constant ret1 : std_logic_vector (31 downto 0) := x"BF800000";
-- constant -1
  signal round_added : unsigned (23 downto 0) := (others => '0');

  constant mantissa_0 : unsigned (23 downto 0) := (others => '0');
  constant mantissa_1 : unsigned (23 downto 0) := (0 => '1',others => '0');

  signal b, c, d : std_logic_vector(31 downto 0) := (others => '0');
begin  -- architecture rtl

  with sign = '1' and (unsigned(mantissa_in) /= x"000000" & "000" or expr /= x"00") select
    ret0 <=
    ret1                          when true,
    sign & x"00" & x"00000" & "000" when others;


  mantissa_out <=
    mantissa_in when 150 < unsigned (expr) or 127 > unsigned (expr) else
    std_logic_vector(shift_left (arg =>
                                 shift_right (arg   => unsigned(mantissa_in),
                                              count => 150 - to_integer(unsigned(expr))),
                                 count              => 150 - to_integer(unsigned(expr))));

  round_added <= mantissa_0 when unsigned(expr) < 127 or unsigned (expr) >= 150 else
                 mantissa_0 when sign = '0' else
                 (23 => '1' ,others => '0') when unsigned (expr) = 127 else
                 mantissa_0 when unsigned(mantissa_in (149 - to_integer(unsigned(expr)) downto 0)) = 0 else
                 shift_left (arg => mantissa_1,
                             count => 150 - to_integer(unsigned(expr)));

  with 127 > unsigned(expr)select
    b <=
    ret0                                     when true,
    std_logic_vector(unsigned(sign & expr & (mantissa_out (22 downto 0))) + unsigned(round_added)) when others;

  process(clk) is
  begin
    if rising_edge(clk) and stall = '0' then
      c <= b;
      d <= c;
    end if;
  end process;

  q <= d;

end architecture rtl;
