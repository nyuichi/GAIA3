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
    cache_out : out cache_out_type;
    sram_out  : in  sram_out_type;
    sram_in   : out sram_in_type);

end entity;

architecture Behavioral of cache is

  type state_type is (NO_OP, FETCH);

  type buf_type is array(0 to 15) of std_logic_vector(31 downto 0);

  type header_line_type is record
    valid : std_logic;
    tag   : std_logic_vector(17 downto 0);
  end record;

  type header_type is
    array(0 to 255) of header_line_type;

  type reg_type is record
    ack1 : std_logic;
    ack2 : std_logic;

    state : state_type;

    -- data cache

    header : header_type;

    tag    : std_logic_vector(17 downto 0);
    index  : std_logic_vector(7 downto 0);
    offset : std_logic_vector(3 downto 0);

    fetch_n : integer range -2 to 15;

    sram_addr : std_logic_vector(31 downto 0);
    sram_we   : std_logic;
    sram_re   : std_logic;
    sram_tx   : std_logic_vector(31 downto 0);

    bram_we   : std_logic;
    bram_di   : std_logic_vector(31 downto 0);
    bram_addr : std_logic_vector(11 downto 0);

    b     : std_logic;
    b_out : std_logic_vector(31 downto 0);

    -- instruction cache

    req1  : std_logic;
    req2  : std_logic;
    addr1 : std_logic_vector(31 downto 0);
    addr2 : std_logic_vector(31 downto 0);
  end record;

  constant rzero : reg_type := (
    ack1      => '0',
    ack2      => '0',
    state     => NO_OP,
    header    => (others => (valid => '0', tag => (others => '0'))),
    tag       => (others => '0'),
    index     => (others => '0'),
    offset    => (others => '0'),
    fetch_n   => -2,
    sram_addr => (others => '0'),
    sram_we   => '0',
    sram_re   => '0',
    sram_tx   => (others => '0'),
    bram_we   => '0',
    bram_di   => (others => '0'),
    bram_addr => (others => '0'),
    b         => '0',
    b_out     => (others => '0'),
    req1      => '0',
    req2      => '0',
    addr1     => (others => '0'),
    addr2     => (others => '0'));

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

  comb : process(r, cache_in, sram_out)
    variable v : reg_type;

    variable miss : std_logic;
    variable v_hazard : std_logic;
    variable v_hazard2 : std_logic;
    variable v_inst : std_logic_vector(31 downto 0);

    variable v_fst : std_logic;
    variable v_res : std_logic_vector(31 downto 0);
  begin
    v := r;

    -- data cache

    if cache_in.addr < x"400000" then
      v.ack1 := '1';
    else
      v.ack1 := '0';
    end if;

    v.sram_addr := (others => '0');
    v.sram_we := '0';
    v.sram_re := '0';

    v_fst   := '0';
    v.b     := '0';
    v.b_out := (others => '0');

    v.bram_addr := (others => '0');
    v.bram_we := '0';
    v.bram_di := (others => '0');

    miss := detect_miss;

    case r.state is
      when NO_OP =>

        if v.ack1 = '0' then
          -- pass

        elsif (cache_in.re = '1' or cache_in.we = '1') and miss = '1' then
          v.tag    := cache_in.addr(31 downto 14);
          v.index  := cache_in.addr(13 downto 6);
          v.offset := cache_in.addr(5 downto 2);

          v.header(conv_integer(v.index)).valid := '0';

          v.sram_addr := v.tag & v.index & "0000" & "00";
          v.sram_re   := '1';
          v.fetch_n   := -2;

          v.state := FETCH;

        elsif cache_in.b = '0' and cache_in.re = '1' and miss = '0' then
          v.bram_addr := cache_in.addr(13 downto 2);

        elsif cache_in.b = '0' and cache_in.we = '1' and miss = '0' then
          v.sram_addr := cache_in.addr;
          v.sram_we   := '1';
          v.sram_tx   := cache_in.val;

          v.bram_addr := cache_in.addr(13 downto 2);
          v.bram_we   := '1';
          v.bram_di   := cache_in.val;

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
            v_fst := '1';
            v.bram_addr := cache_in.addr(13 downto 2);
          end if;

        elsif cache_in.b = '1' and cache_in.we = '1' and miss = '0' then

          if r.bram_addr = cache_in.addr(13 downto 2) and r.bram_we = '0' then
            case cache_in.addr(1 downto 0) is
              when "00" =>
                v_res := cache_in.bram_do(31 downto 8) & cache_in.val(7 downto 0);
              when "01" =>
                v_res := cache_in.bram_do(31 downto 16) & cache_in.val(7 downto 0) & cache_in.bram_do(7 downto 0);
              when "10" =>
                v_res := cache_in.bram_do(31 downto 24) & cache_in.val(7 downto 0) & cache_in.bram_do(15 downto 0);
              when "11" =>
                v_res := cache_in.val(7 downto 0) & cache_in.bram_do(23 downto 0);
              when others =>
                assert false;
            end case;

            v.sram_addr := cache_in.addr;
            v.sram_we   := '1';
            v.sram_tx   := v_res;

            v.bram_addr := cache_in.addr(13 downto 2);
            v.bram_we   := '1';
            v.bram_di   := v_res;
          else
            v_fst := '1';
            v.bram_addr := cache_in.addr(13 downto 2);
          end if;

        end if;

      when FETCH =>

        case r.fetch_n is
          when -2 | -1 =>
            v.sram_addr := r.sram_addr + 4;
            v.sram_re := '1';
            v.fetch_n := r.fetch_n + 1;
          when 0 to 12 =>
            v.sram_addr := r.sram_addr + 4;
            v.sram_re := '1';
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := sram_out.rx;
            v.fetch_n := r.fetch_n + 1;
          when 13 | 14 =>
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := sram_out.rx;
            v.fetch_n := r.fetch_n + 1;
          when 15 =>
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := sram_out.rx;
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

    if v.ack1 = '0' then
      v_hazard := '0';
    elsif v.state = FETCH or r.state = FETCH or v_fst = '1' then
      v_hazard := '1';
    else
      v_hazard := '0';
    end if;


    -- instruction cache

    if cache_in.addr2 < x"400000" then
      v.ack2 := '1';
    else
      v.ack2 := '0';
    end if;

    v_inst := sram_out.rx;

    if v.ack2 = '0' then
      v_hazard2 := '0';
    elsif r.req2 = '1' and r.addr2 = cache_in.addr2 then
      v_hazard2 := '0';
    else
      v_hazard2 := '1';
    end if;

    v.req2  := r.req1;
    v.addr2 := r.addr1;

    if v.sram_re = '0' and v.sram_we = '0' then
      v.req1      := '1';
      v.addr1     := cache_in.addr2;
      -- request to sram
      v.sram_addr := cache_in.addr2;
      v.sram_re   := '1';
    else
      v.req1 := '0';
    end if;

    -- end

    rin <= v;

    cache_out.stall  <= v_hazard;
    if r.ack1 = '1' then
      if r.b = '1' then
        cache_out.rx <= r.b_out;
      else
        cache_out.rx <= cache_in.bram_do;
      end if;
    else
      cache_out.rx <= (others => 'Z');
    end if;

    cache_out.stall2 <= v_hazard2;
    if r.ack2 = '1' then
      cache_out.rx2 <= v_inst;
    else
      cache_out.rx2 <= (others => 'Z');
    end if;

    cache_out.bram_we   <= v.bram_we;
    cache_out.bram_addr <= v.bram_addr;
    cache_out.bram_di   <= v.bram_di;

    -- use value from *previous* clock
    sram_in.addr    <= r.sram_addr;
    sram_in.tx      <= r.sram_tx;
    sram_in.we      <= r.sram_we;
    sram_in.re      <= r.sram_re;
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
