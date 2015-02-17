library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.types.all;

entity bram is

  port (
    clk      : in  std_logic;
    bram_in  : in  bram_in_type;
    bram_out : out bram_out_type);

end entity;

architecture behavioral of bram is

  type ram_t is
    array(0 to 8191) of std_logic_vector(31 downto 0);

  constant ramtest : ram_t := (
0 => x"2e80000c",
1 => x"3ef40000",
2 => x"ce830000",
3 => x"3f000040",
4 => x"3f800040",
5 => x"20800000",
6 => x"21000000",
7 => x"0188021a",
8 => x"f180000f",
9 => x"20800000",
10 => x"0184021a",
11 => x"f180000a",
12 => x"2e800400",
13 => x"027fa001",
14 => x"018400c2",
15 => x"018c8000",
16 => x"02080042",
17 => x"018c8000",
18 => x"02044000",
19 => x"620c0000",
20 => x"00840020",
21 => x"be83fff4",
22 => x"01080020",
23 => x"be83ffef",
24 => x"20800000",
25 => x"21000000",
26 => x"0188021a",
27 => x"f1800012",
28 => x"20800000",
29 => x"0184021a",
30 => x"f180000c",
31 => x"2e800400",
32 => x"027fa001",
33 => x"018400c2",
34 => x"018c8000",
35 => x"02080042",
36 => x"018c8000",
37 => x"830c0000",
38 => x"2e804000",
39 => x"018fa001",
40 => x"848c0000",
41 => x"00840020",
42 => x"be83fff2",
43 => x"2300ffff",
44 => x"01080020",
45 => x"be83ffec",
46 => x"ffffffff",
others => (others => '0')
);

  --signal ram : ram_t := (others => (others => '0'));
  signal ram : ram_t := ramtest;

  signal addr_reg : std_logic_vector(31 downto 0);
  signal addr_reg2 : std_logic_vector(31 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if bram_in.we = '1' then
        ram(conv_integer(bram_in.addr(14 downto 2))) <= bram_in.val;
      end if;
      addr_reg  <= bram_in.addr;
      addr_reg2 <= bram_in.addr2;
    end if;
  end process;

  bram_out.rx  <= ram(conv_integer(addr_reg(14 downto 2)));
  bram_out.rx2 <= ram(conv_integer(addr_reg2(14 downto 2)));

end architecture;
