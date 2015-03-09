library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.types.all;
use work.util.all;

entity alu is

  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    alu_in  : in  alu_in_type;
    alu_out : out alu_out_type);

end entity;

architecture behavioral of alu is

  type reg_type is record
    res : std_logic_vector(31 downto 0);
  end record;

  constant rzero : reg_type := (
    res => (others => '0'));

  signal r, rin : reg_type := rzero;

begin

  comb : process(r, alu_in)

    variable v : reg_type;

    variable optag   : std_logic_vector(4 downto 0);
    variable data_a  : std_logic_vector(31 downto 0);
    variable data_b  : std_logic_vector(31 downto 0);
    variable data_l  : std_logic_vector(31 downto 0);

    variable data_bl : std_logic_vector(31 downto 0);
    variable data_na : std_logic_vector(31 downto 0);
    variable data_nb : std_logic_vector(31 downto 0);

  begin

    v := r;

    optag := alu_in.optag;
    data_a := alu_in.data_a;
    data_b := alu_in.data_b;
    data_l := alu_in.data_l;

    data_bl := std_logic_vector(signed(data_b) + signed(data_l(7 downto 0)));

    case optag is
      when ALU_ADD =>
        v.res := data_a + data_bl;
      when ALU_SUB =>
        v.res := data_a - data_bl;
      when ALU_SHL =>
        v.res := std_logic_vector(shift_left(unsigned(data_a), conv_integer(data_bl)));
      when ALU_SHR =>
        v.res := std_logic_vector(shift_right(unsigned(data_a), conv_integer(data_bl)));
      when ALU_SAR =>
        v.res := std_logic_vector(shift_right(signed(data_a), conv_integer(data_bl)));
      when ALU_AND =>
        v.res := data_a and data_b and data_l;
      when ALU_OR =>
        v.res := data_a or data_b or data_l;
      when ALU_XOR =>
        v.res := data_a xor data_b xor data_l;
      when ALU_CMPULT =>
        v.res := repeat('0', 31) & to_std_logic(data_a < data_bl);
      when ALU_CMPULE =>
        v.res := repeat('0', 31) & to_std_logic(data_a <= data_bl);
      when ALU_CMPNE =>
        v.res := repeat('0', 31) & to_std_logic(data_a /= data_bl);
      when ALU_CMPEQ =>
        v.res := repeat('0', 31) & to_std_logic(data_a = data_bl);
      when ALU_CMPLT =>
        v.res := repeat('0', 31) & to_std_logic(signed(data_a) < signed(data_bl));
      when ALU_CMPLE =>
        v.res := repeat('0', 31) & to_std_logic(signed(data_a) <= signed(data_bl));
      when ALU_FCMPNE =>
        data_na := normalize_fzero(data_a);
        data_nb := normalize_fzero(data_b);
        v.res := repeat('0', 31) & to_std_logic(data_na /= data_nb);
      when ALU_FCMPEQ =>
        data_na := normalize_fzero(data_a);
        data_nb := normalize_fzero(data_b);
        v.res := repeat('0', 31) & to_std_logic(data_na = data_nb);
      when ALU_FCMPLT =>
        data_na := normalize_fzero(data_a);
        data_nb := normalize_fzero(data_b);
        if data_na(31) = '1' or data_nb(31) = '1' then
          v.res := repeat('0', 31) & to_std_logic(data_na >= data_nb);
        else
          v.res := repeat('0', 31) & to_std_logic(data_na < data_nb);
        end if;
      when ALU_FCMPLE =>
        data_na := normalize_fzero(data_a);
        data_nb := normalize_fzero(data_b);
        if data_na(31) = '1' or data_nb(31) = '1' then
          v.res := repeat('0', 31) & to_std_logic(data_na > data_nb);
        else
          v.res := repeat('0', 31) & to_std_logic(data_na <= data_nb);
        end if;
      when others =>
        v.res := (others => '0');
    end case;

    rin <= v;

    alu_out.res <= r.res;

  end process;

  regs : process(clk, rst)
  begin
    if rst = '1' then
      r <= rzero;
    elsif rising_edge(clk) then
      r <= rin;
    end if;
  end process;

end architecture;
