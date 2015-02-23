library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.types.all;

entity uart is

  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    uart_in  : in  uart_in_type;
    uart_out : out uart_out_type;
    RS_TX    : out std_logic;
    RS_RX    : in  std_logic);

end entity;

architecture Behavioral of uart is

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
    ack : std_logic;

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

    -- reg
    prev : std_logic_vector(31 downto 0);
  end record;

  constant rzero : reg_type := (
    ack    => '0',
    tx_buf => (others => (others => '0')),
    tx_ptr => (others => '0'),
    tx_len => 0,
    rx_buf => (others => (others => '0')),
    rx_ptr => (others => '0'),
    rx_len => 0,
    re     => '0',
    we     => '1',
    prev   => (others => '0'));

  signal r, rin : reg_type := rzero;

begin

  rs232c_1 : rs232c port map (
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

  comb : process(r, uart_in, tx_busy, rx_ready, rx_dat)
    variable v : reg_type;

    variable v_din  : std_logic_vector(31 downto 0);
    variable v_dout : std_logic_vector(7 downto 0);
  begin
    v := r;

    if uart_in.addr = x"2000" then
      v.ack := '1';
    else
      v.ack := '0';
    end if;

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
    if v.ack = '1' and uart_in.we = '1' then
      if v.tx_len < 256 then
        v.tx_buf(conv_integer(v.tx_ptr + v.tx_len)) := uart_in.val(7 downto 0);
        v.tx_len := v.tx_len + 1;
      end if;
    end if;

    -- read
    if v.ack = '1' and uart_in.re = '1' then
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

    v.prev := v_din;

    rin <= v;

    tx_go <= v.we;
    rx_done <= v.re;
    tx_dat <= v_dout;
    if r.ack = '1' then
      uart_out.rx <= r.prev;
    else
      uart_out.rx <= (others => 'Z');
    end if;
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
