library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.types.all;

entity mux is

  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    cpu_out    : in  cpu_out_type;
    cpu_in     : out cpu_in_type;
    cache_out  : in  cache_out_type;
    cache_in   : out cache_in_type;
    uart_out   : in  uart_out_type;
    uart_in    : out uart_in_type;
    bram_out   : in  bram_out_type;
    bram_in    : out bram_in_type);

end entity;

architecture Behavioral of mux is

  type reg_type is record
    i_addr : std_logic_vector(31 downto 0);
    d_addr : std_logic_vector(31 downto 0);
    d_we   : std_logic;
    d_re   : std_logic;
  end record;

  constant cpu_in_zero : cpu_in_type := (
    i_stall => '0',
    i_data  => (others => '0'),
    d_stall => '0',
    d_data  => (others => '0'));

  constant cache_in_zero : cache_in_type := (
    we    => '0',
    re    => '0',
    val   => (others => '0'),
    addr  => (others => '0'),
    re2   => '0',
    addr2 => (others => '0'));

  constant bram_in_zero : bram_in_type := (
    we   => '0',
    val  => (others => '0'),
    addr => (others => '0'),
    addr2 => (others => '0'));

  constant uart_in_zero : uart_in_type := (
    we   => '0',
    re   => '0',
    val  => (others => '0'),
    addr => (others => '0'));

  constant rzero : reg_type := (
    i_addr => (others => '0'),
    d_addr => (others => '0'),
    d_we   => '0',
    d_re   => '0');

  signal r, rin : reg_type := rzero;

begin

  comb : process(r, cpu_out, cache_out, uart_out, bram_out)
    variable v : reg_type;
    variable v_cpu_in    : cpu_in_type;
    variable v_cache_in  : cache_in_type;
    variable v_uart_in   : uart_in_type;
    variable v_bram_in   : bram_in_type;
  begin
    v := r;

    v_cpu_in    := cpu_in_zero;
    v_cache_in  := cache_in_zero;
    v_uart_in   := uart_in_zero;
    v_bram_in   := bram_in_zero;

    -- previous req

    case conv_integer(r.i_addr) is
      when 16#00000000# to 16#00001FFF# =>
        v_cpu_in.i_data := bram_out.rx2;
      when 16#00003000# to 16#003FFFFF# =>
        v_cpu_in.i_data := cache_out.rx2;
      when others =>
        assert false report "hoge";
    end case;

    if r.d_re = '1' or r.d_we = '1' then
      case conv_integer(r.d_addr) is
        when 16#00000000# to 16#00001FFF# =>
          v_cpu_in.d_data := bram_out.rx;
        when 16#00002000# =>
          v_cpu_in.d_data := uart_out.rx;
        when 16#00003000# to 16#003FFFFF# =>
          v_cpu_in.d_data := cache_out.rx;
        when others =>
          assert false report "hoge";
      end case;
    end if;

    -- current req

    case conv_integer(cpu_out.i_addr) is
      when 16#00000000# to 16#00001FFF# =>
        v_bram_in.addr2 := cpu_out.i_addr;

      when 16#00003000# to 16#003FFFFF# =>
        v_cache_in.re2 := cpu_out.i_re;
        v_cache_in.addr2 := cpu_out.i_addr;

        v_cpu_in.i_stall := cache_out.stall2;

      when others =>
        assert false report "fuga";
    end case;

    if cpu_out.d_we = '1' or cpu_out.d_re = '1' then
      case conv_integer(cpu_out.d_addr) is
        when 16#00000000# to 16#00001FFF# =>
          v_bram_in.we := cpu_out.d_we;
          v_bram_in.val := cpu_out.d_data;
          v_bram_in.addr := cpu_out.d_addr;

        when 16#00002000# =>
          v_uart_in.we := cpu_out.d_we;
          v_uart_in.re := cpu_out.d_re;
          v_uart_in.val := cpu_out.d_data;
          v_uart_in.addr := cpu_out.d_addr;

        when 16#00003000# to 16#003FFFFF# =>
          v_cache_in.we := cpu_out.d_we;
          v_cache_in.re := cpu_out.d_re;
          v_cache_in.val := cpu_out.d_data;
          v_cache_in.addr := cpu_out.d_addr;

          v_cpu_in.d_stall := cache_out.stall;

        when others =>
          assert false report "fuga";
      end case;
    end if;

    v.i_addr := cpu_out.i_addr;
    v.d_addr := cpu_out.d_addr;
    v.d_re   := cpu_out.d_re;
    v.d_we   := cpu_out.d_we;

    rin <= v;

    cpu_in    <= v_cpu_in;
    cache_in  <= v_cache_in;
    uart_in   <= v_uart_in;
    bram_in   <= v_bram_in;
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
