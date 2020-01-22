----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for the convert signals and meta-data from the DCC
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package Convert_IO is
  constant COLDATA_CONVERT_PERIOD_128MHZ : integer := 62;  --640; --
  
  type convert_t is record
    trigger       : std_logic;
    reset_count   : std_logic_vector(23 downto 0);
    convert_count : std_logic_vector(15 downto 0);
    time_stamp    : std_logic_vector(63 downto 0);
    out_of_sync   : std_logic;
  end record convert_t;
  constant DEFAULT_CONVERT : convert_t := (trigger       => '0',
                                           reset_count   => x"FFFFFF",
                                           convert_count => x"FFFF",
                                           time_stamp    => x"FFFFFFFFFFFFFFFF",
                                           out_of_sync   => '1'
                                           );
  
  type convert_simple_t is record
    trigger       : std_logic;
    reset_count   : std_logic_vector(23 downto 0);
    convert_count : std_logic_vector(15 downto 0);  
    slot_id       : std_logic_vector(2 downto 0);
    crate_id      : std_logic_vector(4 downto 0);
  end record convert_simple_t;
  
end Convert_IO;
