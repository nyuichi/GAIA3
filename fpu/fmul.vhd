library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_arith.ALL;
use IEEE.std_logic_unsigned.ALL;

entity fmul is

  port (
    x, y : in  std_logic_vector(31 downto 0);
    q    : out std_logic_vector(31 downto 0));

end entity;


architecture behavioral of fmul is

  --stage1
  signal input_x,input_y : std_logic_vector(31 downto 0) := (others => '0');
  signal frc_x_h,frc_y_h : std_logic_vector(12 downto 0) := (others => '0');
  signal frc_x_l,frc_y_l : std_logic_vector(10 downto 0) := (others => '0');
  signal exp_x1,exp_y1 : std_logic_vector(8 downto 0);
  signal exp_ans :std_logic_vector(7 downto 0);
  signal exp_ans1,exp_ans2 : std_logic_vector(8 downto 0) := (others => '0');
  signal sgn_ans : std_logic := '0';
  signal frc_hh : std_logic_vector(25 downto 0);
  signal frc_hl,frc_lh : std_logic_vector(23 downto 0);
  signal frc_result : std_logic_vector(26 downto 0);
  signal frc_ans : std_logic_vector(22 downto 0);

begin                           -- fuml

  input_x <= x;
  input_y <= y;
  frc_x_h <= '1' & input_x(22 downto 11);
  frc_x_l <= input_x(10 downto 0);
  frc_y_h <= '1' & input_y(22 downto 11);
  frc_y_l <= input_y(10 downto 0);
  exp_x1  <= '0' & input_x(30 downto 23);
  exp_y1  <= '0' & input_y(30 downto 23);
  exp_ans1 <= exp_x1 + exp_y1 + "010000001";

  sgn_ans <= input_x(31) xor input_y(31);


  frc_hh <= frc_x_h * frc_y_h;
  frc_hl <= frc_x_h * frc_y_l;
  frc_lh <= frc_x_l * frc_y_h;

  frc_result <= '0' & frc_hh + frc_hl(23 downto 11) + frc_lh(23 downto 11) + "10";

  exp_ans2 <= exp_ans1 + '1';

  exp_ans <= "00000000" when exp_ans1(8) = '0'
             else exp_ans2(7 downto 0) when frc_result(25) = '1'
             else exp_ans1(7 downto 0);

  frc_ans <= frc_result(24 downto 2) when frc_result(25) = '1'
             else frc_result(23 downto 1);

  q <= "00000000000000000000000000000000" when exp_ans1(8) = '0'
       else sgn_ans & exp_ans & frc_ans;

end architecture;
