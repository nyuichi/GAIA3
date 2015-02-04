library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.types.all;

entity icache is

  port (
    clk        : in  std_logic;
    icache_in  : in  icache_in_type;
    icache_out : out icache_out_type);

end entity icache;

architecture Behavioral of icache is

  type ram_t is
    array(0 to 1000) of std_logic_vector(31 downto 0);

  constant myram : ram_t := (
    0 => (others => '0'),
    1 => "0010" & "00001" & "00000" & "00" & x"FEDB",
    2 => (others => '0'),
    3 => (others => '0'),
    4 => (others => '0'),
    5 => (others => '0'),
    6 => (others => '0'),
    7 => (others => '0'),
    8 => "0011" & "00001" & "00001" & "00" & x"CA98",
    others => (others => '0'));

  constant myram2 : ram_t := (
    (others => '0'),
    "0010" & "00001" & "00000" & "00" & x"000A", -- 1
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    "1111" & "00001" & "00000" & "00" & x"0014", -- 8
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    "0000" & "00001" & "00001" & "00000" & x"01" & "00001", -- 15
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    "1011" & "11111" & "00000" & "00" & x"FFF1", -- 22
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    "1011" & "11111" & "00000" & "00" & x"FFFF", -- 29
    others => (others => '0'));

  constant myram3 : ram_t := (
    (others => '0'),
    "0000" & "00001" & "00000" & "00000" & x"01" & "00000",
    "0000" & "00010" & "00000" & "00000" & x"02" & "00000",
    "0000" & "00011" & "00000" & "00000" & x"03" & "00000",
    "0000" & "00100" & "00000" & "00000" & x"04" & "00000",
    "0000" & "00101" & "00000" & "00000" & x"05" & "00000",
    "0000" & "00110" & "00000" & "00000" & x"06" & "00000",
    "0000" & "00001" & "00001" & "00010" & x"00" & "00000",
    "0000" & "00001" & "00001" & "00011" & x"00" & "00000",
    "0000" & "00001" & "00001" & "00100" & x"00" & "00000",
    "0000" & "00001" & "00001" & "00101" & x"00" & "00000",
    "0000" & "00001" & "00001" & "00110" & x"00" & "00000",
    others => (others => '0'));

  -- mov r1, 1
  -- mov r2, 2
  -- st r1, r0, 108
  -- st r2, r0, 112
  -- ld r3, r0, 108
  -- ld r4, r0, 112
  -- add r5, r3, r4

  constant myram4 : ram_t := (
    (others => '0'),

    "0000" & "00001" & "00000" & "00000" & x"01" & "00000",
    "0000" & "00010" & "00000" & "00000" & x"02" & "00000",

    "0110" & "00001" & "00000" & "00" & x"006C",
    "0110" & "00010" & "00000" & "00" & x"0070",

    "1000" & "00011" & "00000" & "00" & x"006C",
    "1000" & "00100" & "00000" & "00" & x"0070",

    "0000" & "00101" & "00011" & "00100" & x"00" & "00000",

    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    others => (others => '0'));

  -- mov r1, 0xA
  -- beq r1, r0, 8
  -- sub r1, r1, 1
  -- jl r31, -C
  -- jl r31, -4

  constant myram5 : ram_t := (
    (others => '0'),                    -- 0
    "0010" & "00001" & "00000" & "00" & x"000A", -- 4
    "1111" & "00001" & "00000" & "00" & x"0002", -- 8
    "0000" & "00001" & "00001" & "00000" & x"01" & "00001", -- C
    "1011" & "11111" & "00000" & "00" & x"FFFD",            -- 10
    "1011" & "11111" & "00000" & "00" & x"FFFF",            -- 14
    others => (others => '0'));

  -- mov r1, 10
  -- mov r2, 3
  -- bne r1, r2, [40]
  -- mov r3, 4

  constant myram6 : ram_t := (
    (others => '0'),
    "0010" & "00001" & "00000" & "00" & x"000A",
    "0010" & "00010" & "00000" & "00" & x"0003",
    "1101" & "00001" & "00010" & "00" & x"0040",
    "0010" & "00011" & "00000" & "00" & x"0004",
    others => (others => '0'));

  -- mov r1, 1
  -- add r2, r1, r0
  -- beq r1, r2, [40]
  -- mov r3, 3

  constant myram7 : ram_t := (
    (others => '0'),
    "0010" & "00001" & "00000" & "00" & x"0001",
    "0000" & "00010" & "00001" & "00000" & x"00" & "00000",
    "1111" & "00001" & "00010" & "00" & x"0040",
    "0010" & "00011" & "00000" & "00" & x"0003",
    others => (others => '0'));

  -- mov r1, 1
  -- cmpeq r2, r1, r0, 1

  constant myram8 : ram_t := (
    (others => '0'),
    "0010" & "00001" & "00000" & "00" & x"0001",
    "0000" & "00010" & "00001" & "00000" & x"01" & "11001",
    others => (others => '0'));

  constant myram9 : ram_t := (
x"2e80000c",
x"3ef40000",
x"ce830000",
x"00000000",
x"00000000",
x"00000000",
x"2180000a",
x"20800000",
x"21000001",
x"02040000",
x"00880000",
x"01088000",
x"018c0021",
x"d180fffb",
x"ffffffff",
others => (others => '0')
    );

  constant myram_fibrecur : ram_t := (
0 => x"2e804070",
1 => x"3ef40000",
2 => x"ce830000",
3 => x"0f780181",
4 => x"6e780000",
5 => x"0e84005a",
6 => x"de800014",
7 => x"60fcffff",
8 => x"00840021",
9 => x"6ff8ffff",
10 => x"0f780081",
11 => x"0ff80000",
12 => x"be03fff6",
13 => x"0f7c0080",
14 => x"8ff8ffff",
15 => x"60fcfffe",
16 => x"80fcffff",
17 => x"00840041",
18 => x"6ff8ffff",
19 => x"0f780081",
20 => x"0ff80000",
21 => x"be03ffed",
22 => x"0f7c0080",
23 => x"8ff8ffff",
24 => x"817cfffe",
25 => x"00844000",
26 => x"8e780000",
27 => x"ce030000",
28 => x"2080000a",
29 => x"6ff8ffff",
30 => x"0f780081",
31 => x"0ff80000",
32 => x"be03ffe2",
33 => x"0f7c0080",
34 => x"8ff8ffff",
35 => x"ffffffff",
others => (others => '0'));

  signal ram : ram_t := myram_fibrecur;

  signal addr_reg : std_logic_vector(31 downto 0) := (others => '0');

begin

  process(clk)
  begin
    if rising_edge(clk) then
      addr_reg <= icache_in.addr;
    end if;
  end process;

  icache_out.rx <= ram(conv_integer(addr_reg(31 downto 2)));

end Behavioral;
