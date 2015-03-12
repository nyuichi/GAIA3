library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity fadd is
  port (
    CLK : in  std_logic;
    stall : in std_logic;
    A   : in  std_logic_vector (31 downto 0);
    B   : in  std_logic_vector (31 downto 0);
    C   : out std_logic_vector (31 downto 0));
end entity fadd;

architecture behav of fadd is
  component right_shift is
    port (
      D : in  std_logic_vector (23 downto 0);
      s : in  std_logic_vector (4 downto 0);
      q : out std_logic_vector (26 downto 0));
  end component right_shift;

  component ZLC is
    port (
      A : in  std_logic_vector (27 downto 0);
      Q : out std_logic_vector (4 downto 0));
  end component ZLC;

  signal i_A : std_logic_vector (31 downto 0) := (others => '0');
  signal i_B : std_logic_vector (31 downto 0) := (others => '0');
  signal m_l_0 : std_logic_vector (23 downto 0) := (others => '0');
  signal s : std_logic_vector (4 downto 0) := (others => '0');
  signal diff_AB : std_logic_vector (7 downto 0) := (others => '0');
  signal diff_BA : std_logic_vector (7 downto 0) := (others => '0');

  -- Stage 1 -> 2
  signal m_g : std_logic_vector (26 downto 0) := (others => '0');
  signal m_l : std_logic_vector (26 downto 0) := (others => '0');
  signal sign_in : std_logic := '0';
  signal exp_in : std_logic_vector (7 downto 0) := (others => '0');
  signal isAddition : std_logic := '0';

  signal i_m_g : std_logic_vector (26 downto 0) := (others => '0');
  signal i_m_l : std_logic_vector (26 downto 0) := (others => '0');
  signal i_sign : std_logic := '0';
  signal i_exp : std_logic_vector (7 downto 0) := (others => '0');
  signal i_isAddition : std_logic := '0';
  signal m_added : std_logic_vector (27 downto 0) := (others => '0');
  signal m_leading_zero  : std_logic_vector (4 downto 0) := (others => '0');

  -- Stage 2 -> 3
  signal sign_out : std_logic := '0';
  signal exp_out : std_logic_vector (7 downto 0) := (others => '0');
  signal mantissa : std_logic_vector (24 downto 0) := (others => '0');
  signal carryWhenRound : std_logic := '0';
  signal leading_zero : std_logic_vector (4 downto 0) := (others => '0');

  signal i_sign2 : std_logic := '0';
  signal i_exp2 : std_logic_vector (7 downto 0) := (others => '0');
  signal i_mantissa : std_logic_vector (24 downto 0) := (others => '0');
  signal i_carry : std_logic := '0';
  signal i_leading_zero : std_logic_vector (4 downto 0) := (others => '0');
  signal o_exp0 : std_logic_vector (7 downto 0) := (others => '0');
  signal o_exp : std_logic_vector (7 downto 0) := (others => '0');
  signal o_mantissa : std_logic_vector (22 downto 0) := (others => '0');

begin  -- architecture behav

  -- stage 1

  i_A <= A;
  i_B <= B;

  m_g <=
    "1" & i_A (22 downto 0) & "000" when
    (i_A (30 downto 0) > i_B (30 downto 0)) and
    i_A (30 downto 23) /= x"00" else
    "1" & i_B (22 downto 0) & "000" when
    (i_A (30 downto 0) <= i_B (30 downto 0)) and
    i_B (30 downto 23) /= x"00" else
    (others => '0');

  m_l_0 <=
    "1" & i_A (22 downto 0) when
    (i_A (30 downto 0) < i_B (30 downto 0)) and
    i_A (30 downto 23) /= x"00" else
    "1" & i_B (22 downto 0) when
    (i_A (30 downto 0) >= i_B (30 downto 0)) and
    i_B (30 downto 23) /= x"00" else
    (others => '0');

  shift : right_shift port map (m_l_0,s,m_l);

  diff_AB <= i_A (30 downto 23) - i_B (30 downto 23);
  diff_BA <= i_B (30 downto 23) - i_A (30 downto 23);

  s <= "11111"
       when (i_A (30 downto 0) > i_B (30 downto 0) and
       diff_AB (7 downto 5) /= "000") or
       (i_A (30 downto 0) < i_B (30 downto 0) and
       diff_BA (7 downto 5) /= "000")
       else diff_AB (4 downto 0)
       when i_A (30 downto 0) > i_B (30 downto 0)
       else diff_BA (4 downto 0);

  with i_A (30 downto 0) > i_B (30 downto 0) select
    sign_in <=
    i_A (31) when true,
    i_B (31) when false;

  with i_A (30 downto 0) > i_B (30 downto 0) select
    exp_in <=
    i_A (30 downto 23) when true,
    i_B (30 downto 23) when false;

  isAddition <= not (i_A (31) xor i_B (31));

  process (CLK) is
  begin  -- process set_loop
    if rising_edge (CLK) and stall = '0' then
      i_m_g <= m_g;
      i_m_l <= m_l;
      i_sign <= sign_in;
      i_exp <= exp_in;
      i_isAddition <= isAddition;
    end if;
  end process;

  -- stage 2

  with i_isAddition select
    m_added <=
    "0000000000000000000000000000" + i_m_g + i_m_l when '1',
    "0000000000000000000000000000" + i_m_g - i_m_l when others;

  i_ZLC : ZLC port map (m_added,m_leading_zero);


  carryWhenRound <= '1'
                  when
                    (m_leading_zero = "00000" and m_added (26 downto 4) = "11111111111111111111111") or
                    (m_leading_zero = "00001" and m_added (25 downto 3) = "11111111111111111111111") or
                    (m_leading_zero = "00010" and m_added (24 downto 2) = "11111111111111111111111") or
                    (m_leading_zero = "00011" and m_added (23 downto 1) = "11111111111111111111111")
                  else '0';

  with m_leading_zero (1 downto 0) select
    mantissa <=
    m_added (26 downto 2)  when "00",
    m_added (25 downto 1)  when "01",
    m_added (24 downto 0)  when "10",
    m_added (23 downto 0) & '0' when others;

  sign_out <= i_sign;
  exp_out <= i_exp;
  leading_zero <= m_leading_zero;

  process (CLK) is
  begin
    if rising_edge (CLK) and stall = '0' then
      i_sign2 <= sign_out;
      i_exp2 <= exp_out;
      i_mantissa <= mantissa;
      i_carry <= carryWhenRound;
      i_leading_zero <= leading_zero;
    end if;
  end process;

  -- stage 3

  o_mantissa <= i_mantissa (24 downto 2) + '1'
                when i_leading_zero (4 downto 2) = "000" and
                i_mantissa (1) = '1' and (i_mantissa (0) = '1' or i_mantissa (2) = '1') and
                i_carry = '0'
                else
                "00000000000000000000000"
                when i_leading_zero (4 downto 2) = "000" and
                i_mantissa (1) = '1' and (i_mantissa (0) = '1' or i_mantissa (2) = '1') and
                i_carry = '1'
                else
                i_mantissa (24 downto 2)
                when i_leading_zero (4 downto 2) = "000"
                else
                i_mantissa (20 downto 0) & "00"
                when i_leading_zero (4 downto 2)  = "001"
                else
                i_mantissa (16 downto 0) & "000000"
                when i_leading_zero (4 downto 2)  = "010"
                else
                i_mantissa (12 downto 0) & "0000000000"
                when i_leading_zero (4 downto 2)  = "011"
                else
                i_mantissa (8 downto 0) & "00000000000000"
                when i_leading_zero (4 downto 2)  = "100"
                else
                i_mantissa (4 downto 0) & "000000000000000000"
                when i_leading_zero (4 downto 2)  = "101"
                else
                i_mantissa (0)  & "0000000000000000000000"
                when i_leading_zero (4 downto 2)  = "110"
                else
                "00000000000000000000000";

  o_exp0 <= i_exp2 + 1
          when i_leading_zero (4 downto 2) = "000" and
            i_mantissa (1) = '1' and (i_mantissa (0) = '1' or i_mantissa (2) = '1') and
            i_carry = '1'
          else
            i_exp2;

  o_exp <= (others => '0')
           when i_leading_zero > 0 and (o_exp0 < (i_leading_zero - 1) or i_leading_zero >= 26)
           else o_exp0 - i_leading_zero + 1;

  C <= i_sign2 & o_exp & o_mantissa;

end architecture behav;
