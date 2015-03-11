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

  component f2i is
    port (
      A : in  std_logic_vector (31 downto 0);
      Q : out std_logic_vector (31 downto 0));
  end component;

  component i2f is
    port (
      A : in  std_logic_vector (31 downto 0);
      Q : out std_logic_vector (31 downto 0));
  end component;

  signal a : std_logic_vector(31 downto 0) := (others => '0');
  signal q_i2f, q_f2i : std_logic_vector(31 downto 0) := (others => '0');

begin

  i2f_1: entity work.i2f
    port map (
      A => A,
      Q => Q_i2f);

  f2i_1: entity work.f2i
    port map (
      A => A,
      Q => Q_f2i);

  comb : process(r, alu_in)

    variable v : reg_type;

    variable data_a  : std_logic_vector(31 downto 0);
    variable data_b : std_logic_vector(31 downto 0);

  begin

    v := r;

    data_a := alu_in.data_a;
    data_b := std_logic_vector(signed(alu_in.data_b) + signed(alu_in.data_l(7 downto 0)));

    case alu_in.optag is
      when ALU_ADD =>
        v.res := data_a + data_b;
      when ALU_SUB =>
        v.res := data_a - data_b;
      when ALU_SHL =>
        v.res := std_logic_vector(shift_left(unsigned(data_a), conv_integer(data_b(4 downto 0))));
      when ALU_SHR =>
        v.res := std_logic_vector(shift_right(unsigned(data_a), conv_integer(data_b(4 downto 0))));
      when ALU_SAR =>
        v.res := std_logic_vector(shift_right(signed(data_a), conv_integer(data_b(4 downto 0))));
      when ALU_AND =>
        v.res := data_a and data_b;
      when ALU_OR =>
        v.res := data_a or data_b;
      when ALU_XOR =>
        v.res := data_a xor data_b;
      when ALU_F2I =>
        v.res := q_f2i;
      when ALU_I2F =>
        v.res := q_i2f;
      when ALU_CMPULT =>
        v.res := repeat('0', 31) & to_std_logic(data_a < data_b);
      when ALU_CMPULE =>
        v.res := repeat('0', 31) & to_std_logic(data_a <= data_b);
      when ALU_CMPNE =>
        v.res := repeat('0', 31) & to_std_logic(data_a /= data_b);
      when ALU_CMPEQ =>
        v.res := repeat('0', 31) & to_std_logic(data_a = data_b);
      when ALU_CMPLT =>
        v.res := repeat('0', 31) & to_std_logic(signed(data_a) < signed(data_b));
      when ALU_CMPLE =>
        v.res := repeat('0', 31) & to_std_logic(signed(data_a) <= signed(data_b));
      when ALU_FCMPNE =>
        v.res := repeat('0', 31) & to_std_logic(data_a /= data_b);
      when ALU_FCMPEQ =>
        v.res := repeat('0', 31) & to_std_logic(data_a = data_b);
      when ALU_FCMPLT =>
        if data_a(31) = '1' or data_b(31) = '1' then
          v.res := repeat('0', 31) & to_std_logic(data_a >= data_b);
        else
          v.res := repeat('0', 31) & to_std_logic(data_a < data_b);
        end if;
      when ALU_FCMPLE =>
        if data_a(31) = '1' or data_b(31) = '1' then
          v.res := repeat('0', 31) & to_std_logic(data_a > data_b);
        else
          v.res := repeat('0', 31) & to_std_logic(data_a <= data_b);
        end if;
      when others =>
        v.res := (others => '0');
    end case;

    rin <= v;

    a <= data_a;
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
