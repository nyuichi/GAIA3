library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ZLC is

  port (
    A : in  std_logic_vector (27 downto 0);
    Q : out std_logic_vector (4 downto 0));

end entity ZLC;

architecture rtl of ZLC is

  -- purpose: ZLC of 3 bits
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

  signal Z0 : std_logic_vector (3 downto 0) := (others => '0');
  signal Z1 : std_logic_vector (2 downto 0) := (others => '0');
  signal Z2 : std_logic_vector (1 downto 0) := (others => '0');
  signal Z3 : std_logic_vector (1 downto 0) := (others => '0');

begin  -- architecture rtl
  Z0 <= ZLC15 (A (27 downto 13));
  Z1 <= ZLC7 (A (12 downto 6));
  Z2 <= ZLC3 (A (5 downto 3));
  Z3 <= ZLC3 (A (2 downto 0));

  Q <= '0' & Z0
       when Z0 /= "1111"
       else std_logic_vector(to_unsigned(to_integer (unsigned(Z1)) + 15,5))
       when Z1 /= "111"
       else std_logic_vector(to_unsigned(to_integer (unsigned(Z2)) + 22,5))
       when Z2 /= "11"
       else std_logic_vector(to_unsigned(to_integer (unsigned(Z3)) + 25,5));
end architecture rtl;
