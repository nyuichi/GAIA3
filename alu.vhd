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
    tag      : std_logic_vector(4 downto 0);
    res      : std_logic_vector(31 downto 0);
    q_add    : std_logic_vector(31 downto 0);
    q_sub    : std_logic_vector(31 downto 0);
    q_shl    : std_logic_vector(31 downto 0);
    q_shr    : std_logic_vector(31 downto 0);
    q_sar    : std_logic_vector(31 downto 0);
    q_and    : std_logic_vector(31 downto 0);
    q_or     : std_logic_vector(31 downto 0);
    q_xor    : std_logic_vector(31 downto 0);
    q_cmpult : std_logic_vector(31 downto 0);
    q_cmpule : std_logic_vector(31 downto 0);
    q_cmpne  : std_logic_vector(31 downto 0);
    q_cmpeq  : std_logic_vector(31 downto 0);
    q_cmplt  : std_logic_vector(31 downto 0);
    q_cmple  : std_logic_vector(31 downto 0);
    q_fcmplt : std_logic_vector(31 downto 0);
    q_fcmple : std_logic_vector(31 downto 0);
  end record;

  constant rzero : reg_type := (
    tag => (others => '0'),
    res => (others => '0'),
    others => (others => '0'));

  signal r, rin : reg_type := rzero;

  component f2i is
    port (
      clk : in std_logic;
      A : in  std_logic_vector (31 downto 0);
      Q : out std_logic_vector (31 downto 0));
  end component;

  component i2f is
    port (
      clk : in std_logic;
      A : in  std_logic_vector (31 downto 0);
      Q : out std_logic_vector (31 downto 0));
  end component;

  signal a : std_logic_vector(31 downto 0) := (others => '0');
  signal q_i2f, q_f2i : std_logic_vector(31 downto 0) := (others => '0');

begin

  i2f_1: entity work.i2f
    port map (
      clk => clk,
      A => A,
      Q => Q_i2f);

  f2i_1: entity work.f2i
    port map (
      clk => clk,
      A => A,
      Q => Q_f2i);

  comb : process(r, alu_in)

    variable v : reg_type;

    variable data_a : std_logic_vector(31 downto 0);
    variable data_b : std_logic_vector(31 downto 0);

  begin

    v := r;

    v.tag := alu_in.optag;

    data_a := alu_in.data_a;
    data_b := std_logic_vector(signed(alu_in.data_b) + signed(alu_in.data_l(7 downto 0)));

    v.q_add    := data_a + data_b;
    v.q_sub    := data_a - data_b;
    v.q_shl    := std_logic_vector(shift_left(unsigned(data_a), conv_integer(data_b(4 downto 0))));
    v.q_shr    := std_logic_vector(shift_right(unsigned(data_a), conv_integer(data_b(4 downto 0))));
    v.q_sar    := std_logic_vector(shift_right(signed(data_a), conv_integer(data_b(4 downto 0))));
    v.q_and    := data_a and data_b;
    v.q_or     := data_a or data_b;
    v.q_xor    := data_a xor data_b;
    v.q_cmpult := repeat('0', 31) & to_std_logic(data_a < data_b);
    v.q_cmpule := repeat('0', 31) & to_std_logic(data_a <= data_b);
    v.q_cmpne  := repeat('0', 31) & to_std_logic(data_a /= data_b);
    v.q_cmpeq  := repeat('0', 31) & to_std_logic(data_a = data_b);
    v.q_cmplt  := repeat('0', 31) & to_std_logic(signed(data_a) < signed(data_b));
    v.q_cmple  := repeat('0', 31) & to_std_logic(signed(data_a) <= signed(data_b));

    if data_a(31) = '1' or data_b(31) = '1' then
      v.q_fcmplt := repeat('0', 31) & to_std_logic(data_a >= data_b);
    else
      v.q_fcmplt := repeat('0', 31) & to_std_logic(data_a < data_b);
    end if;
    if data_a(31) = '1' or data_b(31) = '1' then
      v.q_fcmple := repeat('0', 31) & to_std_logic(data_a > data_b);
    else
      v.q_fcmple := repeat('0', 31) & to_std_logic(data_a <= data_b);
    end if;

    rin <= v;

    a <= data_a;

    case r.tag is
      when ALU_ADD =>
        alu_out.res <= r.q_add;
      when ALU_SUB =>
        alu_out.res <= r.q_sub;
      when ALU_SHL =>
        alu_out.res <= r.q_shl;
      when ALU_SHR =>
        alu_out.res <= r.q_shr;
      when ALU_SAR =>
        alu_out.res <= r.q_sar;
      when ALU_AND =>
        alu_out.res <= r.q_and;
      when ALU_OR =>
        alu_out.res <= r.q_or;
      when ALU_XOR =>
        alu_out.res <= r.q_xor;
      when ALU_CMPULT =>
        alu_out.res <= r.q_cmpult;
      when ALU_CMPULE =>
        alu_out.res <= r.q_cmpule;
      when ALU_CMPNE =>
        alu_out.res <= r.q_cmpne;
      when ALU_CMPEQ =>
        alu_out.res <= r.q_cmpeq;
      when ALU_CMPLT =>
        alu_out.res <= r.q_cmplt;
      when ALU_CMPLE =>
        alu_out.res <= r.q_cmple;
      when ALU_F2I =>
        alu_out.res <= q_f2i;
      when ALU_I2F =>
        alu_out.res <= q_i2f;
      when ALU_FCMPLT =>
        alu_out.res <= r.q_fcmplt;
      when ALU_FCMPLE =>
        alu_out.res <= r.q_fcmple;
      when others =>
        alu_out.res <= (others => '0');
    end case;

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
