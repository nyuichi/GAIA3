library IEEE;
use IEEE.std_logic_1164.all;

package types is

  -- cpu

  type cpu_in_type is record
    i_stall   : std_logic;
    i_data    : std_logic_vector(31 downto 0);
    d_stall   : std_logic;
    d_data    : std_logic_vector(31 downto 0);
    int_go    : std_logic;
    int_cause : std_logic_vector(31 downto 0);
    alu_res   : std_logic_vector(31 downto 0);
    fpu_res   : std_logic_vector(31 downto 0);
  end record;

  constant cpu_in_zero : cpu_in_type := (
    i_stall   => '0',
    i_data    => (others => '0'),
    d_stall   => '0',
    d_data    => (others => '0'),
    int_go    => '0',
    int_cause => (others => '0'),
    alu_res   => (others => '0'),
    fpu_res   => (others => '0'));

  type cpu_out_type is record
    i_re   : std_logic;
    i_addr : std_logic_vector(31 downto 0);
    d_re   : std_logic;
    d_we   : std_logic;
    d_b    : std_logic;
    d_data : std_logic_vector(31 downto 0);
    d_addr : std_logic_vector(31 downto 0);
    eoi    : std_logic;
    eoi_id : std_logic_vector(31 downto 0);
    cai    : std_logic;
    vmm_en : std_logic;
    vmm_pd : std_logic_vector(31 downto 0);
    optag  : std_logic_vector(4 downto 0);
    data_a : std_logic_vector(31 downto 0);
    data_b : std_logic_vector(31 downto 0);
    data_l : std_logic_vector(31 downto 0);
  end record;

  constant cpu_out_zero : cpu_out_type := (
    i_re   => '1',
    i_addr => x"80000000",
    d_re   => '0',
    d_we   => '0',
    d_b    => '0',
    d_data => (others => '0'),
    d_addr => (others => '0'),
    eoi    => '0',
    eoi_id => (others => '0'),
    cai    => '0',
    vmm_en => '0',
    vmm_pd => (others => '0'),
    optag  => (others => '0'),
    data_a => (others => '0'),
    data_b => (others => '0'),
    data_l => (others => '0'));

  component cpu is
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      cpu_in  : in  cpu_in_type;
      cpu_out : out cpu_out_type);
  end component;


  -- alu

  type alu_in_type is record
    optag  : std_logic_vector(4 downto 0);
    data_a : std_logic_vector(31 downto 0);
    data_b : std_logic_vector(31 downto 0);
    data_l : std_logic_vector(31 downto 0);
  end record;

  constant alu_in_zero : alu_in_type := (
    optag  => (others => '0'),
    data_a => (others => '0'),
    data_b => (others => '0'),
    data_l => (others => '0'));

  type alu_out_type is record
    res : std_logic_vector(31 downto 0);
  end record;

  constant alu_out_zero : alu_out_type := (
    res => (others => '0'));

  component alu is
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      alu_in  : in  alu_in_type;
      alu_out : out alu_out_type);
  end component;


  -- fpu

  type fpu_in_type is record
    optag  : std_logic_vector(4 downto 0);
    data_a : std_logic_vector(31 downto 0);
    data_b : std_logic_vector(31 downto 0);
  end record;

  constant fpu_in_zero : fpu_in_type := (
    optag  => (others => '0'),
    data_a => (others => '0'),
    data_b => (others => '0'));

  type fpu_out_type is record
    res : std_logic_vector(31 downto 0);
  end record;

  constant fpu_out_zero : fpu_out_type := (
    res => (others => '0'));

  component fpu is
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      fpu_in  : in  fpu_in_type;
      fpu_out : out fpu_out_type);
  end component;


  -- uart

  type uart_out_type is record
    rx     : std_logic_vector(31 downto 0);
    int_go : std_logic;
  end record;

  constant uart_out_zero : uart_out_type := (
    rx     => (others => 'Z'),
    int_go => '0');

  type uart_in_type is record
    we   : std_logic;
    re   : std_logic;
    val  : std_logic_vector(31 downto 0);
    addr : std_logic_vector(31 downto 0);
    eoi  : std_logic;
  end record;

  constant uart_in_zero : uart_in_type := (
    we   => '0',
    re   => '0',
    val  => (others => '0'),
    addr => (others => '0'),
    eoi  => '0');

  component uart is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      uart_in  : in  uart_in_type;
      uart_out : out uart_out_type;
      RS_TX    : out std_logic;
      RS_RX    : in  std_logic);
  end component;


  -- sram

  type sram_out_type is record
    rx : std_logic_vector(31 downto 0);
  end record;

  constant sram_out_zero : sram_out_type := (
    rx => (others => '0'));

  type sram_in_type is record
    addr : std_logic_vector(31 downto 0);
    we : std_logic;
    tx : std_logic_vector(31 downto 0);
  end record;

  constant sram_in_zero : sram_in_type := (
    addr => (others => '0'),
    we   => '0',
    tx   => (others => '0'));

  component sram is
    port (
      clk      : in    std_logic;
      sram_in  : in    sram_in_type;
      sram_out : out   sram_out_type;
      ZD       : inout std_logic_vector(31 downto 0);
      ZDP      : inout std_logic_vector(3 downto 0);
      ZA       : out   std_logic_vector(19 downto 0);
      XWA      : out   std_logic);
  end component;


  -- ram

  type ram_in_type is record
    req1  : std_logic;
    req2  : std_logic;
    data1 : std_logic_vector(31 downto 0);
    data2 : std_logic_vector(31 downto 0);
    addr1 : std_logic_vector(31 downto 0);
    addr2 : std_logic_vector(31 downto 0);
    we1   : std_logic;
    we2   : std_logic;
  end record;

  constant ram_in_zero : ram_in_type := (
    req1  => '0',
    req2  => '0',
    data1 => (others => '0'),
    data2 => (others => '0'),
    addr1 => (others => '0'),
    addr2 => (others => '0'),
    we1   => '0',
    we2   => '0');

  type ram_out_type is record
    grnt1 : std_logic;
    grnt2 : std_logic;
    data1 : std_logic_vector(31 downto 0);
    data2 : std_logic_vector(31 downto 0);
  end record;

  constant ram_out_zero : ram_out_type := (
    grnt1 => '0',
    grnt2 => '0',
    data1 => (others => '0'),
    data2 => (others => '0'));

  component ram is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      ram_in   : in  ram_in_type;
      ram_out  : out ram_out_type;
      sram_in  : out sram_in_type;
      sram_out : in  sram_out_type);
  end component;


  -- data cache

  type dcache_out_type is record
    -- bram
    bram_we   : std_logic;
    bram_di   : std_logic_vector(31 downto 0);
    bram_addr : std_logic_vector(11 downto 0);
    -- ram
    ram_req   : std_logic;
    ram_we    : std_logic;
    ram_data  : std_logic_vector(31 downto 0);
    ram_addr  : std_logic_vector(31 downto 0);
    -- cache
    stall     : std_logic;
    rx        : std_logic_vector(31 downto 0);
  end record;

  constant dcache_out_zero : dcache_out_type := (
    bram_we   => '0',
    bram_di   => (others => '0'),
    bram_addr => (others => '0'),
    ram_req   => '0',
    ram_we    => '0',
    ram_data  => (others => '0'),
    ram_addr  => (others => '0'),
    stall     => '0',
    rx        => (others => 'Z'));

  type dcache_in_type is record
    -- bram
    bram_do  : std_logic_vector(31 downto 0);
    -- ram
    ram_grnt : std_logic;
    ram_data : std_logic_vector(31 downto 0);
    -- cache
    b        : std_logic;
    we       : std_logic;
    re       : std_logic;
    val      : std_logic_vector(31 downto 0);
    addr     : std_logic_vector(31 downto 0);
    cai      : std_logic;
    -- vmm
    vmm_en   : std_logic;
    vmm_pd   : std_logic_vector(31 downto 0);
  end record;

  constant dcache_in_zero : dcache_in_type := (
    bram_do  => (others => '0'),
    ram_grnt => '0',
    ram_data => (others => '0'),
    b        => '0',
    we       => '0',
    re       => '0',
    val      => (others => '0'),
    addr     => (others => '0'),
    cai      => '0',
    vmm_en   => '0',
    vmm_pd   => (others => '0'));

  component dcache is
    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      dcache_in  : in  dcache_in_type;
      dcache_out : out dcache_out_type);
  end component;


  -- inst cache

  type icache_out_type is record
    -- bram
    bram_we   : std_logic;
    bram_di   : std_logic_vector(31 downto 0);
    bram_addr : std_logic_vector(11 downto 0);
    -- ram
    ram_req   : std_logic;
    ram_addr  : std_logic_vector(31 downto 0);
    -- cache
    stall     : std_logic;
    rx        : std_logic_vector(31 downto 0);
  end record;

  constant icache_out_zero : icache_out_type := (
    bram_we   => '0',
    bram_di   => (others => '0'),
    bram_addr => (others => '0'),
    ram_req   => '0',
    ram_addr  => (others => '0'),
    stall     => '0',
    rx        => (others => 'Z'));

  type icache_in_type is record
    -- bram
    bram_do  : std_logic_vector(31 downto 0);
    -- ram
    ram_grnt : std_logic;
    ram_data : std_logic_vector(31 downto 0);
    -- cache
    co_we    : std_logic;
    co_addr  : std_logic_vector(31 downto 0);
    re       : std_logic;
    addr     : std_logic_vector(31 downto 0);
    cai      : std_logic;
    -- vmm
    vmm_en   : std_logic;
    vmm_pd   : std_logic_vector(31 downto 0);
  end record;

  constant icache_in_zero : icache_in_type := (
    bram_do  => (others => '0'),
    ram_grnt => '0',
    ram_data => (others => '0'),
    co_we    => '0',
    co_addr  => (others => '0'),
    re       => '0',
    addr     => (others => '0'),
    cai      => '0',
    vmm_en   => '0',
    vmm_pd   => (others => '0'));

  component icache is
    port (
      clk        : in  std_logic;
      rst        : in  std_logic;
      icache_in  : in  icache_in_type;
      icache_out : out icache_out_type);
  end component;


  -- rom

  type rom_out_type is record
    rx1 : std_logic_vector(31 downto 0);
    rx2 : std_logic_vector(31 downto 0);
  end record;

  constant rom_out_zero : rom_out_type := (
    rx1 => (others => 'Z'),
    rx2 => (others => 'Z'));

  type rom_in_type is record
    addr1 : std_logic_vector(31 downto 0);
    addr2 : std_logic_vector(31 downto 0);
  end record;

  constant rom_in_zero : rom_in_type := (
    addr1 => (others => '0'),
    addr2 => (others => '0'));

  type rom_type is
    array(0 to 4095) of std_logic_vector(31 downto 0);

  component rom is
    port (
      clk     : in  std_logic;
      rom_in  : in  rom_in_type;
      rom_out : out rom_out_type);
  end component;


  -- timer

  type timer_in_type is record
    eoi : std_logic;
  end record;

  type timer_out_type is record
    int_go : std_logic;
  end record;

  constant timer_in_zero : timer_in_type := (
    eoi => '0'
    );

  constant timer_out_zero : timer_out_type := (
    int_go => '0'
    );

  component timer is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        timer_in  : in  timer_in_type;
        timer_out : out timer_out_type);
  end component;


  -- constants

  constant OP_ALU      : std_logic_vector(3 downto 0) := "0000";
  constant OP_FPU      : std_logic_vector(3 downto 0) := "0001";
  constant OP_LDL      : std_logic_vector(3 downto 0) := "0010";
  constant OP_LDH      : std_logic_vector(3 downto 0) := "0011";
  constant OP_JL       : std_logic_vector(3 downto 0) := "0100";
  constant OP_JR       : std_logic_vector(3 downto 0) := "0101";
  constant OP_LD       : std_logic_vector(3 downto 0) := "0110";
  constant OP_LDB      : std_logic_vector(3 downto 0) := "0111";
  constant OP_ST       : std_logic_vector(3 downto 0) := "1000";
  constant OP_STB      : std_logic_vector(3 downto 0) := "1001";
  constant OP_SYSENTER : std_logic_vector(3 downto 0) := "1100";
  constant OP_SYSEXIT  : std_logic_vector(3 downto 0) := "1101";
  constant OP_BNE      : std_logic_vector(3 downto 0) := "1110";
  constant OP_BEQ      : std_logic_vector(3 downto 0) := "1111";

  constant ALU_ADD    : std_logic_vector(4 downto 0) := "00000";
  constant ALU_SUB    : std_logic_vector(4 downto 0) := "00001";
  constant ALU_SHL    : std_logic_vector(4 downto 0) := "00010";
  constant ALU_SHR    : std_logic_vector(4 downto 0) := "00011";
  constant ALU_SAR    : std_logic_vector(4 downto 0) := "00100";
  constant ALU_AND    : std_logic_vector(4 downto 0) := "00101";
  constant ALU_OR     : std_logic_vector(4 downto 0) := "00110";
  constant ALU_XOR    : std_logic_vector(4 downto 0) := "00111";
  constant ALU_CMPULT : std_logic_vector(4 downto 0) := "10110";
  constant ALU_CMPULE : std_logic_vector(4 downto 0) := "10111";
  constant ALU_CMPNE  : std_logic_vector(4 downto 0) := "11000";
  constant ALU_CMPEQ  : std_logic_vector(4 downto 0) := "11001";
  constant ALU_CMPLT  : std_logic_vector(4 downto 0) := "11010";
  constant ALU_CMPLE  : std_logic_vector(4 downto 0) := "11011";
  constant ALU_F2I    : std_logic_vector(4 downto 0) := "11100";
  constant ALU_I2F    : std_logic_vector(4 downto 0) := "11101";
  constant ALU_FCMPLT : std_logic_vector(4 downto 0) := "11110";
  constant ALU_FCMPLE : std_logic_vector(4 downto 0) := "11111";

  constant FPU_FADD : std_logic_vector(4 downto 0) := "00000";
  constant FPU_FSUB : std_logic_vector(4 downto 0) := "00001";
  constant FPU_FMUL : std_logic_vector(4 downto 0) := "00010";

end package;
