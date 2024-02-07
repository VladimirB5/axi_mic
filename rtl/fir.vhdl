LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;


entity fir IS
  port (
   rst_n : in std_logic;
   clk   : in std_logic;
   en    : in std_logic;

   data_in   : in std_logic_vector(7 downto 0);
   dec_valid : out std_logic;
   data_out  : out std_logic_vector(7 downto 0));
END ENTITY fir;

ARCHITECTURE rtl OF fir IS
  -- constant
  constant decim_factor : unsigned(7 downto 0) := X"37"; --dec 55

  -- registers
  type add is array (0 to 100) of unsigned(17 downto 0);
  signal add_results_c, add_results_s : add;

  signal valid_cnt_c, valid_cnt_s : unsigned(7 downto 0);

  -- signals

  type mult is array(0 to 100) of unsigned(15 downto 0);
  signal mult_results : mult;

  type coefficients is array (0 to 100) of unsigned(7 downto 0);
  signal coef: coefficients :=(
 x"00", x"00", x"00", x"00", x"00",
 x"00", x"00", x"00", x"00", x"00",
 x"00", x"00", x"00", x"01", x"01",
 x"01", x"01", x"01", x"01", x"01",
 x"01", x"01", x"01", x"01", x"01",
 x"01", x"01", x"01", x"01", x"02",
 x"02", x"02", x"02", x"02", x"02",
 x"02", x"02", x"02", x"02", x"02",
 x"02", x"02", x"02", x"02", x"02",
 x"02", x"02", x"02", x"02", x"02",
 x"02", x"02", x"02", x"02", x"02",
 x"02", x"02", x"02", x"02", x"02",
 x"02", x"02", x"02", x"02", x"02",
 x"02", x"02", x"02", x"02", x"02",
 x"02", x"02", x"01", x"01", x"01",
 x"01", x"01", x"01", x"01", x"01",
 x"01", x"01", x"01", x"01", x"01",
 x"01", x"01", x"01", x"00", x"00",
 x"00", x"00", x"00", x"00", x"00",
 x"00", x"00", x"00", x"00", x"00",
 x"00"

  );

  BEGIN
  reg : PROCESS (rst_n, clk)
   BEGIN
    IF rst_n = '0' THEN
      for i in 0 to 100 loop
        add_results_s(i) <= (others => '0');
      end loop;
      valid_cnt_s <= (others => '0');
    ELSIF clk = '1' AND clk'EVENT THEN
      IF en = '1' THEN
        for i in 0 to 100 loop
          add_results_s(i) <= add_results_c(i);
        end loop;
        valid_cnt_s <= valid_cnt_c;
      END IF;
    END IF;
 END PROCESS reg;

  mult_results(0) <= unsigned(data_in) * coef(0);
  add_results_c(0) <= ("00" & mult_results(0));

  G_1 : for I in 1 to 100 generate
    mult_results(I) <= unsigned(data_in) * coef(I);
    add_results_c(I) <= mult_results(I) + add_results_s(I-1);
  end generate;

  -- decimation counter
  dec_counter: process(valid_cnt_s)
    BEGIN
    valid_cnt_c <= valid_cnt_s + 1;
    dec_valid <= '0';
    IF valid_cnt_s = decim_factor THEN
      valid_cnt_c <= (others => '0');
      dec_valid <= '1';
    END IF;
  END PROCESS dec_counter;

  -- output data assigment
  data_out <= std_logic_vector(add_results_s(100)(15 downto 8));
END ARCHITECTURE RTL;
