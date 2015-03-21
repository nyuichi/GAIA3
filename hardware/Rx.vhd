library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
use STD.textio.all;

entity Rx is
  generic (
    wtime : std_logic_vector(15 downto 0) := x"1ADB");
  port (
    clk : in std_logic;
    rx_pin : in std_logic;
    done : in std_logic;
    data : out std_logic_vector(7 downto 0);
    ready : out std_logic);
end Rx;


--pragma synthesis_off
architecture Simulation of Rx is
  constant input_filename : string := "/home/yuichi/workspace/gaia-software/a.out";
  shared variable start : boolean := false;
begin
  process
  begin
    wait for 2 ms;
    start := true;
  end process;

  process(clk) is
    variable c : character;
    type ft is file of character;
    file input_file : ft open READ_MODE is input_filename;
    file stdout : ft open WRITE_MODE is "STD_OUTPUT";
    variable go : boolean := true;
  begin
    if rising_edge(clk) and start then
      if not endfile(input_file) and go then
        read(input_file, c);
        data <= std_logic_vector(to_unsigned(character'pos(c), 8));
        ready <= '1';
        go := false;
      elsif not go and done = '1' then
        ready <= '0';
        go := true;
      end if;
    end if;
  end process;
end architecture;
--pragma synthesis_on

architecture Behavioral of Rx is

  signal buf : std_logic_vector(8 downto 0) := (others => '0');
  signal count : std_logic_vector(15 downto 0) := "0" & wtime(15 downto 1);
  signal state : integer range -1 to 9 := -1;

begin

  process(clk) is
  begin
    if rising_edge(clk) then
      if done = '1' then
        ready <= '0';
      end if;

      case state is
        when -1 =>
          if rx_pin = '0' then
            if count = 0 then
              count <= wtime;
              state <= 9;
            else
              count <= count - 1;
            end if;
          end if;
        when 0 =>
          if count = "0" & wtime(15 downto 1) then
            count <= count - 1;
            state <= -1;
            ready <= '1';
          else
            count <= count - 1;
          end if;
        when others =>
          if count = 0 then
            buf <= rx_pin & buf(8 downto 1);
            count <= wtime;
            state <= state - 1;
          else
            count <= count - 1;
          end if;
      end case;
    end if;
  end process;

  data <= buf(7 downto 0);

end Behavioral;
