library IEEE;
use IEEE.std_logic_1164.all;

entity rs232c is
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
end entity;

architecture Behavioral of rs232c is

  -- 9600 bps: 1ADB
  -- 115200 bps: 023D
  -- 230400 bps: 011E

  constant wtime : std_logic_vector(15 downto 0) := x"011E";

  component Rx is
    generic (
      wtime : std_logic_vector(15 downto 0));
    port (
      clk    : in  std_logic;
      rx_pin : in  std_logic;
      done   : in  std_logic;
      data   : out std_logic_vector(7 downto 0);
      ready  : out std_logic);
  end component;

  component Tx is
    generic (
      wtime : std_logic_vector(15 downto 0));
    port (
      clk    : in  std_logic;
      tx_pin : out std_logic;
      go     : in  std_logic;
      busy   : out std_logic;
      data   : in  std_logic_vector(7 downto 0));
  end component;

begin

  myRx: entity work.Rx
    generic map (
      wtime => wtime)
    port map (
      clk    => clk,
      rx_pin => rx_pin,
      done   => rx_done,
      data   => rx_data,
      ready  => rx_ready);

  myTx: entity work.Tx
    generic map (
      wtime => wtime)
    port map (
      clk    => clk,
      tx_pin => tx_pin,
      go     => tx_go,
      busy   => tx_busy,
      data   => tx_data);

end architecture;
