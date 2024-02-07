LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;


entity capture IS
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
END ENTITY capture;

ARCHITECTURE rtl OF capture IS

  -- registers
  signal cnt_c, cnt_s   : unsigned(2 downto 0);
  signal data_c, data_s : std_logic_vector(63 downto 0);
  signal we_c, we_s : std_logic;
  BEGIN
-------------------------------------------------------------------------------
-- sequential
-------------------------------------------------------------------------------
  reg : PROCESS (rst_n, clk)
   BEGIN
    IF rst_n = '0' THEN
      cnt_s  <= (others => '0');
      data_s <= (others => '0');
      we_s   <= '0';
    ELSIF clk = '1' AND clk'EVENT THEN
      IF en = '1' then
        cnt_s  <= cnt_c;
        data_s <= data_c;
        we_s   <= we_c;
      end IF;
    END IF;
 END PROCESS reg;


-------------------------------------------------------------------------------
-- combinational parts
-------------------------------------------------------------------------------
  capture_p: PROCESS(data_s, dec_valid, data_in)
    BEGIN
    data_c <= data_s;
    if dec_valid = '1' then
      data_c(63 downto 8) <= data_s(55 downto 0);
      data_c(7 downto 0)  <= data_in;
    end if;
  END PROCESS capture_p;

  cnt_c <= cnt_s + 1 when dec_valid = '1' and run = '1' else
           (others => '0') when run = '0' else
           cnt_s;

  we_c <= '1' when cnt_s = 6 and dec_valid = '1' else
          '0';
-------------------------------------------------------------------------------
-- output assigment
-------------------------------------------------------------------------------
we     <= we_s;
data_w <= data_s;
END ARCHITECTURE RTL;
