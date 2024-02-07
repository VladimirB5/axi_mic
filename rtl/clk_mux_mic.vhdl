LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;


ENTITY clk_mux_mic IS
  generic (
    G_MUX : boolean -- if mux is use
  );
  port (
    clk_int  : IN std_logic;  -- input clk from internal source
    pclk     : IN std_logic;  -- input clk from external source
    mux      : IN std_logic;
    clk_slow : OUT std_logic  -- output to 25mhz clock domain
    
  ); 
END ENTITY clk_mux_mic;

ARCHITECTURE rtl OF clk_mux_mic IS

BEGIN
 
 mux_gen_0: if G_MUX = true generate
   -- BUFGMUX_CTRL: 2-to-1 Global Clock MUX Buffer
   --               Artix-7
   -- Xilinx HDL Language Template, version 2018.2
   
   BUFGMUX_CTRL_inst : BUFGMUX_CTRL
   port map (
     O => clk_slow,   -- 1-bit output: Clock output
     I0 => clk_int, -- 1-bit input: Clock input (S=0)
     I1 => pclk, -- 1-bit input: Clock input (S=1)
     S => mux    -- 1-bit input: Clock select
   );
   
   -- End of BUFGMUX_CTRL_inst instantiation
 end generate mux_gen_0;
 
 mux_gen_1: if G_MUX = false generate
  clk_slow <= pclk;
 end generate mux_gen_1;
 
END ARCHITECTURE rtl;
