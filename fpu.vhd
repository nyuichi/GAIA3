library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.types.all;
use work.util.all;

entity fpu is

  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    fpu_in  : in  fpu_in_type;
    fpu_out : out fpu_out_type);

end entity;

architecture behavioral of fpu is

  type reg_type is record
    res  : std_logic_vector(31 downto 0);
    tag1 : std_logic_vector(4 downto 0);
    tag2 : std_logic_vector(4 downto 0);
  end record;

  constant rzero : reg_type := (
    res => (others => '0'),
    tag1 => (others => '0'),
    tag2 => (others => '0'));

  signal r, rin : reg_type := rzero;

  component fadd is
    port (
      CLK : in  std_logic;
      stall : in std_logic;
      A   : in  std_logic_vector (31 downto 0);
      B   : in  std_logic_vector (31 downto 0);
      C   : out std_logic_vector (31 downto 0));
  end component;

  component fsub is
    port (
      CLK : in  std_logic;
      stall : in std_logic;
      A   : in  std_logic_vector (31 downto 0);
      B   : in  std_logic_vector (31 downto 0);
      C   : out std_logic_vector (31 downto 0));
  end component;

  component fmul is
    port (
      CLK : in  std_logic;
      stall : in std_logic;
      A   : in  std_logic_vector (31 downto 0);
      B   : in  std_logic_vector (31 downto 0);
      C   : out std_logic_vector (31 downto 0));
  end component;

  component f2i is
    port (
      CLK   : in  std_logic;
      stall : in  std_logic;
      A     : in  std_logic_vector (31 downto 0);
      Q     : out std_logic_vector (31 downto 0));
  end component;

  component i2f is
    port (
      CLK   : in  std_logic;
      stall : in  std_logic;
      A     : in  std_logic_vector (31 downto 0);
      Q     : out std_logic_vector (31 downto 0));
  end component;

  component floor is
    port (
      CLK   : in  std_logic;
      stall : in  std_logic;
      A     : in  std_logic_vector (31 downto 0);
      Q     : out std_logic_vector (31 downto 0));
  end component;

  signal a : std_logic_vector(31 downto 0) := (others => '0');
  signal b : std_logic_vector(31 downto 0) := (others => '0');
  signal q_add : std_logic_vector(31 downto 0) := (others => '0');
  signal q_sub : std_logic_vector(31 downto 0) := (others => '0');
  signal q_mul : std_logic_vector(31 downto 0) := (others => '0');
  signal q_i2f : std_logic_vector(31 downto 0) := (others => '0');
  signal q_f2i : std_logic_vector(31 downto 0) := (others => '0');

begin

  fadd_1: entity work.fadd
    port map (
      CLK => CLK,
      stall => fpu_in.stall,
      A   => A,
      B   => B,
      C   => q_add);

  fsub_1: entity work.fsub
    port map (
      CLK => CLK,
      stall => fpu_in.stall,
      A   => A,
      B   => B,
      C   => q_sub);

  fmul_1: entity work.fmul
    port map (
      CLK => CLK,
      stall => fpu_in.stall,
      A   => A,
      B   => B,
      C   => q_mul);

  f2i_1: entity work.f2i
    port map (
      CLK => CLK,
      stall => fpu_in.stall,
      A   => A,
      Q   => q_f2i);

  i2f_1: entity work.i2f
    port map (
      CLK => CLK,
      stall => fpu_in.stall,
      A   => A,
      Q   => q_i2f);

  comb : process(r, fpu_in, q_add, q_sub, q_mul, q_f2i, q_i2f)
    variable v : reg_type;
  begin

    v := r;

    v.tag1 := fpu_in.optag;
    v.tag2 := r.tag1;

    case r.tag2 is
      when FPU_FADD =>
        v.res := q_add;
      when FPU_FSUB =>
        v.res := q_sub;
      when FPU_FMUL =>
        v.res := q_mul;
      when FPU_F2I =>
        v.res := q_f2i;
      when FPU_I2F =>
        v.res := q_i2f;
      when others =>
        v.res := (others => '0');
    end case;

    if fpu_in.stall = '1' then
      v := r;
    end if;

    rin <= v;

    a <= fpu_in.data_a;
    b <= fpu_in.data_b;
    fpu_out.res <= r.res;

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
