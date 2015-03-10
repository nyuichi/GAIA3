library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fadd is

  port (
    x, y : in  std_logic_vector(31 downto 0);
    q    : out std_logic_vector(31 downto 0));

end entity;

architecture behavioral of fadd is

  -- stage1
  signal input_x,input_y : std_logic_vector(31 downto 0);
  signal cmp_abs : std_logic_vector(1 downto 0);
  signal arg_large,arg_small : std_logic_vector(31 downto 0);
  signal frc_large,frc_small,frc_small_shifted,frc_result1,frc_result2,frc_uped,frc_result3,frc_ans : std_logic_vector(27 downto 0);
  signal exp_large,exp_small,exp_gap,exp_ans : std_logic_vector(7 downto 0);
  signal exp_ans2 : std_logic_vector(8 downto 0);
  signal sgn_large,sgn_small,sgn_ans : std_logic;
  signal op : std_logic;
  signal shift : std_logic_vector(4 downto 0);
  signal exp_up :std_logic;
  signal rounding :std_logic;
  signal ans_head : std_logic_vector(8 downto 0);
  signal Parameter1 : std_logic_vector(27 downto 0);
  signal Parameter2 : std_logic_vector(27 downto 0);
  signal Round : std_logic_vector(4 downto 0);

begin

  input_x <= x;
  input_y <= y;

  --if |a| > |b| return 10
  --   |a| < |b| return 01
  --   |a| = |b| return 00
  cmp_abs <= "10" when input_x(30 downto 0) > input_y(30 downto 0)
             else "01" when input_x(30 downto 0) < input_y(30 downto 0)
             else "00";

  arg_large <= input_x when cmp_abs(1) = '1' else input_y;
  arg_small <= input_y when cmp_abs(1) = '1' else input_x;

  frc_large <= "01" & arg_large(22 downto 0) & "000";
  frc_small <= "01" & arg_small(22 downto 0) & "000";

  exp_large <= arg_large(30 downto 23);
  exp_small <= arg_small(30 downto 23);

  exp_gap <= exp_large - exp_small;
  exp_ans <= exp_large;

  sgn_large <= arg_large(31);
  sgn_small <= arg_small(31);

  sgn_ans <= sgn_large;

  op <= '0' when sgn_large = sgn_small else '1';

  Parameter1 <= Frc_Small when Exp_Gap(1 downto 0) = "00"
                else '0' & Frc_Small(27 downto 1) when Exp_Gap(1 downto 0) = "01"
                else "00" & Frc_Small(27 downto 2) when Exp_Gap(1 downto 0) = "10"
                else "000" & Frc_Small(27 downto 3);

  Round(0) <= '1' when Parameter1(4 downto 0) /= "00000" else '0';

  Parameter2 <= Parameter1 when Exp_Gap(2) = '0'
                else "0000" & Parameter1(27 downto 5) & Round(0);

  Round(1) <= '1' when Parameter1(8 downto 0)  = "000000000"
              else '1';
  Round(2) <= '1' when Parameter1(16 downto 0) = "00000000000000000"
              else '1';
  Round(3) <= '1' when Parameter1(24 downto 0) = "0000000000000000000000000"
              else '1';
  Round(4) <= '1' when Parameter1(27 downto 0) = "000000000000000000000000000"
              else '1';

  frc_small_shifted <=
    "000000000000000000000000000" & Round(4) when Exp_Gap(7 downto 5) /= "000"
    else Parameter2 when Exp_Gap(4 downto 3) = "00"
    else "00000000"
    & Parameter2(27 downto 9) & Round(1) when Exp_Gap(4 downto 3) = "01"
    else "0000000000000000"
    & Parameter2(27 downto 17) & Round(2) when Exp_Gap(4 downto 3) = "10"
    else "000000000000000000000000"
    & Parameter2(27 downto 25) & Round(3) when Exp_Gap(4 downto 3) = "11";

  frc_result1 <= frc_large + frc_small_shifted when op = '0'
                 else frc_large - frc_small_shifted;

  shift <=
    "00000" when frc_result1(27) = '1' else
    "00001" when frc_result1(26) = '1' else
    "00010" when frc_result1(25) = '1' else
    "00011" when frc_result1(24) = '1' else
    "00100" when frc_result1(23) = '1' else
    "00101" when frc_result1(22) = '1' else
    "00110" when frc_result1(21) = '1' else
    "00111" when frc_result1(20) = '1' else
    "01000" when frc_result1(19) = '1' else
    "01001" when frc_result1(18) = '1' else
    "01010" when frc_result1(17) = '1' else
    "01011" when frc_result1(16) = '1' else
    "01100" when frc_result1(15) = '1' else
    "01101" when frc_result1(14) = '1' else
    "01110" when frc_result1(13) = '1' else
    "01111" when frc_result1(12) = '1' else
    "10000" when frc_result1(11) = '1' else
    "10001" when frc_result1(10) = '1' else
    "10010" when frc_result1(9)  = '1' else
    "10011" when frc_result1(8)  = '1' else
    "10100" when frc_result1(7)  = '1' else
    "10101" when frc_result1(6)  = '1' else
    "10110" when frc_result1(5)  = '1' else
    "10111" when frc_result1(4)  = '1' else
    "11000" when frc_result1(3)  = '1' else
    "11001" when frc_result1(2)  = '1' else
    "11010" when frc_result1(1)  = '1' else
    "11011" when frc_result1(0)  = '1' else
    "11100";

  exp_up <= '1' when frc_result1(25 downto 2) = "111111111111111111111111" and (frc_result1(26) or frc_result1(1))='1'
            else '0';

  frc_uped <= "1000000000000000000000000000"
              when frc_result1(26 downto 2) = "1111111111111111111111111"
              else "0100000000000000000000000000"
              when frc_result1(25 downto 1) = "1111111111111111111111111"
              else frc_result1;

  frc_result2 <=
    frc_uped(27 downto 0) when shift(1 downto 0) = "00" else
    frc_uped(26 downto 0) & '0' when shift(1 downto 0) = "01" else
    frc_uped(25 downto 0) & "00" when shift(1 downto 0) = "10" else
    frc_uped(24 downto 0) & "000" when shift(1 downto 0) = "11";

  rounding <= frc_result2(3) and (frc_result2(4) or frc_result2(2) or frc_result2(1));

  frc_result3 <=
    Frc_Result2(23 downto 0) & "0000" when Shift(4 Downto 2) = "001" else
    Frc_Result2(19 downto 0) & "00000000" when Shift(4 Downto 2) = "010" else
    Frc_Result2(15 downto 0) & "000000000000" when Shift(4 Downto 2) = "011" else
    Frc_Result2(11 downto 0) & "0000000000000000" when Shift(4 Downto 2) = "100" else
    Frc_Result2(7  downto 0) & "00000000000000000000" when Shift(4 Downto 2) = "101" else
    Frc_Result2(3  downto 0) & "000000000000000000000000" when Shift(4 Downto 2) = "110" else
    "0000000000000000000000000000" when Shift(4 Downto 2) = "111" else
    Frc_Result2(27 downto 0);

  frc_ans <= frc_result2 + (rounding & "0000") when shift(4 downto 2) = "000"
             else frc_result3;

  --exp_ans2 <= exp_ans + exp_up + 1 - zlc;
  exp_ans2 <= ('0'&exp_ans) + ("0000000" & exp_up & (not exp_up)) - ("0000"&shift);

  ans_head <= "000000000" when exp_ans2(8)='1' or shift >= "11010" or exp_ans ="00000000"
              else sgn_ans&exp_ans2(7 downto 0);

  q <= ans_head & frc_ans(26 downto 4);

end architecture;
