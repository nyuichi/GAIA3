library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.types.all;
use work.data.all;

entity ram is

  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    ram_in   : in  ram_in_type;
    ram_out  : out ram_out_type;
    sram_in  : out sram_in_type;
    sram_out : in  sram_out_type);

end entity;

architecture behavioral of ram is

  type state_type is (M1, M2);

  signal state, statein : state_type := M1;

begin

  ram_out.grnt1 <= '1' when state = M1 else '0';
  ram_out.grnt2 <= '1' when state = M2 else '0';

  ram_out.data1 <= sram_out.rx;
  ram_out.data2 <= sram_out.rx;

  sram_in.addr <= ram_in.addr1 when state = M1 else ram_in.addr2;
  sram_in.we   <= ram_in.we1   when state = M1 else ram_in.we2;
  sram_in.tx   <= ram_in.data1 when state = M1 else ram_in.data2;

  process(state, ram_in) is
    variable v : state_type;
  begin
    v := state;

    case state is
      when M1 =>
        if ram_in.req1 = '1' then
          v := M1;
        elsif ram_in.req2 = '1' then
          v := M2;
        end if;
      when M2 =>
        if ram_in.req2 = '1' then
          v := M2;
        elsif ram_in.req1 = '1' then
          v := M1;
        end if;
      when others =>
        assert false;
    end case;

    statein <= v;
  end process;

  process(clk, rst) is
  begin
    if rst = '1' then
      state <= M1;
    elsif rising_edge(clk) then
      state <= statein;
    end if;
  end process;

end architecture;
