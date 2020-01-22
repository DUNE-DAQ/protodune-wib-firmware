----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for history_monitor records
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package HISTORY_IO is

  type HISTORY_monitor_t is record
    data      : std_logic_vector(8 downto 0);
    presample : std_logic;
    valid     : std_logic;
  end record HISTORY_monitor_t;

  type HISTORY_control_t is record
    ack : std_logic;
  end record HISTORY_control_t;
  constant DEFAULT_History_Control_t : History_control_t := (ack => '0');

end package HISTORY_IO;
