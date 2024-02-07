-------------------------------------------------------------------------------
-- model for used with GHDL
-- not used for synthesys
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;


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

ARCHITECTURE behavior OF clk_mux_mic IS

BEGIN
 
 mux_gen_0: if G_MUX = true generate

   clk_slow <= clk_int when mux = '0' ELSE 
               pclk;
             
 end generate mux_gen_0;
 
 mux_gen_1: if G_MUX = false generate
  clk_slow <= pclk;
 end generate mux_gen_1;
 
END ARCHITECTURE behavior;
 
