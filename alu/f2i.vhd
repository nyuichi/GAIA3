library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity f2i is
  port (
    clk : in std_logic;
    A   : in  std_logic_vector (31 downto 0);
    Q   : out std_logic_vector (31 downto 0));
end entity f2i;

architecture behav of f2i is
  signal sign : std_logic := '0';
  signal expr : std_logic_vector (7 downto 0) := (others => '0');
  signal mantissa : std_logic_vector (22 downto 0) := (others => '0');
  signal ret : std_logic_vector (31 downto 0) := (others => '0');

  signal q_res : std_logic_vector(31 downto 0) := (others => '0');
begin  -- architecture behav
  with expr > 150 select
    ret <=
    std_logic_vector(
      shift_left (arg => unsigned("000000001" & mantissa),
                  count => conv_integer(expr - 150))) when true,
    std_logic_vector(
      shift_right (arg => unsigned("000000001" & mantissa),
                   count => conv_integer(150 - expr))) when others;

  with sign select
    q_res <=
    ret  when '0',
    not ret + 1 when others;

  -- input
  sign <= A (31);
  expr <= A (30 downto 23);
  mantissa <= A (22 downto 0);

  process(clk)
  begin
    if rising_edge(clk) then
      q <= q_res;
    end if;
  end process;

end architecture behav;
