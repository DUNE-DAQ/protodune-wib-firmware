----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interface to the FEMB daq links
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
--use work.COLDATA_IO.all;
use work.types.all;
use work.HISTORY_IO.all;

package DTS_IO is

--  constant PDTS_CMD_START  : std_logic_vector(3 downto 0) := x"1";
--  constant PDTS_CMD_STOP   : std_logic_vector(3 downto 0) := x"2";
--  constant PDTS_CMD_CALIB  : std_logic_vector(3 downto 0) := x"3";
--  constant PDTS_CMD_TM_RST : std_logic_vector(3 downto 0) := x"4";
  

  
  -------------------------------------------------------------------------------
  -- Monitor
  -------------------------------------------------------------------------------

  type DTS_I2C_Monitor_t is record
    rw         : std_logic;
    byte_count : std_logic_vector(2 downto 0);
    address    : std_logic_vector(7 downto 0);
    rd_data    : std_logic_vector(31 downto 0);
    wr_data    : std_logic_vector(31 downto 0);
    done       : std_logic;
    error      : std_logic;
    reset      : std_logic;
  end record DTS_I2C_Monitor_t;

  type DTS_CDS_Monitor_t is record
    I2C : DTS_I2C_Monitor_t;
    input_select : std_logic;
    LOL : std_logic;
    LOS : std_logic;
  end record DTS_CDS_Monitor_t;

  type DTS_SI5344_Monitor_t is record
    I2C : DTS_I2C_Monitor_t;
    interrupt : std_logic;
    enable    : std_logic;
    reset     : std_logic;
    LOL       : std_logic;
    LOS       : std_logic;
    in_sel    : std_logic_vector(1 downto 0);
    count_reset_requests   : std_logic_vector(31 downto 0);
    count_performed_resets : std_logic_vector(31 downto 0);    
  end record DTS_SI5344_Monitor_t;
  
 
  type DTS_Convert_Monitor_t is record
    converts_enabled      : std_logic;
    use_local_timestamp   : std_logic;
    sync_counter_period   : std_logic_vector(31 downto 0);
    last_good_sync         : std_logic_vector(63 downto 0);
    missed_periodic_syncs : std_logic_vector(31 downto 0);
    out_of_sync           : std_logic;
    halt                  : std_logic;
    state                 : std_logic_vector(3 downto 0);
    enable_fake           : std_logic;
    blame_counter         : std_logic_vector(31 downto 0);
    DAQ_timestamps_before_sync : std_logic_vector(3 downto 0);
  end record DTS_Convert_Monitor_t;
  
  type PDTS_Monitor_t is record
    enable       : std_logic;
    enable_resetter : std_logic;
    resetter_count : std_logic_vector(31 downto 0);
    resetter_count_reset : std_logic;
    CMD_count_reset : std_logic_vector(15 downto 0);
    CMD_count    : uint32_array_t(15 downto 0);    
    timing_group : std_logic_vector(1 downto 0);
    state        : std_logic_vector(3 downto 0);
    ready        : std_logic;
    reset        : std_logic;
    timestamp    : std_logic_vector(63 downto 0);
    event_number : std_logic_vector(31 downto 0);
    data_clk_reset : std_logic;
    locked_data_clock : std_logic;
    rec_8b_word       : std_logic_vector(8 downto 0);
    rec_10b_word      : std_logic_vector(9 downto 0);
    addr              : std_logic_vector(7 downto 0);
    addr_override_en  : std_logic;
    override_addr     : std_logic_vector(7 downto 0);
  end record PDTS_Monitor_t;

  type DTS_Tx_Monitor_t is record
    OE                   : std_logic;
    buffered_loopback    : std_logic;
  end record DTS_Tx_Monitor_t;
  
  type DTS_Monitor_t is record
    CDS            : DTS_CDS_Monitor_t;
    SI5344         : DTS_SI5344_Monitor_t;
    DTS_Convert    : DTS_Convert_Monitor_t;
    PDTS           : PDTS_Monitor_t;
    history        : HISTORY_monitor_t;
    DTS_Tx         : DTS_Tx_Monitor_t;
    clk_DUNE_in_locked : std_logic;
    clk_DUNE_in_reset  : std_logic;
--    CLK_CFG        : DTS_CLK_CFG_Monitor_t;
--    FEMB_CMD       : DTS_FEMB_CMD_Monitor_t;
--    local_triggering : std_logic;
  end record DTS_Monitor_t;

  -------------------------------------------------------------------------------
  -- Control
  -------------------------------------------------------------------------------
  type DTS_I2C_Control_t is record
    run        : std_logic;
    rw         : std_logic;
    byte_count : std_logic_vector(2 downto 0);
    address    : std_logic_vector(7 downto 0);
--    rd_data    : std_logic_vector(31 downto 0);
    wr_data    : std_logic_vector(31 downto 0);
    reset      : std_logic;
  end record DTS_I2C_Control_t;
  constant DEFAULT_DTS_I2C_Control : DTS_I2C_Control_t := (run => '0',
                                                           rw => '0',
                                                           byte_count => "000",
                                                           address => x"00",
--                                                          rd_data => x"00000000",
                                                           wr_data => x"00000000",
                                                           reset   => '1');

  type DTS_CDS_Control_t is record
    I2C : DTS_I2C_Control_t;
    input_select : std_logic;
  end record DTS_CDS_Control_t;
  constant DEFAULT_DTS_CDS_Control : DTS_CDS_Control_t := (I2C => DEFAULT_DTS_I2C_Control,
                                                           input_select => '0');

  type DTS_SI5344_Control_t is record
    I2C : DTS_I2C_Control_t;
    enable : std_logic;
    reset  : std_logic;
    in_sel : std_logic_vector(1 downto 0);
    reset_count_reset_requests   : std_logic;
    reset_count_performed_resets : std_logic;    
  end record DTS_SI5344_Control_t;
  constant DEFAULT_DTS_SI5344_Control : DTS_SI5344_Control_t := (I2C => DEFAULT_DTS_I2C_Control,
                                                                 enable => '1',
                                                                 reset => '0',
                                                                 in_sel => "01",
                                                                 reset_count_reset_requests   => '0',
                                                                 reset_count_performed_resets => '0'
                                                                 );
  
--  type DTS_FEMB_CMD_Control_t is record
--    trigger_enable       : std_logic;
--    inject_calibrate     : std_logic;
--    inject_sync          : std_logic;
--    inject_COLDATA_reset : std_logic;
--  end record DTS_FEMB_CMD_Control_t;
--  constant DEFAULT_DTS_FEMB_CMD_Control : DTS_FEMB_CMD_Control_t := (trigger_enable       => '0',
--                                                                     inject_calibrate     => '0',
--                                                                     inject_sync          => '0',
--                                                                     inject_COLDATA_reset => '0');

--  type DTS_CLK_CFG_Control_t is record
--    reset_SI5338    : std_logic;
--    clk_switch      : std_logic;
--    cmd_switch      : std_logic;
--    reset_DUNE_PLL  : std_logic;
--    reset_FEMB_PLL  : std_logic;
--    locked_DUNE_PLL : std_logic;
--    locked_FEMB_PLL : std_logic;
--  end record DTS_CLK_CFG_Control_t;
--  constant DEFAULT_DTS_CLK_CFG_control : DTS_CLK_CFG_Control_t := (reset_SI5338    => '0',
--                                                                   clk_switch      => '0',
--                                                                   cmd_switch      => '0',
--                                                                   reset_DUNE_PLL  => '0',
--                                                                   reset_FEMB_PLL  => '0',
--                                                                   locked_DUNE_PLL => '0',
--                                                                   locked_FEMB_PLL => '0'
--                                                                   );

  type DTS_Convert_Control_t is record
    converts_enabled      : std_logic;
    use_local_timestamp   : std_logic;
    halt                  : std_logic;
    start_sync            : std_logic;
    sync_counter_period   : std_logic_vector(31 downto 0);
    enable_fake           : std_logic;
    DAQ_timestamps_before_sync : std_logic_vector(3 downto 0);
  end record DTS_Convert_Control_t;
  constant DEFAULT_DTS_CONVERT_control : DTS_Convert_Control_t := (converts_enabled    => '0',
                                                                   use_local_timestamp => '0',
                                                                   halt                => '1',
                                                                   start_sync          => '0',
                                                                   sync_counter_period  => x"02faf080",
                                                                   enable_fake         => '0',
                                                                   DAQ_timestamps_before_sync => x"0"
                                                                   );
  
  type PDTS_Control_t is record
    enable       : std_logic;
    enable_resetter : std_logic;
    resetter_count_reset : std_logic;
    timing_group : std_logic_vector(1 downto 0);
    CMD_count_reset : std_logic_vector(15 downto 0);
    data_clk_reset : std_logic;
    addr_override_en  : std_logic;
    override_addr     : std_logic_vector(7 downto 0);
  end record PDTS_Control_t;
  constant DEFAULT_PDTS_Control : PDTS_Control_t := (enable => '0',
                                                     enable_resetter => '0',
                                                     resetter_count_reset => '0',
                                                     timing_group => "00",
                                                     CMD_count_reset => x"0000",
                                                     data_clk_reset => '0',
                                                     addr_override_en => '0',
                                                     override_addr => x"65");
  

  type DTS_Tx_Control_t is record
    OE                   : std_logic;
    buffered_loopback    : std_logic;
  end record DTS_Tx_Control_t;
  constant DEFAULT_DTS_Tx_Control : DTS_Tx_Control_t := (OE => '1',
                                                         buffered_loopback => '1');
  
  type DTS_Control_t is record
    DUNE_clk_sel : std_logic;
    PDTS         : PDTS_Control_t;    
    CDS          : DTS_CDS_Control_t;
    SI5344       : DTS_SI5344_Control_t;
    DTS_Convert  : DTS_Convert_Control_t;
    history      : HISTORY_control_t;
    DTS_Tx       : DTS_Tx_Control_t;
  end record DTS_Control_t;

  --constant used for default settings 
  constant DEFAULT_DTS_control : DTS_Control_t := (DUNE_clk_sel => '1',
                                                   PDTS         => DEFAULT_PDTS_Control,
                                                   CDS          => DEFAULT_DTS_CDS_Control,
                                                   SI5344       => DEFAULT_DTS_SI5344_Control,
                                                   DTS_Convert  => DEFAULT_DTS_CONVERT_Control,
                                                   history      => DEFAULT_HISTORY_Control_t,
                                                   DTS_Tx       => DEFAULT_DTS_Tx_Control);

end DTS_IO;
