library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_arith.ALL;
use IEEE.std_logic_unsigned.ALL;

use work.types.all;

entity timer is

  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    timer_in  : in  timer_in_type;
    timer_out : out timer_out_type);

end entity;

architecture Behavioral of timer is

  constant tick : std_logic_vector(19 downto 0) := x"A2BE8";

  type reg_type is record
    count  : std_logic_vector(19 downto 0);
    int_go : std_logic;
  end record;

  constant rzero : reg_type := (
    count  => (others => '0'),
    int_go => '0'
    );

  signal r, rin : reg_type := rzero;

begin

  comb : process(r, timer_in)
    variable v : reg_type;
  begin
    v := r;

    if timer_in.eoi = '1' then
      v.int_go := '0';
    end if;

    if r.count >= tick then
      v.count := (others => '0');
      v.int_go := '1';
    else
      v.count := r.count + 1;
    end if;

    rin <= v;

    timer_out.int_go <= r.int_go;
  end process;

  regs : process(clk, rst)
  begin
    if rst = '1' then
      r <= rzero;
    elsif rising_edge(clk) then
      r <= rin;
    end if;
  end process;

end architecture;
