library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.types.all;

entity cache is

  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    dc_in    : in  dmem_down_type;
    dc_out   : out dmem_up_type;
    dc_stall : out std_logic;
    ic_in    : in  imem_down_type;
    ic_out   : out imem_up_type;
    ic_stall : out std_logic;
    sram_out : in  sram_out_type;
    sram_in  : out sram_in_type);

end entity;

architecture Behavioral of cache is

  type data_header_line_type is record
    valid : std_logic;
    tag   : std_logic_vector(17 downto 0);
  end record;

  type data_header_type is
    array(0 to 255) of data_header_line_type;

  type dc_type is record
    header : data_header_type;

    we     : std_logic;
    tag    : std_logic_vector(17 downto 0);
    index  : std_logic_vector(7 downto 0);
    offset : std_logic_vector(3 downto 0);

    bram_addr : std_logic_vector(11 downto 0);
    bram_we   : std_logic;
    bram_tx   : std_logic_vector(31 downto 0);
  end record;

  type ic_type is record
    header : std_logic_vector(25 downto 0);

    tag : std_logic_vector(25 downto 0);
    offset : std_logic_vector(3 downto 0);

    bram_addr : std_logic_vector(3 downto 0);
    bram_we   : std_logic;
    bram_tx   : std_logic_vector(31 downto 0);
  end record;

  type state_type is (NO_OP, DC_FETCH, DC_FLUSH, IC_FETCH);

  type reg_type is record
    state : state_type;

    dc : dc_type;
    ic : ic_type;

    fetch_n : integer range -1 to 15;
    flush_n : integer range -1 to 0;
    ifetch_n: integer range -1 to 15;

    sram_addr : std_logic_vector(31 downto 0);
    sram_we   : std_logic;
    sram_tx   : std_logic_vector(31 downto 0);
  end record;

  constant rzero : reg_type := (
    state       => NO_OP,
    dc          => (
      header    => (others => (valid => '0', tag => (others => '0'))),
      we        => '0',
      tag       => (others => '0'),
      index     => (others => '0'),
      offset    => (others => '0'),
      bram_addr => (others => '0'),
      bram_we   => '0',
      bram_tx   => (others => '0')),
    ic          => (
      header    => (others => '0'),
      tag       => (others => '0'),
      offset    => (others => '0'),
      bram_addr => (others => '0'),
      bram_we   => '0',
      bram_tx   => (others => '0')),
    fetch_n     => -1,
    flush_n     => -1,
    ifetch_n    => -1,
    sram_addr   => (others => '0'),
    sram_we     => '0',
    sram_tx     => (others => '0'));

  signal r, rin : reg_type;

  impure function dc_need_fetch (v : reg_type) return boolean is
    variable index : integer range 0 to 255;
  begin
    index := conv_integer(v.dc.index);
    if dc_in.we = '0' and dc_in.re = '0' then
      return false;
    else
      return not (r.dc.header(index).valid = '1' and r.dc.header(index).tag = v.dc.tag);
    end if;
  end function;

  function dc_need_flush (v : reg_type) return boolean is
  begin
    return v.dc.we = '1';
  end function;

  impure function ic_need_fetch (v : reg_type) return boolean is
  begin
    return ic_in.re = '1' and not (v.ic.header = v.ic.tag);
  end function;

  signal dc_bram_we   : std_logic;
  signal dc_bram_addr : std_logic_vector(11 downto 0);
  signal dc_bram_tx   : std_logic_vector(31 downto 0);
  signal dc_bram_rx   : std_logic_vector(31 downto 0);

  signal ic_bram_we   : std_logic;
  signal ic_bram_addr : std_logic_vector(3 downto 0);
  signal ic_bram_tx   : std_logic_vector(31 downto 0);
  signal ic_bram_rx   : std_logic_vector(31 downto 0);

begin

  blockram_1: entity work.blockram
    generic map (
      dwidth => 32,
      awidth => 12)
    port map (
      clk  => clk,
      we   => dc_bram_we,
      di   => dc_bram_tx,
      do   => dc_bram_rx,
      addr => dc_bram_addr);

  blockram_2: entity work.blockram
    generic map (
      dwidth => 32,
      awidth => 4)
    port map (
      clk  => clk,
      we   => ic_bram_we,
      di   => ic_bram_tx,
      do   => ic_bram_rx,
      addr => ic_bram_addr);

  comb : process(r, dc_in, ic_in, sram_out)
    variable v : reg_type;

    variable v_dc_stall : std_logic;
    variable v_ic_stall : std_logic;
  begin
    v := r;

    v.sram_addr := (others => '0');
    v.sram_we   := '0';
    v.sram_tx   := (others => '0');

    v.dc.bram_we   := '0';
    v.dc.bram_tx   := (others => '0');
    v.dc.bram_addr := (others => '0');

    v.ic.bram_we   := '0';
    v.ic.bram_tx   := (others => '0');
    v.ic.bram_addr := (others => '0');

    -- decode

    if r.state = NO_OP or r.state = IC_FETCH then
      v.dc.we        := dc_in.we;
      v.dc.tag       := dc_in.addr(31 downto 14);
      v.dc.index     := dc_in.addr(13 downto 6);
      v.dc.offset    := dc_in.addr(5 downto 2);
      v.dc.bram_addr := v.dc.index & v.dc.offset;
    end if;

    if r.state = NO_OP or r.state = DC_FETCH or r.state = DC_FLUSH then
      v.ic.tag    := ic_in.addr(31 downto 6);
      v.ic.offset := ic_in.addr(5 downto 2);
      v.ic.bram_addr := v.ic.offset;
    end if;

    -- run state

    case r.state is
      when NO_OP =>
        assert r.fetch_n = -1;
        assert r.flush_n = -1;
        assert r.ifetch_n = -1;

        -- miss?

        if dc_need_fetch(v) then
          v.state     := DC_FETCH;
          v.dc.header(conv_integer(v.dc.index)).valid := '0';
          v.sram_addr := v.dc.tag & v.dc.index & "0000" & "00";
        elsif dc_need_flush(v) then
          v.state     := DC_FLUSH;
          v.sram_we   := '1';
          v.sram_tx   := dc_in.data;
          v.sram_addr := dc_in.addr;
        elsif ic_need_fetch(v) then
          v.state := IC_FETCH;
          v.sram_addr := v.ic.tag & "0000" & "00";
        end if;

      when DC_FETCH =>
        case r.fetch_n is
          when -1 =>
            v.sram_addr := r.sram_addr + 4;
            v.fetch_n := 0;
          when 0 to 13 =>
            v.sram_addr := r.sram_addr + 4;
            v.dc.bram_addr := r.dc.index & conv_std_logic_vector(r.fetch_n, 4);
            v.dc.bram_we := '1';
            v.dc.bram_tx := sram_out.rx;
            v.fetch_n := r.fetch_n + 1;
          when 14 =>
            v.dc.bram_addr := r.dc.index & conv_std_logic_vector(r.fetch_n, 4);
            v.dc.bram_we := '1';
            v.dc.bram_tx := sram_out.rx;
            v.fetch_n := 15;
          when 15 =>
            v.dc.header(conv_integer(r.dc.index)).valid := '1';
            v.dc.header(conv_integer(r.dc.index)).tag := r.dc.tag;
            v.dc.bram_addr := r.dc.index & conv_std_logic_vector(r.fetch_n, 4);
            v.dc.bram_we := '1';
            v.dc.bram_tx := sram_out.rx;
            v.fetch_n := -1;

            if dc_need_flush(v) then
              v.state     := DC_FLUSH;
              v.sram_we   := '1';
              v.sram_tx   := dc_in.data;
              v.sram_addr := dc_in.addr;
            elsif ic_need_fetch(v) then
              v.state := IC_FETCH;
              v.sram_addr := v.ic.tag & "0000" & "00";
            else
              v.state := NO_OP;
            end if;
          when others =>
            assert false;
        end case;

      when DC_FLUSH =>
        case r.flush_n is
          when -1 =>
            v.flush_n := 0;
          when 0 =>
            v.dc.bram_addr := r.dc.index & r.dc.offset;
            v.dc.bram_we := '1';
            v.dc.bram_tx := sram_out.rx;
            v.flush_n := -1;

            if ic_need_fetch(v) then
              v.state := IC_FETCH;
              v.sram_addr := v.ic.tag & "0000" & "00";
            else
              v.state := NO_OP;
            end if;
          when others =>
            assert false;
        end case;

      when IC_FETCH =>
        case r.ifetch_n is
          when -1 =>
            v.sram_addr := r.sram_addr + 4;
            v.ifetch_n := 0;
          when 0 to 13 =>
            v.sram_addr := r.sram_addr + 4;
            v.ic.bram_addr := conv_std_logic_vector(r.ifetch_n, 4);
            v.ic.bram_we := '1';
            v.ic.bram_tx := sram_out.rx;
            v.ifetch_n := r.ifetch_n + 1;
          when 14 =>
            v.ic.bram_addr := conv_std_logic_vector(r.ifetch_n, 4);
            v.ic.bram_we := '1';
            v.ic.bram_tx := sram_out.rx;
            v.ifetch_n := 15;
          when 15 =>
            v.ic.header := r.ic.tag;
            v.ic.bram_addr := conv_std_logic_vector(r.ifetch_n, 4);
            v.ic.bram_we := '1';
            v.ic.bram_tx := sram_out.rx;
            v.ifetch_n := -1;

            v.state := NO_OP;
          when others =>
            assert false;
        end case;
      when others =>
        assert false;
    end case;

    -- control

    if v.state = IC_FETCH or ic_need_fetch(v) then
      v_ic_stall := '1';
    else
      v_ic_stall := '0';
    end if;

    if v.state = NO_OP or v.state = IC_FETCH then
      v_dc_stall := '0';
    else
      v_dc_stall := '1';
    end if;

    -- end

    rin <= v;

    dc_stall     <= v_dc_stall;
    ic_stall     <= v_ic_stall;
    dc_out.data  <= dc_bram_rx;
    ic_out.data  <= ic_bram_rx;
    sram_in.addr <= v.sram_addr;
    sram_in.tx   <= v.sram_tx;
    sram_in.we   <= v.sram_we;
    sram_in.re   <= '1';
    dc_bram_we   <= v.dc.bram_we;
    dc_bram_tx   <= v.dc.bram_tx;
    dc_bram_addr <= v.dc.bram_addr;
    ic_bram_we   <= v.ic.bram_we;
    ic_bram_tx   <= v.ic.bram_tx;
    ic_bram_addr <= v.ic.bram_addr;
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
