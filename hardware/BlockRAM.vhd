library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity blockram is

  generic (
    dwidth : integer;
    awidth : integer);

  port (
    clk   : in  std_logic;
    we    : in  std_logic;
    di    : in  std_logic_vector(dwidth - 1 downto 0);
    do    : out std_logic_vector(dwidth - 1 downto 0);
    addr  : in  std_logic_vector(awidth - 1 downto 0);
    do2   : out std_logic_vector(dwidth - 1 downto 0);
    addr2 : in  std_logic_vector(awidth - 1 downto 0) := (others => '0'));

end entity;

architecture behavioral of blockram is

  type ram_type is
    array(0 to (2 ** awidth) - 1) of std_logic_vector(dwidth - 1 downto 0);

  signal ram : ram_type := (others => (others => '0'));

  signal reg_addr  : std_logic_vector(awidth - 1 downto 0);
  signal reg_addr2 : std_logic_vector(awidth - 1 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        ram(conv_integer(addr)) <= di;
      end if;
      reg_addr  <= addr;
      reg_addr2 <= addr2;
    end if;
  end process;

  do  <= ram(conv_integer(reg_addr));
  do2 <= ram(conv_integer(reg_addr2));

end architecture;
