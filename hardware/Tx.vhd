library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity Tx is
  generic (
    wtime : std_logic_vector(15 downto 0) := x"1ADB");
  port (
    clk : in std_logic;
    tx_pin : out std_logic;
    go : in std_logic;
    busy : out std_logic;
    data : in std_logic_vector(7 downto 0));
end Tx;

architecture Behavioral of Tx is

  signal buf : std_logic_vector(8 downto 0) := (others => '1');
  signal count : std_logic_vector(15 downto 0) := wtime;
  signal state : integer range -1 to 9 := -1;

begin

  busy <= '1' when state /= -1 else '0';

  process(clk)
  begin
    if rising_edge(clk) then
      case state is
        when -1 =>
          if go = '1' then
            buf <= data & "0";
            count <= wtime;
            state <= 9;
          end if;
        when others =>
          if count = 0 then
            buf <= "1" & buf(8 downto 1);
            count <= wtime;
            state <= state - 1;
          else
            count <= count - 1;
          end if;
      end case;
    end if;
  end process;

  tx_pin <= buf(0);

end Behavioral;
