library IEEE;
use IEEE.std_logic_1164.all;

entity io_tb is
end io_tb;

architecture Behavioral of io_tb is

  component io is
    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      re    : in  std_logic;
      we    : in  std_logic;
      dout  : in  std_logic_vector(31 downto 0);
      din   : out std_logic_vector(31 downto 0);
      RS_TX : out std_logic;
      RS_RX : in  std_logic);
  end component io;

  signal rst   : std_logic;
  signal re    : std_logic;
  signal we    : std_logic;
  signal dout  : std_logic_vector(31 downto 0);
  signal din   : std_logic_vector(31 downto 0);
  signal RS_TX : std_logic;
  signal RS_RX : std_logic;

  signal CLK : std_logic := '0';

  -- global clock period
  constant CP: time := 15.15 ns;
  -- bit rate (1 / 9600bps)
  constant BR: time := 104166 ns;

begin

  io_2: entity work.io
    port map (
      clk   => clk,
      rst   => rst,
      re    => re,
      we    => we,
      dout  => dout,
      din   => din,
      RS_TX => RS_TX,
      RS_RX => RS_RX);

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

    re <= '0';
    we <= '0';
    rst <= '1';

    wait for 10 us;

    rst <= '0';

    wait for 10 us;

    we <= '1';
    dout <= x"00000065";

    wait for CP;

    we <= '1';
    dout <= x"0000006B";

    wait for CP;

    we <= '0';

    wait for (16 * BR);

    wait for BR; RS_RX <= '0'; -- start-bit
    wait for BR; RS_RX <= '1'; -- data-bit 8'hc5
    wait for BR; RS_RX <= '0';
    wait for BR; RS_RX <= '1';
    wait for BR; RS_RX <= '0';
    wait for BR; RS_RX <= '0';
    wait for BR; RS_RX <= '0';
    wait for BR; RS_RX <= '1';
    wait for BR; RS_RX <= '1';
    wait for BR; RS_RX <= '1'; -- stop-bit

    wait for (2 * BR);

    wait for BR; RS_RX <= '0'; -- start-bit
    wait for BR; RS_RX <= '0'; -- data-bit 8'hf0
    wait for BR; RS_RX <= '0';
    wait for BR; RS_RX <= '0';
    wait for BR; RS_RX <= '0';
    wait for BR; RS_RX <= '1';
    wait for BR; RS_RX <= '1';
    wait for BR; RS_RX <= '1';
    wait for BR; RS_RX <= '1';
    wait for BR; RS_RX <= '1'; -- stop-bit

    wait for (16 * BR);

    for i in 0 to 1000 loop

      wait for i * CP;

      wait for BR; RS_RX <= '0'; -- start-bit
      wait for BR; RS_RX <= '1'; -- data-bit 8'hc5
      wait for BR; RS_RX <= '0';
      wait for BR; RS_RX <= '1';
      wait for BR; RS_RX <= '0';
      wait for BR; RS_RX <= '0';
      wait for BR; RS_RX <= '0';
      wait for BR; RS_RX <= '1';
      wait for BR; RS_RX <= '1';
      wait for BR; RS_RX <= '1'; -- stop-bit

    end loop;

    wait for (16 * BR);

    assert false report "Simulation End." severity failure;
  end process;

end Behavioral;

