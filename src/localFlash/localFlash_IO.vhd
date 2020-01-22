----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interface to the LocalFlash
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.types.all;

package LocalFlash_IO is
  type LocalFlash_Monitor_t is record
    wr_data    : std_logic_vector(31 downto 0);
    rd_data    : std_logic_vector(31 downto 0);
    addr       : std_logic_vector(15 downto 0);
    rw         : std_logic;
    reset      : std_logic;
    done       : std_logic;
    error      : std_logic;    
  end record LocalFlash_Monitor_t;

  type LocalFlash_Control_t is record
    rw         : std_logic;
    run        : std_logic;
    wr_data    : std_logic_vector(31 downto 0);
    rd_data    : std_logic_vector(31 downto 0);
    addr       : std_logic_vector(15 downto 0);
    reset      : std_logic;    
  end record LocalFlash_Control_t;
  constant DEFAULT_LocalFlash_Control_t : LocalFlash_Control_t := (rw => '0',
                                                                   run => '0',
                                                                   wr_data => (others => '0'),
                                                                   rd_data => (others => '0'),
                                                                   addr => x"0000",
                                                                   reset => '0');
  
end package LocalFlash_IO;
