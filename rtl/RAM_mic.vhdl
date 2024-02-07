library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity RAM_mic is
   GENERIC (
     word : natural; -- := 8;
     adr  : natural-- := 8
    );
    Port ( CLK1  : in  STD_LOGIC;
           ADR1  : in  STD_LOGIC_VECTOR (adr downto 0);
           DATA1 : in  STD_LOGIC_VECTOR (word-1 downto 0);
           WE    : in  STD_LOGIC;
              
           CLK2  : in  STD_LOGIC;
           ADR2  : in  STD_LOGIC_VECTOR (adr downto 0);
           DATA2 : out  STD_LOGIC_VECTOR (word-1 downto 0);
           RE    : in  STD_LOGIC);
end RAM_mic;

architecture RTL of RAM_mic is
TYPE tram_array IS ARRAY ((2**(adr+1))-1 downto 0) OF std_logic_vector (word-1 downto 0);
SIGNAL ram_mem :tram_array;
SIGNAL read_adress : std_logic_vector (adr downto 0);
begin
----------------------------------------------------------------------------
sync_ram_write: PROCESS (CLK1)
BEGIN
    IF CLK1'EVENT AND CLK1 = '1' THEN
        IF WE = '1' THEN
            ram_mem(to_integer(unsigned(ADR1))) <= DATA1;
        END IF;
    END IF;
END PROCESS sync_ram_write;
----------------------------------------------------------------------------
sync_ram_read: PROCESS (CLK2)
BEGIN
    IF CLK2'EVENT AND CLK2 = '1' THEN
        IF RE = '1' THEN
            read_adress <= ADR2;
                --DATA2 <= ram(to_integer(unsigned(read_adress)));
        END IF;
          --DATA2 <= ram(to_integer(unsigned(read_adress)));
    END IF;
END PROCESS sync_ram_read;
DATA2 <= ram_mem(to_integer(unsigned(read_adress)));

end RTL;
