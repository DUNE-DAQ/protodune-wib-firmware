----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interfaces with the WIB Event builder
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package CD_EB_BRIDGE is

  
  type CD_stream_t is record
    valid : std_logic;
    capture_errors : std_logic_vector( 7 downto 0);
    CD_errors      : std_logic_vector(15 downto 0);
    CD_timestamp   : std_logic_vector(15 downto 0);
    -- CD_reserved : std_logic_vector( 7 downto 0);
    data_out       : std_logic_vector(31 downto 0);
  end record CD_stream_t;
  type CD_Stream_array_t is array (integer range <>) of CD_Stream_t;

  
end CD_EB_BRIDGE;
