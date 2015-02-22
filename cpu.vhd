library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use work.types.all;
use work.util.all;

entity cpu is

  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    cpu_in  : in  cpu_in_type;
    cpu_out : out cpu_out_type);

end entity;

architecture Behavioral of cpu is

  type regfile_type is
    array(0 to 31) of std_logic_vector(31 downto 0);

  type fetch_reg_type is record
    pc      : std_logic_vector(31 downto 0);
    nextpc  : std_logic_vector(31 downto 0);
    i_stall : std_logic;
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
    regfile : regfile_type;
    f       : fetch_reg_type;
    d       : decode_reg_type;
    e       : execute_reg_type;
    m       : memory_reg_type;
  end record;

  constant fzero : fetch_reg_type := (
    pc      => (others => '0'),
    nextpc  => (others => '0'),
    i_stall => '0'
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
    regfile => (others => (others => '0')),
    f       => fzero,
    d       => dzero,
    e       => ezero,
    m       => mzero
    );

  signal r, rin : reg_type := rzero;


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
    elsif r.m.reg_write = '1' and r.m.reg_dest /= "00000" and r.m.reg_dest = reg_src then
      if r.m.reg_mem = '1' then
        res := cpu_in.d_data;
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

    variable opcode : std_logic_vector(3 downto 0);
    variable reg_x  : std_logic_vector(4 downto 0);
    variable reg_a  : std_logic_vector(4 downto 0);
    variable reg_b  : std_logic_vector(4 downto 0);

  begin

    -- micro decoder
    opcode := inst(31 downto 28);
    reg_x := inst(27 downto 23);
    reg_a := inst(22 downto 18);
    case opcode is
      when OP_ALU | OP_FPU =>
        reg_b := inst(17 downto 13);
      when others =>
        reg_b := "00000";
    end case;

    stall := '0';

    -- load stall
    if r.d.mem_read = '1' and r.d.reg_dest /= "00000" and (r.d.reg_dest = reg_a or r.d.reg_dest = reg_b) then
      stall := '1';
    end if;

    -- branch hazard
    case opcode is
      when OP_BNE | OP_BEQ =>
        if r.d.reg_write = '1' and r.d.reg_dest /= "00000" and (r.d.reg_dest = reg_x or r.d.reg_dest = reg_a) then
          stall := '1';
        end if;
        if r.e.reg_write = '1' and r.e.reg_dest /= "00000" and (r.e.reg_dest = reg_x or r.e.reg_dest = reg_a) then
          stall := '1';
        end if;
      when OP_JR =>
        if r.d.reg_write = '1' and r.d.reg_dest /= "00000" and r.d.reg_dest = reg_x then
          stall := '1';
        end if;
        if r.e.reg_write = '1' and r.e.reg_dest /= "00000" and r.e.reg_dest = reg_x then
          stall := '1';
        end if;
      when others =>
    end case;
  end procedure;


  procedure detect_branch (
    inst    : in  std_logic_vector(31 downto 0);
    data_x  : in  std_logic_vector(31 downto 0);
    data_a  : in  std_logic_vector(31 downto 0);
    pc_src  : out std_logic;            -- value of pc_src may be wrong during stall
    pc_addr : out std_logic_vector(31 downto 0)) is

    variable fd_data_x : std_logic_vector(31 downto 0);
    variable fd_data_a : std_logic_vector(31 downto 0);

  begin

    fd_data_x := data_x;
    fd_data_a := data_a;

    d_data_forward(inst(27 downto 23), fd_data_x);
    d_data_forward(inst(22 downto 18), fd_data_a);

    case inst(31 downto 28) is
      when OP_JL | OP_BNE | OP_BEQ =>
        pc_addr := r.f.nextpc + (repeat(inst(15), 14) & inst(15 downto 0) & "00");
      when OP_JR =>
        pc_addr := fd_data_x;
      when others =>
        pc_addr := (others => '-');
    end case;

    case inst(31 downto 28) is
      when OP_JL | OP_JR =>
        pc_src := '1';
      when OP_BNE =>
        pc_src := to_std_logic(fd_data_x /= fd_data_a);
      when OP_BEQ =>
        pc_src := to_std_logic(fd_data_x = fd_data_a);
      when others =>
        pc_src := '0';
    end case;

  end procedure;


begin

  comb : process(r, cpu_in)
    variable v : reg_type;

    -- decode
    variable inst : std_logic_vector(31 downto 0);
    variable stall : std_logic;
    variable pc_addr : std_logic_vector(31 downto 0);
    variable pc_src : std_logic;

    -- write
    variable res : std_logic_vector(31 downto 0);

    -- execute
    variable data_a : std_logic_vector(31 downto 0);
    variable data_b : std_logic_vector(31 downto 0);
    variable data_x : std_logic_vector(31 downto 0);

    -- external
    variable i_addr : std_logic_vector(31 downto 0);
    variable i_re : std_logic;
    variable d_addr : std_logic_vector(31 downto 0);
    variable d_val : std_logic_vector(31 downto 0);
    variable d_we : std_logic;
    variable d_re : std_logic;
  begin
    v := r;

    -- WRITE

    if r.m.reg_mem = '1' then
      res := cpu_in.d_data;
    else
      res := r.m.res;
    end if;

    if r.m.reg_write = '1' then
      for i in 1 to 31 loop
        if r.m.reg_dest = i then
          v.regfile(i) := res;
        end if;
      end loop;
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

    if cpu_in.d_stall = '1' then
      v.m.reg_write := '0';
    end if;

    -- EXECUTE

    e_data_forward(r.d.reg_a, r.d.data_a, data_a);
    e_data_forward(r.d.reg_b, r.d.data_b, data_b);
    e_data_forward(r.d.reg_dest, r.d.data_x, data_x);

    case r.d.opcode is
      when OP_ALU =>
        case r.d.tag is
          when ALU_ADD =>
            v.e.res := data_a + data_b + r.d.data_l;
          when ALU_SUB =>
            v.e.res := data_a - data_b - r.d.data_l;
          when ALU_SHL =>
            v.e.res := std_logic_vector(shift_left(unsigned(data_a), conv_integer(data_b + r.d.data_l)));
          when ALU_SHR =>
            v.e.res := std_logic_vector(shift_right(unsigned(data_a), conv_integer(data_b + r.d.data_l)));
          when ALU_SAR =>
            v.e.res := std_logic_vector(shift_right(signed(data_a), conv_integer(data_b + r.d.data_l)));
          when ALU_AND =>
            v.e.res := data_a and data_b and r.d.data_l;
          when ALU_OR =>
            v.e.res := data_a or data_b or r.d.data_l;
          when ALU_XOR =>
            v.e.res := data_a xor data_b xor r.d.data_l;
          when ALU_CMPNE =>
            v.e.res := repeat('0', 31) & to_std_logic(data_a /= data_b + r.d.data_l);
          when ALU_CMPEQ =>
            v.e.res := repeat('0', 31) & to_std_logic(data_a = data_b + r.d.data_l);
          when ALU_CMPLT =>
            v.e.res := repeat('0', 31) & to_std_logic(signed(data_a) < signed(data_b + r.d.data_l));
          when ALU_CMPLE =>
            v.e.res := repeat('0', 31) & to_std_logic(signed(data_a) <= signed(data_b + r.d.data_l));
          when ALU_FCMPNE =>
            normalize_fzero(data_a);
            normalize_fzero(data_b);
            v.e.res := repeat('0', 31) & to_std_logic(data_a /= data_b);
          when ALU_FCMPEQ =>
            normalize_fzero(data_a);
            normalize_fzero(data_b);
            v.e.res := repeat('0', 31) & to_std_logic(data_a = data_b);
          when ALU_FCMPLT =>
            normalize_fzero(data_a);
            normalize_fzero(data_b);
            if data_a(31) = '1' or data_b(31) = '1' then
              v.e.res := repeat('0', 31) & to_std_logic(data_a >= data_b);
            else
              v.e.res := repeat('0', 31) & to_std_logic(data_a < data_b);
            end if;
          when ALU_FCMPLE =>
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
      when OP_LDL =>
        v.e.res := r.d.data_d;
      when OP_LDH =>
        v.e.res := r.d.data_d(15 downto 0) & data_a(15 downto 0);
      when OP_JL =>
        v.e.res := r.d.nextpc;
      when others =>
        v.e.res := (others => '0');
    end case;

    v.e.mem_addr := data_a + (r.d.data_d(29 downto 0) & "00");

    v.e.reg_dest := r.d.reg_dest;
    v.e.data_x := data_x;
    v.e.reg_write := r.d.reg_write;
    v.e.reg_mem := r.d.reg_mem;
    v.e.mem_write := r.d.mem_write;
    v.e.mem_read := r.d.mem_read;

    if cpu_in.d_stall = '1' then
      v.e := r.e;
    end if;

    -- DECODE

    if r.f.i_stall = '0' then
      inst := cpu_in.i_data;
    else
      inst := (others => '0');
    end if;

    v.d.opcode   := inst(31 downto 28);
    v.d.reg_dest := inst(27 downto 23);
    v.d.reg_a    := inst(22 downto 18);
    v.d.reg_b    := inst(17 downto 13);
    v.d.data_x   := v.regfile(conv_integer(inst(27 downto 23)));
    v.d.data_a   := v.regfile(conv_integer(inst(22 downto 18)));
    v.d.data_b   := v.regfile(conv_integer(inst(17 downto 13)));
    v.d.data_l   := repeat(inst(12), 24) & inst(12 downto 5);
    v.d.data_d   := repeat(inst(15), 16) & inst(15 downto 0);
    v.d.tag      := inst(4 downto 0);

    v.d.nextpc := r.f.nextpc;

    case inst(31 downto 28) is
      when OP_ALU | OP_FPU | OP_LDL | OP_LDH | OP_LD | OP_JL =>
        v.d.reg_write := '1';
      when others =>
        v.d.reg_write := '0';
    end case;
    v.d.reg_mem   := to_std_logic(inst(31 downto 28) = OP_LD);
    v.d.mem_write := to_std_logic(inst(31 downto 28) = OP_ST);
    v.d.mem_read  := to_std_logic(inst(31 downto 28) = OP_LD);

    --// take care of hazards
    detect_hazard(inst, stall);
    detect_branch(inst, v.d.data_x, v.d.data_a, pc_src, pc_addr);

    if cpu_in.d_stall = '1' then
      v.d := r.d;
    elsif stall = '1' then
      v.d.reg_write := '0';
      v.d.mem_write := '0';
      v.d.mem_read := '0';
    end if;

    -- FETCH

    i_re := '1';

    if stall = '1' or cpu_in.d_stall = '1' then
      i_addr := r.f.pc;
    elsif pc_src = '1' then
      i_addr := pc_addr;
    else
      i_addr := r.f.nextpc;
    end if;

    v.f.pc := i_addr;

    if cpu_in.i_stall = '1' then
      v.f.nextpc := i_addr;
    else
      v.f.nextpc := i_addr + 4;
    end if;

    v.f.i_stall := cpu_in.i_stall;

    -- END

    rin <= v;

    cpu_out.i_addr <= i_addr;
    cpu_out.i_re   <= i_re;
    cpu_out.d_addr <= d_addr;
    cpu_out.d_data <= d_val;
    cpu_out.d_we   <= d_we;
    cpu_out.d_re   <= d_re;
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
