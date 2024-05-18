LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use STD.textio.all;
use ieee.std_logic_textio.all;
use IEEE.numeric_std.all;

--library work;
--use work.tb_top_pkg.all;

ENTITY tb_triangle_gen IS
END ENTITY tb_triangle_gen;

ARCHITECTURE behavior OF tb_triangle_gen IS------------------------------------------------------------------------------


COMPONENT triangle_gen IS
  port (
   rst_n : in std_logic;
   clk   : in std_logic;
   en    : in std_logic;

   run   : in std_logic;
   data  : out std_logic_vector(7 downto 0));
END COMPONENT triangle_gen;


COMPONENT pdm IS
  port(
   rst_n   : in std_logic;
   clk     : in std_logic;
   en      : in std_logic;

   run     : in std_logic;
   x_in    : in std_logic_vector(7 downto 0);
   y_out   : out std_logic);
END COMPONENT pdm;

COMPONENT fir IS
  generic (
    filter_taps : natural := 101
  );
  port (
   rst_n : in std_logic;
   clk   : in std_logic;
   en    : in std_logic;

   data_in   : in std_logic;
   dec_valid : out std_logic;
   data_out  : out std_logic_vector(7 downto 0));
END COMPONENT fir;

COMPONENT capture IS
  port (
   rst_n : in std_logic;
   clk   : in std_logic;
   en    : in std_logic;

   run       : in std_logic;
   data_in   : in std_logic_vector(7 downto 0);
   dec_valid : in std_logic;
   -- fifo interface
   data_w     : OUT std_logic_vector(63 downto 0);
   we         : OUT std_logic;
   full_w     : IN  std_logic);
END COMPONENT capture;

-------------------------------------------------------------------------------
   constant clk_period_25   : time := 400 ns;
   signal clk_25 : std_logic := '0';
   signal run    : std_logic := '0';
   signal en     : std_logic := '0';
   signal rst_n  : std_logic := '0';
   signal triangle_data : std_logic_vector(7 downto 0);
   signal pdm_data : std_logic;
   signal data_out : std_logic_vector(7 downto 0);
   signal dec_valid : std_logic;
   -- control signals
   signal stop_sim: boolean := false;
   signal p : std_logic;

   file file_RESULTS : text;
   file file_RESULTS_DEC : text;

begin

   i_tri_gen : triangle_gen
   port map (
   rst_n => rst_n,
   clk   => clk_25,
   en    => en,

   run   => run,
   data  => triangle_data
   );

   i_pdm : pdm
   port map (
   rst_n   => rst_n,
   clk     => clk_25,
   en      => en,

   run     => run,
   x_in    => triangle_data,
   y_out   => pdm_data
   );

   i_fir : fir
   generic map (
   filter_taps => 101
   )
   port map (
   rst_n => rst_n,
   clk   => clk_25,
   en    => en,

   data_in  => pdm_data,
   dec_valid => dec_valid,
   data_out => data_out
   );

   i_capture : capture
   port map(
   rst_n => rst_n,
   clk   => clk_25,
   en    => en,

   run       => run,
   data_in   => data_out,
   dec_valid => dec_valid,
   -- fifo interface
   data_w    => open,
   we        => open,
   full_w    => '0'
   );

   clock_25: process
     variable num_clock : integer := 0;
     begin
        num_clock := num_clock + 1;
        clk_25 <= '0';
        wait for clk_period_25/2;  --
        clk_25 <= '1';
        wait for clk_period_25/2;  --
        if stop_sim = true then
          report "Number of clock is " & integer'image(num_clock);
          wait;
        end if;
   end process;

   dec_p: process
     variable dec : integer := 0;
     begin
        wait until clk_25 = '1';
        wait for 1 ns;
        if dec_valid = '1' then
          dec := dec + 1;
        end if;
        if stop_sim = true then
          report "Number of dec_valid pulses is " & integer'image(dec);
          wait;
        end if;
   end process;

   stimuli: process
     begin
     wait for 10 ns;
     rst_n <= '1';
     wait for 100 ns;
     en <= '1';
     run <= '1';
     wait for 5000 us;
     stop_sim <= true;
     wait;
   end process;

   write_results: process
   variable v_OLINE : line;
   begin
     file_open(file_RESULTS, "output_results.txt", write_mode);

     wait until rst_n = '1' and run = '1';
     for k in 0 to 12500 loop --12500
       wait until clk_25 = '1';
       wait for 1 ns;
       write(v_OLINE, data_out, right, 8);
       --write(line_var, integer'image(to_integer(unsigned(data_out))));
       writeline(file_RESULTS, v_OLINE);
     end loop;
     file_close(file_RESULTS);
     wait;
   end process;

   write_results_dec: process
   variable v_OLINE : line;
   begin
     file_open(file_RESULTS_DEC, "output_results_dec.txt", write_mode);

     wait until rst_n = '1' and run = '1';
     for k in 0 to 223 loop --
       wait until dec_valid = '1';
       wait for 1 ns;
       write(v_OLINE, data_out, right, 8);
       --write(line_var, integer'image(to_integer(unsigned(data_out))));
       writeline(file_RESULTS_DEC, v_OLINE);
     end loop;
     file_close(file_RESULTS_DEC);
     wait;
   end process;

end ARCHITECTURE behavior;

