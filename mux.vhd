library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

use work.types.all;

entity mux is

  port (
    clk            : in  std_logic;
    rst            : in  std_logic;

    -- inst memory
    cpu_imem_down  : in  imem_down_type;
    cpu_imem_up    : out imem_up_type;
    cpu_imem_stall : out std_logic;

    -- data memory
    cpu_dmem_down  : in  dmem_down_type;
    cpu_dmem_up    : out dmem_up_type;
    cpu_dmem_stall : out std_logic;

    -- uart
    uart_in  : out uart_in_type;
    uart_out : in  uart_out_type;

    -- inst sram cache
    ic_in    : out imem_down_type;
    ic_out   : in  imem_up_type;
    ic_stall : in  std_logic;

    -- data sram cache
    dc_in    : out dmem_down_type;
    dc_out   : in  dmem_up_type;
    dc_stall : in  std_logic;

    -- inst bram
    ib_in  : out imem_down_type;
    ib_out : in  imem_up_type;

    -- data bram
    db_in  : out dmem_down_type;
    db_out : in  dmem_up_type);

end entity;

architecture Behavioral of mux is

  type reg_type is record
    i : imem_down_type;
    d : dmem_down_type;
  end record;

  constant rzero : reg_type := (
    i => imem_down_zero,
    d => dmem_down_zero);

  signal r, rin : reg_type;

begin

  comb : process(r, cpu_imem_down, cpu_dmem_down, uart_out, ic_out, ic_stall, dc_out, dc_stall, ib_out, db_out)
    variable v : reg_type;

    variable v_cpu_imem_stall : std_logic;
    variable v_cpu_dmem_stall : std_logic;
    variable v_cpu_imem_up : imem_up_type;
    variable v_cpu_dmem_up : dmem_up_type;
    variable v_uart_in : uart_in_type;
    variable v_ic_in : imem_down_type;
    variable v_dc_in : dmem_down_type;
    variable v_ib_in : imem_down_type;
    variable v_db_in : dmem_down_type;
  begin
    v := r;

    v_cpu_imem_stall := '0';
    v_cpu_imem_up := imem_up_zero;
    v_ic_in := imem_down_zero;
    v_ib_in := imem_down_zero;

    v_cpu_dmem_stall := '0';
    v_cpu_dmem_up := dmem_up_zero;
    v_uart_in := uart_in_zero;
    v_dc_in := dmem_down_zero;
    v_db_in := dmem_down_zero;

    -- previous req

    if r.i.re = '1' then
      case conv_integer(r.i.addr) is
        when 16#00000000# to 16#00001FFF# =>
          v_cpu_imem_up := ib_out;
        when 16#00003000# to 16#003FFFFF# =>
          v_cpu_imem_up := ic_out;
        when others =>
          assert false report "hoge";
      end case;
    end if;

    if r.d.re = '1' or r.d.we = '1' then
      case conv_integer(r.d.addr) is
        when 16#00000000# to 16#00001FFF# =>
          v_cpu_dmem_up := db_out;
        when 16#00002000# to 16#00002008# =>
          v_cpu_dmem_up.data := uart_out.rx;
        when 16#00003000# to 16#003FFFFF# =>
          v_cpu_dmem_up := dc_out;
        when others =>
          assert false report "hoge";
      end case;
    end if;

    -- current req

    if cpu_imem_down.re = '1' then
      case conv_integer(cpu_imem_down.addr) is
        when 16#00000000# to 16#00001FFF# =>
          v_ib_in := cpu_imem_down;
        when 16#00003000# to 16#003FFFFF# =>
          v_ic_in := cpu_imem_down;
          v_cpu_imem_stall := ic_stall;
        when others =>
          assert false report "fuga";
      end case;
    end if;

    if cpu_dmem_down.re = '1' or cpu_dmem_down.we = '1' then
      case conv_integer(cpu_dmem_down.addr) is
        when 16#00000000# to 16#00001FFF# =>
          v_db_in := cpu_dmem_down;
        when 16#00002000# to 16#00002008# =>
          v_uart_in.we := cpu_dmem_down.we;
          v_uart_in.re := cpu_dmem_down.re;
          v_uart_in.val := cpu_dmem_down.data;
          v_uart_in.addr := cpu_dmem_down.addr;
        when 16#00003000# to 16#003FFFFF# =>
          v_dc_in := cpu_dmem_down;
          v_cpu_dmem_stall := dc_stall;
        when others =>
          assert false report "fuga";
      end case;
    end if;

    v.i := cpu_imem_down;
    v.d := cpu_dmem_down;

    rin <= v;

    cpu_imem_stall <= v_cpu_imem_stall;
    cpu_dmem_stall <= v_cpu_dmem_stall;
    cpu_imem_up    <= v_cpu_imem_up;
    cpu_dmem_up    <= v_cpu_dmem_up;
    uart_in        <= v_uart_in;
    ic_in          <= v_ic_in;
    dc_in          <= v_dc_in;
    ib_in          <= v_ib_in;
    db_in          <= v_db_in;
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
