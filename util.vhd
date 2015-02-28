library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

package util is

  function to_std_logic(b : boolean) return std_logic;
  function repeat(B: std_logic; N: natural) return std_logic_vector;
  function normalize_fzero(a : std_logic_vector(31 downto 0)) return std_logic_vector;
  function stdv2str(vec : std_logic_vector) return string;

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

  function normalize_fzero (a : std_logic_vector(31 downto 0))
    return std_logic_vector is
    variable result : std_logic_vector(31 downto 0);
  begin
    if a = x"80000000" then
      result := x"00000000";
    else
      result := a;
    end if;
    return result;
  end function;

  function stdv2str(vec:std_logic_vector) return string is
    variable str: string(vec'left+1 downto 1);
  begin
    for i in vec'reverse_range loop
      if(vec(i)='U') then
        str(i+1):='U';
      elsif(vec(i)='X') then
        str(i+1):='X';
      elsif(vec(i)='0') then
        str(i+1):='0';
      elsif(vec(i)='1') then
        str(i+1):='1';
      elsif(vec(i)='Z') then
        str(i+1):='Z';
      elsif(vec(i)='W') then
        str(i+1):='W';
      elsif(vec(i)='L') then
        str(i+1):='L';
      elsif(vec(i)='H') then
        str(i+1):='H';
      else
        str(i+1):='-';
      end if;
    end loop;
    return str;
  end;

end util;
