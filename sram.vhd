library IEEE;
use IEEE.std_logic_1164.all;
use work.types.all;

entity sram is

  port (
    clk : in std_logic;

    sram_in  : in  sram_in_type;
    sram_out : out sram_out_type;

    -- Hardware Pins
    ZD  : inout std_logic_vector(31 downto 0);
    ZDP : inout std_logic_vector(3 downto 0);
    ZA  : out   std_logic_vector(19 downto 0);
    XWA : out   std_logic);

end entity;

architecture Behavioral of sram is

  signal we1, we2 : std_logic;
  signal tx1, tx2 : std_logic_vector(31 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      we1 <= sram_in.we;
      tx1 <= sram_in.tx;
      we2 <= we1;
      tx2 <= tx1;
    end if;
  end process;

  sram_out.rx <= ZD;

  ZA  <= sram_in.addr(21 downto 2);
  ZD  <= tx2    when we2 = '1' else (others => 'Z');
  ZDP <= "0000" when we2 = '1' else (others => 'Z');
  XWA <= not sram_in.we;

end architecture;
