----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interfaces with the WIB Event builder
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.WIB_Constants.all;
use work.GB_IO.all;

package EB_IO is

  -------------------------------------------------------------------------------
  -- Control
  -------------------------------------------------------------------------------
 
  
  type DAQ_Link_EB_Control_t is record
   enable            : std_logic; 
   COLDATA_en        : std_logic_vector(LINKS_PER_DAQ_LINK -1 downto 0);
   event_count_reset : std_logic;
   mismatch_count_reset : std_logic;
   timestamp_repeated_count_reset : std_logic;

   spy_buffer_wait_for_trigger : std_logic;
   spy_buffer_start  : std_logic;
   spy_buffer_read   : std_logic;
   debug             : std_logic;
   enable_bad_crc    : std_logic;
   bad_crc_bits      : std_logic_vector(15 downto 0);
   
   gearbox           : GB_Control_t;
   CD_readout_debug  : std_logic;
  end record DAQ_Link_EB_Control_t;
  type DAQ_Link_EB_Control_array_t is array (integer range <>) of DAQ_Link_EB_Control_t;
  constant DEFAULT_DAQ_Link_EB_CONTROL : DAQ_Link_EB_CONTROL_t := (enable => '0',
                                                                   COLDATA_en => (others => '0'),
                                                                   event_count_reset => '0',
                                                                   mismatch_count_reset => '0',
                                                                   timestamp_repeated_count_reset => '0',
                                                                   spy_buffer_wait_for_trigger => '0',
                                                                   spy_buffer_start => '0',
                                                                   spy_buffer_read => '0',
                                                                   debug => '0',
                                                                   enable_bad_crc => '0',
                                                                   bad_crc_bits => x"03FF",
                                                                   gearbox => DEFAULT_GB_CONTROL,
                                                                   CD_readout_debug => '0'
                                                                   );  

  type I2C_Control_t is record
    reset      : std_logic;
    run        : std_logic;
    rw         : std_logic;
    byte_count : std_logic_vector(2 downto 0);
    address    : std_logic_vector(7 downto 0);
    wr_data    : std_logic_vector(31 downto 0);
  end record I2C_Control_t;
  constant DEFAULT_I2C_Control : I2C_Control_t := (reset => '0',
                                                   run => '0',
                                                   rw => '0',
                                                   byte_count => "000",
                                                   address => x"00",
                                                   wr_data => x"00000000");

  type SI5342_Control_t is record
    I2C  : I2C_Control_t;
    enable : std_logic;
    reset  : std_logic;
    sel0   : std_logic;
    sel1   : std_logic;
  end record SI5342_Control_t;
  constant DEFAULT_SI5342_CONTROL : SI5342_Control_t := (I2C => DEFAULT_I2C_Control,
                                                         enable => '1',
                                                         reset => '0',
                                                         sel0 => '0',
                                                         sel1 => '0');

  type QSFP_Control_t is record
    reset : std_logic;
    LP_mode : std_logic;
    I2C_EN  : std_logic;
    I2C     : I2C_Control_t;
  end record QSFP_Control_t;
  constant DEFAULT_QSFP_CONTROL : QSFP_Control_t := (reset => '0',
                                                     LP_mode => '0',
                                                     I2C_EN => '1',
                                                     I2C => DEFAULT_I2C_Control);
  
  type EB_Control_t is record
    DAQ_Link_EB          : DAQ_Link_EB_Control_array_t(DAQ_LINK_COUNT downto 1);
    SI5342               : SI5342_Control_t;
    tx_reset             : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);    
    QSFP                 : QSFP_Control_t;
  end record EB_Control_t;
  constant DEFAULT_EB_CONTROL : EB_Control_t := (DAQ_Link_EB => (others => DEFAULT_DAQ_Link_EB_CONTROL) ,
                                                 SI5342 => DEFAULT_SI5342_CONTROL,
                                                 tx_reset           => (others => '0'),    
                                                 QSFP => DEFAULT_QSFP_CONTROL);



  -------------------------------------------------------------------------------
  -- Monitoring
  -------------------------------------------------------------------------------
  
  type DAQ_Link_EB_Monitor_t is record
    enable            : std_logic; 
    COLDATA_en   : std_logic_vector(LINKS_PER_DAQ_LINK -1 downto 0);
    fiber_number : std_logic_vector(1 downto 0);
    FEMB_mask    : std_logic_vector(FEMB_COUNT-1 downto 0);
    crate_id     : std_logic_vector(3 downto 0);
    slot_id      : std_logic_vector(3 downto 0);
    event_count  : std_logic_vector(31 downto 0);
    event_rate   : std_logic_vector(31 downto 0);
    mismatch_count : std_logic_vector(31 downto 0);
    timestamp_repeated_count : std_logic_vector(31 downto 0);
    sending_data : std_logic;
    
    spy_buffer_data    : std_logic_vector(35 downto 0);
    spy_buffer_empty   : std_logic;
    spy_buffer_running : std_logic;
    spy_buffer_wait_for_trigger : std_logic;

    debug             : std_logic;
    enable_bad_crc    : std_logic;
    bad_crc_bits      : std_logic_vector(15 downto 0);
    
    gearbox            : GB_Monitor_t;
    CD_readout_debug  : std_logic;
  end record DAQ_Link_EB_Monitor_t;
  type DAQ_Link_EB_Monitor_array_t is array (integer range <>) of DAQ_Link_EB_Monitor_t;

  type I2C_Monitor_t is record
    rw         : std_logic;
    byte_count : std_logic_vector(2 downto 0);
    address    : std_logic_vector(7 downto 0);
    rd_data    : std_logic_vector(31 downto 0);
    wr_data    : std_logic_vector(31 downto 0);
    done       : std_logic;
    error      : std_logic;
  end record I2C_Monitor_t;

  type SI5342_Monitor_t is record
    I2C   : I2C_Monitor_t;
    reset : std_logic;
    enable : std_logic;
    sel0   : std_logic;
    sel1   : std_logic;
    LOL    : std_logic;
    LOSXAXB : std_logic;
    LOS1    : std_logic;
    LOS2    : std_logic;
    LOS3    : std_logic;
    interrupt : std_logic;
  end record SI5342_Monitor_t;

  type QSFP_Monitor_t is record         -- I2C_Monitor_t
    reset     : std_logic;
    LP_mode   : std_logic;
    interrupt : std_logic;
    present   : std_logic;
    I2C_EN    : std_logic;
    I2C       : I2C_Monitor_t;
  end record QSFP_Monitor_t;
  
  type EB_Monitor_t is record
    DAQ_Link_EB            : DAQ_Link_EB_Monitor_array_t(FEMB_Count downto 1);

    SI5342             : SI5342_Monitor_t;

    QSFP               : QSFP_Monitor_t;
    tx_reset           : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);    
    tx_pll_powerdown   : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
    tx_analogreset     : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
    tx_digitalreset    : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);    
    tx_ready           : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
    tx_pll_locked      : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
    tx_cal_busy        : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);

  end record EB_Monitor_t;
  

  
end EB_IO;
