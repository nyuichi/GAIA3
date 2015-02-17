library IEEE;
use IEEE.std_logic_1164.all;

library UNISIM;
use UNISIM.VComponents.all;

use work.types.all;

entity top is

  port (
    MCLK1  : in    std_logic;
    XRST   : in    std_logic;
    RS_TX  : out   std_logic;
    RS_RX  : in    std_logic;
    ZD     : inout std_logic_vector(31 downto 0);
    ZDP    : inout std_logic_vector(3 downto 0);
    ZA     : out   std_logic_vector(19 downto 0);
    XE1    : out   std_logic;
    E2A    : out   std_logic;
    XE3    : out   std_logic;
    XZBE   : out   std_logic_vector(3 downto 0);
    XGA    : out   std_logic;
    XWA    : out   std_logic;
    XZCKE  : out   std_logic;
    ZCLKMA : out   std_logic_vector(1 downto 0);
    ADVA   : out   std_logic;
    XFT    : out   std_logic;
    XLBO   : out   std_logic;
    ZZA    : out   std_logic);

end entity;

architecture Behavioral of top is

  signal iclk, clk : std_logic := '0';

  signal rst : std_logic;

  signal cpu_imem_down  : imem_down_type;
  signal cpu_imem_up    : imem_up_type;
  signal cpu_imem_stall : std_logic;
  signal cpu_dmem_down  : dmem_down_type;
  signal cpu_dmem_up    : dmem_up_type;
  signal cpu_dmem_stall : std_logic;
  signal uart_in        : uart_in_type;
  signal uart_out       : uart_out_type;
  signal ic_in          : imem_down_type;
  signal ic_out         : imem_up_type;
  signal ic_stall       : std_logic;
  signal dc_in          : dmem_down_type;
  signal dc_out         : dmem_up_type;
  signal dc_stall       : std_logic;
  signal ib_in          : imem_down_type;
  signal ib_out         : imem_up_type;
  signal db_in          : dmem_down_type;
  signal db_out         : dmem_up_type;
  signal sram_out       : sram_out_type;
  signal sram_in        : sram_in_type;

begin  -- architecture Behavioral

  ib: IBUFG port map (
    i => MCLK1,
    o => iclk);

  bg: BUFG port map (
    i => iclk,
    o => clk);

  rst <= not XRST;

  cpu_1: entity work.cpu
    port map (
      clk        => clk,
      rst        => rst,
      imem_stall => cpu_imem_stall,
      imem_up    => cpu_imem_up,
      imem_down  => cpu_imem_down,
      dmem_stall => cpu_dmem_stall,
      dmem_up    => cpu_dmem_up,
      dmem_down  => cpu_dmem_down);

  mux_1: entity work.mux
    port map (
      clk            => clk,
      rst            => rst,
      cpu_imem_down  => cpu_imem_down,
      cpu_imem_up    => cpu_imem_up,
      cpu_imem_stall => cpu_imem_stall,
      cpu_dmem_down  => cpu_dmem_down,
      cpu_dmem_up    => cpu_dmem_up,
      cpu_dmem_stall => cpu_dmem_stall,
      uart_in        => uart_in,
      uart_out       => uart_out,
      ic_in          => ic_in,
      ic_out         => ic_out,
      ic_stall       => ic_stall,
      dc_in          => dc_in,
      dc_out         => dc_out,
      dc_stall       => dc_stall,
      ib_in          => ib_in,
      ib_out         => ib_out,
      db_in          => db_in,
      db_out         => db_out);

  cache_1: entity work.cache
    port map (
      clk      => clk,
      rst      => rst,
      dc_in    => dc_in,
      dc_out   => dc_out,
      dc_stall => dc_stall,
      ic_in    => ic_in,
      ic_out   => ic_out,
      ic_stall => ic_stall,
      sram_out => sram_out,
      sram_in  => sram_in);

  uart_1 : entity work.uart
    port map (
      clk      => clk,
      rst      => rst,
      uart_in  => uart_in,
      uart_out => uart_out,
      RS_TX    => RS_TX,
      RS_RX    => RS_RX);

  bram_1: entity work.bram
    port map (
      clk       => clk,
      imem_down => ib_in,
      imem_up   => ib_out,
      dmem_down => db_in,
      dmem_up   => db_out);

  sram_1 : entity work.sram
    port map (
      clk      => clk,
      sram_in  => sram_in,
      sram_out => sram_out,
      ZD       => ZD,
      ZDP      => ZDP,
      ZA       => ZA,
      XWA      => XWA);

  XE1       <= '0';
  E2A       <= '1';
  XE3       <= '0';
  XZBE      <= "0000";
  XGA       <= '0';
  XZCKE     <= '0';
  ZCLKMA(0) <= clk;
  ZCLKMA(1) <= clk;
  ADVA      <= '0';
  XFT       <= not '0';
  XLBO      <= '1';
  ZZA       <= '0';

end architecture;
