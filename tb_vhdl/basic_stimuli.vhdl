LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

use work.tb_top_pkg.all;
use work.axi_lite_pkg.all;

ENTITY stimuli_tb IS 
  port (
    axi_m_in  : IN   t_AXI_M_IN; 
    axi_m_out : OUT  t_AXI_M_OUT;
    ctrl      : OUT  t_CTRL;
    int       : IN   std_logic
  );
END ENTITY stimuli_tb;

ARCHITECTURE cam_stimuli OF stimuli_tb IS
-------------------------------------------------------------------------------
  signal address   : std_logic_vector(31 downto 0);
  signal data      : std_logic_vector(31 downto 0);
  signal data_read : std_logic_vector(31 downto 0) := (others => '0');
 
begin

   sim: process
     begin
     axi_m_out.ARPROT  <= (others => '0');
     --AXI_L_ARVALID <= '0';     
     ctrl.rst_n <= '0';
     wait for 100 ns;
     wait for 100 ns;
     ctrl.AXI_HP_AWREADY <= '1';
     ctrl.AXI_HP_WREADY  <= '1';
     ctrl.AXI_HP_BVALID  <= '1';
     ctrl.rst_n <= '1';
          
     wait for us;
     -- channel B
     address <= x"0000000C";
     data    <= x"00000200"; -- channel B
     axi_write(axi_m_in, axi_m_out, address, data);   
     
     address <= x"0000000C";
     axi_read(axi_m_in, axi_m_out, address, data_read);
     report "data : channel B = " & integer'image(to_integer(unsigned(data_read)));    
     
     -- byte size 
     address <= x"00000010";
     data    <= x"00000003"; -- num transfers
     axi_write(axi_m_in, axi_m_out, address, data);   
     
     address <= x"00000010";
     axi_read(axi_m_in, axi_m_out, address, data_read);
     report "data : transfers = " & integer'image(to_integer(unsigned(data_read)));     
     
     -- enable 
     address <= x"00000000";
     data    <= x"00000001"; -- enable
     axi_write(axi_m_in, axi_m_out, address, data);     

     -- read enable
     address <= x"00000000";
     axi_read(axi_m_in, axi_m_out, address, data_read);
     report "data : enable = " & integer'image(to_integer(unsigned(data_read)));
    
     -- enable interrupt 
     address <= x"00000018";
     data    <= x"00000001"; -- int ena
     axi_write(axi_m_in, axi_m_out, address, data);      
    
     -- run
     address <= x"00000004";
     data    <= x"00000001"; -- run
     axi_write(axi_m_in, axi_m_out, address, data);     

     -- read run address
     address <= x"00000004";
     axi_read(axi_m_in, axi_m_out, address, data_read);
     report "data : run = " & integer'image(to_integer(unsigned(data_read)));
     
     address <= x"00000020";
     data    <= x"00000001"; -- enable test
     axi_write(axi_m_in, axi_m_out, address, data);
     
     wait on int for 1500 us;
    
     if (int = '0') then 
       report "Interrupt is not set(1)" severity error;
     else 
       report "Interupt is set(1)"; 
     end if;

     -- read interrups address
     address <= x"0000001C";
     axi_read(axi_m_in, axi_m_out, address, data_read);
     report "interrupts = " & integer'image(to_integer(unsigned(data_read)));
     
     -- clear interrupt 
     address <= x"0000001C";
     data    <= x"00000001"; -- int clear
     axi_write(axi_m_in, axi_m_out, address, data); 
     
     if (int = '1') then 
       report "Interrupt is not cleared(1)" severity error;
     else 
       report "Interupt is cleared successfully(1)"; 
     end if;     
     
     wait on int for 1500 us;
    
     if (int = '0') then 
       report "Interrupt is not set(2)" severity error;
     else 
       report "Interupt is set(2)";
     end if;   

     -- read interrups address
     address <= x"0000001C";
     axi_read(axi_m_in, axi_m_out, address, data_read);
     report "interrupts = " & integer'image(to_integer(unsigned(data_read)));
     
     address <= x"0000001C";
     data    <= x"00000002"; -- int clear
     axi_write(axi_m_in, axi_m_out, address, data);  
     
     if (int = '1') then 
       report "Interrupt is not cleared(2)" severity error;
     else 
       report "Interupt is cleared successfully(2)"; 
     end if;      
     
     wait for 100 us;

     ctrl.stop_sim <= true;
     --report "simulation finished successfully" severity FAILURE;
     wait;    
   end process;

end ARCHITECTURE cam_stimuli; 
 
 
