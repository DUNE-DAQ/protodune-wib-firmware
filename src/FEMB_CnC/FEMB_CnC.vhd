library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.COLDATA_CNC_package.all;
use work.FEMB_CnC_IO.all;

entity FEMB_CnC is
port (
  clk_DTS_FEMB_100Mhz : in std_logic;  
  clk_PDTS            : in std_logic;
  clk_out             : out std_logic;
  reset               : in std_logic;
  cmd_start           : in std_logic; -- pulse
  cmd_stop            : in std_logic; -- pulse
  cmd_calibrate       : in std_logic; -- pulse
  cmd_timestamp_reset : in std_logic; -- pulse  
  COLDATA_cmd         : out std_logic;
  COLDATA_cmd_sel     : out std_logic;
  COLDATA_clk_sel     : out std_logic;
  monitor             : out FEMB_CNC_Monitor_t;
  control             : in  FEMB_CNC_Control_t
  );
end entity FEMB_CnC;
architecture FEMB_CnC of FEMB_CnC is
  component SBND_PWM_CLK_ENCODER is
    port (
      RESET         : IN  STD_LOGIC;
      CLK_100MHz    : IN  STD_LOGIC;
      SAMPLE_RATE   : IN  STD_LOGIC_vector(3 downto 0);
      EXT_CMD1      : IN  STD_LOGIC;
      EXT_CMD2      : IN  STD_LOGIC;
      EXT_CMD3      : IN  STD_LOGIC;
      EXT_CMD4      : IN  STD_LOGIC;
      SW_CMD1       : IN  STD_LOGIC;
      SW_CMD2       : IN  STD_LOGIC;
      SW_CMD3       : IN  STD_LOGIC;
      SW_CMD4       : IN  STD_LOGIC;
      DIS_CMD1      : IN  STD_LOGIC;
      DIS_CMD2      : IN  STD_LOGIC;
      DIS_CMD3      : IN  STD_LOGIC;
      DIS_CMD4      : IN  STD_LOGIC;
      SBND_SYNC_CMD : OUT STD_LOGIC;
      SBND_ADC_CLK  : OUT STD_LOGIC);
  end component SBND_PWM_CLK_ENCODER;

  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;
  
  component FEMB_DTS_clk is
    port (
      refclk   : in  std_logic := '0';
      rst      : in  std_logic := '0';
      outclk_0 : out std_logic;
      locked   : out std_logic);
  end component FEMB_DTS_clk;
  
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

  signal clk_DTS_100Mhz : std_logic := '0';
  
  signal frame_counter : integer range FRAME_LENGTH downto 0 := FRAME_LENGTH;
  signal error_convert_timing : std_logic := '0';

  signal hold_PWM_in_timestamp_reset : std_logic := '1';
  signal send_timestamp_reset_pulse : std_logic := '0';
  
  signal clk_local : std_logic := '0';

  signal  cmd_100Mhz_start_data      : std_logic := '0';
  signal  cmd_100Mhz_stop_data       : std_logic := '0';
  signal  cmd_100Mhz_calibration     : std_logic := '0';
  signal  cmd_100Mhz_timestamp_reset : std_logic := '0';
  signal  send_cmd_start_data        : std_logic := '0';
  signal  send_cmd_stop_data         : std_logic := '0';
  signal  send_cmd_calibration       : std_logic := '0';
  signal  send_cmd_timestamp_reset   : std_logic := '0';
  
begin  -- architecture FEMB_CnC

  COLDATA_clk_sel <= control.clk_sel;
  monitor.clk_sel <= control.clk_sel;

  monitor.DTS_reset <= control.DTS_reset;
--  FEMB_DTS_clk_1: FEMB_DTS_clk
--    port map (
--      refclk   => clk_DTS_FEMB_100Mhz,
--      rst      => control.DTS_reset,
--      outclk_0 => clk_DTS_100Mhz,
--      locked   => monitor.DTS_locked);
  monitor.DTS_locked <= '1';
  clk_DTS_100Mhz <= clk_DTS_FEMB_100Mhz;
  

  clk_local <= clk_DTS_100Mhz;
  clk_out   <= clk_DTS_100Mhz;
  
  pacd_1: entity work.pacd
    port map (
      iPulseA => cmd_stop,
      iClkA   => clk_PDTS,
      iRSTAn  => '1',
      iClkB   => clk_local,
      iRSTBn  => '1',
      oPulseB => cmd_100Mhz_stop_data);
  pacd_2: entity work.pacd
    port map (
      iPulseA => cmd_start,
      iClkA   => clk_PDTS,
      iRSTAn  => '1',
      iClkB   => clk_local,
      iRSTBn  => '1',
      oPulseB => cmd_100Mhz_start_data);
  pacd_3: entity work.pacd
    port map (
      iPulseA => cmd_timestamp_reset,
      iClkA   => clk_PDTS,
      iRSTAn  => '1',
      iClkB   => clk_local,
      iRSTBn  => '1',
      oPulseB => cmd_100Mhz_timestamp_reset);
  pacd_4: entity work.pacd
    port map (
      iPulseA => cmd_calibrate,
      iClkA   => clk_PDTS,
      iRSTAn  => '1',
      iClkB   => clk_local,
      iRSTBn  => '1',
      oPulseB => cmd_100Mhz_calibration);


  monitor.DTS_cmd_enable    <= control.DTS_cmd_enable;
  monitor.DTS_TP_enable     <= control.DTS_TP_enable;
  
  send_cmd_stop_data        <= (control.DTS_cmd_enable and cmd_100Mhz_stop_data       ) or control.stop_data;
  send_cmd_start_data       <= (control.DTS_cmd_enable and cmd_100Mhz_start_data      ) or control.start_data;
  send_cmd_timestamp_reset  <= (control.DTS_cmd_enable and cmd_100Mhz_timestamp_reset ) or control.timestamp_reset;
  send_cmd_calibration      <= (control.DTS_cmd_enable and control.DTS_TP_enable and cmd_100Mhz_calibration     ) or control.calibration;
  
  SBND_PWM_CLK_ENCODER_1: entity work.SBND_PWM_CLK_ENCODER
    port map (
      RESET         => reset,
      CLK_100MHz    => clk_local,
      SAMPLE_RATE   => x"0",
      EXT_CMD1      => '0',
      EXT_CMD2      => '0',
      EXT_CMD3      => '0',
      EXT_CMD4      => '0',
      SW_CMD1       => send_cmd_calibration,
      SW_CMD2       => send_cmd_timestamp_reset,--send_timestamp_reset_pulse,
      SW_CMD3       => send_cmd_stop_data,--control.stop_data,
      SW_CMD4       => send_cmd_start_data,--control.start_data,
      DIS_CMD1      => '0',
      DIS_CMD2      => '0',
      DIS_CMD3      => '0',
      DIS_CMD4      => '0',
      SBND_SYNC_CMD => COLDATA_cmd,
      SBND_ADC_CLK  => open);

    
  -------------------------------------------------------------------------------
  -- Error counter
  ------------------------------------------------------------------------------- 
  counter_5: entity work.counter
    port map (
      clk         => clk_local,
      reset_async => reset,
      reset_sync  => control.error_convert_timing_counter_reset,
      enable      => '1',
      event       => error_convert_timing,
      count       => monitor.error_convert_timing_counter,
      at_max      => open);

  -------------------------------------------------------------------------------
  -- Counters for FEMB cmds
  ------------------------------------------------------------------------------- 
  counter_1: entity work.counter
    port map (
      clk         => clk_local,
      reset_async => reset,
      reset_sync  => control.convert_counter_reset,
      enable      => '1',
      event       => send_cmd_stop_data,
      count       => monitor.convert_counter,
      at_max      => open);
  counter_2: entity work.counter
    port map (
      clk         => clk_local,
      reset_async => reset,
      reset_sync  => control.calibrate_counter_reset,
      enable      => '1',
      event       => send_cmd_calibration,
      count       => monitor.calibrate_counter,
      at_max      => open);
  counter_3: entity work.counter
    port map (
      clk         => clk_local,
      reset_async => reset,
      reset_sync  => control.sync_counter_reset,
      enable      => '1',
      event       => send_cmd_start_data,
      count       => monitor.sync_counter,
      at_max      => open);
  counter_4: entity work.counter
    port map (
      clk         => clk_local,
      reset_async => reset,
      reset_sync  => control.reset_counter_reset,
      enable      => '1',
      event       => send_cmd_timestamp_reset,
      count       => monitor.reset_counter,
      at_max      => open);

end architecture FEMB_CnC;
