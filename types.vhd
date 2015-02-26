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

  constant cpu_in_zero : cpu_in_type := (
    i_stall => '0',
    i_data  => (others => '0'),
    d_stall => '0',
    d_data  => (others => '0'));

  type cpu_out_type is record
    i_re   : std_logic;
    i_addr : std_logic_vector(31 downto 0);
    d_re   : std_logic;
    d_we   : std_logic;
    d_data : std_logic_vector(31 downto 0);
    d_addr : std_logic_vector(31 downto 0);
  end record;

  constant cpu_out_zero : cpu_out_type := (
    i_re   => '1',
    i_addr => x"80000000",
    d_re   => '0',
    d_we   => '0',
    d_data => (others => '0'),
    d_addr => (others => '0'));

  component cpu is
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      cpu_in  : in  cpu_in_type;
      cpu_out : out cpu_out_type);
  end component;


  -- uart

  type uart_out_type is record
    rx : std_logic_vector(31 downto 0);
  end record;

  constant uart_out_zero : uart_out_type := (
    rx => (others => 'Z'));

  type uart_in_type is record
    we   : std_logic;
    re   : std_logic;
    val  : std_logic_vector(31 downto 0);
    addr : std_logic_vector(31 downto 0);
  end record;

  constant uart_in_zero : uart_in_type := (
    we   => '0',
    re   => '0',
    val  => (others => '0'),
    addr => (others => '0'));

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

  constant sram_out_zero : sram_out_type := (
    rx => (others => '0'));

  type sram_in_type is record
    addr : std_logic_vector(31 downto 0);
    we : std_logic;
    re : std_logic;
    tx : std_logic_vector(31 downto 0);
  end record;

  constant sram_in_zero : sram_in_type := (
    addr => (others => '0'),
    we   => '0',
    re   => '0',
    tx   => (others => '0'));

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

  constant cache_out_zero : cache_out_type := (
    stall  => '0',
    rx     => (others => 'Z'),
    stall2 => '0',
    rx2    => (others => 'Z'));

  type cache_in_type is record
    we    : std_logic;
    re    : std_logic;
    val   : std_logic_vector(31 downto 0);
    addr  : std_logic_vector(31 downto 0);
    re2   : std_logic;
    addr2 : std_logic_vector(31 downto 0);
  end record;

  constant cache_in_zero : cache_in_type := (
    we    => '0',
    re    => '0',
    val   => (others => '0'),
    addr  => (others => '0'),
    re2   => '0',
    addr2 => (others => '0'));

  component cache is
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      cache_in  : in  cache_in_type;
      cache_out : out cache_out_type;
      sram_out  : in  sram_out_type;
      sram_in   : out sram_in_type);
  end component;


  -- rom

  type rom_out_type is record
    rx  : std_logic_vector(31 downto 0);
    rx2 : std_logic_vector(31 downto 0);
  end record;

  constant rom_out_zero : rom_out_type := (
    rx => (others => 'Z'),
    rx2 => (others => 'Z'));

  type rom_in_type is record
    addr  : std_logic_vector(31 downto 0);
    addr2 : std_logic_vector(31 downto 0);
  end record;

  constant rom_in_zero : rom_in_type := (
    addr  => (others => '0'),
    addr2 => (others => '0'));

  type rom_type is
    array(0 to 4095) of std_logic_vector(31 downto 0);

  component rom is
    port (
      clk     : in  std_logic;
      rom_in  : in  rom_in_type;
      rom_out : out rom_out_type);
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


  -- constants

  constant OP_ALU      : std_logic_vector(3 downto 0) := "0000";
  constant OP_FPU      : std_logic_vector(3 downto 0) := "0001";
  constant OP_LDL      : std_logic_vector(3 downto 0) := "0010";
  constant OP_LDH      : std_logic_vector(3 downto 0) := "0011";
  constant OP_SYSENTER : std_logic_vector(3 downto 0) := "0100";
  constant OP_SYSEXIT  : std_logic_vector(3 downto 0) := "0101";
  constant OP_ST       : std_logic_vector(3 downto 0) := "0110";
  constant OP_LD       : std_logic_vector(3 downto 0) := "1000";
  constant OP_JL       : std_logic_vector(3 downto 0) := "1011";
  constant OP_JR       : std_logic_vector(3 downto 0) := "1100";
  constant OP_BNE      : std_logic_vector(3 downto 0) := "1101";
  constant OP_BEQ      : std_logic_vector(3 downto 0) := "1111";

  constant ALU_ADD    : std_logic_vector(4 downto 0) := "00000";
  constant ALU_SUB    : std_logic_vector(4 downto 0) := "00001";
  constant ALU_SHL    : std_logic_vector(4 downto 0) := "00010";
  constant ALU_SHR    : std_logic_vector(4 downto 0) := "00011";
  constant ALU_SAR    : std_logic_vector(4 downto 0) := "00100";
  constant ALU_AND    : std_logic_vector(4 downto 0) := "00101";
  constant ALU_OR     : std_logic_vector(4 downto 0) := "00110";
  constant ALU_XOR    : std_logic_vector(4 downto 0) := "00111";
  constant ALU_CMPNE  : std_logic_vector(4 downto 0) := "11000";
  constant ALU_CMPEQ  : std_logic_vector(4 downto 0) := "11001";
  constant ALU_CMPLT  : std_logic_vector(4 downto 0) := "11010";
  constant ALU_CMPLE  : std_logic_vector(4 downto 0) := "11011";
  constant ALU_FCMPNE : std_logic_vector(4 downto 0) := "11100";
  constant ALU_FCMPEQ : std_logic_vector(4 downto 0) := "11101";
  constant ALU_FCMPLT : std_logic_vector(4 downto 0) := "11110";
  constant ALU_FCMPLE : std_logic_vector(4 downto 0) := "11111";

end package;
