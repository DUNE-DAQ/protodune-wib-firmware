----------------------------------------------------------------------------------
-- Company: Boston University EDF
-- Engineer: Dan Gastler
--
-- package for interface to the FEMB daq links
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.COLDATA_IO.all;
use work.types.all;

package DCC_IO is

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
  end record DTS_SI5344_Monitor_t;
  
  
  type DCC_FEMB_CMD_Monitor_t is record
    trigger_enable  : std_logic;
  end record DCC_FEMB_CMD_Monitor_t;

  type DCC_CLK_CFG_Monitor_t is record
    reset_SI5338    : std_logic;
    program_state   : std_logic_vector(7 downto 0);
    clk_switch      : std_logic;
    cmd_switch      : std_logic;
    reset_DUNE_PLL  : std_logic;
    reset_FEMB_PLL  : std_logic;
    locked_DUNE_PLL : std_logic;
    locked_FEMB_PLL : std_logic;
  end record DCC_CLK_CFG_Monitor_t;

  type PDTS_Monitor_t is record
    enable       : std_logic;
    CMD_count_reset : std_logic_vector(15 downto 0);
    CMD_count    : uint32_array_t(15 downto 0);
    timing_group : std_logic_vector(1 downto 0);
    sfp_los      : std_logic;
    cdr_los      : std_logic;
    cdr_lol      : std_logic;
    state        : std_logic_vector(3 downto 0);
    ready        : std_logic;
    reset        : std_logic;
  end record PDTS_Monitor_t;

  type FAKE_DTS_Monitor_t is record
    reset_count : std_logic;
    enable      : std_logic;
  end record FAKE_DTS_Monitor_t;

  
  type DCC_Monitor_t is record
    CDS            : DTS_CDS_Monitor_t;
    SI5344         : DTS_SI5344_Monitor_t;    
    reset_count    : std_logic_vector(23 downto 0);
    convert_count  : std_logic_vector(15 downto 0);
    time_stamp     : std_logic_vector(63 downto 0);
--    trigger_enable : std_logic;
    slot_id        : std_logic_vector(2 downto 0);
    crate_id       : std_logic_vector(4 downto 0);
    DUNE_clk_sel   : std_logic;
    FAKE_DTS       : FAKE_DTS_Monitor_t;
    PDTS           : PDTS_Monitor_t;
    CLK_CFG        : DCC_CLK_CFG_Monitor_t;
    FEMB_CMD       : DCC_FEMB_CMD_Monitor_t;
    local_triggering : std_logic;
    local_timestamp : std_logic;
  end record DCC_Monitor_t;

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
  end record DTS_I2C_Control_t;
  constant DEFAULT_DTS_I2C_Control : DTS_I2C_Control_t := (run => '0',
                                                           rw => '0',
                                                           byte_count => "000",
                                                           address => x"00",
--                                                          rd_data => x"00000000",
                                                           wr_data => x"00000000");

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
  end record DTS_SI5344_Control_t;
  constant DEFAULT_DTS_SI5344_Control : DTS_SI5344_Control_t := (I2C => DEFAULT_DTS_I2C_Control,
                                                                 enable => '1',
                                                                 reset => '0',
                                                                 in_sel => "01");
  
  type DCC_FEMB_CMD_Control_t is record
    trigger_enable       : std_logic;
    inject_calibrate     : std_logic;
    inject_sync          : std_logic;
    inject_COLDATA_reset : std_logic;
  end record DCC_FEMB_CMD_Control_t;
  constant DEFAULT_DCC_FEMB_CMD_Control : DCC_FEMB_CMD_Control_t := (trigger_enable       => '0',
                                                                     inject_calibrate     => '0',
                                                                     inject_sync          => '0',
                                                                     inject_COLDATA_reset => '0');

  type DCC_CLK_CFG_Control_t is record
    reset_SI5338    : std_logic;
    clk_switch      : std_logic;
    cmd_switch      : std_logic;
    reset_DUNE_PLL  : std_logic;
    reset_FEMB_PLL  : std_logic;
    locked_DUNE_PLL : std_logic;
    locked_FEMB_PLL : std_logic;

  end record DCC_CLK_CFG_Control_t;
  constant DEFAULT_DCC_CLK_CFG_control : DCC_CLK_CFG_Control_t := (reset_SI5338    => '0',
                                                                   clk_switch      => '0',
                                                                   cmd_switch      => '0',
                                                                   reset_DUNE_PLL  => '0',
                                                                   reset_FEMB_PLL  => '0',
                                                                   locked_DUNE_PLL => '0',
                                                                   locked_FEMB_PLL => '0'
                                                                   );

  type PDTS_Control_t is record
    enable       : std_logic;
    timing_group : std_logic_vector(1 downto 0);
    CMD_count_reset : std_logic_vector(15 downto 0);
  end record PDTS_Control_t;
  constant DEFAULT_PDTS_Control : PDTS_Control_t := (enable => '0',
                                                     timing_group => "00",
                                                     CMD_count_reset => x"0000");

  type FAKE_DTS_Control_t is record
    reset_count : std_logic;
    enable      : std_logic;
  end record FAKE_DTS_Control_t;
  constant DEFAULT_FAKE_DTS_Control : FAKE_DTS_Control_t := (reset_count => '0',enable=>'1');
  
  
  type DCC_Control_t is record
    slot_id      : std_logic_vector(2 downto 0);
    crate_id     : std_logic_vector(4 downto 0);
    DUNE_clk_sel : std_logic;
    PDTS         : PDTS_Control_t;
    CDS          : DTS_CDS_Control_t;
    SI5344       : DTS_SI5344_Control_t;
    FAKE_DTS     : FAKE_DTS_Control_t;
    CLK_CFG      : DCC_CLK_CFG_Control_t;
    FEMB_CMD     : DCC_FEMB_CMD_Control_t;
    local_triggering : std_logic;
    local_timestamp : std_logic;
  end record DCC_Control_t;

  --constant used for default settings 
  constant DEFAULT_DCC_control : DCC_Control_t := (slot_id      => "000",
                                                   crate_id     => "00000",
                                                   DUNE_clk_sel => '1',
                                                   PDTS         => DEFAULT_PDTS_Control,
                                                   CDS          => DEFAULT_DTS_CDS_Control,
                                                   SI5344       => DEFAULT_DTS_SI5344_Control,
                                                   FAKE_DTS     => DEFAULT_FAKE_DTS_Control,
                                                   CLK_CFG      => DEFAULT_DCC_CLK_CFG_control,
                                                   FEMB_CMD     => DEFAULT_DCC_FEMB_CMD_control,
                                                   local_triggering => '1',
                                                   local_timestamp  => '1');

end DCC_IO;
