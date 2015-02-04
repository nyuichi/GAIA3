library IEEE;
use IEEE.std_logic_1164.all;

package types is

  type cpu_out_type is record
    we   : std_logic;
    re   : std_logic;
    val  : std_logic_vector(31 downto 0);
    addr : std_logic_vector(31 downto 0);
  end record;

  type cache_out_type is record
    stall : std_logic;
    rx : std_logic_vector(31 downto 0);
  end record;

  type icache_out_type is record
    rx : std_logic_vector(31 downto 0);
  end record;

  type icache_in_type is record
    addr : std_logic_vector(31 downto 0);
  end record;

  type mem_out_type is record
    rx : std_logic_vector(31 downto 0);
  end record;

  type mem_in_type is record
    addr : std_logic_vector(31 downto 0);
    we : std_logic;
    re : std_logic;
    tx : std_logic_vector(31 downto 0);
  end record;

  component cpu is
    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      icache_out : in  icache_out_type;
      icache_in  : out icache_in_type;
      cache_out  : in  cache_out_type;
      cpu_out    : out cpu_out_type);
  end component cpu;

  component cache is
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      cpu_out   : in  cpu_out_type;
      cache_out : out cache_out_type;
      mem_out   : in  mem_out_type;
      mem_in    : out mem_in_type);
  end component cache;

  component icache is
    port (
      clk        : in  std_logic;
      icache_in  : in  icache_in_type;
      icache_out : out icache_out_type);
  end component icache;

  component mem is
    port (
      clk     : in    std_logic;
      mem_in  : in    mem_in_type;
      mem_out : out   mem_out_type;
      ZD      : inout std_logic_vector(31 downto 0);
      ZDP     : inout std_logic_vector(3 downto 0);
      ZA      : out   std_logic_vector(19 downto 0);
      XWA     : out   std_logic);
  end component mem;

end package;
