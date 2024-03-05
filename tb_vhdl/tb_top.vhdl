LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

library work;
use work.tb_top_pkg.all;

ENTITY tb_top IS 
END ENTITY tb_top;

ARCHITECTURE behavior OF tb_top IS
-------------------------------------------------------------------------------
COMPONENT axi_mic IS
  generic (
    G_TEST : boolean -- diagnostig logic added
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
END COMPONENT;

COMPONENT stimuli_tb IS 
  port (
    axi_m_in  : IN   t_AXI_M_IN; 
    axi_m_out : OUT  t_AXI_M_OUT;
    ctrl      : OUT  t_CTRL;
    int       : IN  std_logic
  );
END COMPONENT stimuli_tb;
-------------------------------------------------------------------------------

   signal clk_100   : std_logic := '0';
   signal clk_slow  : std_logic := '0';
   signal clk_audio : std_logic := '0';
   signal rst_n     : std_logic := '0';
   
   signal AXI_L_ACLK    : std_logic;
   -- axi lite signals
   signal AXI_L_AWVALID : std_logic := '0';
   signal AXI_L_AWREADY : std_logic;
   signal AXI_L_AWADDR  : std_logic_vector(31 downto 0) := (others => '0');
   signal AXI_L_AWPROT  : std_logic_vector(2 downto 0)  := (others => '0');
    -- write data channel
   signal AXI_L_WVALID  : std_logic := '0';
   signal AXI_L_WREADY  : std_logic;
   signal AXI_L_WDATA   : std_logic_vector(31 downto 0) := (others => '0');
   signal AXI_L_WSTRB   : std_logic_vector(3 downto 0)  := (others => '0'); -- C_S_AXI_DATA_WIDTH/8)-1 : 0
    -- write response channel
   signal AXI_L_BVALID  : std_logic;
   signal AXI_L_BREADY  : std_logic := '0';
   signal AXI_L_BRESP   : std_logic_vector(1 downto 0);
    -- read address channel
   signal AXI_L_ARVALID : std_logic;
   signal AXI_L_ARREADY : std_logic;
   signal AXI_L_ARADDR  : std_logic_vector(31 downto 0);
   signal AXI_L_ARPROT  : std_logic_vector(2 downto 0);
    -- read data channel
   signal AXI_L_RVALID  : std_logic;
   signal AXI_L_RREADY  : std_logic;
   signal AXI_L_RDATA   : std_logic_vector(31 downto 0);
   signal AXI_L_RRESP   : std_logic_vector(1 downto 0);    

   -- axi hp
   -- write adress channel
   signal AXI_HP_AWADDR        : std_logic_vector(31 downto 0);
   signal AXI_HP_AWVALID       : std_logic;
   signal AXI_HP_AWREADY       : std_logic;
   signal AXI_HP_AWID          : std_logic_vector(5 downto 0);   
   signal AXI_HP_AWLOCK        : std_logic_vector(1 downto 0); 
   signal AXI_HP_AWCACHE       : std_logic_vector(3 downto 0); 
   signal AXI_HP_AWPROT        : std_logic_vector(2 downto 0); 
   signal AXI_HP_AWLEN         : std_logic_vector(3 downto 0); 
   signal AXI_HP_AWSIZE        : std_logic_vector(2 downto 0); 
   signal AXI_HP_AWBURST       : std_logic_vector(1 downto 0); 
   signal AXI_HP_AWQOS         : std_logic_vector(3 downto 0);  
     -- write data channel  
   signal AXI_HP_WDATA         : std_logic_vector(63 downto 0);
   signal AXI_HP_WVALID        : std_logic;
   signal AXI_HP_WREADY        : std_logic;
   signal AXI_HP_WID           : std_logic_vector(5 downto 0);
   signal AXI_HP_WLAST         : std_logic;
   signal AXI_HP_WSTRB         : std_logic_vector(7 downto 0);
   signal AXI_HP_WCOUNT        : std_logic_vector(7 downto 0);
   signal AXI_HP_WACOUNT       : std_logic_vector(5 downto 0);
   signal AXI_HP_WRISSUECAP1EN : std_logic;
     -- write response channel
   signal AXI_HP_BVALID        : std_logic;
   signal AXI_HP_BREADY        : std_logic;
   signal AXI_HP_BID           : std_logic_vector(5 downto 0);
   signal AXI_HP_BRESP         : std_logic_vector(1 downto 0);
     -- read address channel  
   signal AXI_HP_ARADDR        : std_logic_vector(31 downto 0);
   signal AXI_HP_ARVALID       : std_logic;
   signal AXI_HP_ARREADY       : std_logic;
   signal AXI_HP_ARID          : std_logic_vector(5 downto 0);    
   signal AXI_HP_ARLOCK        : std_logic_vector(1 downto 0);
   signal AXI_HP_ARCACHE       : std_logic_vector(3 downto 0);
   signal AXI_HP_ARPROT        : std_logic_vector(2 downto 0);
   signal AXI_HP_ARLEN         : std_logic_vector(3 downto 0);
   signal AXI_HP_ARSIZE        : std_logic_vector(2 downto 0);
   signal AXI_HP_ARBURST       : std_logic_vector(1 downto 0);
   signal AXI_HP_ARQOS         : std_logic_vector(3 downto 0);
     -- read data channel  
   signal AXI_HP_RDATA         : std_logic_vector(63 downto 0);
   signal AXI_HP_RVALID        : std_logic;
   signal AXI_HP_RREADY        : std_logic;
   signal AXI_HP_RID           : std_logic_vector(5 downto 0);    
   signal AXI_HP_RLAST         : std_logic;
   signal AXI_HP_RRESP         : std_logic_vector(1 downto 0);
   signal AXI_HP_RCOUNT        : std_logic_vector(7 downto 0);
   signal AXI_HP_RACOUNT       : std_logic_vector(2 downto 0);
   signal AXI_HP_RDISSUECAP1EN : std_logic;     
   
   signal stop_sim: boolean := false;
   constant clk_period_100  : time := 10 ns;
   constant clk_period_25  : time := 38 ns;  
   constant clk_period_slow : time := 40 ns;
   
   signal address : std_logic_vector(31 downto 0);
   signal data    : std_logic_vector(31 downto 0);   
   
   signal write_start : std_logic := '0';
   signal read_start : std_logic := '0';   
   signal mic_int : std_logic;
begin

   i_axi_mic: axi_mic
   generic map (
     G_TEST => true
   )
   PORT MAP (
    -- clocks and resets
    clk_f         => clk_100, -- fast clock expecte at 100 Mhz
    rst_n         => rst_n,

    clk_s         => clk_slow, -- slow clock at 2.5Mhz

     -- axi-lite
     AXI_L_ACLK    => '0',
     -- write adress channel
     AXI_L_AWVALID => AXI_L_AWVALID,
     AXI_L_AWREADY => AXI_L_AWREADY,
     AXI_L_AWADDR  => AXI_L_AWADDR,
     AXI_L_AWPROT  => AXI_L_AWPROT,
     -- write data channel
     AXI_L_WVALID  => AXI_L_WVALID,
     AXI_L_WREADY  => AXI_L_WREADY,
     AXI_L_WDATA   => AXI_L_WDATA,
     AXI_L_WSTRB   => AXI_L_WSTRB,
     -- write response channel
     AXI_L_BVALID  => AXI_L_BVALID,
     AXI_L_BREADY  => AXI_L_BREADY,
     AXI_L_BRESP   => AXI_L_BRESP,
     -- read address channel
     AXI_L_ARVALID => AXI_L_ARVALID,
     AXI_L_ARREADY => AXI_L_ARREADY,
     AXI_L_ARADDR  => AXI_L_ARADDR,
     AXI_L_ARPROT  => AXI_L_ARPROT,
     -- read data channel
     AXI_L_RVALID  => AXI_L_RVALID,
     AXI_L_RREADY  => AXI_L_RREADY,
     AXI_L_RDATA   => AXI_L_RDATA,
     AXI_L_RRESP   => AXI_L_RRESP, 

     -- axi hp
     AXI_HP_ACLK     => '0',
     -- write adress channel
     AXI_HP_AWADDR   => AXI_HP_AWADDR,
     AXI_HP_AWVALID  => AXI_HP_AWVALID,
     AXI_HP_AWREADY  => AXI_HP_AWREADY,
     AXI_HP_AWID     => AXI_HP_AWID,  
     AXI_HP_AWLOCK   => AXI_HP_AWLOCK,
     AXI_HP_AWCACHE  => AXI_HP_AWCACHE,
     AXI_HP_AWPROT   => AXI_HP_AWPROT,
     AXI_HP_AWLEN    => AXI_HP_AWLEN,
     AXI_HP_AWSIZE   => AXI_HP_AWSIZE,
     AXI_HP_AWBURST  => AXI_HP_AWBURST,
     AXI_HP_AWQOS    => AXI_HP_AWQOS,
     -- write data channel  
     AXI_HP_WDATA         => AXI_HP_WDATA,
     AXI_HP_WVALID        => AXI_HP_WVALID,
     AXI_HP_WREADY        => AXI_HP_WREADY,
     AXI_HP_WID           => AXI_HP_WID,
     AXI_HP_WLAST         => AXI_HP_WLAST,
     AXI_HP_WSTRB         => AXI_HP_WSTRB,
     AXI_HP_WCOUNT        => AXI_HP_WCOUNT,
     AXI_HP_WACOUNT       => AXI_HP_WACOUNT,
     AXI_HP_WRISSUECAP1EN => AXI_HP_WRISSUECAP1EN,
     -- write response channel
     AXI_HP_BVALID        => AXI_HP_BVALID,
     AXI_HP_BREADY        => AXI_HP_BREADY,
     AXI_HP_BID           => AXI_HP_BID, 
     AXI_HP_BRESP         => AXI_HP_BRESP,
     -- read address channel   
     AXI_HP_ARADDR        => AXI_HP_ARADDR,
     AXI_HP_ARVALID       => AXI_HP_ARVALID,
     AXI_HP_ARREADY       => AXI_HP_ARREADY,
     AXI_HP_ARID          => AXI_HP_ARID,   
     AXI_HP_ARLOCK        => AXI_HP_ARLOCK,
     AXI_HP_ARCACHE       => AXI_HP_ARCACHE,
     AXI_HP_ARPROT        => AXI_HP_ARPROT,
     AXI_HP_ARLEN         => AXI_HP_ARLEN,
     AXI_HP_ARSIZE        => AXI_HP_ARSIZE,
     AXI_HP_ARBURST       => AXI_HP_ARBURST,
     AXI_HP_ARQOS         => AXI_HP_ARQOS,
     -- read data channel  
     AXI_HP_RDATA         => AXI_HP_RDATA,
     AXI_HP_RVALID        => AXI_HP_RVALID,
     AXI_HP_RREADY        => AXI_HP_RREADY,
     AXI_HP_RID           => AXI_HP_RID,
     AXI_HP_RLAST         => AXI_HP_RLAST,
     AXI_HP_RRESP         => AXI_HP_RRESP,
     AXI_HP_RCOUNT        => AXI_HP_RCOUNT,
     AXI_HP_RACOUNT       => AXI_HP_RACOUNT,
     AXI_HP_RDISSUECAP1EN => AXI_HP_RDISSUECAP1EN,
  
     -- mic
     audio_clk            => clk_audio,
     audio_do             => '0',

     -- mic int
     mic_int              => mic_int
   );
           
   i_stimuli_tb : stimuli_tb
   PORT MAP (
     axi_m_in.clk_syn => clk_100,
     axi_m_in.AWREADY => AXI_L_AWREADY,
     axi_m_in.WREADY  => AXI_L_WREADY,
     axi_m_in.BVALID  => AXI_L_BVALID,
     axi_m_in.BRESP   => AXI_L_BRESP,
     axi_m_in.ARREADY => AXI_L_ARREADY,
     axi_m_in.RVALID  => AXI_L_RVALID,
     axi_m_in.RDATA   => AXI_L_RDATA,
     axi_m_in.RRESP   => AXI_L_RRESP,
     
     axi_m_out.ACLK   => AXI_L_ACLK,    
     axi_m_out.AWVALID=> AXI_L_AWVALID,
     axi_m_out.AWADDR => AXI_L_AWADDR,
     axi_m_out.AWPROT => AXI_L_AWPROT,
     axi_m_out.WVALID => AXI_L_WVALID,
     axi_m_out.WDATA  => AXI_L_WDATA,
     axi_m_out.WSTRB  => AXI_L_WSTRB,
     axi_m_out.BREADY => AXI_L_BREADY,
     axi_m_out.ARVALID=> AXI_L_ARVALID,
     axi_m_out.ARADDR => AXI_L_ARADDR,
     axi_m_out.ARPROT => AXI_L_ARPROT,
     axi_m_out.RREADY => AXI_L_RREADY,
--      t_CTRL
     ctrl.stop_sim    => stop_sim,
     ctrl.rst_n       => rst_n,
     ctrl.AXI_HP_AWREADY => AXI_HP_AWREADY,
     ctrl.AXI_HP_WREADY  => AXI_HP_WREADY,
     ctrl.AXI_HP_BVALID  => AXI_HP_BVALID,
     -- interrupt 
     int => mic_int
   );  
   
   clock_100: process
     begin
        clk_100 <= '0';
        wait for clk_period_100/2;  --
        clk_100 <= '1';
        wait for clk_period_100/2;  --
        if stop_sim = true then
          wait;
        end if;
   end process;
   
   clock_slow: process
     begin
        clk_slow <= '0';
        wait for clk_period_25/2;  --
        clk_slow <= '1';
        wait for clk_period_25/2;  --
        if stop_sim = true then
          wait;
        end if;
   end process;   
      
end ARCHITECTURE behavior; 
 
