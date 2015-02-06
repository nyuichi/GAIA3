library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.types.all;

entity cache is

  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    cpu_out   : in  cpu_out_type;
    cache_out : out cache_out_type;
    sram_out  : in  sram_out_type;
    sram_in   : out sram_in_type);

end entity;

architecture Behavioral of cache is

  type data_line_type is
    array (0 to 15) of std_logic_vector(31 downto 0);

  type data_type is
    array (0 to 255) of data_line_type;

  type header_line_type is record
    valid : std_logic;
    tag : integer range 0 to 262143;
  end record;

  type header_type is
    array(0 to 255) of header_line_type;

  type reg_type is record
    header : header_type;
    data : data_type;

    tag : integer range 0 to 262143;
    index : integer range 0 to 255;
    offset : integer range 0 to 15;

    fetch_n : integer range -2 to 15;
    flush_n : integer range -2 to 0;

    addr : std_logic_vector(31 downto 0);
  end record;

  signal r, rin : reg_type;

  impure function need_fetch (
    index : integer range 0 to 255;
    tag : integer range 0 to 262143)
    return boolean is
  begin
    if cpu_out.we = '0' and cpu_out.re = '0' then
      return false;
    else
      return not (r.header(index).valid = '1' and r.header(index).tag = tag);
    end if;
  end function;

begin

  comb : process(clk)
    variable v : reg_type;

    variable tag : integer range 0 to 262143;
    variable index : integer range 0 to 255;
    variable offset : integer range 0 to 15;

    variable stall : std_logic;
    variable fetch : std_logic;
    variable flush : std_logic;

    variable dout : std_logic_vector(31 downto 0);
    variable din : std_logic_vector(31 downto 0);
    variable we : std_logic;
  begin
    v := r;

    -- current req

    tag := conv_integer(cpu_out.addr(31 downto 14));
    index := conv_integer(cpu_out.addr(13 downto 6));
    offset := conv_integer(cpu_out.addr(5 downto 2));

    v.tag := tag;
    v.index := index;
    v.offset := offset;

    -- previous req

    dout := r.data(r.index)(r.offset);

    -- fetcher

    if need_fetch(index, tag) then
      fetch := '1';
    else
      fetch := '0';
    end if;

    v.addr := (others => '0');

    case r.fetch_n is
      when -2 =>
        if fetch = '1' then
          v.header(index).valid := '0';
          v.addr := conv_std_logic_vector(tag, 18) & conv_std_logic_vector(index, 8) & "000000";
          v.fetch_n := -1;
        end if;
      when -1 =>
        v.addr := r.addr + 4;
        v.fetch_n := 0;
      when 14 =>
        v.data(r.index)(r.fetch_n) := sram_out.rx;
        v.fetch_n := 15;
      when 15 =>
        v.header(index).valid := '1';
        v.header(index).tag := tag;
        v.data(r.index)(r.fetch_n) := sram_out.rx;
        v.fetch_n := -2;
      when others =>
        v.addr := r.addr + 4;
        v.data(r.index)(r.fetch_n) := sram_out.rx;
        v.fetch_n := r.fetch_n + 1;
    end case;

    -- flusher

    if cpu_out.we = '1' and fetch = '0' and r.flush_n /= 0 then
      flush := '1';
    else
      flush := '0';
    end if;

    we := '0';
    din := (others => '0');

    case r.flush_n is
      when -2 =>
        if flush = '1' then
          we := '1';
          v.addr := cpu_out.addr;
          v.flush_n := -1;
        end if;
      when -1 =>
        v.flush_n := 0;
      when 0 =>
        din := cpu_out.val;
        v.data(r.index)(r.offset) := din;
        v.flush_n := -2;
      when others =>
        assert false;
    end case;

    -- control

    if fetch = '1' or flush = '1' then
      stall := '1';
    else
      stall := '0';
    end if;

    -- end

    if rst = '1' then
      for i in 0 to 255 loop
        v.header(i).valid := '0';
      end loop;
      v.fetch_n := -2;
      v.flush_n := -2;
    end if;

    rin <= v;

    cache_out.stall <= stall;
    cache_out.rx <= dout;
    sram_in.addr <= v.addr;
    sram_in.tx <= din;
    sram_in.we <= we;
  end process;

  regs : process(clk)
  begin
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process;

end architecture;
