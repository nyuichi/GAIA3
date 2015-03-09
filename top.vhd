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

  signal cpu_in     : cpu_in_type     := cpu_in_zero;
  signal cpu_out    : cpu_out_type    := cpu_out_zero;
  signal alu_in     : alu_in_type     := alu_in_zero;
  signal alu_out    : alu_out_type    := alu_out_zero;
  signal icache_in  : icache_in_type  := icache_in_zero;
  signal icache_out : icache_out_type := icache_out_zero;
  signal dcache_in  : dcache_in_type  := dcache_in_zero;
  signal dcache_out : dcache_out_type := dcache_out_zero;
  signal uart_in    : uart_in_type    := uart_in_zero;
  signal uart_out   : uart_out_type   := uart_out_zero;
  signal sram_out   : sram_out_type   := sram_out_zero;
  signal sram_in    : sram_in_type    := sram_in_zero;
  signal ram_out    : ram_out_type    := ram_out_zero;
  signal ram_in     : ram_in_type     := ram_in_zero;
  signal rom_out    : rom_out_type    := rom_out_zero;
  signal rom_in     : rom_in_type     := rom_in_zero;
  signal timer_in   : timer_in_type   := timer_in_zero;
  signal timer_out  : timer_out_type  := timer_out_zero;

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

  alu_in.optag   <= cpu_out.optag;
  alu_in.data_a  <= cpu_out.data_a;
  alu_in.data_b  <= cpu_out.data_b;
  alu_in.data_l  <= cpu_out.data_l;
  cpu_in.alu_res <= alu_out.res;

  cpu_in.d_stall <= dcache_out.stall;
  cpu_in.d_data  <= dcache_out.rx;
  cpu_in.d_data  <= uart_out.rx;
  cpu_in.d_data  <= rom_out.rx1;
-- pragma synthesis_off
  cpu_in.d_data  <= (others => 'H');
-- pragma synthesis_on

  cpu_in.i_stall <= icache_out.stall;
  cpu_in.i_data  <= icache_out.rx;
  cpu_in.i_data  <= rom_out.rx2;
-- pragma synthesis_off
  cpu_in.i_data  <= (others => 'H');
-- pragma synthesis_on

  cpu_in.int_go  <= uart_out.int_go or timer_out.int_go;
  cpu_in.int_cause <= x"00000001" when timer_out.int_go = '1' else
                      x"00000002" when uart_out.int_go = '1' else
                      x"00000000";

  dcache_in.cai    <= cpu_out.cai;
  dcache_in.b      <= cpu_out.d_b;
  dcache_in.we     <= cpu_out.d_we;
  dcache_in.re     <= cpu_out.d_re;
  dcache_in.addr   <= cpu_out.d_addr;
  dcache_in.val    <= cpu_out.d_data;
  dcache_in.vmm_en <= cpu_out.vmm_en;
  dcache_in.vmm_pd <= cpu_out.vmm_pd;

  icache_in.cai     <= cpu_out.cai;
  icache_in.co_we   <= cpu_out.d_we;
  icache_in.co_addr <= cpu_out.d_addr;
  icache_in.re      <= cpu_out.i_re;
  icache_in.addr    <= cpu_out.i_addr;
  icache_in.vmm_en  <= cpu_out.vmm_en;
  icache_in.vmm_pd  <= cpu_out.vmm_pd;

  uart_in.addr <= cpu_out.d_addr;
  uart_in.we   <= cpu_out.d_we;
  uart_in.re   <= cpu_out.d_re;
  uart_in.val  <= cpu_out.d_data;
  uart_in.eoi  <= cpu_out.eoi when cpu_out.eoi_id = x"00000002" else '0';

  rom_in.addr1 <= cpu_out.d_addr;
  rom_in.addr2 <= cpu_out.i_addr;

  timer_in.eoi <= cpu_out.eoi when cpu_out.eoi_id = x"00000001" else '0';

  alu_1: entity work.alu
    port map (
      clk     => clk,
      rst     => rst,
      alu_in  => alu_in,
      alu_out => alu_out);

  blockram_1 : entity work.blockram
    generic map (
      dwidth => 32,
      awidth => 12)
    port map (
      clk  => clk,
      we   => dcache_out.bram_we,
      di   => dcache_out.bram_di,
      do   => dcache_in.bram_do,
      addr => dcache_out.bram_addr);

  dcache_1 : entity work.dcache
    port map (
      clk        => clk,
      rst        => rst,
      dcache_in  => dcache_in,
      dcache_out => dcache_out);

  dcache_in.ram_grnt <= ram_out.grnt1;
  dcache_in.ram_data <= ram_out.data1;

  ram_in.req1  <= dcache_out.ram_req;
  ram_in.data1 <= dcache_out.ram_data;
  ram_in.addr1 <= dcache_out.ram_addr;
  ram_in.we1   <= dcache_out.ram_we;

  blockram_2: entity work.blockram
    generic map (
      dwidth => 32,
      awidth => 12)
    port map (
      clk  => clk,
      we   => icache_out.bram_we,
      di   => icache_out.bram_di,
      do   => icache_in.bram_do,
      addr => icache_out.bram_addr);

  icache_2 : entity work.icache
    port map (
      clk        => clk,
      rst        => rst,
      icache_in  => icache_in,
      icache_out => icache_out);

  icache_in.ram_grnt <= ram_out.grnt2;
  icache_in.ram_data <= ram_out.data2;

  ram_in.req2  <= icache_out.ram_req;
  ram_in.addr2 <= icache_out.ram_addr;

  ram_1: entity work.ram
    port map (
      clk      => clk,
      rst      => rst,
      ram_in   => ram_in,
      ram_out  => ram_out,
      sram_in  => sram_in,
      sram_out => sram_out);

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
