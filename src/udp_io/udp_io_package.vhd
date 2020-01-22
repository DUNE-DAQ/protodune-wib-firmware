----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interface to the UDP io
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;


package NET_IO is

  type UDP_Monitor_t is record
    en_readback       : std_logic;
    timeout           : std_logic_vector(31 downto 0);
    frame_size        : std_logic_vector(11 downto 0);
    DQM_ip_dest_addr  : std_logic_vector(31 downto 0);
    DQM_mac_dest_addr : std_logic_vector(47 downto 0);
    DQM_dest_port     : std_logic_vector(15 downto 0);
  end record UDP_Monitor_t;

  type UDP_Control_t is record
    en_readback : std_logic;
    timeout     : std_logic_vector(31 downto 0);
    frame_size  : std_logic_vector(11 downto 0);
  end record UDP_Control_t;
  constant DEFAULT_UDP_Control : UDP_Control_t := (en_readback => '1',
                                                   timeout => x"00001000",
                                                   frame_size => x"1f8");
  
end package NET_IO;

