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
    res : std_logic_vector(31 downto 0);
  end record;

  constant rzero : reg_type := (
    res => (others => '0'));

  signal r, rin : reg_type := rzero;

  component fadd is
    port (
      CLK : in  std_logic;
      A   : in  std_logic_vector (31 downto 0);
      B   : in  std_logic_vector (31 downto 0);
      C   : out std_logic_vector (31 downto 0));
  end component;

  component fsub is
    port (
      CLK : in  std_logic;
      A   : in  std_logic_vector (31 downto 0);
      B   : in  std_logic_vector (31 downto 0);
      C   : out std_logic_vector (31 downto 0));
  end component;

  component fmul is
    port (
      CLK : in  std_logic;
      A   : in  std_logic_vector (31 downto 0);
      B   : in  std_logic_vector (31 downto 0);
      C   : out std_logic_vector (31 downto 0));
  end component;

  signal a, b : std_logic_vector(31 downto 0) := (others => '0');
  signal q_add, q_sub, q_mul : std_logic_vector(31 downto 0) := (others => '0');

begin

  fadd_1: entity work.fadd
    port map (
      CLK => CLK,
      A   => A,
      B   => B,
      C   => q_add);

  fsub_1: entity work.fsub
    port map (
      CLK => CLK,
      A   => A,
      B   => B,
      C   => q_sub);

  fmul_1: entity work.fmul
    port map (
      CLK => CLK,
      A   => A,
      B   => B,
      C   => q_mul);


  comb : process(r, fpu_in, q_add, q_sub, q_mul)

    variable v : reg_type;

    variable res : std_logic_vector(31 downto 0);

  begin

    v := r;

    case fpu_in.optag is
      when FPU_FADD =>
        v.res := q_add;
      when FPU_FSUB =>
        v.res := q_sub;
      when FPU_FMUL =>
        v.res := q_mul;
      when others =>
        v.res := (others => '0');
    end case;

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
