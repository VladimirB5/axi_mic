LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;


entity audio_aquire IS
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
END ENTITY audio_aquire;

ARCHITECTURE rtl OF audio_aquire IS

COMPONENT triangle_gen IS
  port (
   rst_n : in std_logic;
   clk   : in std_logic;
   en    : in std_logic;

   run   : in std_logic;
   data  : out std_logic_vector(7 downto 0));
END COMPONENT triangle_gen;


COMPONENT pdm IS
  port (
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
 -- interconnect signals
 signal triangle_data : std_logic_vector(7 downto 0);
 signal pdm_data      : std_logic;
 signal audio_data    : std_logic;
 signal dec_valid     : std_logic;
 signal filtered_data : std_logic_vector(7 downto 0);
 --signal audio_in_vec  : std_logic_vector(7 downto 0);
 -- register
 signal audio_in_s : std_logic;
BEGIN
  -------------------------------------------------------------------------------
  -- sequential
  -------------------------------------------------------------------------------
  -- capture input data into register on raising edge
  state_reg : PROCESS (clk, rst_n)
   BEGIN
    IF rst_n = '0' THEN
      audio_in_s <= '0';
    ELSIF clk = '1' AND clk'EVENT THEN
      IF en = '1' THEN
        audio_in_s <= audio_in;
      END IF;
    END IF;
  END PROCESS state_reg;


 test: if G_TEST = true generate

  i_triangle_gen : triangle_gen
  port map (
   rst_n => rst_n,
   clk   => clk,
   en    => en,
   --
   run   => test_en,
   data  => triangle_data
   );

  i_pdm : pdm
  port map(
   rst_n   => rst_n,
   clk     => clk,
   en      => en,

   run     => test_en,
   x_in    => triangle_data,
   y_out   => pdm_data
   );

   audio_data <= pdm_data when test_en = '1' else
                 audio_in_s;

 end generate test;

  no_test: if G_TEST = false generate

  audio_data <= audio_in_s;

  end generate no_test;

  i_fir : fir
  port map (
   rst_n => rst_n,
   clk   => clk,
   en    => en,

   data_in   => audio_data,
   dec_valid => dec_valid,
   data_out  => filtered_data
   );

  i_capture : capture
  port map(
   rst_n => rst_n,
   clk   => clk,
   en    => en,
   
   run       => run,
   data_in   => filtered_data,
   dec_valid => dec_valid,
   -- fifo interface
   data_w    => data_w,
   we        => we,
   full_w    => fifo_full
   );

END ARCHITECTURE RTL;

