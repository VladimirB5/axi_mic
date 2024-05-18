LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;


entity fir IS
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
END ENTITY fir;

ARCHITECTURE rtl OF fir IS
  -- constant
  constant decim_factor : unsigned(7 downto 0) := X"37"; --dec 55

  -- registers
  signal data_in_c, data_in_s : std_logic;
  type add is array (0 to filter_taps-1) of signed(17 downto 0);
  signal add_results_c, add_results_s : add;

  signal valid_cnt_c, valid_cnt_s : unsigned(7 downto 0);

  -- signals
  signal data : signed(7 downto 0);
  type mult is array(0 to filter_taps-1) of signed(15 downto 0);
  signal mult_results : mult;

  type coefficients is array (0 to filter_taps-1) of signed(7 downto 0);
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
      for i in 0 to filter_taps-1 loop
        add_results_s(i) <= (others => '0');
      end loop;
      valid_cnt_s <= (others => '0');
      data_in_s <= '0';
    ELSIF clk = '1' AND clk'EVENT THEN
      IF en = '1' THEN
        for i in 0 to filter_taps-1 loop
          add_results_s(i) <= add_results_c(i);
        end loop;
        valid_cnt_s <= valid_cnt_c;
        data_in_s <= data_in_c;
      END IF;
    END IF;
 END PROCESS reg;

 data_in_c <= data_in;

 data <= to_signed(1,8) when data_in_s = '1' else
         to_signed(-1,8);

  G_1 : for I in 0 to filter_taps-2 generate
    mult_results(I) <= data * coef(I);
    add_results_c(I) <= mult_results(I) + add_results_s(I+1);
  end generate;

  mult_results(filter_taps-1) <= data * coef(filter_taps-1);
  add_results_c(filter_taps-1) <= ( mult_results(filter_taps-1)(15 downto 14) & mult_results(filter_taps-1));

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
  data_out <= std_logic_vector(add_results_s(0)(7 downto 0));
END ARCHITECTURE RTL;
