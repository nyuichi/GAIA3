library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.types.all;
use work.util.all;

entity cpu is

  port (
    clk           : in  std_logic;
    rst           : in  std_logic;
    icache_out    : in  icache_out_type;
    icache_in     : out icache_in_type;
    cpu_in        : in  bus_up_type;
    cpu_out       : out bus_down_type;
    memory_hazard : in  std_logic);

end entity;

architecture Behavioral of cpu is

  type regfile_type is
    array(0 to 31) of std_logic_vector(31 downto 0);

  type fetch_reg_type is record
    nextpc : std_logic_vector(31 downto 0);
  end record;

  type decode_reg_type is record
    opcode    : std_logic_vector(3 downto 0);
    reg_dest  : std_logic_vector(4 downto 0);
    reg_a     : std_logic_vector(4 downto 0);
    reg_b     : std_logic_vector(4 downto 0);
    data_x    : std_logic_vector(31 downto 0);
    data_a    : std_logic_vector(31 downto 0);
    data_b    : std_logic_vector(31 downto 0);
    data_l    : std_logic_vector(31 downto 0);
    data_d    : std_logic_vector(31 downto 0);
    tag       : std_logic_vector(4 downto 0);
    nextpc    : std_logic_vector(31 downto 0);
    reg_write : std_logic;
    reg_mem   : std_logic;
    mem_write : std_logic;
    mem_read  : std_logic;
    pc_addr   : std_logic_vector(31 downto 0);
    pc_src    : std_logic;
  end record;

  type execute_reg_type is record
    res       : std_logic_vector(31 downto 0);
    mem_addr  : std_logic_vector(31 downto 0);
    data_x    : std_logic_vector(31 downto 0);
    reg_dest  : std_logic_vector(4 downto 0);
    reg_write : std_logic;
    reg_mem   : std_logic;
    mem_write : std_logic;
    mem_read  : std_logic;
  end record;

  type memory_reg_type is record
    res       : std_logic_vector(31 downto 0);
    reg_dest  : std_logic_vector(4 downto 0);
    reg_write : std_logic;
    reg_mem   : std_logic;
  end record;

  type reg_type is record
    pc      : std_logic_vector(31 downto 0);
    regfile : regfile_type;
    f       : fetch_reg_type;
    d       : decode_reg_type;
    e       : execute_reg_type;
    m       : memory_reg_type;
  end record;

  constant fzero : fetch_reg_type := (
    nextpc => (others => '0')
    );

  constant dzero : decode_reg_type := (
    opcode    => "0000",
    reg_dest  => "00000",
    reg_a     => "00000",
    reg_b     => "00000",
    data_x    => (others => '0'),
    data_a    => (others => '0'),
    data_b    => (others => '0'),
    data_l    => (others => '0'),
    data_d    => (others => '0'),
    tag       => "00000",
    nextpc    => (others => '0'),
    reg_write => '0',
    reg_mem   => '0',
    mem_write => '0',
    mem_read  => '0',
    pc_addr   => (others => '0'),
    pc_src    => '0'
    );

  constant ezero : execute_reg_type := (
    res       => (others => '0'),
    mem_addr  => (others => '0'),
    data_x    => (others => '0'),
    reg_dest  => "00000",
    reg_write => '0',
    reg_mem   => '0',
    mem_write => '0',
    mem_read  => '0'
    );

  constant mzero : memory_reg_type := (
    res       => (others => '0'),
    reg_dest  => "00000",
    reg_write => '0',
    reg_mem   => '0'
    );

  constant rzero : reg_type := (
    pc      => (others => '0'),
    regfile => (others => (others => '0')),
    f       => fzero,
    d       => dzero,
    e       => ezero,
    m       => mzero
    );

  signal r, rin : reg_type;

  procedure normalize_fzero(
    a : inout std_logic_vector) is
  begin
    if a = x"80000000" then
      a := x"00000000";
    end if;
  end procedure;

  procedure d_data_forward (
    reg_src : in  std_logic_vector(4 downto 0);
    res     : out std_logic_vector(31 downto 0)) is
  begin
    if r.e.reg_write = '1' and r.e.reg_dest /= "00000" and r.e.reg_dest = reg_src then
      res := r.e.res;
    end if;
  end procedure;

  procedure e_data_forward (
    reg_src  : in  std_logic_vector(4 downto 0);
    reg_data : in  std_logic_vector(31 downto 0);
    res      : out std_logic_vector(31 downto 0)) is
  begin
    if r.e.reg_write = '1' and r.e.reg_dest /= "00000" and r.e.reg_dest = reg_src then
      res := r.e.res;
    elsif r.m.reg_write = '1' and r.m.reg_dest /= "00000" and r.e.reg_dest /= reg_src and r.m.reg_dest = reg_src then
      if r.m.reg_mem = '1' then
        res := cpu_in.rx;
      else
        res := r.m.res;
      end if;
    else
      res := reg_data;
    end if;
  end procedure;

  procedure detect_hazard (
    inst  : in  std_logic_vector(31 downto 0);
    stall : out std_logic) is

    variable lw_stall : std_logic;
    variable br_stall : std_logic;
    variable br_inst  : std_logic;

    variable reg_x : std_logic_vector(4 downto 0);
    variable reg_a : std_logic_vector(4 downto 0);
    variable reg_b : std_logic_vector(4 downto 0);

  begin
    reg_x := inst(27 downto 23);
    reg_a := inst(22 downto 18);
    if inst(31 downto 29) = "000" then
      reg_b := inst(17 downto 13);
    else
      reg_b := "00000";
    end if;

    -- load stall
    lw_stall := to_std_logic(
      r.d.mem_read = '1' and (r.d.reg_dest = reg_a or r.d.reg_dest = reg_b)
      );

    -- branch hazard
    if inst(31 downto 30) = "11" then
      if inst(28) = '1' then
        br_stall := to_std_logic(
          (r.d.reg_write = '1' and (r.d.reg_dest = reg_x or r.d.reg_dest = reg_a))
          or
          (r.e.reg_write = '1' and (r.e.reg_dest = reg_x or r.e.reg_dest = reg_a))
          );
      else
        br_stall := to_std_logic(
          (r.d.reg_write = '1' and r.d.reg_dest = reg_x)
          or
          (r.e.reg_write = '1' and r.e.reg_dest = reg_x)
          );
      end if;
    else
      br_stall := '0';
    end if;

    stall := br_stall or lw_stall;
  end procedure;

begin

  comb : process(r, icache_out, cpu_in, memory_hazard)
    variable v : reg_type;

    -- decode/write
    variable regfile : regfile_type;

    -- fetch
    variable pc : std_logic_vector(31 downto 0);

    -- decode
    variable inst : std_logic_vector(31 downto 0);

    variable fd_data_x : std_logic_vector(31 downto 0);
    variable fd_data_a : std_logic_vector(31 downto 0);

    -- write
    variable res : std_logic_vector(31 downto 0);

    -- execute
    variable shifter : integer;
    variable data_a : std_logic_vector(31 downto 0);
    variable data_b : std_logic_vector(31 downto 0);
    variable data_x : std_logic_vector(31 downto 0);

    -- control
    variable stall : std_logic;

    -- external
    variable i_addr : std_logic_vector(31 downto 0);
    variable d_addr : std_logic_vector(31 downto 0);
    variable d_val : std_logic_vector(31 downto 0);
    variable d_we : std_logic;
    variable d_re : std_logic;
  begin
    v := r;

    detect_hazard(icache_out.rx, stall);

    -- FETCH

    if r.d.pc_src = '0' then
      pc := r.f.nextpc;
    else
      pc := r.d.pc_addr;
    end if;

    v.pc := pc;
    v.f.nextpc := pc + 4;

    if stall = '1' or memory_hazard = '1' then
      pc := r.pc;
      v.pc := r.pc;
      v.f := r.f;
    end if;

    i_addr := pc;

    -- WRITE (put here to avoid structual hazard between WRITE and DECODE)

    if r.m.reg_mem = '1' then
      res := cpu_in.rx;
    else
      res := r.m.res;
    end if;

    regfile := r.regfile;

    if r.m.reg_write = '1' then
      for i in 1 to 31 loop
        if r.m.reg_dest = i then
          regfile(i) := res;
        end if;
      end loop;
    end if;

    v.regfile := regfile;

    -- DECODE

    inst := icache_out.rx;

    if r.d.pc_src = '1' then
      inst := x"00000000";
    end if;

    v.d.opcode := inst(31 downto 28);
    v.d.reg_dest := inst(27 downto 23);
    v.d.reg_a := inst(22 downto 18);
    v.d.reg_b := inst(17 downto 13);
    v.d.data_x := regfile(conv_integer(inst(27 downto 23)));
    v.d.data_a := regfile(conv_integer(inst(22 downto 18)));
    v.d.data_b := regfile(conv_integer(inst(17 downto 13)));
    v.d.data_l := repeat(inst(12), 24) & inst(12 downto 5);
    v.d.data_d := repeat(inst(15), 16) & inst(15 downto 0);
    v.d.tag := inst(4 downto 0);

    v.d.nextpc := r.f.nextpc;

    v.d.reg_write := to_std_logic(inst(30) = '0');
    v.d.reg_mem := to_std_logic(inst(31 downto 28) = "1000");
    v.d.mem_write := to_std_logic(inst(31 downto 28) = "0110");
    v.d.mem_read := to_std_logic(inst(31 downto 28) = "1000");

    -- branching...

    fd_data_x := regfile(conv_integer(inst(27 downto 23)));
    fd_data_a := regfile(conv_integer(inst(22 downto 18)));

    d_data_forward(inst(27 downto 23), fd_data_x);
    d_data_forward(inst(22 downto 18), fd_data_a);

    case inst(31 downto 28) is
      when "1011" | "1101" | "1111" =>
        v.d.pc_addr := r.f.nextpc + (repeat(inst(15), 14) & inst(15 downto 0) & "00");
      when "1100" =>
        v.d.pc_addr := fd_data_x;
      when others =>
        v.d.pc_addr := (others => '-');
    end case;

    case inst(31 downto 28) is
      when "1011" | "1100" =>
        v.d.pc_src := '1';
      when "1101" =>
        v.d.pc_src := to_std_logic(fd_data_x /= fd_data_a);
      when "1111" =>
        v.d.pc_src := to_std_logic(fd_data_x = fd_data_a);
      when others =>
        v.d.pc_src := '0';
    end case;

    if memory_hazard = '1' then
      v.d := r.d;
    elsif stall = '1' then
      v.d.reg_write := '0';
      v.d.mem_write := '0';
      v.d.mem_read := '0';
    end if;

    -- EXECUTE

    e_data_forward(r.d.reg_a, r.d.data_a, data_a);
    e_data_forward(r.d.reg_b, r.d.data_b, data_b);
    e_data_forward(r.d.reg_dest, r.d.data_x, data_x);

    case r.d.opcode is
      when "0000" =>
        case r.d.tag is
          when "00000" =>
            v.e.res := data_a + data_b + r.d.data_l;
          when "00001" =>
            v.e.res := data_a - data_b - r.d.data_l;
          when "00010" =>
            shifter := conv_integer(data_b + r.d.data_l);
            v.e.res := std_logic_vector(shift_left(unsigned(data_a), shifter));
          when "00011" =>
            shifter := conv_integer(data_b + r.d.data_l);
            v.e.res := std_logic_vector(shift_right(unsigned(data_a), shifter));
          when "00100" =>
            shifter := conv_integer(data_b + r.d.data_l);
            v.e.res := std_logic_vector(shift_right(signed(data_a), shifter));
          when "00101" =>
            v.e.res := data_a and data_b and r.d.data_l;
          when "00110" =>
            v.e.res := data_a or data_b or r.d.data_l;
          when "00111" =>
            v.e.res := data_a xor data_b xor r.d.data_l;
          when "11000" =>
            v.e.res := repeat('0', 31) & to_std_logic(data_a /= data_b + r.d.data_l);
          when "11001" =>
            v.e.res := repeat('0', 31) & to_std_logic(data_a = data_b + r.d.data_l);
          when "11010" =>
            v.e.res := repeat('0', 31) & to_std_logic(data_a < data_b + r.d.data_l);
          when "11011" =>
            v.e.res := repeat('0', 31) & to_std_logic(data_a <= data_b + r.d.data_l);
          when "11100" =>
            normalize_fzero(data_a);
            normalize_fzero(data_b);
            v.e.res := repeat('0', 31) & to_std_logic(data_a /= data_b);
          when "11101" =>
            normalize_fzero(data_a);
            normalize_fzero(data_b);
            v.e.res := repeat('0', 31) & to_std_logic(data_a = data_b);
          when "11110" =>
            normalize_fzero(data_a);
            normalize_fzero(data_b);
            if data_a(31) = '1' or data_b(31) = '1' then
              v.e.res := repeat('0', 31) & to_std_logic(data_a >= data_b);
            else
              v.e.res := repeat('0', 31) & to_std_logic(data_a < data_b);
            end if;
          when "11111" =>
            normalize_fzero(data_a);
            normalize_fzero(data_b);
            if data_a(31) = '1' or data_b(31) = '1' then
              v.e.res := repeat('0', 31) & to_std_logic(data_a > data_b);
            else
              v.e.res := repeat('0', 31) & to_std_logic(data_a <= data_b);
            end if;
          when others =>
            v.e.res := (others => '0');
            assert false report "Unknown ALU opcode";
        end case;
      when "0010" =>
        v.e.res := r.d.data_d;
      when "0011" =>
        v.e.res := r.d.data_d(15 downto 0) & data_a(15 downto 0);
      when "1011" =>
        v.e.res := r.d.nextpc;
      when others =>
        v.e.res := (others => '0');
    end case;

    v.e.mem_addr := r.d.data_a + (r.d.data_d(29 downto 0) & "00");

    v.e.reg_dest := r.d.reg_dest;
    v.e.data_x := data_x;
    v.e.reg_write := r.d.reg_write;
    v.e.reg_mem := r.d.reg_mem;
    v.e.mem_write := r.d.mem_write;
    v.e.mem_read := r.d.mem_read;

    if memory_hazard = '1' then
      v.e := r.e;
    end if;

    -- MEMORY

    d_addr := r.e.mem_addr;
    d_val := r.e.data_x;
    d_we := r.e.mem_write;
    d_re := r.e.mem_read;
    v.m.res := r.e.res;
    v.m.reg_dest := r.e.reg_dest;
    v.m.reg_write := r.e.reg_write;
    v.m.reg_mem := r.e.reg_mem;

    if memory_hazard = '1' then
      v.m.reg_write := '0';
    end if;

    -- END

    rin <= v;

    icache_in.addr <= i_addr;
    cpu_out.addr <= d_addr;
    cpu_out.val <= d_val;
    cpu_out.we <= d_we;
    cpu_out.re <= d_re;
  end process;

  regs : process(clk, rst)
  begin
    if rst = '1' then
      r <= rzero;
    elsif rising_edge(clk) then
      r <= rin;
    end if;
  end process;

end architecture;
