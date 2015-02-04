library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

package util is

  function to_std_logic(b : boolean) return std_logic;
  function repeat(B: std_logic; N: natural) return std_logic_vector;

end package;

package body util is

  function to_std_logic(b : boolean)
    return std_logic is
  begin
    if b then
      return '1';
    else
      return '0';
    end if;
  end to_std_logic;

  function repeat(B: std_logic; N: natural)
    return std_logic_vector is
    variable result: std_logic_vector(N downto 1);
  begin
    for i in 1 to N loop
      result(i) := B;
    end loop;
    return result;
  end;

end util;
