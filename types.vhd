library IEEE;
use IEEE.std_logic_1164.all;

package types is

  -- cpu

  type cpu_in_type is record
    i_stall : std_logic;
    i_data  : std_logic_vector(31 downto 0);
    d_stall : std_logic;
    d_data  : std_logic_vector(31 downto 0);
  end record;

  type cpu_out_type is record
    i_addr : std_logic_vector(31 downto 0);
    d_re   : std_logic;
    d_we   : std_logic;
    d_data : std_logic_vector(31 downto 0);
    d_addr : std_logic_vector(31 downto 0);
  end record;

  component cpu is
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      cpu_in  : in  cpu_in_type;
      cpu_out : out cpu_out_type);
  end component;


  -- icache (to be removed)

  type icache_out_type is record
    rx : std_logic_vector(31 downto 0);
  end record;

  type icache_in_type is record
    addr : std_logic_vector(31 downto 0);
  end record;

  component icache is
    port (
      clk        : in  std_logic;
      icache_in  : in  icache_in_type;
      icache_out : out icache_out_type);
  end component;


  -- uart

  type uart_out_type is record
    rx : std_logic_vector(31 downto 0);
  end record;

  type uart_in_type is record
    we   : std_logic;
    re   : std_logic;
    val  : std_logic_vector(31 downto 0);
    addr : std_logic_vector(31 downto 0);
  end record;

  component uart is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      uart_in  : in  uart_in_type;
      uart_out : out uart_out_type;
      RS_TX    : out std_logic;
      RS_RX    : in  std_logic);
  end component;


  -- sram

  type sram_out_type is record
    rx : std_logic_vector(31 downto 0);
  end record;

  type sram_in_type is record
    addr : std_logic_vector(31 downto 0);
    we : std_logic;
    re : std_logic;
    tx : std_logic_vector(31 downto 0);
  end record;

  component sram is
    port (
      clk      : in    std_logic;
      sram_in  : in    sram_in_type;
      sram_out : out   sram_out_type;
      ZD       : inout std_logic_vector(31 downto 0);
      ZDP      : inout std_logic_vector(3 downto 0);
      ZA       : out   std_logic_vector(19 downto 0);
      XWA      : out   std_logic);
  end component;


  -- cache

  type cache_out_type is record
    stall : std_logic;
    rx : std_logic_vector(31 downto 0);
    stall2 : std_logic;
    rx2 : std_logic_vector(31 downto 0);
  end record;

  type cache_in_type is record
    we   : std_logic;
    re   : std_logic;
    val  : std_logic_vector(31 downto 0);
    addr : std_logic_vector(31 downto 0);
    addr2 : std_logic_vector(31 downto 0);
  end record;

  component cache is
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      cache_in  : in  cache_in_type;
      cache_out : out cache_out_type;
      sram_out  : in  sram_out_type;
      sram_in   : out sram_in_type);
  end component;


  -- bram

  type bram_out_type is record
    rx  : std_logic_vector(31 downto 0);
    rx2 : std_logic_vector(31 downto 0);
  end record;

  type bram_in_type is record
    we    : std_logic;
    val   : std_logic_vector(31 downto 0);
    addr  : std_logic_vector(31 downto 0);
    addr2 : std_logic_vector(31 downto 0);
  end record;

  component bram is
    port (
      clk      : in  std_logic;
      bram_in  : in  bram_in_type;
      bram_out : out bram_out_type);
  end component;


  -- mux

  component mux is
    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      cpu_out    : in  cpu_out_type;
      cpu_in     : out cpu_in_type;
      icache_out : in  icache_out_type;
      icache_in  : out icache_in_type;
      cache_out  : in  cache_out_type;
      cache_in   : out cache_in_type;
      uart_out   : in  uart_out_type;
      uart_in    : out uart_in_type;
      bram_out   : in  bram_out_type;
      bram_in    : out bram_in_type);
  end component;


  -- util (to be moved)

  component blockram is
    generic (
      dwidth : integer;
      awidth : integer);
    port (
      clk  : in  std_logic;
      we   : in  std_logic;
      di   : in  std_logic_vector(dwidth - 1 downto 0);
      do   : out std_logic_vector(dwidth - 1 downto 0);
      addr : in  std_logic_vector(awidth - 1 downto 0));
  end component;

end package;
