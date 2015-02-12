library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.types.all;

-- # sram cache
-- When cache_out.stall = '1', caller must drive the same address and control
-- flags as the first call.

entity cache is

  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    cache_in  : in  bus_down_type;
    cache_out : out bus_up_type;
    sram_out  : in  sram_out_type;
    sram_in   : out sram_in_type);

end entity;

architecture Behavioral of cache is

  type header_line_type is record
    valid : std_logic;
    tag : std_logic_vector(17 downto 0);
  end record;

  type header_type is
    array(0 to 255) of header_line_type;

  type reg_type is record
    header : header_type;

    tag    : std_logic_vector(17 downto 0);
    index  : std_logic_vector(7 downto 0);
    offset : std_logic_vector(3 downto 0);

    fetch_n : integer range -2 to 15;
    flush_n : integer range -2 to 0;

    sram_addr : std_logic_vector(31 downto 0);
    sram_we   : std_logic;
    sram_tx   : std_logic_vector(31 downto 0);

    bram_addr : std_logic_vector(11 downto 0);
    bram_we   : std_logic;
  end record;

  constant rzero : reg_type := (
    header    => (others => (valid => '0', tag => (others => '0'))),
    tag       => (others => '0'),
    index     => (others => '0'),
    offset    => (others => '0'),
    fetch_n   => -2,
    flush_n   => -2,
    sram_addr => (others => '0'),
    sram_we   => '0',
    sram_tx   => (others => '0'),
    bram_addr => (others => '0'),
    bram_we   => '0');

  signal r, rin : reg_type;

  impure function need_fetch (
    index : std_logic_vector(7 downto 0);
    tag   : std_logic_vector(17 downto 0))
    return boolean is
    variable v_index : integer range 0 to 255;
  begin
    v_index := conv_integer(index);
    if cache_in.we = '0' and cache_in.re = '0' then
      return false;
    else
      return not (r.header(v_index).valid = '1' and r.header(v_index).tag = tag);
    end if;
  end function;

  impure function need_flush (
    next_fetch_n : integer range -2 to 15)
    return boolean is
  begin
    return cache_in.we = '1' and next_fetch_n = -2 and r.flush_n /= 0;
  end function;

  signal bram_we   : std_logic;
  signal bram_addr : std_logic_vector(11 downto 0);

begin

  blockram_1: entity work.blockram
    generic map (
      dwidth => 32,
      awidth => 12)
    port map (
      clk  => clk,
      we   => bram_we,
      di   => cache_in.val,
      do   => cache_out.rx,
      addr => bram_addr);

  comb : process(clk)
    variable v : reg_type;

    variable stall : std_logic;
  begin
    v := r;

    v.tag    := cache_in.addr(31 downto 14);
    v.index  := cache_in.addr(13 downto 6);
    v.offset := cache_in.addr(5 downto 2);

    -- fetcher

    v.sram_addr := (others => '0');
    v.bram_addr := (others => '0');

    case r.fetch_n is
      when -2 =>
        if need_fetch(v.index, v.tag) then
          v.header(conv_integer(v.index)).valid := '0';
          v.sram_addr := v.tag & v.index & "0000" & "00";
          v.fetch_n := -1;
        end if;
      when -1 =>
        v.sram_addr := r.sram_addr + 4;
        v.fetch_n := 0;
      when 14 =>
        v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
        v.fetch_n := 15;
      when 15 =>
        v.header(conv_integer(r.index)).valid := '1';
        v.header(conv_integer(r.index)).tag := r.tag;
        v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
        v.fetch_n := -2;
      when others =>
        v.sram_addr := r.sram_addr + 4;
        v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
        v.fetch_n := r.fetch_n + 1;
    end case;

    -- flusher

    v.sram_we := '0';
    v.sram_tx := (others => '0');
    v.bram_we := '1';

    case r.flush_n is
      when -2 =>
        if need_flush(v.fetch_n) then
          v.sram_we := '1';
          v.sram_addr := cache_in.addr;
          v.sram_tx := cache_in.val;
          v.flush_n := -1;
        end if;
      when -1 =>
        v.flush_n := 0;
      when 0 =>
        v.bram_addr := r.index & r.offset;
        v.bram_we := '1';
        v.flush_n := -2;
      when others =>
        assert false report "cache: invalid value stored in flush_n";
    end case;

    -- control

    if v.fetch_n = -2 and v.flush_n = -2 then
      stall := '0';
    else
      stall := '1';
    end if;

    -- end

    rin <= v;

    cache_out.stall <= stall;
    sram_in.addr    <= v.sram_addr;
    sram_in.tx      <= v.sram_tx;
    sram_in.we      <= v.sram_we;
    sram_in.re      <= '1';
    bram_we         <= v.bram_we;
    bram_addr       <= v.bram_addr;
  end process;

  regs : process(clk)
  begin
    if rst = '1' then
      r <= rzero;
    elsif rising_edge(clk) then
      r <= rin;
    end if;
  end process;

end architecture;
