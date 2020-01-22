library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

use work.Convert_IO.all;
use work.EB_IO.all;
use work.COLDATA_IO.all;
use work.WIB_IO.all;
use work.CD_EB_BRIDGE.all;
use work.WIB_constants.all;
use work.types.all;

entity EventBuilder is
  port (
    clk_sys             : in  std_logic;
    reset_sys           : in  std_logic;
    reset_DAQ           : in  std_logic;

    QSFP_Rx             : in std_logic;
    clk_rx_ref          : in std_logic;
    clk_rx_out          : out std_logic;
    
    clk_ref             : in  std_logic;
    QSFP_Tx             : out std_logic_vector(DAQ_LINK_COUNT -1 downto 0);
    QSFP_RST_N          : out   std_logic;      -- 2.5V, default
    QSFP_LOW_POWER_MODE : out std_logic;
    QSFP_INT_N          : in  std_logic;
    QSFP_PRESENT_N      : in  std_logic;
    QSFP_I2C_SEL_N      : out   std_logic;     -- 2.5V
    QSFP_SCL            : inout   std_logic;      -- 2.5V, default   
    QSFP_SDA            : inout std_logic;      -- 2.5V, default
--    QSFP_SDA_EN         : out   std_logic;
    
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
--    DAQ_LINK_SI5342_SDA_EN : out std_logic;
    DAQ_LINK_SI5342_SEL0      : out std_logic;
    DAQ_LINK_SI5342_SEL1      : out std_logic;
    
    WIB_ID         : in  WIB_ID_t;
    converts       : in  convert_array_t;
    convert_acks   : out std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
    
    CD_stream      : in  CD_stream_array_t(FEMB_COUNT*LINKS_PER_FEMB downto 1);
    Cd_read        : out std_logic_vector(FEMB_COUNT*LINKS_PER_FEMB downto 1);
    clk_EVB        : out std_logic;
    clk_EVB_locked : out std_logic;
    
    monitor        : out EB_Monitor_t;
    control        : in  EB_Control_t
    );

end entity EventBuilder;

architecture behavioral of EventBuilder is
  component DAQ_Link_EventBuilder is
    generic (
      OUTPUT_BYTE_COUNT : integer;
      FIBER_ID          : integer);
    port (
      clk        : in  std_logic;
      reset      : in  std_logic;
      WIB_ID     : in  WIB_ID_t;
      convert    : in  convert_t;
      convert_ack : out std_logic;
      CD_stream  : in  CD_stream_array_t(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0);
      CD_read    : out std_logic_vector(CDAS_PER_DAQ_LINK*LINKS_PER_CDA -1 downto 0);
      data_out   : out std_logic_vector((8*OUTPUT_BYTE_COUNT)-1 downto 0);
      data_k_out : out std_logic_vector(OUTPUT_BYTE_COUNT - 1 downto 0);
      monitor    : out DAQ_Link_EB_Monitor_t;
      control    : in  DAQ_Link_EB_Control_t);
  end component DAQ_Link_EventBuilder;
  component RCE_PCS is
    generic (
      TX_COUNT   : integer;
      WORD_WIDTH : integer);
    port (
      sys_clk         : in  std_logic;
      sys_reset      : in  std_logic;
      reset           : in  std_logic;
      pll_powerdown   : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_analogreset  : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_digitalreset : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_ready        : out std_logic_vector(TX_COUNT - 1 downto 0);
      pll_locked      : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_cal_busy     : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_refclk       : in  std_logic;
      tx              : out std_logic_vector(TX_COUNT - 1 downto 0);
      clk_data        : out std_logic;
      data_wr         : in  std_logic_vector(TX_COUNT - 1 downto 0);
      k_data          : in  uint8_array_t(TX_COUNT -1 downto 0);
      data            : in  uint64_array_t(TX_COUNT -1 downto 0));
  end component RCE_PCS;
  component FELIX_PCS is
    generic (
      TX_COUNT   : integer;
      WORD_WIDTH : integer);
    port (
      sys_clk         : in  std_logic;
      sys_reset       : in  std_logic;
      reset           : in  std_logic;
      pll_powerdown   : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_analogreset  : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_digitalreset : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_ready        : out std_logic_vector(TX_COUNT - 1 downto 0);
      pll_locked      : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_cal_busy     : out std_logic_vector(TX_COUNT - 1 downto 0);
      tx_refclk       : in  std_logic;
      tx              : out std_logic_vector(TX_COUNT - 1 downto 0);
      clk_data        : out std_logic;
      data_wr         : in  std_logic_Vector(TX_COUNT -1 downto 0);
      k_data          : in  std_logic_vector(TX_COUNT*WORD_WIDTH - 1 downto 0);
      data            : in  std_logic_vector(TX_COUNT*WORD_WIDTH * 8 - 1 downto 0));
  end component FELIX_PCS;
  
  component I2C_reg_master is
    generic (
      I2C_QUARTER_PERIOD_CLOCK_COUNT : integer;
      IGNORE_ACK                     : std_logic;
      USE_RESTART_FOR_READ_SEQUENCE : std_logic);
    port (
      clk_sys     : in    std_logic;
      reset       : in    std_logic;
      I2C_Address : in    std_logic_vector(6 downto 0);
      run         : in    std_logic;
      rw          : in    std_logic;
      reg_addr    : in    std_logic_vector(7 downto 0);
      rd_data     : out   std_logic_vector(31 downto 0);
      wr_data     : in    std_logic_vector(31 downto 0);
      byte_count  : in    std_logic_vector(2 downto 0);
      done        : out   std_logic;
      error       : out   std_logic;
      SDA         : inout std_logic := 'L';
      SCLK        : inout std_logic);
  end component I2C_reg_master;
  
  -------------------------------------------------------------------------------
  -- state machine
  -------------------------------------------------------------------------------
  type EB_state_t is (EB_STATE_WAIT_CONV,     -- waiting for a convert signal
                      EB_STATE_WAIT_FEMB,     -- waiting for data from each CDstream
                      EB_STATE_SEND_HEADER_0, -- build and send header
                      EB_STATE_SEND_DATA);    --
  signal EB_state : EB_state_t := EB_STATE_WAIT_CONV;
  
  constant BYTE_WIDTH : integer := 4;
 
  signal pll_powerdown    : std_logic_vector(DAQ_LINK_COUNT - 1 downto 0);
  signal tx_analogreset   : std_logic_vector(DAQ_LINK_COUNT - 1 downto 0);
  signal tx_digitalreset  : std_logic_vector(DAQ_LINK_COUNT - 1 downto 0);
  signal tx_ready         : std_logic_vector(DAQ_LINK_COUNT - 1 downto 0);
  signal pll_locked       : std_logic_vector(DAQ_LINK_COUNT - 1 downto 0);
  signal tx_cal_busy      : std_logic_vector(DAQ_LINK_COUNT - 1 downto 0);


  
  signal tx_parallel_data : std_logic_vector((DAQ_LINK_COUNT*8*8) -1 downto 0)  := (others => '0');
  signal tx_datak         : std_logic_vector((DAQ_LINK_COUNT*8) -1 downto 0)   := (others => '0');


  signal new_event : std_logic := '0';


  signal PCS_reset : std_logic := '0';


  signal clk_EVB_local : std_logic := '0';
  
begin

  -----------------------------------------------------------------
  -- QSFP signals
  -----------------------------------------------------------------
  QSFP_RST_N           <= not control.QSFP.reset;
  monitor.QSFP.reset   <=     control.QSFP.reset;
  QSFP_LOW_POWER_MODE  <= control.QSFP.LP_mode;
  monitor.QSFP.LP_mode <= control.QSFP.LP_mode;
    
  monitor.QSFP.interrupt <= not QSFP_INT_N;
  monitor.QSFP.present   <= not QSFP_PRESENT_N;

  QSFP_I2C_SEL_N      <= not control.QSFP.I2C_EN;
  monitor.QSFP.I2C_EN <=     control.QSFP.I2C_EN;

  monitor.QSFP.I2C.byte_count <= control.QSFP.I2C.byte_count;
  monitor.QSFP.I2C.rw         <= control.QSFP.I2C.rw;
  monitor.QSFP.I2C.address    <= control.QSFP.I2C.address;
  monitor.QSFP.I2C.wr_data    <= control.QSFP.I2C.wr_data;
  I2C_reg_master_1: entity work.I2C_reg_master
    generic map (
      I2C_QUARTER_PERIOD_CLOCK_COUNT => 124,--31,      
      IGNORE_ACK                     => '0',
      USE_RESTART_FOR_READ_SEQUENCE  => '0')
    port map (
      clk_sys     => clk_sys,
      reset       => reset_sys,
      I2C_Address => "1101011",
      run         => control.QSFP.I2C.run,
      rw          => control.QSFP.I2C.rw,
      reg_addr    => control.QSFP.I2C.address,
      rd_data     => monitor.QSFP.I2C.rd_data,
      wr_data     => control.QSFP.I2C.wr_data,
      byte_count  => control.QSFP.I2C.byte_count,
      done        => monitor.QSFP.I2C.done,
      error       => monitor.QSFP.I2C.error,
      SDA         => QSFP_SDA,
      SCLK        => QSFP_SCL);
  
  
  DAQ_Link_EventBuilders: for iDAQ_Link in DAQ_LINK_COUNT downto 1 generate
    constant CDA_STR_PER_DAQ_LINK : integer := CDAS_PER_DAQ_LINK * LINKS_PER_CDA;
    constant FEMB_PER_DAQ_LINK : integer := FEMB_COUNT/DAQ_LINK_COUNT;
  begin
    DAQ_Link_EventBuilder_1: entity work.DAQ_Link_EventBuilder
        generic map (
          FIBER_ID => iDAQ_Link
          )
        port map (
          clk         => clk_EVB_local,--clk_PCS_parallel_125Mhz(iDAQ_Link-1),
          reset       => reset_DAQ,
          WIB_ID      => WIB_ID,
          convert     => converts(iDAQ_LINK-1),
          convert_ack => convert_acks(iDAQ_LINK-1),
          CD_stream   => CD_stream( (iDAQ_Link *  CDA_STR_PER_DAQ_LINK) downto ((iDAQ_Link-1) * CDA_STR_PER_DAQ_LINK ) +1),
          CD_read     => CD_read(   (iDAQ_Link *  CDA_STR_PER_DAQ_LINK) downto ((iDAQ_Link-1) * CDA_STR_PER_DAQ_LINK ) +1),
          data_out    => tx_parallel_data((iDAQ_Link * 8 * 8) - 1 downto (iDAQ_Link-1)*8*8),
          data_k_out  => tx_datak        ((iDAQ_Link * 8) - 1 downto (iDAQ_Link-1)*8),
          monitor     => monitor.DAQ_Link_EB(iDAQ_Link),
          control     => control.DAQ_Link_EB(iDAQ_Link)     
          );    
  end generate DAQ_Link_EventBuilders;


  clk_EVB_locked <= and_reduce(tx_ready);


  monitor.tx_reset         <= control.tx_reset;  
  monitor.tx_pll_powerdown <= pll_powerdown;
  monitor.tx_pll_locked    <= pll_locked;     
  monitor.tx_analogreset   <= tx_analogreset; 
  monitor.tx_digitalreset  <= tx_digitalreset;
  monitor.tx_ready         <= tx_ready;
  
  PCS_reset <= or_reduce(control.tx_reset);

  clk_EVB <= clk_EVB_local;
  RCE_FELIX_SWITCH: if CDAS_PER_DAQ_LINK = 2 generate    
    RCE_PCS_1: entity work.RCE_PCS
      port map (
        sys_clk         => clk_sys,
        sys_reset       => PCS_reset,
        reset           => PCS_reset,
        pll_powerdown   => pll_powerdown,
        tx_analogreset  => tx_analogreset,
        tx_digitalreset => tx_digitalreset,
        tx_ready        => tx_ready,
        pll_locked      => pll_locked,
        tx_cal_busy     => tx_cal_busy,
        tx_refclk       => clk_ref,
        tx              => QSFP_Tx,
        clk_data        => clk_EVB_local,
        data_wr         => x"F",
        k_data          => tx_datak,
        data            => tx_parallel_data);
  end generate RCE_FELIX_SWITCH;

  RCE_FELIX_SWITCH_ELSE: if CDAS_PER_DAQ_LINK = 4 generate
    FELIX_PCS_2: entity work.FELIX_PCS
      port map (
        sys_clk         => clk_sys,
        sys_reset       => PCS_reset,
        reset           => PCS_reset,
        pll_powerdown   => pll_powerdown,
        tx_analogreset  => tx_analogreset,
        tx_digitalreset => tx_digitalreset,
        tx_ready        => tx_ready,
        pll_locked      => pll_locked,
        tx_cal_busy     => tx_cal_busy,
        tx_refclk       => clk_ref,
        tx              => QSFP_Tx,
        clk_data        => clk_EVB_local,
        data_wr         => "11",
        k_data          => tx_datak,
        data            => tx_parallel_data);
  end generate RCE_FELIX_SWITCH_ELSE;



  ------------------------------------------------------------------------------
  -- SI5342 refclock driver
  ------------------------------------------------------------------------------    
  monitor.SI5342.I2C.byte_count <= control.SI5342.I2C.byte_count;
  monitor.SI5342.I2C.rw         <= control.SI5342.I2C.rw;
  monitor.SI5342.I2C.address    <= control.SI5342.I2C.address;
  monitor.SI5342.I2C.wr_data    <= control.SI5342.I2C.wr_data;
  monitor.SI5342.reset          <= control.SI5342.reset;
  monitor.SI5342.enable         <= control.SI5342.enable;
  monitor.SI5342.sel0           <= control.SI5342.sel0;
  monitor.SI5342.sel1           <= control.SI5342.sel1;  
  DAQ_LINK_SI5342_Mon: process (clk_sys) is
  begin  -- process DAQ_LINK_SI5342_Mon
    if clk_sys'event and clk_sys = '1' then  -- rising clock edge
      monitor.SI5342.LOL       <= not DAQ_LINK_SI5342_LOL_N;
      monitor.SI5342.LOS1      <= not DAQ_LINK_SI5342_LOS1_N;
      monitor.SI5342.LOS2      <= not DAQ_LINK_SI5342_LOS2_N;
      monitor.SI5342.LOS3      <= not DAQ_LINK_SI5342_LOS3_N;
      monitor.SI5342.LOSXAXB   <= not DAQ_LINK_SI5342_LOSXAXB_N;
      monitor.SI5342.interrupt <= not DAQ_LINK_SI5342_INT_N;      
    end if;
  end process DAQ_LINK_SI5342_Mon;
  DAQ_LINK_SI5342_OE_N    <= not control.SI5342.enable;
  DAQ_LINK_SI5342_RESET_N <= not control.SI5342.reset;
  DAQ_LINK_SI5342_sel0    <= control.SI5342.sel0;
  DAQ_LINK_SI5342_sel1    <= control.SI5342.sel1;  

  DAQ_LINK_SI5342_I2C: entity work.I2C_reg_master
    generic map (
      I2C_QUARTER_PERIOD_CLOCK_COUNT => 31,--124,
      IGNORE_ACK                     => '0')--,
--      USE_RESTART_FOR_READ_SEQUENCE  => '0')
    port map (
      clk_sys     => clk_sys,
      reset       => control.SI5342.I2C.reset,
      I2C_Address => "1101011",
      run         => control.SI5342.I2C.run,
      rw          => control.SI5342.I2C.rw,
      reg_addr    => control.SI5342.I2C.address,
      rd_data     => monitor.SI5342.I2C.rd_data,
      wr_data     => control.SI5342.I2C.wr_data,
      byte_count  => control.SI5342.I2C.byte_count,
      done        => monitor.SI5342.I2C.done,
      error       => monitor.SI5342.I2C.error,
      SDA         => DAQ_LINK_SI5342_SDA,
      SCLK        => DAQ_LINK_SI5342_SCL);


  
  
end architecture behavioral;
