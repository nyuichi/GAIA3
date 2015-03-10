library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

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
    pc     : std_logic_vector(31 downto 0);
    nextpc : std_logic_vector(31 downto 0);
    bubble : std_logic;
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
    res_unit  : integer range 0 to 2;
    mem_write : std_logic;
    mem_read  : std_logic;
    mem_byte  : std_logic;
    pc_addr   : std_logic_vector(31 downto 0);
    pc_src    : std_logic;
  end record;

  type execute_reg_type is record
    res       : std_logic_vector(31 downto 0);
    mem_addr  : std_logic_vector(31 downto 0);
    reg_dest  : std_logic_vector(4 downto 0);
    reg_write : std_logic;
    res_unit  : integer range 0 to 2;
    mem_write : std_logic;
    mem_read  : std_logic;
    mem_byte  : std_logic;
  end record;

  type memory_reg_type is record
    res       : std_logic_vector(31 downto 0);
    reg_dest  : std_logic_vector(4 downto 0);
    reg_write : std_logic;
    reg_mem   : std_logic;
  end record;

  type flag_type is record
    int_en      : std_logic;
    int_pc      : std_logic_vector(31 downto 0);
    int_cause   : std_logic_vector(31 downto 0);
    int_handler : std_logic_vector(31 downto 0);
    vmm_en      : std_logic;
    vmm_pd      : std_logic_vector(31 downto 0);
  end record;

  type reg_type is record
    regfile : regfile_type;
    f       : fetch_reg_type;
    d       : decode_reg_type;
    e       : execute_reg_type;
    m       : memory_reg_type;
    flag    : flag_type;
    eoi     : std_logic;
  end record;

  constant fzero : fetch_reg_type := (
    pc     => (others => '0'),
    nextpc => x"80000000",
    bubble => '0'
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
    res_unit  => 0,
    mem_write => '0',
    mem_read  => '0',
    mem_byte  => '0',
    pc_addr   => (others => '0'),
    pc_src    => '0'
    );

  constant ezero : execute_reg_type := (
    res       => (others => '0'),
    mem_addr  => (others => '0'),
    reg_dest  => "00000",
    reg_write => '0',
    res_unit  => 0,
    mem_write => '0',
    mem_read  => '0',
    mem_byte  => '0'
    );

  constant mzero : memory_reg_type := (
    res       => (others => '0'),
    reg_dest  => "00000",
    reg_write => '0',
    reg_mem   => '0'
    );

  constant flag_zero : flag_type := (
    int_en      => '0',
    int_pc      => (others => '0'),
    int_cause   => (others => '0'),
    int_handler => (others => '0'),
    vmm_en      => '0',
    vmm_pd      => (others => '0')
    );

  constant rzero : reg_type := (
    regfile => (others => (others => '0')),
    f       => fzero,
    d       => dzero,
    e       => ezero,
    m       => mzero,
    flag    => flag_zero,
    eoi     => '0'
    );

  signal r, rin : reg_type := rzero;


  procedure data_forward (
    reg_src  : in  std_logic_vector(4 downto 0);
    reg_data : in  std_logic_vector(31 downto 0);
    res      : out std_logic_vector(31 downto 0)) is
  begin
    if r.e.reg_write = '1' and r.e.reg_dest /= "00000" and r.e.reg_dest = reg_src then
      case r.e.res_unit is
        when 0 =>
          res := r.e.res;
        when 1 =>
          res := cpu_in.alu_res;
        when 2 =>
          res := cpu_in.fpu_res;
        when others =>
          assert false severity failure;
      end case;
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
    reg_x  := inst(27 downto 23);
    reg_a  := inst(22 downto 18);
    case opcode is
      when OP_ALU | OP_FPU =>
        reg_b := inst(17 downto 13);
      when others =>
        reg_b := "00000";
    end case;

    stall := '0';

    -- load stall
    case opcode is
      when OP_ST | OP_STB =>
        if r.d.mem_read = '1' and r.d.reg_dest /= "00000" and (r.d.reg_dest = reg_x or r.d.reg_dest = reg_a) then
          stall := '1';
        end if;
      when others =>
        if r.d.mem_read = '1' and r.d.reg_dest /= "00000" and (r.d.reg_dest = reg_a or r.d.reg_dest = reg_b) then
          stall := '1';
        end if;
    end case;

    -- branch hazard
    case opcode is
      when OP_BNE | OP_BEQ =>
        if r.d.reg_write = '1' and r.d.reg_dest /= "00000" and (r.d.reg_dest = reg_x or r.d.reg_dest = reg_a) then
          stall := '1';
        end if;
        if r.e.mem_read = '1' and r.e.reg_dest /= "00000" and (r.e.reg_dest = reg_x or r.e.reg_dest = reg_a) then
          stall := '1';
        end if;
      when OP_JR =>
        if r.d.reg_write = '1' and r.d.reg_dest /= "00000" and r.d.reg_dest = reg_a then
          stall := '1';
        end if;
        if r.e.mem_read = '1' and r.e.reg_dest /= "00000" and r.e.reg_dest = reg_a then
          stall := '1';
        end if;
      when OP_SYSENTER | OP_SYSEXIT =>
        if r.d.mem_write = '1' or r.d.mem_read = '1' then
          stall := '1';
        end if;
      when others =>
    end case;

    -- interrupt hazard
    if cpu_in.int_go = '1' then
      if r.d.mem_write = '1' or r.d.mem_read = '1' then
        stall := '1';
      end if;
    end if;

  end procedure;


  procedure detect_branch (
    inst    : in  std_logic_vector(31 downto 0);
    regfile : in  regfile_type;
    int_hdr : in  std_logic_vector(31 downto 0);
    int_pc  : in  std_logic_vector(31 downto 0);
    pc_src  : out std_logic;
    pc_addr : out std_logic_vector(31 downto 0)) is

    variable opcode : std_logic_vector(3 downto 0);
    variable reg_x  : std_logic_vector(4 downto 0);
    variable reg_a  : std_logic_vector(4 downto 0);
    variable data_x : std_logic_vector(31 downto 0);
    variable data_a : std_logic_vector(31 downto 0);

  begin

    opcode := inst(31 downto 28);
    reg_x  := inst(27 downto 23);
    reg_a  := inst(22 downto 18);

    -- forwarding, but results may be wrong...
    if r.e.reg_write = '1' and r.e.reg_dest /= "00000" and r.e.reg_dest = reg_x then
      case r.e.res_unit is
        when 0 =>
          data_x := r.e.res;
        when 1 =>
          data_x := cpu_in.alu_res;
        when 2 =>
          data_x := cpu_in.fpu_res;
        when others =>
          assert false severity failure;
      end case;
    else
      data_x := regfile(conv_integer(reg_x));
    end if;

    if r.e.reg_write = '1' and r.e.reg_dest /= "00000" and r.e.reg_dest = reg_a then
      case r.e.res_unit is
        when 0 =>
          data_a := r.e.res;
        when 1 =>
          data_a := cpu_in.alu_res;
        when 2 =>
          data_a := cpu_in.fpu_res;
        when others =>
          assert false severity failure;
      end case;
    else
      data_a := regfile(conv_integer(reg_a));
    end if;

    case opcode is
      when OP_JL | OP_BNE | OP_BEQ =>
        pc_addr := r.f.nextpc + (repeat(inst(15), 14) & inst(15 downto 0) & "00");
      when OP_JR =>
        pc_addr := data_a;
      when OP_SYSENTER =>
        pc_addr := int_hdr;
      when OP_SYSEXIT =>
        pc_addr := int_pc;
      when others =>
        pc_addr := (others => '-');
    end case;

    case opcode is
      when OP_JL | OP_JR | OP_SYSENTER | OP_SYSEXIT =>
        pc_src := '1';
      when OP_BNE =>
        pc_src := to_std_logic(data_x /= data_a);
      when OP_BEQ =>
        pc_src := to_std_logic(data_x = data_a);
      when others =>
        pc_src := '0';
    end case;

  end procedure;


  procedure detect_interrupt (
    int_en : in  std_logic;
    eoi    : out std_logic) is
  begin
    if r.eoi = '0' and int_en = '1' and cpu_in.int_go = '1' then
      eoi := '1';
    else
      eoi := '0';
    end if;
  end procedure;


  procedure memory_flag (
    addr : in  std_logic_vector(31 downto 0);
    re   : in  std_logic;
    we   : in  std_logic;
    val  : in  std_logic_vector(31 downto 0);
    flag : out flag_type;
    res  : out std_logic_vector(31 downto 0);
    cai  : out std_logic) is
  begin

    flag := r.flag;

    cai := '0';

    case addr is
      when x"80001100" =>
        if re = '1' then
          res := r.flag.int_handler;
        end if;
        if we = '1' then
          flag.int_handler := val;
        end if;
      when x"80001104" =>
        if re = '1' then
          res := repeat('0', 31) & r.flag.int_en;
        end if;
        if we = '1' then
          flag.int_en := val(0);
        end if;
      when x"80001108" =>
        if re = '1' then
          res := r.flag.int_pc;
        end if;
        if we = '1' then
          flag.int_pc := val;
        end if;
      when x"8000110C" =>
        if re = '1' then
          res := r.flag.int_cause;
        end if;
        if we = '1' then
          flag.int_cause := val;
        end if;
      when x"80001200" =>
        if re = '1' then
          res := repeat('0', 31) & r.flag.vmm_en;
        end if;
        if we = '1' then
          flag.vmm_en := val(0);
          cai := '1';
        end if;
      when x"80001204" =>
        if re = '1' then
          res := r.flag.vmm_pd;
        end if;
        if we = '1' then
          flag.vmm_pd := val;
          cai := '1';
        end if;
      when others =>
    end case;

  end procedure;


begin

  comb : process(r, cpu_in)
    variable v : reg_type;

    -- decode
    variable inst : std_logic_vector(31 downto 0);
    variable stall : std_logic;

    -- write
    variable res : std_logic_vector(31 downto 0);

    -- execute
    variable data_a  : std_logic_vector(31 downto 0);
    variable data_b  : std_logic_vector(31 downto 0);
    variable data_x  : std_logic_vector(31 downto 0);
    variable data_bl : std_logic_vector(31 downto 0);

    -- external
    variable i_addr : std_logic_vector(31 downto 0);
    variable i_re   : std_logic;
    variable d_addr : std_logic_vector(31 downto 0);
    variable d_val  : std_logic_vector(31 downto 0);
    variable d_we   : std_logic;
    variable d_re   : std_logic;
    variable d_b    : std_logic;
    variable cai    : std_logic;
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
    d_val  := r.e.res;
    d_we   := r.e.mem_write;
    d_re   := r.e.mem_read;
    d_b    := r.e.mem_byte;

    case r.e.res_unit is
      when 0 =>
        v.m.res := r.e.res;
      when 1 =>
        v.m.res := cpu_in.alu_res;
      when 2 =>
        v.m.res := cpu_in.fpu_res;
      when others =>
        assert false severity failure;
    end case;

    if x"80001100" <= d_addr and d_addr < x"80002000" then
      v.m.reg_mem := '0';
    else
      v.m.reg_mem := r.e.mem_read;
    end if;

    memory_flag(d_addr, d_re, d_we, d_val, v.flag, v.m.res, cai);

    v.m.reg_dest  := r.e.reg_dest;
    v.m.reg_write := r.e.reg_write;

    if cpu_in.d_stall = '1' then
      v.m.reg_write := '0';
    end if;

    -- EXECUTE

    data_forward(r.d.reg_a, r.d.data_a, data_a);
    data_forward(r.d.reg_b, r.d.data_b, data_b);
    data_forward(r.d.reg_dest, r.d.data_x, data_x);

    case r.d.opcode is
      when OP_LDL =>
        v.e.res := r.d.data_d;
      when OP_LDH =>
        v.e.res := r.d.data_d(15 downto 0) & data_a(15 downto 0);
      when OP_JL | OP_JR =>
        v.e.res := r.d.nextpc;
      when OP_ST | OP_STB =>
        v.e.res := data_x;
      when others =>
        v.e.res := (others => '0');
    end case;

    if r.d.mem_byte = '1' then
      v.e.mem_addr := data_a + r.d.data_d;
    else
      v.e.mem_addr := data_a + (r.d.data_d(29 downto 0) & "00");
    end if;

    v.e.reg_dest  := r.d.reg_dest;
    v.e.res_unit  := r.d.res_unit;
    v.e.reg_write := r.d.reg_write;
    v.e.mem_write := r.d.mem_write;
    v.e.mem_read  := r.d.mem_read;
    v.e.mem_byte  := r.d.mem_byte;

    if cpu_in.d_stall = '1' then
      v.e := r.e;
    elsif r.eoi = '1' then
      v.e.reg_write := '0';
      v.e.mem_write := '0';
      v.e.mem_read  := '0';
    end if;

    -- DECODE

    if r.f.bubble = '1' then
      inst := (others => '0');
    else
      inst := cpu_in.i_data;
    end if;

--pragma synthesis_off
    if is_x(inst) then
      inst := (others => '0');
    end if;
--pragma synthesis_on

    v.d.opcode   := inst(31 downto 28);
    v.d.reg_dest := inst(27 downto 23);
    v.d.reg_a    := inst(22 downto 18);
    v.d.reg_b    := inst(17 downto 13);
    v.d.data_l   := repeat(inst(12), 24) & inst(12 downto 5);
    v.d.data_d   := repeat(inst(15), 16) & inst(15 downto 0);
    v.d.tag      := inst(4 downto 0);

    v.d.nextpc := r.f.nextpc;

    case v.d.opcode is
      when OP_ALU | OP_FPU | OP_LDL | OP_LDH | OP_LD | OP_LDB | OP_JL | OP_JR =>
        v.d.reg_write := '1';
      when others =>
        v.d.reg_write := '0';
    end case;
    case v.d.opcode is
      when OP_ALU =>
        v.d.res_unit := 1;
      when OP_FPU =>
        v.d.res_unit := 2;
      when others =>
        v.d.res_unit := 0;
    end case;
    v.d.mem_write := to_std_logic(v.d.opcode = OP_ST or v.d.opcode = OP_STB);
    v.d.mem_read  := to_std_logic(v.d.opcode = OP_LD or v.d.opcode = OP_LDB);
    v.d.mem_byte  := to_std_logic(v.d.opcode = OP_LDB or v.d.opcode = OP_STB);

    detect_hazard(inst, stall);
    detect_branch(inst, v.regfile, v.flag.int_handler, v.flag.int_pc, v.d.pc_src, v.d.pc_addr);
    detect_interrupt(v.flag.int_en, v.eoi);

    if cpu_in.d_stall = '1' then
      v.d := r.d;
      v.eoi := '0';
    elsif stall = '1' or r.d.pc_src = '1' or r.eoi = '1' then
      v.d.reg_write := '0';
      v.d.mem_write := '0';
      v.d.mem_read := '0';
      v.d.pc_src := '0';
      v.eoi := '0';
    else
      if v.eoi = '1' then
        v.flag.int_cause := cpu_in.int_cause;
        v.flag.int_pc    := r.f.nextpc;
        v.flag.int_en    := '0';
      elsif v.d.opcode = OP_SYSENTER then
        v.flag.int_cause := x"00000003";
        v.flag.int_pc    := r.f.nextpc + 4;
        v.flag.int_en    := '0';
      elsif v.d.opcode = OP_SYSEXIT then
        v.flag.int_en := '1';
      end if;
    end if;

    --// see http://goo.gl/dhJQ69 for detail
    v.d.data_x := v.regfile(conv_integer(v.d.reg_dest));
    v.d.data_a := v.regfile(conv_integer(v.d.reg_a));
    v.d.data_b := v.regfile(conv_integer(v.d.reg_b));

    -- FETCH

    i_re := '1';

    if r.eoi = '1' then
      i_addr := r.flag.int_handler;
    elsif stall = '1' or cpu_in.d_stall = '1' then
      i_addr := r.f.pc;
    elsif r.d.pc_src = '1' then
      i_addr := r.d.pc_addr;
    elsif r.f.bubble = '1' then
      i_addr := r.f.pc;
    else
      i_addr := r.f.nextpc;
    end if;

    v.f.pc := i_addr;
    v.f.nextpc := i_addr + 4;

    v.f.bubble := cpu_in.i_stall;

    -- END

    rin <= v;

    cpu_out.i_addr <= i_addr;
    cpu_out.i_re   <= i_re;
    cpu_out.d_addr <= d_addr;
    cpu_out.d_data <= d_val;
    cpu_out.d_we   <= d_we;
    cpu_out.d_re   <= d_re;
    cpu_out.d_b    <= d_b;
    cpu_out.eoi    <= r.eoi;
    cpu_out.eoi_id <= r.flag.int_cause;
    cpu_out.cai    <= cai;
    cpu_out.vmm_en <= r.flag.vmm_en;
    cpu_out.vmm_pd <= r.flag.vmm_pd;
    cpu_out.optag  <= r.d.tag;
    cpu_out.data_a <= data_a;
    cpu_out.data_b <= data_b;
    cpu_out.data_l <= r.d.data_l;
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
