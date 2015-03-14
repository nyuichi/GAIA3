library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

use work.types.all;
use work.util.all;

entity icache is

  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    icache_in  : in  icache_in_type;
    icache_out : out icache_out_type);

end entity;

architecture Behavioral of icache is

  type state_type is (NO_OP, VMM_REQ, VMM, FETCH_REQ, FETCH);

  type reg_type is record
    ack : std_logic;

    state : state_type;

    -- inst cache

    valid : std_logic_vector(0 to 255);

    tag    : std_logic_vector(17 downto 0);
    index  : std_logic_vector(7 downto 0);
    offset : std_logic_vector(3 downto 0);

    pdi : std_logic_vector(9 downto 0);
    pti : std_logic_vector(9 downto 0);
    off : std_logic_vector(11 downto 0);

    vmm_n : integer range 0 to 5;
    fetch_n : integer range -2 to 15;

    bubble : std_logic;

    ram_req  : std_logic;
    ram_addr : std_logic_vector(31 downto 0);

    bram_we   : std_logic;
    bram_di   : std_logic_vector(31 downto 0);
    bram_addr : std_logic_vector(11 downto 0);
  end record;

  constant rzero : reg_type := (
    ack       => '0',
    state     => NO_OP,
    valid     => (others => '0'),
    tag       => (others => '0'),
    index     => (others => '0'),
    offset    => (others => '0'),
    pdi       => (others => '0'),
    pti       => (others => '0'),
    off       => (others => '0'),
    vmm_n     => 0,
    fetch_n   => -2,
    bubble    => '0',
    ram_req   => '0',
    ram_addr  => (others => '0'),
    bram_we   => '0',
    bram_di   => (others => '0'),
    bram_addr => (others => '0'));

  signal r, rin : reg_type := rzero;

  type tag_array_type is
    array(0 to 255) of std_logic_vector(17 downto 0);

  signal tag_array : tag_array_type := (others => (others => '0'));
  signal tag_array_we : std_logic := '0';
  signal tag_array_idx : std_logic_vector(7 downto 0) := (others => '0');
  signal tag_array_tag : std_logic_vector(17 downto 0) := (others => '0');


  impure function detect_miss(addr : std_logic_vector(31 downto 0))
    return std_logic is

    variable index : integer;
    variable tag : std_logic_vector(17 downto 0);
    variable miss : std_logic;

  begin
    index := conv_integer(addr(13 downto 6));
    tag := addr(31 downto 14);

    if r.valid(index) = '1' and tag_array(index) = tag then
      miss := '0';
    else
      miss := '1';
    end if;

    return miss;
  end function;


begin

  comb : process(r, icache_in)
    variable v : reg_type;

    variable miss : std_logic;
    variable hazard : std_logic;
  begin
    v := r;

    -- inst cache

    if icache_in.addr < x"80000000" or icache_in.addr >= x"80002000" then
      v.ack := '1';
    else
      v.ack := '0';
    end if;

    hazard := '0';

    v.ram_req := '0';
    v.bram_we := '0';

    miss := detect_miss(icache_in.addr);

    if icache_in.co_we = '1' and detect_miss(icache_in.co_addr) = '0' then
      v.valid(conv_integer(icache_in.co_addr(13 downto 6))) := '0';
    end if;

    case r.state is
      when NO_OP =>

        if v.ack = '0' then
          -- pass

        elsif icache_in.re = '1' and miss = '1' then
          v.tag    := icache_in.addr(31 downto 14);
          v.index  := icache_in.addr(13 downto 6);
          v.offset := icache_in.addr(5 downto 2);
          v.pdi    := icache_in.addr(31 downto 22);
          v.pti    := icache_in.addr(21 downto 12);
          v.off    := icache_in.addr(11 downto 0);

          v.ram_req := '1';
          hazard := '1';

          if icache_in.vmm_en = '0' then
            v.state := FETCH_REQ;
          else
            v.state := VMM_REQ;
          end if;

        elsif icache_in.re = '1' and miss = '0' then
          v.bram_addr := icache_in.addr(13 downto 2);

        end if;

      when VMM_REQ =>
        v.ram_req := '1';
        hazard := '1';

        if icache_in.ram_grnt = '1' then
          v.ram_addr := icache_in.vmm_pd(31 downto 12) & r.pdi & "00";
          v.vmm_n := 0;
          v.state := VMM;
        end if;

      when VMM =>
        v.ram_req := '1';
        hazard := '1';

        assert icache_in.ram_grnt = '1' severity failure;

        case r.vmm_n is
          when 0 | 1 =>
            v.vmm_n := r.vmm_n + 1;
          when 2 =>
            v.vmm_n := r.vmm_n + 1;
            v.ram_addr := icache_in.ram_data(31 downto 12) & r.pti & "00";
          when 3 | 4 =>
            v.vmm_n := r.vmm_n + 1;
          when 5 =>
            v.vmm_n := 0;
            v.ram_addr := icache_in.ram_data(31 downto 12) & r.off(11 downto 6) & "0000" & "00";
            v.fetch_n := -2;
            v.state := FETCH;
          when others =>
            assert false;
            v.state := NO_OP;
        end case;

      when FETCH_REQ =>
        v.ram_req := '1';
        hazard := '1';

        if icache_in.ram_grnt = '1' then
          v.ram_addr := r.tag & r.index & "0000" & "00";
          v.fetch_n  := -2;
          v.state := FETCH;
        end if;

      when FETCH =>
        v.ram_req := '1';
        hazard := '1';

        assert icache_in.ram_grnt = '1' severity failure;

        case r.fetch_n is
          when -2 | -1 =>
            v.ram_addr := r.ram_addr + 4;
            v.fetch_n := r.fetch_n + 1;
          when 0 to 12 =>
            v.ram_addr := r.ram_addr + 4;
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := icache_in.ram_data;
            v.fetch_n := r.fetch_n + 1;
          when 13 | 14 =>
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := icache_in.ram_data;
            v.fetch_n := r.fetch_n + 1;
          when 15 =>
            v.ram_req := '0';
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := icache_in.ram_data;
            v.fetch_n := -2;
            v.valid(conv_integer(r.index)) := '1';
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

    v.bubble := hazard;

    if icache_in.cai = '1' then
      v.valid := (others => '0');
    end if;

    -- end

    rin <= v;

    icache_out.stall <= hazard;
    if r.ack = '1' then
      if r.bubble = '1' then
        icache_out.rx <= (others => '0');
      else
        icache_out.rx <= icache_in.bram_do;
      end if;
    else
      icache_out.rx <= (others => 'Z');
    end if;

    if r.fetch_n = 15 then
      tag_array_we <= '1';
    else
      tag_array_we <= '0';
    end if;
    tag_array_idx <= r.index;
    tag_array_tag <= r.tag;

    icache_out.bram_we   <= v.bram_we;
    icache_out.bram_addr <= v.bram_addr;
    icache_out.bram_di   <= v.bram_di;

    icache_out.ram_req  <= r.ram_req;
    icache_out.ram_addr <= r.ram_addr;
  end process;

  regs : process(clk, rst)
  begin
    if rst = '1' then
      r <= rzero;
    elsif rising_edge(clk) then
      r <= rin;
      if tag_array_we = '1' then
        tag_array(conv_integer(tag_array_idx)) <= tag_array_tag;
      end if;
    end if;
  end process;

end architecture;
