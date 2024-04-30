LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use STD.textio.all;

entity mic_model IS
  port (
  -- mic
  audio_clk            : IN std_logic;
  audio_do             : OUT std_logic
  );
END ENTITY mic_model;


ARCHITECTURE behavior OF mic_model IS------------------------------------------------------------------------------
  file file_RESULTS : text;
 begin

   read_pdm: process
   variable v_OLINE : line;
   variable v_data_read   : integer;
   begin
     file_open(file_RESULTS, "pdm.txt", read_mode);

     --wait until rst_n = '1' and run = '1';
     for k in 0 to 10000 loop --12500
       wait until audio_clk = '1';
       wait for 1 ns;
       readline(file_RESULTS,v_OLINE);
       read(v_OLINE,v_data_read);
       audio_do <= std_logic(unsigned(v_data_read));
       wait until audio_clk = '0';
     end loop;
     file_close(file_RESULTS);
     wait;
   end process;


end ARCHITECTURE behavior;
