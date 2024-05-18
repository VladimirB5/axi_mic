LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;


entity pdm IS
  port (
   rst_n   : in std_logic;
   clk     : in std_logic;
   en      : in std_logic;

   run     : in std_logic;
   x_in    : in std_logic_vector(7 downto 0);
   y_out   : out std_logic);
END ENTITY pdm;


ARCHITECTURE rtl OF pdm IS
   signal error_c, error_s : unsigned(7 downto 0);
   signal y_c, y_s         : unsigned(7 downto 0);

begin
  reg : PROCESS (rst_n, clk)
   BEGIN
    IF rst_n = '0' THEN
      error_s <= (others => '0');
      y_s <= (others => '0');
    ELSIF clk = '1' AND clk'EVENT THEN
      IF en = '1' THEN
        error_s <= error_c;
        y_s     <= y_c;
      END IF;
    END IF;
 END PROCESS reg;

 y_c <= to_unsigned(255,8) when unsigned(x_in) > error_s else
        to_unsigned(0,8);

 error_c <= (y_c - unsigned(x_in)) + error_s;

 -- output assigment
 y_out <= std_logic(y_s(0));

END ARCHITECTURE RTL;
