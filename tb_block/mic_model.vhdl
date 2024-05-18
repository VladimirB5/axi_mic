LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use STD.textio.all;

entity mic_model IS
  port (
  -- mic
  audio_clk            : IN std_logic;
  audio_do             : OUT std_logic;
  read_done            : OUT std_logic
  );
END ENTITY mic_model;


ARCHITECTURE behavior OF mic_model IS------------------------------------------------------------------------------
  file file_RESULTS : text;
 begin

   read_pdm: process
   variable v_OLINE : line;
   variable v_data_read   : integer;
   begin
     audio_do <= '0';
     read_done <= '0';
     file_open(file_RESULTS, "pdm.txt", read_mode);

     loop
       wait until audio_clk = '1';
       wait for 1 ns;
       if (not endfile(file_RESULTS)) then
         readline(file_RESULTS,v_OLINE);
         read(v_OLINE,v_data_read);
         if v_data_read = 1 then
           audio_do <= '1';
         else
           audio_do <= '0';
         end if;
         wait until audio_clk = '0';
        else
          read_done <= '1';
          exit;
        end if;
     end loop;
     file_close(file_RESULTS);
     wait;
   end process;


end ARCHITECTURE behavior;
