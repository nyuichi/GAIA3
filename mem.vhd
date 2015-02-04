library IEEE;
use IEEE.std_logic_1164.all;
use work.types.all;

entity mem is
  port (
    clk : in std_logic;

    mem_in : in mem_in_type;
    mem_out : out mem_out_type;

    -- Hardware Pins
    ZD : inout std_logic_vector(31 downto 0);
    ZDP : inout std_logic_vector(3 downto 0);
    ZA : out std_logic_vector(19 downto 0);
    XWA : out std_logic);
end mem;

architecture Behavioral of MEM is

begin

  mem_out.rx <= ZD;

  ZA <= mem_in.addr when mem_in.re = '1' or mem_in.we = '1' else (others => 'Z');
  ZD <= mem_in.tx when mem_in.we = '1' else (others => 'Z');
  ZDP <= "0000" when mem_in.we = '1' else (others => 'Z');
  XWA <= not mem_in.we;

end Behavioral;
