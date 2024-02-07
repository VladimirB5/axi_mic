LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--use IEEE.numeric_std.all;

entity mic_model IS
  generic (
    G_DIAG : boolean -- diagnostig logic added
  );
  port (
  -- mic
  audio_clk            : IN std_logic;
  audio_do             : OUT std_logic
  );
END ENTITY mic_model;

