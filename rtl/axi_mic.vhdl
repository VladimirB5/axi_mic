LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

--library work;

entity axi_mic IS
  generic (
    G_TEST : boolean := TRUE -- diagnostig logic added
  );
  port (
    -- clocks and resets
  clk_f               : IN std_logic; -- fast clock expecte at 100 Mhz
  rst_n               : IN std_logic;

  clk_s               : IN std_logic; -- slow clock at 2.5Mhz

  -- AXI lite
  AXI_L_ACLK           : IN std_logic;
  -- write adress channel
  AXI_L_AWVALID        : IN std_logic;
  AXI_L_AWREADY        : OUT std_logic;
  AXI_L_AWADDR         : IN std_logic_vector(31 downto 0);
  AXI_L_AWPROT         : IN std_logic_vector(2 downto 0);
  -- write data channel
  AXI_L_WVALID         : IN std_logic;
  AXI_L_WREADY         : OUT std_logic;
  AXI_L_WDATA          : IN std_logic_vector(31 downto 0);
  AXI_L_WSTRB          : IN std_logic_vector(3 downto 0); -- C_S_AXI_DATA_WIDTH/8)-1 : 0
  -- write response channel
  AXI_L_BVALID         : OUT std_logic;
  AXI_L_BREADY         : IN std_logic;
  AXI_L_BRESP          : OUT std_logic_vector(1 downto 0);
  -- read address channel
  AXI_L_ARVALID        : IN  std_logic;
  AXI_L_ARREADY        : OUT std_logic;
  AXI_L_ARADDR         : IN std_logic_vector(31 downto 0);
  AXI_L_ARPROT         : IN std_logic_vector(2 downto 0);
  -- read data channel
  AXI_L_RVALID         : OUT std_logic;
  AXI_L_RREADY         : IN std_logic;
  AXI_L_RDATA          : OUT std_logic_vector(31 downto 0);
  AXI_L_RRESP          : OUT std_logic_vector(1 downto 0);

  -- AXI HP
  AXI_HP_ACLK          : IN std_logic;
  -- write adress channel
  AXI_HP_AWADDR        : OUT std_logic_vector(31 downto 0);
  AXI_HP_AWVALID       : OUT std_logic;
  AXI_HP_AWREADY       : IN  std_logic;
  AXI_HP_AWID          : OUT std_logic_vector(5 downto 0);
  AXI_HP_AWLOCK        : OUT std_logic_vector(1 downto 0);
  AXI_HP_AWCACHE       : OUT std_logic_vector(3 downto 0);
  AXI_HP_AWPROT        : OUT std_logic_vector(2 downto 0);
  AXI_HP_AWLEN         : OUT std_logic_vector(3 downto 0);
  AXI_HP_AWSIZE        : OUT std_logic_vector(2 downto 0);
  AXI_HP_AWBURST       : OUT std_logic_vector(1 downto 0);
  AXI_HP_AWQOS         : OUT std_logic_vector(3 downto 0);
  -- write data channel
  AXI_HP_WDATA         : OUT std_logic_vector(63 downto 0);
  AXI_HP_WVALID        : OUT std_logic;
  AXI_HP_WREADY        : IN  std_logic;
  AXI_HP_WID           : OUT std_logic_vector(5 downto 0);
  AXI_HP_WLAST         : OUT std_logic;
  AXI_HP_WSTRB         : OUT std_logic_vector(7 downto 0);
  AXI_HP_WCOUNT        : IN  std_logic_vector(7 downto 0);
  AXI_HP_WACOUNT       : IN  std_logic_vector(5 downto 0);
  AXI_HP_WRISSUECAP1EN : OUT std_logic;
  -- write response channel
  AXI_HP_BVALID        : IN  std_logic;
  AXI_HP_BREADY        : OUT std_logic;
  AXI_HP_BID           : IN  std_logic_vector(5 downto 0);
  AXI_HP_BRESP         : IN  std_logic_vector(1 downto 0);
  -- read address channel
  AXI_HP_ARADDR        : OUT std_logic_vector(31 downto 0);
  AXI_HP_ARVALID       : OUT std_logic;
  AXI_HP_ARREADY       : IN  std_logic;
  AXI_HP_ARID          : OUT std_logic_vector(5 downto 0);
  AXI_HP_ARLOCK        : OUT std_logic_vector(1 downto 0);
  AXI_HP_ARCACHE       : OUT std_logic_vector(3 downto 0);
  AXI_HP_ARPROT        : OUT std_logic_vector(2 downto 0);
  AXI_HP_ARLEN         : OUT std_logic_vector(3 downto 0);
  AXI_HP_ARSIZE        : OUT std_logic_vector(2 downto 0);
  AXI_HP_ARBURST       : OUT std_logic_vector(1 downto 0);
  AXI_HP_ARQOS         : OUT std_logic_vector(3 downto 0);
  -- read data channel
  AXI_HP_RDATA         : IN  std_logic_vector(63 downto 0);
  AXI_HP_RVALID        : IN  std_logic;
  AXI_HP_RREADY        : OUT std_logic;
  AXI_HP_RID           : IN  std_logic_vector(5 downto 0);
  AXI_HP_RLAST         : IN  std_logic;
  AXI_HP_RRESP         : IN  std_logic_vector(1 downto 0);
  AXI_HP_RCOUNT        : IN  std_logic_vector(7 downto 0);
  AXI_HP_RACOUNT       : IN  std_logic_vector(2 downto 0);
  AXI_HP_RDISSUECAP1EN : OUT std_logic;

  -- mic
  audio_clk            : OUT std_logic;
  audio_do             : IN std_logic;

  -- mic int
  mic_int              : out std_logic
  );
END ENTITY axi_mic;

ARCHITECTURE rtl OF axi_mic IS

COMPONENT audio_aquire IS
  generic (
    G_TEST : boolean -- if mux is use
  );
  port (
   rst_n : in std_logic;
   clk   : in std_logic;
   en    : in std_logic;
   
   run      : in std_logic;
   test_en  : in std_logic;
   audio_in : in std_logic;
   data_w   : OUT std_logic_vector(63 downto 0);
   we       : OUT std_logic;
   fifo_full: IN std_logic);
END COMPONENT audio_aquire;

COMPONENT fifo IS
  port (
    -- 100 mhz port
    clk_100 : IN std_logic; -- 100Mhz clk
    rst_100n: IN std_logic; -- active in 0
    re      : IN std_logic;
    sa_rstn : IN std_logic; -- sw reset a
    full_r  : OUT std_logic;
    empty   : OUT std_logic;
    data_r  : OUT std_logic_vector(63 downto 0);
    -- 25 mhz port
    clk_25  : IN  std_logic;
    rst_25n : IN  std_logic;
    sb_rstn : IN  std_logic; -- sw reset b
    data_w  : IN  std_logic_vector(63 downto 0);
    we      : IN  std_logic;
    full_w  : OUT std_logic
  );
END COMPONENT fifo;

COMPONENT axi_hp_mic IS
  port (
  en      : IN std_logic;
  -- AXI signals
  -- Global signals
  ACLK    : IN std_logic;
  ARESETn : IN std_logic;
  -- write adress channel
  AWADDR  : OUT std_logic_vector(31 downto 0);
  AWVALID : OUT std_logic;
  AWREADY : IN  std_logic;
  AWID    : OUT std_logic_vector(5 downto 0);
  AWLOCK  : OUT std_logic_vector(1 downto 0);
  AWCACHE : OUT std_logic_vector(3 downto 0);
  AWPROT  : OUT std_logic_vector(2 downto 0);
  AWLEN   : OUT std_logic_vector(3 downto 0);
  AWSIZE  : OUT std_logic_vector(2 downto 0);
  AWBURST : OUT std_logic_vector(1 downto 0);
  AWQOS   : OUT std_logic_vector(3 downto 0);
  -- write data channel
  WDATA   : OUT std_logic_vector(63 downto 0);
  WVALID  : OUT std_logic;
  WREADY  : IN  std_logic;
  WID     : OUT std_logic_vector(5 downto 0);
  WLAST   : OUT std_logic;
  WSTRB   : OUT std_logic_vector(7 downto 0);
  WCOUNT  : IN  std_logic_vector(7 downto 0);
  WACOUNT : IN  std_logic_vector(5 downto 0);
  WRISSUECAP1EN : OUT std_logic;
  -- write response channel
  BVALID  : IN  std_logic;
  BREADY  : OUT std_logic;
  BID     : IN  std_logic_vector(5 downto 0);
  BRESP   : IN  std_logic_vector(1 downto 0);
  -- read address channel
  ARADDR  : OUT std_logic_vector(31 downto 0);
  ARVALID : OUT std_logic;
  ARREADY : IN  std_logic;
  ARID    : OUT std_logic_vector(5 downto 0);
  ARLOCK  : OUT std_logic_vector(1 downto 0);
  ARCACHE : OUT std_logic_vector(3 downto 0);
  ARPROT  : OUT std_logic_vector(2 downto 0);
  ARLEN   : OUT std_logic_vector(3 downto 0);
  ARSIZE  : OUT std_logic_vector(2 downto 0);
  ARBURST : OUT std_logic_vector(1 downto 0);
  ARQOS   : OUT std_logic_vector(3 downto 0);
  -- read data channel
  RDATA   : IN  std_logic_vector(63 downto 0);
  RVALID  : IN  std_logic;
  RREADY  : OUT std_logic;
  RID     : IN  std_logic_vector(5 downto 0);
  RLAST   : IN  std_logic;
  RRESP   : IN  std_logic_vector(1 downto 0);
  RCOUNT  : IN  std_logic_vector(7 downto 0);
  RACOUNT : IN  std_logic_vector(2 downto 0);
  RDISSUECAP1EN : OUT std_logic;

  -- zynq fifo signals
  re      : OUT std_logic;
  full_r  : IN  std_logic;
  empty   : IN  std_logic;
  data_r  : IN  std_logic_vector(63 downto 0);

  -- control signals
  run       : IN  std_logic;
  address_a : IN  std_logic_vector(31 downto 0);
  address_b : IN  std_logic_vector(31 downto 0);
  buff_size : IN  std_logic_vector(7 downto 0);
  channel   : OUT std_logic;
  byte_send : OUT std_logic_vector(31 downto 0);
  busy      : OUT std_logic
  );
END COMPONENT axi_hp_mic;

COMPONENT axi_lite_mic_ctrl_reg IS
  port (
  -- Global signals
  ACLK    : IN std_logic;
  ARESETn : IN std_logic;
  -- write adress channel
  AWVALID : IN std_logic;
  AWREADY : OUT std_logic;
  AWADDR  : IN std_logic_vector(31 downto 0);
  AWPROT  : IN std_logic_vector(2 downto 0);
  -- write data channel
  WVALID  : IN std_logic;
  WREADY  : OUT std_logic;
  WDATA   : IN std_logic_vector(31 downto 0);
  WSTRB   : IN std_logic_vector(3 downto 0); -- C_S_AXI_DATA_WIDTH/8)-1 : 0
  -- write response channel
  BVALID  : OUT std_logic;
  BREADY  : IN std_logic;
  BRESP   : OUT std_logic_vector(1 downto 0);
  -- read address channel
  ARVALID : IN  std_logic;
  ARREADY : OUT std_logic;
  ARADDR  : IN std_logic_vector(31 downto 0);
  ARPROT  : IN std_logic_vector(2 downto 0);
  -- read data channel
  RVALID  : OUT std_logic;
  RREADY  : IN std_logic;
  RDATA   : OUT std_logic_vector(31 downto 0);
  RRESP   : OUT std_logic_vector(1 downto 0);

  --registers
  enable      : OUT std_logic; -- power savings
  run         : OUT std_logic; -- enable outputs, counters run
  chann_a     : OUT std_logic_vector(31 downto 0); -- address for buffer A
  chann_b     : OUT std_logic_vector(31 downto 0); -- address for buffer A
  buff_size   : OUT std_logic_vector(7 downto 0); -- channel a pwm
  test_en     : OUT std_logic;
  byte_sended : IN std_logic_vector(31 downto 0);
  hp_busy     : IN std_logic;
  channel     : IN std_logic;

  -- interrupt
  mic_int : OUT std_logic
  );
END COMPONENT axi_lite_mic_ctrl_reg;

COMPONENT synchronizer is
    Port ( clk       : in  STD_LOGIC;
           res_n     : in  STD_LOGIC;
           data_in   : in  STD_LOGIC;
           data_out  : out STD_LOGIC
         );
end COMPONENT;
  -- clock and reset
  signal clk_slow   : std_logic;
  -- fifo write
  signal data_write : std_logic_vector(63 downto 0);
  signal data_we    : std_logic;
  signal full_write : std_logic;
  signal enable     : std_logic;
  -- fifo read
  signal data_re    : std_logic;
  signal full_r     : std_logic;
  signal empty_r    : std_logic;
  signal data_read  : std_logic_vector(63 downto 0);
  -- ctrl signals
  signal run         : std_logic; -- enable outputs, counters run
  signal address_a   : std_logic_vector(31 downto 0); -- address for buffer A
  signal address_b   : std_logic_vector(31 downto 0); -- address for buffer A
  signal buff_size   : std_logic_vector(7 downto 0); -- channel a pwm
  signal test_en     : std_logic;
  signal byte_sended : std_logic_vector(31 downto 0);
  signal hp_busy     : std_logic;
  signal channel     : std_logic;
  -- slow clock domain
  signal s_test_en : std_logic;
  signal s_en      : std_logic;
  signal s_run     : std_logic;
BEGIN

  clk_slow <= clk_s;
  audio_clk <= clk_slow;

  i_audio_aquire : audio_aquire
  generic map(
    G_TEST => G_TEST -- if mux is use
  )
  port map(
   rst_n => rst_n,
   clk   => clk_slow,
   en    => s_en,

   run       => s_run,
   test_en   => s_test_en,
   audio_in  => audio_do,
   data_w    => data_write,
   we        => data_we,
   fifo_full => full_write);

  i_fifo : fifo
  port map (
    -- 100 mhz port
    clk_100  => clk_f,
    rst_100n => rst_n, -- active in 0
    re       => data_re,
    sa_rstn  => run,
    full_r  => full_r,
    empty   => empty_r,
    data_r  => data_read,
    -- 25 mhz port
    clk_25  => clk_slow,
    rst_25n => rst_n,
    sb_rstn => s_run, --sw reset b
    data_w  => data_write,
    we      => data_we,
    full_w  => full_write
  );

i_axi_lite_mic_ctrl_reg : axi_lite_mic_ctrl_reg
  port map(
  -- Global signals
  ACLK    => clk_f,
  ARESETn => rst_n,
  -- write adress channel
  AWVALID => AXI_L_AWVALID,
  AWREADY => AXI_L_AWREADY,
  AWADDR  => AXI_L_AWADDR,
  AWPROT  => AXI_L_AWPROT,
  -- write data channel
  WVALID  => AXI_L_WVALID,
  WREADY  => AXI_L_WREADY,
  WDATA   => AXI_L_WDATA,
  WSTRB   => AXI_L_WSTRB,
  -- write response channel
  BVALID  => AXI_L_BVALID,
  BREADY  => AXI_L_BREADY,
  BRESP   => AXI_L_BRESP,
  -- read address channel
  ARVALID => AXI_L_ARVALID,
  ARREADY => AXI_L_ARREADY,
  ARADDR  => AXI_L_ARADDR,
  ARPROT  => AXI_L_ARPROT,
  -- read data channel
  RVALID  => AXI_L_RVALID,
  RREADY  => AXI_L_RREADY,
  RDATA   => AXI_L_RDATA,
  RRESP   => AXI_L_RRESP,

  --registers
  enable      => enable,
  run         => run,
  chann_a     => address_a,
  chann_b    => address_b,
  buff_size   => buff_size,
  test_en     => test_en,
  byte_sended => byte_sended,
  hp_busy     => hp_busy,
  channel     => channel,

  -- interrupt
  mic_int => mic_int
  );


i_axi_hp : axi_hp_mic
  port map(
  en      => enable,
  -- AXI signals
  -- Global signals
  ACLK    => clk_f,
  ARESETn => rst_n,
  -- write adress channel
  AWADDR  => AXI_HP_AWADDR,
  AWVALID => AXI_HP_AWVALID,
  AWREADY => AXI_HP_AWREADY,
  AWID    => AXI_HP_AWID,
  AWLOCK  => AXI_HP_AWLOCK,
  AWCACHE => AXI_HP_AWCACHE,
  AWPROT  => AXI_HP_AWPROT,
  AWLEN   => AXI_HP_AWLEN,
  AWSIZE  => AXI_HP_AWSIZE,
  AWBURST => AXI_HP_AWBURST,
  AWQOS   => AXI_HP_AWQOS,
  -- write data channel
  WDATA   => AXI_HP_WDATA,
  WVALID  => AXI_HP_WVALID,
  WREADY  => AXI_HP_WREADY,
  WID     => AXI_HP_WID,
  WLAST   => AXI_HP_WLAST,
  WSTRB   => AXI_HP_WSTRB,
  WCOUNT  => AXI_HP_WCOUNT,
  WACOUNT => AXI_HP_WACOUNT,
  WRISSUECAP1EN => AXI_HP_WRISSUECAP1EN,
  -- write response channel
  BVALID  => AXI_HP_BVALID,
  BREADY  => AXI_HP_BREADY,
  BID     => AXI_HP_BID,
  BRESP   => AXI_HP_BRESP,
  -- read address channel
  ARADDR  => AXI_HP_ARADDR,
  ARVALID => AXI_HP_ARVALID,
  ARREADY => AXI_HP_ARREADY,
  ARID    => AXI_HP_ARID,
  ARLOCK  => AXI_HP_ARLOCK,
  ARCACHE => AXI_HP_ARCACHE,
  ARPROT  => AXI_HP_ARPROT,
  ARLEN   => AXI_HP_ARLEN,
  ARSIZE  => AXI_HP_ARSIZE,
  ARBURST => AXI_HP_ARBURST,
  ARQOS   => AXI_HP_ARQOS,
  -- read data channel
  RDATA   => AXI_HP_RDATA,
  RVALID  => AXI_HP_RVALID,
  RREADY  => AXI_HP_RREADY,
  RID     => AXI_HP_RID,
  RLAST   => AXI_HP_RLAST,
  RRESP   => AXI_HP_RRESP,
  RCOUNT  => AXI_HP_RCOUNT,
  RACOUNT => AXI_HP_RACOUNT,
  RDISSUECAP1EN => AXI_HP_RDISSUECAP1EN,

  -- zynq fifo signals
  re      => data_re,
  full_r  => full_r,
  empty   => empty_r,
  data_r  => data_read,

  -- control signals
  run       => run,
  address_a => address_a,
  address_b => address_b,
  buff_size => buff_size,
  byte_send => byte_sended,
  channel   => channel,
  busy      => hp_busy
  );

  i_res_test_ena : synchronizer
  Port map (
    clk       => clk_slow,
    res_n     => rst_n,
    data_in   => test_en,
    data_out  => s_test_en
  );

  i_res_ena : synchronizer
  Port map (
    clk       => clk_slow,
    res_n     => rst_n,
    data_in   => enable,
    data_out  => s_en
  );
  
  i_res_run : synchronizer
  Port map (
    clk       => clk_slow,
    res_n     => rst_n,
    data_in   => run,
    data_out  => s_run
  );  

END ARCHITECTURE rtl;
