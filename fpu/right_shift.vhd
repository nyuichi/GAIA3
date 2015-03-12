library IEEE;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity right_shift is
  
  port (
    D : in  std_logic_vector (23 downto 0);
    s : in  std_logic_vector (4 downto 0);
    q : out std_logic_vector (26 downto 0));

end entity right_shift;

architecture rtl of right_shift is

  signal P1 : std_logic_vector(26 downto 0);
  signal P2 : std_logic_vector(26 downto 0);
  signal Round : std_logic_vector(3 downto 0);

begin  -- architecture rtl

  with s (1 downto 0) select
    P1 <=
    D & "000"      when "00",
    '0' & D & "00" when "01",
    "00" & D & '0' when "10",
    "000" & D      when others;

  with s (2) select
    P2 <=
    P1                                    when '0',
    "0000" & P1 (26 downto 4)             when others;

  with s (4 downto 3) select
    q <=
    P2                                                 when "00",
    "00000000" & P2 (26 downto 8)                      when "01",
    "0000000000000000" & P2 (26 downto 16)             when "10",
    "000000000000000000000000" & P2 (26 downto 24)      when others;

end architecture rtl;
