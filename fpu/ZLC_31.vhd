library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ZLC31 is

  port (
    A : in  std_logic_vector (30 downto 0);
    Q : out std_logic_vector (4 downto 0));

end entity ZLC31;

architecture rtl of ZLC31 is
  signal Z15 : std_logic_vector (3 downto 0) := (others => '0');
  signal Z7 : std_logic_vector (2 downto 0) := (others => '0');
  signal Z30 : std_logic_vector (1 downto 0) := (others => '0');
  signal Z31 : std_logic_vector (1 downto 0) := (others => '0');
  signal Z32 : std_logic_vector (1 downto 0) := (others => '0');
  signal Q0 : std_logic_vector (4 downto 0) := (others => '0');
  signal Q1 : std_logic_vector (4 downto 0) := (others => '0');
  signal Q2 : std_logic_vector (4 downto 0) := (others => '0');
  signal Q3 : std_logic_vector (4 downto 0) := (others => '0');
  signal Q4 : std_logic_vector (4 downto 0) := (others => '0');
  signal B0 : boolean := true;
  signal B1 : boolean := true;
  signal B2 : boolean := true;
  signal B3 : boolean := true;
  signal B4 : boolean := true;
  -- purpose: ZLC31 of 3 bits
  function ZLC3 (
    A : std_logic_vector (2 downto 0))
    return std_logic_vector is
    variable ret : std_logic_vector (1 downto 0) := (others => '0');
  begin  -- function ZLC3
    ret (1) := A (2) nor A (1);
    ret (0) := not (A (2) or (not A(1) and A (0)));
    return ret;
  end function ZLC3;

  -- purpose: ZLC of 7 bits
  function ZLC7 (
    A : std_logic_vector (6 downto 0))
    return std_logic_vector is
    variable ret : std_logic_vector (2 downto 0) := (others => '0');
  begin  -- function ZLC7
    ret (2) := not (A (6) or A (5) or A (4) or A (3));
    ret (1) := not (A (6) or A (5) or (not A (4) and not A (3) and (A (2) or A (1))));
    ret (0) := not (A (6)
               or ( not A (5) and ( A (4)
               or ( not A (3) and ( A (2)
               or ( not A (1) and ( A (0))))))));
    return ret;
  end function ZLC7;

  -- purpose: ZLC of 15 bits
  function ZLC15 (
    A : std_logic_vector (14 downto 0))
    return std_logic_vector is
    variable ret : std_logic_vector (3 downto 0) := (others => '0');
  begin  -- function ZLC15
    ret (3) := not (A (14) or A (13) or A (12) or A (11)
               or A (10) or A (9) or A (8) or A (7));
    ret (2) := not (A (14) or A (13) or A (12) or A (11)
                    or (not A (10) and not A (9) and not A (8) and not A (7)
                    and (A (6) or A (5) or A (4) or A (3))));
    ret (1) := not (A (14) or A (13)
               or ( not A (12) and not A (11) and ( A (10) or A (9)
               or ( not A (8) and not A (7) and (A (6) or A (5)
               or (not A (4) and not A (3) and (A (2) or A (1))))))));
    ret (0) := not (A (14)
               or ( not A (13) and ( A (12)
               or ( not A (11) and ( A (10)
               or ( not A (9) and ( A (8)
               or ( not A (7) and ( A (6)
               or ( not A (5) and ( A (4)
               or ( not A (3) and ( A (2)
               or ( not A (1) and ( A (0))))))))))))))));
    return ret;
  end function ZLC15;

begin  -- architecture rtl
  Q4 <= "00000" + ZLC3 (A (5 downto 3)) + ZLC3 (A (2 downto 0));
  Z15 <= ZLC15 (A (30 downto 16));
  Z7 <= ZLC7 (A (15 downto 9));
  Z30 <= ZLC3 (A (8 downto 6));
  Z31 <= ZLC3 (A (5 downto 3));
  Z32 <= ZLC3 (A (2 downto 0));
  Q0 <= '0' & ZLC15 (A (30 downto 16));
  B0 <= ZLC15 (A (30 downto 16)) /= x"f";
  Q1 <= "01111" + ZLC7 (A (15 downto 9));
  B1 <= ZLC7 (A (15 downto 9)) /= "111";
  Q2 <= "10110" + ZLC3 (A (5 downto 3));
  B2 <= ZLC3 (A (8 downto 6)) /= "11";
  Q3 <= "11001" + ZLC3 (A (5 downto 3));
  B3 <= ZLC3 (A (5 downto 3)) /= "11";
  Q <= '0' & ZLC15 (A (30 downto 16))
       when ZLC15 (A (30 downto 16)) /= x"f"
       else "01111" + ZLC7 (A (15 downto 9))
       when ZLC7 (A (15 downto 9)) /= "111"
       else "10110" + ZLC3 (A (8 downto 6))
       when ZLC3 (A (8 downto 6)) /= "11"
       else "11001" + ZLC3 (A (5 downto 3))
       when ZLC3 (A (5 downto 3)) /= "11"
       else "11100" + ZLC3 (A (2 downto 0));
end architecture rtl;
