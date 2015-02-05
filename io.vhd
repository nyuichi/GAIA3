library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity io is

  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    re    : in  std_logic;
    we    : in  std_logic;
    dout  : in  std_logic_vector(31 downto 0);
    din   : out std_logic_vector(31 downto 0);
    RS_TX : out std_logic;
    RS_RX : in  std_logic);

end entity;

architecture Behavioral of io is

  component rs232c is
    port (
      clk      : in  std_logic;
      tx_pin   : out std_logic;
      rx_pin   : in  std_logic;
      tx_go    : in  std_logic;
      tx_busy  : out std_logic;
      tx_data  : in  std_logic_vector(7 downto 0);
      rx_done  : in  std_logic;
      rx_ready : out std_logic;
      rx_data  : out std_logic_vector(7 downto 0));
  end component;

  signal tx_go    : std_logic                    := '0';
  signal tx_busy  : std_logic                    := '0';
  signal tx_dat   : std_logic_vector(7 downto 0) := (others => '0');
  signal rx_done  : std_logic                    := '0';
  signal rx_ready : std_logic                    := '0';
  signal rx_dat   : std_logic_vector(7 downto 0) := (others => '0');

  type buf_t is
    array(0 to 255) of std_logic_vector(7 downto 0);

  type reg_type is record
    -- buffer
    tx_buf : buf_t;
    tx_ptr : std_logic_vector(7 downto 0);
    tx_len : integer range 0 to 256;
    rx_buf : buf_t;
    rx_ptr : std_logic_vector(7 downto 0);
    rx_len : integer range 0 to 256;

    -- pins
    re : std_logic;
    we : std_logic;
  end record;

  constant rzero : reg_type := (
    tx_buf => (others => (others => '0')),
    tx_ptr => (others => '0'),
    tx_len => 0,
    rx_buf => (others => (others => '0')),
    rx_ptr => (others => '0'),
    rx_len => 0,
    re     => '0',
    we     => '1');

  signal r, rin : reg_type;

begin

  myRS232C : RS232C port map (
    clk      => clk,
    tx_pin   => RS_TX,
    rx_pin   => RS_RX,
    tx_go    => tx_go,
    tx_busy  => tx_busy,
    tx_data  => tx_dat,
    rx_done  => rx_done,
    rx_ready => rx_ready,
    rx_data  => rx_dat);

  -- WRITE

  comb : process(r, rst, re, we, dout, tx_busy, rx_ready, rx_dat)
    variable v : reg_type;

    variable v_din  : std_logic_vector(31 downto 0);
    variable v_dout : std_logic_vector(7 downto 0);
  begin
    v := r;

    v_din := x"FFFFFFFF";
    v_dout := x"00";

    -- fill buf
    if rx_ready = '1' and v.re = '0' and v.rx_len < 256 then
      v.rx_buf(conv_integer(v.rx_ptr + v.rx_len)) := rx_dat;
      v.rx_len := v.rx_len + 1;
      v.re := '1';
    else
      v.re := '0';
    end if;

    -- write
    if we = '1' then
      if v.tx_len < 256 then
        v.tx_buf(conv_integer(v.tx_ptr + v.tx_len)) := dout(7 downto 0);
        v.tx_len := v.tx_len + 1;
      end if;
    end if;

    -- read
    if re = '1' then
      if v.rx_len > 0 then
        v_din := x"000000" & v.rx_buf(conv_integer(v.rx_ptr));
        v.rx_ptr := v.rx_ptr + 1;
        v.rx_len := v.rx_len - 1;
      end if;
    end if;

    -- flush buf
    if tx_busy = '0' and v.we = '0' and v.tx_len > 0 then
      v_dout := v.tx_buf(conv_integer(v.tx_ptr));
      v.tx_ptr := v.tx_ptr + 1;
      v.tx_len := v.tx_len - 1;
      v.we := '1';
    else
      v.we := '0';
    end if;

    rin <= v;

    tx_go <= v.we;
    rx_done <= v.re;
    tx_dat <= v_dout;
    din <= v_din;
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
