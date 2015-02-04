library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GS8160Z18 is
  generic (
    report_read : boolean := false;
    report_write : boolean := false);
  port (
    A : in std_logic_vector(19 downto 0);
    CK : in std_logic;
    XBA : in std_logic;
    XBB : in std_logic;
    XW : in std_logic;
    XE1 : in std_logic;
    E2 : in std_logic;
    XE3 : in std_logic;
    XG : in std_logic;
    ADV : in std_logic;
    XCKE : in std_logic;
    DQA : inout std_logic_vector(7 downto 0);
    DQB : inout std_logic_vector(7 downto 0);
    DQPA : inout std_logic;
    DQPB : inout std_logic;
    ZZ : in std_logic := '0';
    XFT : in std_logic := '1';
    XLBO : in std_logic);
end entity GS8160Z18;

-- It's internal structure is different than the actual circuit.
-- not implemented : ZZ
architecture Behavioral of GS8160Z18 is

  constant insignal_delay : time := 1 fs;
  signal A_delayed : std_logic_vector(19 downto 0);
  signal XBA_delayed : std_logic;
  signal XBB_delayed : std_logic;
  signal XW_delayed : std_logic;
  signal ADV_delayed : std_logic;
  signal XFT_delayed : std_logic;

  signal K : std_logic;
  signal XE : std_logic;
  signal ADV_latched : std_logic;
  signal A_latched : std_logic_vector(19 downto 0);
  signal SA_low : std_logic_vector(1 downto 0);
  signal SA : std_logic_vector(19 downto 0);
  signal burst_count : unsigned(1 downto 0);
  signal burst_output : unsigned(1 downto 0);
  signal memory_addr : std_logic_vector(19 downto 0);
  subtype memory_cell is std_logic_vector(17 downto 0);
  signal data_inA : std_logic_vector(8 downto 0);
  signal data_inB : std_logic_vector(8 downto 0);
  signal memory_output : memory_cell;
  signal memory_output2 : memory_cell;
  signal SA_latched : std_logic_vector(19 downto 0);
  signal XW_latched : std_logic;
  signal XE_latched : std_logic;
  signal XBA_latched : std_logic;
  signal XBB_latched : std_logic;
  signal SA_latched2 : std_logic_vector(19 downto 0);
  signal XW_latched2 : std_logic;
  signal XE_latched2 : std_logic;
  signal XBA_latched2 : std_logic;
  signal XBB_latched2 : std_logic;
  signal SA2 : std_logic_vector(19 downto 0);
  signal XW2 : std_logic;
  signal XE2 : std_logic;
  signal XBA2 : std_logic;
  signal XBB2 : std_logic;
begin

  A_delayed <= A after insignal_delay;
  XBA_delayed <= XBA after insignal_delay;
  XBB_delayed <= XBB after insignal_delay;
  XW_delayed <= XW after insignal_delay;
  ADV_delayed <= ADV after insignal_delay;
  XFT_delayed <= XFT after insignal_delay;

  data_inA <= DQPA & DQA after insignal_delay;
  data_inB <= DQPB & DQB after insignal_delay;

  memory_addr <= SA2;
  memory_output2 <=
    (others => 'Z') when XE2 = '1' or XW2 /= '1' or XG = '1' else
    memory_output;
  DQPA <= memory_output2(17);
  DQA <= std_logic_vector(memory_output2(16 downto 9));
  DQPB <= memory_output2(8);
  DQB <= std_logic_vector(memory_output2(7 downto 0));

  SA2 <= SA_latched when XFT_delayed = '1' else SA;
  XW2 <= XW_latched2 when XFT_delayed = '1' else XW_latched;
  XE2 <= XE_latched2 when XFT_delayed = '1' else XE_latched;
  XBA2 <= XBA_latched2 when XFT_delayed = '1' else XBA_latched;
  XBB2 <= XBB_latched2 when XFT_delayed = '1' else XBB_latched;
  main : process(K,memory_addr)
    type memory_array_t is array(0 to 1048575) of memory_cell;
    variable memory_array : memory_array_t;
    variable addr_memo : unsigned(19 downto 0);
    variable wrupd : boolean;
  begin
    wrupd := false;
    if rising_edge(K) then
      SA_latched <= SA;
      if ADV_delayed /= '1' then
        XW_latched <= XW_delayed;
        XE_latched <= XE;
      end if;
      XBA_latched <= XBA_delayed;
      XBB_latched <= XBB_delayed;

      SA_latched2 <= SA_latched;
      XW_latched2 <= XW_latched;
      XE_latched2 <= XE_latched;
      XBA_latched2 <= XBA_latched;
      XBB_latched2 <= XBB_latched;

      if XE2 /= '1' and XW2 /= '1' then
        addr_memo := TO_01(unsigned(memory_addr), 'X');
        if addr_memo(19) = 'X' then
          if XBA2 /= '1' or XBB2 /= '1' then
            report "GS8160Z18: metavalue detected in Writing Address, aborting write operation"
              severity warning;
          end if;
        else
          wrupd := true;
          if XBA2 /= '1' then
            memory_array(to_integer(addr_memo))(17 downto 9)
              := data_inA;
          end if;
          if XBB2 /= '1' then
            memory_array(to_integer(addr_memo))(8 downto 0)
              := data_inB;
          end if;
          assert not report_write
            report "write " & integer'image(to_integer(unsigned(memory_addr)))
                   & " " & integer'image(to_integer(unsigned(memory_array(to_integer(unsigned(memory_addr)))))) severity note;
        end if;
      end if;
    end if;
    if memory_addr'event or wrupd then
      addr_memo := TO_01(unsigned(memory_addr), 'X');
      if addr_memo(19) = 'X' then
        assert not report_read report "read X" severity note;
        memory_output <= (others => 'X');
      else
        assert not report_read
          report "read " & integer'image(to_integer(addr_memo))
                 & " " & integer'image(to_integer(unsigned(memory_array(to_integer(addr_memo))))) severity note;
        memory_output <=
          memory_array(to_integer(addr_memo));
      end if;
    end if;
  end process main;

  burst_output <= unsigned(SA_low) + burst_count when XLBO /= '1' else
                  unsigned(SA_low) xor burst_count;
  burst_counter : process(K)
  begin
    if rising_edge(K) then
      ADV_latched <= ADV_delayed;
      if ADV_delayed = '1' then
        if ZZ /= '1' then
          burst_count <= burst_count + 1;
        end if;
      else
        burst_count <= "00";
      end if;
    end if;
  end process burst_counter;

  SA <= A_latched when ADV_latched /= '1' else
        A_latched(19 downto 2) & std_logic_vector(burst_output);
  SA_low <= A_latched(1 downto 0);
  latch_address : process(K)
  begin
    if rising_edge(K) and ADV_delayed /= '1' then
      A_latched <= A_delayed;
    end if;
  end process latch_address;

  XE <= XE1 or (not E2) or XE3 after insignal_delay;

  clk_in : process(CK)
  begin
    if rising_edge(CK) and XCKE /= '1' then
      K <= '1';
    end if;
    if falling_edge(CK) then
      K <= '0';
    end if;
  end process clk_in;
end architecture Behavioral;
