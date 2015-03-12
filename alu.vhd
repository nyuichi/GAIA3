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

    variable a : std_logic_vector(31 downto 0);
    variable b : std_logic_vector(31 downto 0);

  begin

    v := r;

    a := alu_in.data_a;
    b := std_logic_vector(signed(alu_in.data_b) + signed(alu_in.data_l));

    case alu_in.optag is
      when ALU_ADD =>
        v.res := a + b;
      when ALU_SUB =>
        v.res := a - b;
      when ALU_SHL =>
        v.res := std_logic_vector(shift_left(unsigned(a), conv_integer(b(4 downto 0))));
      when ALU_SHR =>
        v.res := std_logic_vector(shift_right(unsigned(a), conv_integer(b(4 downto 0))));
      when ALU_SAR =>
        v.res := std_logic_vector(shift_right(signed(a), conv_integer(b(4 downto 0))));
      when ALU_AND =>
        v.res := a and b;
      when ALU_OR =>
        v.res := a or b;
      when ALU_XOR =>
        v.res := a xor b;
      when ALU_CMPULT =>
        v.res := repeat('0', 31) & to_std_logic(a < b);
      when ALU_CMPULE =>
        v.res := repeat('0', 31) & to_std_logic(a <= b);
      when ALU_CMPNE =>
        v.res := repeat('0', 31) & to_std_logic(a /= b);
      when ALU_CMPEQ =>
        v.res := repeat('0', 31) & to_std_logic(a = b);
      when ALU_CMPLT =>
        v.res := repeat('0', 31) & to_std_logic(signed(a) < signed(b));
      when ALU_CMPLE =>
        v.res := repeat('0', 31) & to_std_logic(signed(a) <= signed(b));
      when ALU_FCMPNE =>
        v.res := repeat('0', 31) & to_std_logic(a /= b);
      when ALU_FCMPEQ =>
        v.res := repeat('0', 31) & to_std_logic(a = b);
      when ALU_FCMPLT =>
        if a(31) = '1' or b(31) = '1' then
          v.res := repeat('0', 31) & to_std_logic(a >= b);
        else
          v.res := repeat('0', 31) & to_std_logic(a < b);
        end if;
      when ALU_FCMPLE =>
        if a(31) = '1' or b(31) = '1' then
          v.res := repeat('0', 31) & to_std_logic(a > b);
        else
          v.res := repeat('0', 31) & to_std_logic(a <= b);
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
