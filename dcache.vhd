library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

use work.types.all;
use work.util.all;

entity dcache is

  port (
    clk        : in  std_logic;
    rst        : in  std_logic;
    dcache_in  : in  dcache_in_type;
    dcache_out : out dcache_out_type);

end entity;

architecture Behavioral of dcache is

  type state_type is (NO_OP, WRITE_REQ, FETCH_REQ, FETCH);

  type tag_array_type is
    array(0 to 255) of std_logic_vector(17 downto 0);

  type reg_type is record
    ack : std_logic;

    state : state_type;

    -- data cache

    valid : std_logic_vector(0 to 255);

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
    valid     => (others => '0'),
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

  signal tag_array : tag_array_type := (others => (others => '0'));
  signal tag_array_we : std_logic := '0';
  signal tag_array_idx : std_logic_vector(7 downto 0) := (others => '0');
  signal tag_array_tag : std_logic_vector(17 downto 0) := (others => '0');


  impure function detect_miss return std_logic is
    variable index : integer;
    variable tag : std_logic_vector(17 downto 0);
    variable miss : std_logic;
  begin
    index := conv_integer(dcache_in.addr(13 downto 6));
    tag := dcache_in.addr(31 downto 14);

    if r.valid(index) = '1' and tag_array(index) = tag then
      miss := '0';
    else
      miss := '1';
    end if;

    return miss;
  end function;


  impure function v2p (vaddr : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable paddr : std_logic_vector(31 downto 0);
  begin

    if dcache_in.vmm_en = '0' then
      paddr := vaddr;
    else
      assert false severity failure;
    end if;

    return paddr;
  end function;


begin

  comb : process(r, dcache_in)
    variable v : reg_type;

    variable miss : std_logic;
    variable hazard : std_logic;
  begin
    v := r;

    -- data cache

    if dcache_in.addr < x"400000" then
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

        elsif (dcache_in.re = '1' or dcache_in.we = '1') and miss = '1' then
          v.tag    := dcache_in.addr(31 downto 14);
          v.index  := dcache_in.addr(13 downto 6);
          v.offset := dcache_in.addr(5 downto 2);

          v.ram_req := '1';
          hazard := '1';

          if dcache_in.vmm_en = '0' then
            v.state := FETCH_REQ;
          else
            assert false severity failure;
          end if;

        elsif dcache_in.b = '0' and dcache_in.re = '1' and miss = '0' then
          v.bram_addr := dcache_in.addr(13 downto 2);

        elsif dcache_in.b = '0' and dcache_in.we = '1' and miss = '0' then
          v.bram_addr := dcache_in.addr(13 downto 2);
          v.bram_we   := '1';
          v.bram_di   := dcache_in.val;

          v.ram_req  := '1';
          v.ram_we   := '1';
          v.ram_data := dcache_in.val;
          v.ram_addr := v2p(dcache_in.addr);
          v.state := WRITE_REQ;
          hazard := '1';

        elsif dcache_in.b = '1' and dcache_in.re = '1' and miss = '0' then

          if r.bram_addr = dcache_in.addr(13 downto 2) and r.bram_we = '0' then
            v.b := '1';
            case dcache_in.addr(1 downto 0) is
              when "00" =>
                v.b_out := repeat(dcache_in.bram_do(7), 24) & dcache_in.bram_do(7 downto 0);
              when "01" =>
                v.b_out := repeat(dcache_in.bram_do(15), 24) & dcache_in.bram_do(15 downto 8);
              when "10" =>
                v.b_out := repeat(dcache_in.bram_do(23), 24) & dcache_in.bram_do(23 downto 16);
              when "11" =>
                v.b_out := repeat(dcache_in.bram_do(31), 24) & dcache_in.bram_do(31 downto 24);
              when others =>
                assert false;
            end case;
          else
            v.bram_addr := dcache_in.addr(13 downto 2);
            hazard := '1';
          end if;

        elsif dcache_in.b = '1' and dcache_in.we = '1' and miss = '0' then

          if r.bram_addr = dcache_in.addr(13 downto 2) and r.bram_we = '0' then
            case dcache_in.addr(1 downto 0) is
              when "00" =>
                v.bram_di := dcache_in.bram_do(31 downto 8) & dcache_in.val(7 downto 0);
              when "01" =>
                v.bram_di := dcache_in.bram_do(31 downto 16) & dcache_in.val(7 downto 0) & dcache_in.bram_do(7 downto 0);
              when "10" =>
                v.bram_di := dcache_in.bram_do(31 downto 24) & dcache_in.val(7 downto 0) & dcache_in.bram_do(15 downto 0);
              when "11" =>
                v.bram_di := dcache_in.val(7 downto 0) & dcache_in.bram_do(23 downto 0);
              when others =>
                assert false;
            end case;
            v.bram_we   := '1';
            v.bram_addr := dcache_in.addr(13 downto 2);

            v.ram_req  := '1';
            v.ram_we   := '1';
            v.ram_data := v.bram_di;
            v.ram_addr := v2p(dcache_in.addr);
            v.state := WRITE_REQ;
            hazard := '1';
          else
            v.bram_addr := dcache_in.addr(13 downto 2);
            hazard := '1';
          end if;

        end if;

      when WRITE_REQ =>
        v.ram_req := '1';
        v.ram_we := '1';
        hazard := '1';

        if dcache_in.ram_grnt = '1' then
          v.ram_req := '0';
          v.state := NO_OP;
          hazard := '0';
        end if;

      when FETCH_REQ =>
        v.ram_req := '1';
        hazard := '1';

        if dcache_in.ram_grnt = '1' then
          v.ram_addr := r.tag & r.index & "0000" & "00";
          v.fetch_n  := -2;
          v.state := FETCH;
        end if;

      when FETCH =>
        v.ram_req := '1';
        hazard := '1';

        assert dcache_in.ram_grnt = '1' severity failure;

        case r.fetch_n is
          when -2 | -1 =>
            v.ram_addr := r.ram_addr + 4;
            v.fetch_n := r.fetch_n + 1;
          when 0 to 12 =>
            v.ram_addr := r.ram_addr + 4;
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := dcache_in.ram_data;
            v.fetch_n := r.fetch_n + 1;
          when 13 | 14 =>
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := dcache_in.ram_data;
            v.fetch_n := r.fetch_n + 1;
          when 15 =>
            v.ram_req := '0';
            v.bram_addr := r.index & conv_std_logic_vector(r.fetch_n, 4);
            v.bram_we := '1';
            v.bram_di := dcache_in.ram_data;
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

    if dcache_in.cai = '1' then
      v.valid := (others => '0');
    end if;


    -- end

    rin <= v;

    dcache_out.stall <= hazard;
    if r.ack = '1' then
      if r.b = '1' then
        dcache_out.rx <= r.b_out;
      else
        dcache_out.rx <= dcache_in.bram_do;
      end if;
    else
      dcache_out.rx <= (others => 'Z');
    end if;

    if r.fetch_n = 15 then
      tag_array_we <= '1';
    else
      tag_array_we <= '0';
    end if;
    tag_array_idx <= r.index;
    tag_array_tag <= r.tag;

    dcache_out.bram_we   <= v.bram_we;
    dcache_out.bram_addr <= v.bram_addr;
    dcache_out.bram_di   <= v.bram_di;

    dcache_out.ram_req  <= r.ram_req;
    dcache_out.ram_addr <= r.ram_addr;
    dcache_out.ram_data <= r.ram_data;
    dcache_out.ram_we   <= r.ram_we;
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
