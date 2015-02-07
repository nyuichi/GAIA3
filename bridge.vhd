library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.types.all;

entity bridge is

  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    cpu_out   : in  bus_down_type;
    cpu_in    : out bus_up_type;
    cache_out : in  bus_up_type;
    cache_in  : out bus_down_type;
    uart_out  : in  bus_up_type;
    uart_in   : out bus_down_type);

end entity;

architecture Behavioral of bridge is

  type reg_type is record
    addr : std_logic_vector(31 downto 0);
  end record;

  constant bus_up_zero : bus_up_type := (
    stall => '0',
    rx    => (others => '0'));

  constant bus_down_zero : bus_down_type := (
    we   => '0',
    re   => '0',
    val  => (others => '0'),
    addr => (others => '0'));

  signal r, rin : reg_type;

begin

  comb : process(rst, cpu_out, cache_out)
    variable v : reg_type;

    variable v_cpu_in : bus_up_type;
    variable v_cache_in : bus_down_type;
    variable v_uart_in : bus_down_type;
  begin
    v := r;

    v_cpu_in := bus_up_zero;
    v_cache_in := bus_down_zero;
    v_uart_in := bus_down_zero;

    v.addr := cpu_out.addr;

    -- previous req
    case conv_integer(r.addr) is
      when 16#00002000# to 16#00002008# =>
        v_cpu_in := uart_out;
      when 16#00003000# to 16#003FFFFF# =>
        v_cpu_in := cache_out;
      when others =>
    end case;

    -- current req
    if cpu_out.we = '1' or cpu_out.re = '1' then
      case conv_integer(cpu_out.addr) is
        when 16#00002000# to 16#00002008# =>
          v_uart_in := cpu_out;
        when 16#00003000# to 16#003FFFFF# =>
          v_cache_in := cpu_out;
        when others =>
          assert false report "fuga";
      end case;
    end if;

    rin <= v;

    cpu_in <= v_cpu_in;
    cache_in <= v_cache_in;
    uart_in <= v_uart_in;
  end process;

  regs : process(clk)
  begin
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process;

end architecture;
