LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.axi_lite_mic_regs_pkg.all;

ENTITY axi_lite_mic_ctrl_reg IS
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
END ENTITY axi_lite_mic_ctrl_reg;

ARCHITECTURE rtl OF axi_lite_mic_ctrl_reg IS
  -- components
COMPONENT int_ctrl_mic IS
  port (
   rstn          : IN std_logic;
   clk           : IN std_logic;
   en            : IN std_logic;

   int_ena       : IN std_logic;
   ena           : IN std_logic; -- axi hp block enabled
   cap_err       : IN std_logic;
   hp_busy       : IN std_logic; -- when goes from 1 to 0 it
   channel       : IN std_logic;
   sts_fin_a_clr : IN std_logic; -- clear status and interrupt
   sts_fin_b_clr : IN std_logic; -- clear status and interrupt
   sts_err_clr   : IN std_logic; -- clear status and interrupt
   sts_fin_a     : OUT std_logic; -- sts finished channel a
   sts_fin_b     : OUT std_logic; -- sts finished channel a
   sts_err       : OUT std_logic; -- status error

   int           : OUT std_logic
  );
END COMPONENT int_ctrl_mic;
  -- signals
  signal busy    : std_logic;
  signal sts_fin_a, sts_fin_b : std_logic;
  signal sts_err : std_logic;
  -- output registers
  signal  arready_c, arready_s : std_logic;
  signal  rvalid_c, rvalid_s   : std_logic;
  signal  awready_c, awready_s : std_logic;
  signal  wready_c, wready_s   : std_logic;
  signal  bvalid_c, bvalid_s   : std_logic;
  signal  rresp_c, rresp_s     : std_logic_vector(1 downto 0); -- read response
  signal  bresp_c, bresp_s     : std_logic_vector(1 downto 0); -- write resonse
  signal  rdata_c, rdata_s     : std_logic_vector(31 downto 0);
  -- interrupts
  signal  sts_fin_clr_a_c, sts_fin_clr_a_s : std_logic;
  signal  sts_fin_clr_b_c, sts_fin_clr_b_s : std_logic;
  signal  sts_err_clr_c, sts_err_clr_s : std_logic;
  -- register form reg. bank
  signal reg_c, reg_s : t_axi_lite_mic_regs;

  -- fsm read declaration
  TYPE t_read_state IS (R_IDLE, R_AREADY, R_VDATA);
  SIGNAL fsm_read_c, fsm_read_s :t_read_state;
  
  -- fsm write declaration
  TYPE t_write_state IS (W_IDLE, W_ADDR_DAT, W_RESP);
  SIGNAL fsm_write_c, fsm_write_s :t_write_state;  
  
  -- responses
  constant OKAY   : std_logic_vector(1 downto 0) := B"00";
  constant EXOKAY : std_logic_vector(1 downto 0) := B"01";
  constant SLVERR : std_logic_vector(1 downto 0) := B"10";
  constant DECERR : std_logic_vector(1 downto 0) := B"11";
  begin
  i_int_ctrl : int_ctrl_mic
  port map(
   rstn          => ARESETn,
   clk           => ACLK,
   en            => reg_s.enable,
   --
   int_ena       => reg_s.int_ena,
   ena           => reg_s.run, -- axi hp block enabled
   cap_err       => '0',
   hp_busy       => hp_busy, -- when goes from 1 to 0 it
   channel       => channel,
   sts_fin_a_clr => sts_fin_clr_a_s, -- clear status and interrupt
   sts_fin_b_clr => sts_fin_clr_b_s,
   sts_err_clr   => sts_err_clr_s, -- clear status and interrupt
   sts_fin_a     => sts_fin_a, -- sts finished a
   sts_fin_b     => sts_fin_b, -- sts finished b
   sts_err       => sts_err, -- status error

   int        => mic_int
  );



  -- sequential 
 state_reg : PROCESS (ACLK, ARESETn)
   BEGIN
    IF ARESETn = '0' THEN
      arready_s      <= '0';
      rvalid_s       <= '0';
      awready_s      <= '0';
      wready_s       <= '0';
      bvalid_s       <= '0';
      rresp_s        <= (others => '0');
      bresp_s        <= (others => '0');
      rdata_s        <= (others => '0');
      -- axi-lite registers
      reg_s          <= C_AXI_LITE_REGS_INIT;
      sts_fin_clr_a_s <= '0';
      sts_fin_clr_b_s <= '0';
      sts_err_clr_s   <= '0';
      
      fsm_read_s     <= R_IDLE; -- init state after reset
      fsm_write_s    <= W_IDLE;
    ELSIF ACLK = '1' AND ACLK'EVENT THEN
      arready_s       <= arready_c;
      rvalid_s        <= rvalid_c;
      awready_s       <= awready_c;
      wready_s        <= wready_c;
      bvalid_s        <= bvalid_c;
      rresp_s         <= rresp_c;
      bresp_s         <= bresp_c;
      rdata_s         <= rdata_c;

      reg_s           <= reg_c;
      sts_fin_clr_a_s <= sts_fin_clr_a_c;
      sts_fin_clr_b_s <= sts_fin_clr_b_c;
      sts_err_clr_s   <= sts_err_clr_c;

      fsm_read_s      <= fsm_read_c; -- next fsm state
      fsm_write_s     <= fsm_write_c;
    END IF;       
 END PROCESS state_reg;

 -- read processes ---------------------------------------------------------------------------
 next_state_read_logic : PROCESS (fsm_read_s, ARVALID, RREADY)
 BEGIN
    fsm_read_c <= fsm_read_s;
    CASE fsm_read_s IS
      WHEN R_IDLE =>
        fsm_read_c <= R_AREADY;
      
      when R_AREADY =>
        IF ARVALID = '1' then 
          fsm_read_c <= R_VDATA;
        ELSE
          fsm_read_c <= R_AREADY;
        END IF;
            
      WHEN R_VDATA =>
        IF RREADY = '1' then
          fsm_read_c <= R_IDLE;
        ELSE
          fsm_read_c <= R_VDATA;
        END IF;
    END CASE;        
 END PROCESS next_state_read_logic;
    
  -- ouput combinational logic
 output_read_logic : PROCESS (fsm_read_c)
 BEGIN
    rvalid_c  <= '0';
    arready_c <= '0'; 
    CASE fsm_read_c IS
      WHEN R_IDLE =>
        arready_c <= '0';
      
      WHEN R_AREADY =>
        arready_c <= '1';
             
      WHEN R_VDATA =>
        rvalid_c <= '1';
    END CASE;
  END PROCESS output_read_logic;
  
 -- output read mux
 output_read_mux : PROCESS (fsm_read_s, ARVALID, ARADDR(4 downto 2), reg_s)
 BEGIN
    rdata_c <= (others => '0');
    rresp_c <= OKAY;   
    IF ARVALID = '1' AND fsm_read_s = R_AREADY THEN
      CASE ARADDR(5 downto 2) IS 
        WHEN C_ADDR_ENABLE =>
          rdata_c(0) <= reg_s.enable;
        WHEN C_ADDR_RUN =>
          rdata_c(0) <= reg_s.run;
        WHEN C_ADDR_CHANN_A =>
          rdata_c <= reg_s.chann_a;
        WHEN C_ADDR_CHANN_B =>
          rdata_c <= reg_s.chann_b;
        WHEN C_ADDR_BUFF_SIZE =>
          rdata_c(7 downto 0) <= reg_s.buff_size;
        WHEN C_ADDR_NUM_BYTES =>
          rdata_c <= byte_sended;
        WHEN C_ADDR_INT_ENA =>
          rdata_c(0)           <= reg_s.int_ena;
        WHEN C_ADDR_INT_STS =>
          rdata_c(0) <= sts_fin_a;
          rdata_c(1) <= sts_fin_b;
          rdata_c(2) <= sts_err;
        WHEN C_ADDR_TEST_CTRL =>
          rdata_c(0) <= reg_s.test_ena;
        WHEN C_ADDR_TEST_READ =>
          rdata_c <= x"87115571";
        WHEN others =>
          rresp_c <= SLVERR;
      END CASE;
    ELSIF fsm_read_s = R_VDATA THEN
      rdata_c <= rdata_s;
      rresp_c <= rresp_s;
    ELSE
      rdata_c <= (others => '0');
    END IF;
  END PROCESS output_read_mux;
  
-- write processes ------------------------------------------------------------------------  
 next_state_write_logic : PROCESS (fsm_write_s, AWVALID, WVALID, BREADY)
 BEGIN
    fsm_write_c <= fsm_write_s;
    CASE fsm_write_s IS
      WHEN W_IDLE =>
        IF AWVALID = '1' AND WVALID = '1' THEN
          fsm_write_c <= W_ADDR_DAT;
        END IF;
            
      WHEN W_ADDR_DAT =>
        fsm_write_c <= W_RESP;
      
      WHEN W_RESP =>
        IF BREADY = '1' THEN 
          fsm_write_c <= W_IDLE;
        END IF;
    END CASE;
 END PROCESS next_state_write_logic;
  
 output_write_logic : PROCESS (fsm_write_c, AWADDR(4 downto 2), WDATA, bresp_s, reg_s)
 BEGIN
    awready_c      <= '0';
    wready_c       <= '0';
    bvalid_c       <= '0';
    bresp_c        <= bresp_s;
    -- axi registers
    reg_c           <= reg_s;
    sts_fin_clr_a_c <= '0';
    sts_fin_clr_b_c <= '0';
    sts_err_clr_c   <= '0';

    CASE fsm_write_c IS
      WHEN W_IDLE => 
        bresp_c   <= OKAY;
        awready_c <= '0';
        wready_c  <= '0';
        bvalid_c  <= '0';
            
      WHEN W_ADDR_DAT =>
        CASE AWADDR(5 downto 2) IS
          WHEN C_ADDR_ENABLE =>
            reg_c.enable <= WDATA(0);
          WHEN C_ADDR_RUN =>
            reg_c.run <= WDATA(0);
          WHEN C_ADDR_CHANN_A =>
            reg_c.chann_a <= WDATA;
          WHEN C_ADDR_CHANN_B =>
            reg_c.chann_b <= WDATA;
          WHEN C_ADDR_BUFF_SIZE =>
            reg_c.buff_size <= WDATA(7 downto 0);
          WHEN C_ADDR_NUM_BYTES =>
            -- do nothing for write
          WHEN C_ADDR_INT_ENA =>
            reg_c.int_ena <= WDATA(0);
          WHEN C_ADDR_INT_STS =>
            sts_fin_clr_a_c <= WDATA(0);
            sts_fin_clr_b_c <= WDATA(1);
            sts_err_clr_c   <= WDATA(2);
          WHEN C_ADDR_TEST_CTRL =>
            reg_c.test_ena <= WDATA(0);
          WHEN C_ADDR_TEST_READ =>
            -- do nothing register only for read
          WHEN others =>
            bresp_c <= SLVERR;
        END CASE;      
        awready_c <= '1';
        wready_c  <= '1';
        bvalid_c  <= '0';      
      
      WHEN W_RESP =>
        awready_c <= '0';
        wready_c  <= '0';
        bvalid_c  <= '1';      
    END CASE;
  END PROCESS output_write_logic; 
  
  -- output assigment
  -- read channels
  ARREADY <= arready_s;
  RVALID  <= rvalid_s;
  RDATA   <= rdata_s;
  RRESP   <= rresp_s;
  -- write channels
  AWREADY <= awready_s;
  WREADY  <= wready_s;
  BVALID  <= bvalid_s;
  BRESP   <= bresp_s;
  -- output from register bank
  enable    <= reg_s.enable;
  run       <= reg_s.run;
  chann_a   <= reg_s.chann_a;
  chann_b   <= reg_s.chann_b;
  test_en   <= reg_s.test_ena;
  buff_size <= reg_s.buff_size;
END ARCHITECTURE RTL;
 
