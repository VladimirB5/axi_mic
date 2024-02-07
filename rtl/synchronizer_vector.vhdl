library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity synchronizer_vector is
    GENERIC (
        N : natural 
    );
    Port ( clk       : in  STD_LOGIC;
           res_n     : in  STD_LOGIC;
           data_in   : in  STD_LOGIC_VECTOR(N downto 0);
           data_out  : out  STD_LOGIC_VECTOR(N downto 0)
         );
end synchronizer_vector;

architecture RTL of synchronizer_vector is
SIGNAL data_A_d     : std_logic_vector(N downto 0);
SIGNAL data_A_q_B_d : std_logic_vector(N downto 0);
SIGNAL data_B_q     : std_logic_vector(N downto 0);
begin
   data_A_d <= data_in;
    regA_B : PROCESS (clk, res_n)
    BEGIN
        IF res_n = '0' THEN
            data_A_q_B_d <= (others => '0');
            data_B_q     <= (others => '0');
        ELSIF clk'EVENT AND clk='1' THEN
            data_A_q_B_d <= data_A_d;
            data_B_q     <= data_A_q_B_d;
        END IF;
    END PROCESS regA_B;
---------------------------------------------------------- output    
   data_out <= data_B_q;

end RTL;

