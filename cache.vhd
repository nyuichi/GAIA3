library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

use work.types.all;
use work.util.all;

entity cache is

  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    cache_in  : in  cache_in_type;
    cache_out : out cache_out_type);

end entity;

architecture Behavioral of cache is

  type state_type is (NO_OP, WRITE_REQ, FETCH_REQ, FETCH);

  type buf_type is array(0 to 15) of std_logic_vector(31 downto 0);

  type header_line_type is record
    valid : std_logic;
    tag   : std_logic_vector(17 downto 0);
  end record;

  type header_type is
    array(0 to 255) of header_line_type;

  type reg_type is record
    ack : std_logic;

    state : state_type;

    -- data cache

    header : header_type;

    tag    : std_logic_vector(17 downto 0);
    index  : std_logic_vector(7 downto 0);
    offset : std_logic_vector(3 downto 0);

    fetch_n : integer range -2 to 15;

    ram_req  : std_logic;
    ram_we   : std_logic;
    ram_data : std_logic_vector(31 downto 0);
    ram_addr : std_logic_vector(31 downto 0);

    bram_we   : std_logic;
    bram_di   : std_logic_vector(31 downto 0);
    bram_addr : std_logic_vector(11 downto 0);

    b     : std_logic;
    b_out : std_logic_vector(31 downto 0);
  end record;

  constant rzero : reg_type := (
    ack       => '0',
    state     => NO_OP,
    header    => (others => (valid => '0', tag => (others => '0'))),
    tag       => (others => '0'),
    index     => (others => '0'),
    offset    => (others => '0'),
    fetch_n   => -2,
    ram_req   => '0',
    ram_we    => '0',
    ram_data  => (others => '0'),
    ram_addr  => (others => '0'),
    bram_we   => '0',
    bram_di   => (others => '0'),
    bram_addr => (others => '0'),
    b         => '0',
    b_out     => (others => '0'));

  signal r, rin : reg_type := rzero;


  impure function detect_miss return std_logic is
    variable index : integer;
    variable tag : std_logic_vector(17 downto 0);
    variable miss : std_logic;
  begin
    index := conv_integer(cache_in.addr(13 downto 6));
    tag := cache_in.addr(31 downto 14);

    if r.header(index).valid = '1' and r.header(index).tag = tag then
      miss := '0';
    else
      miss := '1';
    end if;

    return miss;
  end function;


begin

  comb : process(r, cache_in)
    variable v : reg_type;

    variable miss : std_logic;
    variable hazard : std_logic;
  begin
    v := r;

    -- data cache

    if cache_in.addr < x"400000" then
      v.ack := '1';
    else
      v.ack := '0';
    end if;

    hazard := '0';

    v.b := '0';
    v.ram_req := '0';
    v.ram_we := '0';
    v.bram_we := '0';

    miss := detect_miss;

    case r.state is
      when NO_OP =>

        if v.ack = '0' then
          -- pass

        elsif (cache_in.re = '1' or cache_in.we = '1') and miss = '1' then
          v.tag    := cache_in.addr(31 downto 14);
          v.index  := cache_in.addr(13 downto 6);
          v.offset := cache_in.addr(5 downto 2);

          v.ram_req := '1';
          v.ram_addr := v.tag & v.index & "0000" & "00";
          v.fetch_n  := -2;
          v.state := FETCH_REQ;
          hazard := '1';

        elsif cache_in.b = '0' and cache_in.re = '1' and miss = '0' then
          v.bram_addr := cache_in.addr(13 downto 2);

        elsif cache_in.b = '0' and cache_in.we = '1' and miss = '0' then
          v.bram_addr := cache_in.addr(13 downto 2);
          v.bram_we   := '1';
          v.bram_di   := cache_in.val;

          v.ram_req  := '1';
          v.ram_we   := '1';
          v.ram_data := cache_in.val;
          v.ram_addr := cache_in.addr;
          v.state := WRITE_REQ;
          hazard := '1';

        elsif cache_in.b = '1' and cache_in.re = '1' and miss = '0' then

          if r.bram_addr = cache_in.addr(13 downto 2) and r.bram_we = '0' then
            v.b := '1';
            case cache_in.addr(1 downto 0) is
              when "00" =>
                v.b_out := repeat(cache_in.bram_do(7), 24) & cache_in.bram_do(7 downto 0);
              when "01" =>
                v.b_out := repeat(cache_in.bram_do(15), 24) & cache_in.bram_do(15 downto 8);
              when "10" =>
                v.b_out := repeat(cache_in.bram_do(23), 24) & cache_in.bram_do(23 downto 16);
              when "11" =>
                v.b_out := repeat(cache_in.bram_do(31), 24) & cache_in.bram_do(31 downto 24);
              when others =>
                assert false;
            end case;
          else
            v.bram_addr := cache_in.addr(13 downto 2);
            hazard := '1';
          end if;

        elsif cache_in.b = '1' and cache_in.we = '1' and miss = '0' then

          if r.bram_addr = cache_in.addr(13 downto 2) and r.bram_we = '0' then
            case cache_in.addr(1 downto 0) is
              when "00" =>
                v.bram_di := cache_in.bram_do(31 downto 8) & cache_in.val(7 downto 0);
              when "01" =>
                v.bram_di := cache_in.bram_do(31 downto 16) & cache_in.val(7 downto 0) & cache_in.bram_do(7 downto 0);
              when "10" =>
                v.bram_di := cache_in.bram_do(31 downto 24) & cache_in.val(7 downto 0) & cache_in.bram_do(15 downto 0);
              when "11" =>
                v.bram_di := cache_in.val(7 downto 0) & cache_in.bram_do(23 downto 0);
              when others =>
                assert false;
            end case;
            v.bram_we   := '1';
            v.bram_addr := cache_in.addr(13 downto 2);

            v.ram_req  := '1';
            v.ram_we   := '1';
            v.ram_data := v.bram_di;
            v.ram_addr := cache_in.addr;
            v.state := WRITE_REQ;
            hazard := '1';
          else
            v.bram_addr := cache_in.addr(13 downto 2);
            hazard := '1';
          end if;

        end if;

      when WRITE_REQ =>
        v.ram_req := '1';
        v.ram_we := '1';
        hazard := '1';

        if cache_in.ram_grnt = '1' then
          v.ram_req := '0';
          v.state := NO_OP;
          hazard := '0';
        end if;

      when FETCH_REQ =>
        v.ram_req := '1';
        hazard := '1';

        if cache_in.ram_grnt = '1' then
          v.state := FETCH;
        end if;

      when FETCH =>
        v.ram_req := '1';
        hazard := '1';

        assert cache_in.ram_grnt = '1' severity failure;

        case r.fetch_n is
          when -2 | -1 =>
            v.ram_addr := r.ram_addr + 4;
            v.fetch_n := r.fetch_n + 1;
          when 0 to 12 =>
            v.ram_addr := r.ram_addr + 4;
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := cache_in.ram_data;
            v.fetch_n := r.fetch_n + 1;
          when 13 | 14 =>
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := cache_in.ram_data;
            v.fetch_n := r.fetch_n + 1;
          when 15 =>
            v.ram_req := '0';
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := cache_in.ram_data;
            v.fetch_n := -2;
            v.header(conv_integer(r.index)).valid := '1';
            v.header(conv_integer(r.index)).tag := r.tag;
            v.state := NO_OP;
          when others =>
            assert false;
            v.state := NO_OP;
        end case;

      when others =>
        assert false;
        v.state := NO_OP;
    end case;

    if v.ack = '0' then
      hazard := '0';
    end if;


    -- end

    rin <= v;

    cache_out.stall <= hazard;
    if r.ack = '1' then
      if r.b = '1' then
        cache_out.rx <= r.b_out;
      else
        cache_out.rx <= cache_in.bram_do;
      end if;
    else
      cache_out.rx <= (others => 'Z');
    end if;

    cache_out.bram_we   <= v.bram_we;
    cache_out.bram_addr <= v.bram_addr;
    cache_out.bram_di   <= v.bram_di;

    cache_out.ram_req  <= r.ram_req;
    cache_out.ram_addr <= r.ram_addr;
    cache_out.ram_data <= r.ram_data;
    cache_out.ram_we   <= r.ram_we;
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
