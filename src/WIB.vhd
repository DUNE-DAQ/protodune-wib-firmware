library altera;
use altera.altera_primitives_components.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.WIB_Constants.all;
use work.FEMB_DAQ_IO.all;
use work.WIB_IO.all;
use work.DTS_IO.all;
use work.Convert_IO.all;
use work.EB_IO.all;
use work.DQM_IO.all;
use work.types.all;
use work.DQM_packet.all;
use work.FEMB_CnC_IO.all;
use work.Flash_IO.all;
use work.localFlash_IO.all;
use work.CD_EB_BRIDGE.all;
use work.NET_IO.all;
use work.WIB_PWR_IO.all;

entity WIB is
  port
    (
      ---------------------------------------------------------------------------
      -- System clocks
      reset_ext            : in std_logic;  -- 2.5V,  PIN_AM31
      clk_in_50MHz         : in std_logic;  -- 2.5V, PIN_A16, Fixed 50Mhz
      -- Flash control
--      AS_DATA   : inout std_logic_vector(3 downto 0);
--      AS_CLK    : out std_logic;
--      AS_NCS    : out std_logic;
    
      ---------------------------------------------------------------------------      
      --  DUNE timing system
      DTS_CDS_SOURCE  : out std_logic;     --FP or BP
      DTS_CDS_LOL     : in std_logic;
      DTS_CDS_LOS     : in std_logic;
      DTS_CDS_SCL     : inout std_logic;
      DTS_CDS_SDA     : inout std_logic;
      
      DUNE_clk_in_P   : in std_logic;  
      DUNE_clk_out_P  : out std_logic;  

      DTS_data_clk_P : in std_logic;
      DTS_data_P     : in std_logic;  

      DTS_FEMB_clk_P : in std_logic;
      
      DTS_FP_CLK_OUT_DSBL : out std_logic;
      DTS_FP_CLK_OUT_P  : out std_logic;
      DTS_BP_OUT_DSBL  : out std_logic_vector(5 downto 0);
      
--      DTS_FPGA_CLK_P : out std_logic;      
      
      DTS_SI5344_SCL    : inout std_logic;
      DTS_SI5344_SDA    : inout std_logic;
      DTS_SI5344_INT_N  : in    std_logic;
      DTS_SI5344_OE_N   : out    std_logic;
      DTS_SI5344_RST_N  : out    std_logic;
      DTS_SI5344_LOL_N  : in    std_logic;
      DTS_SI5344_LOS_N  : in    std_logic;
      DTS_SI5344_IN_SEL : out   std_logic_vector(1 downto 0); 
      
      ---------------------------------------------------------------------------
      -- FEMB clocking
      FEMB_CLK_SEL : out std_logic;
      
      DCC_CMD_SEL : out std_logic;     
      DCC_FPGA_CMD_P : out std_logic;        
      ---------------------------------------------------------------------------
      -- Slow Control GBE
      SFP_refclk_P : in  std_logic;     -- LVDS, PIN_R9      
      SFP_Rx_P     : in  std_logic;     -- 1.5-V PCML, PIN_H1
      SFP_Tx_P     : out std_logic;     -- 1.5-V PCML, PIN_G3


      ---------------------------------------------------------------------------      
      -- DAQ links
--      QSFP_Tx_P : out std_logic_vector(3 downto 0);  -- 1.5-V PCML, PIN_G32,J32,L32,N32 DAQ Transmit Data
      QSFP_Tx_P : out std_logic_vector(DAQ_LINK_COUNT -1 downto 0);  -- 1.5-V PCML, PIN_G32,J32,L32,N32 DAQ Transmit Data
--      QSFP_Rx_P : in std_logic; --PCML PIN_H34
      
      DAQ_LINK_SI5342_LOL_N     : in std_logic;
      DAQ_LINK_SI5342_LOSXAXB_N : in std_logic;
      DAQ_LINK_SI5342_LOS1_N    : in std_logic;
      DAQ_LINK_SI5342_LOS2_N    : in std_logic;
      DAQ_LINK_SI5342_LOS3_N    : in std_logic;
      DAQ_LINK_SI5342_OE_N      : out std_logic;
      DAQ_LINK_SI5342_RESET_N   : out std_logic;
      DAQ_LINK_SI5342_INT_N     : in std_logic;
      DAQ_LINK_SI5342_SCL       : inout std_logic;
      DAQ_LINK_SI5342_SDA       : inout std_logic;   
      DAQ_LINK_SI5342_SEL0      : out std_logic;
      DAQ_LINK_SI5342_SEL1      : out std_logic;
      
      RCE_Tx_refclk_P : in std_logic;   -- LVDS PIN_W26
      FELIX_Tx_refclk_P : in std_logic;   -- LVDS PIN_W26
      refclk_out  : out std_logic; -- LVDS PIN_C31
      
      -- DAQ Linkc afbontrol
      QSFP_RST_N  : out   std_logic;      -- 2.5V, default
      QSFP_LOW_POWER_MODE : out std_logic;
      QSFP_INT_N  : in  std_logic;
      QSFP_PRESENT_N  : in  std_logic;
      QSFP_I2C_SEL_N  : out   std_logic;     -- 2.5V
      QSFP_SCL    : inout   std_logic;      -- 2.5V, default   
      QSFP_SDA    : inout std_logic;      -- 2.5V, default


      ---------------------------------------------------------------------------
      -- FEMB Data streams
      clk_FEMB_128Mhz_P : in std_logic;  -- LVDS PIN_A19, global clock for FEMB
                                         -- capture
      FEMB_RX_P         : in std_logic_vector(15 downto 0);  -- 1.5-V PCML, Cold electronics board reciver

      FEMB_Rx_refclk_P : in std_logic_vector(1 downto 0);  -- LVDS PIN_R27,R26, for 128Mhz FEMB_RX_P 0-7,8-15

      FEMB_LOS_n         : in std_logic_vector(15 downto 0);  --2.5V, default
      

      ---------------------------------------------------------------------------
      -- FEMB Slow Control & calibration

      ---- FEMB I2C interface
      FEMB_SCL   : out   std_logic_vector(3 downto 0); -- LVDS ,  FEMB DIFF I2C  CLOCK
      FEMB_SDA_P : inout std_logic_vector(3 downto 0); -- DIFF 2.5V SSTL CLASS I , FEMB      DIFF I2C  DATA
      FEMB_SDA_N : inout std_logic_vector(3 downto 0); -- DIFF 2.5V SSTL CLASS I , FEMB      DIFF I2C  DATA

      ----  WIB-FEMB JTAG INTERFACE
--      FEMB_JTAG_TDO : in  std_logic_vector(3 downto 0); -- 2.5V, default
--      FEMB_JTAG_TMS : out std_logic_vector(3 downto 0); -- 2.5V, default
--      FEMB_JTAG_TCK : out std_logic_vector(3 downto 0); -- 2.5V, default
--      FEMB_JTAG_TDI : out std_logic_vector(3 downto 0); -- 2.5V, default

      ---- WIB CALIBRATRION CONTROL
      --CAL_PUL_GEN : out std_logic;      --  2.5V, DC TO DC PWR ENABLE FOR 3.6V
      --
      --CAL_DAC_SYNC : out std_logic;     -- 2.5V, DC TO DC PWR ENABLE FOR 3.6V
      --CAL_DAC_SCLK : out std_logic;     -- 2.5V, DC TO DC PWR ENABLE FOR 3.6V
      --CAL_DAC_DIN  : out std_logic;     --  2.5V, DC TO DC PWR ENABLE FOR 3.6V
      --
      --CAL_SRC_SEL : out std_logic_vector(3 downto 0);  --     2.5V, DC TO DC PWR ENABLE FOR 3.6V

      ---------------------------------------------------------------------------
      -- FEMB Power control & monitoring                                                       
      
      -- WIB FEMB POWER CONTROL 
      --PWR_CLK_IN  : out std_logic_vector(5 downto 0);  -- 2.5V, NOT USED
      --PWR_CLK_OUT : in  std_logic_vector(5 downto 0);  -- 2.5V, NOt USED

      PWR_EN_3V6  : out std_logic_vector(3 downto 0);  -- 2.5V, DC TO DC PWR ENABLE FOR 3.6V
      PWR_EN_2V8  : out std_logic_vector(3 downto 0);  -- 2.5V, DC TO DC PWR ENABLE FOR 2.8V
      PWR_EN_2V5  : out std_logic_vector(3 downto 0);  -- 2.5V, DC TO DC PWR ENABLE FOR 2.5V      
      PWR_EN_1V5  : out std_logic_vector(3 downto 0);  -- 2.5V, DC TO DC PWR ENABLE FOR 1.5V      
      PWR_EN_BIAS : out std_logic_vector(3 downto 0);  -- 2.5V, DC TO DC PWR ENABLE FOR 4.9V
      
      PWR_EN_BIAS_MASTER : out std_logic;                -- 2.5V, Master bias enable

      ---- WIB FEMB POWER MONITOR (4 is bias)
      PWR_SCL : inout std_logic_vector(4 downto 0);    -- 2.5V, LTC2991 clk control
      PWR_SDA : inout std_logic_vector(4 downto 0);    -- 2.5V, LTC2991 SDA control

      PWR_WIB_SCL : inout std_logic; --2.5V LTC2991 clk
      PWR_WIB_SDA : inout std_logic; --2.5V LTC2991 clk


      ---------------------------------------------------------------------------
      -- WIB MISC_IO
      CRATE_ADDR : in std_logic_vector(3 downto 0);     -- 2.5V, PIN_AN9,AJ16,AN8,AP10
      SLOT_ADDR  : in std_logic_vector(3 downto 0);     -- 2.5V, PIN_AL14,AM14,AN14,AP14
--      DIP_SW     : in    std_logic;                     -- 2.5V, PIN_A27
      LED : out std_logic_vector(7 downto 0);  -- 2.5V, PIN_C29,A29,D30,B30,A28,F29,D28,F28       

--      LEMO_IN1  : out std_logic;        --     2.5V,  LEMO_FRNT PANNEL 
--      LEMO_OUT   : out  std_logic;        --      2.5V,  LEMO_FRNT PANNEL
--      LEMO_OUT2  : out  std_logic;        --      2.5V,  LEMO_FRNT PANNEL 

--      BP_IO        : inout std_logic_vector(7 downto 0);   --   2.5V,   
--      MISC_IO      : inout std_logic_vector(15 downto 0);  --        2.5V, 
      LFLASH_SCL    : inout   std_logic;                      --    2.5V,  24lc64
      LFLASH_SDA    : inout std_logic;                       --  2.5V,  24lc64
      
      TS_CS_N  : out   std_logic;                      --  2.5V,  MAX31855K
      TS_SCLK : out   std_logic;                      -- 2.5V,  MAX31855K
      TS_SDA  : inout std_logic                       -- 2.5V,  MAX31855K

      -- Un-used
      --refclk4 : in std_logic;                          -- LVDS    , default 125MHz        
      --refclk5 : in std_logic;                          -- LVDS    , default 125MHz


      );
end entity;

architecture WIB_ARCH of WIB is

  component reseter is
    generic (
      DEPTH : integer);
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      reset       : out std_logic);
  end component reseter;

  component sys_rst
    port(
      clk      : in  std_logic;
      reset_in : in  std_logic;
      start    : out std_logic;
      RST_OUT  : out std_logic
      );
  end component;

  component sys_pll
    port(
      refclk   : in  std_logic := 'X';  -- clk
      rst      : in  std_logic := 'X';  -- reset
      outclk_0 : out std_logic;         -- clk
      outclk_1 : out std_logic;         -- clk
      outclk_2 : out std_logic;
      outclk_3 : out std_logic;
      outclk_4 : out std_logic;
      locked   : out std_logic);
  end component;

  component REFCLK_PLL is
    port (
      refclk   : in  std_logic := '0';
      rst      : in  std_logic := '0';
      outclk_0 : out std_logic);
  end component REFCLK_PLL;
  
  component DCC_FEMB_PLL is
    port (
      refclk   : in  std_logic := '0';
      rst      : in  std_logic := '0';
      outclk_0 : out std_logic;
      outclk_1 : out std_logic;
      locked   : out std_logic);
  end component DCC_FEMB_PLL;

  component register_map is
    generic (
      FIRMWARE_VERSION : std_logic_vector(31 downto 0));
    port (
      clk_UDP      : in  std_logic;
      locked_UDP   : in  std_logic;
      reset        : in  std_logic;
      Ver_ID       : in  std_logic_vector(31 downto 0);
      data_in      : in  std_logic_vector(31 downto 0);
      WR_address   : in  std_logic_vector(15 downto 0);
      RD_address   : in  std_logic_vector(15 downto 0);
      WR_strb      : in  std_logic;
      RD_strb      : in  std_logic;
      data_out     : out std_logic_vector(31 downto 0);
      rd_ack       : out std_logic;
      wr_ack       : out std_logic;
      clk_WIB      : in  std_logic;
      clk_EVB      : in  std_logic;
      clk_FEMB     : in  std_logic;
      clk_services : in  std_logic;
      clk_flash    : in  std_logic;
      clk_DUNE     : in std_logic;
      clk_FEMB_CNC : in std_logic;
      locked_WIB   : in  std_logic;
      locked_EVB   : in  std_logic;
      locked_FEMB  : in  std_logic;
      locked_services : in std_logic;
      locked_flash : in  std_logic;
      locked_DUNE  : in std_logic;
      locked_FEMB_CNC : in std_logic;
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
      UDP_Control  : out DQM_Control_t;
      UDP_Monitor  : in  DQM_Monitor_t;
      WIB_PWR_control : out WIB_PWR_Control_t;
      WIB_PWR_monitor : in  WIB_PWR_Monitor_t      
      );
  end component register_map;


  component UDP_IO is
    port (
      reset            : IN  STD_LOGIC;
      CLK_125Mhz       : IN  STD_LOGIC;
      CLK_50MHz        : IN  STD_LOGIC;
      CLK_IO           : IN  STD_LOGIC;
      SPF_OUT          : IN  STD_LOGIC;
      SFP_IN           : OUT STD_LOGIC;
      START            : IN  STD_LOGIC;
      BRD_IP           : IN  STD_LOGIC_VECTOR(31 downto 0);
      BRD_MAC          : IN  STD_LOGIC_VECTOR(47 downto 0);
      EN_WR_RDBK       : IN  std_logic;
      TIME_OUT_wait    : IN  STD_LOGIC_VECTOR(31 downto 0);
      FRAME_SIZE       : IN  std_logic_vector(11 downto 0);
      tx_fifo_clk      : IN  STD_LOGIC;
      tx_fifo_wr       : IN  STD_LOGIC;
      tx_fifo_in       : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
      tx_fifo_full     : OUT STD_LOGIC;
      tx_fifo_used     : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
      DQM_ip_dest_addr  : out  std_logic_vector(31 downto 0);
      DQM_mac_dest_addr : out  std_logic_vector(47 downto 0);
      DQM_dest_port     : out  std_logic_vector(15 downto 0);
      header_user_info : IN  STD_LOGIC_VECTOR(63 downto 0);
      system_status    : IN  STD_LOGIC_VECTOR(31 downto 0);
      data             : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      rdout            : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      wr_strb          : OUT STD_LOGIC;
      rd_strb          : OUT STD_LOGIC;
      rd_ack           : in  STD_LOGIC;
      wr_ack           : in  STD_LOGIC;
      WR_address       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      RD_address       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      RD_WR_ADDR_SEL   : OUT STD_LOGIC;
      FEMB_BRD         : OUT std_logic_vector(3 downto 0);
      FEMB_RD_strb     : OUT STD_LOGIC;
      FEMB_WR_strb     : OUT STD_LOGIC;
      FEMB_RDBK_strb   : IN  STD_LOGIC;
      FEMB_RDBK_DATA   : IN  STD_LOGIC_VECTOR(31 DOWNTO 0));
  end component UDP_IO;

  component localFlash is
    port (
      clk_40Mhz : in    std_logic;
      SCL       : inout   std_logic;
      SDA       : inout std_logic;
      monitor   : out   localFlash_monitor_t;
      control   : in    localFlash_control_t);
  end component localFlash;

  component TempSensor is
    port (
      clk_40Mhz : in  std_logic;
      CS_N      : out std_logic;
      SCLK      : out std_logic;
      SDA       : in  std_logic;
      start     : in  std_logic;
      temp      : out std_logic_vector(31 downto 0);
      busy      : out std_logic);
  end component TempSensor;

  component DTS is
    port (
      clk_sys_50Mhz       : in    std_logic;
      reset               : in    std_logic;
      DTS_CDS_SOURCE      : out   std_logic;
      DTS_CDS_LOL         : in    std_logic;
      DTS_CDS_LOS         : in    std_logic;
      DTS_CDS_SCL         : inout std_logic;
      DTS_CDS_SDA         : inout std_logic;
      DTS_SI5344_SCL      : inout std_logic;
      DTS_SI5344_SDA      : inout std_logic;
      DTS_SI5344_INT_N    : in    std_logic;
      DTS_SI5344_OE_N     : out   std_logic;
      DTS_SI5344_RST_N    : out   std_logic;
      DTS_SI5344_LOL_N    : in    std_logic;
      DTS_SI5344_LOS_N    : in    std_logic;
      DTS_SI5344_IN_SEL   : out   std_logic_vector(1 downto 0);
      DUNE_clk_in_P       : in    std_logic;
      DUNE_clk_out_P      : out   std_logic;
      DTS_data_clk_P      : in    std_logic;
      DTS_data_P          : in    std_logic;
      DTS_FP_CLK_OUT_DSBL : out   std_logic;
      DTS_FP_CLK_OUT      : out   std_logic;
      WIB_ID              : in    WIB_ID_t;
      clk_DUNE            : out   std_logic;
      locked_DUNE         : out   std_logic;
      reset_DUNE          : out   std_logic;
      ready_DUNE          : out   std_logic;
      convert_DUNE        : out   convert_t;
      reset_FEMB_Convert_count : in std_logic;
      clk_FEMB_128Mhz     : in    std_logic;
      convert_FEMB        : out   convert_t;
      clk_EB              : in    std_logic;
      convert_EB          : out   convert_array_t;
      convert_EB_acks     : in    std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
      monitor             : out   DTS_Monitor_t;
      control             : in    DTS_Control_t);
  end component DTS;

  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;
  component FEMB_CnC is
    port (
      clk_DTS_FEMB_100Mhz : in std_logic;
      clk_PDTS            : in std_logic;
      clk_out       : out std_logic;
      reset         : in  std_logic;
      cmd_start           : in std_logic; -- pulse
      cmd_stop            : in std_logic; -- pulse
      cmd_calibrate       : in std_logic; -- pulse
      cmd_timestamp_reset : in std_logic; -- pulse  
      COLDATA_cmd   : out std_logic;
      COLDATA_cmd_sel : out std_logic;
      COLDATA_clk_sel : out std_logic;
      monitor       : out FEMB_CNC_Monitor_t;
      control       : in  FEMB_CNC_Control_t);
  end component FEMB_CnC;
  
  component FEMB_DAQ is
    port (
      reset       : in  std_logic;
      clk_FEMB    : in  std_logic;
--      clk_FEMB    : out std_logic;
      reset_FEMB  : in  std_logic;
      convert     : in  convert_t;
      Rx          : in  std_logic_vector((FEMB_COUNT*4) - 1 downto 0);
      Rx_refclk   : in  std_logic_vector(1 downto 0);
      Rx_LOS_n    : in  std_logic_vector((FEMB_COUNT*4) - 1 downto 0);
      clk_EVB     : in  std_logic;
      reset_EVB   : in  std_logic;
      CD_stream   : out CD_stream_array_t(FEMB_COUNT*4 downto 1);
      CD_read     : in  std_logic_vector(FEMB_COUNT*4 downto 1);
      monitor     : out FEMB_DAQs_Monitor_t;
      control     : in  FEMB_DAQs_Control_t;
      DQM         : out FEMB_DQM_t);
  end component FEMB_DAQ;

  component WIB_FEMB_COMM_TOP is
    port (
      RESET              : IN    STD_LOGIC;
      SYS_CLK            : IN    STD_LOGIC;
      FEMB_wr_strb       : IN    STD_LOGIC;
      FEMB_rd_strb       : IN    STD_LOGIC;
      FEMB_address       : IN    STD_LOGIC_VECTOR(15 downto 0);
      FEMB_BRD           : IN    STD_LOGIC_VECTOR(3 downto 0);
      FEMB_DATA_TO_FEMB  : IN    STD_LOGIC_VECTOR(31 downto 0);
      FEMB_DATA_RDY      : OUT   STD_LOGIC;
      FEMB_DATA_FRM_FEMB : OUT   STD_LOGIC_VECTOR(31 downto 0);
      FEMB_SCL_BRDO      : OUT   STD_LOGIC;
      FEMB_SDA_BRD0_P    : INOUT STD_LOGIC;
      FEMB_SDA_BRD0_N    : INOUT STD_LOGIC;
      FEMB_SCL_BRD1      : OUT   STD_LOGIC;
      FEMB_SDA_BRD1_P    : INOUT STD_LOGIC;
      FEMB_SDA_BRD1_N    : INOUT STD_LOGIC;
      FEMB_SCL_BRD2      : OUT   STD_LOGIC;
      FEMB_SDA_BRD2_P    : INOUT STD_LOGIC;
      FEMB_SDA_BRD2_N    : INOUT STD_LOGIC;
      FEMB_SCL_BRD3      : OUT   STD_LOGIC;
      FEMB_SDA_BRD3_P    : INOUT STD_LOGIC;
      FEMB_SDA_BRD3_N    : INOUT STD_LOGIC);
  end component WIB_FEMB_COMM_TOP;
  
  component EventBuilder is
    generic (
      FEMB_COUNT : integer;
      RCE_LINK_FIRMWARE   : integer := 1);
    port (
      clk_sys        : in  std_logic;
      reset_sys      : in  std_logic;
      reset_DAQ      : in  std_logic;
      QSFP_Rx             : in std_logic;
      clk_rx_ref          : in std_logic;
      clk_rx_out          : out std_logic;
      clk_ref        : in  std_logic;
      QSFP_Tx        : out std_logic_vector(FEMB_COUNT -1 downto 0);
      QSFP_RST_N          : out   std_logic;      -- 2.5V, default
      QSFP_LOW_POWER_MODE : out std_logic;
      QSFP_INT_N          : in  std_logic;
      QSFP_PRESENT_N      : in  std_logic;
      QSFP_I2C_SEL_N      : out   std_logic;     -- 2.5V
      QSFP_SCL            : inout   std_logic;      -- 2.5V, default   
      QSFP_SDA            : inout std_logic;      -- 2.5V, default
--      QSFP_SDA_EN         : out   std_logic;
      DAQ_LINK_SI5342_LOL_N     : in std_logic;
      DAQ_LINK_SI5342_LOSXAXB_N : in std_logic;
      DAQ_LINK_SI5342_LOS1_N    : in std_logic;
      DAQ_LINK_SI5342_LOS2_N    : in std_logic;
      DAQ_LINK_SI5342_LOS3_N    : in std_logic;
      DAQ_LINK_SI5342_OE_N      : out std_logic;
      DAQ_LINK_SI5342_RESET_N   : out std_logic;
      DAQ_LINK_SI5342_INT_N     : in std_logic;
      DAQ_LINK_SI5342_SCL       : inout std_logic;
      DAQ_LINK_SI5342_SDA       : inout std_logic;
      DAQ_LINK_SI5342_SDA_EN    : out std_logic;
      DAQ_LINK_SI5342_SEL0      : out std_logic;
      DAQ_LINK_SI5342_SEL1      : out std_logic;
      WIB_ID      : in  WIB_ID_t;
      converts     : in  convert_array_t;
      covnert_acks : out std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
      CD_stream : in  CD_stream_array_t(FEMB_COUNT*4 downto 1);
      CD_read   : out std_logic_vector(FEMB_COUNT*4 downto 1);
      clk_EVB     : out std_logic;
      clk_EVB_locked : out std_logic;
      monitor     : out EB_Monitor_t;
      control     : in  EB_Control_t);
  end component EventBuilder;

  component DQM is
    port (
      clk_128Mhz  : in  std_logic;
      reset       : in  std_logic;
      convert     : in  convert_t;
      WIB_ID      : in  WIB_ID_t;
      packet_out  : out DQM_Packet_t;
      packet_free : in  std_logic;
      monitor     : out DQM_Monitor_t;
      control     : in  DQM_Control_t;
      DQM         : in  FEMB_DQM_t);
  end component DQM;

  component WIB_PWR_MON is
    port (
      rst          : IN    STD_LOGIC;
      clk          : IN    STD_LOGIC;
      monitor                         : out   WIB_PWR_Monitor_t;
      control                         : in    WIB_PWR_Control_t;
      PWR_SCL_BRD  : INOUT STD_LOGIC_vector;
      PWR_SDA_BRD  : INOUT STD_LOGIC_vector;
      PWR_SCL_BIAS : INOUT STD_LOGIC;
      PWR_SDA_BIAS : INOUT STD_LOGIC;
      PWR_SCL_WIB  : inout STD_LOGIC;
      PWR_SDA_WIB  : inout STD_LOGIC);
  end component WIB_PWR_MON;

  component FLASH_loader is
    port (
      noe_in              : in  std_logic                    := 'X';
      dclk_in             : in  std_logic                    := 'X';
      ncso_in             : in  std_logic                    := 'X';
      data_in             : in  std_logic_vector(3 downto 0) := (others => 'X');
      data_oe             : in  std_logic_vector(3 downto 0) := (others => 'X');
      asmi_access_granted : in  std_logic                    := 'X';
      data_out            : out std_logic_vector(3 downto 0);
      asmi_access_request : out std_logic);
  end component FLASH_loader;
  
  component Flash is
    port (
      clk_25Mhz : in  std_logic;
      clk_10Mhz : in  std_logic;
      reset     : in  std_logic;
--      AS_DATA   : inout std_logic_vector(3 downto 0);
--      AS_CLK    : out std_logic;
--      AS_NCS    : out std_logic;
      asmi_dataout  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- asmi_dataout
      asmi_dclk     : out std_logic;                                        -- asmi_dclk
      asmi_scein    : out std_logic;                                        -- asmi_scein
      asmi_sdoin    : out std_logic_vector(3 downto 0);                     -- asmi_sdoin
      asmi_dataoe   : out std_logic_vector(3 downto 0);                      -- asmi_dataoe   
 
      monitor   : out Flash_monitor_t;
      control   : in  Flash_control_t);
  end component Flash;

  signal DAQ_refclk   : std_logic := '0';   

  
  signal clk_FEMB_128Mhz         : std_logic;
  signal clk_DUNE                : std_logic;
  signal clk_SBND                : std_logic;
  signal clk_100Mhz              : std_logic;
  signal clk_50Mhz               : std_logic;
  signal clk_40Mhz : std_logic;
  signal clk_UDP_IO : std_logic;
  signal clk_flash : std_logic;
  signal clk_reconfig : std_logic;
  signal clk_FEMB_CNC : std_logic := '0';
  signal clk_dune_100Mhz : std_logic;
  
  signal FEMB_locked    : std_logic := '0';
  signal sys_pll_locked : std_logic;
  signal EVB_locked     : std_logic := '0';
  signal EVB_locked_n : std_logic := '1';
  signal locked_DUNE                : std_logic;
  
  signal sys_reset   : std_logic;
  signal GLB_i_RESET : std_logic;
  signal GLB_RESET   : std_logic;
  signal REG_RESET   : std_logic;
  signal UDP_RESET   : std_logic;
  signal ALG_RESET   : std_logic;
  signal FEMB_reset  : std_logic := '1';
  signal DCC_locked  : std_logic;
  signal FEMB_PLL_locked_n : std_logic := '1';
  signal flash_reset : std_logic := '0';

  signal asmi_dataout : std_logic_vector(3 downto 0); -- asmi_dataout
  signal asmi_dclk    : std_logic;                                          -- asmi_dclk
  signal asmi_scein   : std_logic;                                        -- asmi_scein
  signal asmi_sdoin   : std_logic_vector(3 downto 0);                     -- asmi_sdoin
  signal asmi_dataoe  : std_logic_vector(3 downto 0);                      -- asmi_dataoe   
  signal asmi_access_granted : std_logic;
  
  signal reset_FEMB_Convert_count : std_logic;
  
  signal start_udp_mac        : std_logic;
  signal UDP_FRAME_SIZE       : std_logic_vector(11 downto 0);
  signal UDP_TIME_OUT_wait    : std_logic_vector(31 downto 0);
  signal UDP_header_user_info : std_logic_vector(31 downto 0);
  signal packet_free          : std_logic := '0';
  signal tx_fifo_used : std_logic_vector(11 downto 0) := (others => '0');
  signal RD_WR_ADDR_SEL       : std_logic;
  signal rd_strb              : std_logic;
  signal wr_strb              : std_logic;
  signal udp_rd_ack           : std_logic;
  signal udp_wr_ack           : std_logic;
  signal WR_address           : std_logic_vector(15 downto 0);
  signal RD_address           : std_logic_vector(15 downto 0);
  signal data                 : std_logic_vector(31 downto 0);
  signal rdout                : std_logic_vector(31 downto 0);

  signal DAQ_LINK_SI5342_SDA_local : std_logic;
  signal DAQ_LINK_SI5342_SDA_EN    : std_logic;

  signal CD_stream     : CD_stream_array_t(LINK_COUNT downto 1);
  signal CD_read       : std_logic_vector(LINK_COUNT downto 1);
--  signal FEMB_data       : data_8b10b_t(LINK_COUNT -1 downto 0);
--  signal FEMB_data_valid : std_logic_vector(LINK_COUNT-1 downto 0);

  signal clk_EVB   : std_logic := '0';
  signal EVB_reset : std_logic := '0';  
  
  signal convert_FEMB : convert_t;
  signal convert_EB   : convert_array_t;
  signal convert_DUNE : convert_t;
  signal convert_EB_acks : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
  signal ready_PDTS : std_logic;
  
  signal DTS_Monitor  : DTS_Monitor_t;
  signal DTS_Control  : DTS_Control_t;
  signal WIB_Monitor  : WIB_Monitor_t;
  signal WIB_Control  : WIB_Control_t;
  signal FEMB_DAQ_control : FEMB_DAQs_control_t;
  signal FEMB_DAQ_monitor : FEMB_DAQs_monitor_t;
  signal FEMB_DQM     : FEMB_DQM_t;
  signal EB_Monitor   : EB_Monitor_t;
  signal EB_Control   : EB_Control_t;
  signal DQM_Monitor  : DQM_Monitor_t;
  signal DQM_Control  : DQM_Control_t;
  signal DQM_packet   : DQM_packet_t := DEFAULT_DQM_PACKET;
  signal FEMB_CNC_monitor : FEMB_CNC_Monitor_t;
  signal FEMB_CNC_control : FEMB_CNC_Control_t;
  signal Flash_Monitor : Flash_monitor_t;
  signal Flash_Control : Flash_control_t;
  signal localFlash_control : localFlash_control_t;
  signal localFlash_monitor : localFlash_monitor_t;
  signal UDP_Monitor : UDP_Monitor_t;
  signal UDP_Control : UDP_Control_t;
  signal WIB_PWR_Monitor : WIB_PWR_Monitor_t;
  signal WIB_PWR_Control : WIB_PWR_Control_t;
  
  
  signal FEMB_SC_wr_strb : std_logic := '0';
  signal FEMB_SC_rd_strb : std_logic := '0';
  signal FEMB_SC_readback_strb : std_logic := '0';
  signal FEMB_SC_readback_data : std_logic_vector(31 downto 0) := x"deadbeef";
  signal FEMB_SC_board : std_logic_vector(3 downto 0) := x"0";
  
--  signal clk_refclk : std_logic;

  signal DTS_OUT_DSBL : std_logic;
  

  signal QSFP_Tx : std_logic_vector(DAQ_LINK_COUNT -1 downto 0) := (others => '0');
  signal QSFP_SDA_local : std_logic;
  signal QSFP_SDA_OE : std_logic := '0';
  signal Rx_refclk : std_logic := '0';
  

  signal ip_address           : STD_LOGIC_VECTOR(31 downto 0);
  signal mac_address          : STD_LOGIC_VECTOR(47 downto 0);
  signal sub_address          : unsigned(7 downto 0) := x"00";

  type ip_byte_slot_table_t is array (0 to 5) of std_logic_vector(7 downto 0);
  type ip_byte_crate_table_t is array (0 to 9) of ip_byte_slot_table_t;
  constant IP_BYTE_LOOKUP : ip_byte_crate_table_t := ((x"14",x"15",x"16",x"17",x"18",x"00"), --Crate0
                                                      (x"1a",x"1b",x"1c",x"1d",x"1e",x"00"), --crate1
                                                      (x"1f",x"20",x"21",x"22",x"23",x"00"), --crate2
                                                      (x"24",x"25",x"26",x"27",x"28",x"00"), --crate3
                                                      (x"29",x"2a",x"2b",x"2c",x"2d",x"00"), --crate4
                                                      (x"2e",x"2f",x"30",x"37",x"31",x"00"), --crate5
                                                      (x"32",x"33",x"34",x"35",x"36",x"00"), --crate6
                                                      (x"00",x"00",x"00",x"00",x"00",x"00"), --crate7
                                                      (x"14",x"15",x"16",x"17",x"18",x"19"), --crate8 (FNAL)
                                                      (x"28",x"29",x"2a",x"2b",x"2c",x"00")  --crate9
                                                      );


  signal FEMB_CMD : std_logic;

  signal DTS_FP_CLK_OUT_DSBL_local : std_logic;
  signal DTS_BP_OUT_DSBL_local  : std_logic_vector(5 downto 0);

  
begin

  -----------------------------------------------------------------
  -- WIB ID
  -----------------------------------------------------------------
  WIB_Monitor.FEMB_COUNT <= std_logic_vector(to_unsigned(FEMB_COUNT,4));
  WIB_Monitor.DAQ_LINK_COUNT <= std_logic_vector(to_unsigned(DAQ_LINK_COUNT,4));
  WIB_Monitor.real_ID.slot <= SLOT_ADDR;
  WIB_Monitor.real_ID.crate <= CRATE_ADDR;
  WIB_Monitor.use_fake_ID <= WIB_Control.use_fake_ID;
  WIB_Monitor.fake_ID <= WIB_Monitor.real_ID;
  WIB_ID_control: process (clk_50Mhz) is
  begin  -- process WIB_ID_control
    if clk_50Mhz'event and clk_50Mhz = '1' then  -- rising clock edge
      if WIB_Control.use_fake_ID = '0' then
        WIB_Monitor.ID  <= WIB_Monitor.real_ID;
      else
        WIB_Monitor.ID  <= WIB_Monitor.fake_ID;
      end if;
    end if;
  end process WIB_ID_control;
  
  -----------------------------------------------------------------
  -- System clocking
  -----------------------------------------------------------------

  sys_pll_inst : sys_pll
    port map(
      refclk   => clk_in_50Mhz,
      rst      => '0',
      outclk_0 => clk_50Mhz,
      outclk_1 => clk_100Mhz,
      outclk_2 => clk_40Mhz,
      outclk_3 => clk_flash,
      outclk_4 => clk_reconfig,
      locked   => sys_pll_locked
      );
  sys_reset              <= not sys_pll_locked;
  WIB_Monitor.sys_locked <= sys_pll_locked;
  clk_UDP_IO             <= clk_100Mhz;

  REFCLK_PLL_2: REFCLK_PLL
    port map (
      refclk   => clk_50Mhz,
      rst      => '0',
      outclk_0 => Rx_refclk);

  
  WIB_Monitor.reset_FEMB_PLL <= WIB_Control.reset_FEMB_PLL;
  clk_dune_100Mhz <= DTS_FEMB_clk_P; ---test
  DCC_FEMB_PLL_1 : DCC_FEMB_PLL
    port map (
      refclk   => DTS_FEMB_clk_P,--clk_FEMB_128Mhz_P,
      rst      => WIB_Control.reset_FEMB_PLL,
      outclk_0 => clk_FEMB_128Mhz,
      outclk_1 => open,--clk_dune_100Mhz,
      locked   => FEMB_locked);
--  FEMB_locked <= FEMB_DAQ_monitor.FEMB(1).Rx.rx_is_lockedtoref(1);
  
  SYS_RST_inst : sys_rst
    port map(clk      => clk_50Mhz,
             reset_in => sys_reset,
             start    => start_udp_mac,
             RST_OUT  => GLB_RESET);


  WIB_monitor.GLB_i_Reset <= GLB_i_Reset;
  GLB_i_RESET             <= GLB_RESET;  --WIB_control.GLB_i_RESET;


  reseter_1: entity work.reseter
    port map (
      clk         => clk_UDP_IO,
      reset_async => GLB_RESET,
      reset_sync  => WIB_control.REG_RESET,
      reset       => REG_RESET);
  WIB_monitor.REG_RESET   <= REG_RESET;
  
  reseter_2: entity work.reseter
    port map (
      clk         => clk_UDP_IO,
      reset_async => GLB_RESET,
      reset_sync  => WIB_control.UDP_RESET,
      reset       => UDP_RESET);
  WIB_monitor.UDP_RESET   <= UDP_RESET;
  
  reseter_3: entity work.reseter
    port map (
      clk         => clk_40Mhz,
      reset_async => GLB_RESET,
      reset_sync  => WIB_control.ALG_RESET,
      reset       => ALG_RESET);
  WIB_monitor.ALG_RESET   <= ALG_RESET;
  
  FEMB_PLL_locked_n   <= not (sys_pll_locked and FEMB_locked);  
  reseter_4: entity work.reseter
    generic map (
      DEPTH => 5) --4 (this is a good guess, but it shouldn't matter exactly
                  --what it is. 4 since this is about 2 times faster than evb
                  --clock for RCE. Should this change for FELIX? 
    port map (
      clk         => clk_FEMB_128Mhz,
      reset_async => FEMB_PLL_locked_n or WIB_control.DAQ_PATH_RESET,
      reset_sync  => '0',
      reset       => FEMB_RESET);
  WIB_Monitor.FEMB_locked <= not FEMB_PLL_locked_n;  
  
  EVB_locked_n <= not (EVB_locked);
  reseter_5: entity work.reseter
    port map (
      clk         => clk_EVB,
      reset_async => EVB_locked_n or WIB_control.DAQ_PATH_RESET,
      reset_sync  => WIB_control.EVB_reset,
      reset       => EVB_reset);
  WIB_Monitor.EB_locked <= EVB_locked;

  WIB_monitor.DAQ_PATH_RESET <= WIB_control.DAQ_PATH_RESET;
  
  reseter_6: entity work.reseter
    port map (
      clk         => clk_flash,
      reset_async => '0',
      reset_sync  => sys_reset,
      reset       => flash_reset);

  WIB_Monitor.DCC_locked <= locked_DUNE;

  LED_SWITCH_RCE: if CDAS_PER_DAQ_LINK = 2 generate
    LED(7)          <= not EB_Monitor.DAQ_Link_EB(4).sending_data;
    LED(6)          <= not EB_Monitor.DAQ_Link_EB(3).sending_data;    
  end generate LED_SWITCH_RCE;
  LED_SWITCH_FELIX: if CDAS_PER_DAQ_LINK = 4 generate
    LED(7)          <= '1';
    LED(6)          <= '1';
  end generate LED_SWITCH_FELIX;
  LED(5)          <= not EB_Monitor.DAQ_Link_EB(2).sending_data;
  LED(4)          <= not EB_Monitor.DAQ_Link_EB(1).sending_data;
  LED(3 downto 0) <= not (convert_FEMB.trigger &        
                          DCC_locked &
                          FEMB_locked &
                          sys_pll_locked);


  localFlash_1: entity work.localFlash
    port map (
      clk_40Mhz => clk_40Mhz,
      SCL       => LFLASH_SCL,
      SDA       => LFLASH_SDA,
      monitor   => localFlash_monitor,
      control   => localFlash_control);

  TempSensor_1: entity work.TempSensor
    port map (
      clk_40Mhz => clk_40Mhz,
      CS_N      => TS_CS_N,
      SCLK      => TS_SCLK,
      SDA       => TS_SDA,
      start     => WIB_Control.TempSensor.start,
      temp      => WIB_Monitor.TempSensor.temp,
      busy      => WIB_Monitor.TempSensor.busy);
  
  -----------------------------------------------------------------
  -- FEMB Power
  -----------------------------------------------------------------
  WIB_Monitor.Power.EN_3V6  <= WIB_Control.Power.EN_3V6;
  WIB_Monitor.Power.EN_2V8  <= WIB_Control.Power.EN_2V8;
  WIB_Monitor.Power.EN_2V5  <= WIB_Control.Power.EN_2V5;
  WIB_Monitor.Power.EN_1V5  <= WIB_Control.Power.EN_1V5;
  WIB_Monitor.Power.EN_BIAS <= WIB_Control.Power.EN_BIAS;
  WIB_Monitor.Power.EN_BIAS_MASTER <= WIB_Control.Power.EN_BIAS_MASTER;
  PWR_EN_3V6  <= WIB_Control.Power.EN_3V6;
  PWR_EN_2V8  <= WIB_Control.Power.EN_2V8;
  PWR_EN_2V5  <= WIB_Control.Power.EN_2V5;
  PWR_EN_1V5  <= WIB_Control.Power.EN_1V5;
  PWR_EN_BIAS <= WIB_Control.Power.EN_BIAS;
  PWR_EN_BIAS_MASTER <= WIB_Control.Power.EN_BIAS_MASTER;
  
  WIB_Monitor.Power.measurement_select <= WIB_Control.Power.measurement_select;
  WIB_PWR_MON_1: entity work.WIB_PWR_MON
    port map (
      rst          => ALG_RESET,
      clk          => clk_40Mhz,
      monitor      => WIB_PWR_Monitor,
      control      => WIB_PWR_Control,
      
      PWR_SCL_BRD  => PWR_SCL(3 downto 0),
      PWR_SDA_BRD  => PWR_SDA(3 downto 0),
      PWR_SCL_BIAS => PWR_SCL(4),
      PWR_SDA_BIAS => PWR_SDA(4),
      PWR_SCL_WIB  => PWR_WIB_SCL,
      PWR_SDA_WIB  => PWR_WIB_SDA);

  -----------------------------------------------------------------
  -- FPGA Flash control
  -----------------------------------------------------------------
  FLASH_loader_1: FLASH_loader
    port map (
      noe_in              => '0',
      dclk_in             => asmi_dclk,
      ncso_in             => asmi_scein,
      data_in             => asmi_sdoin,
      data_oe             => asmi_dataoe,
      asmi_access_granted => asmi_access_granted,--'0', --2018-06-26
      data_out            => asmi_dataout,
      asmi_access_request => asmi_access_granted);--open);
  
  Flash_2: entity work.Flash
    port map (
      clk_25Mhz => clk_flash,
      clk_10Mhz => clk_reconfig,
      reset     => flash_reset,
      asmi_dataout => asmi_dataout,   
      asmi_dclk    => asmi_dclk,     
      asmi_scein   => asmi_scein,    
      asmi_sdoin   => asmi_sdoin,    
      asmi_dataoe  => asmi_dataoe,         
--      AS_DATA   => AS_DATA,
--      AS_CLK    => AS_CLK,
--      AS_NCS    => AS_NCS,
      monitor   => Flash_monitor,
      control   => Flash_control);
  
  -----------------------------------------------------------------
  -- GbE interface
  -----------------------------------------------------------------
--  packet_free <= not or_reduce(tx_fifo_used);
  packet_free <= tx_fifo_used(0); -- hiding empty in tx_fifo_used(0)

  sub_address(7 downto 4) <= x"0";
  sub_address(3 downto 0) <= unsigned(WIB_Monitor.ID.slot);
  addr: process (clk_50Mhz, sys_pll_locked) is
  begin  -- process addr
    if sys_pll_locked = '0' then
      ip_address <= x"c0a87901";
      mac_address <= x"AABBCCDDEE10";
    elsif clk_50Mhz'event and clk_50Mhz = '1' then  -- rising clock edge

      if WIB_Monitor.ID.crate = x"8" then
        --This is the FNAL setup
        ip_address(31 downto  0)  <= x"c0a87901";        --FNAL default
        ip_address( 7 downto  0)  <= IP_BYTE_LOOKUP(8)(to_integer(unsigned(WIB_Monitor.ID.slot)));

        mac_address(47 downto  0) <= x"AABBCCDDEE10";
        mac_address(11 downto  8) <= WIB_Monitor.ID.crate;
        mac_address( 7 downto  4) <= x"0";
        mac_address( 3 downto  0) <= WIB_Monitor.ID.slot;
        
      elsif ((WIB_Monitor.ID.crate = x"f" or WIB_Monitor.ID.slot = x"f") or
          (unsigned(WIB_Monitor.ID.slot) > x"5") 
          )then
        -- Not connected to a proper crate
        ip_address <= x"c0a87901"; --FNAL default
        mac_address <= x"AABBCCDDEE10";
        if WIB_Monitor.ID.slot /= x"f" then
          ip_address(15 downto  8)  <= x"c8";
          ip_address( 7 downto  4)  <= x"0";
          ip_address( 3 downto  0)  <= WIB_Monitor.ID.slot;          
          mac_address( 3 downto  0) <= WIB_Monitor.ID.slot;
        end if;
      else
        --Connected to crate at CERN
        ip_address <= x"0a498900";
        mac_address <= x"AABBCCDD0000";
        
        case WIB_Monitor.ID.crate is          
          when x"0" | x"1" | x"2" | x"3" | x"4" | x"5" | x"6" | x"9" =>
--            ip_address(7 downto 0) <= std_logic_vector(x"14" + sub_address) ;
            ip_address(7 downto 0) <= IP_BYTE_LOOKUP(to_integer(unsigned(WIB_Monitor.ID.crate)))(to_integer(unsigned(WIB_Monitor.ID.slot)));
            mac_address(11 downto  8) <= WIB_Monitor.ID.crate;
            mac_address( 3 downto  0) <= WIB_Monitor.ID.slot;
          when others => NULL;
        end case;
      end if;
    end if;
  end process addr;

  UDP_Monitor.en_readback <= UDP_Control.en_readback;
  UDP_Monitor.timeout     <= UDP_Control.timeout;
  UDP_IO_2: entity work.UDP_IO
    port map (
      reset            => UDP_RESET,
      CLK_125Mhz       => SFP_refclk_P,
      CLK_50MHz        => clk_50MHz,
      CLK_IO           => clk_UDP_IO,
      SPF_OUT          => SFP_Rx_P,
      SFP_IN           => SFP_Tx_P,
      START            => start_udp_mac,
      BRD_IP           => ip_address,
      BRD_MAC          => mac_address,
      EN_WR_RDBK       => UDP_Control.en_readback,
      TIME_OUT_wait    => UDP_Control.timeout,
      FRAME_SIZE       => UDP_Control.frame_size,--x"1F8",
      tx_fifo_clk      => clk_FEMB_128Mhz,
      tx_fifo_wr       => DQM_packet.fifo_wr,
      tx_fifo_in       => DQM_packet.fifo_data,
      tx_fifo_full     => open,
      tx_fifo_used     => tx_fifo_used,
      DQM_ip_dest_addr  => UDP_Monitor.DQM_ip_dest_addr,
      DQM_mac_dest_addr => UDP_Monitor.DQM_mac_dest_addr,  
      DQM_dest_port     => UDP_Monitor.DQM_dest_port,      
      header_user_info => DQM_packet.header_user_info,
      system_status    => DQM_packet.system_status,
      data             => data,
      rdout            => rdout,
      wr_strb          => wr_strb,
      rd_strb          => rd_strb,
      rd_ack           => udp_rd_ack,
      wr_ack           => udp_wr_ack,
      WR_address       => WR_address,
      RD_address       => RD_address,
      RD_WR_ADDR_SEL   => RD_WR_ADDR_SEL,
      FEMB_BRD         => FEMB_SC_board,
      FEMB_RD_strb     => FEMB_SC_rd_strb,
      FEMB_WR_strb     => FEMB_SC_wr_strb,
      FEMB_RDBK_strb   => FEMB_SC_readback_strb,
      FEMB_RDBK_DATA   => FEMB_SC_readback_data);

  -----------------------------------------------------------------
  -- IO
  -----------------------------------------------------------------

  register_map_1 : entity work.register_map
    generic map (
      FIRMWARE_VERSION => FW_VERSION)
    port map (
      clk_UDP      => clk_UDP_IO,
      locked_UDP   => '1',  -- Nothing is running if this clock isn't locked
      reset        => REG_RESET,
      Ver_ID       => x"00000102",
      data_in      => data,
      WR_address   => WR_address,
      RD_address   => RD_address,
      WR_strb      => WR_strb,
      RD_strb      => RD_strb,
      data_out     => rdout,
      rd_ack       => udp_rd_ack,
      wr_ack       => udp_wr_ack,
      clk_WIB      => clk_50Mhz,
      clk_EVB      => clk_EVB,
      clk_FEMB     => clk_FEMB_128Mhz,
      clk_services => clk_40Mhz,
      clk_flash    => clk_flash,
      clk_DUNE     => clk_DUNE,
      clk_FEMB_CNC => clk_FEMB_CNC,
      locked_WIB   => '1',              -- sys clock is always locked
      locked_EVB   => EVB_locked,              -- sys clock is always locked,
      locked_FEMB  => FEMB_locked,
      locked_services => '1',           -- sys clock is always locked
      locked_flash => '1', --sys clock is always locked
      locked_DUNE  => locked_DUNE,
      locked_FEMB_CNC => FEMB_locked,--FEMB_CnC_monitor.DTS_locked,
      WIB_control  => WIB_control,
      WIB_monitor  => WIB_monitor,
      Flash_control => Flash_control,
      Flash_monitor => Flash_monitor,
      localFlash_control => localFlash_control,
      localFlash_monitor => localFlash_monitor,
      DTS_control  => DTS_control,
      DTs_monitor  => DTS_monitor,
      FEMB_CnC_control => FEMB_CnC_control,
      FEMB_CnC_monitor => FEMB_CnC_monitor,
      FEMB_DAQ_control => FEMB_DAQ_control,
      FEMB_DAQ_monitor => FEMB_DAQ_monitor,
      EB_control   => EB_control,
      EB_monitor   => EB_monitor,
      DQM_Control  => DQM_Control,
      DQM_Monitor  => DQM_Monitor,
      UDP_Control  => UDP_Control,
      UDP_Monitor  => UDP_Monitor,
      WIB_PWR_Control => WIB_PWR_Control,
      WIB_PWR_Monitor => WIB_PWR_Monitor
      );





  -----------------------------------------------------------------
  -- DUNE timing system
  -----------------------------------------------------------------
  pacd_1: entity work.pacd
    port map (
      iPulseA => FEMB_CNC_control.timestamp_reset,
      iClkA   => clk_dune_100Mhz,
      iRSTAn  => '1',
      iClkB   => clk_FEMB_128Mhz,
      iRSTBn  => '1',
      oPulseB => reset_FEMB_Convert_count);

  DTS_FP_CLK_OUT_DSBL <= DTS_FP_CLK_OUT_DSBL_local;
  DTS_BP_OUT_DSBL     <= DTS_BP_OUT_DSBL_local;
  WIB_monitor.DTS_FP_CLK_OUT_DSBL <= DTS_FP_CLK_OUT_DSBL_local;
  WIB_monitor.DTS_BP_OUT_DSBL     <= DTS_BP_OUT_DSBL_local;

  PDTS_TX_DISBLE: process (DTS_OUT_DSBL) is
  begin  -- process PDTS_TX_DISBLE
    DTS_FP_CLK_OUT_DSBL_local                               <= DTS_OUT_DSBL;
    DTS_BP_OUT_DSBL_local                                   <= (others => 'Z');
    if DTS_OUT_DSBL = '0' then
      DTS_BP_OUT_DSBL_local(to_integer(unsigned(SLOT_ADDR)))  <= '0';
    else
      DTS_BP_OUT_DSBL_local(to_integer(unsigned(SLOT_ADDR)))  <= 'Z';
    end if;
--    DTS_BP_OUT_DSBL_local(to_integer(unsigned(SLOT_ADDR)))  <= '0';--DTS_OUT_DSBL;    
  end process PDTS_TX_DISBLE;

--  DTS_FP_CLK_OUT_P <= clk_50Mhz; --2018-09-20
  DTS_1: entity work.DTS
    port map (
      clk_sys_50Mhz       => clk_50Mhz,
      reset               => '0',
      DTS_CDS_SOURCE      => DTS_CDS_SOURCE,
      DTS_CDS_LOL         => DTS_CDS_LOL,
      DTS_CDS_LOS         => DTS_CDS_LOS,
      DTS_CDS_SCL         => DTS_CDS_SCL,
      DTS_CDS_SDA         => DTS_CDS_SDA,
      DTS_SI5344_SCL      => DTS_SI5344_SCL,
      DTS_SI5344_SDA      => DTS_SI5344_SDA,
      DTS_SI5344_INT_N    => DTS_SI5344_INT_N,
      DTS_SI5344_OE_N     => DTS_SI5344_OE_N,
      DTS_SI5344_RST_N    => DTS_SI5344_RST_N,
      DTS_SI5344_LOL_N    => DTS_SI5344_LOL_N,
      DTS_SI5344_LOS_N    => DTS_SI5344_LOS_N,
      DTS_SI5344_IN_SEL   => DTS_SI5344_IN_SEL,
      DUNE_clk_in_P       => DUNE_clk_in_P,
      DUNE_clk_out_P      => open,--DUNE_clk_out_P,
      DTS_data_clk_P      => DTS_data_clk_P,
      DTS_data_P          => DTS_data_P,
      DTS_FP_CLK_OUT_DSBL => DTS_OUT_DSBL,
      DTS_FP_CLK_OUT      => DTS_FP_CLK_OUT_P, -- 2018-09-20
      WIB_ID              => WIB_Monitor.ID,
      clk_DUNE            => clk_DUNE,
      locked_DUNE         => locked_DUNE,
      reset_DUNE          => open,
      ready_DUNE          => ready_PDTS, --open,
      reset_FEMB_Convert_count => reset_FEMB_Convert_count,
      convert_DUNE        => convert_DUNE,
      clk_FEMB_128Mhz     => clk_FEMB_128Mhz,
      convert_FEMB        => convert_FEMB,
      clk_EB              => clk_EvB,
      convert_EB          => convert_EB,
      convert_EB_acks     => convert_EB_acks,
      monitor             => DTS_monitor,
      control             => DTS_control);
  
  -----------------------------------------------------------------
  -- FEMB clock and control
  -----------------------------------------------------------------
--  DTS_FPGA_CLK_P <= clk_100Mhz; -- HW switch selects the real 100Mhz
  DUNE_clk_out_P <= clk_FEMB_CNC;
--  LEMO_OUT <= not FEMB_CMD;
--  LEMO_OUT2 <= not clk_FEMB_CNC;
  DCC_FPGA_CMD_P <= FEMB_CMD;
  FEMB_CnC_1: entity work.FEMB_CnC
    port map (
      clk_DTS_FEMB_100Mhz => clk_dune_100Mhz,--DTS_FEMB_clk_P,
      clk_PDTS            => clk_DUNE,
      clk_out       => clk_FEMB_CNC,
      reset         => not ready_PDTS,--'0',
      cmd_start   => convert_DUNE.cmd_start,           
      cmd_stop => convert_DUNE.cmd_stop,            
      cmd_calibrate      => convert_DUNE.cmd_calibrate,       
      cmd_timestamp_reset     => convert_DUNE.cmd_timestamp_reset, 
      COLDATA_cmd   => FEMB_CMD,--DCC_FPGA_CMD_P,
      COLDATA_cmd_sel => DCC_CMD_SEL,--FEMB_CLK_SEL,
      COLDATA_clk_sel => FEMB_CLK_SEL,--DCC_CMD_SEL,
      monitor       => FEMB_CnC_monitor,
      control       => FEMB_CnC_control);
  
  -----------------------------------------------------------------
  -- FEMB DAQ
  -----------------------------------------------------------------

  FEMBs : entity work.FEMB_DAQ
    port map (
      reset       => FEMB_PLL_locked_n,
      clk_FEMB    => clk_FEMB_128Mhz,
      reset_FEMB  => FEMB_reset,
      convert     => convert_FEMB,
      Rx          => FEMB_Rx_P,
      Rx_refclk   => FEMB_Rx_refclk_P,
      Rx_LOS_n    => FEMB_LOS_n,
      clk_EVB     => clk_EVB,
      reset_EVB   => EVB_reset,
      CD_stream => CD_stream,
      CD_read   => CD_read,
      monitor     => FEMB_DAQ_monitor,
      control     => FEMB_DAQ_control,
      DQM         => FEMB_DQM);

  WIB_FEMB_COMM_TOP_1: entity work.WIB_FEMB_COMM_TOP
    port map (
      RESET              => ALG_RESET,
      SYS_CLK            => clk_100Mhz,
      FEMB_wr_strb       => FEMB_SC_wr_strb,
      FEMB_rd_strb       => FEMB_SC_rd_strb,
      FEMB_address       => WR_address,
      FEMB_BRD           => FEMB_SC_board,
      FEMB_DATA_TO_FEMB  => data,
      FEMB_DATA_RDY      => FEMB_SC_readback_strb,
      FEMB_DATA_FRM_FEMB => FEMB_SC_readback_data,
      FEMB_SCL_BRDO      => FEMB_SCL(0),
      FEMB_SDA_BRD0_P    => FEMB_SDA_P(0),
      FEMB_SDA_BRD0_N    => FEMB_SDA_N(0),
      FEMB_SCL_BRD1      => FEMB_SCL(1),
      FEMB_SDA_BRD1_P    => FEMB_SDA_P(1),
      FEMB_SDA_BRD1_N    => FEMB_SDA_N(1),
      FEMB_SCL_BRD2      => FEMB_SCL(2),
      FEMB_SDA_BRD2_P    => FEMB_SDA_P(2),
      FEMB_SDA_BRD2_N    => FEMB_SDA_N(2),
      FEMB_SCL_BRD3      => FEMB_SCL(3),
      FEMB_SDA_BRD3_P    => FEMB_SDA_P(3),
      FEMB_SDA_BRD3_N    => FEMB_SDA_N(3));
  
  QSFP_Tx_P <= QSFP_Tx;

  DAQ_CLOCK_SWITCH_RCE: if CDAS_PER_DAQ_LINK = 2 generate
--    DAQ_refclk <= RCE_Tx_refclk_P;
	 DAQ_refclk <= FELIX_Tx_refclk_P;
  end generate DAQ_CLOCK_SWITCH_RCE;
  DAQ_CLOCK_SWITCH_FELIX: if CDAS_PER_DAQ_LINK = 4 generate
    DAQ_refclk <= FELIX_Tx_refclk_P;
  end generate DAQ_CLOCK_SWITCH_FELIX;

--  tri_state_buffer_SI5342 : TRI
--    port map (
--      a_in  => DAQ_LINK_SI5342_SDA_local,
--      oe    => DAQ_LINK_SI5342_SDA_EN,
--      a_out => DAQ_LINK_SI5342_SDA);

--  tri_state_buffer_QSFP : TRI
--    port map (
--      a_in  => QSFP_SDA_local,
--      oe    => QSFP_SDA_OE,
--      a_out => QSFP_SDA);

  EventBuilder_1 : entity work.EventBuilder
    port map (
      clk_sys     => clk_50Mhz,
      reset_sys   => GLB_RESET,
      reset_DAQ   => EVB_reset,
      QSFP_Rx     => '0',
      clk_rx_ref  => Rx_refclk,
      clk_rx_out  => refclk_out,

      clk_ref     => DAQ_refclk,
      QSFP_RST_N          => QSFP_RST_N,          
      QSFP_LOW_POWER_MODE => QSFP_LOW_POWER_MODE,
      QSFP_INT_N          => QSFP_INT_N,          
      QSFP_PRESENT_N      => QSFP_PRESENT_N,      
      QSFP_I2C_SEL_N      => QSFP_I2C_SEL_N,      
      QSFP_SCL            => QSFP_SCL,              
      QSFP_SDA            => QSFP_SDA,--QSFP_SDA_local,            
--      QSFP_SDA_EN         => QSFP_SDA_OE,         
      DAQ_LINK_SI5342_LOL_N     => DAQ_LINK_SI5342_LOL_N,    
      DAQ_LINK_SI5342_LOSXAXB_N => DAQ_LINK_SI5342_LOSXAXB_N,    
      DAQ_LINK_SI5342_LOS1_N    => DAQ_LINK_SI5342_LOS1_N,
      DAQ_LINK_SI5342_LOS2_N    => DAQ_LINK_SI5342_LOS2_N,
      DAQ_LINK_SI5342_LOS3_N    => DAQ_LINK_SI5342_LOS3_N,
      DAQ_LINK_SI5342_OE_N      => DAQ_LINK_SI5342_OE_N,
      DAQ_LINK_SI5342_RESET_N   => DAQ_LINK_SI5342_RESET_N,
      DAQ_LINK_SI5342_INT_N     => DAQ_LINK_SI5342_INT_N,
      DAQ_LINK_SI5342_SCL      => DAQ_LINK_SI5342_SCL,    
      DAQ_LINK_SI5342_SDA      => DAQ_LINK_SI5342_SDA,--DAQ_LINK_SI5342_SDA_local,       
--      DAQ_LINK_SI5342_SDA_EN => DAQ_LINK_SI5342_SDA_EN, 
      DAQ_LINK_SI5342_SEL0     => DAQ_LINK_SI5342_SEL0,
      DAQ_LINK_SI5342_SEL1     => DAQ_LINK_SI5342_SEL1,
      QSFP_Tx     => QSFP_Tx(DAQ_LINK_COUNT-1 downto 0),
      WIB_ID      => WIB_Monitor.ID,
      converts     => convert_EB,
      convert_acks => convert_EB_acks,
      CD_stream => CD_stream,
      CD_read   => CD_read,
      clk_EVB     => clk_EVB,
      clk_EVB_locked => EVB_locked,
      monitor     => EB_Monitor,
      control     => EB_Control);

  DQM_1 : entity work.DQM
    port map (
      clk_128Mhz  => clk_FEMB_128Mhz,
      reset       => FEMB_RESET,
      convert     => convert_FEMB,
      WIB_ID      => WIB_Monitor.ID,
      packet_out  => DQM_packet,
      packet_free => packet_free,
      monitor     => DQM_monitor,
      control     => DQM_control,
      FEMB_DQM    => FEMB_DQM);

  
end WIB_ARCH;
