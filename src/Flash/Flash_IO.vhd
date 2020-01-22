----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interface to the Flash
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.types.all;

package Flash_IO is
  constant FLASH_PAGE_SIZE : integer := 64;
  
  type Flash_Monitor_t is record
    data          : uint32_array_t(FLASH_PAGE_SIZE -1 downto 0);
    busy          : std_logic;
    byte_count    : std_logic_vector( 7 downto  0);
    read_address  : std_logic_vector(23 downto  0);
    address       : std_logic_vector(23 downto  0);
    status        : std_logic_vector( 7 downto  0);
    illegal_write : std_logic;
    illegal_erase : std_logic;
    reconfig_param : std_logic_vector(2 downto 0);
    reconfig_rd_data : std_logic_vector(23 downto 0);
    reconfig_busy : std_logic;
    reconfig      : std_logic;
  end record Flash_Monitor_t;

  type Flash_Control_t is record
    data       : std_logic_vector(31 downto 0);
    data_address: integer range FLASH_PAGE_SIZE -1 downto 0;
    data_wr    : std_logic;
    wr         : std_logic;
    rd         : std_logic; 
    erase      : std_logic;
    status_rd  : std_logic;
    byte_count : std_logic_vector(7 downto 0);
    address    : std_logic_vector(23 downto 0);
    reconfig_rd_param : std_logic;
    reconfig_wr_param : std_logic;
    reconfig_param    : std_logic_vector(2 downto 0);    
    reconfig   : std_logic;
    reconfig_reset : std_logic;
    reconfig_wr_data : std_logic_vector(23 downto 0);
  end record Flash_Control_t;
  constant DEFAULT_Flash_Control_t : Flash_Control_t := (data       => x"00000000",
                                                         data_address => 0,
                                                         data_wr    => '0',
                                                         wr         => '0',
                                                         rd         => '0',
                                                         erase      => '0',
                                                         status_rd  => '0',
                                                         byte_count => x"00",
                                                         address    => x"000000",
                                                         reconfig_rd_param => '0',
                                                         reconfig_wr_param => '0',
                                                         reconfig_param => "000",
                                                         reconfig   => '0',
                                                         reconfig_reset => '0',
                                                         reconfig_wr_data => (others => '0')
                                                         );
  
end package Flash_IO;
