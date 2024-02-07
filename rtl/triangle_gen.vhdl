LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;


entity triangle_gen IS
  port (
   rst_n : in std_logic;
   clk   : in std_logic;
   en    : in std_logic;

   run   : in std_logic;
   data  : out std_logic_vector(7 downto 0));
END ENTITY triangle_gen;

ARCHITECTURE rtl OF triangle_gen IS
  --registers
  signal aux_cnt_c : unsigned(3 downto 0);
  signal aux_cnt_s : unsigned(3 downto 0);
  signal data_cnt_c : unsigned(7 downto 0);
  signal data_cnt_s : unsigned (7 downto 0);
  signal cnt_direction_c : std_logic;
  signal cnt_direction_s : std_logic;
  -- signals
  signal aux_cnt_done : std_logic;
  BEGIN

  reg : PROCESS (rst_n, clk)
   BEGIN
    IF rst_n = '0' THEN
      cnt_direction_s <= '0';
      aux_cnt_s <= (others => '0');
      data_cnt_s <= (others => '0');
    ELSIF clk = '1' AND clk'EVENT THEN
      IF en = '1' THEN
        cnt_direction_s <= cnt_direction_c;
        aux_cnt_s <= aux_cnt_c;
        data_cnt_s <= data_cnt_c;
      END IF;
    END IF;
 END PROCESS reg;

aux_cnt_done <= '0' when aux_cnt_s < 11 else
                '1';

 -- aux_cnt count to 11
 aux_cnt_c <= aux_cnt_s + 1 when aux_cnt_done = '0' and run = '1' else
              (others => '0');

 cnt_direction_c <= not cnt_direction_s when (data_cnt_s = 255 and cnt_direction_s = '0') or (data_cnt_s = 0 and cnt_direction_s = '1') else
                    cnt_direction_s;

 -- main data counter
 data_cnt_c <= data_cnt_s + 1 when cnt_direction_s = '0' and run = '1' and aux_cnt_done = '1' else
               data_cnt_s - 1 when cnt_direction_s = '1' and run = '1' and aux_cnt_done = '1' else
               (others => '0') when run = '0' else
               data_cnt_s;


-- output assigment
data <= std_logic_vector(data_cnt_s);

END ARCHITECTURE RTL;
