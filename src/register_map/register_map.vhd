library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.WIB_Constants.all;
use work.WIB_IO.all;
use work.FEMB_CNC_IO.all;
use work.FEMB_DAQ_IO.all;
use work.DTS_IO.all;
use work.EB_IO.all;
use work.DQM_IO.all;
use work.Flash_IO.all;
use work.localFlash_IO.all;
use work.NET_IO.all;
use work.WIB_PWR_IO.all;
use work.types.all;


use work.FW_TIMESTAMP.all;

entity register_map is

  generic (
    FIRMWARE_VERSION : std_logic_vector(31 downto 0) := x"00000000");
  

  port (
    clk_UDP    : in std_logic;
    locked_UDP : in std_logic;
    reset      : in std_logic;          -- state machine reset

    Ver_ID     : in  std_logic_vector(31 downto 0);
    data_in    : in  std_logic_vector(31 downto 0);
    WR_address : in  std_logic_vector(15 downto 0);
    RD_address : in  std_logic_vector(15 downto 0);
    WR_strb    : in  std_logic;
    RD_strb    : in  std_logic;
    data_out   : out std_logic_vector(31 downto 0);
    rd_ack     : out std_logic;
    wr_ack     : out std_logic;
    
    -- register clock domains
    clk_WIB         : in std_logic;
    clk_EVB         : in std_logic;
    clk_FEMB        : in std_logic;
    clk_services    : in std_logic;
    clk_flash       : in std_logic;
    clk_DUNE        : in std_logic;
    clk_FEMB_CnC    : in std_logic;
    locked_WIB      : in std_logic;
    locked_EVB      : in std_logic;
    locked_FEMB     : in std_logic;
    locked_services : in std_logic;
    locked_flash    : in std_logic;
    locked_DUNE     : in std_logic;
    locked_FEMB_CnC : in std_logic;

    -- intefaces to data
    WIB_control  : out WIB_control_t;
    WIB_monitor  : in  WIB_monitor_t;
    Flash_control : out Flash_control_t;
    Flash_monitor : in  Flash_monitor_t;
    localFlash_control : out localFlash_control_t;
    localFlash_monitor : in  localFlash_monitor_t;
    DTS_control  : out DTS_control_t;
    DTS_monitor  : in  DTS_monitor_t;
    FEMB_CNC_control : out FEMB_CNC_Control_t;
    FEMB_CNC_monitor : in  FEMB_CNC_Monitor_t;
    FEMB_DAQ_control : out FEMB_DAQs_control_t;
    FEMB_DAQ_monitor : in  FEMB_DAQs_monitor_t;
    EB_control   : out EB_control_t;
    EB_monitor   : in  EB_monitor_t;
    DQM_Control  : out DQM_Control_t;
    DQM_Monitor  : in  DQM_Monitor_t;
    UDP_Control  : out UDP_Control_t;
    UDP_Monitor  : in  UDP_Monitor_t;
    WIB_PWR_control : out WIB_PWR_Control_t;
    WIB_PWR_monitor : in  WIB_PWR_Monitor_t
    );
  

end entity register_map;

architecture Behavioral of register_map is

  component register_map_bridge is
    generic (
      CLOCK_DOMAINS : integer);
    port (
      clk_reg_map           : in  std_logic;
      reset                 : in  std_logic;
      WR_strobe             : in  std_logic;
      RD_strobe             : in  std_logic;
      WR_address            : in  std_logic_vector(15 downto 0);
      RD_address            : in  std_logic_vector;
      data_in               : in  std_logic_vector(31 downto 0);
      data_out              : out std_logic_vector(31 downto 0);
      rd_ack                : out std_logic;
      wr_ack                : out std_logic;
      clk_domain            : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
      clk_domain_locked     : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
      read_address_valid    : out std_logic_vector(CLOCK_DOMAINS-1 downto 0);
      read_address_ack      : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
      read_address          : out uint16_array_t(CLOCK_DOMAINS-1 downto 0);
      read_data_wr          : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
      read_data             : in  uint36_array_t(CLOCK_DOMAINS-1 downto 0);
      write_addr_data_valid : out std_logic_vector(CLOCK_DOMAINS-1 downto 0);
      write_addr_data_ack   : in  std_logic_vector(CLOCK_DOMAINS-1 downto 0);
      write_addr            : out uint16_array_t(CLOCK_DOMAINS-1 downto 0);
      write_data            : out uint32_array_t(CLOCK_DOMAINS-1 downto 0));
    
  end component register_map_bridge;

  component reseter is
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      reset       : out std_logic);
  end component reseter;

  component counter is
    generic (
      roll_over   : std_logic;
      end_value   : std_logic_vector;
      start_value : std_logic_vector;
      DATA_WIDTH  : integer);
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      enable      : in  std_logic;
      event       : in  std_logic;
      count       : out std_logic_vector(DATA_WIDTH-1 downto 0);
      at_max      : out std_logic);
  end component counter;

  component history_monitor is
    generic (
      HISTORY_BIT_LENGTH : integer;
      SIGNAL_COUNT       : integer);
    port (
      clk               : in  std_logic;
      reset             : in  std_logic;
      signals           : in  std_logic_vector(SIGNAL_COUNT-1 downto 0);
      start             : in  std_logic;
      stop              : in  std_logic;
      history_out       : out std_logic_vector(SIGNAL_COUNT-1 downto 0);
      history_presample : out std_logic;
      history_valid     : out std_logic;
      history_ack       : in  std_logic);
  end component history_monitor;

  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;
  
  -----------------------------------------------------------------------------
  -- types
  -----------------------------------------------------------------------------
  --type address_array_t is array (integer range <>) of std_logic_vector(15 downto 0);
  --type address_array_array_t is array (integer range <>) of array_address_t;

  -----------------------------------------------------------------------------
  -- Address space
  -----------------------------------------------------------------------------


  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R0     : unsigned(15 downto 0) := x"0000";
  -- 0 (r/w) global reset  (TODO)
  -- 1 (r/w) register reset (TODO)
  -- 2 (r/w) udp reset (TODO)
  -- 3 (r/w) FEMB clock encoder (TODO)
  -- 4 (r/w) HSD reset (TODO)
  
  ----------------------------
  -- SBND reg1
  ----------------------------
  constant SBND_R1     : unsigned(15 downto 0) := x"0001";
  -- 3..0 (r/w) FEMB clock encoder sw commands 4 downto 1 (TODO)
    
  ----------------------------
  -- SBND reg2
  ----------------------------
  constant SBND_R2     : unsigned(15 downto 0) := x"0002";
  -- 0 (r/w) WIB LED 0 and FEMB clock encoder disable command 1
  -- 7..1 (r/w) WIB LEDs (TODO)
  
  ----------------------------
  -- SBND reg3
  ----------------------------
  constant SBND_R3     : unsigned(15 downto 0) := x"0003";
  
  ----------------------------
  -- SBND reg4
  ----------------------------
  constant SBND_R4     : unsigned(15 downto 0) := x"0004";
  -- 0 (r/w) FEMB clock select (TODO)
  -- 1 (r/w) FEMB command select and enable clock output on lemo 1 input (TODO) 
  -- 3..2 (r/w) FEMB internal clock select??? (TODO)  
  
  ----------------------------
  -- SBND reg5
  ----------------------------
  constant SBND_R5     : unsigned(15 downto 0) := x"0005";
  -- 7..0 (r/w) power measure select (TODO)
  -- 16  (r/w) power measure start (TODO)
  
  ----------------------------
  -- SBND reg6
  ----------------------------
  constant SBND_R6     : unsigned(15 downto 0) := x"0006";  
  -- 31..0 (r) power measurements (TODO)

  ----------------------------
  -- SBND reg7
  ----------------------------
  constant SBND_R7     : unsigned(15 downto 0) := x"0007";
  -- 31     (r/w) UDP readout disabled (TODO)
  -- 19..16 (r/w) UDP monitoring Board select (TODO)
  -- 11..8  (r/w) UDP monitoring Chip select (TODO)
  -- 3..0  (r/w) UDP monitoring channel select (TODO)
  
  ----------------------------
  -- SBND reg8
  ----------------------------
  constant SBND_R8     : unsigned(15 downto 0) := x"0008";
  -- 0 (r/w) Board 0 3.6V en (TODO)
  -- 1 (r/w) Board 0 2.8V en (TODO)
  -- 2 (r/w) Board 0 2.5V en (TODO) 
  -- 3 (r/w) Board 0 1.5V en (TODO)
  -- 4 (r/w) Board 1 3.6V en (TODO)
  -- 5 (r/w) Board 1 2.8V en (TODO)
  -- 6 (r/w) Board 1 2.5V en (TODO) 
  -- 7 (r/w) Board 1 1.5V en (TODO)
  -- 8 (r/w) Board 2 3.6V en (TODO)
  -- 9 (r/w) Board 2 2.8V en (TODO)
  -- 10 (r/w) Board 2 2.5V en (TODO)
  -- 11 (r/w) Board 2 1.5V en (TODO)
  -- 12 (r/w) Board 3 3.6V en (TODO)
  -- 13 (r/w) Board 3 2.8V en (TODO)
  -- 14 (r/w) Board 3 2.5V en (TODO)
  -- 15 (r/w) Board 3 1.5V en (TODO)
  -- 16 (r/w) Board 0 Bias en (TODO)
  -- 17 (r/w) Board 1 Bias en (TODO)
  -- 18 (r/w) Board 2 Bias en (TODO)
  -- 19 (r/w) Board 3 Bias en (TODO)
     
  ----------------------------
  -- SBND reg9
  ----------------------------
  constant SBND_R9     : unsigned(15 downto 0) := x"0009";
  -- 0 (r/w) P-Pod enable (TODO)
  
  ----------------------------
  -- SBND reg10
  ----------------------------
  constant SBND_R10     : unsigned(15 downto 0) := x"000a";
  -- 0 (r/w) I2C wr strobe (TODO) (ok to make an action)
  -- 1 (r/w) I2c rd strobe (TODO) (ok to make an action)

  ----------------------------
  -- SBND reg11
  ----------------------------
  constant SBND_R11     : unsigned(15 downto 0) := x"000b";
  -- 3..0 (r/w) i2c byte count (TODO)

  ----------------------------
  -- SBND reg12
  ----------------------------
  constant SBND_R12     : unsigned(15 downto 0) := x"000c";
  -- 7..0 (r/w) i2c address (TODO)
  
  ----------------------------
  -- SBND reg13
  ----------------------------
  constant SBND_R13     : unsigned(15 downto 0) := x"000d";
  -- 7..0 (r/w) i2c write data (TODO)
  
  ----------------------------
  -- SBND reg14
  ----------------------------
  constant SBND_R14     : unsigned(15 downto 0) := x"000e";
  -- 31..0 (r) i2c read data (TODO)
  
  ----------------------------
  -- SBND reg15
  ----------------------------
  constant SBND_R15     : unsigned(15 downto 0) := x"000f";
  
  ----------------------------
  -- SBND reg16
  ----------------------------
  constant SBND_R16     : unsigned(15 downto 0) := x"0010";
  
  ----------------------------
  -- SBND reg17
  ----------------------------
  constant SBND_R17     : unsigned(15 downto 0) := x"0011";
  -- 0 (r/w) GXB analog reset (TODO)
  -- 1 (r/w) GXB digital reset (TODO)
  
  ----------------------------
  -- SBND reg18
  ----------------------------
  constant SBND_R18     : unsigned(15 downto 0) := x"0012";
  -- 3..0 (r/w) link stat sel ? (TODO)
  -- 8 (r/w) TS_latch ? (TODO)
  -- 15 (r/w) ERR cnt reset ? (TODO)
  
  ----------------------------
  -- SBND reg19
  ----------------------------
  constant SBND_R19     : unsigned(15 downto 0) := x"0013";
  
  ----------------------------
  -- SBND reg20
  ----------------------------
  constant SBND_R20     : unsigned(15 downto 0) := x"0014";
  -- 0 (r/w) tx packet not enable (TODO)
  -- 1 (r/w) tx packet fifo 
  -- 2 (r/w) tx analog reset
  -- 3 (r/w) tx digital reset
  -- 4 (r/w) tx pll powerdown enable?
  
  ----------------------------
  -- SBND reg21
  ----------------------------
  constant SBND_R21     : unsigned(15 downto 0) := x"0015";
  -- 15..0 (r/w) comma sequence (TODO)
  -- 17..16 (r/w) comm sequence k-char bits
  
  ----------------------------
  -- SBND reg22
  ----------------------------
  constant SBND_R22     : unsigned(15 downto 0) := x"0016";
  
  ----------------------------
  -- SBND reg23
  ----------------------------
  constant SBND_R23     : unsigned(15 downto 0) := x"0017";
  -- 
  
  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R24     : unsigned(15 downto 0) := x"0018";
  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R25     : unsigned(15 downto 0) := x"0019";
  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R26     : unsigned(15 downto 0) := x"001a";
  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R27     : unsigned(15 downto 0) := x"001b";
  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R28     : unsigned(15 downto 0) := x"001c";
  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R29     : unsigned(15 downto 0) := x"001d";
  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R30     : unsigned(15 downto 0) := x"001e";
  ----------------------------
  -- SBND reg0
  ----------------------------
  constant SBND_R31     : unsigned(15 downto 0) := x"001f";

  
  ----------------------------
  -- WIB Status
  ----------------------------
  constant WIB_STATUS     : unsigned(15 downto 0) := x"0100";
  -- 0 (a) global reset
  -- 1 (a) control register reset
  -- 2 (a) UDP reset
  -- 3 (a) DAQ-path reset
  -- 4 (r) sys locked
  -- 5 (r) FEMB locked
  -- 6 (r) EB locked
  -- 8 (r/w) DUNE clk sel
  -- 9 (r) DUNE clk locked
  -- 12 (a) tx clock reset
  -- 13 (a) reset all FEMB counters
  -- 14 (a) reset FEMB pll
  -- 27..24 (r) DAQ Link count
  -- 31..28 (r) FEMB count

  

  ----------------------------
  -- WIB FW Version
  ----------------------------
  constant WIB_FW_VERSION : unsigned(15 downto 0) := x"0101";
  --   7..0 (r) rev   (1-99) Manually updated
  --  15..8 (r) day   (1-31) Manually updated
  -- 23..16 (r) month (1-12) Manually updated
  -- 31..24 (r) year  (20XX) Manually updated

  ----------------------------
  -- WIB Synthesis Date
  ----------------------------
  constant WIB_SYNTH_DATE : unsigned(15 downto 0) := x"0102";
  --   7..0 (r) day     (1-31)  automatically updated
  --  15..8 (r) month   (1-12)  automatically updated
  -- 23..16 (r) year    (00-99) automatically updated
  -- 31..24 (r) century (20)    automatically updated

  ----------------------------
  -- WIB Synthesis Time
  ----------------------------
  constant WIB_SYNTH_TIME : unsigned(15 downto 0) := x"0103";
  --   7..0 (r) second  (00-59)  automatically updated
  --  15..8 (r) minute  (00-59)  automatically updated
  -- 23..16 (r) hour    (00-23) automatically updated

  ----------------------------
  -- WIB ID
  ----------------------------
  constant WIB_ID : unsigned(15 downto 0) := x"0104";
  -- 3..0 (r) Slot number
  -- 7..4 (r) Crate number
  -- 8    (r/w) Use fake slot/crate
  -- 19..16 (r/w) Fake slot number
  -- 23..20 (r/w) Fake crate number
  -- 27..24 (r/w) Real slot number
  -- 31..28 (r/w) Real crate number

  ----------------------------
  -- WIB BP SFP MON
  ----------------------------
  constant WIB_BPFP_DIS_MON : unsigned(15 downto 0) := x"0105";
  -- 0  (r) SFP disble
  -- 9..4 (r) backplane disable
  
  ----------------------------
  -- SC Do not disturb
  ----------------------------
  constant WIB_SC_DND : unsigned(15 downto 0) := x"0109";
  -- 0 (r/w) DND mode

  
  ----------------------------
  -- UDP Control
  ----------------------------
  constant UDP_CTRL : unsigned(15 downto 0) := x"0110";
  -- 0 (r/w) enable readback

  ----------------------------
  -- UDP DQM timeout
  ----------------------------
  constant UDP_TIMEOUT : unsigned(15 downto 0) := x"0111";
  -- 31..0 (r/w) udp timeout

  ----------------------------
  -- UDP DQM dest IP
  ----------------------------
  constant UDP_DEST_IP : unsigned(15 downto 0) := x"0112";
  -- 31..0 (r) destination IP

  ----------------------------
  -- UDP DQM dest mac
  ----------------------------
  constant UDP_DEST_MAC_LO : unsigned(15 downto 0) := x"0113";
  -- 31..0 (r) destination MAC[31..0]

  ----------------------------
  -- UDP DQM dest mac
  ----------------------------
  constant UDP_DEST_MAC_HI : unsigned(15 downto 0) := x"0114";
  -- 15..0 (r) destination MAC[47..32]

  ----------------------------
  -- UDP DQM dest port
  ----------------------------
  constant UDP_DEST_PORT : unsigned(15 downto 0) := x"0115";
  -- 15..0 (r) destination port

  ----------------------------
  -- UDP DQM dest port
  ----------------------------
  constant UDP_FRAME_SIZE : unsigned(15 downto 0) := x"0116";
  -- 11..0 (r/w) udp frame size


  ----------------------------
  -- local Flash control
  ----------------------------
  constant LFLASH_CTRL : unsigned(15 downto 0) := x"0120";
  -- 0 (a) run
  -- 1 (r/w) r/w
  -- 2 (r) done
  -- 3 (r) error
  -- 4 (a) reset
  -- 31..16 (r/w) address
  
  ----------------------------
  -- local Flash write data
  ----------------------------
  constant LFLASH_WRITE : unsigned(15 downto 0) := x"0121";
  -- 31..0  (r/w) data
  
  ----------------------------
  -- local Flash read data
  ----------------------------
  constant LFLASH_READ : unsigned(15 downto 0) := x"0122";
  -- 31..0  (r) data



  ----------------------------
  -- local Flash write data
  ----------------------------
  constant TS_CTRL : unsigned(15 downto 0) := x"0130";
  -- 0  (a) start
  -- 1  (r) busy
  
  ----------------------------
  -- local Flash write data
  ----------------------------
  constant TS_DATA : unsigned(15 downto 0) := x"0131";
  -- 31..0 (r) temp data


  
  
  ----------------------------
  -- CONTROL Control
  ----------------------------
  constant DTS_CTRL : unsigned(15 downto 0) := x"0200";
  -- 1 (r/w) PDTS enable
  -- 2 (r/w) PDTS resetter enabled
  -- 3 (r/w) PDTS resetter counter reset
  -- 4 (r/w) PDTS data clk reset
  -- 5 (r)   PDTS data clock locked
  -- 8 (r/w) tx ouput enable
  -- 9 (r/w) tx output rx data
  -- 10 (r)  clk DUNE in reset
  -- 11 (r)  clk DUNE in locked
  -- 13..12  (r/w) PDTS timing group
  -- 19..16  (r) PDTS state

  
  ----------------------------
  -- CONTROL STATUS 1
  ----------------------------
  constant DTS_RESET_COUNT : unsigned(15 downto 0) := x"0201";
  -- 23..0 (r)   reset count

  ----------------------------
  -- CONTROL Convert count 2
  ----------------------------
  constant DTS_EVENT_COUNT : unsigned(15 downto 0) := x"0202";
  -- 31..0  (r)  event count

  ----------------------------
  -- CONTROL Time
  ----------------------------
  constant DTS_TIME_LSB : unsigned(15 downto 0) := x"0203";
  -- 31..0 (r)   time stamp 31..0

  ----------------------------
  -- CONTROL Time
  ----------------------------
  constant DTS_TIME_MSB : unsigned(15 downto 0) := x"0204";
  -- 31..0 (r)   time stamp 63..32

  ----------------------------
  -- DTS Convert control
  ----------------------------
  constant DTS_CONVERT_CONTROL : unsigned(15 downto 0) := x"0205";
  -- 0 (r/w) converts_enabled
  -- 1 (r)   out of sync
  -- 2 (r/w) local timestamp
  -- 3 (r/w) enable fake DTS
  -- 4 (r/w) halt
  -- 5 (a)   start_sync
  -- 11..8 (r) state

  ----------------------------
  -- DTS Convert sync period
  ----------------------------
  constant DTS_CONVERT_SYNC_PERIOD : unsigned(15 downto 0) := x"0206";
  -- 31..0 (r/w) convert period in 50Mhz clock ticks

  ----------------------------
  -- DTS last good sync LSB
  ----------------------------
  constant DTS_CONVERT_LAST_SYNC_LSB : unsigned(15 downto 0) := x"0207";
  -- 31..0 (r) last good convert time 31..0

  ----------------------------
  -- DTS last good sync MSB
  ----------------------------
  constant DTS_CONVERT_LAST_SYNC_MSB : unsigned(15 downto 0) := x"0208";
  -- 31..0 (r) last good convert time 63..32

  ----------------------------
  -- DTS missed periodic syncs
  ----------------------------
  constant DTS_CONVERT_MISSED_SYNCS : unsigned(15 downto 0) := x"0209";
  -- 31..0 (r/w) count of missed syncs

  ----------------------------
  -- DTS bad FEMB hack
  ----------------------------
  constant DTS_CONVERT_BAD_FEMB_HACK : unsigned(15 downto 0) := x"020A";
  -- 3..0 (r/w) enable bad FEMB hack
 
 
  ----------------------------
  -- PDTS resetter count
  ----------------------------
  constant PDTS_RESETTER_COUNT : unsigned(15 downto 0) := x"020B";
  -- 31..0 (r) count of resetter resets


  ----------------------------
  -- PDTS debugging
  ----------------------------
  constant PDTS_HISTORY_MONITOR : unsigned(15 downto 0) := x"020C";
  -- 0     (r/i) valid
  -- 1     (r/i) type (1 presample, 0 postsample)
  -- 31..4 (r/i) data  

  ----------------------------
  -- PDTS address
  ----------------------------
  constant PDTS_ADDR : unsigned(15 downto 0) := x"020D";
  -- 7..0   (r) address
  -- 16     (r/w) enable address override
  -- 31..24 (r/w) override address

  
  ----------------------------
  -- DTS CDS
  ----------------------------
  constant DTS_CDS_Control : unsigned(15 downto 0) := x"0210";
  -- 0 (r/w) input select (FP/BP)
  -- 2 (r) LOL
  -- 3 (r) LOS


   
  ----------------------------
  -- DTS CDS I2c Control
  ----------------------------
  constant DTS_CDS_I2C_Control : unsigned(15 downto 0) := x"0212";
  -- 0 (a) run
  -- 1 (r/w) r/w
  -- 2 (r) busy
  -- 3 (r) available
  -- 4 (a) reset
  -- 11..8 (r/w) byte_count
  -- 23..16 (r/w) address

  ----------------------------
  -- DTS CDS I2c write
  ----------------------------
  constant DTS_CDS_I2C_WR_DATA : unsigned(15 downto 0) := x"0213";
  -- 31..0 (r/w) write data

  ----------------------------
  -- DTS CDS I2c read
  ----------------------------
  constant DTS_CDS_I2C_RD_DATA : unsigned(15 downto 0) := x"0214";
  -- 31..0 (r) read data

  ----------------------------
  -- DTS SI5344
  ----------------------------
  constant DTS_SI5344_Control : unsigned(15 downto 0) := x"0220";
  -- 0 (r/w) enable
  -- 1 (r/w) reset
  -- 2 (r) LOL
  -- 3 (r) LOS
  -- 4 (r) interrupt
  -- 9..8 (r/w) input select
  
  ----------------------------
  -- DTS SI5344 I2c Control
  ----------------------------
  constant DTS_SI5344_I2C_Control : unsigned(15 downto 0) := x"0222";
  -- 0 (a) run
  -- 1 (r/w) r/w
  -- 2 (r) busy
  -- 3 (r) available
  -- 4 (a) reset
  -- 11..8 (r/w) byte_count
  -- 23..16 (r/w) address

  ----------------------------
  -- DTS SI5344 I2c write
  ----------------------------
  constant DTS_SI5344_I2C_WR_DATA : unsigned(15 downto 0) := x"0223";
  -- 31..0 (r/w) write data

  ----------------------------
  -- DTS SI5344 I2c read
  ----------------------------
  constant DTS_SI5344_I2C_RD_DATA : unsigned(15 downto 0) := x"0224";
  -- 31..0 (r) read data


  ----------------------------
  -- DTS SI5344 reset requested count
  ----------------------------
  constant DTS_SI5344_RST_REQ : unsigned(15 downto 0) := x"0225";
  -- 31..0 (r/a) reset requests

    ----------------------------
  -- DTS SI5344 reset performed count
  ----------------------------
  constant DTS_SI5344_RST_PERF : unsigned(15 downto 0) := x"0226";
  -- 31..0 (r/a) resets performed

  
  ----------------------------
  -- DTS PDTS Monitor
  ----------------------------
  -- 0 (r) reset
  -- 1 (r) ready
  -- 4 (r) cdr
  
  ----------------------------
  -- DTS command count
  ----------------------------
  constant DTS_SYNC_CMD_CONTROL : unsigned(15 downto 0) := x"0235";
  -- 15..0 (r/w) counter reset

  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_0 : unsigned(15 downto 0) := x"0240";
  -- 31..0 (r/w) count

  ----------------------------
  -- DTS command 1 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_1 : unsigned(15 downto 0) := x"0241";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_2 : unsigned(15 downto 0) := x"0242";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_3 : unsigned(15 downto 0) := x"0243";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_4 : unsigned(15 downto 0) := x"0244";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_5 : unsigned(15 downto 0) := x"0245";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_6 : unsigned(15 downto 0) := x"0246";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_7 : unsigned(15 downto 0) := x"0247";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_8 : unsigned(15 downto 0) := x"0248";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_9 : unsigned(15 downto 0) := x"0249";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_10 : unsigned(15 downto 0) := x"024A";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_11 : unsigned(15 downto 0) := x"024B";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_12 : unsigned(15 downto 0) := x"024C";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_13 : unsigned(15 downto 0) := x"024D";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_14 : unsigned(15 downto 0) := x"024E";
  -- 31..0 (r/w) count
  ----------------------------
  -- DTS command 0 count
  ----------------------------
  constant DTS_SYNC_CMD_COUNT_15 : unsigned(15 downto 0) := x"024F";
  -- 31..0 (r/w) count

  
  
  
  

  ----------------------------
  -- DQM
  ----------------------------
  constant DQM_CTRL : unsigned(15 downto 0) := x"0800";
  -- 0 (r/w) enable DQM packets
  -- 7..4 (r/w) DQM type (Modes: 0x0:Jack, 0x1:testing)

  ----------------------------
  -- DQM COLDATA single stream
  ----------------------------
  constant DQM_CD_SS : unsigned(15 downto 0) := x"0801";
  -- 0 (r/w) stream_number
  -- 1 (r/w) CD_number
  -- 3..2 (r/w) FEMB_number
  -- 4 (r/w) sub_stream number (for jack mode)


  ----------------------------
  -- FEMB Power Enables
  ----------------------------
  constant FEMB_POWER_CONTROL : unsigned(15 downto 0) := x"0400";
  -- 0 (r/w) FEMB 1 EN 3.6 V
  -- 1 (r/w) FEMB 1 EN 2.8 V
  -- 2 (r/w) FEMB 1 EN 2.5 V
  -- 3 (r/w) FEMB 1 EN 1.5 V
  -- 4 (r/w) FEMB 1 EN Bias V
  -- 12..8  (r/w) FEMB 2 Power Enables
  -- 20..16 (r/w) FEMB 3 Power Enables
  -- 28..24 (r/w) FEMB 4 Power Enables
  -- 31     (r/w) Master bias enable

  ----------------------------
  -- FEMB Power Monitor Control
  ----------------------------
  constant FEMB_POWER_MON_CONTROL : unsigned(15 downto 0) := x"0401";
  -- 0 (r/w) reset

  ----------------------------
  -- FEMB BIAS mon
  ----------------------------
  constant FEMB_BIAS_MON : unsigned(15 downto 0) := x"0402";
  -- 15..0  (r) Bias Vcc
  -- 31..16 (r) bias temp

  ----------------------------
  -- FEMB FE mon
  ----------------------------
  constant FEMB_FE_MON : unsigned(15 downto 0) := x"0403";
  -- 15..0  (r) FE Vcc
  -- 31..16 (r) FE temp
  
  ----------------------------
  -- FEMB1 mon 0
  ----------------------------
  constant FEMB_1_MON_0 : unsigned(15 downto 0) := x"0410";
  -- 15..0  (r) Bias Vcc
  -- 31..16 (r) bias temp
  
  ----------------------------
  -- FEMB1 mon 1
  ----------------------------
  constant FEMB_1_MON_1 : unsigned(15 downto 0) := x"0411";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current

  ----------------------------
  -- FEMB1 mon 2
  ----------------------------
  constant FEMB_1_MON_2 : unsigned(15 downto 0) := x"0412";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB1 mon 3
  ----------------------------
  constant FEMB_1_MON_3 : unsigned(15 downto 0) := x"0413";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB1 mon 4
  ----------------------------
  constant FEMB_1_MON_4 : unsigned(15 downto 0) := x"0414";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB1 mon 5
  ----------------------------
  constant FEMB_1_MON_5 : unsigned(15 downto 0) := x"0415";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB1 mon 6
  ----------------------------
  constant FEMB_1_MON_6 : unsigned(15 downto 0) := x"0416";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current

  ----------------------------
  -- FEMB2 mon 0
  ----------------------------
  constant FEMB_2_MON_0 : unsigned(15 downto 0) := x"0420";
  -- 15..0  (r) Bias Vcc
  -- 31..16 (r) bias temp
  ----------------------------
  -- FEMB2 mon 1
  ----------------------------
  constant FEMB_2_MON_1 : unsigned(15 downto 0) := x"0421";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB2 mon 2
  ----------------------------
  constant FEMB_2_MON_2 : unsigned(15 downto 0) := x"0422";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB2 mon 3
  ----------------------------
  constant FEMB_2_MON_3 : unsigned(15 downto 0) := x"0423";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB2 mon 4
  ----------------------------
  constant FEMB_2_MON_4 : unsigned(15 downto 0) := x"0424";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB2 mon 5
  ----------------------------
  constant FEMB_2_MON_5 : unsigned(15 downto 0) := x"0425";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB2 mon 6
  ----------------------------
  constant FEMB_2_MON_6 : unsigned(15 downto 0) := x"0426";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current


  ----------------------------
  -- FEMB3 mon 0
  ----------------------------
  constant FEMB_3_MON_0 : unsigned(15 downto 0) := x"0430";
  -- 15..0  (r) Bias Vcc
  -- 31..16 (r) bias temp
  ----------------------------
  -- FEMB3 mon 1
  ----------------------------
  constant FEMB_3_MON_1 : unsigned(15 downto 0) := x"0431";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB3 mon 2
  ----------------------------
  constant FEMB_3_MON_2 : unsigned(15 downto 0) := x"0432";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB3 mon 3
  ----------------------------
  constant FEMB_3_MON_3 : unsigned(15 downto 0) := x"0433";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB3 mon 4
  ----------------------------
  constant FEMB_3_MON_4 : unsigned(15 downto 0) := x"0434";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB3 mon 5
  ----------------------------
  constant FEMB_3_MON_5 : unsigned(15 downto 0) := x"0435";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB3 mon 6
  ----------------------------
  constant FEMB_3_MON_6 : unsigned(15 downto 0) := x"0436";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current

  ----------------------------
  -- FEMB4 mon 0
  ----------------------------
  constant FEMB_4_MON_0 : unsigned(15 downto 0) := x"0440";
  -- 15..0  (r) Bias Vcc
  -- 31..16 (r) bias temp
  ----------------------------
  -- FEMB4 mon 1
  ----------------------------
  constant FEMB_4_MON_1 : unsigned(15 downto 0) := x"0441";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB4 mon 2
  ----------------------------
  constant FEMB_4_MON_2 : unsigned(15 downto 0) := x"0442";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB4 mon 3
  ----------------------------
  constant FEMB_4_MON_3 : unsigned(15 downto 0) := x"0443";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB4 mon 4
  ----------------------------
  constant FEMB_4_MON_4 : unsigned(15 downto 0) := x"0444";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB4 mon 5
  ----------------------------
  constant FEMB_4_MON_5 : unsigned(15 downto 0) := x"0445";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- FEMB4 mon 6
  ----------------------------
  constant FEMB_4_MON_6 : unsigned(15 downto 0) := x"0446";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current


  ----------------------------
  -- WIB mon 0
  ----------------------------
  constant WIB_MON_0 : unsigned(15 downto 0) := x"0450";
  -- 15..0  (r) Bias Vcc
  -- 31..16 (r) bias temp
  ----------------------------
  -- WIB mon 1
  ----------------------------
  constant WIB_MON_1 : unsigned(15 downto 0) := x"0451";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- WIB mon 2
  ----------------------------
  constant WIB_MON_2 : unsigned(15 downto 0) := x"0452";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- WIB mon 3
  ----------------------------
  constant WIB_MON_3 : unsigned(15 downto 0) := x"0453";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current
  ----------------------------
  -- WIB mon 4
  ----------------------------
  constant WIB_MON_4 : unsigned(15 downto 0) := x"0454";
  -- 15..0  (r) Voltage
  -- 31..16 (r) Current



  
  
  ----------------------------
  -- FEMB CnC control
  ----------------------------
  constant FEMB_CNC : unsigned(15 downto 0) := x"0500";
  -- 0 (r/w) CnC Clock Select (0 DTS,1 local)
  -- 1 (r/w) CnC Command Select
  -- 2 (r/w) Enable converts
  -- 3 (r)   convert going down to FEMB
  -- 4 (a)   DTS 100Mhz reset
  -- 5 (r)   DTS 100Mhz locked
  -- 8 (a)   stop femb data
  -- 9 (a)   start femb data
  -- 10 (a)  reset femb timestamp
  -- 11 (a)  send femb calibration pulse
  -- 12 (r/w) enable commands from DTS to FEMBs
  -- 13 (r/w) enable test pulse from DTS

  ----------------------------
  -- FEMB spy control
  ----------------------------
  constant FEMB_SPY_CONTROL : unsigned(15 downto 0) := x"0900";
  -- 3..0   (r/w) stream id  
  -- 4      (r/w) ext_en
  -- 5      (r/w) word_en
  -- 8      (r)   fifo empty
  -- 20..12 (r/w) word trig value
  -- 31..30 (r)   spy state
  
  ----------------------------
  -- FEMB spy arm
  ----------------------------
  constant FEMB_SPY_ARM : unsigned(15 downto 0) := x"0901";
  -- 0      (a)  arm spy buffer
  -- 1      (a)  software trigger

  ----------------------------
  -- FEMB spy readout
  ----------------------------
  constant FEMB_SPY_readout : unsigned(15 downto 0) := x"0902";
  -- 8..0  (r/a) spy data

  ----------------------------
  -- FEMB duplicate
  ----------------------------
  constant FEMB_DUPLICATE : unsigned(15 downto 0) := x"0FFF";
  -- 0     (r/w) override FEMB 3&4 and replace with 1&2
  
  ----------------------------
  -- FEMB Control
  ----------------------------
  constant FEMB_1_CONTROL : unsigned(15 downto 0) := x"1000";
  constant FEMB_2_CONTROL : unsigned(15 downto 0) := x"2000";
  constant FEMB_3_CONTROL : unsigned(15 downto 0) := x"3000";
  constant FEMB_4_CONTROL : unsigned(15 downto 0) := x"4000";
  -- 0    (r/w) reset
  -- 1    (r/w) reconfigure reset
  -- 7..4 (r/w) enable processing link 4..1
  
  ----------------------------
  -- FEMB Triggering
  ----------------------------
  constant FEMB_1_TRIGGER : unsigned(15 downto 0) := x"1001";
  constant FEMB_2_TRIGGER : unsigned(15 downto 0) := x"2001";
  constant FEMB_3_TRIGGER : unsigned(15 downto 0) := x"3001";
  constant FEMB_4_TRIGGER : unsigned(15 downto 0) := x"4001";
  --  7..0  (r/w) convert delay CD1.1 
  -- 15..8  (r/w) convert delay CD1.2
  -- 23..16 (r/w) convert delay CD2.1
  -- 31..24 (r/w) convert delay CD2.2

  ----------------------------
  -- FEMB FAKE COLDATA
  ----------------------------
  constant FEMB_1_FAKE_CD : unsigned(15 downto 0) := x"1010";
  constant FEMB_2_FAKE_CD : unsigned(15 downto 0) := x"2010";
  constant FEMB_3_FAKE_CD : unsigned(15 downto 0) := x"3010";
  constant FEMB_4_FAKE_CD : unsigned(15 downto 0) := x"4010";
  --     0 (r/w) fake COLDATA ASIC 1 sample data type 0/1 (samples/bytes)
  --     1 (r/w) fake COLDATA ASIC 2 sample data type 0/1 (samples/bytes)
  --     2 (r/w) fake COLDATA ASIC 1 data type 1 => (CD packet is SOF+counter)
  --     3 (r/w) fake COLDATA ASIC 2 data type 1 => (CD packet is SOF+counter)  
  --  7..4 (r/w) RX data source (0 transceiver, 1 local fake data)
  -- 11..8 (r/w) TX data stream (0 idle, 1 fake COLDATA)

  ----------------------------
  -- FEMB FAKE COLDATA 1.1 packets
  ----------------------------
  constant FEMB_1_FAKE_CD_1_1_PACKETS : unsigned(15 downto 0) := x"1011";
  constant FEMB_2_FAKE_CD_1_1_PACKETS : unsigned(15 downto 0) := x"2011";
  constant FEMB_3_FAKE_CD_1_1_PACKETS : unsigned(15 downto 0) := x"3011";
  constant FEMB_4_FAKE_CD_1_1_PACKETS : unsigned(15 downto 0) := x"4011";
  -- 31..0 (r) fake COLDATA ASIC 1 stream 1 packets

  ----------------------------
  -- FEMB FAKE COLDATA 1.2 packets
  ----------------------------
  constant FEMB_1_FAKE_CD_1_2_PACKETS : unsigned(15 downto 0) := x"1012";
  constant FEMB_2_FAKE_CD_1_2_PACKETS : unsigned(15 downto 0) := x"2012";
  constant FEMB_3_FAKE_CD_1_2_PACKETS : unsigned(15 downto 0) := x"3012";
  constant FEMB_4_FAKE_CD_1_2_PACKETS : unsigned(15 downto 0) := x"4012";
  -- 31..0 (r) fake COLDATA ASIC 1 stream 2 packets

  ----------------------------
  -- FEMB FAKE COLDATA 2.1 packets
  ----------------------------
  constant FEMB_1_FAKE_CD_2_1_PACKETS : unsigned(15 downto 0) := x"1013";
  constant FEMB_2_FAKE_CD_2_1_PACKETS : unsigned(15 downto 0) := x"2013";
  constant FEMB_3_FAKE_CD_2_1_PACKETS : unsigned(15 downto 0) := x"3013";
  constant FEMB_4_FAKE_CD_2_1_PACKETS : unsigned(15 downto 0) := x"4013";
  -- 31..0 (r) fake COLDATA ASIC 1 stream 1 packets

  ----------------------------
  -- FEMB FAKE COLDATA 2.2 packets
  ----------------------------
  constant FEMB_1_FAKE_CD_2_2_PACKETS : unsigned(15 downto 0) := x"1014";
  constant FEMB_2_FAKE_CD_2_2_PACKETS : unsigned(15 downto 0) := x"2014";
  constant FEMB_3_FAKE_CD_2_2_PACKETS : unsigned(15 downto 0) := x"3014";
  constant FEMB_4_FAKE_CD_2_2_PACKETS : unsigned(15 downto 0) := x"4014";
  -- 31..0 (r) fake COLDATA ASIC 1 stream 2 packets

  ----------------------------
  -- FEMB CD 1/2 FAKE Reserved word
  ----------------------------
  constant FEMB_1_FAKE_CD_RESERVED_WORD : unsigned(15 downto 0) := x"1015";
  constant FEMB_2_FAKE_CD_RESERVED_WORD : unsigned(15 downto 0) := x"2015";
  constant FEMB_3_FAKE_CD_RESERVED_WORD : unsigned(15 downto 0) := x"3015";
  constant FEMB_4_FAKE_CD_RESERVED_WORD : unsigned(15 downto 0) := x"4015";
  -- 15..0  (r/w) reserved word CD 1
  -- 31..16 (r/w) reserved word CD 2

  ----------------------------
  -- FEMB CD 1 FAKE Header word
  ----------------------------
  constant FEMB_1_FAKE_CD_1_HEADER_WORD : unsigned(15 downto 0) := x"1016";
  constant FEMB_2_FAKE_CD_1_HEADER_WORD : unsigned(15 downto 0) := x"2016";
  constant FEMB_3_FAKE_CD_1_HEADER_WORD : unsigned(15 downto 0) := x"3016";
  constant FEMB_4_FAKE_CD_1_HEADER_WORD : unsigned(15 downto 0) := x"4016";
  -- 31..0 (r/w) header words CD1

  ----------------------------
  -- FEMB CD 2 FAKE Header word
  ----------------------------
  constant FEMB_1_FAKE_CD_2_HEADER_WORD : unsigned(15 downto 0) := x"1017";
  constant FEMB_2_FAKE_CD_2_HEADER_WORD : unsigned(15 downto 0) := x"2017";
  constant FEMB_3_FAKE_CD_2_HEADER_WORD : unsigned(15 downto 0) := x"3017";
  constant FEMB_4_FAKE_CD_2_HEADER_WORD : unsigned(15 downto 0) := x"4017";
  -- 31..0 (r/w) header words CD2

  
  ----------------------------
  -- FEMB CD 1/2 Error injection
  ----------------------------
  constant FEMB_1_FAKE_CD_ERR_INJ : unsigned(15 downto 0) := x"1020";
  constant FEMB_2_FAKE_CD_ERR_INJ : unsigned(15 downto 0) := x"2020";
  constant FEMB_3_FAKE_CD_ERR_INJ : unsigned(15 downto 0) := x"3020";
  constant FEMB_4_FAKE_CD_ERR_INJ : unsigned(15 downto 0) := x"4020";
  -- 0 (a) inject set errors on next event

  ----------------------------
  -- FEMB CD 1.1 Error injection
  ----------------------------
  constant FEMB_1_FAKE_CD_1_ERR_INJ : unsigned(15 downto 0) := x"1021";
  constant FEMB_2_FAKE_CD_1_ERR_INJ : unsigned(15 downto 0) := x"2021";
  constant FEMB_3_FAKE_CD_1_ERR_INJ : unsigned(15 downto 0) := x"3021";
  constant FEMB_4_FAKE_CD_1_ERR_INJ : unsigned(15 downto 0) := x"4021";
  -- 0 (r/w) stream 1 bad checksum
  -- 1 (r/w) stream 1 bad SOF char
  -- 2 (r/w) stream 1 large frame
  -- 3 (r/w) stream 1 small frame
  -- 4 (r/w) stream 1 k-char in data
  -- 15..8 (r/w) stream 1 CD error word
  -- 16 (r/w) stream 2 bad checksum
  -- 17 (r/w) stream 2 bad SOF char
  -- 18 (r/w) stream 2 large frame
  -- 19 (r/w) stream 2 small frame
  -- 20 (r/w) stream 2 k-char in data
  -- 31..24 (r/w) stream 2 CD error word

    
  ----------------------------
  -- FEMB CD 1.2 Error injection
  ----------------------------
  constant FEMB_1_FAKE_CD_2_ERR_INJ : unsigned(15 downto 0) := x"1022";
  constant FEMB_2_FAKE_CD_2_ERR_INJ : unsigned(15 downto 0) := x"2022";
  constant FEMB_3_FAKE_CD_2_ERR_INJ : unsigned(15 downto 0) := x"3022";
  constant FEMB_4_FAKE_CD_2_ERR_INJ : unsigned(15 downto 0) := x"4022";
  -- 0 (r/w) stream 3 bad checksu3
  -- 1 (r/w) stream 3 bad SOF cha4
  -- 2 (r/w) stream 3 large frame
  -- 3 (r/w) stream 3 small frame
  -- 4 (r/w) stream 3 k-char in data
  -- 15..8 (r/w) stream 3 CD error word
  -- 16 (r/w) stream 4 bad checksum
  -- 17 (r/w) stream 4 bad SOF char
  -- 18 (r/w) stream 4 large frame
  -- 19 (r/w) stream 4 small frame
  -- 20 (r/w) stream 4 k-char in data
  -- 31..24 (r/w) stream 4 CD error word


  
  ----------------------------
  -- FEMB Stream 1 RX STATUS
  ----------------------------  
  constant FEMB_1_STR_1_STATUS : unsigned(15 downto 0) := x"1100";
  constant FEMB_2_STR_1_STATUS : unsigned(15 downto 0) := x"2100";
  constant FEMB_3_STR_1_STATUS : unsigned(15 downto 0) := x"3100";
  constant FEMB_4_STR_1_STATUS : unsigned(15 downto 0) := x"4100";
  --  0 (r) LOS
  --  1 (r) rx calibration busy  
  --  4 (r/w) rx analog reset
  --  5 (r/w) rx digital reset
  --  6 (r) rx is locked to reference
  --  7 (r) rx is locked to data
  -- 15..10 (r) rdusedw
  -- 16 (r) rx error detected
  -- 17 (r) rx disparity error
  -- 18 (r) rx runnign disparity
  -- 20 (r) rx pattern detect
  -- 21 (r) rx sync status
  -- 22 (r/w) reset rx error counter
  -- 23 (r/w) reset rx disp error counter
  -- 31..28 (a) reset link side logic
  
  ----------------------------
  -- FEMB Stream 1 RX packets
  ----------------------------  
  constant FEMB_1_STR_1_PACKET_COUNT : unsigned(15 downto 0) := x"1101";
  constant FEMB_2_STR_1_PACKET_COUNT : unsigned(15 downto 0) := x"2101";
  constant FEMB_3_STR_1_PACKET_COUNT : unsigned(15 downto 0) := x"3101";
  constant FEMB_4_STR_1_PACKET_COUNT : unsigned(15 downto 0) := x"4101";
  -- 31..0 (r) packet count

  ----------------------------
  -- FEMB Stream 1 RX packet rate
  ----------------------------  
  constant FEMB_1_STR_1_PACKET_RATE : unsigned(15 downto 0) := x"1102";
  constant FEMB_2_STR_1_PACKET_RATE : unsigned(15 downto 0) := x"2102";
  constant FEMB_3_STR_1_PACKET_RATE : unsigned(15 downto 0) := x"3102";
  constant FEMB_4_STR_1_PACKET_RATE : unsigned(15 downto 0) := x"4102";
  -- 31..0 (r) packet rate

  ----------------------------
  -- FEMB Stream 1 RX RAW packet rate
  ----------------------------  
  constant FEMB_1_STR_1_RAW_PACKET_RATE : unsigned(15 downto 0) := x"1103";
  constant FEMB_2_STR_1_RAW_PACKET_RATE : unsigned(15 downto 0) := x"2103";
  constant FEMB_3_STR_1_RAW_PACKET_RATE : unsigned(15 downto 0) := x"3103";
  constant FEMB_4_STR_1_RAW_PACKET_RATE : unsigned(15 downto 0) := x"4103";
  -- 31..0 (r) packet rate


  ----------------------------
  -- FEMB Stream 1 counter resets
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_RESETS : unsigned(15 downto 0) := x"1150";
  constant FEMB_2_STR_1_ERR_CNT_RESETS : unsigned(15 downto 0) := x"2150";
  constant FEMB_3_STR_1_ERR_CNT_RESETS : unsigned(15 downto 0) := x"3150";
  constant FEMB_4_STR_1_ERR_CNT_RESETS : unsigned(15 downto 0) := x"4150";  
  --  0 (a) reset all counters for this stream
  --  1 (a) reset convert in wait count
  --  2 (a) reset bad sof count
  --  3 (a) reset unexpetect eof count
  --  4 (a) reset missing eof count
  --  5 (a) reset kchar in data count
  --  6 (a) reset bad checksum count
  --  7 (a) reset buffer full count
  --  8 (a) reset timestamp incr count
  --  9 (a) reset bad write count
  -- 10 (a) reset bad ro start count

  ----------------------------
  -- FEMB Stream 1 Convert in window
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"1151";
  constant FEMB_2_STR_1_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"2151";
  constant FEMB_3_STR_1_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"3151";
  constant FEMB_4_STR_1_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"4151";
  -- 31..0 (r/a) Count of converts between a convert and waiting for data(action reset)

  ----------------------------
  -- FEMB Stream 1 Bad start of frame
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"1152";
  constant FEMB_2_STR_1_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"2152";
  constant FEMB_3_STR_1_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"3152";
  constant FEMB_4_STR_1_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"4152";
  -- 31..0 (r/a) Count of bad start of frame characters (action reset)

  ----------------------------
  -- FEMB Stream 1 Early idle
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"1153";
  constant FEMB_2_STR_1_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"2153";
  constant FEMB_3_STR_1_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"3153";
  constant FEMB_4_STR_1_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"4153";
  -- 31..0 (r/a) Count of early idle characters (action reset)

  ----------------------------
  -- FEMB Stream 1 No idle
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"1154";
  constant FEMB_2_STR_1_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"2154";
  constant FEMB_3_STR_1_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"3154";
  constant FEMB_4_STR_1_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"4154";
  -- 31..0 (r/a) Count missing end of frame idle (action reset)

  ----------------------------
  -- FEMB Stream 1 K-char in data
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"1155";
  constant FEMB_2_STR_1_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"2155";
  constant FEMB_3_STR_1_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"3155";
  constant FEMB_4_STR_1_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"4155";
  -- 31..0 (r/a) Count k-chars in data (action reset)

  ----------------------------
  -- FEMB Stream 1 Bad Checksum
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"1156";
  constant FEMB_2_STR_1_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"2156";
  constant FEMB_3_STR_1_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"3156";
  constant FEMB_4_STR_1_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"4156";
  -- 31..0 (r/a) Count of bad checksums (action reset)

  ----------------------------
  -- FEMB Stream 1 Buffer full
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"1157";
  constant FEMB_2_STR_1_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"2157";
  constant FEMB_3_STR_1_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"3157";
  constant FEMB_4_STR_1_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"4157";
  -- 31..0 (r/a) Count of events lost due to the buffer being full (action reset)

  ----------------------------
  -- FEMB Stream 1 rx errors
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"1158";
  constant FEMB_2_STR_1_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"2158";
  constant FEMB_3_STR_1_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"3158";
  constant FEMB_4_STR_1_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"4158";
  -- 31..0 (r/a) Count of symbol errors on the rx

  ----------------------------
  -- FEMB Stream 1 rx disp errors
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"1159";
  constant FEMB_2_STR_1_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"2159";
  constant FEMB_3_STR_1_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"3159";
  constant FEMB_4_STR_1_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"4159";
  -- 31..0 (r/a) Count of disp errors on the rx

  ----------------------------
  -- FEMB Stream 1 timestamp incr error
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"115A";
  constant FEMB_2_STR_1_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"215A";
  constant FEMB_3_STR_1_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"315A";
  constant FEMB_4_STR_1_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"415A";
  -- 31..0 (r/a) Count of timestamp increment errors

  ----------------------------
  -- FEMB Stream 1 bad write count error
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"115B";
  constant FEMB_2_STR_1_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"215B";
  constant FEMB_3_STR_1_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"315B";
  constant FEMB_4_STR_1_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"415B";
  -- 31..0 (r/a) Count of bad write counts into CD to EB fifo

  ----------------------------
  -- FEMB Stream 1 bad ro start
  ----------------------------  
  constant FEMB_1_STR_1_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"115c";
  constant FEMB_2_STR_1_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"215c";
  constant FEMB_3_STR_1_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"315c";
  constant FEMB_4_STR_1_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"415c";
  -- 31..0 (r/a) Count of CD to EB fifo readouts that don't start with a SOF character

  ----------------------------
  -- FEMB Stream 1 timestamp incr error
  ----------------------------  
  constant FEMB_1_STR_1_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"115D";
  constant FEMB_2_STR_1_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"215D";
  constant FEMB_3_STR_1_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"315D";
  constant FEMB_4_STR_1_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"415D";
  -- 31..0 (r/a) rate of timestamp increment errors
  

  ----------------------------
  -- FEMB RX STATUS 2
  ----------------------------  
  constant FEMB_1_STR_2_STATUS : unsigned(15 downto 0) := x"1200";
  constant FEMB_2_STR_2_STATUS : unsigned(15 downto 0) := x"2200";
  constant FEMB_3_STR_2_STATUS : unsigned(15 downto 0) := x"3200";
  constant FEMB_4_STR_2_STATUS : unsigned(15 downto 0) := x"4200";
  --  0 (r) rx ready
  --  1 (r) tx ready (fake)
  --  2 (r) pll locked
  --  4 (r) rx is locked to reference
  --  5 (r) rx is locked to data
  --  8 (r) pll powerdown ???
  --  9 (r) reconfigure busy
  -- 10 (r) rx calibration busy
  -- 11 (r) tx calibration busy
  -- 12 (r) rx analog reset
  -- 13 (r) rx digital reset
  -- 14 (r) tx analog reset
  -- 15 (r) tx digital reset
  -- 16 (r) rx error detected
  -- 17 (r) rx disparity error
  -- 18 (r) rx runnign disparity
  -- 20 (r) rx pattern detect
  -- 21 (r) rx sync status
  -- 22 (r/w) reset rx error counter
  -- 23 (r/w) reset rx disp error counter
  -- 31..28 (a) reset link side logic

  ----------------------------
  -- FEMB RX packets 2
  ----------------------------  
  constant FEMB_1_STR_2_PACKET_COUNT : unsigned(15 downto 0) := x"1201";
  constant FEMB_2_STR_2_PACKET_COUNT : unsigned(15 downto 0) := x"2201";
  constant FEMB_3_STR_2_PACKET_COUNT : unsigned(15 downto 0) := x"3201";
  constant FEMB_4_STR_2_PACKET_COUNT : unsigned(15 downto 0) := x"4201";
  -- 31..0 (r) packet count

  ----------------------------
  -- FEMB Stream 2 RX packet rate
  ----------------------------  
  constant FEMB_1_STR_2_PACKET_RATE : unsigned(15 downto 0) := x"1202";
  constant FEMB_2_STR_2_PACKET_RATE : unsigned(15 downto 0) := x"2202";
  constant FEMB_3_STR_2_PACKET_RATE : unsigned(15 downto 0) := x"3202";
  constant FEMB_4_STR_2_PACKET_RATE : unsigned(15 downto 0) := x"4202";
  -- 31..0 (r) packet rate

  ----------------------------
  -- FEMB Stream 2 RX RAW packet rate
  ----------------------------  
  constant FEMB_1_STR_2_RAW_PACKET_RATE : unsigned(15 downto 0) := x"1203";
  constant FEMB_2_STR_2_RAW_PACKET_RATE : unsigned(15 downto 0) := x"2203";
  constant FEMB_3_STR_2_RAW_PACKET_RATE : unsigned(15 downto 0) := x"3203";
  constant FEMB_4_STR_2_RAW_PACKET_RATE : unsigned(15 downto 0) := x"4203";
  -- 31..0 (r) packet rate


  ----------------------------
  -- FEMB Stream 2 counter resets
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_RESETS : unsigned(15 downto 0) := x"1250";
  constant FEMB_2_STR_2_ERR_CNT_RESETS : unsigned(15 downto 0) := x"2250";
  constant FEMB_3_STR_2_ERR_CNT_RESETS : unsigned(15 downto 0) := x"3250";
  constant FEMB_4_STR_2_ERR_CNT_RESETS : unsigned(15 downto 0) := x"4250";  
  -- 0 (a) reset all counters for this stream
  -- 1 (a) reset convert in wait count
  -- 2 (a) reset bad sof count
  -- 3 (a) reset unexpetect eof count
  -- 4 (a) reset missing eof count
  -- 5 (a) reset kchar in data count
  -- 6 (a) reset bad checksum count
  -- 7 (a) reset buffer full count
  -- 8 (a) reset timestamp incr count
  --  9 (a) reset bad write count
  -- 10 (a) reset bad ro start count

  
  ----------------------------
  -- FEMB Stream 2 Convert in window
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"1251";
  constant FEMB_2_STR_2_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"2251";
  constant FEMB_3_STR_2_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"3251";
  constant FEMB_4_STR_2_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"4251";
  -- 31..0 (r/a) Count of converts between a convert and waiting for data(action reset)

  ----------------------------
  -- FEMB Stream 2 Bad start of frame
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"1252";
  constant FEMB_2_STR_2_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"2252";
  constant FEMB_3_STR_2_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"3252";
  constant FEMB_4_STR_2_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"4252";
  -- 31..0 (r/a) Count of bad start of frame characters (action reset)

  ----------------------------
  -- FEMB Stream 2 Early idle
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"1253";
  constant FEMB_2_STR_2_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"2253";
  constant FEMB_3_STR_2_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"3253";
  constant FEMB_4_STR_2_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"4253";
  -- 31..0 (r/a) Count of early idle characters (action reset)

  ----------------------------
  -- FEMB Stream 2 No idle
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"1254";
  constant FEMB_2_STR_2_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"2254";
  constant FEMB_3_STR_2_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"3254";
  constant FEMB_4_STR_2_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"4254";
  -- 31..0 (r/a) Count missing end of frame idle (action reset)

  ----------------------------
  -- FEMB Stream 2 K-char in data
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"1255";
  constant FEMB_2_STR_2_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"2255";
  constant FEMB_3_STR_2_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"3255";
  constant FEMB_4_STR_2_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"4255";
  -- 31..0 (r/a) Count k-chars in data (action reset)

  ----------------------------
  -- FEMB Stream 2 Bad Checksum
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"1256";
  constant FEMB_2_STR_2_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"2256";
  constant FEMB_3_STR_2_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"3256";
  constant FEMB_4_STR_2_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"4256";
  -- 31..0 (r/a) Count of bad checksums (action reset4

  ----------------------------
  -- FEMB Stream 2 Buffer full
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"1257";
  constant FEMB_2_STR_2_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"2257";
  constant FEMB_3_STR_2_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"3257";
  constant FEMB_4_STR_2_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"4257";
  -- 31..0 (r/a) Count of events lost due to the buffer being full (action reset)

  ----------------------------
  -- FEMB Stream 2 rx errors
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"1258";
  constant FEMB_2_STR_2_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"2258";
  constant FEMB_3_STR_2_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"3258";
  constant FEMB_4_STR_2_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"4258";
  -- 31..0 (r/a) Count of symbol errors on the rx

  ----------------------------
  -- FEMB Stream 2 rx disp errors
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"1259";
  constant FEMB_2_STR_2_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"2259";
  constant FEMB_3_STR_2_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"3259";
  constant FEMB_4_STR_2_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"4259";
  -- 31..0 (r/a) Count of disp errors on the rx

  ----------------------------
  -- FEMB Stream 2 timestamp incr error
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"125A";
  constant FEMB_2_STR_2_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"225A";
  constant FEMB_3_STR_2_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"325A";
  constant FEMB_4_STR_2_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"425A";
  -- 31..0 (r/a) Count of timestamp increment errors

  ----------------------------
  -- FEMB Stream 2 bad write count error
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"125B";
  constant FEMB_2_STR_2_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"225B";
  constant FEMB_3_STR_2_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"325B";
  constant FEMB_4_STR_2_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"425B";
  -- 31..0 (r/a) Count of bad write counts into CD to EB fifo

  ----------------------------
  -- FEMB Stream 2 bad ro start
  ----------------------------  
  constant FEMB_1_STR_2_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"125c";
  constant FEMB_2_STR_2_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"225c";
  constant FEMB_3_STR_2_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"325c";
  constant FEMB_4_STR_2_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"425c";
  -- 31..0 (r/a) Count of CD to EB fifo readouts that don't start with a SOF character

  ----------------------------
  -- FEMB Stream 1 timestamp incr error
  ----------------------------  
  constant FEMB_1_STR_2_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"125D";
  constant FEMB_2_STR_2_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"225D";
  constant FEMB_3_STR_2_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"325D";
  constant FEMB_4_STR_2_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"425D";
  -- 31..0 (r/a) rate of timestamp increment errors
  

  ----------------------------
  -- FEMB RX STATUS 3
  ----------------------------  
  constant FEMB_1_STR_3_STATUS : unsigned(15 downto 0) := x"1300";
  constant FEMB_2_STR_3_STATUS : unsigned(15 downto 0) := x"2300";
  constant FEMB_3_STR_3_STATUS : unsigned(15 downto 0) := x"3300";
  constant FEMB_4_STR_3_STATUS : unsigned(15 downto 0) := x"4300";
  --  0 (r) rx ready
  --  1 (r) tx ready (fake)
  --  2 (r) pll locked
  --  4 (r) rx is locked to reference
  --  5 (r) rx is locked to data
  --  8 (r) pll powerdown ???
  --  9 (r) reconfigure busy
  -- 10 (r) rx calibration busy
  -- 11 (r) tx calibration busy
  -- 12 (r) rx analog reset
  -- 13 (r) rx digital reset
  -- 14 (r) tx analog reset
  -- 15 (r) tx digital reset
  -- 16 (r) rx error detected
  -- 17 (r) rx disparity error
  -- 18 (r) rx runnign disparity
  -- 20 (r) rx pattern detect
  -- 21 (r) rx sync status
  -- 22 (r/w) reset rx error counter
  -- 23 (r/w) reset rx disp error counter
  -- 31..28 (a) reset link side logic
  
  ----------------------------
  -- FEMB RX packets 3
  ----------------------------  
  constant FEMB_1_STR_3_PACKET_COUNT : unsigned(15 downto 0) := x"1301";
  constant FEMB_2_STR_3_PACKET_COUNT : unsigned(15 downto 0) := x"2301";
  constant FEMB_3_STR_3_PACKET_COUNT : unsigned(15 downto 0) := x"3301";
  constant FEMB_4_STR_3_PACKET_COUNT : unsigned(15 downto 0) := x"4301";
  -- 31..0 (r) packet count

  ----------------------------
  -- FEMB Stream 3 RX packet rate
  ----------------------------  
  constant FEMB_1_STR_3_PACKET_RATE : unsigned(15 downto 0) := x"1302";
  constant FEMB_2_STR_3_PACKET_RATE : unsigned(15 downto 0) := x"2302";
  constant FEMB_3_STR_3_PACKET_RATE : unsigned(15 downto 0) := x"3302";
  constant FEMB_4_STR_3_PACKET_RATE : unsigned(15 downto 0) := x"4302";
  -- 31..0 (r) packet rate

  ----------------------------
  -- FEMB Stream 3 RX RAW packet rate
  ----------------------------  
  constant FEMB_1_STR_3_RAW_PACKET_RATE : unsigned(15 downto 0) := x"1303";
  constant FEMB_2_STR_3_RAW_PACKET_RATE : unsigned(15 downto 0) := x"2303";
  constant FEMB_3_STR_3_RAW_PACKET_RATE : unsigned(15 downto 0) := x"3303";
  constant FEMB_4_STR_3_RAW_PACKET_RATE : unsigned(15 downto 0) := x"4303";
  -- 31..0 (r) packet rate

  
  ----------------------------
  -- FEMB Stream 3 counter resets
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_RESETS : unsigned(15 downto 0) := x"1350";
  constant FEMB_2_STR_3_ERR_CNT_RESETS : unsigned(15 downto 0) := x"2350";
  constant FEMB_3_STR_3_ERR_CNT_RESETS : unsigned(15 downto 0) := x"3350";
  constant FEMB_4_STR_3_ERR_CNT_RESETS : unsigned(15 downto 0) := x"4350";  
  -- 0 (a) reset all counters for this stream
  -- 1 (a) reset convert in wait count
  -- 2 (a) reset bad sof count
  -- 3 (a) reset unexpetect eof count
  -- 4 (a) reset missing eof count
  -- 5 (a) reset kchar in data count
  -- 6 (a) reset bad checksum count
  -- 7 (a) reset buffer full count
  -- 8 (a) reset timestamp incr count
  --  9 (a) reset bad write count
  -- 10 (a) reset bad ro start count

  
  ----------------------------
  -- FEMB Stream 3 Convert in window
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"1351";
  constant FEMB_2_STR_3_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"2351";
  constant FEMB_3_STR_3_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"3351";
  constant FEMB_4_STR_3_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"4351";
  -- 31..0 (r/a) Count of converts between a convert and waiting for data(action reset)

  ----------------------------
  -- FEMB Stream 3 Bad start of frame
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"1352";
  constant FEMB_2_STR_3_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"2352";
  constant FEMB_3_STR_3_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"3352";
  constant FEMB_4_STR_3_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"4352";
  -- 31..0 (r/a) Count of bad start of frame characters (action reset)

  ----------------------------
  -- FEMB Stream 3 Early idle
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"1353";
  constant FEMB_2_STR_3_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"2353";
  constant FEMB_3_STR_3_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"3353";
  constant FEMB_4_STR_3_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"4353";
  -- 31..0 (r/a) Count of early idle characters (action reset)

  
  ----------------------------
  -- FEMB Stream 3 No idle
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"1354";
  constant FEMB_2_STR_3_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"2354";
  constant FEMB_3_STR_3_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"3354";
  constant FEMB_4_STR_3_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"4354";
  -- 31..0 (r/a) Count missing end of frame idle (action reset)

  ----------------------------
  -- FEMB Stream 3 K-char in data
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"1355";
  constant FEMB_2_STR_3_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"2355";
  constant FEMB_3_STR_3_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"3355";
  constant FEMB_4_STR_3_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"4355";
  -- 31..0 (r/a) Count k-chars in data (action reset)

  ----------------------------
  -- FEMB Stream 3 Bad Checksum
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"1356";
  constant FEMB_2_STR_3_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"2356";
  constant FEMB_3_STR_3_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"3356";
  constant FEMB_4_STR_3_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"4356";
  -- 31..0 (r/a) Count of bad checksums (action reset)
  
  ----------------------------
  -- FEMB Stream 3 Buffer full
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"1357";
  constant FEMB_2_STR_3_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"2357";
  constant FEMB_3_STR_3_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"3357";
  constant FEMB_4_STR_3_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"4357";
  -- 31..0 (r/a) Count of events lost due to the buffer being full (action reset)

  ----------------------------
  -- FEMB Stream 3 rx errors
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"1358";
  constant FEMB_2_STR_3_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"2358";
  constant FEMB_3_STR_3_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"3358";
  constant FEMB_4_STR_3_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"4358";
  -- 31..0 (r/a) Count of symbol errors on the rx

  ----------------------------
  -- FEMB Stream 3 rx disp errors
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"1359";
  constant FEMB_2_STR_3_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"2359";
  constant FEMB_3_STR_3_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"3359";
  constant FEMB_4_STR_3_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"4359";
  -- 31..0 (r/a) Count of disp errors on the rx

  ----------------------------
  -- FEMB Stream 3 timestamp incr error
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"135A";
  constant FEMB_2_STR_3_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"235A";
  constant FEMB_3_STR_3_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"335A";
  constant FEMB_4_STR_3_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"435A";
  -- 31..0 (r/a) Count of timestamp increment errors

  ----------------------------
  -- FEMB Stream 3 bad write count error
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"135B";
  constant FEMB_2_STR_3_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"235B";
  constant FEMB_3_STR_3_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"335B";
  constant FEMB_4_STR_3_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"435B";
  -- 31..0 (r/a) Count of bad write counts into CD to EB fifo

  ----------------------------
  -- FEMB Stream 3 bad ro start
  ----------------------------  
  constant FEMB_1_STR_3_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"135c";
  constant FEMB_2_STR_3_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"235c";
  constant FEMB_3_STR_3_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"335c";
  constant FEMB_4_STR_3_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"435c";
  -- 31..0 (r/a) Count of CD to EB fifo readouts that don't start with a SOF character

  ----------------------------
  -- FEMB Stream 1 timestamp incr error
  ----------------------------  
  constant FEMB_1_STR_3_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"135D";
  constant FEMB_2_STR_3_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"235D";
  constant FEMB_3_STR_3_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"335D";
  constant FEMB_4_STR_3_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"435D";
  -- 31..0 (r/a) rate of timestamp increment errors
  
  
  ----------------------------
  -- FEMB RX STATUS 4
  ----------------------------  
  constant FEMB_1_STR_4_STATUS : unsigned(15 downto 0) := x"1400";
  constant FEMB_2_STR_4_STATUS : unsigned(15 downto 0) := x"2400";
  constant FEMB_3_STR_4_STATUS : unsigned(15 downto 0) := x"3400";
  constant FEMB_4_STR_4_STATUS : unsigned(15 downto 0) := x"4400";
  --  0 (r) rx ready
  --  1 (r) tx ready (fake)
  --  2 (r) pll locked
  --  4 (r) rx is locked to reference
  --  5 (r) rx is locked to data
  --  8 (r) pll powerdown ???
  --  9 (r) reconfigure busy
  -- 10 (r) rx calibration busy
  -- 11 (r) tx calibration busy
  -- 12 (r) rx analog reset
  -- 13 (r) rx digital reset
  -- 14 (r) tx analog reset
  -- 15 (r) tx digital reset
  -- 16 (r) rx error detected
  -- 17 (r) rx disparity error
  -- 18 (r) rx runnign disparity
  -- 20 (r) rx pattern detect
  -- 21 (r) rx sync status
  -- 22 (r/w) reset rx error counter
  -- 23 (r/w) reset rx disp error counter
  -- 31..28 (a) reset link side logic
  
  ----------------------------
  -- FEMB RX packets 4
  ----------------------------  
  constant FEMB_1_STR_4_PACKET_COUNT : unsigned(15 downto 0) := x"1401";
  constant FEMB_2_STR_4_PACKET_COUNT : unsigned(15 downto 0) := x"2401";
  constant FEMB_3_STR_4_PACKET_COUNT : unsigned(15 downto 0) := x"3401";
  constant FEMB_4_STR_4_PACKET_COUNT : unsigned(15 downto 0) := x"4401";
  -- 31..0 (r) packet count

  ----------------------------
  -- FEMB Stream 4 RX packet rate
  ----------------------------  
  constant FEMB_1_STR_4_PACKET_RATE : unsigned(15 downto 0) := x"1402";
  constant FEMB_2_STR_4_PACKET_RATE : unsigned(15 downto 0) := x"2402";
  constant FEMB_3_STR_4_PACKET_RATE : unsigned(15 downto 0) := x"3402";
  constant FEMB_4_STR_4_PACKET_RATE : unsigned(15 downto 0) := x"4402";
  -- 31..0 (r) packet rate

  ----------------------------
  -- FEMB Stream 4 RX RAW packet rate
  ----------------------------  
  constant FEMB_1_STR_4_RAW_PACKET_RATE : unsigned(15 downto 0) := x"1403";
  constant FEMB_2_STR_4_RAW_PACKET_RATE : unsigned(15 downto 0) := x"2403";
  constant FEMB_3_STR_4_RAW_PACKET_RATE : unsigned(15 downto 0) := x"3403";
  constant FEMB_4_STR_4_RAW_PACKET_RATE : unsigned(15 downto 0) := x"4403";
  -- 31..0 (r) packet rate


  ----------------------------
  -- FEMB Stream 4 counter resets
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_RESETS : unsigned(15 downto 0) := x"1450";
  constant FEMB_2_STR_4_ERR_CNT_RESETS : unsigned(15 downto 0) := x"2450";
  constant FEMB_3_STR_4_ERR_CNT_RESETS : unsigned(15 downto 0) := x"3450";
  constant FEMB_4_STR_4_ERR_CNT_RESETS : unsigned(15 downto 0) := x"4450";  
  -- 0 (a) reset all counters for this stream
  -- 1 (a) reset convert in wait count
  -- 2 (a) reset bad sof count
  -- 3 (a) reset unexpetect eof count
  -- 4 (a) reset missing eof count
  -- 5 (a) reset kchar in data count
  -- 6 (a) reset bad checksum count
  -- 7 (a) reset buffer full count
  -- 8 (a) reset timestamp incr count
  --  9 (a) reset bad write count
  -- 10 (a) reset bad ro start count

  
  ----------------------------
  -- FEMB Stream 4 Convert in window
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"1451";
  constant FEMB_2_STR_4_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"2451";
  constant FEMB_3_STR_4_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"3451";
  constant FEMB_4_STR_4_ERR_CNT_CONVERT_IN_WAIT : unsigned(15 downto 0) := x"4451";
  -- 31..0 (r/a) Count of converts between a convert and waiting for data(action reset)

  ----------------------------
  -- FEMB Stream 4 Bad start of frame
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"1452";
  constant FEMB_2_STR_4_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"2452";
  constant FEMB_3_STR_4_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"3452";
  constant FEMB_4_STR_4_ERR_CNT_BAD_SOF : unsigned(15 downto 0) := x"4452";
  -- 31..0 (r/a) Count of bad start of frame characters (action reset)

  ----------------------------
  -- FEMB Stream 4 Early idle
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"1453";
  constant FEMB_2_STR_4_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"2453";
  constant FEMB_3_STR_4_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"3453";
  constant FEMB_4_STR_4_ERR_CNT_UNEXPECTED_EOF : unsigned(15 downto 0) := x"4453";
  -- 31..0 (r/a) Count of early idle characters (action reset)

  ----------------------------
  -- FEMB Stream 4 No idle
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"1454";
  constant FEMB_2_STR_4_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"2454";
  constant FEMB_3_STR_4_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"3454";
  constant FEMB_4_STR_4_ERR_CNT_MISSING_EOF : unsigned(15 downto 0) := x"4454";
  -- 31..0 (r/a) Count missing end of frame idle (action reset)

  ----------------------------
  -- FEMB Stream 4 K-char in data
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"1455";
  constant FEMB_2_STR_4_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"2455";
  constant FEMB_3_STR_4_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"3455";
  constant FEMB_4_STR_4_ERR_CNT_KCHAR_IN_DATA : unsigned(15 downto 0) := x"4455";
  -- 31..0 (r/a) Count k-chars in data (action reset)

  ----------------------------
  -- FEMB Stream 4 Bad Checksum
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"1456";
  constant FEMB_2_STR_4_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"2456";
  constant FEMB_3_STR_4_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"3456";
  constant FEMB_4_STR_4_ERR_CNT_BAD_CHSUM : unsigned(15 downto 0) := x"4456";
  -- 31..0 (r/a) Count of bad checksums (action reset)

  ----------------------------
  -- FEMB Stream 4 Buffer full
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"1457";
  constant FEMB_2_STR_4_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"2457";
  constant FEMB_3_STR_4_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"3457";
  constant FEMB_4_STR_4_ERR_CNT_BUFFER_FULL : unsigned(15 downto 0) := x"4457";
  -- 31..0 (r/a) Count of events lost due to the buffer being full (action reset)

  ----------------------------
  -- FEMB Stream 4 rx errors
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"1458";
  constant FEMB_2_STR_4_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"2458";
  constant FEMB_3_STR_4_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"3458";
  constant FEMB_4_STR_4_ERR_CNT_RX_ERROR : unsigned(15 downto 0) := x"4458";
  -- 31..0 (r/a) Count of symbol errors on the rx

  ----------------------------
  -- FEMB Stream 4 rx disp errors
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"1459";
  constant FEMB_2_STR_4_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"2459";
  constant FEMB_3_STR_4_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"3459";
  constant FEMB_4_STR_4_ERR_CNT_RX_DISP_ERROR : unsigned(15 downto 0) := x"4459";
  -- 31..0 (r/a) Count of disp errors on the rx

  ----------------------------
  -- FEMB Stream 4 timestamp incr error
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"145A";
  constant FEMB_2_STR_4_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"245A";
  constant FEMB_3_STR_4_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"345A";
  constant FEMB_4_STR_4_ERR_CNT_T_INCR : unsigned(15 downto 0) := x"445A";
  -- 31..0 (r/a) Count of timestamp increment errors

  ----------------------------
  -- FEMB Stream 4 bad write count error
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"145B";
  constant FEMB_2_STR_4_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"245B";
  constant FEMB_3_STR_4_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"345B";
  constant FEMB_4_STR_4_ERR_CNT_BAD_WRITE : unsigned(15 downto 0) := x"445B";
  -- 31..0 (r/a) Count of bad write counts into CD to EB fifo

  ----------------------------
  -- FEMB Stream 4 bad ro start
  ----------------------------  
  constant FEMB_1_STR_4_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"145c";
  constant FEMB_2_STR_4_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"245c";
  constant FEMB_3_STR_4_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"345c";
  constant FEMB_4_STR_4_ERR_CNT_BAD_RO_START : unsigned(15 downto 0) := x"445c";
  -- 31..0 (r/a) Count of CD to EB fifo readouts that don't start with a SOF character

  ----------------------------
  -- FEMB Stream 1 timestamp incr error
  ----------------------------  
  constant FEMB_1_STR_4_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"145D";
  constant FEMB_2_STR_4_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"245D";
  constant FEMB_3_STR_4_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"345D";
  constant FEMB_4_STR_4_ERR_RATE_T_INCR : unsigned(15 downto 0) := x"445D";
  -- 31..0 (r/a) rate of timestamp increment errors
  
  
  ----------------------------
  -- DAQ Control
  ----------------------------
  constant DAQ_CONTROL : unsigned(15 downto 0) := x"5000";
  -- 0     (r/w) reset
  -- 1     (r/w) reconfigure reset

  ----------------------------
  -- DAQ QSFP Control
  ----------------------------
  constant DAQ_QSFP_CONTROL : unsigned(15 downto 0) := x"5001";  
  -- 0     (r/w) reset
  -- 1     (r/w) low power mode
  -- 4     (r)   present
  -- 5     (r)   interrupt

  ----------------------------
  -- DAQ QSFP I2c Control
  ----------------------------
  constant DAQ_QSFP_I2C_Control : unsigned(15 downto 0) := x"5002";
  -- 0 (a) run
  -- 1 (r/w) r/w
  -- 2 (r) busy
  -- 3 (r) available
  -- 11..8 (r/w) byte_count
  -- 23..16 (r/w) address

  ----------------------------
  -- DAQ QSFP I2c write
  ----------------------------
  constant DAQ_QSFP_I2C_WR_DATA : unsigned(15 downto 0) := x"5003";
  -- 31..0 (r/w) write data

  ----------------------------
  -- DAQ QSFP I2c read
  ----------------------------
  constant DAQ_QSFP_I2C_RD_DATA : unsigned(15 downto 0) := x"5004";
  -- 31..0 (r) read data

  ----------------------------
  -- DAQ SI5342
  ----------------------------
  constant DAQ_SI5342_Control : unsigned(15 downto 0) := x"5010";
  -- 0 (r/w) enable
  -- 1 (r/w) reset
  -- 2 (r) LOL
  -- 3 (r) LOS_XAXB
  -- 4 (r) interrupt
  -- 7..5 (r) LOS
  -- 9..8 (r/w) input select
  
  ----------------------------
  -- DAQ SI5342 I2c Control
  ----------------------------
  constant DAQ_SI5342_I2C_Control : unsigned(15 downto 0) := x"5011";
  -- 0 (a) run
  -- 1 (r/w) r/w
  -- 2 (r) busy
  -- 3 (r) available
  -- 4 (a) reset
  -- 11..8 (r/w) byte_count
  -- 23..16 (r/w) address

  ----------------------------
  -- DAQ SI5342 I2c write
  ----------------------------
  constant DAQ_SI5342_I2C_WR_DATA : unsigned(15 downto 0) := x"5012";
  -- 31..0 (r/w) write data

  ----------------------------
  -- DAQ SI5342 I2c read
  ----------------------------
  constant DAQ_SI5342_I2C_RD_DATA : unsigned(15 downto 0) := x"5013";
  -- 31..0 (r) read data


  ----------------------------
  -- DAQ clk counter
  ----------------------------
  constant DAQ_CLK_COUNTER : unsigned(15 downto 0) := x"5020";
  -- 31..0 (r) read data

  ----------------------------
  -- DAQ clk write state
  ----------------------------
  constant DAQ_REG_WRITE_STATE : unsigned(15 downto 0) := x"5021";
  -- 3..0 (r) write state

  ----------------------------
  -- DAQ clk write count
  ----------------------------
  constant DAQ_REG_WRITE_COUNT : unsigned(15 downto 0) := x"5022";
  -- 31..0 (r) write count

  ----------------------------
  -- DAQ debugging
  ----------------------------
  constant DAQ_HISTORY_MONITOR_CONF : unsigned(15 downto 0) := x"5023";
  -- 0     (a) arm
  
  ----------------------------
  -- DAQ debugging
  ----------------------------
  constant DAQ_HISTORY_MONITOR_1 : unsigned(15 downto 0) := x"5024";
  -- 0     (r/i) valid
  -- 1     (r/i) type (1 presample, 0 postsample)
  -- 9..4  (r/i) data  

  ----------------------------
  -- DAQ debugging
  ----------------------------
  constant DAQ_HISTORY_MONITOR_2 : unsigned(15 downto 0) := x"5025";
  -- 31..0 (r) data  

  ----------------------------
  -- DAQ debugging
  ----------------------------
  constant DAQ_HISTORY_MONITOR_3 : unsigned(15 downto 0) := x"5026";
  -- 31..0 (r) data  
  
  ----------------------------
  -- DAQ Rx
  ----------------------------
--  constant DAQ_RX : unsigned(15 downto 0) := x"5014";
  -- 0 (r/w) analog reset
  -- 1 (r/w) digital reset
  -- 2 (r)   locked to ref
  -- 3 (r)   locked to data
  -- 4 (r)   cal busy

  ----------------------------
  -- DAQ LINK Fiber
  ----------------------------  
  constant DAQ_LINK_1_CONTROL : unsigned(15 downto 0) := x"5100";
  constant DAQ_LINK_2_CONTROL : unsigned(15 downto 0) := x"5200";
  constant DAQ_LINK_3_CONTROL : unsigned(15 downto 0) := x"5300";
  constant DAQ_LINK_4_CONTROL : unsigned(15 downto 0) := x"5400";
  -- 0       (r/w) daq-linke-enabled
  -- 1       (r/w) cd debug mode (0 off, 1 on)
  -- 9..8    (r)   fiber number  
  -- 19..16      (r) FEMB mask
  -- 31..24  (r/w) CD Stream enable

  ----------------------------
  -- DAQ Link 0 status
  ----------------------------  
  constant DAQ_LINK_1_STREAM_STATUS : unsigned(15 downto 0) := x"5101";
  constant DAQ_LINK_2_STREAM_STATUS : unsigned(15 downto 0) := x"5201";
  constant DAQ_LINK_3_STREAM_STATUS : unsigned(15 downto 0) := x"5301";
  constant DAQ_LINK_4_STREAM_STATUS : unsigned(15 downto 0) := x"5401";
  --  0 (r/w) tx reset
  --  1 (r)   tx pll powerdown
  --  2 (r)   tx analog reset
  --  3 (r )  tx digital reset
  --  4 (r)   tx pll locked
  --  5 (r)   tx ready
  --  6 (r)   tx cal busy
  
  ----------------------------
  -- DAQ Link 0 event count
  ----------------------------  
  constant DAQ_LINK_1_EVENT_COUNT : unsigned(15 downto 0) := x"5102";
  constant DAQ_LINK_2_EVENT_COUNT : unsigned(15 downto 0) := x"5202";
  constant DAQ_LINK_3_EVENT_COUNT : unsigned(15 downto 0) := x"5302";
  constant DAQ_LINK_4_EVENT_COUNT : unsigned(15 downto 0) := x"5402";
  -- 31..0 (r/a) event counter (reset)

  ----------------------------
  -- DAQ Link 0 debug
  ----------------------------  
  constant DAQ_LINK_1_DEBUG : unsigned(15 downto 0) := x"5103";
  constant DAQ_LINK_2_DEBUG : unsigned(15 downto 0) := x"5203";
  constant DAQ_LINK_3_DEBUG : unsigned(15 downto 0) := x"5303";
  constant DAQ_LINK_4_DEBUG : unsigned(15 downto 0) := x"5403";
  -- 0       (r/w) debug mode enable
  -- 1       (r/w) debug send bad crcs
  -- 31..16  (r/w) bad crc mask and comp.  

  ----------------------------
  -- DAQ Link 0 mismatch count
  ----------------------------  
  constant DAQ_LINK_1_MISMATCH_COUNT : unsigned(15 downto 0) := x"5104";
  constant DAQ_LINK_2_MISMATCH_COUNT : unsigned(15 downto 0) := x"5204";
  constant DAQ_LINK_3_MISMATCH_COUNT : unsigned(15 downto 0) := x"5304";
  constant DAQ_LINK_4_MISMATCH_COUNT : unsigned(15 downto 0) := x"5404";
  -- 31..0  (r/a) mismatch count (reset)

  ----------------------------
  -- DAQ Link 0 mismatch count
  ----------------------------  
  constant DAQ_LINK_1_TIMESTAMP_REPEATED_COUNT : unsigned(15 downto 0) := x"5105";
  constant DAQ_LINK_2_TIMESTAMP_REPEATED_COUNT : unsigned(15 downto 0) := x"5205";
  constant DAQ_LINK_3_TIMESTAMP_REPEATED_COUNT : unsigned(15 downto 0) := x"5305";
  constant DAQ_LINK_4_TIMESTAMP_REPEATED_COUNT : unsigned(15 downto 0) := x"5405";
  -- 31..0  (r/a) repeated timestamp count (reset)
  
  ----------------------------
  -- DAQ Link 0 event rate
  ----------------------------  
  constant DAQ_LINK_1_EVENT_RATE : unsigned(15 downto 0) := x"5106";
  constant DAQ_LINK_2_EVENT_RATE : unsigned(15 downto 0) := x"5206";
  constant DAQ_LINK_3_EVENT_RATE : unsigned(15 downto 0) := x"5306";
  constant DAQ_LINK_4_EVENT_RATE : unsigned(15 downto 0) := x"5406";
  -- 31..0 (r) event rate
  
  ----------------------------
  -- DAQ Link 0 spy_buffer control  
  ----------------------------  
  constant DAQ_LINK_1_SPY_BUFFER_CONTROL : unsigned(15 downto 0) := x"5110";
  constant DAQ_LINK_2_SPY_BUFFER_CONTROL : unsigned(15 downto 0) := x"5210";
  constant DAQ_LINK_3_SPY_BUFFER_CONTROL : unsigned(15 downto 0) := x"5310";
  constant DAQ_LINK_4_SPY_BUFFER_CONTROL : unsigned(15 downto 0) := x"5410";
  -- 0 (a)   spy buffer start
  -- 1 (r/w) wait for trigger mode
  -- 2 (r)   spy buffer empty
  -- 3 (r)   spy buffer capturing data
  ----------------------------
  -- DAQ Link 0 spy_buffer readout data
  ----------------------------  
  constant DAQ_LINK_1_SPY_BUFFER_READOUT_DATA : unsigned(15 downto 0) := x"5111";
  constant DAQ_LINK_2_SPY_BUFFER_READOUT_DATA : unsigned(15 downto 0) := x"5211";
  constant DAQ_LINK_3_SPY_BUFFER_READOUT_DATA : unsigned(15 downto 0) := x"5311";
  constant DAQ_LINK_4_SPY_BUFFER_READOUT_DATA : unsigned(15 downto 0) := x"5411";
  -- 31..0 (r/a) data characters

  ----------------------------
  -- DAQ Link 0 spy_buffer readout K-data
  ----------------------------  
  constant DAQ_LINK_1_SPY_BUFFER_READOUT_KDATA : unsigned(15 downto 0) := x"5112";
  constant DAQ_LINK_2_SPY_BUFFER_READOUT_KDATA : unsigned(15 downto 0) := x"5212";
  constant DAQ_LINK_3_SPY_BUFFER_READOUT_KDATA : unsigned(15 downto 0) := x"5312";
  constant DAQ_LINK_4_SPY_BUFFER_READOUT_KDATA : unsigned(15 downto 0) := x"5412";
  -- 3..0 (r) k-data bits
  

  ----------------------------
  -- DAQ Link 0 Rx status
  ----------------------------  
  constant DAQ_LINK_1_RX_STREAM_STATUS : unsigned(15 downto 0) := x"5151";
  constant DAQ_LINK_2_RX_STREAM_STATUS : unsigned(15 downto 0) := x"5251";
  constant DAQ_LINK_3_RX_STREAM_STATUS : unsigned(15 downto 0) := x"5351";
  constant DAQ_LINK_4_RX_STREAM_STATUS : unsigned(15 downto 0) := x"5451";
  --       0 (r) rx ready
  --       1 (r) rx analog reset
  --       2 (r) rx digital reset
  --       3 (r) rx cal busy
  --       4 (r) rx is locked to ref
  --       5 (r) rx is locked to data
  --  19..16 (r) error detected
  --  23..20 (r) running disparity
  --  27..24 (r) pattern detect
  --  31..28 (r) sync status

  ----------------------------
  -- DAQ Link 0 event count
  ----------------------------  
  constant DAQ_LINK_1_RX_EVENT_COUNT : unsigned(15 downto 0) := x"5152";
  constant DAQ_LINK_2_RX_EVENT_COUNT : unsigned(15 downto 0) := x"5252";
  constant DAQ_LINK_3_RX_EVENT_COUNT : unsigned(15 downto 0) := x"5352";
  constant DAQ_LINK_4_RX_EVENT_COUNT : unsigned(15 downto 0) := x"5452";
  -- 31..0 (r/a) event counter (reset)

  ----------------------------
  -- DAQ Link 0 Gearbox monitoring control
  ----------------------------  
  constant DAQ_LINK_1_GEARBOX_CTRL : unsigned(15 downto 0) := x"5160";
  constant DAQ_LINK_2_GEARBOX_CTRL : unsigned(15 downto 0) := x"5260";
  constant DAQ_LINK_3_GEARBOX_CTRL : unsigned(15 downto 0) := x"5360";
  constant DAQ_LINK_4_GEARBOX_CTRL : unsigned(15 downto 0) := x"5460";
  --  0 (a) reset all
  --  1 (a) reset underflow counter
  -- 16 (r/w) enable counter
  
  ----------------------------
  -- DAQ Link 0 Gearbox underflow counter
  ----------------------------  
  constant DAQ_LINK_1_GEARBOX_UNDERFLOW : unsigned(15 downto 0) := x"5161";
  constant DAQ_LINK_2_GEARBOX_UNDERFLOW : unsigned(15 downto 0) := x"5261";
  constant DAQ_LINK_3_GEARBOX_UNDERFLOW : unsigned(15 downto 0) := x"5361";
  constant DAQ_LINK_4_GEARBOX_UNDERFLOW : unsigned(15 downto 0) := x"5461";
  -- 31..0 (r/a) counter (wr-reset) 

  
  ----------------------------
  -- Flash control
  ----------------------------  
  constant FLASH_CTRL : unsigned(15 downto 0) := x"F000";
  -- 0 (a) run command
  -- 2..1 (a) command (11 erase, 01 read, 00 write,10 status)
  -- 8 (r)      invalid write
  -- 9 (r)      invalid erase
  -- 16 (r)     busy
  -- 29 (a)     reconfig reset
  -- 30 (r)     reconfig busy
  -- 31 (a)     reconfig
  
  ----------------------------
  -- Flash address
  ----------------------------  
  constant FLASH_ADDRESS : unsigned(15 downto 0) := x"F001";
  -- 23..0 (r/w) flash address

  ----------------------------
  -- Flash page byte count
  ----------------------------  
  constant FLASH_PAGE_BYTE_COUNT : unsigned(15 downto 0) := x"F002";
  -- 7..0 (r/w) byte count

  ----------------------------
  -- Flash status
  ----------------------------  
  constant FLASH_STATUS : unsigned(15 downto 0) := x"F003";
  -- 7..0 (r) flash status

  ----------------------------
  -- Flash status
  ----------------------------  
  constant FLASH_RECONFIG : unsigned(15 downto 0) := x"F004";
  -- 0 (a) param rd
  -- 1 (a) param wr
  -- 6..4 (r/w) param
  -- 31..8 (r/w) param value
  
  
  ----------------------------
  -- Flash page Data
  ----------------------------  
  constant FLASH_PAGE_DATA_START : unsigned(15 downto 0) := x"F080";
  -- 31 ..0 (r/w) data to write to queue for flash write

  ----------------------------
  -- Flash page Data
  ----------------------------  
  constant FLASH_PAGE_DATA_END : unsigned(15 downto 0) := x"F0FF";
  -- 31 ..0 (r/w) data to write to queue for flash write


  ----------------------------
  -- Register map locked
  ----------------------------  

  
  ----------------------------
  -- Test register clk 0
  ----------------------------  
  constant REG_TEST_0 : unsigned(15 downto 0) := x"FFF0";
  -- 31..0 (r/w) test

  ----------------------------
  -- Test register clk 1
  ----------------------------  
  constant REG_TEST_1 : unsigned(15 downto 0) := x"FFF1";
  -- 31..0 (r/w) test

  ----------------------------
  -- Test register clk 2
  ----------------------------  
  constant REG_TEST_2 : unsigned(15 downto 0) := x"FFF2";
  -- 31..0 (r/w) test

  ----------------------------
  -- Test register clk 3
  ----------------------------  
  constant REG_TEST_3 : unsigned(15 downto 0) := x"FFF3";
  -- 31..0 (r/w) test

  ----------------------------
  -- Test register clk 4
  ----------------------------  
  constant REG_TEST_4 : unsigned(15 downto 0) := x"FFF4";
  -- 31..0 (r/w) test

  ----------------------------
  -- Test register clk 5
  ----------------------------  
  constant REG_TEST_5 : unsigned(15 downto 0) := x"FFF5";
  -- 31..0 (r/w) test

  ----------------------------
  -- Test register clk 6
  ----------------------------  
  constant REG_TEST_6 : unsigned(15 downto 0) := x"FFF6";
  -- 31..0 (r/w) test

  ----------------------------
  -- Test register clk 7
  ----------------------------  
  constant REG_TEST_7 : unsigned(15 downto 0) := x"FFF7";
  -- 31..0 (r/w) test

  ----------------------------
  -- clk locked
  ----------------------------  
  constant REG_LOCKED : unsigned(15 downto 0) := x"FFFC";
  -- 6..0 (r) clock domain locked
  
  ----------------------------
  -- reg read count
  ----------------------------  
  constant REG_RD_COUNT : unsigned(15 downto 0) := x"FFFD";
  -- 31..0 (r/w) register reads

  ----------------------------
  -- reg write count
  ----------------------------  
  constant REG_WR_COUNT : unsigned(15 downto 0) := x"FFFE";
  -- 31..0 (r/w) register write 






  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------
  constant CLOCK_DOMAINS       : integer := 8;
  signal read_address_valid    : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal read_address_ack      : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal read_address          : uint16_array_t(CLOCK_DOMAINS-1 downto 0);
  signal read_address_cap      : unsigned16_array_t(CLOCK_DOMAINS-1 downto 0);
  signal read_data_wr          : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal read_data             : uint36_array_t(CLOCK_DOMAINS-1 downto 0);
  signal read_data_delayed     : uint36_array_t(CLOCK_DOMAINS-1 downto 0);
  signal write_addr_data_valid : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal write_addr_data_ack   : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal write_addr            : uint16_array_t(CLOCK_DOMAINS-1 downto 0);
  signal write_addr_cap        : unsigned16_array_t(CLOCK_DOMAINS-1 downto 0);
  signal write_data            : uint32_array_t(CLOCK_DOMAINS-1 downto 0);
  signal write_data_cap        : uint32_array_t(CLOCK_DOMAINS-1 downto 0);

  signal clk_domain        : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal clk_domain_locked : std_logic_vector(CLOCK_DOMAINS-1 downto 0);
  signal reset_sync_domain : std_logic_vector(CLOCK_DOMAINS-1 downto 0);      

  --FEMB decoding helpers

--type FEMB_index_array_t is array (CLOCK_DOMAINS-1 downto 0) of integer range FEMB_COUNT downto 1;
--type FEMB_stream_index_array_t is array (CLOCK_DOMAINS-1 downto 0) of integer range LINKS_PER_FEMB downto 1;

  signal FEMB_read_index         : integer range FEMB_COUNT downto 1;
  signal FEMB_read_stream_index  : integer range LINKS_PER_FEMB downto 1;
  signal FEMB_write_index        : integer range FEMB_COUNT downto 1;
  signal FEMB_write_stream_index : integer range LINKS_PER_FEMB downto 1;

  signal EB_FEMB_read_index      : integer range FEMB_COUNT downto 1;
  signal EB_FEMB_write_index     : integer range FEMB_COUNT downto 1;
  signal EB_FEMB_FEMB_read_index      : integer range FEMB_COUNT downto 1;
  signal EB_FEMB_read_stream_index    : integer range LINKS_PER_FEMB downto 1;

  signal SYS_DAQ_LINK_read_index  : integer range DAQ_LINK_COUNT -1 downto 0;
  signal SYS_DAQ_LINK_write_index : integer range DAQ_LINK_COUNT -1 downto 0;

  signal power_monitor_FEMB_index : integer range 4 downto 1;


  --Helper signals
  signal tx_clock_reset_pulse     : std_logic;
  signal eb_tx_reset              : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);  
  
  --state machines
  type READ_STATE_t is (READ_STATE_IDLE, READ_STATE_READ, READ_STATE_CAPTURE_ADDRESS, READ_STATE_ADDRESS_HELPERS, READ_STATE_WRITE);
  type READ_STATE_array_t is array (CLOCK_DOMAINS-1 downto 0) of READ_STATE_t;
  signal READ_state : READ_STATE_array_t := (others => READ_STATE_IDLE);

  type WRITE_STATE_t is (WRITE_STATE_IDLE, WRITE_STATE_CAPTURE_ADDRESS,WRITE_STATE_ADDRESS_HELPERS, WRITE_STATE_WRITE);
  type WRITE_STATE_array_t is array (CLOCK_DOMAINS-1 downto 0) of WRITE_STATE_t;
  signal WRITE_state : WRITE_STATE_array_t := (others => WRITE_STATE_IDLE);

  --testing
  type test_reg_t is array (CLOCK_DOMAINS-1 downto 0) of std_logic_vector(31 downto 0);
  signal test_reg_buffer : test_reg_t := (others => (others => '0'));
  signal test_reg : test_reg_t := (others => (others => '0'));

  signal SC_DND : std_logic_vector(31 downto 0);
  
  signal read_count  : std_logic_vector(31 downto 0) := x"00000000";
  signal write_count : std_logic_vector(31 downto 0) := x"00000000";

  signal daq_counter : std_logic_vector(31 downto 0);
  signal daq_write_count : std_logic_vector(31 downto 0);
  signal daq_write_hist_arm : std_logic;
  signal daq_write_hist_arm_clk0 : std_logic;
  signal write_state_lookup    : std_logic_vector( 3 downto  0);
  signal history_out           : std_logic_vector(69 downto  0);
  signal history_presample : std_logic;
  signal history_valid     : std_logic;
  signal history_ack       : std_logic;
  
  
begin  -- architecture Behavioral

  -------------------------------------------------------------------------------------
  -- clock domain bridge interface
  -------------------------------------------------------------------------------------
  clk_domain(0)        <= clk_WIB;
  clk_domain(1)        <= clk_FEMB;
  clk_domain(2)        <= clk_EVB;
  clk_domain(3)        <= clk_UDP;
  clk_domain(4)        <= clk_services;
  clk_domain(5)        <= clk_flash;
  clk_domain(6)        <= clk_DUNE;
  clk_domain(7)        <= clk_FEMB_CnC;
  
  clk_domain_locked(0) <= locked_WIB;
  clk_domain_locked(1) <= locked_FEMB;
  clk_domain_locked(2) <= locked_EVB;
  clk_domain_locked(3) <= locked_UDP;
  clk_domain_locked(4) <= locked_services;
  clk_domain_locked(5) <= locked_flash;
  clk_domain_locked(6) <= locked_DUNE;
  clk_domain_locked(7) <= locked_FEMB_CnC;

  reset_proc: for iClk in CLOCK_DOMAINS-1 downto 0 generate
    reseter_2: entity work.reseter
      port map (
        clk         => clk_domain(iClk),
        reset_async => reset,
        reset_sync  => '0',
        reset       => reset_sync_domain(iClk));
  end generate reset_proc;

  

  register_map_bridge_1 : entity work.register_map_bridge
    generic map (
      CLOCK_DOMAINS => CLOCK_DOMAINS)
    port map (
      clk_reg_map           => clk_UDP,
      reset                 => reset,
      WR_strobe             => WR_strb,
      RD_strobe             => RD_strb,
      WR_address            => WR_address,
      RD_address            => RD_address,
      data_in               => data_in,
      data_out              => data_out,
      rd_ack                => rd_ack,
      wr_ack                => wr_ack,
      clk_domain            => clk_domain,
      clk_domain_locked     => clk_domain_locked,
      read_address_valid    => read_address_valid,
      read_address_ack      => read_address_ack,
      read_address          => read_address,
      read_data_wr          => read_data_wr,
      read_data             => read_data,
      write_addr_data_valid => write_addr_data_valid,
      write_addr_data_ack   => write_addr_data_ack,
      write_addr            => write_addr,
      write_data            => write_data);


  -------------------------------------------------------------------------------------
  -- 100Mhz clocks
  -------------------------------------------------------------------------------------
  REGS_100Mhz : process (clk_domain(3)) is
  begin  -- process REGS_100Mhz
    if clk_domain(3)'event and clk_domain(3) = '1' then  -- rising clock edge
      if reset_sync_domain(3) = '1' then 
        WIB_control.REG_RESET    <= '0';
        UDP_Control <= DEFAULT_UDP_Control;
        WIB_control.glb_i_reset   <= '0';
        WIB_control.alg_reset     <= '0';
        WIB_control.evb_reset     <= '0';
        WIB_control.reset_femb_pll <= '0';
        
        test_reg(3) <= (others => '0');
        SC_DND <= (others => '0');

        READ_state(3)  <= READ_STATE_IDLE;
        WRITE_state(3) <= WRITE_STATE_IDLE;
      else                
        -------------------------------------------------------
        -- Read
        -------------------------------------------------------
        read_address_ack(3) <= '0';
        read_data_wr(3)     <= '0';

        case READ_state(3) is

          when READ_STATE_IDLE =>
            if read_address_valid(3) = '1' then
              read_address_ack(3) <= '1';
              READ_state(3)       <= READ_STATE_CAPTURE_ADDRESS;
            end if;
          when READ_STATE_CAPTURE_ADDRESS =>
            -- capture the address we will be using
            read_address_cap(3) <= unsigned(read_address(3));
            READ_state(3)       <= READ_STATE_READ;

          when READ_STATE_READ =>
            READ_state(3) <= READ_STATE_WRITE;

            read_data(3) <= x"100000000";  --Mark the data as zeros and the
                                           --register found                

            case read_address_cap(3) is
              when WIB_STATUS =>
                read_data(3)(0) <= WIB_Monitor.GLB_i_RESET;
                read_data(3)(1) <= WIB_Monitor.REG_RESET;
                read_data(3)(2) <= WIB_Monitor.UDP_RESET;
                read_data(3)(3) <= WIB_Monitor.DAQ_PATH_RESET;
                read_data(3)(4) <= WIB_Monitor.sys_locked;
                read_data(3)(5) <= WIB_Monitor.FEMB_locked;
                read_data(3)(6) <= WIB_Monitor.EB_locked;
                read_data(3)(9) <= WIB_Monitor.DCC_locked;
                read_data(3)(27 downto 24) <= WIB_Monitor.DAQ_LINK_COUNT;
                read_data(3)(31 downto 28) <= WIB_Monitor.FEMB_COUNT;
              when WIB_SC_DND =>
                read_data(3)(31 downto 0)  <= SC_DND;
              when UDP_CTRL =>
                read_data(3)(0) <= UDP_Monitor.en_readback;
              when UDP_TIMEOUT =>
                read_data(3)(31 downto 0) <= UDP_MOnitor.timeout;
              when UDP_DEST_IP =>
                read_data(3)(31 downto 0) <= UDP_Monitor.DQM_ip_dest_addr;
              when UDP_DEST_MAC_LO =>
                read_data(3)(31 downto 0) <= UDP_MOnitor.DQM_mac_dest_addr(31 downto 0);
              when UDP_DEST_MAC_HI =>
                read_data(3)(15 downto 0) <= UDP_Monitor.DQM_mac_dest_addr(47 downto 32);
              when UDP_DEST_PORT =>
                read_data(3)(15 downto 0) <= UDP_Monitor.DQM_dest_port;
              when UDP_FRAME_SIZE =>
                read_data(3)(11 downto 0) <= UDP_Monitor.frame_size;
              when REG_TEST_3 =>
                read_data(3)(31 downto 0) <= test_reg(3);
              when REG_LOCKED =>
                read_data(3)(7 downto 0) <= clk_domain_locked;
              when REG_RD_COUNT =>
                read_data(3)(31 downto 0) <= std_logic_vector(read_count);
              when REG_WR_COUNT =>
                read_data(3)(31 downto 0) <= std_logic_vector(write_count);
              when others =>
                --mark data as not found
                read_data(3) <= x"000000000";
            end case;

          when READ_STATE_WRITE =>
            read_data_wr(3) <= '1';
            READ_state(3)   <= READ_STATE_IDLE;
          when others =>
            READ_state(3) <= READ_STATE_IDLE;
        end case;

        -------------------------------------------------------
        -- Write
        -------------------------------------------------------
        WIB_control.REG_RESET <= '0';
        WIB_control.DAQ_PATH_RESET <= '0';
        WIB_control.reset_femb_pll <= '0';
        
        write_addr_data_ack(3) <= '0';
        case WRITE_state(3) is
          when WRITE_STATE_IDLE =>
            -- Write/action switch
            if write_addr_data_valid(3) = '1' then
              WRITE_STATE(3) <= WRITE_STATE_CAPTURE_ADDRESS;
            end if;
          when WRITE_STATE_CAPTURE_ADDRESS =>
            -- buffer address
            write_addr_cap(3)      <= unsigned(write_addr(3));
            write_data_cap(3)      <= write_data(3);
            WRITE_STATE(3)         <= WRITE_STATE_WRITE;
            write_addr_data_ack(3) <= '1';
          when WRITE_STATE_WRITE =>
            -- process write and ack
            WRITE_STATE(3) <= WRITE_STATE_IDLE;
            case write_addr_cap(3) is
              when WIB_STATUS =>
                --Reset UDP 
                WIB_control.DAQ_PATH_RESET <= write_data_cap(3)(3) or write_data_cap(3)(0);
                WIB_control.REG_RESET      <= write_data_cap(3)(1) or write_data_cap(3)(0);
                WIB_control.reset_femb_pll <= write_data_cap(3)(14) or write_data_cap(3)(0);
              when WIB_SC_DND   =>
                SC_DND <= write_data_cap(3)(31 downto 0);
              when UDP_CTRL =>
                UDP_Control.en_readback  <= write_data_cap(3)(0);
              when UDP_TIMEOUT =>
                UDP_Control.timeout      <= write_data_cap(3)(31 downto 0);
              when UDP_FRAME_SIZE =>
                UDP_Control.frame_size   <= write_data_cap(3)(11 downto 0);
              when REG_TEST_3 =>
                test_reg(3) <= write_data_cap(3);
                
              when others => null;
            end case;            
          when others => WRITE_STATE(3) <= WRITE_STATE_IDLE;
        end case;
      end if;
    end if;
  end process REGS_100Mhz;



  -------------------------------------------------------------------------------------
  -- WIB clocks
  -------------------------------------------------------------------------------------
  REGS_50Mhz : process (clk_domain(0)) is
  begin  -- process REGS_50Mhz
    if clk_domain(0)'event and clk_domain(0) = '1' then  -- rising clock edge
      if reset_sync_domain(0) = '1' then 
        WIB_control.UDP_RESET    <= '0';
        WIB_control.Power        <= DEFAULT_Power_control_t;
        WIB_control.use_fake_ID  <= DEFAULT_WIB_control.use_fake_ID;
        WIB_control.fake_id      <= DEFAULT_WIB_control.fake_id;
        
        DTS_Control.DUNE_clk_sel <= DEFAULT_DTS_control.DUNE_clk_sel; 
        DTS_Control.PDTS         <= DEFAULT_DTS_control.PDTS;         
        DTS_Control.CDS          <= DEFAULT_DTS_control.CDS;          
        DTS_Control.SI5344       <= DEFAULT_DTS_control.SI5344;       
        DTS_Control.DTS_Tx       <= DEFAULT_DTS_control.DTS_Tx;       
        

        EB_Control.tx_reset         <= DEFAULT_EB_Control.tx_reset;
        EB_Control.SI5342           <= DEFAULT_EB_control.SI5342;        

        tx_clock_reset_pulse <= '0';
        eb_tx_reset <= (others => '0');
        test_reg(0) <= (others => '0');

        FEMB_CNC_Control.DTS_reset <= '1';

        READ_state(0)  <= READ_STATE_IDLE;
        WRITE_state(0) <= WRITE_STATE_IDLE;

      else      
        -------------------------------------------------------
        -- Read
        -------------------------------------------------------
        read_address_ack(0) <= '0';
        read_data_wr(0)     <= '0';

        --incr pulse
        DTS_Control.history.ack <= '0';
        
        case READ_state(0) is

          when READ_STATE_IDLE =>
            if read_address_valid(0) = '1' then
              read_address_ack(0) <= '1';
              READ_state(0)       <= READ_STATE_CAPTURE_ADDRESS;
            end if;
          when READ_STATE_CAPTURE_ADDRESS =>
            -- capture the address we will be using
            read_address_cap(0) <= unsigned(read_address(0));
            READ_state(0)       <= READ_STATE_READ;
            SYS_DAQ_LINK_read_index <= to_integer(unsigned(read_address(0)(10 downto 8)));
          when READ_STATE_READ =>
            READ_state(0) <= READ_STATE_WRITE;

            read_data(0) <= x"100000000";  --Mark the data as zeros and the
                                           --register found                
            case read_address_cap(0) is
              when WIB_FW_VERSION =>
                read_data(0)(31 downto 0) <= FIRMWARE_VERSION;
              when WIB_SYNTH_DATE =>
                read_data(0)(31 downto 0) <= TS_CENT & TS_YEAR & TS_MONTH & TS_DAY;
              when WIB_SYNTH_TIME =>
                read_data(0)(31 downto 0) <= x"00" & TS_HOUR & TS_MIN & TS_SEC;
              when WIB_ID =>
                read_data(0)( 3 downto  0) <= WIB_Monitor.ID.slot;
                read_data(0)( 7 downto  4) <= WIB_Monitor.ID.crate;
                read_data(0)(8)            <= WIB_Monitor.use_fake_ID;
                read_data(0)(19 downto 16) <= WIB_Monitor.fake_ID.slot;
                read_data(0)(23 downto 20) <= WIB_Monitor.fake_ID.crate;
                read_data(0)(27 downto 24) <= WIB_Monitor.real_ID.slot;
                read_data(0)(31 downto 28) <= WIB_Monitor.real_ID.crate;
              when WIB_BPFP_DIS_MON =>
                read_data(0)(0)            <= WIB_Monitor.DTS_FP_CLK_OUT_DSBL;
                read_data(0)( 9 downto  4) <= WIB_Monitor.DTS_BP_OUT_DSBL;
              when DTS_CTRL =>
                read_data(0)(1)            <= DTS_Monitor.PDTS.enable;
                read_data(0)(2)            <= DTS_Monitor.PDTS.enable_resetter;
                read_data(0)(3)            <= DTS_Monitor.PDTS.resetter_count_reset;
                read_data(0)(4)            <= DTS_Monitor.PDTS.data_clk_reset;
                read_data(0)(5)            <= DTS_Monitor.PDTS.locked_data_clock;
                read_data(0)(8)            <= DTS_MOnitor.DTS_Tx.OE;
                read_data(0)(9)            <= DTS_MOnitor.DTS_Tx.buffered_loopback;
                read_data(0)(10)           <= DTS_Monitor.clk_DUNE_in_reset;
                read_data(0)(11)           <= DTS_Monitor.clk_DUNE_in_locked;
                read_data(0)(13 downto 12) <= DTS_Monitor.PDTS.timing_group;
                read_data(0)(19 downto 16) <= DTS_Monitor.PDTS.state;
              when DTS_RESET_COUNT =>
--                read_data(0)(23 downto 0) <= std_logic_vector(DTS_Monitor.reset_count);
              when DTS_EVENT_COUNT =>
                read_data(0)(31 downto 0) <= DTS_Monitor.PDTS.event_number(31 downto  0);
              when DTS_TIME_LSB =>
                read_data(0)(31 downto 0) <= DTS_Monitor.PDTS.timestamp(31 downto  0);
              when DTS_TIME_MSB =>
                read_data(0)(31 downto 0) <= DTS_Monitor.PDTS.timestamp(63 downto 32);
                
              when PDTS_RESETTER_COUNT =>
                read_data(0)(31 downto 0) <= DTS_Monitor.PDTS.resetter_count;

              when PDTS_HISTORY_MONITOR =>
                read_data(0)(0)            <= DTS_Monitor.history.valid;
                read_data(0)(1)            <= DTS_Monitor.history.presample;
                read_data(0)(12 downto  4) <= DTS_Monitor.history.data;
--                read_data(0)(28 downto  4) <= DTS_Monitor.history.data;
                DTS_Control.history.ack <= '1';

              when PDTS_ADDR =>
                read_data(0)( 7 downto  0) <= DTS_Monitor.PDTS.addr;
                read_data(0)(16)           <= DTS_Monitor.PDTS.addr_override_en;
                read_data(0)(31 downto 24) <= DTS_Monitor.PDTS.override_addr;
                
              when DTS_CDS_Control =>
                read_data(0)(0) <= DTS_monitor.CDS.input_select;
                read_data(0)(2) <= DTS_monitor.CDS.LOL;
                read_data(0)(3) <= DTS_monitor.CDS.LOS;

              when DTS_CDS_I2C_Control =>
                read_data(0)(1) <= DTS_monitor.CDS.I2C.rw;
                read_data(0)(2) <= DTS_monitor.CDS.I2C.done;
                read_data(0)(3) <= DTS_monitor.CDS.I2C.error;
                read_data(0)(10 downto  8) <= DTS_monitor.CDS.I2C.byte_count;
                read_data(0)(23 downto 16) <= DTS_monitor.CDS.I2C.address;

              when DTS_CDS_I2C_WR_DATA =>
                read_data(0)(31 downto 0) <= DTS_monitor.CDS.I2C.wr_data;

              when DTS_CDS_I2C_RD_DATA =>
                read_data(0)(31 downto 0) <= DTS_monitor.CDS.I2C.rd_data;

              when DTS_SI5344_Control =>
                read_data(0)(0) <= DTS_monitor.SI5344.enable;
                read_data(0)(1) <= DTS_monitor.SI5344.reset;
                read_data(0)(2) <= DTS_monitor.SI5344.LOL;
                read_data(0)(3) <= DTS_monitor.SI5344.LOS;
                read_data(0)(4) <= DTS_monitor.SI5344.interrupt;
                read_data(0)(9 downto 8) <= DTS_monitor.SI5344.in_sel;

              when DTS_SI5344_I2C_Control =>
                read_data(0)(1) <= DTS_monitor.SI5344.I2C.rw;
                read_data(0)(2) <= DTS_monitor.SI5344.I2C.done;
                read_data(0)(3) <= DTS_monitor.SI5344.I2C.error;
                read_data(0)(10 downto  8) <= DTS_monitor.SI5344.I2C.byte_count;
                read_data(0)(23 downto 16) <= DTS_monitor.SI5344.I2C.address;

              when DTS_SI5344_I2C_WR_DATA =>
                read_data(0)(31 downto 0) <= DTS_monitor.SI5344.I2C.wr_data;

              when DTS_SI5344_I2C_RD_DATA =>
                read_data(0)(31 downto 0) <= DTS_monitor.SI5344.I2C.rd_data;

              when DTS_SI5344_RST_REQ =>
                read_data(0)(31 downto 0) <= DTS_monitor.SI5344.count_reset_requests;
              when DTS_SI5344_RST_PERF =>
                read_data(0)(31 downto 0) <= DTS_monitor.SI5344.count_performed_resets;





              when DAQ_SI5342_Control =>
                read_data(0)(0) <= EB_monitor.SI5342.enable;
                read_data(0)(1) <= EB_monitor.SI5342.reset;
                read_data(0)(2) <= EB_monitor.SI5342.LOL;
                read_data(0)(3) <= EB_monitor.SI5342.LOSXAXB;
                read_data(0)(4) <= EB_monitor.SI5342.interrupt;
                read_data(0)(5) <= EB_monitor.SI5342.LOS1;
                read_data(0)(6) <= EB_monitor.SI5342.LOS2;
                read_data(0)(7) <= EB_monitor.SI5342.LOS3;
                read_data(0)(8) <= EB_monitor.SI5342.sel0;
                read_data(0)(9) <= EB_monitor.SI5342.sel1;

              when DAQ_SI5342_I2C_Control =>
                read_data(0)(1) <= EB_monitor.SI5342.I2C.rw;
                read_data(0)(2) <= EB_monitor.SI5342.I2C.done;
                read_data(0)(3) <= EB_monitor.SI5342.I2C.error;
                read_data(0)(10 downto  8) <= EB_monitor.SI5342.I2C.byte_count;
                read_data(0)(23 downto 16) <= EB_monitor.SI5342.I2C.address;

              when DAQ_SI5342_I2C_WR_DATA =>
                read_data(0)(31 downto 0) <= EB_monitor.SI5342.I2C.wr_data;

              when DAQ_SI5342_I2C_RD_DATA =>
                read_data(0)(31 downto 0) <= EB_monitor.SI5342.I2C.rd_data;

                                
              when DTS_SYNC_CMD_CONTROL =>
                read_data(0)(15 downto 0) <= DTS_monitor.PDTS.CMD_count_reset;
              when DTS_SYNC_CMD_COUNT_0  | DTS_SYNC_CMD_COUNT_1  | DTS_SYNC_CMD_COUNT_2  | DTS_SYNC_CMD_COUNT_3  |
                   DTS_SYNC_CMD_COUNT_4  | DTS_SYNC_CMD_COUNT_5  | DTS_SYNC_CMD_COUNT_6  | DTS_SYNC_CMD_COUNT_7  |
                   DTS_SYNC_CMD_COUNT_8  | DTS_SYNC_CMD_COUNT_9  | DTS_SYNC_CMD_COUNT_10 | DTS_SYNC_CMD_COUNT_11 |
                   DTS_SYNC_CMD_COUNT_12 | DTS_SYNC_CMD_COUNT_13 | DTS_SYNC_CMD_COUNT_14 | DTS_SYNC_CMD_COUNT_15 =>
                read_data(0)(31 downto 0) <= DTS_monitor.PDTS.CMD_count(to_integer(read_address_cap(0)(3 downto 0)));
              when REG_TEST_0 =>
                read_data(0)(31 downto 0) <= test_reg(0);

              when FEMB_POWER_CONTROL =>
                read_data(0)(0) <= WIB_Monitor.Power.EN_3V6(0);
                read_data(0)(1) <= WIB_Monitor.Power.EN_2V8(0);
                read_data(0)(2) <= WIB_Monitor.Power.EN_2V5(0);
                read_data(0)(3) <= WIB_Monitor.Power.EN_1V5(0);
                read_data(0)(4) <= WIB_Monitor.Power.EN_BIAS(0);

                read_data(0)(8)  <= WIB_Monitor.Power.EN_3V6(1);
                read_data(0)(9)  <= WIB_Monitor.Power.EN_2V8(1);
                read_data(0)(10) <= WIB_Monitor.Power.EN_2V5(1);
                read_data(0)(11) <= WIB_Monitor.Power.EN_1V5(1);
                read_data(0)(12) <= WIB_Monitor.Power.EN_BIAS(1);

                read_data(0)(16) <= WIB_Monitor.Power.EN_3V6(2);
                read_data(0)(17) <= WIB_Monitor.Power.EN_2V8(2);
                read_data(0)(18) <= WIB_Monitor.Power.EN_2V5(2);
                read_data(0)(19) <= WIB_Monitor.Power.EN_1V5(2);
                read_data(0)(20) <= WIB_Monitor.Power.EN_BIAS(2);

                read_data(0)(24) <= WIB_Monitor.Power.EN_3V6(3);
                read_data(0)(25) <= WIB_Monitor.Power.EN_2V8(3);
                read_data(0)(26) <= WIB_Monitor.Power.EN_2V5(3);
                read_data(0)(27) <= WIB_Monitor.Power.EN_1V5(3);
                read_data(0)(28) <= WIB_Monitor.Power.EN_BIAS(3);
                read_data(0)(31) <= WIB_Monitor.Power.EN_BIAS_MASTER;
--              when FEMB_POWER_MON_CONTROL =>
--                read_data(0)(7 downto 0) <= WIB_Monitor.Power.measurement_select;
--                read_data(0)(8)          <= WIB_Monitor.Power.measurement_valid;
--              when FEMB_POWER_MON_VALUE =>
--                read_data(0)(31 downto 0) <= WIB_Monitor.Power.measurement;

              when DAQ_LINK_1_STREAM_STATUS | DAQ_LINK_2_STREAM_STATUS | DAQ_LINK_3_STREAM_STATUS | DAQ_LINK_4_STREAM_STATUS =>
                read_data(0)(0)          <= EB_Monitor.tx_reset(SYS_DAQ_LINK_read_index);
                read_data(0)(1)          <= EB_Monitor.tx_pll_powerdown(SYS_DAQ_LINK_read_index);
                read_data(0)(2)          <= EB_Monitor.tx_analogreset(SYS_DAQ_LINK_read_index);
                read_data(0)(3)          <= EB_Monitor.tx_digitalreset(SYS_DAQ_LINK_read_index);
                read_data(0)(4)          <= EB_Monitor.tx_pll_locked(SYS_DAQ_LINK_read_index);
                read_data(0)(5)          <= EB_Monitor.tx_ready(SYS_DAQ_LINK_read_index);
                read_data(0)(6)          <= EB_Monitor.tx_cal_busy(SYS_DAQ_LINK_read_index);


              when others =>
                --mark data as not found
                read_data(0) <= x"000000000";
            end case;
          when READ_STATE_WRITE =>
            read_data_wr(0) <= '1';
            READ_state(0)   <= READ_STATE_IDLE;
          when others =>
            READ_state(0) <= READ_STATE_IDLE;
        end case;

        -------------------------------------------------------
        -- Write
        -------------------------------------------------------
        WIB_control.UDP_RESET <= '0';
        WIB_control.Power.measurement_start <= '0';

        DTS_control.CDS.I2C.run    <= '0';
        DTS_control.SI5344.I2C.run <= '0';
                

        DTS_control.SI5344.reset_count_reset_requests   <= '0';
        DTS_control.SI5344.reset_count_performed_resets <= '0';

        DTS_control.CDS.I2C.reset <= '0';
        DTS_control.SI5344.I2C.reset <= '0';

        tx_clock_reset_pulse <= '0';
        for iLink in DAQ_LINK_COUNT-1 downto 0 loop
          EB_Control.tx_reset(iLink) <= eb_tx_reset(iLink) or tx_clock_reset_pulse;          
        end loop;  -- iLink

        FEMB_CNC_Control.DTS_reset <= '0';

        EB_control.SI5342.I2C.run <= '0';
        EB_control.SI5342.I2C.reset <= '0';

        daq_write_hist_arm_clk0 <= '0';
        
        write_addr_data_ack(0) <= '0';
        case WRITE_state(0) is
          when WRITE_STATE_IDLE =>
            -- Write/action switch
            if write_addr_data_valid(0) = '1' then
              WRITE_STATE(0) <= WRITE_STATE_CAPTURE_ADDRESS;
            end if;
          when WRITE_STATE_CAPTURE_ADDRESS =>
            -- buffer address
            write_addr_cap(0)      <= unsigned(write_addr(0));
            write_data_cap(0)      <= write_data(0);
            WRITE_STATE(0)         <= WRITE_STATE_WRITE;
            SYS_DAQ_LINK_write_index   <= to_integer(unsigned(write_addr(0)(10 downto 8)));
            write_addr_data_ack(0) <= '1';
          when WRITE_STATE_WRITE =>
            -- process write and ack
            WRITE_STATE(0) <= WRITE_STATE_IDLE;
            case write_addr_cap(0) is
              when WIB_STATUS =>
                --Reset UDP 
                WIB_control.UDP_RESET <= write_data_cap(0)(2)  or write_data_cap(0)(0);
                tx_clock_reset_pulse  <= write_data_cap(0)(12) or write_data_cap(0)(0);                
--              WIB_control.ALG_RESET <= write_data_cap(0)(3) or write_data_cap(0)(0);
              when WIB_ID =>
                WIB_control.use_fake_ID   <= write_data_cap(0)(8);
                WIB_control.fake_ID.slot  <= write_data_cap(0)(19 downto 16);
                WIB_control.fake_ID.crate <= write_data_cap(0)(23 downto 20);
              when DTS_CTRL =>
                DTS_control.PDTS.enable          <= write_data_cap(0)(1);
                DTS_control.PDTS.enable_resetter          <= write_data_cap(0)(2);
                DTS_control.PDTS.resetter_count_reset     <= write_data_cap(0)(3);
                DTS_control.PDTS.data_clk_reset           <= write_data_cap(0)(4);
                DTS_Control.DTS_Tx.OE            <= write_data_cap(0)(8);
                DTS_Control.DTS_Tx.buffered_loopback <= write_data_cap(0)(9);                
                DTS_control.PDTS.timing_group    <= write_data_cap(0)(13 downto 12);
                
              when DTS_CDS_Control =>
                DTS_control.CDS.input_select <= write_data_cap(0)(0);
              when DTS_CDS_I2C_Control =>
                DTS_control.CDS.I2C.run <= write_data_cap(0)(0);
                DTS_control.CDS.I2C.rw  <= write_data_cap(0)(1);
                DTS_control.CDS.I2C.reset <= write_data_cap(0)(4);
                DTS_control.CDS.I2C.byte_count <= write_data_cap(0)(10 downto  8);
                DTS_control.CDS.I2C.address    <= write_data_cap(0)(23 downto 16);

              when DTS_CDS_I2C_WR_DATA =>
                DTS_control.CDS.I2C.wr_data <= write_data_cap(0)(31 downto 0);

              when DTS_SI5344_Control =>
                DTS_control.SI5344.enable <= write_data_cap(0)(0);
                DTS_control.SI5344.reset  <= write_data_cap(0)(1);                
                DTS_control.SI5344.in_sel <= write_data_cap(0)(9 downto 8);
              when DTS_SI5344_I2C_Control =>
                DTS_control.SI5344.I2C.run <= write_data_cap(0)(0);
                DTS_control.SI5344.I2C.rw <= write_data_cap(0)(1);
                DTS_control.SI5344.I2C.reset <= write_data_cap(0)(4);
                
                DTS_control.SI5344.I2C.byte_count <= write_data_cap(0)(10 downto  8);
                DTS_control.SI5344.I2C.address    <= write_data_cap(0)(23 downto 16);

              when DTS_SI5344_I2C_WR_DATA =>
                DTS_control.SI5344.I2C.wr_data   <= write_data_cap(0)(31 downto 0);

              when DTS_SI5344_RST_REQ =>
                DTS_control.SI5344.reset_count_reset_requests <= '1';
              when DTS_SI5344_RST_PERF =>
                DTS_control.SI5344.reset_count_performed_resets <= '1';

                
              when DTS_SYNC_CMD_CONTROL =>
                DTS_control.PDTS.CMD_count_reset <= write_data_cap(0)(15 downto 0);

              when PDTS_ADDR =>
                DTS_Control.PDTS.addr_override_en <= write_data_cap(0)(16);
                DTS_Control.PDTS.override_addr    <= write_data_cap(0)(31 downto 24);
                

              when DAQ_HISTORY_MONITOR_CONF =>
                daq_write_hist_arm_clk0 <= '1';

              when DAQ_SI5342_Control =>
                EB_control.SI5342.enable <= write_data_cap(0)(0);
                EB_control.SI5342.reset  <= write_data_cap(0)(1);                
                EB_control.SI5342.sel0   <= write_data_cap(0)(8);
                EB_control.SI5342.sel1   <= write_data_cap(0)(9);
              when DAQ_SI5342_I2C_Control =>
                EB_control.SI5342.I2C.run <= write_data_cap(0)(0);
                EB_control.SI5342.I2C.rw <= write_data_cap(0)(1);
                EB_control.SI5342.I2C.reset <= write_data_cap(0)(4);
                
                EB_control.SI5342.I2C.byte_count <= write_data_cap(0)(10 downto  8);
                EB_control.SI5342.I2C.address    <= write_data_cap(0)(23 downto 16);

              when DAQ_SI5342_I2C_WR_DATA =>
                EB_control.SI5342.I2C.wr_data   <= write_data_cap(0)(31 downto 0);



              when FEMB_CNC =>
                if write_data_cap(0)(4) = '1' then
                  FEMB_CNC_Control.DTS_reset <= '1';                  
                end if;


                
              when REG_TEST_0 =>
                test_reg(0) <= write_data_cap(0);
              when FEMB_POWER_CONTROL =>
                WIB_Control.Power.EN_3V6(0) <=  write_data_cap(0)(0); 
                WIB_Control.Power.EN_2V8(0) <=  write_data_cap(0)(1); 
                WIB_Control.Power.EN_2V5(0) <=  write_data_cap(0)(2); 
                WIB_Control.Power.EN_1V5(0) <=  write_data_cap(0)(3); 
                WIB_Control.Power.EN_BIAS(0)<=  write_data_cap(0)(4); 
                
                WIB_Control.Power.EN_3V6(1) <=  write_data_cap(0)(8); 
                WIB_Control.Power.EN_2V8(1) <=  write_data_cap(0)(9); 
                WIB_Control.Power.EN_2V5(1) <=  write_data_cap(0)(10); 
                WIB_Control.Power.EN_1V5(1) <=  write_data_cap(0)(11); 
                WIB_Control.Power.EN_BIAS(1)<=  write_data_cap(0)(12); 
                
                WIB_Control.Power.EN_3V6(2) <=  write_data_cap(0)(16); 
                WIB_Control.Power.EN_2V8(2) <=  write_data_cap(0)(17); 
                WIB_Control.Power.EN_2V5(2) <=  write_data_cap(0)(18); 
                WIB_Control.Power.EN_1V5(2) <=  write_data_cap(0)(19); 
                WIB_Control.Power.EN_BIAS(2)<=  write_data_cap(0)(20); 
                
                WIB_Control.Power.EN_3V6(3) <=  write_data_cap(0)(24); 
                WIB_Control.Power.EN_2V8(3) <=  write_data_cap(0)(25); 
                WIB_Control.Power.EN_2V5(3) <=  write_data_cap(0)(26); 
                WIB_Control.Power.EN_1V5(3) <=  write_data_cap(0)(27); 
                WIB_Control.Power.EN_BIAS(3)<=  write_data_cap(0)(28);

                WIB_Control.Power.EN_BIAS_MASTER <= write_data_cap(0)(31);
--              when FEMB_POWER_MON_CONTROL =>
--                WIB_Control.Power.measurement_select <= write_data_cap(0)(7 downto 0);
--                WIB_Control.Power.measurement_start <= '1';
              when DAQ_LINK_1_STREAM_STATUS | DAQ_LINK_2_STREAM_STATUS | DAQ_LINK_3_STREAM_STATUS | DAQ_LINK_4_STREAM_STATUS =>
                eb_tx_reset(SYS_DAQ_LINK_write_index-1)         <= write_data_cap(0)(0);

              when others => null;
            end case;
          when others => WRITE_STATE(0) <= WRITE_STATE_IDLE;
        end case;
      end if;
    end if;
  end process REGS_50Mhz;


  -------------------------------------------------------------------------------------
  -- Event builder clocks
  -------------------------------------------------------------------------------------
  daq_counter_1 : entity work.counter
    generic map (
      DATA_WIDTH  => 32)
    port map (
      clk         => clk_domain(2),
      reset_async => '0',
      reset_sync  => '0',
      enable      => '1',
      event       => '1',
      count       => daq_counter,
      at_max      => open);
  counter_2: entity work.counter
    generic map (
      DATA_WIDTH  => 32)
    port map (
      clk         => clk_domain(2),
      reset_async => '0',
      reset_sync  => '0',
      enable      => '1',
      event       => write_addr_data_valid(2),
      count       => daq_write_count,
      at_max      => open);

  pacd_1: entity work.pacd
    port map (
      iPulseA => daq_write_hist_arm_clk0,
      iClkA   => clk_domain(0),
      iRSTAn  => '1',
      iClkB   => clk_domain(2),
      iRSTBn  => '1',
      oPulseB => daq_write_hist_arm);

  write_state_lookup <= x"1" when write_state(2) = WRITE_STATE_IDLE else
                        x"2" when write_state(2) = WRITE_STATE_CAPTURE_ADDRESS else
                        x"4" when write_state(2) = WRITE_STATE_ADDRESS_HELPERS else
                        x"8" when write_state(2) = WRITE_STATE_WRITE else
                        x"0";
                        
  history_monitor_1: entity work.history_monitor
    generic map (
      HISTORY_BIT_LENGTH => 4,
      SIGNAL_COUNT       => history_out'length)
    port map (
      clk               => clk_domain(2),
      reset             => '0',
      signals(15 downto 0)  => write_addr(2),
      signals(31 downto 16) => std_logic_vector(write_addr_cap(2)),
      signals(63 downto 32) => write_data(2),
      signals(67 downto 64) => write_state_lookup,
      signals(68)       => write_addr_data_valid(2),
      signals(69)       => write_addr_data_ack(2),
      start             => daq_write_hist_arm,
      stop              => write_addr_data_valid(2),
      history_out       => history_out,
      history_presample => history_presample,
      history_valid     => history_valid,
      history_ack       => history_ack);
  
  event_builder_EBClk : process (clk_domain(2)) is
  begin  -- process event_builder_EBClk
    if clk_domain(2)'event and clk_domain(2) = '1' then  -- rising clock edge
      if reset_sync_domain(2) = '1' then 
        
        for iDAQ_LINK in DAQ_LINK_COUNT downto 1 loop
          EB_Control.DAQ_LINK_EB(iDAQ_LINK) <= DEFAULT_EB_CONTROL.DAQ_LINK_EB(iDAQ_LINK);
        end loop;  -- iFEMB
        
        test_reg(2) <= (others => '0');
        READ_state(2)  <= READ_STATE_IDLE;
        WRITE_state(2) <= WRITE_STATE_IDLE;
        
      else
        test_reg_buffer(2) <= test_reg(2);
        -------------------------------------------------------
        -- Read
        -------------------------------------------------------
        read_address_ack(2) <= '0';
        read_data_wr(2)     <= '0';
        history_ack <= '1';
        
        case READ_state(2) is
          when READ_STATE_IDLE =>
            if read_address_valid(2) = '1' then
              read_address_ack(2) <= '1';
              READ_state(2)       <= READ_STATE_CAPTURE_ADDRESS;
            end if;
          when READ_STATE_CAPTURE_ADDRESS =>
            -- capture the address we will be using
            read_address_cap(2) <= unsigned(read_address(2));
            READ_state(2)       <= READ_STATE_ADDRESS_HELPERS;

          when READ_STATE_ADDRESS_HELPERS =>
            -- FEMB index for 0x5XXX addresses
            EB_FEMB_read_index  <= to_integer(unsigned(read_address_cap(2)(10 downto 8)));
            --FEMB index for 0xXXXX addresses
            EB_FEMB_FEMB_read_index  <= to_integer(unsigned(read_address_cap(2)(14 downto 12)));
            --stream index for 0xXXXX addresses
            EB_FEMB_read_stream_index  <= to_integer(unsigned(read_address_cap(2)(10 downto 8)));
            
            READ_state(2)       <= READ_STATE_READ;
            
          when READ_STATE_READ =>
            READ_state(2) <= READ_STATE_WRITE;

            read_data_delayed(2) <= x"100000000";  --Mark the data as zeros and the
                                           --register found                
            case read_address_cap(2) is
              when DAQ_CLK_COUNTER =>
                read_data_delayed(2)(31 downto 0) <= daq_counter;
              when DAQ_REG_WRITE_STATE =>
                case WRITE_state(2) is
                  when WRITE_STATE_IDLE            => read_Data_delayed(2)(3 downto 0) <= x"1";
                  when WRITE_STATE_CAPTURE_ADDRESS => read_Data_delayed(2)(3 downto 0) <= x"2";
                  when WRITE_STATE_ADDRESS_HELPERS => read_Data_delayed(2)(3 downto 0) <= x"3";
                  when WRITE_STATE_WRITE           => read_Data_delayed(2)(3 downto 0) <= x"4";
                  when others                      => read_Data_delayed(2)(3 downto 0) <= x"0";
                end case;
              when DAQ_REG_WRITE_COUNT =>                
                read_data_delayed(2)(31 downto 0) <= daq_write_count;

              when DAQ_HISTORY_MONITOR_1 =>
                read_data_delayed(2)(0)            <= history_valid;
                read_data_delayed(2)(1)            <= history_presample;
                read_data_delayed(2)( 7 downto  4) <= history_out(67 downto 64);
                read_data_delayed(2)(8)            <= history_out(68);
                read_data_delayed(2)(9)            <= history_out(69);
                history_ack <= '1';

              when DAQ_HISTORY_MONITOR_2 =>
                read_data_delayed(2)(31 downto 0)     <= history_out(63 downto 32);
              when DAQ_HISTORY_MONITOR_3 =>
                read_data_delayed(2)(31 downto 0)     <= history_out(31 downto  0);
                                                      
                
              when DAQ_LINK_1_CONTROL | DAQ_LINK_2_CONTROL | DAQ_LINK_3_CONTROL | DAQ_LINK_4_CONTROL =>
                read_data_delayed(2)(0)            <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).enable;
                read_data_delayed(2)(1)            <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).CD_readout_debug;
                read_data_delayed(2)(9 downto 8)   <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).fiber_number;
                read_data_delayed(2)(19 downto 16) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).FEMB_mask;
                read_data_delayed(2)(24+LINKS_PER_DAQ_LINK -1 downto 24) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).COLDATA_en;
                
              when DAQ_LINK_1_EVENT_COUNT | DAQ_LINK_2_EVENT_COUNT | DAQ_LINK_3_EVENT_COUNT | DAQ_LINK_4_EVENT_COUNT =>
                read_data_delayed(2)(31 downto 0) <= std_logic_vector(EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).event_count);

              when DAQ_LINK_1_EVENT_RATE | DAQ_LINK_2_EVENT_RATE | DAQ_LINK_3_EVENT_RATE | DAQ_LINK_4_EVENT_RATE =>
                read_data_delayed(2)(31 downto 0) <= std_logic_vector(EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).event_rate);

              when DAQ_LINK_1_DEBUG | DAQ_LINK_2_DEBUG | DAQ_LINK_3_DEBUG | DAQ_LINK_4_DEBUG =>
                read_data_delayed(2)(0)          <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).debug;
                read_data_delayed(2)(1)          <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).enable_bad_crc;
                read_data_delayed(2)(31 downto 16) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).bad_crc_bits;

              when DAQ_LINK_1_MISMATCH_COUNT | DAQ_LINK_2_MISMATCH_COUNT | DAQ_LINK_3_MISMATCH_COUNT | DAQ_LINK_4_MISMATCH_COUNT =>
                read_data_delayed(2)(31 downto 0) <= std_logic_vector(EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).mismatch_count);

              when DAQ_LINK_1_TIMESTAMP_REPEATED_COUNT | DAQ_LINK_2_TIMESTAMP_REPEATED_COUNT | DAQ_LINK_3_TIMESTAMP_REPEATED_COUNT | DAQ_LINK_4_TIMESTAMP_REPEATED_COUNT =>
                read_data_delayed(2)(31 downto 0) <= std_logic_vector(EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).timestamp_repeated_count);

              when DAQ_LINK_1_SPY_BUFFER_CONTROL | DAQ_LINK_2_SPY_BUFFER_CONTROL | DAQ_LINK_3_SPY_BUFFER_CONTROL | DAQ_LINK_4_SPY_BUFFER_CONTROL =>
                read_data_delayed(2)(1) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_wait_for_trigger;
                read_data_delayed(2)(2) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_empty;
                read_data_delayed(2)(3) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_running;
              when DAQ_LINK_1_SPY_BUFFER_READOUT_DATA | DAQ_LINK_2_SPY_BUFFER_READOUT_DATA | DAQ_LINK_3_SPY_BUFFER_READOUT_DATA | DAQ_LINK_4_SPY_BUFFER_READOUT_DATA =>
                read_data_delayed(2)( 7 downto  0) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_data( 7 downto  0);
                read_data_delayed(2)(15 downto  8) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_data(16 downto  9);
                read_data_delayed(2)(23 downto 16) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_data(25 downto 18);
                read_data_delayed(2)(31 downto 24) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_data(34 downto 27);              
              when DAQ_LINK_1_SPY_BUFFER_READOUT_KDATA | DAQ_LINK_2_SPY_BUFFER_READOUT_KDATA | DAQ_LINK_3_SPY_BUFFER_READOUT_KDATA | DAQ_LINK_4_SPY_BUFFER_READOUT_KDATA =>
                read_data_delayed(2)(0) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_data( 8);
                read_data_delayed(2)(1) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_data(17);
                read_data_delayed(2)(2) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_data(26);
                read_data_delayed(2)(3) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).spy_buffer_data(35);

              when DAQ_LINK_1_GEARBOX_CTRL | DAQ_LINK_2_GEARBOX_CTRL | DAQ_LINK_3_GEARBOX_CTRL | DAQ_LINK_4_GEARBOX_CTRL =>
                read_data_delayed(2)(16)  <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).gearbox.enable_counter_underflow;
              when DAQ_LINK_1_GEARBOX_UNDERFLOW | DAQ_LINK_2_GEARBOX_UNDERFLOW | DAQ_LINK_3_GEARBOX_UNDERFLOW | DAQ_LINK_4_GEARBOX_UNDERFLOW =>
                read_data_delayed(2)(31 downto 0) <= EB_Monitor.DAQ_LINK_EB(EB_FEMB_read_index).gearbox.counter_underflow;
                
--              when DAQ_CONTROL =>
--                read_data_delayed(2)(0) <= EB_Monitor.reset;
--                read_data_delayed(2)(1) <= EB_Monitor.reconf_reset;                
                
--              when DAQ_LINK_0_STREAM_STATUS =>
--                read_data_delayed(2)(0)  <= EB_Monitor.tx_ready(0);
--                read_data_delayed(2)(1)  <= EB_Monitor.pll_locked(0);
--                read_data_delayed(2)(4)  <= EB_Monitor.pll_powerdown(0);
--                read_data_delayed(2)(5)  <= EB_Monitor.reconfig_busy;
--                read_data_delayed(2)(8)  <= EB_Monitor.tx_cal_busy(0);
--                read_data_delayed(2)(9)  <= EB_Monitor.tx_analogreset(0);
--                read_data_delayed(2)(10) <= EB_Monitor.tx_digitalreset(0);

              when REG_TEST_2 =>
--                read_data_delayed(2)(31 downto 0) <= test_reg(2);
                read_data_delayed(2)(31 downto 0) <= test_reg_buffer(2);
                
              when others =>
                --mark data as not found
                read_data_delayed(2) <= x"000000000";
            end case;

          when READ_STATE_WRITE =>
            read_data(2)    <= read_data_delayed(2);
            read_data_wr(2) <= '1';
            READ_state(2)   <= READ_STATE_IDLE;
          when others =>
            READ_state(2) <= READ_STATE_IDLE;
        end case;

        -------------------------------------------------------
        -- Write/action
        -------------------------------------------------------
        write_addr_data_ack(2)                  <= '0';
        -- action resets
        for iDAQ_LINK in DAQ_LINK_COUNT downto 1 loop 
          EB_Control.DAQ_LINK_EB(iDAQ_LINK).event_count_reset <= '0';
          EB_Control.DAQ_LINK_EB(iDAQ_LINK).mismatch_count_reset <= '0';
          EB_Control.DAQ_LINK_EB(iDAQ_LINK).timestamp_repeated_count_reset <= '0';          
          EB_Control.DAQ_LINK_EB(iDAQ_LINK).spy_buffer_start  <= '0';
          EB_Control.DAQ_LINK_EB(iDAQ_LINK).spy_buffer_read <= '0';
          EB_Control.DAQ_LINK_EB(iDAQ_LINK).gearbox.reset_counter_underflow <= '0';
        end loop;  -- iFEMB

        
        case WRITE_state(2) is
          when WRITE_STATE_IDLE =>
            -- Write/action switch
            if write_addr_data_valid(2) = '1' then
              WRITE_STATE(2) <= WRITE_STATE_CAPTURE_ADDRESS;
            end if;
          when WRITE_STATE_CAPTURE_ADDRESS =>
            -- buffer address
            write_addr_cap(2)      <= unsigned(write_addr(2));
            write_data_cap(2)      <= write_data(2);
            WRITE_STATE(2)         <= WRITE_STATE_ADDRESS_HELPERS;
            write_addr_data_ack(2) <= '1';
          when WRITE_STATE_ADDRESS_HELPERS =>
            EB_FEMB_write_index  <= to_integer(unsigned(write_addr_cap(2)(10 downto 8)));
            WRITE_STATE(2)         <= WRITE_STATE_WRITE;
          when WRITE_STATE_WRITE =>
            -- process write and ack
            WRITE_STATE(2) <= WRITE_STATE_IDLE;
            case write_addr_cap(2) is
                
              when DAQ_LINK_1_CONTROL | DAQ_LINK_2_CONTROL | DAQ_LINK_3_CONTROL | DAQ_LINK_4_CONTROL =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).enable               <= write_data_cap(2)(0);
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).CD_readout_debug     <= write_data_cap(2)(1);
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).COLDATA_en           <= write_data_cap(2)(24+LINKS_PER_DAQ_LINK -1 downto 24);
                
              when DAQ_LINK_1_EVENT_COUNT | DAQ_LINK_2_EVENT_COUNT | DAQ_LINK_3_EVENT_COUNT | DAQ_LINK_4_EVENT_COUNT =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).event_count_reset    <= '1';
                
              when DAQ_LINK_1_DEBUG | DAQ_LINK_2_DEBUG | DAQ_LINK_3_DEBUG | DAQ_LINK_4_DEBUG =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).debug                <= write_data_cap(2)(0);
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).enable_bad_crc       <= write_data_cap(2)(1);
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).bad_crc_bits         <= write_data_cap(2)(31 downto 16);
                
              when DAQ_LINK_1_MISMATCH_COUNT | DAQ_LINK_2_MISMATCH_COUNT | DAQ_LINK_3_MISMATCH_COUNT | DAQ_LINK_4_MISMATCH_COUNT =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).mismatch_count_reset <= '1';
                
              when DAQ_LINK_1_TIMESTAMP_REPEATED_COUNT | DAQ_LINK_2_TIMESTAMP_REPEATED_COUNT | DAQ_LINK_3_TIMESTAMP_REPEATED_COUNT | DAQ_LINK_4_TIMESTAMP_REPEATED_COUNT =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).TIMESTAMP_REPEATED_count_reset <= '1';
                
              when DAQ_LINK_1_SPY_BUFFER_CONTROL | DAQ_LINK_2_SPY_BUFFER_CONTROL | DAQ_LINK_3_SPY_BUFFER_CONTROL | DAQ_LINK_4_SPY_BUFFER_CONTROL =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).spy_buffer_start <= write_data_cap(2)(0);
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).spy_buffer_wait_for_trigger <= write_data_cap(2)(1);
                
              when DAQ_LINK_1_SPY_BUFFER_READOUT_DATA | DAQ_LINK_2_SPY_BUFFER_READOUT_DATA | DAQ_LINK_3_SPY_BUFFER_READOUT_DATA | DAQ_LINK_4_SPY_BUFFER_READOUT_DATA =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).spy_buffer_read <= '1';

              when DAQ_LINK_1_GEARBOX_CTRL | DAQ_LINK_2_GEARBOX_CTRL | DAQ_LINK_3_GEARBOX_CTRL | DAQ_LINK_4_GEARBOX_CTRL =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).gearbox.enable_counter_underflow <= write_data_cap(2)(16);
                if write_data_cap(2)(0) = '1' or write_data_cap(2)(1) = '1' then
                  EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).gearbox.reset_counter_underflow <= '1';
                end if;
                
              when DAQ_LINK_1_GEARBOX_UNDERFLOW | DAQ_LINK_2_GEARBOX_UNDERFLOW | DAQ_LINK_3_GEARBOX_UNDERFLOW | DAQ_LINK_4_GEARBOX_UNDERFLOW =>
                EB_Control.DAQ_LINK_EB(EB_FEMB_write_index).gearbox.reset_counter_underflow <= '1';
                
              when REG_TEST_2 =>
                test_reg(2) <= write_data_cap(2);
              when others => null;
            end case;
          when others =>
            WRITE_STATE(2) <= WRITE_STATE_IDLE;
        end case;
      end if;
    end if;
  end process event_builder_EBClk;

  -------------------------------------------------------------------------------------
  -- FEMB clocks
  -------------------------------------------------------------------------------------

  REGS_128Mhz : process (clk_domain(1)) is
  begin  -- process REGS_128Mhz
    if clk_domain(1)'event and clk_domain(1) = '1' then  -- rising clock edge
      
      if reset_sync_domain(1) = '1' then 
        FEMB_DAQ_Control <= DEFAULT_FEMB_DAQs_control;
       
        
        DQM_Control <= DEFAULT_DQM_CONTROL;
        test_reg(1) <= (others => '0');

        READ_state(1)  <= READ_STATE_IDLE;
        WRITE_state(1) <= WRITE_STATE_IDLE;

      else
        
        -------------------------------------------------------
        -- Read
        -------------------------------------------------------
        read_address_ack(1) <= '0';
        read_data_wr(1)     <= '0';

        FEMB_DAQ_Control.spy.fifo_read <= '0';
        
        case READ_state(1) is

          when READ_STATE_IDLE =>
            if read_address_valid(1) = '1' then
              read_address_ack(1) <= '1';
              READ_state(1)       <= READ_STATE_CAPTURE_ADDRESS;

              read_address_cap(1)    <= unsigned(read_address(1));
              FEMB_read_index        <= to_integer(unsigned(read_address(1)(14 downto 12)));
              FEMB_read_stream_index <= to_integer(unsigned(read_address(1)(10 downto 8)));

            end if;
          when READ_STATE_CAPTURE_ADDRESS =>
            -- capture the address we will be using
--            read_address_cap(1) <= unsigned(read_address(1));
--            READ_state(1)       <= READ_STATE_ADDRESS_HELPERS;
            READ_state(1)       <= READ_STATE_READ;

--          when READ_STATE_ADDRESS_HELPERS =>
--            --Create useful itnegers for address table bits
--            FEMB_read_index        <= to_integer(unsigned(read_address_cap(1)(14 downto 12)));
--            FEMB_read_stream_index <= to_integer(unsigned(read_address_cap(1)(10 downto 8)));
--            READ_state(1)             <= READ_STATE_READ;
          when READ_STATE_READ =>
            read_address_ack(1) <= '1';
            READ_state(1) <= READ_STATE_WRITE;

            read_data_delayed(1) <= x"100000000";  --Mark the data as zeros and the
                                                   --register found                
            case read_address_cap(1) is
              when DQM_CTRL =>
                read_data_delayed(1)(0)          <= DQM_Monitor.enable_DQM;
                read_data_delayed(1)(7 downto 4) <= DQM_Monitor.DQM_type;

              when DQM_CD_SS =>
                read_data_delayed(1)(0)          <= DQM_Monitor.CD_SS.stream_number;
                read_data_delayed(1)(1)          <= DQM_Monitor.CD_SS.CD_number;
                read_data_delayed(1)(3 downto 2) <= DQM_Monitor.CD_SS.FEMB_number;
                read_data_delayed(1)(4)          <= DQM_Monitor.CD_SS.sub_stream_number;

              when FEMB_SPY_CONTROL =>
                read_data_delayed(1)( 3 downto  0) <= std_logic_vector(to_unsigned(FEMB_DAQ_Monitor.spy.stream_id,4));
                read_data_delayed(1)(4)            <= FEMB_DAQ_Monitor.spy.ext_en;
                read_data_delayed(1)(5)            <= FEMB_DAQ_Monitor.spy.word_en;
                read_data_delayed(1)(8)            <= FEMB_DAQ_Monitor.spy.fifo_empty;
                read_data_delayed(1)(20 downto 12) <= FEMB_DAQ_Monitor.spy.word_trig;
                read_data_delayed(1)(31 downto 30) <= FEMB_DAQ_Monitor.spy.state;

              when FEMB_SPY_READOUT =>
                read_data_delayed(1)( 8 downto  0) <= FEMB_DAQ_Monitor.spy.fifo_data;
                FEMB_DAQ_Control.spy.fifo_read <= not FEMB_DAQ_Monitor.spy.fifo_empty;
              when FEMB_DUPLICATE =>
                read_data_delayed(1)(0) <= FEMB_DAQ_Monitor.copyFEMB1and2to3and4;
                
              when FEMB_1_CONTROL | FEMB_2_CONTROL | FEMB_3_CONTROL | FEMB_4_CONTROL =>
                read_data_delayed(1)(0) <= FEMB_DAQ_Monitor.reset;
                read_data_delayed(1)(1) <= FEMB_DAQ_Monitor.reconf_reset;
                read_data_delayed(1)(4) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(1).enable;
                read_data_delayed(1)(5) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(2).enable;
                read_data_delayed(1)(6) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(3).enable;
                read_data_delayed(1)(7) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(4).enable;        

              when FEMB_1_TRIGGER | FEMB_2_TRIGGER | FEMB_3_TRIGGER | FEMB_4_TRIGGER =>
                read_data_delayed(1)(7 downto 0)   <= std_logic_vector(to_unsigned(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(1).convert_delay, 8));
                read_data_delayed(1)(15 downto 8)  <= std_logic_vector(to_unsigned(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(1).convert_delay, 8));
                read_data_delayed(1)(23 downto 16) <= std_logic_vector(to_unsigned(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(2).convert_delay, 8));
                read_data_delayed(1)(31 downto 24) <= std_logic_vector(to_unsigned(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(2).convert_delay, 8));

              when FEMB_1_FAKE_CD | FEMB_2_FAKE_CD | FEMB_3_FAKE_CD | FEMB_4_FAKE_CD =>
                read_data_delayed(1)(0)          <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).FAKE_CD(1).fake_data_type(0);
                read_data_delayed(1)(1)          <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).FAKE_CD(2).fake_data_type(0);
                read_data_delayed(1)(2)          <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).FAKE_CD(1).fake_data_type(1);
                read_data_delayed(1)(3)          <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).FAKE_CD(2).fake_data_type(1);
                read_data_delayed(1)(7 downto 4) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).fake_loopback_en;
                read_data_delayed(1)(8)          <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).fake_stream_type(1);
                read_data_delayed(1)(9)          <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).fake_stream_type(2);
                read_data_delayed(1)(10)         <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).fake_stream_type(1);
                read_data_delayed(1)(11)         <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).fake_stream_type(2);

              when FEMB_1_FAKE_CD_1_1_PACKETS | FEMB_2_FAKE_CD_1_1_PACKETS | FEMB_3_FAKE_CD_1_1_PACKETS | FEMB_4_FAKE_CD_1_1_PACKETS =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).counter_packets_A);
              when FEMB_1_FAKE_CD_1_2_PACKETS | FEMB_2_FAKE_CD_1_2_PACKETS | FEMB_3_FAKE_CD_1_2_PACKETS | FEMB_4_FAKE_CD_1_2_PACKETS =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).counter_packets_B);
              when FEMB_1_FAKE_CD_2_1_PACKETS | FEMB_2_FAKE_CD_2_1_PACKETS | FEMB_3_FAKE_CD_2_1_PACKETS | FEMB_4_FAKE_CD_2_1_PACKETS =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).counter_packets_A);
              when FEMB_1_FAKE_CD_2_2_PACKETS | FEMB_2_FAKE_CD_2_2_PACKETS | FEMB_3_FAKE_CD_2_2_PACKETS | FEMB_4_FAKE_CD_2_2_PACKETS =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).counter_packets_B);

              when FEMB_1_FAKE_CD_RESERVED_WORD | FEMB_2_FAKE_CD_RESERVED_WORD | FEMB_3_FAKE_CD_RESERVED_WORD | FEMB_4_FAKE_CD_RESERVED_WORD =>
                read_data_delayed(1)(15 downto  0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).set_reserved;
                read_data_delayed(1)(31 downto 16) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).set_reserved;

              when FEMB_1_FAKE_CD_1_HEADER_WORD | FEMB_2_FAKE_CD_1_HEADER_WORD | FEMB_3_FAKE_CD_1_HEADER_WORD | FEMB_4_FAKE_CD_1_HEADER_WORD =>
                read_data_delayed(1)(31 downto  0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).set_header;

              when FEMB_1_FAKE_CD_2_HEADER_WORD | FEMB_2_FAKE_CD_2_HEADER_WORD | FEMB_3_FAKE_CD_2_HEADER_WORD | FEMB_4_FAKE_CD_2_HEADER_WORD =>
                read_data_delayed(1)(31 downto  0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).set_header;

                
--            when FEMB_1_FAKE_CD_1_DATA | FEMB_2_FAKE_CD_1_DATA | FEMB_3_FAKE_CD_1_DATA | FEMB_4_FAKE_CD_1_DATA =>
--              read_data_delayed(1)(8 downto 0)   <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).data_A;
--              read_data_delayed(1)(24 downto 16) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).data_B;
--            when FEMB_1_FAKE_CD_2_DATA | FEMB_2_FAKE_CD_2_DATA | FEMB_3_FAKE_CD_2_DATA | FEMB_4_FAKE_CD_2_DATA =>
--              read_data_delayed(1)(8 downto 0)   <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).data_A;
--              read_data_delayed(1)(24 downto 16) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).data_B;


                
              when FEMB_1_FAKE_CD_1_ERR_INJ | FEMB_2_FAKE_CD_1_ERR_INJ | FEMB_3_FAKE_CD_1_ERR_INJ | FEMB_4_FAKE_CD_1_ERR_INJ =>
                read_data_delayed(1)(0)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_BAD_CHECKSUM(0);
                read_data_delayed(1)(1)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_BAD_SOF(0);
                read_data_delayed(1)(2)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_LARGE_FRAME(0);
                read_data_delayed(1)(3)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_SHORT_FRAME(0);
                read_data_delayed(1)(4)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_K_CHAR(0);
                read_data_delayed(1)(15 downto 8)  <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_CD_errors(7 downto 0);
                read_data_delayed(1)(16)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_BAD_CHECKSUM(1);
                read_data_delayed(1)(17)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_BAD_SOF(1);
                read_data_delayed(1)(18)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_LARGE_FRAME(1);
                read_data_delayed(1)(19)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_SHORT_FRAME(1);
                read_data_delayed(1)(20)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_K_CHAR(1);
                read_data_delayed(1)(31 downto 24) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(1).inject_CD_errors(15 downto 8);

              when FEMB_1_FAKE_CD_2_ERR_INJ | FEMB_2_FAKE_CD_2_ERR_INJ | FEMB_3_FAKE_CD_2_ERR_INJ | FEMB_4_FAKE_CD_2_ERR_INJ =>
                read_data_delayed(1)(0)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_BAD_CHECKSUM(0);
                read_data_delayed(1)(1)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_BAD_SOF(0);
                read_data_delayed(1)(2)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_LARGE_FRAME(0);
                read_data_delayed(1)(3)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_SHORT_FRAME(0);
                read_data_delayed(1)(4)            <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_K_CHAR(0);
                read_data_delayed(1)(15 downto 8)  <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_CD_errors(7 downto 0);
                read_data_delayed(1)(16)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_BAD_CHECKSUM(1);
                read_data_delayed(1)(17)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_BAD_SOF(1);
                read_data_delayed(1)(18)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_LARGE_FRAME(1);
                read_data_delayed(1)(19)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_SHORT_FRAME(1);
                read_data_delayed(1)(20)           <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_K_CHAR(1);
                read_data_delayed(1)(31 downto 24) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Fake_CD(2).inject_CD_errors(15 downto 8);


              when FEMB_1_STR_1_STATUS | FEMB_1_STR_2_STATUS | FEMB_1_STR_3_STATUS | FEMB_1_STR_4_STATUS |
                FEMB_2_STR_1_STATUS | FEMB_2_STR_2_STATUS | FEMB_2_STR_3_STATUS | FEMB_2_STR_4_STATUS |
                FEMB_3_STR_1_STATUS | FEMB_3_STR_2_STATUS | FEMB_3_STR_3_STATUS | FEMB_3_STR_4_STATUS |
                FEMB_4_STR_1_STATUS | FEMB_4_STR_2_STATUS | FEMB_4_STR_3_STATUS | FEMB_4_STR_4_STATUS =>
                read_data_delayed(1)(0)  <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).LOS(FEMB_read_stream_index);
                read_data_delayed(1)(1)  <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_cal_busy(FEMB_read_stream_index);

                read_data_delayed(1)(4)  <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_analogreset(FEMB_read_stream_index);
                read_data_delayed(1)(5)  <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_digitalreset(FEMB_read_stream_index);
                read_data_delayed(1)(6)  <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_is_lockedtoref(FEMB_read_stream_index);
                read_data_delayed(1)(7)  <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_is_lockedtodata(FEMB_read_stream_index);
                read_data_delayed(1)(15 downto 10) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rdusedw(FEMB_read_stream_index);
                
                read_data_delayed(1)(16) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_errdetect(FEMB_read_stream_index);
                read_data_delayed(1)(17) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_disperr(FEMB_read_stream_index);
                read_data_delayed(1)(18) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_runningdisp(FEMB_read_stream_index);
                read_data_delayed(1)(20) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_patterndetect(FEMB_read_stream_index);
                read_data_delayed(1)(21) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.rx_syncstatus(FEMB_read_stream_index);

                read_data_delayed(1)(22) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.reset_counter_rx_error(FEMB_read_stream_index);
                read_data_delayed(1)(23) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.reset_counter_rx_disp_error(FEMB_read_stream_index);

              when FEMB_1_STR_1_PACKET_COUNT | FEMB_1_STR_2_PACKET_COUNT | FEMB_1_STR_3_PACKET_COUNT | FEMB_1_STR_4_PACKET_COUNT |
                FEMB_2_STR_1_PACKET_COUNT | FEMB_2_STR_2_PACKET_COUNT | FEMB_2_STR_3_PACKET_COUNT | FEMB_2_STR_4_PACKET_COUNT |
                FEMB_3_STR_1_PACKET_COUNT | FEMB_3_STR_2_PACKET_COUNT | FEMB_3_STR_3_PACKET_COUNT | FEMB_3_STR_4_PACKET_COUNT |
                FEMB_4_STR_1_PACKET_COUNT | FEMB_4_STR_2_PACKET_COUNT | FEMB_4_STR_3_PACKET_COUNT | FEMB_4_STR_4_PACKET_COUNT =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_packets);

              when FEMB_1_STR_1_PACKET_RATE | FEMB_1_STR_2_PACKET_RATE | FEMB_1_STR_3_PACKET_RATE | FEMB_1_STR_4_PACKET_RATE |
                FEMB_2_STR_1_PACKET_RATE | FEMB_2_STR_2_PACKET_RATE | FEMB_2_STR_3_PACKET_RATE | FEMB_2_STR_4_PACKET_RATE |
                FEMB_3_STR_1_PACKET_RATE | FEMB_3_STR_2_PACKET_RATE | FEMB_3_STR_3_PACKET_RATE | FEMB_3_STR_4_PACKET_RATE |
                FEMB_4_STR_1_PACKET_RATE | FEMB_4_STR_2_PACKET_RATE | FEMB_4_STR_3_PACKET_RATE | FEMB_4_STR_4_PACKET_RATE =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).timer_frames);

              when FEMB_1_STR_1_RAW_PACKET_RATE | FEMB_1_STR_2_RAW_PACKET_RATE | FEMB_1_STR_3_RAW_PACKET_RATE | FEMB_1_STR_4_RAW_PACKET_RATE |
                FEMB_2_STR_1_RAW_PACKET_RATE | FEMB_2_STR_2_RAW_PACKET_RATE | FEMB_2_STR_3_RAW_PACKET_RATE | FEMB_2_STR_4_RAW_PACKET_RATE |
                FEMB_3_STR_1_RAW_PACKET_RATE | FEMB_3_STR_2_RAW_PACKET_RATE | FEMB_3_STR_3_RAW_PACKET_RATE | FEMB_3_STR_4_RAW_PACKET_RATE |
                FEMB_4_STR_1_RAW_PACKET_RATE | FEMB_4_STR_2_RAW_PACKET_RATE | FEMB_4_STR_3_RAW_PACKET_RATE | FEMB_4_STR_4_RAW_PACKET_RATE =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.raw_sof_rate(FEMB_read_stream_index));

                
              when FEMB_1_STR_1_ERR_CNT_BAD_CHSUM | FEMB_1_STR_2_ERR_CNT_BAD_CHSUM | FEMB_1_STR_3_ERR_CNT_BAD_CHSUM | FEMB_1_STR_4_ERR_CNT_BAD_CHSUM |
                FEMB_2_STR_1_ERR_CNT_BAD_CHSUM | FEMB_2_STR_2_ERR_CNT_BAD_CHSUM | FEMB_2_STR_3_ERR_CNT_BAD_CHSUM | FEMB_2_STR_4_ERR_CNT_BAD_CHSUM |
                FEMB_3_STR_1_ERR_CNT_BAD_CHSUM | FEMB_3_STR_2_ERR_CNT_BAD_CHSUM | FEMB_3_STR_3_ERR_CNT_BAD_CHSUM | FEMB_3_STR_4_ERR_CNT_BAD_CHSUM |
                FEMB_4_STR_1_ERR_CNT_BAD_CHSUM | FEMB_4_STR_2_ERR_CNT_BAD_CHSUM | FEMB_4_STR_3_ERR_CNT_BAD_CHSUM | FEMB_4_STR_4_ERR_CNT_BAD_CHSUM =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_BAD_CHSUM);
                

              when FEMB_1_STR_1_ERR_CNT_BUFFER_FULL | FEMB_1_STR_2_ERR_CNT_BUFFER_FULL | FEMB_1_STR_3_ERR_CNT_BUFFER_FULL | FEMB_1_STR_4_ERR_CNT_BUFFER_FULL |
                FEMB_2_STR_1_ERR_CNT_BUFFER_FULL | FEMB_2_STR_2_ERR_CNT_BUFFER_FULL | FEMB_2_STR_3_ERR_CNT_BUFFER_FULL | FEMB_2_STR_4_ERR_CNT_BUFFER_FULL |
                FEMB_3_STR_1_ERR_CNT_BUFFER_FULL | FEMB_3_STR_2_ERR_CNT_BUFFER_FULL | FEMB_3_STR_3_ERR_CNT_BUFFER_FULL | FEMB_3_STR_4_ERR_CNT_BUFFER_FULL |
                FEMB_4_STR_1_ERR_CNT_BUFFER_FULL | FEMB_4_STR_2_ERR_CNT_BUFFER_FULL | FEMB_4_STR_3_ERR_CNT_BUFFER_FULL | FEMB_4_STR_4_ERR_CNT_BUFFER_FULL =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_BUFFER_FULL);

              when FEMB_1_STR_1_ERR_CNT_CONVERT_IN_WAIT | FEMB_1_STR_2_ERR_CNT_CONVERT_IN_WAIT | FEMB_1_STR_3_ERR_CNT_CONVERT_IN_WAIT | FEMB_1_STR_4_ERR_CNT_CONVERT_IN_WAIT |
                FEMB_2_STR_1_ERR_CNT_CONVERT_IN_WAIT | FEMB_2_STR_2_ERR_CNT_CONVERT_IN_WAIT | FEMB_2_STR_3_ERR_CNT_CONVERT_IN_WAIT | FEMB_2_STR_4_ERR_CNT_CONVERT_IN_WAIT |
                FEMB_3_STR_1_ERR_CNT_CONVERT_IN_WAIT | FEMB_3_STR_2_ERR_CNT_CONVERT_IN_WAIT | FEMB_3_STR_3_ERR_CNT_CONVERT_IN_WAIT | FEMB_3_STR_4_ERR_CNT_CONVERT_IN_WAIT |
                FEMB_4_STR_1_ERR_CNT_CONVERT_IN_WAIT | FEMB_4_STR_2_ERR_CNT_CONVERT_IN_WAIT | FEMB_4_STR_3_ERR_CNT_CONVERT_IN_WAIT | FEMB_4_STR_4_ERR_CNT_CONVERT_IN_WAIT =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_CONVERT_IN_WAIT_WINDOW);

              when FEMB_1_STR_1_ERR_CNT_BAD_SOF | FEMB_1_STR_2_ERR_CNT_BAD_SOF | FEMB_1_STR_3_ERR_CNT_BAD_SOF | FEMB_1_STR_4_ERR_CNT_BAD_SOF |
                FEMB_2_STR_1_ERR_CNT_BAD_SOF | FEMB_2_STR_2_ERR_CNT_BAD_SOF | FEMB_2_STR_3_ERR_CNT_BAD_SOF | FEMB_2_STR_4_ERR_CNT_BAD_SOF |
                FEMB_3_STR_1_ERR_CNT_BAD_SOF | FEMB_3_STR_2_ERR_CNT_BAD_SOF | FEMB_3_STR_3_ERR_CNT_BAD_SOF | FEMB_3_STR_4_ERR_CNT_BAD_SOF |
                FEMB_4_STR_1_ERR_CNT_BAD_SOF | FEMB_4_STR_2_ERR_CNT_BAD_SOF | FEMB_4_STR_3_ERR_CNT_BAD_SOF | FEMB_4_STR_4_ERR_CNT_BAD_SOF =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_BAD_SOF);

              when FEMB_1_STR_1_ERR_CNT_UNEXPECTED_EOF | FEMB_1_STR_2_ERR_CNT_UNEXPECTED_EOF | FEMB_1_STR_3_ERR_CNT_UNEXPECTED_EOF | FEMB_1_STR_4_ERR_CNT_UNEXPECTED_EOF |
                FEMB_2_STR_1_ERR_CNT_UNEXPECTED_EOF | FEMB_2_STR_2_ERR_CNT_UNEXPECTED_EOF | FEMB_2_STR_3_ERR_CNT_UNEXPECTED_EOF | FEMB_2_STR_4_ERR_CNT_UNEXPECTED_EOF |
                FEMB_3_STR_1_ERR_CNT_UNEXPECTED_EOF | FEMB_3_STR_2_ERR_CNT_UNEXPECTED_EOF | FEMB_3_STR_3_ERR_CNT_UNEXPECTED_EOF | FEMB_3_STR_4_ERR_CNT_UNEXPECTED_EOF |
                FEMB_4_STR_1_ERR_CNT_UNEXPECTED_EOF | FEMB_4_STR_2_ERR_CNT_UNEXPECTED_EOF | FEMB_4_STR_3_ERR_CNT_UNEXPECTED_EOF | FEMB_4_STR_4_ERR_CNT_UNEXPECTED_EOF =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_UNEXPECTED_EOF);
                
              when FEMB_1_STR_1_ERR_CNT_MISSING_EOF | FEMB_1_STR_2_ERR_CNT_MISSING_EOF | FEMB_1_STR_3_ERR_CNT_MISSING_EOF | FEMB_1_STR_4_ERR_CNT_MISSING_EOF |
                FEMB_2_STR_1_ERR_CNT_MISSING_EOF | FEMB_2_STR_2_ERR_CNT_MISSING_EOF | FEMB_2_STR_3_ERR_CNT_MISSING_EOF | FEMB_2_STR_4_ERR_CNT_MISSING_EOF |
                FEMB_3_STR_1_ERR_CNT_MISSING_EOF | FEMB_3_STR_2_ERR_CNT_MISSING_EOF | FEMB_3_STR_3_ERR_CNT_MISSING_EOF | FEMB_3_STR_4_ERR_CNT_MISSING_EOF |
                FEMB_4_STR_1_ERR_CNT_MISSING_EOF | FEMB_4_STR_2_ERR_CNT_MISSING_EOF | FEMB_4_STR_3_ERR_CNT_MISSING_EOF | FEMB_4_STR_4_ERR_CNT_MISSING_EOF =>   
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_MISSING_EOF);
                
              when FEMB_1_STR_1_ERR_CNT_KCHAR_IN_DATA | FEMB_1_STR_2_ERR_CNT_KCHAR_IN_DATA | FEMB_1_STR_3_ERR_CNT_KCHAR_IN_DATA | FEMB_1_STR_4_ERR_CNT_KCHAR_IN_DATA |
                FEMB_2_STR_1_ERR_CNT_KCHAR_IN_DATA | FEMB_2_STR_2_ERR_CNT_KCHAR_IN_DATA | FEMB_2_STR_3_ERR_CNT_KCHAR_IN_DATA | FEMB_2_STR_4_ERR_CNT_KCHAR_IN_DATA |
                FEMB_3_STR_1_ERR_CNT_KCHAR_IN_DATA | FEMB_3_STR_2_ERR_CNT_KCHAR_IN_DATA | FEMB_3_STR_3_ERR_CNT_KCHAR_IN_DATA | FEMB_3_STR_4_ERR_CNT_KCHAR_IN_DATA |
                FEMB_4_STR_1_ERR_CNT_KCHAR_IN_DATA | FEMB_4_STR_2_ERR_CNT_KCHAR_IN_DATA | FEMB_4_STR_3_ERR_CNT_KCHAR_IN_DATA | FEMB_4_STR_4_ERR_CNT_KCHAR_IN_DATA =>
                read_data_delayed(1)(31 downto 0) <= std_logic_vector(FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_KCHAR_IN_DATA);

              when FEMB_1_STR_1_ERR_CNT_RX_ERROR | FEMB_1_STR_2_ERR_CNT_RX_ERROR | FEMB_1_STR_3_ERR_CNT_RX_ERROR | FEMB_1_STR_4_ERR_CNT_RX_ERROR |
                FEMB_2_STR_1_ERR_CNT_RX_ERROR | FEMB_2_STR_2_ERR_CNT_RX_ERROR | FEMB_2_STR_3_ERR_CNT_RX_ERROR | FEMB_2_STR_4_ERR_CNT_RX_ERROR |
                FEMB_3_STR_1_ERR_CNT_RX_ERROR | FEMB_3_STR_2_ERR_CNT_RX_ERROR | FEMB_3_STR_3_ERR_CNT_RX_ERROR | FEMB_3_STR_4_ERR_CNT_RX_ERROR |
                FEMB_4_STR_1_ERR_CNT_RX_ERROR | FEMB_4_STR_2_ERR_CNT_RX_ERROR | FEMB_4_STR_3_ERR_CNT_RX_ERROR | FEMB_4_STR_4_ERR_CNT_RX_ERROR =>
                read_data_delayed(1)(31 downto 0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.counter_rx_error(FEMB_read_stream_index) ;

              when FEMB_1_STR_1_ERR_CNT_RX_DISP_ERROR | FEMB_1_STR_2_ERR_CNT_RX_DISP_ERROR | FEMB_1_STR_3_ERR_CNT_RX_DISP_ERROR | FEMB_1_STR_4_ERR_CNT_RX_DISP_ERROR |
                FEMB_2_STR_1_ERR_CNT_RX_DISP_ERROR | FEMB_2_STR_2_ERR_CNT_RX_DISP_ERROR | FEMB_2_STR_3_ERR_CNT_RX_DISP_ERROR | FEMB_2_STR_4_ERR_CNT_RX_DISP_ERROR |
                FEMB_3_STR_1_ERR_CNT_RX_DISP_ERROR | FEMB_3_STR_2_ERR_CNT_RX_DISP_ERROR | FEMB_3_STR_3_ERR_CNT_RX_DISP_ERROR | FEMB_3_STR_4_ERR_CNT_RX_DISP_ERROR |
                FEMB_4_STR_1_ERR_CNT_RX_DISP_ERROR | FEMB_4_STR_2_ERR_CNT_RX_DISP_ERROR | FEMB_4_STR_3_ERR_CNT_RX_DISP_ERROR | FEMB_4_STR_4_ERR_CNT_RX_DISP_ERROR =>
                read_data_delayed(1)(31 downto 0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).Rx.counter_rx_disp_error(FEMB_read_stream_index);

              when FEMB_1_STR_1_ERR_CNT_T_INCR | FEMB_1_STR_2_ERR_CNT_T_INCR | FEMB_1_STR_3_ERR_CNT_T_INCR | FEMB_1_STR_4_ERR_CNT_T_INCR |
                FEMB_2_STR_1_ERR_CNT_T_INCR | FEMB_2_STR_2_ERR_CNT_T_INCR | FEMB_2_STR_3_ERR_CNT_T_INCR | FEMB_2_STR_4_ERR_CNT_T_INCR |
                FEMB_3_STR_1_ERR_CNT_T_INCR | FEMB_3_STR_2_ERR_CNT_T_INCR | FEMB_3_STR_3_ERR_CNT_T_INCR | FEMB_3_STR_4_ERR_CNT_T_INCR |
                FEMB_4_STR_1_ERR_CNT_T_INCR | FEMB_4_STR_2_ERR_CNT_T_INCR | FEMB_4_STR_3_ERR_CNT_T_INCR | FEMB_4_STR_4_ERR_CNT_T_INCR =>
                read_data_delayed(1)(31 downto 0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_timestamp_incr;

              when FEMB_1_STR_1_ERR_CNT_BAD_WRITE | FEMB_1_STR_2_ERR_CNT_BAD_WRITE | FEMB_1_STR_3_ERR_CNT_BAD_WRITE | FEMB_1_STR_4_ERR_CNT_BAD_WRITE |
                FEMB_2_STR_1_ERR_CNT_BAD_WRITE | FEMB_2_STR_2_ERR_CNT_BAD_WRITE | FEMB_2_STR_3_ERR_CNT_BAD_WRITE | FEMB_2_STR_4_ERR_CNT_BAD_WRITE |
                FEMB_3_STR_1_ERR_CNT_BAD_WRITE | FEMB_3_STR_2_ERR_CNT_BAD_WRITE | FEMB_3_STR_3_ERR_CNT_BAD_WRITE | FEMB_3_STR_4_ERR_CNT_BAD_WRITE |
                FEMB_4_STR_1_ERR_CNT_BAD_WRITE | FEMB_4_STR_2_ERR_CNT_BAD_WRITE | FEMB_4_STR_3_ERR_CNT_BAD_WRITE | FEMB_4_STR_4_ERR_CNT_BAD_WRITE =>
                read_data_delayed(1)(31 downto 0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_BAD_WRITE;

              when FEMB_1_STR_1_ERR_CNT_BAD_RO_START | FEMB_1_STR_2_ERR_CNT_BAD_RO_START | FEMB_1_STR_3_ERR_CNT_BAD_RO_START | FEMB_1_STR_4_ERR_CNT_BAD_RO_START |
                FEMB_2_STR_1_ERR_CNT_BAD_RO_START | FEMB_2_STR_2_ERR_CNT_BAD_RO_START | FEMB_2_STR_3_ERR_CNT_BAD_RO_START | FEMB_2_STR_4_ERR_CNT_BAD_RO_START |
                FEMB_3_STR_1_ERR_CNT_BAD_RO_START | FEMB_3_STR_2_ERR_CNT_BAD_RO_START | FEMB_3_STR_3_ERR_CNT_BAD_RO_START | FEMB_3_STR_4_ERR_CNT_BAD_RO_START |
                FEMB_4_STR_1_ERR_CNT_BAD_RO_START | FEMB_4_STR_2_ERR_CNT_BAD_RO_START | FEMB_4_STR_3_ERR_CNT_BAD_RO_START | FEMB_4_STR_4_ERR_CNT_BAD_RO_START =>
                read_data_delayed(1)(31 downto 0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).counter_BAD_RO_START;

              when FEMB_1_STR_1_ERR_RATE_T_INCR | FEMB_1_STR_2_ERR_RATE_T_INCR | FEMB_1_STR_3_ERR_RATE_T_INCR | FEMB_1_STR_4_ERR_RATE_T_INCR |
                FEMB_2_STR_1_ERR_RATE_T_INCR | FEMB_2_STR_2_ERR_RATE_T_INCR | FEMB_2_STR_3_ERR_RATE_T_INCR | FEMB_2_STR_4_ERR_RATE_T_INCR |
                FEMB_3_STR_1_ERR_RATE_T_INCR | FEMB_3_STR_2_ERR_RATE_T_INCR | FEMB_3_STR_3_ERR_RATE_T_INCR | FEMB_3_STR_4_ERR_RATE_T_INCR |
                FEMB_4_STR_1_ERR_RATE_T_INCR | FEMB_4_STR_2_ERR_RATE_T_INCR | FEMB_4_STR_3_ERR_RATE_T_INCR | FEMB_4_STR_4_ERR_RATE_T_INCR =>
                read_data_delayed(1)(31 downto 0) <= FEMB_DAQ_Monitor.FEMB(FEMB_read_index).CD_Stream(FEMB_read_stream_index).timer_incr_error;

                
              when REG_TEST_1 =>
                read_data_delayed(1)(31 downto 0) <= test_reg(1);
                
              when others =>
                --mark data as not found
                read_data_delayed(1) <= x"000000000";
            end case;
          when READ_STATE_WRITE =>
            read_data(1) <= read_data_delayed(1);
            read_data_wr(1) <= '1';
            READ_state(1)   <= READ_STATE_IDLE;
          when others =>
            READ_state(1) <= READ_STATE_IDLE;
        end case;

        -------------------------------------------------------
        -- Write
        -------------------------------------------------------
        write_addr_data_ack(1) <= '0';

        FEMB_DAQ_Control.FEMB(1).Fake_CD(1).inject_errors <= '0';
        FEMB_DAQ_Control.FEMB(1).Fake_CD(2).inject_errors <= '0';

        for iFEMB in FEMB_COUNT downto 1 loop
          for iStream in LINKS_PER_FEMB downto 1 loop
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_BUFFER_FULL            <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_CONVERT_IN_WAIT_WINDOW <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_BAD_SOF                <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_UNEXPECTED_EOF         <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_MISSING_EOF            <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_KCHAR_IN_DATA          <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_packets                <= '0';          
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_BAD_CHSUM              <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_timestamp_incr         <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_BAD_WRITE              <= '0';                      
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_counter_BAD_RO_START           <= '0';

            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_timer_frames                   <= '0';
            FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iStream).reset_timer_incr_error               <= '0';

            FEMB_DAQ_Control.FEMB(iFEMB).Rx.reset_link_side(iStream) <= '0';
            
          end loop;  -- iStream
        end loop;  -- iFEMB
        
        FEMB_DAQ_Control.spy.arm       <= '0';
        FEMB_DAQ_Control.spy.sw_trig   <= '0';

        
        case WRITE_state(1) is
          when WRITE_STATE_IDLE =>
            -- Write/action switch
            if write_addr_data_valid(1) = '1' then
              WRITE_STATE(1) <= WRITE_STATE_CAPTURE_ADDRESS;
            end if;
          when WRITE_STATE_CAPTURE_ADDRESS =>
            -- buffer address
            write_addr_cap(1)      <= unsigned(write_addr(1));
            write_data_cap(1)      <= write_data(1);
            WRITE_STATE(1)         <= WRITE_STATE_ADDRESS_HELPERS;
            write_addr_data_ack(1) <= '1';
          when WRITE_STATE_ADDRESS_HELPERS =>
            WRITE_STATE(1)         <= WRITE_STATE_WRITE;
            FEMB_write_index        <= to_integer(unsigned(write_addr_cap(1)(14 downto 12)));
            FEMB_write_stream_index <= to_integer(unsigned(write_addr_cap(1)(10 downto 8)));

          when WRITE_STATE_WRITE =>
            -- process write and ack
            WRITE_STATE(1) <= WRITE_STATE_IDLE;
            case write_addr_cap(1) is
              when WIB_STATUS =>
                if write_data_cap(1)(13) = '1' then                 
                  for iFEMB in FEMB_COUNT downto 1 loop
                    for iCDALink in LINKS_PER_FEMB downto 1 loop
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_BUFFER_FULL            <= '1';                      
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_CONVERT_IN_WAIT_WINDOW <= '1';
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_BAD_SOF                <= '1';
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_UNEXPECTED_EOF         <= '1';
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_MISSING_EOF            <= '1';
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_KCHAR_IN_DATA          <= '1';
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_packets                <= '1';          
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_BAD_CHSUM              <= '1';
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_timestamp_incr         <= '1';                      
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_BAD_WRITE              <= '1';                      
                      FEMB_DAQ_Control.FEMB(iFEMB).CD_Stream(iCDALink).reset_counter_BAD_RO_START           <= '1';
                    end loop;  -- iCDALink
                  end loop;  -- iFEMB
                end if;              
              when DQM_CTRL =>
                DQM_Control.enable_DQM <= write_data_cap(1)(0);
                DQM_Control.DQM_type   <= write_data_cap(1)(7 downto 4);
              when DQM_CD_SS =>
                DQM_Control.CD_SS.stream_number <= write_data_cap(1)(0);
                DQM_Control.CD_SS.CD_number     <= write_data_cap(1)(1);
                DQM_Control.CD_SS.FEMB_number   <= write_data_cap(1)(3 downto 2);
                DQM_Control.CD_SS.sub_stream_number <= write_data_cap(1)(4);

              when FEMB_SPY_CONTROL =>
                FEMB_DAQ_Control.spy.stream_id <= to_integer(unsigned(write_data_cap(1)( 3 downto  0)));
                FEMB_DAQ_Control.spy.ext_en    <= write_data_cap(1)(4);
                FEMB_DAQ_Control.spy.word_en   <= write_data_cap(1)(5);
                FEMB_DAQ_Control.spy.word_trig <= write_data_cap(1)(20 downto 12);

              when FEMB_SPY_ARM =>
                FEMB_DAQ_Control.spy.arm       <= write_data_cap(1)(0);
                FEMB_DAQ_Control.spy.sw_trig   <= write_data_cap(1)(1);                

              when FEMB_DUPLICATE =>
                FEMB_DAQ_Control.copyFEMB1and2to3and4 <= write_data_cap(1)(0);

              when FEMB_1_CONTROL | FEMB_2_CONTROL | FEMB_3_CONTROL | FEMB_4_CONTROL =>
                FEMB_DAQ_Control.reset        <= write_data_cap(1)(0);
                FEMB_DAQ_Control.reconf_reset <= write_data_cap(1)(1);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(1).enable <= write_data_cap(1)(4);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(2).enable <= write_data_cap(1)(5);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(3).enable <= write_data_cap(1)(6);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(4).enable <= write_data_cap(1)(7);
                
              when FEMB_1_TRIGGER | FEMB_2_TRIGGER | FEMB_3_TRIGGER | FEMB_4_TRIGGER =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(1).convert_delay <= to_integer(unsigned(write_data_cap(1)(7 downto 0)));
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(2).convert_delay <= to_integer(unsigned(write_data_cap(1)(15 downto 8)));
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(3).convert_delay <= to_integer(unsigned(write_data_cap(1)(23 downto 16)));
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(4).convert_delay <= to_integer(unsigned(write_data_cap(1)(31 downto 24)));
              when FEMB_1_FAKE_CD | FEMB_2_FAKE_CD | FEMB_3_FAKE_CD | FEMB_4_FAKE_CD =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).fake_data_type(0)   <= write_data_cap(1)(0);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).fake_data_type(0)   <= write_data_cap(1)(1);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).fake_data_type(1)   <= write_data_cap(1)(2);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).fake_data_type(1)   <= write_data_cap(1)(3);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).fake_loopback_en            <= write_data_cap(1)(7 downto 4);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).fake_stream_type <= write_data_cap(1)(9 downto 8);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).fake_stream_type <= write_data_cap(1)(11 downto 10);

              when FEMB_1_FAKE_CD_RESERVED_WORD | FEMB_2_FAKE_CD_RESERVED_WORD | FEMB_3_FAKE_CD_RESERVED_WORD | FEMB_4_FAKE_CD_RESERVED_WORD =>
                FEMB_DAQ_Control.FEMB(FEMB_read_index).Fake_CD(1).set_reserved <= write_data_cap(1)(15 downto  0);
                FEMB_DAQ_Control.FEMB(FEMB_read_index).Fake_CD(2).set_reserved <= write_data_cap(1)(31 downto 16);

              when FEMB_1_FAKE_CD_1_HEADER_WORD | FEMB_2_FAKE_CD_1_HEADER_WORD | FEMB_3_FAKE_CD_1_HEADER_WORD | FEMB_4_FAKE_CD_1_HEADER_WORD =>
                FEMB_DAQ_Control.FEMB(FEMB_read_index).Fake_CD(1).set_header <= write_data_cap(1)(31 downto  0);

              when FEMB_1_FAKE_CD_2_HEADER_WORD | FEMB_2_FAKE_CD_2_HEADER_WORD | FEMB_3_FAKE_CD_2_HEADER_WORD | FEMB_4_FAKE_CD_2_HEADER_WORD =>
                FEMB_DAQ_Control.FEMB(FEMB_read_index).Fake_CD(2).set_header <= write_data_cap(1)(31 downto  0);

              when FEMB_1_FAKE_CD_ERR_INJ | FEMB_2_FAKE_CD_ERR_INJ | FEMB_3_FAKE_CD_ERR_INJ | FEMB_4_FAKE_CD_ERR_INJ =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_errors <= '1';
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_errors <= '1';
              when FEMB_1_FAKE_CD_1_ERR_INJ | FEMB_2_FAKE_CD_1_ERR_INJ | FEMB_3_FAKE_CD_1_ERR_INJ | FEMB_4_FAKE_CD_1_ERR_INJ =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_BAD_CHECKSUM(0)        <= write_data_cap(1)(0);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_BAD_SOF(0)             <= write_data_cap(1)(1);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_LARGE_FRAME(0)         <= write_data_cap(1)(2);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_SHORT_FRAME(0)         <= write_data_cap(1)(3);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_K_CHAR(0)              <= write_data_cap(1)(4);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_CD_errors(7 downto 0)  <= write_data_cap(1)(15 downto 8);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_BAD_CHECKSUM(1)        <= write_data_cap(1)(16);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_BAD_SOF(1)             <= write_data_cap(1)(17);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_LARGE_FRAME(1)         <= write_data_cap(1)(18);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_SHORT_FRAME(1)         <= write_data_cap(1)(19);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_K_CHAR(1)              <= write_data_cap(1)(20);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(1).inject_CD_errors(15 downto 8) <= write_data_cap(1)(31 downto 24);
              when FEMB_1_FAKE_CD_2_ERR_INJ | FEMB_2_FAKE_CD_2_ERR_INJ | FEMB_3_FAKE_CD_2_ERR_INJ | FEMB_4_FAKE_CD_2_ERR_INJ =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_BAD_CHECKSUM(0)        <= write_data_cap(1)(0);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_BAD_SOF(0)             <= write_data_cap(1)(1);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_LARGE_FRAME(0)         <= write_data_cap(1)(2);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_SHORT_FRAME(0)         <= write_data_cap(1)(3);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_K_CHAR(0)              <= write_data_cap(1)(4);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_CD_errors(7 downto 0)  <= write_data_cap(1)(15 downto 8);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_BAD_CHECKSUM(1)        <= write_data_cap(1)(16);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_BAD_SOF(1)             <= write_data_cap(1)(17);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_LARGE_FRAME(1)         <= write_data_cap(1)(18);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_SHORT_FRAME(1)         <= write_data_cap(1)(19);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_K_CHAR(1)              <= write_data_cap(1)(20);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Fake_CD(2).inject_CD_errors(15 downto 8) <= write_data_cap(1)(31 downto 24);


              when FEMB_1_STR_1_STATUS | FEMB_1_STR_2_STATUS | FEMB_1_STR_3_STATUS | FEMB_1_STR_4_STATUS |
                FEMB_2_STR_1_STATUS | FEMB_2_STR_2_STATUS | FEMB_2_STR_3_STATUS | FEMB_2_STR_4_STATUS |
                FEMB_3_STR_1_STATUS | FEMB_3_STR_2_STATUS | FEMB_3_STR_3_STATUS | FEMB_3_STR_4_STATUS |
                FEMB_4_STR_1_STATUS | FEMB_4_STR_2_STATUS | FEMB_4_STR_3_STATUS | FEMB_4_STR_4_STATUS =>

                FEMB_DAQ_Control.FEMB(FEMB_write_index).Rx.reset_counter_rx_error(FEMB_write_stream_index)      <= write_data_cap(1)(22);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Rx.reset_counter_rx_disp_error(FEMB_write_stream_index) <= write_data_cap(1)(23);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).Rx.reset_link_side <= write_data_cap(1)(31 downto 28);
                
                
              when FEMB_1_STR_1_PACKET_COUNT | FEMB_1_STR_2_PACKET_COUNT | FEMB_1_STR_3_PACKET_COUNT | FEMB_1_STR_4_PACKET_COUNT |
                FEMB_2_STR_1_PACKET_COUNT | FEMB_2_STR_2_PACKET_COUNT | FEMB_2_STR_3_PACKET_COUNT | FEMB_2_STR_4_PACKET_COUNT |
                FEMB_3_STR_1_PACKET_COUNT | FEMB_3_STR_2_PACKET_COUNT | FEMB_3_STR_3_PACKET_COUNT | FEMB_3_STR_4_PACKET_COUNT |
                FEMB_4_STR_1_PACKET_COUNT | FEMB_4_STR_2_PACKET_COUNT | FEMB_4_STR_3_PACKET_COUNT | FEMB_4_STR_4_PACKET_COUNT =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_packets <= '1';

              when FEMB_1_STR_1_PACKET_RATE | FEMB_1_STR_2_PACKET_RATE | FEMB_1_STR_3_PACKET_RATE | FEMB_1_STR_4_PACKET_RATE |
                FEMB_2_STR_1_PACKET_RATE | FEMB_2_STR_2_PACKET_RATE | FEMB_2_STR_3_PACKET_RATE | FEMB_2_STR_4_PACKET_RATE |
                FEMB_3_STR_1_PACKET_RATE | FEMB_3_STR_2_PACKET_RATE | FEMB_3_STR_3_PACKET_RATE | FEMB_3_STR_4_PACKET_RATE |
                FEMB_4_STR_1_PACKET_RATE | FEMB_4_STR_2_PACKET_RATE | FEMB_4_STR_3_PACKET_RATE | FEMB_4_STR_4_PACKET_RATE =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_timer_frames <= '1';


              when FEMB_1_STR_1_ERR_CNT_RESETS | FEMB_1_STR_2_ERR_CNT_RESETS | FEMB_1_STR_3_ERR_CNT_RESETS | FEMB_1_STR_4_ERR_CNT_RESETS |
                FEMB_2_STR_1_ERR_CNT_RESETS | FEMB_2_STR_2_ERR_CNT_RESETS | FEMB_2_STR_3_ERR_CNT_RESETS | FEMB_2_STR_4_ERR_CNT_RESETS |
                FEMB_3_STR_1_ERR_CNT_RESETS | FEMB_3_STR_2_ERR_CNT_RESETS | FEMB_3_STR_3_ERR_CNT_RESETS | FEMB_3_STR_4_ERR_CNT_RESETS |
                FEMB_4_STR_1_ERR_CNT_RESETS | FEMB_4_STR_2_ERR_CNT_RESETS | FEMB_4_STR_3_ERR_CNT_RESETS | FEMB_4_STR_4_ERR_CNT_RESETS  =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_CONVERT_IN_WAIT_WINDOW <= write_data_cap(1)(0) or write_data_cap(1)(1);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_BAD_SOF                <= write_data_cap(1)(0) or write_data_cap(1)(2);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_UNEXPECTED_EOF         <= write_data_cap(1)(0) or write_data_cap(1)(3);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_MISSING_EOF            <= write_data_cap(1)(0) or write_data_cap(1)(4);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_KCHAR_IN_DATA          <= write_data_cap(1)(0) or write_data_cap(1)(5);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_BAD_CHSUM              <= write_data_cap(1)(0) or write_data_cap(1)(6);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_BUFFER_FULL            <= write_data_cap(1)(0) or write_data_cap(1)(7);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_timestamp_incr         <= write_data_cap(1)(0) or write_data_cap(1)(8);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_BAD_WRITE              <= write_data_cap(1)(0) or write_data_cap(1)(9);
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_BAD_RO_START           <= write_data_cap(1)(0) or write_data_cap(1)(10);

              when FEMB_1_STR_1_ERR_CNT_BUFFER_FULL | FEMB_1_STR_2_ERR_CNT_BUFFER_FULL | FEMB_1_STR_3_ERR_CNT_BUFFER_FULL | FEMB_1_STR_4_ERR_CNT_BUFFER_FULL |
                FEMB_2_STR_1_ERR_CNT_BUFFER_FULL | FEMB_2_STR_2_ERR_CNT_BUFFER_FULL | FEMB_2_STR_3_ERR_CNT_BUFFER_FULL | FEMB_2_STR_4_ERR_CNT_BUFFER_FULL |
                FEMB_3_STR_1_ERR_CNT_BUFFER_FULL | FEMB_3_STR_2_ERR_CNT_BUFFER_FULL | FEMB_3_STR_3_ERR_CNT_BUFFER_FULL | FEMB_3_STR_4_ERR_CNT_BUFFER_FULL |
                FEMB_4_STR_1_ERR_CNT_BUFFER_FULL | FEMB_4_STR_2_ERR_CNT_BUFFER_FULL | FEMB_4_STR_3_ERR_CNT_BUFFER_FULL | FEMB_4_STR_4_ERR_CNT_BUFFER_FULL =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_BUFFER_FULL <= '1';

              when FEMB_1_STR_1_ERR_CNT_CONVERT_IN_WAIT | FEMB_1_STR_2_ERR_CNT_CONVERT_IN_WAIT | FEMB_1_STR_3_ERR_CNT_CONVERT_IN_WAIT | FEMB_1_STR_4_ERR_CNT_CONVERT_IN_WAIT |
                FEMB_2_STR_1_ERR_CNT_CONVERT_IN_WAIT | FEMB_2_STR_2_ERR_CNT_CONVERT_IN_WAIT | FEMB_2_STR_3_ERR_CNT_CONVERT_IN_WAIT | FEMB_2_STR_4_ERR_CNT_CONVERT_IN_WAIT |
                FEMB_3_STR_1_ERR_CNT_CONVERT_IN_WAIT | FEMB_3_STR_2_ERR_CNT_CONVERT_IN_WAIT | FEMB_3_STR_3_ERR_CNT_CONVERT_IN_WAIT | FEMB_3_STR_4_ERR_CNT_CONVERT_IN_WAIT |
                FEMB_4_STR_1_ERR_CNT_CONVERT_IN_WAIT | FEMB_4_STR_2_ERR_CNT_CONVERT_IN_WAIT | FEMB_4_STR_3_ERR_CNT_CONVERT_IN_WAIT | FEMB_4_STR_4_ERR_CNT_CONVERT_IN_WAIT =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_CONVERT_IN_WAIT_WINDOW <= '1';


              when FEMB_1_STR_1_ERR_CNT_BAD_SOF | FEMB_1_STR_2_ERR_CNT_BAD_SOF | FEMB_1_STR_3_ERR_CNT_BAD_SOF | FEMB_1_STR_4_ERR_CNT_BAD_SOF |
                FEMB_2_STR_1_ERR_CNT_BAD_SOF | FEMB_2_STR_2_ERR_CNT_BAD_SOF | FEMB_2_STR_3_ERR_CNT_BAD_SOF | FEMB_2_STR_4_ERR_CNT_BAD_SOF |
                FEMB_3_STR_1_ERR_CNT_BAD_SOF | FEMB_3_STR_2_ERR_CNT_BAD_SOF | FEMB_3_STR_3_ERR_CNT_BAD_SOF | FEMB_3_STR_4_ERR_CNT_BAD_SOF |
                FEMB_4_STR_1_ERR_CNT_BAD_SOF | FEMB_4_STR_2_ERR_CNT_BAD_SOF | FEMB_4_STR_3_ERR_CNT_BAD_SOF | FEMB_4_STR_4_ERR_CNT_BAD_SOF =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_BAD_SOF <= '1';
                

              when FEMB_1_STR_1_ERR_CNT_UNEXPECTED_EOF | FEMB_1_STR_2_ERR_CNT_UNEXPECTED_EOF | FEMB_1_STR_3_ERR_CNT_UNEXPECTED_EOF | FEMB_1_STR_4_ERR_CNT_UNEXPECTED_EOF |
                FEMB_2_STR_1_ERR_CNT_UNEXPECTED_EOF | FEMB_2_STR_2_ERR_CNT_UNEXPECTED_EOF | FEMB_2_STR_3_ERR_CNT_UNEXPECTED_EOF | FEMB_2_STR_4_ERR_CNT_UNEXPECTED_EOF |
                FEMB_3_STR_1_ERR_CNT_UNEXPECTED_EOF | FEMB_3_STR_2_ERR_CNT_UNEXPECTED_EOF | FEMB_3_STR_3_ERR_CNT_UNEXPECTED_EOF | FEMB_3_STR_4_ERR_CNT_UNEXPECTED_EOF |
                FEMB_4_STR_1_ERR_CNT_UNEXPECTED_EOF | FEMB_4_STR_2_ERR_CNT_UNEXPECTED_EOF | FEMB_4_STR_3_ERR_CNT_UNEXPECTED_EOF | FEMB_4_STR_4_ERR_CNT_UNEXPECTED_EOF =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_UNEXPECTED_EOF <= '1';
                
              when FEMB_1_STR_1_ERR_CNT_MISSING_EOF | FEMB_1_STR_2_ERR_CNT_MISSING_EOF | FEMB_1_STR_3_ERR_CNT_MISSING_EOF | FEMB_1_STR_4_ERR_CNT_MISSING_EOF |
                FEMB_2_STR_1_ERR_CNT_MISSING_EOF | FEMB_2_STR_2_ERR_CNT_MISSING_EOF | FEMB_2_STR_3_ERR_CNT_MISSING_EOF | FEMB_2_STR_4_ERR_CNT_MISSING_EOF |
                FEMB_3_STR_1_ERR_CNT_MISSING_EOF | FEMB_3_STR_2_ERR_CNT_MISSING_EOF | FEMB_3_STR_3_ERR_CNT_MISSING_EOF | FEMB_3_STR_4_ERR_CNT_MISSING_EOF |
                FEMB_4_STR_1_ERR_CNT_MISSING_EOF | FEMB_4_STR_2_ERR_CNT_MISSING_EOF | FEMB_4_STR_3_ERR_CNT_MISSING_EOF | FEMB_4_STR_4_ERR_CNT_MISSING_EOF =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_MISSING_EOF <= '1';

              when FEMB_1_STR_1_ERR_CNT_BAD_CHSUM | FEMB_1_STR_2_ERR_CNT_BAD_CHSUM | FEMB_1_STR_3_ERR_CNT_BAD_CHSUM | FEMB_1_STR_4_ERR_CNT_BAD_CHSUM |
                FEMB_2_STR_1_ERR_CNT_BAD_CHSUM | FEMB_2_STR_2_ERR_CNT_BAD_CHSUM | FEMB_2_STR_3_ERR_CNT_BAD_CHSUM | FEMB_2_STR_4_ERR_CNT_BAD_CHSUM |
                FEMB_3_STR_1_ERR_CNT_BAD_CHSUM | FEMB_3_STR_2_ERR_CNT_BAD_CHSUM | FEMB_3_STR_3_ERR_CNT_BAD_CHSUM | FEMB_3_STR_4_ERR_CNT_BAD_CHSUM |
                FEMB_4_STR_1_ERR_CNT_BAD_CHSUM | FEMB_4_STR_2_ERR_CNT_BAD_CHSUM | FEMB_4_STR_3_ERR_CNT_BAD_CHSUM | FEMB_4_STR_4_ERR_CNT_BAD_CHSUM =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_BAD_CHSUM <= '1';

              when FEMB_1_STR_1_ERR_CNT_KCHAR_IN_DATA | FEMB_1_STR_2_ERR_CNT_KCHAR_IN_DATA | FEMB_1_STR_3_ERR_CNT_KCHAR_IN_DATA | FEMB_1_STR_4_ERR_CNT_KCHAR_IN_DATA |
                FEMB_2_STR_1_ERR_CNT_KCHAR_IN_DATA | FEMB_2_STR_2_ERR_CNT_KCHAR_IN_DATA | FEMB_2_STR_3_ERR_CNT_KCHAR_IN_DATA | FEMB_2_STR_4_ERR_CNT_KCHAR_IN_DATA |
                FEMB_3_STR_1_ERR_CNT_KCHAR_IN_DATA | FEMB_3_STR_2_ERR_CNT_KCHAR_IN_DATA | FEMB_3_STR_3_ERR_CNT_KCHAR_IN_DATA | FEMB_3_STR_4_ERR_CNT_KCHAR_IN_DATA |
                FEMB_4_STR_1_ERR_CNT_KCHAR_IN_DATA | FEMB_4_STR_2_ERR_CNT_KCHAR_IN_DATA | FEMB_4_STR_3_ERR_CNT_KCHAR_IN_DATA | FEMB_4_STR_4_ERR_CNT_KCHAR_IN_DATA =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_KCHAR_IN_DATA <= '1';

              when FEMB_1_STR_1_ERR_CNT_T_INCR | FEMB_1_STR_2_ERR_CNT_T_INCR | FEMB_1_STR_3_ERR_CNT_T_INCR | FEMB_1_STR_4_ERR_CNT_T_INCR |
                FEMB_2_STR_1_ERR_CNT_T_INCR | FEMB_2_STR_2_ERR_CNT_T_INCR | FEMB_2_STR_3_ERR_CNT_T_INCR | FEMB_2_STR_4_ERR_CNT_T_INCR |
                FEMB_3_STR_1_ERR_CNT_T_INCR | FEMB_3_STR_2_ERR_CNT_T_INCR | FEMB_3_STR_3_ERR_CNT_T_INCR | FEMB_3_STR_4_ERR_CNT_T_INCR |
                FEMB_4_STR_1_ERR_CNT_T_INCR | FEMB_4_STR_2_ERR_CNT_T_INCR | FEMB_4_STR_3_ERR_CNT_T_INCR | FEMB_4_STR_4_ERR_CNT_T_INCR =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_counter_timestamp_incr <= '1';

              when FEMB_1_STR_1_ERR_RATE_T_INCR | FEMB_1_STR_2_ERR_RATE_T_INCR | FEMB_1_STR_3_ERR_RATE_T_INCR | FEMB_1_STR_4_ERR_RATE_T_INCR |
                FEMB_2_STR_1_ERR_RATE_T_INCR | FEMB_2_STR_2_ERR_RATE_T_INCR | FEMB_2_STR_3_ERR_RATE_T_INCR | FEMB_2_STR_4_ERR_RATE_T_INCR |
                FEMB_3_STR_1_ERR_RATE_T_INCR | FEMB_3_STR_2_ERR_RATE_T_INCR | FEMB_3_STR_3_ERR_RATE_T_INCR | FEMB_3_STR_4_ERR_RATE_T_INCR |
                FEMB_4_STR_1_ERR_RATE_T_INCR | FEMB_4_STR_2_ERR_RATE_T_INCR | FEMB_4_STR_3_ERR_RATE_T_INCR | FEMB_4_STR_4_ERR_RATE_T_INCR =>
                FEMB_DAQ_Control.FEMB(FEMB_write_index).CD_Stream(FEMB_write_stream_index).reset_timer_incr_error <= '1';

              when REG_TEST_1 =>
                test_reg(1) <= write_data_cap(1);

              when others => null;
            end case;
          when others =>
            WRITE_STATE(1) <= WRITE_STATE_IDLE;
        end case;
      end if;
    end if;
  end process REGS_128Mhz;


  -------------------------------------------------------------------------------------
  -- services clocks
  -------------------------------------------------------------------------------------
  REGS_40Mhz : process (clk_domain(4)) is
  begin  -- process REGS_50Mhz
    if clk_domain(4)'event and clk_domain(4) = '1' then  -- rising clock edge
      if reset_sync_domain(4) = '1' then  
        test_reg(4) <= (others => '0');
        localFlash_control <= DEFAULT_localFlash_control_t;
        WIB_control.TempSensor <= DEFAULT_TempSensor_control_t;
        WIB_PWR_control <= DEFAULT_WIB_PWR_Control;

        READ_state(4)  <= READ_STATE_IDLE;
        WRITE_state(4) <= WRITE_STATE_IDLE;

      else
        
        -------------------------------------------------------
        -- Read
        -------------------------------------------------------
        read_address_ack(4) <= '0';
        read_data_wr(4)     <= '0';

        case READ_state(4) is

          when READ_STATE_IDLE =>
            if read_address_valid(4) = '1' then
-----              read_address_ack(4) <= '1';
-----              READ_state(4)       <= READ_STATE_CAPTURE_ADDRESS;
              -- capture the address we will be using
              read_address_cap(4) <= unsigned(read_address(4));
              --Get index for FEMB monitoring
              power_monitor_FEMB_index <= to_integer(unsigned(read_address(4)(7 downto 4)));
              READ_state(4)       <= READ_STATE_READ;

            end if;
          when READ_STATE_CAPTURE_ADDRESS =>
-----            -- capture the address we will be using
-----            read_address_cap(4) <= unsigned(read_address(4));
-----            READ_state(4)       <= READ_STATE_ADDRESS_HELPERS;
          when READ_STATE_ADDRESS_HELPERS =>
-----            --Get index for FEMB monitoring
-----            power_monitor_FEMB_index <= to_integer(unsigned(read_address_cap(4)(7 downto 4)));
-----            READ_state(4)       <= READ_STATE_READ;
          when READ_STATE_READ =>
-----            READ_state(4) <= READ_STATE_WRITE;

            read_data(4) <= x"100000000";  --Mark the data as zeros and the
                                           --register found
                                           --
            case read_address_cap(4) is
              when LFLASH_CTRL =>
                read_data(4)(1)            <= localFlash_monitor.rw;
                read_data(4)(2)            <= localFlash_monitor.done;
                read_data(4)(3)            <= localFlash_monitor.error;
                read_data(4)(31 downto 16) <= localFlash_monitor.addr;
              when LFLASH_READ =>
                read_data(4)(31 downto 0)  <= localFlash_monitor.rd_data;
              when LFLASH_WRITE =>
                read_data(4)(31 downto 0)  <= localFlash_monitor.wr_data;
              when TS_CTRL =>
                read_data(4)(1)            <= WIB_Monitor.TempSensor.busy;
              when TS_DATA =>
                read_data(4)(31 downto 0)  <= WIB_Monitor.TempSensor.temp;
              when FEMB_POWER_MON_CONTROL =>
                read_data(4)(1)            <= WIB_PWR_monitor.reset;
              when FEMB_BIAS_MON =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.bias_Vcc;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.bias_temp;
              when FEMB_FE_MON =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.FE_Vcc;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.FE_temp;


              when FEMB_1_MON_0 | FEMB_2_MON_0 | FEMB_3_MON_0 | FEMB_4_MON_0 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).Vcc;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).temp;
              when FEMB_1_MON_1 | FEMB_2_MON_1 | FEMB_3_MON_1 | FEMB_4_MON_1 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).V_3V6;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).V_3V6;
              when FEMB_1_MON_2 | FEMB_2_MON_2 | FEMB_3_MON_2 | FEMB_4_MON_2 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).V_2V8;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).I_2V8;
              when FEMB_1_MON_3 | FEMB_2_MON_3 | FEMB_3_MON_3 | FEMB_4_MON_3 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).V_2V5;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).I_2V5;
              when FEMB_1_MON_4 | FEMB_2_MON_4 | FEMB_3_MON_4 | FEMB_4_MON_4 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).V_1V5;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).I_1V5;
              when FEMB_1_MON_5 | FEMB_2_MON_5 | FEMB_3_MON_5 | FEMB_4_MON_5 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).V_Bias;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).I_Bias;
              when FEMB_1_MON_6 | FEMB_2_MON_6 | FEMB_3_MON_6 | FEMB_4_MON_6 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).V_FE_2V5;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.FEMB(power_monitor_FEMB_index).I_FE_2V5;
              when WIB_MON_0 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.WIB.VCC;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.WIB.Temp;
              when WIB_MON_1 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.WIB.V_5V;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.WIB.I_5V;
              when WIB_MON_2 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.WIB.V_1V8;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.WIB.I_1V8;
              when WIB_MON_3 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.WIB.V_3V6;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.WIB.I_3V6;
              when WIB_MON_4 =>
                read_data(4)(15 downto  0) <= WIB_PWR_monitor.WIB.V_2V8;
                read_data(4)(31 downto 16) <= WIB_PWR_monitor.WIB.I_2V8;

              when REG_TEST_4 =>
                read_data(4)(31 downto 0)  <= test_reg(4);
              when others =>
                --mark data as not found
                read_data(4) <= x"000000000";
            end case;
            read_data_wr(4) <= '1';
            READ_state(4)   <= READ_STATE_IDLE;
          when READ_STATE_WRITE =>
-----            read_data_wr(4) <= '1';
-----            READ_state(4)   <= READ_STATE_IDLE;
          when others =>
            READ_state(4) <= READ_STATE_IDLE;
        end case;

        -------------------------------------------------------
        -- Write
        -------------------------------------------------------
        localFlash_Control.run <= '0';
        localFlash_Control.reset <= '0';
        WIB_control.TempSensor.start <= '0';
--        WIB_PWR_control.convert <= '0';
--        WIB_PWR_control.WIB_I2C.run <= '0';
--        WIB_PWR_control.WIB_I2C.reset <= '0';
        
        write_addr_data_ack(4) <= '0';      
        case WRITE_state(4) is
          when WRITE_STATE_IDLE =>
            -- Write/action switch
            if write_addr_data_valid(4) = '1' then
-----              WRITE_STATE(4) <= WRITE_STATE_CAPTURE_ADDRESS;
              -- buffer address
              write_addr_cap(4)      <= unsigned(write_addr(4));
              write_data_cap(4)      <= write_data(4);
              WRITE_STATE(4)         <= WRITE_STATE_WRITE;
            end if;
          when WRITE_STATE_CAPTURE_ADDRESS =>
-----            -- buffer address
-----            write_addr_cap(4)      <= unsigned(write_addr(4));
-----            write_data_cap(4)      <= write_data(4);
-----            WRITE_STATE(4)         <= WRITE_STATE_WRITE;
-----            write_addr_data_ack(4) <= '1';
          when WRITE_STATE_WRITE =>
            -- process write and ack
            WRITE_STATE(4) <= WRITE_STATE_IDLE;
            case write_addr_cap(4) is

              when LFLASH_CTRL =>
                localFlash_Control.run        <= write_data_cap(4)(0);
                localFlash_Control.rw         <= write_data_cap(4)(1);
                localFlash_Control.reset      <= write_data_cap(4)(4);
                localFlash_Control.addr       <= write_data_cap(4)(31 downto 16);
              when LFLASH_WRITE =>
                localFlash_Control.wr_data    <= write_data_cap(4)(31 downto 0);
              when TS_CTRL =>
                WIB_control.TempSensor.start  <= write_data_cap(4)(0);
                
              when FEMB_POWER_MON_CONTROL =>
                WIB_PWR_control.reset <= write_data_cap(4)(0);
              when REG_TEST_4 =>
                test_reg(4) <= write_data_cap(4)(31 downto 0);

              when others => null;
            end case;
          when others => WRITE_state(4) <= WRITE_STATE_IDLE;
        end case;
      end if;
    end if;
  end process REGS_40Mhz;
  
  -------------------------------------------------------------------------------------
  -- 25Mhz clocks
  -------------------------------------------------------------------------------------
  REGS_25Mhz : process (clk_domain(5)) is
  begin  -- process REGS_25Mhz
    if clk_domain(5)'event and clk_domain(5) = '1' then  -- rising clock edge
      if reset_sync_domain(5) = '1' then 
        
        test_reg(5) <= (others => '0');
        EB_Control.QSFP <= DEFAULT_QSFP_CONTROL;

        READ_state(5)  <= READ_STATE_IDLE;
        WRITE_state(5) <= WRITE_STATE_IDLE;

      else                
        -------------------------------------------------------
        -- Read
        -------------------------------------------------------
        read_address_ack(5) <= '0';
        read_data_wr(5)     <= '0';

        case READ_state(5) is

          when READ_STATE_IDLE =>
            if read_address_valid(5) = '1' then
              read_address_ack(5) <= '1';
-----              READ_state(5)       <= READ_STATE_CAPTURE_ADDRESS;
              -- capture the address we will be using
              read_address_cap(5) <= unsigned(read_address(5));
              READ_state(5)       <= READ_STATE_READ;
            end if;
          when READ_STATE_CAPTURE_ADDRESS =>
-----            -- capture the address we will be using
-----            read_address_cap(5) <= unsigned(read_address(5));
-----            READ_state(5)       <= READ_STATE_READ;

          when READ_STATE_READ =>
--            READ_state(5) <= READ_STATE_WRITE;

            read_data(5) <= x"100000000";  --Mark the data as zeros and the
                                           --register found                

            case to_integer(read_address_cap(5)) is
              when to_integer(DAQ_QSFP_CONTROL) =>
                read_data(5)(0) <= EB_Monitor.QSFP.reset;
                read_data(5)(1) <= EB_Monitor.QSFP.LP_mode;
                read_data(5)(4) <= EB_Monitor.QSFP.present;
                read_data(5)(5) <= EB_Monitor.QSFP.interrupt;

              when to_integer(DAQ_QSFP_I2C_Control) =>
                read_data(5)(1)            <= EB_Monitor.QSFP.I2C.rw;
                read_data(5)(2)            <= EB_Monitor.QSFP.I2C.done;
                read_data(5)(3)            <= EB_Monitor.QSFP.I2C.error;
                read_data(5)(10 downto  8) <= EB_Monitor.QSFP.I2C.byte_count;
                read_data(5)(23 downto 16) <= EB_Monitor.QSFP.I2C.address;

              when to_integer(DAQ_QSFP_I2C_WR_DATA) =>
                read_data(5)(31 downto 0) <= EB_Monitor.QSFP.I2C.wr_data;

              when to_integer(DAQ_QSFP_I2C_RD_DATA) =>
                read_data(5)(31 downto 0) <= EB_Monitor.QSFP.I2C.rd_data;
              
              when to_integer(FLASH_CTRL)         =>
                read_data(5)(8)  <= Flash_monitor.illegal_write;
                read_data(5)(9)  <= Flash_monitor.illegal_erase;
                read_data(5)(16) <= Flash_monitor.busy;
                read_data(5)(30) <= Flash_monitor.reconfig_busy;
              when to_integer(FLASH_ADDRESS)         => read_data(5)(23 downto  0) <= Flash_monitor.address;
              when to_integer(FLASH_PAGE_BYTE_COUNT) => read_data(5)( 7 downto  0) <= Flash_monitor.byte_count;
              when to_integer(FLASH_STATUS)          => read_data(5)( 7 downto  0) <= Flash_monitor.status;
                                                        
              when to_integer(FLASH_RECONFIG) =>
                read_data(5)( 6 downto  4) <= Flash_monitor.reconfig_param;
                read_data(5)(31 downto  8) <= Flash_monitor.reconfig_rd_data;
              when to_integer(FLASH_PAGE_DATA_START) to to_integer(FLASH_PAGE_DATA_END) =>
                read_data(5)(31 downto  0) <= Flash_monitor.data(to_integer(read_address_cap(5)(7 downto 0))); 
              when to_integer(REG_TEST_5) =>
                read_data(5)(31 downto 0) <= test_reg(5);
              when others =>
                --mark data as not found
                read_data(5) <= x"000000000";
            end case;
            read_data_wr(5) <= '1';            
            READ_state(5)   <= READ_STATE_IDLE;
            
          when READ_STATE_WRITE =>
-----            read_data_wr(5) <= '1';
-----            READ_state(5)   <= READ_STATE_IDLE;
          when others =>
            READ_state(5) <= READ_STATE_IDLE;
        end case;

        -------------------------------------------------------
        -- Write
        -------------------------------------------------------
        Flash_control.data_wr <= '0';
        Flash_control.wr <= '0';
        Flash_control.erase <= '0';
        Flash_control.status_rd <= '0';
        Flash_control.rd <= '0';
        Flash_control.reconfig <= '0';
        Flash_control.reconfig_reset <= '0';
        Flash_control.reconfig_rd_param <= '0';
        Flash_control.reconfig_wr_param <= '0';
        EB_control.QSFP.I2C.run <= '0';
        EB_control.QSFP.I2C.rw  <= '0';

        
        write_addr_data_ack(5) <= '0';
        case WRITE_state(5) is
          when WRITE_STATE_IDLE =>
            -- Write/action switch
            if write_addr_data_valid(5) = '1' then
--              WRITE_STATE(5) <= WRITE_STATE_CAPTURE_ADDRESS;
              -- buffer address
              write_addr_cap(5)      <= unsigned(write_addr(5));
              write_data_cap(5)      <= write_data(5);
              WRITE_STATE(5)         <= WRITE_STATE_WRITE;
            end if;
          when WRITE_STATE_CAPTURE_ADDRESS =>
--            -- buffer address
--            write_addr_cap(5)      <= unsigned(write_addr(5));
--            write_data_cap(5)      <= write_data(5);
--            WRITE_STATE(5)         <= WRITE_STATE_WRITE;
--            write_addr_data_ack(5) <= '1';
          when WRITE_STATE_WRITE =>
            -- process write and ack
            WRITE_STATE(5) <= WRITE_STATE_IDLE;
            case to_integer(write_addr_cap(5)) is

              when to_integer(DAQ_QSFP_CONTROL) =>
                EB_Control.QSFP.reset   <= write_data_cap(5)(0); 
                EB_Control.QSFP.LP_mode <= write_data_cap(5)(1);

              when to_integer(DAQ_QSFP_I2C_Control) =>
                EB_control.QSFP.I2C.run <= write_data_cap(5)(0);
                EB_control.QSFP.I2C.rw  <= write_data_cap(5)(1);
                EB_Control.QSFP.I2C.byte_count <= write_data_cap(5)(10 downto  8);
                EB_Control.QSFP.I2C.address    <= write_data_cap(5)(23 downto 16);
                
              when to_integer(DAQ_QSFP_I2C_WR_DATA) =>
                EB_Control.QSFP.I2C.wr_data <= write_data_cap(5)(31 downto 0);

              
              when to_integer(FLASH_CTRL) =>
                if write_data_cap(5)(0) = '1' then
                  case write_data_cap(5)(2 downto 1) is
                    when "00" => Flash_control.wr <= '1';
                    when "11" => Flash_control.erase <= '1';
                    when "01" => Flash_control.status_rd <= '1';
                    when "10" => Flash_control.rd <= '1';
                    when others => null;
                  end case;                  
                end if;
                Flash_control.reconfig <= write_data_cap(5)(31);
                Flash_control.reconfig_reset <= write_data_cap(5)(29);
              when to_integer(FLASH_RECONFIG) =>
                Flash_control.reconfig_rd_param <= write_data_cap(5)(0);
                Flash_control.reconfig_wr_param <= write_data_cap(5)(1);
                Flash_control.reconfig_param    <= write_data_cap(5)( 6 downto  4);
                Flash_control.reconfig_wr_data  <= write_data_cap(5)(31 downto  8);
                
              when to_integer(FLASH_ADDRESS)         => Flash_control.address    <= write_data_cap(5)(23 downto  0);
              when to_integer(FLASH_PAGE_BYTE_COUNT) => Flash_control.byte_count <= write_data_cap(5)( 7 downto  0);
              when to_integer(FLASH_PAGE_DATA_START) to to_integer(FLASH_PAGE_DATA_END) =>
                --write to address in flash page buffer
                Flash_control.data <= write_data_cap(5)(31 downto 0);
                Flash_control.data_address <= to_integer(write_addr_cap(5)(7 downto 0));
                Flash_control.data_wr <= '1';
              when to_integer(REG_TEST_5) =>
                test_reg(5) <= write_data_cap(5);

              when others => null;
            end case;
          when others => WRITE_STATE(5) <= WRITE_STATE_IDLE;
        end case;
      end if;
    end if;
  end process REGS_25Mhz;



  -------------------------------------------------------------------------------------
  -- DUNE clock
  -------------------------------------------------------------------------------------
  REGS_DUNE : process (clk_domain(6)) is
  begin  -- process REGS_50Mhz
    if clk_domain(6)'event and clk_domain(6) = '1' then  -- rising clock edge
      if reset_sync_domain(6) = '1' then 
        DTS_Control.DTS_Convert  <= DEFAULT_DTS_control.DTS_Convert;  
        test_reg(6) <= (others => '0');

        READ_state(6)  <= READ_STATE_IDLE;
        WRITE_state(6) <= WRITE_STATE_IDLE;

      else      
        -------------------------------------------------------
        -- Read
        -------------------------------------------------------
        read_address_ack(6) <= '0';
        read_data_wr(6)     <= '0';

        case READ_state(6) is

          when READ_STATE_IDLE =>
            if read_address_valid(6) = '1' then
              read_address_ack(6) <= '1';
              READ_state(6)       <= READ_STATE_CAPTURE_ADDRESS;
            end if;
          when READ_STATE_CAPTURE_ADDRESS =>
            -- capture the address we will be using
            read_address_cap(6) <= unsigned(read_address(6));
            READ_state(6)       <= READ_STATE_READ;

          when READ_STATE_READ =>
            READ_state(6) <= READ_STATE_WRITE;

            read_data(6) <= x"100000000";  --Mark the data as zeros and the
                                           --register found                
            case read_address_cap(6) is

              when DTS_CONVERT_CONTROL =>
                read_data(6)(0)           <= DTS_Monitor.DTS_Convert.converts_enabled;
                read_data(6)(1)           <= DTS_Monitor.DTS_Convert.out_of_sync;
                read_data(6)(2)           <= DTS_Monitor.DTS_Convert.use_local_timestamp;
                read_data(6)(3)           <= DTS_Monitor.DTS_Convert.enable_fake;
                read_data(6)(4)           <= DTS_Monitor.DTS_Convert.halt;
                read_data(6)(11 downto  8)<= DTS_Monitor.DTS_Convert.state;

              when DTS_CONVERT_SYNC_PERIOD =>
                read_data(6)(31 downto 0) <= DTS_Monitor.DTS_Convert.sync_counter_period;
                
              when DTS_CONVERT_LAST_SYNC_LSB =>
                read_data(6)(31 downto 0) <= DTS_Monitor.DTS_Convert.last_good_sync(31 downto  0);
              when DTS_CONVERT_LAST_SYNC_MSB =>
                read_data(6)(31 downto 0) <= DTS_Monitor.DTS_Convert.last_good_sync(63 downto 32);
              when DTS_CONVERT_MISSED_SYNCS =>
                read_data(6)(31 downto 0) <= DTS_Monitor.DTS_Convert.missed_periodic_syncs;
              when DTS_CONVERT_BAD_FEMB_HACK =>
                read_data(6)(3 downto 0)   <= DTS_Monitor.DTS_Convert.DAQ_timestamps_before_sync;

              when REG_TEST_6 =>
                read_data(6)(31 downto 0) <= test_reg(6);
                
              when others =>
                --mark data as not found
                read_data(6) <= x"000000000";
            end case;
          when READ_STATE_WRITE =>
            read_data_wr(6) <= '1';
            READ_state(6)   <= READ_STATE_IDLE;
          when others =>
            READ_state(6) <= READ_STATE_IDLE;
        end case;

        -------------------------------------------------------
        -- Write
        -------------------------------------------------------
        DTS_Control.DTS_Convert.start_sync <= '0';

        write_addr_data_ack(6) <= '0';
        case WRITE_state(6) is
          when WRITE_STATE_IDLE =>
            -- Write/action switch
            if write_addr_data_valid(6) = '1' then
              WRITE_STATE(6) <= WRITE_STATE_CAPTURE_ADDRESS;
            end if;
          when WRITE_STATE_CAPTURE_ADDRESS =>
            -- buffer address
            write_addr_cap(6)      <= unsigned(write_addr(6));
            write_data_cap(6)      <= write_data(6);
            WRITE_STATE(6)         <= WRITE_STATE_WRITE;
            write_addr_data_ack(6) <= '1';
          when WRITE_STATE_WRITE =>
            -- process write and ack
            WRITE_STATE(6) <= WRITE_STATE_IDLE;
            case write_addr_cap(6) is

              when DTS_CONVERT_CONTROL =>
                DTS_Control.DTS_Convert.converts_enabled    <= write_data_cap(6)(0);
                DTS_Control.DTS_Convert.use_local_timestamp <= write_data_cap(6)(2);
                DTS_Control.DTS_Convert.enable_fake         <= write_data_cap(6)(3);
                
                DTS_Control.DTS_Convert.halt                <= write_data_cap(6)(4);
                DTS_Control.DTS_Convert.start_sync          <= write_data_cap(6)(5);

              when DTS_CONVERT_SYNC_PERIOD =>
                DTS_Control.DTS_Convert.sync_counter_period <= write_data_cap(6)(31 downto 0);

              when DTS_CONVERT_BAD_FEMB_HACK =>
                DTS_control.DTS_Convert.DAQ_timestamps_before_sync <= write_data_cap(6)(3 downto 0);
                
              when REG_TEST_6 =>
                test_reg(6) <= write_data_cap(6);
              when others => null;
            end case;
          when others => WRITE_STATE(6) <= WRITE_STATE_IDLE;
        end case;
      end if;
    end if;
  end process REGS_DUNE;


  -------------------------------------------------------------------------------------
  -- FEMB_CNC clock
  -------------------------------------------------------------------------------------
  REGS_FEMB_CNC : process (clk_domain(7)) is
  begin  -- process REGS_50Mhz
    if clk_domain(7)'event and clk_domain(7) = '1' then  -- rising clock edge
      if reset_sync_domain(7) = '1' then 
--        FEMB_CNC_control <= DEFAULT_FEMB_CNC_Control;
        FEMB_CNC_control.error_convert_timing_counter_reset <= DEFAULT_FEMB_CNC_Control.error_convert_timing_counter_reset;
        FEMB_CNC_control.convert_counter_reset              <= DEFAULT_FEMB_CNC_Control.convert_counter_reset;
        FEMB_CNC_control.calibrate_counter_reset            <= DEFAULT_FEMB_CNC_Control.calibrate_counter_reset;
        FEMB_CNC_control.sync_counter_reset                 <= DEFAULT_FEMB_CNC_Control.sync_counter_reset;
        FEMB_CNC_control.reset_counter_reset                <= DEFAULT_FEMB_CNC_Control.reset_counter_reset;
        FEMB_CNC_control.cmd_sel                            <= DEFAULT_FEMB_CNC_Control.cmd_sel;
        FEMB_CNC_control.clk_sel                            <= DEFAULT_FEMB_CNC_Control.clk_sel;
        FEMB_CNC_control.enable_converts_to_FEMB            <= DEFAULT_FEMB_CNC_Control.enable_converts_to_FEMB;
        FEMB_CNC_control.stop_data                          <= DEFAULT_FEMB_CNC_Control.stop_data;
        FEMB_CNC_control.start_data                         <= DEFAULT_FEMB_CNC_Control.start_data;
        FEMB_CNC_control.timestamp_reset                    <= DEFAULT_FEMB_CNC_Control.timestamp_reset;
        FEMB_CNC_control.calibration                        <= DEFAULT_FEMB_CNC_Control.calibration;
        FEMB_CNC_control.DTS_cmd_enable                     <= DEFAULT_FEMB_CNC_Control.DTS_cmd_enable;
        FEMB_CNC_control.DTS_TP_enable                      <= DEFAULT_FEMB_CNC_Control.DTS_TP_enable;
        
        test_reg(7) <= (others => '0');

        READ_state(7)  <= READ_STATE_IDLE;
        WRITE_state(7) <= WRITE_STATE_IDLE;

      else      
        -------------------------------------------------------
        -- Read
        -------------------------------------------------------
        read_address_ack(7) <= '0';
        read_data_wr(7)     <= '0';

        case READ_state(7) is

          when READ_STATE_IDLE =>
            if read_address_valid(7) = '1' then
              read_address_ack(7) <= '1';
              READ_state(7)       <= READ_STATE_CAPTURE_ADDRESS;
            end if;
          when READ_STATE_CAPTURE_ADDRESS =>
            -- capture the address we will be using
            read_address_cap(7) <= unsigned(read_address(7));
            READ_state(7)       <= READ_STATE_READ;

          when READ_STATE_READ =>
            READ_state(7) <= READ_STATE_WRITE;

            read_data(7) <= x"100000000";  --Mark the data as zeros and the
                                           --register found                
            case read_address_cap(7) is
              when FEMB_CNC =>
                read_data(7)(0)  <= FEMB_CNC_Monitor.clk_sel;
                read_data(7)(1)  <= FEMB_CNC_Monitor.cmd_sel;
                read_data(7)(2)  <= FEMB_CNC_Monitor.enable_converts_to_FEMB;
                read_data(7)(3)  <= FEMB_CNC_Monitor.sending_converts_to_FEMB;
                read_data(7)(5)  <= FEMB_CNC_Monitor.DTS_locked;               
                read_data(7)(12) <= FEMB_CNC_monitor.DTS_cmd_enable;
                read_data(7)(13) <= FEMB_CNC_monitor.DTS_TP_enable;
              when REG_TEST_7 =>
                read_data(7)(31 downto 0) <= test_reg(7);
                
              when others =>
                --mark data as not found
                read_data(7) <= x"000000000";
            end case;
          when READ_STATE_WRITE =>
            read_data_wr(7) <= '1';
            READ_state(7)   <= READ_STATE_IDLE;
          when others =>
            READ_state(7) <= READ_STATE_IDLE;
        end case;

        -------------------------------------------------------
        -- Write
        -------------------------------------------------------
        FEMB_CNC_Control.stop_data  <= '0';
        FEMB_CNC_Control.start_data <= '0';
        FEMB_CNC_Control.timestamp_reset <= '0';     
        FEMB_CNC_Control.calibration <= '0';
        
        write_addr_data_ack(7) <= '0';
        case WRITE_state(7) is
          when WRITE_STATE_IDLE =>
            -- Write/action switch
            if write_addr_data_valid(7) = '1' then
              WRITE_STATE(7) <= WRITE_STATE_CAPTURE_ADDRESS;
            end if;
          when WRITE_STATE_CAPTURE_ADDRESS =>
            -- buffer address
            write_addr_cap(7)      <= unsigned(write_addr(7));
            write_data_cap(7)      <= write_data(7);
            WRITE_STATE(7)         <= WRITE_STATE_WRITE;
            write_addr_data_ack(7) <= '1';
          when WRITE_STATE_WRITE =>
            -- process write and ack
            WRITE_STATE(7) <= WRITE_STATE_IDLE;
            case write_addr_cap(7) is
              when FEMB_CNC =>
                FEMB_CNC_Control.clk_sel    <= write_data_cap(7)(0);
                FEMB_CNC_Control.cmd_sel    <= write_data_cap(7)(1);
                FEMB_CNC_Control.enable_converts_to_FEMB <= write_data_cap(7)(2);


                FEMB_CNC_Control.stop_data  <= write_data_cap(7)(8);
                FEMB_CNC_Control.start_data <= write_data_cap(7)(9);     
                FEMB_CNC_Control.timestamp_reset <= write_data_cap(7)(10);
                FEMB_CNC_Control.calibration <= write_data_cap(7)(11);

                FEMB_CNC_control.DTS_cmd_enable  <= write_data_cap(7)(12);
                FEMB_CNC_control.DTS_TP_enable   <= write_data_cap(7)(13);
              when REG_TEST_7 =>
                test_reg(7) <= write_data_cap(7);
              when others => null;
            end case;
          when others => WRITE_STATE(7) <= WRITE_STATE_IDLE;
        end case;
      end if;
    end if;
  end process REGS_FEMB_CNC;





  
  counter_reads: entity work.counter
    generic map (
      DATA_WIDTH  => 32)
    port map (
      clk         => clk_UDP,
      reset_async => '0',
      reset_sync  => reset,
      enable      => '1',
      event       => RD_strb,
      count       => read_count,
      at_max      => open);
  
  counter_writes: entity work.counter
    generic map (
      DATA_WIDTH  => 32)
    port map (
      clk         => clk_UDP,
      reset_async => '0',
      reset_sync  => reset,
      enable      => '1',
      event       => WR_strb,
      count       => write_count,
      at_max      => open);


end architecture Behavioral;

