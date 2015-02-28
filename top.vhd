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

  signal cpu_in    : cpu_in_type    := cpu_in_zero;
  signal cpu_out   : cpu_out_type   := cpu_out_zero;
  signal cache_in  : cache_in_type  := cache_in_zero;
  signal cache_out : cache_out_type := cache_out_zero;
  signal uart_in   : uart_in_type   := uart_in_zero;
  signal uart_out  : uart_out_type  := uart_out_zero;
  signal sram_out  : sram_out_type  := sram_out_zero;
  signal sram_in   : sram_in_type   := sram_in_zero;
  signal rom_out   : rom_out_type   := rom_out_zero;
  signal rom_in    : rom_in_type    := rom_in_zero;
  signal timer_in  : timer_in_type  := timer_in_zero;
  signal timer_out : timer_out_type := timer_out_zero;

  signal count : natural := 0;

begin   -- architecture Behavioral

  ib: IBUFG port map (
    i => MCLK1,
    o => iclk);

  bg: BUFG port map (
    i => iclk,
    o => clk);

  rst <= (not XRST) when count > 100000 else '1';

  process(clk)
  begin
    if rising_edge(clk) then
      if count <= 100000 then
         count <= count + 1;
      end if;
    end if;
  end process;

  cpu_1: entity work.cpu
    port map (
      clk     => clk,
      rst     => rst,
      cpu_in  => cpu_in,
      cpu_out => cpu_out);

  cpu_in.d_stall <= cache_out.stall;
  cpu_in.d_data  <= cache_out.rx;
  cpu_in.d_data  <= uart_out.rx;
  cpu_in.d_data  <= rom_out.rx;
-- pragma synthesis_off
  cpu_in.d_data  <= (others => 'H');
-- pragma synthesis_on
  cpu_in.i_stall <= cache_out.stall2;
  cpu_in.i_data  <= cache_out.rx2;
  cpu_in.i_data  <= rom_out.rx2;
-- pragma synthesis_off
  cpu_in.i_data  <= (others => 'H');
-- pragma synthesis_on
  cpu_in.int_go  <= uart_out.int_go or timer_out.int_go;
  cpu_in.int_cause <= x"00000001" when timer_out.int_go = '1' else
                      x"00000002" when uart_out.int_go = '1' else
                      x"00000000";

  cache_in.b     <= cpu_out.d_b;
  cache_in.we    <= cpu_out.d_we;
  cache_in.re    <= cpu_out.d_re;
  cache_in.addr  <= cpu_out.d_addr;
  cache_in.val   <= cpu_out.d_data;
  cache_in.re2   <= cpu_out.i_re;
  cache_in.addr2 <= cpu_out.i_addr;

  uart_in.addr <= cpu_out.d_addr;
  uart_in.we   <= cpu_out.d_we;
  uart_in.re   <= cpu_out.d_re;
  uart_in.val  <= cpu_out.d_data;
  uart_in.eoi  <= cpu_out.eoi when cpu_out.eoi_id = x"00000002" else '0';

  rom_in.addr  <= cpu_out.d_addr;
  rom_in.addr2 <= cpu_out.i_addr;

  timer_in.eoi <= cpu_out.eoi when cpu_out.eoi_id = x"00000001" else '0';

  cache_1 : entity work.cache
    port map (
      clk       => clk,
      rst       => rst,
      cache_in  => cache_in,
      cache_out => cache_out,
      sram_out  => sram_out,
      sram_in   => sram_in);

  uart_1 : entity work.uart
    port map (
      clk      => clk,
      rst      => rst,
      uart_in  => uart_in,
      uart_out => uart_out,
      RS_TX    => RS_TX,
      RS_RX    => RS_RX);

  rom_1 : entity work.rom
    port map (
      clk     => clk,
      rom_in  => rom_in,
      rom_out => rom_out);

  sram_1 : entity work.sram
    port map (
      clk      => clk,
      sram_in  => sram_in,
      sram_out => sram_out,
      ZD       => ZD,
      ZDP      => ZDP,
      ZA       => ZA,
      XWA      => XWA);

  timer_1: entity work.timer
    port map (
      clk       => clk,
      rst       => rst,
      timer_in  => timer_in,
      timer_out => timer_out);

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
