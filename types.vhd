library IEEE;
use IEEE.std_logic_1164.all;

package types is

  type imem_down_type is record
    re   : std_logic;
    addr : std_logic_vector(31 downto 0);
  end record;

  type imem_up_type is record
    data  : std_logic_vector(31 downto 0);
  end record;

  type dmem_down_type is record
    re   : std_logic;
    we   : std_logic;
    addr : std_logic_vector(31 downto 0);
    data : std_logic_vector(31 downto 0);
  end record;

  type dmem_up_type is record
    data  : std_logic_vector(31 downto 0);
  end record;

  constant imem_down_zero : imem_down_type;
  constant imem_up_zero   : imem_up_type;
  constant dmem_down_zero : dmem_down_type;
  constant dmem_up_zero   : dmem_up_type;

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

  constant uart_in_zero : uart_in_type;

  -- sram

  type sram_out_type is record
    rx : std_logic_vector(31 downto 0);
  end record;

  type sram_in_type is record
    addr : std_logic_vector(31 downto 0);
    we   : std_logic;
    re   : std_logic;
    tx   : std_logic_vector(31 downto 0);
  end record;

  component cpu is
    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      imem_stall : in  std_logic;
      imem_up    : in  imem_up_type;
      imem_down  : out imem_down_type;
      dmem_stall : in  std_logic;
      dmem_up    : in  dmem_up_type;
      dmem_down  : out dmem_down_type);
  end component;

  component mux is
    port (
      clk            : in  std_logic;
      rst            : in  std_logic;
      cpu_imem_down  : in  imem_down_type;
      cpu_imem_up    : out imem_up_type;
      cpu_imem_stall : out std_logic;
      cpu_dmem_down  : in  dmem_down_type;
      cpu_dmem_up    : out dmem_up_type;
      cpu_dmem_stall : out std_logic;
      uart_in        : out uart_in_type;
      uart_out       : in  uart_out_type;
      ic_in          : out imem_down_type;
      ic_out         : in  imem_up_type;
      ic_stall       : in  std_logic;
      dc_in          : out dmem_down_type;
      dc_out         : in  dmem_up_type;
      dc_stall       : in  std_logic;
      ib_in          : out imem_down_type;
      ib_out         : in  imem_up_type;
      db_in          : out dmem_down_type;
      db_out         : in  dmem_up_type);
  end component;

  component cache is
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
  end component;

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

  component uart is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      uart_in  : in  uart_in_type;
      uart_out : out uart_out_type;
      RS_TX    : out std_logic;
      RS_RX    : in  std_logic);
  end component;

  component bram is
    port (
      clk       : in  std_logic;
      imem_down : in  imem_down_type;
      imem_up   : out imem_up_type;
      dmem_down : in  dmem_down_type;
      dmem_up   : out dmem_up_type);
  end component;

  component blockram is
    generic (
      dwidth : integer;
      awidth : integer);
    port (
      clk   : in  std_logic;
      we    : in  std_logic;
      di    : in  std_logic_vector(dwidth - 1 downto 0);
      do    : out std_logic_vector(dwidth - 1 downto 0);
      addr  : in  std_logic_vector(awidth - 1 downto 0);
      do2   : out std_logic_vector(dwidth - 1 downto 0);
      addr2 : in  std_logic_vector(awidth - 1 downto 0) := (others => '0'));
  end component;

end package;

package body types is

  constant imem_down_zero : imem_down_type := (
    re   => '0',
    addr => (others => '0'));

  constant imem_up_zero   : imem_up_type := (
    data => (others => '0'));

  constant dmem_down_zero : dmem_down_type := (
    re   => '0',
    we   => '0',
    data => (others => '0'),
    addr => (others => '0'));

  constant dmem_up_zero   : dmem_up_type := (
    data => (others => '0'));

  constant uart_in_zero : uart_in_type := (
    re   => '0',
    we   => '0',
    val  => (others => '0'),
    addr => (others => '0'));

end package body;
