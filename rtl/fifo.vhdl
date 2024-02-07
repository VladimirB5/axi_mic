LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

ENTITY fifo IS
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
END ENTITY fifo; 


ARCHITECTURE rtl OF fifo IS

COMPONENT fifo_read IS
  port (
    -- 100 mhz port
    clk       : IN  std_logic; -- clk
    rstn      : IN  std_logic; -- active in 0
    re        : IN  std_logic;
    sw_rstn   : IN std_logic; -- sw reset
    write_ptr : IN  std_logic_vector(5 downto 0);
    read_ptr  : OUT std_logic_vector(5 downto 0);    
    addr      : OUT std_logic_vector(8 downto 0);
    full      : OUT std_logic;
    empty     : OUT std_logic
  ); 
END COMPONENT;

COMPONENT fifo_write IS
  port (
    -- 25 mhz port
    clk       : IN  std_logic; -- clk
    rstn      : IN  std_logic; -- active in 0
    we        : IN  std_logic;
    sw_rstn   : IN std_logic; -- sw reset    
    read_ptr  : IN  std_logic_vector(5 downto 0);
    write_ptr : OUT std_logic_vector(5 downto 0);    
    addr      : OUT std_logic_vector(8 downto 0);
    full      : OUT std_logic
  ); 
END COMPONENT fifo_write; 

COMPONENT synchronizer_vector is
    GENERIC (
        N : natural 
    );
    Port ( clk       : IN  STD_LOGIC;
           res_n     : IN  STD_LOGIC;
           data_in   : IN  STD_LOGIC_VECTOR(N downto 0);
           data_out  : OUT STD_LOGIC_VECTOR(N downto 0)
         );
END COMPONENT;

COMPONENT RAM_mic is
   GENERIC (
     word : natural; -- := 8;
     adr  : natural-- := 8
    );
    Port ( CLK1  : in  STD_LOGIC;
           ADR1  : in  STD_LOGIC_VECTOR (adr downto 0);
           DATA1 : in  STD_LOGIC_VECTOR (word-1 downto 0);
           WE    : in  STD_LOGIC;
              
           CLK2  : in  STD_LOGIC;
           ADR2  : in  STD_LOGIC_VECTOR (adr downto 0);
           DATA2 : out STD_LOGIC_VECTOR (word-1 downto 0);
           RE    : in  STD_LOGIC);
END COMPONENT;

signal read_ptr      : std_logic_vector(5 downto 0);
signal write_ptr     : std_logic_vector(5 downto 0);
signal read_ptr_25   : std_logic_vector(5 downto 0);
signal write_ptr_100 : std_logic_vector(5 downto 0);
signal addr_r        : std_logic_vector(8 downto 0);
signal addr_w        : std_logic_vector(8 downto 0);

BEGIN
-------------------------------------------------------------------------------
i_fifo_read : fifo_read
port map (
    -- 100 mhz port
    clk       => clk_100,
    rstn      => rst_100n,
    re        => re,
    sw_rstn   => sa_rstn,
    write_ptr => write_ptr_100,
    read_ptr  => read_ptr,
    addr      => addr_r,
    full      => full_r,
    empty     => empty
  ); 

-------------------------------------------------------------------------------
i_fifo_write: fifo_write
port map(
    -- 25 mhz port
    clk       => clk_25,
    rstn      => rst_25n,
    we        => we,
    sw_rstn   => sb_rstn,
    read_ptr  => read_ptr_25,
    write_ptr => write_ptr,   
    addr      => addr_w,
    full      => full_w
  ); 
  
-------------------------------------------------------------------------------
i_synchro_write : synchronizer_vector
generic map (
      n      => 5
)
port map (
     clk      => clk_100,
     res_n    => rst_100n,
     data_in  => write_ptr,
     data_out => write_ptr_100
);

------------------------------------------------------------------------------- 
i_synchro_read : synchronizer_vector
generic map (
      n      => 5
)
port map (
     clk      => clk_25,
     res_n    => rst_25n,
     data_in  => read_ptr,
     data_out => read_ptr_25
);

-------------------------------------------------------------------------------
i_FIFO_RAM : RAM_mic
generic map (
      word => 64,
      adr  => 8)
port map (
     CLK1  => clk_25,
     ADR1  => addr_w,
     DATA1 => data_w, 
     WE    => we,
              
     CLK2  => clk_100,
     ADR2  => addr_r,
     DATA2 => data_r,
     RE    => re);    

END ARCHITECTURE rtl;
