library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity fmul is
  port (
    CLK : in  std_logic;
    stall : in std_logic;
    A   : in  std_logic_vector (31 downto 0);
    B   : in  std_logic_vector (31 downto 0);
    C   : out std_logic_vector (31 downto 0));
end entity fmul;

architecture behav of fmul is
  signal e : std_logic_vector (15 downto 0) := (others => '0');
  signal m : std_logic_vector (47 downto 0) := (others => '0');
  signal re : std_logic := '0';
  signal HH : std_logic_vector (25 downto 0) := (others => '0');
  signal HL : std_logic_vector (23 downto 0) := (others => '0');
  signal LH : std_logic_vector (23 downto 0) := (others => '0');
  signal exp01 : std_logic_vector (8 downto 0) := (others => '0');
  signal exp0 : std_logic_vector (7 downto 0) := (others => '0');
  signal exp1 : std_logic_vector (7 downto 0) := (others => '0');
  signal underflow_bit : std_logic := '0';
  signal m2 : std_logic_vector (25 downto 0) := (others => '0');
  signal state : std_logic_vector (1 downto 0) := (others => '0');
  signal sign_o : std_logic := '0';
  signal sign : std_logic_vector (2 downto 0) := (others => '0');
  signal exp : std_logic_vector (7 downto 0) := (others => '0');
  signal mantissa : std_logic_vector (25 downto 0) := (others => '0');
  signal m_out : std_logic_vector (22 downto 0) := (others => '0');

  signal sign_o2, sign_o3 : std_logic := '0';

  signal i_a : std_logic_vector (31 downto 0) := (others => '0');
  signal i_b : std_logic_vector (31 downto 0) := (others => '0');

  signal i_HH : std_logic_vector (25 downto 0) := (others => '0');
  signal i_HL : std_logic_vector (23 downto 0) := (others => '0');
  signal i_LH : std_logic_vector (23 downto 0) := (others => '0');
  signal i_exp : std_logic_vector (7 downto 0) := (others => '0');
  signal i_underflow_bit : std_logic := '0';

  signal i_m : std_logic_vector (25 downto 0) := (others => '0');
  signal i_exp0 : std_logic_vector (7 downto 0) := (others => '0');
  signal i_exp1 : std_logic_vector (7 downto 0) := (others => '0');
begin  -- architecture behav

  -- stage 1

  i_a <= A;
  i_b <= B;

  HH <= (others => '0') when i_a (30 downto 0) = "0000000000000000000000000000000"
        or i_b (30 downto 0) = "0000000000000000000000000000000" else
        ('1' & i_a (22 downto 11)) * ('1' & i_b (22 downto 11));
  HL <= ('1' & i_a (22 downto 11)) * (i_b (10 downto 0));
  LH <= (i_a (10 downto 0)) * ('1' & i_b (22 downto 11));
  exp01 <= (others => '0') when i_a (30 downto 0) = "0000000000000000000000000000000"
          or i_b (30 downto 0) = "0000000000000000000000000000000" else
          "000000000" + i_a (30 downto 23) + i_b (30 downto 23) + 129;
  sign_o <= i_a (31) xor i_b (31);

  process (CLK) is
  begin
    if rising_edge (CLK) and stall = '0' then
      i_HH <= HH;
      i_HL <= HL;
      i_LH <= LH;
      i_exp <= exp01(7 downto 0);
      i_underflow_bit <= exp01(8);
      sign_o2 <= sign_o;
    end if;
  end process;

  -- stage 2

  mantissa <= (others => '0') when i_HH = "00000000000000000000000000" else
              "00000000000000000000000000" + i_HH + i_HL (23 downto 11) + i_LH (23 downto 11) + 2;

  with i_underflow_bit select
    exp0 <=
    "00000000" when '0',
    i_exp      when '1',
    i_exp      when others;

  with i_underflow_bit select
    exp1 <=
    "00000001" when '0',
    i_exp + 1  when '1',
    i_exp + 1  when others;

  process (CLK) is
  begin  -- process set_loop
    if rising_edge (CLK) and stall = '0' then
      i_m <= mantissa;
      i_exp0 <= exp0;
      i_exp1 <= exp1;
      sign_o3 <= sign_o2;
    end if;
  end process;

  -- stage 3

  with i_m (25) select
    m_out <=
    i_m (23 downto 1) when '0',
    i_m (24 downto 2) when '1',
    i_m (24 downto 2) when others;

  with i_m (25) select
    exp <=
    i_exp1 when '1',
    i_exp0 when '0',
    i_exp0 when others;

  C <= sign_o3 & exp & m_out;

end architecture behav;
