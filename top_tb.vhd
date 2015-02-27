library IEEE;
use IEEE.std_logic_1164.all;

entity Top_tb is
end Top_tb;

architecture Behavioral of Top_tb is

  component Top is
    port (
      MCLK1 : in std_logic;
      XRST : in std_logic;
      RS_TX : out std_logic;
      RS_RX : in std_logic;
      ZD : inout std_logic_vector(31 downto 0);
      ZDP : inout std_logic_vector(3 downto 0);
      ZA : out std_logic_vector(19 downto 0);
      XE1 : out std_logic;
      E2A : out std_logic;
      XE3 : out std_logic;
      XZBE : out std_logic_vector(3 downto 0);
      XGA : out std_logic;
      XWA : out std_logic;
      XZCKE : out std_logic;
      ZCLKMA : out std_logic_vector(1 downto 0);
      ADVA : out std_logic;
      XFT : out std_logic;
      XLBO : out std_logic;
      ZZA : out std_logic);
  end component;

  component GS8160Z18 is
    generic (
      report_read : boolean := false;
      report_write : boolean := false);
    port (
      A : in std_logic_vector(19 downto 0); -- Address
      CK : in std_logic; -- Clock
      XBA : in std_logic; -- Write Byte A
      XBB : in std_logic; -- Write Byte B
      XW : in std_logic; -- Write Enable
      XE1 : in std_logic; -- Chip Enable
      E2 : in std_logic; -- Chip Enable
      XE3 : in std_logic; -- Chip Enable
      XG : in std_logic; -- Output Enable
      ADV : in std_logic; -- Burst Mode
      XCKE : in std_logic; -- Clock Enable
      DQA : inout std_logic_vector(7 downto 0); -- Data A
      DQB : inout std_logic_vector(7 downto 0); -- Data B
      DQPA : inout std_logic; -- Data Parity A
      DQPB : inout std_logic; -- Data Parity B
      ZZ : in std_logic := '0'; -- Sleep
      XFT : in std_logic := '1'; -- Flow Through Mode
      XLBO : in std_logic); -- Linear Byte Order
  end component;

  signal ZD : std_logic_vector(31 downto 0);
  signal ZDP : std_logic_vector(3 downto 0);
  signal ZA : std_logic_vector(19 downto 0);
  signal XE1 : std_logic;
  signal E2A : std_logic;
  signal XE3 : std_logic;
  signal XZBE : std_logic_vector(3 downto 0);
  signal XGA : std_logic;
  signal XWA : std_logic;
  signal XZCKE : std_logic;
  signal ZCLKMA : std_logic_vector(1 downto 0);
  signal ADVA : std_logic;
  signal XFT : std_logic;
  signal XLBO : std_logic;
  signal ZZA : std_logic;

  signal CLK : std_logic := '0';
  signal rs_tx, rs_rx : std_logic;

  signal XRST : std_logic := '1';

  -- global clock period
  constant CP: time := 15.15 ns;
  -- bit rate:
  --  1 / 9600bps   == 104166 ns
  --  1 / 115200bps == 8680 ns
  constant BR: time := 8680 ns;

begin

  sram_unit0 : GS8160Z18 generic map (report_write => false) port map (
    A => ZA,
    CK => ZCLKMA(0),
    XBA => XZBE(0),
    XBB => XZBE(1),
    XW => XWA,
    XE1 => XE1,
    E2 => E2A,
    XE3 => XE3,
    XG => XGA,
    ADV => ADVA,
    XCKE => XZCKE,
    DQA => ZD(7 downto 0),
    DQB => ZD(15 downto 8),
    DQPA => ZDP(0),
    DQPB => ZDP(1),
    ZZ => ZZA,
    XFT => XFT,
    XLBO => XLBO);

  sram_unit1 : GS8160Z18 generic map (report_write => false)  port map (
    A => ZA,
    CK => ZCLKMA(1),
    XBA => XZBE(2),
    XBB => XZBE(3),
    XW => XWA,
    XE1 => XE1,
    E2 => E2A,
    XE3 => XE3,
    XG => XGA,
    ADV => ADVA,
    XCKE => XZCKE,
    DQA => ZD(23 downto 16),
    DQB => ZD(31 downto 24),
    DQPA => ZDP(2),
    DQPB => ZDP(3),
    ZZ => ZZA,
    XFT => XFT,
    XLBO => XLBO);

  myTop : Top port map (
    MCLK1 => CLK,
    RS_TX => RS_TX,
    RS_RX => RS_RX,
    XRST => XRST,
    ZD => ZD,
    ZDP => ZDP,
    ZA => ZA,
    XE1 => XE1,
    E2A => E2A,
    XE3 => XE3,
    XZBE => XZBE,
    XGA => XGA,
    XWA => XWA,
    XZCKE => XZCKE,
    ZCLKMA => ZCLKMA,
    ADVA => ADVA,
    XFT => XFT,
    XLBO => XLBO,
    ZZA => ZZA);

  -- clock generator
  process
  begin
    CLK <= '0';
    wait for CP / 2;
    CLK <= '1';
    wait for CP / 2;
  end process;

  process
  begin

    RS_RX <= '1';

    wait for (5 * BR);

        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);


        wait for BR; RS_RX <= '0';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';
        wait for BR; RS_RX <= '1';

        wait for (2 * BR);

    wait for (100 * BR);

    assert false report "Simulation End." severity failure;
  end process;

end Behavioral;
