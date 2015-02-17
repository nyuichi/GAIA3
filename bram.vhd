library IEEE;
use IEEE.std_logic_1164.all;

use work.types.all;

entity bram is

  port (
    clk      : in  std_logic;
    bram_in  : in  bram_in_type;
    bram_out : out bram_out_type);

end entity;

architecture behavioral of bram is

begin

  blockram_1: entity work.blockram
    generic map (
      dwidth => 32,
      awidth => 13)
    port map (
      clk  => clk,
      we   => bram_in.we,
      di   => bram_in.val,
      do   => bram_out.rx,
      addr => bram_in.addr(14 downto 2));

end architecture;
