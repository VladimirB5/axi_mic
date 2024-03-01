LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

library work;
-- Package Declaration Section
package axi_lite_mic_regs_pkg is
  
  -- axi lite reg map registers
  type t_axi_lite_mic_regs is record
    enable    : std_logic;
    run       : std_logic;
    chann_a   : std_logic_vector(31 downto 0);
    chann_b   : std_logic_vector(31 downto 0);
    buff_size : std_logic_vector(7 downto 0);
    int_ena   : std_logic;
    clk_mux   : std_logic;
    test_ena  : std_logic;
  end record t_axi_lite_mic_regs;

  constant C_AXI_LITE_REGS_INIT : t_axi_lite_mic_regs :=
            (enable    => '0',
             run       => '0',
             chann_a   => (others => '0'),
             chann_b   => (others => '0'),
             buff_size => (others => '0'),
             int_ena   => '0',
             clk_mux   => '0',
             test_ena  => '0');

    -- reg addresses
  CONSTANT  C_ADDR_ENABLE    : std_logic_vector(3 downto 0) := "0000";
  CONSTANT  C_ADDR_RUN       : std_logic_vector(3 downto 0) := "0001";
  CONSTANT  C_ADDR_CHANN_A   : std_logic_vector(3 downto 0) := "0010";
  CONSTANT  C_ADDR_CHANN_B   : std_logic_vector(3 downto 0) := "0011";
  CONSTANT  C_ADDR_BUFF_SIZE : std_logic_vector(3 downto 0) := "0100";
  CONSTANT  C_ADDR_NUM_BYTES : std_logic_vector(3 downto 0) := "0101";
  CONSTANT  C_ADDR_INT_ENA   : std_logic_vector(3 downto 0) := "0110";
  CONSTANT  C_ADDR_INT_STS   : std_logic_vector(3 downto 0) := "0111";
  CONSTANT  C_ADDR_TEST_CTRL : std_logic_vector(3 downto 0) := "1000";
  CONSTANT  C_ADDR_TEST_READ : std_logic_vector(3 downto 0) := "1001";
      
end package axi_lite_mic_regs_pkg;
