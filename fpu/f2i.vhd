library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity f2i is
  port (
    CLK : in  std_logic;
    stall : in std_logic;
    A   : in  std_logic_vector (31 downto 0);
    Q   : out std_logic_vector (31 downto 0));
end entity f2i;

architecture behav of f2i is
  signal sign : std_logic := '0';
  signal expr : std_logic_vector (7 downto 0) := (others => '0');
  signal mantissa : std_logic_vector (22 downto 0) := (others => '0');
  signal ret : std_logic_vector (31 downto 0) := (others => '0');

  signal b, c, d : std_logic_vector(31 downto 0) := (others => '0');

begin  -- architecture behav

  process (clk) is
  begin
    if rising_edge (clk) and stall = '0' then
      b <= a;
    end if;
  end process;

  sign <= B (31);
  expr <= B (30 downto 23);
  mantissa <= B (22 downto 0);

  with expr > 150 select
    ret <=
    std_logic_vector(
      shift_left (arg => unsigned("000000001" & mantissa),
                  count => conv_integer(expr - 150))) when true,
    std_logic_vector(
      shift_right (arg => unsigned("000000001" & mantissa),
                  count => conv_integer(150 - expr))) when others;

  with sign select
    c <=
    ret  when '0',
    not ret + 1 when others;

  process (clk) is
  begin
    if rising_edge (clk) and stall = '0' then
      d <= c;
    end if;
  end process;

  q <= d;

end architecture behav;
