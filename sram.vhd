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

begin

  sram_out.rx <= ZD;

  ZA <= sram_in.addr when sram_in.re = '1' or sram_in.we = '1' else (others => 'Z');
  ZD <= sram_in.tx when sram_in.we = '1' else (others => 'Z');
  ZDP <= "0000" when sram_in.we = '1' else (others => 'Z');
  XWA <= not sram_in.we;

end architecture;
