library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use work.DTS_IO.all;
use work.Convert_IO.all;
use work.WIB_IO.all;
use work.pdts_defs.all;
use work.types.all;
use work.WIB_Constants.all;

entity DTS is
  port (
    clk_sys_50Mhz       : in    std_logic;
    reset               : in    std_logic;
                        
    DTS_CDS_SOURCE      : out std_logic;     --FP or BP
    DTS_CDS_LOL         : in std_logic;
    DTS_CDS_LOS         : in std_logic;
    DTS_CDS_SCL         : inout std_logic;
    DTS_CDS_SDA         : inout std_logic;
                                                
    DTS_SI5344_SCL      : inout std_logic;
    DTS_SI5344_SDA      : inout std_logic;
    DTS_SI5344_INT_N    : in    std_logic;
    DTS_SI5344_OE_N     : out    std_logic;
    DTS_SI5344_RST_N    : out    std_logic;
    DTS_SI5344_LOL_N    : in    std_logic;
    DTS_SI5344_LOS_N    : in    std_logic;
    DTS_SI5344_IN_SEL   : out   std_logic_vector(1 downto 0); 

    
    DUNE_clk_in_P        : in std_logic;  
    DUNE_clk_out_P       : out std_logic;  

    DTS_data_clk_P      : in std_logic;
    DTS_data_P          : in std_logic;  
    
    DTS_FP_CLK_OUT_DSBL : out std_logic;
    DTS_FP_CLK_OUT      : out std_logic;
   
    WIB_ID          : in    WIB_ID_t;
    -- DUNE 
    clk_DUNE        : out   std_logic;
    locked_DUNE     : out   std_logic;
    reset_DUNE      : out   std_logic;
    ready_DUNE      : out   std_logic;
    convert_DUNE    : out   convert_t;
    -- FEMB capture (clk_FEMB_128Mhz)
    reset_FEMB_Convert_count : in std_logic;
    clk_FEMB_128Mhz : in    std_logic;
    convert_FEMB    : out   convert_t;
    -- Event Builder (clk_EB)
    clk_EB          : in    std_logic;
    convert_EB      : out   convert_array_t;
    convert_EB_acks : in   std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
    -- UDP monitor/control
    monitor         : out   DTS_Monitor_t;
    control         : in    DTS_Control_t
    );

end entity DTS;

architecture behavioral of DTS is

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
  component pass_std_logic_vector is
    generic (
      DATA_WIDTH : integer;
      RESET_VAL  : std_logic_vector);
    port (
      clk_in   : in  std_logic;
      clk_out  : in  std_logic;
      reset    : in  std_logic;
      pass_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      pass_out : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component pass_std_logic_vector;
  component pdts_endpoint is
    generic (
      SCLK_FREQ : real;
      EN_TX: boolean;
      SIM: boolean);
    port (
      sclk    : in  std_logic;
      srst    : in  std_logic;
      addr    : in  std_logic_vector(7 downto 0);
      tgrp    : in  std_logic_vector(1 downto 0);
      stat    : out std_logic_vector(3 downto 0);
      rec_clk_50Mhz: in std_logic; -- CDR recovered 50Mhz clock
      rec_clk_250Mhz : in std_logic; -- CDR recovered 250Mhz clock
      rec_d: in std_logic; -- CDR recovered data (rec_clk domain)
      rec_clk_locked : in std_logic; -- recovered clock locked
      rec_clk_reset : out std_logic; -- reset of SI5344
      txd: out std_logic; -- Output data to timing link (rec_clk domain)
      sfp_los : in  std_logic;
      cdr_los : in  std_logic;
      cdr_lol : in  std_logic;
      sfp_tx_dis: out std_logic; -- SFP tx disable line (clk domain)
      clk     : out std_logic;
      rst     : out std_logic;
      rdy     : out std_logic;
      sync    : out std_logic_vector(SCMD_W - 1 downto 0);
      sync_stb: out std_logic; -- Sync command strobe (clk domain)
--      sync_valid: out std_logic; -- Sync command valid flag (clk domain)
      sync_first: out std_logic; -- Sync command valid flag (clk domain)
      tstamp  : out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
      tsync_in: in cmd_w; -- Tx sync command input
      tsync_out: out cmd_r; -- Tx sync command handshake
      monitor: out Monitor_PDTS_EP_S_t
      );
  end component pdts_endpoint;


  component I2C_reg_master is
    generic (
      I2C_QUARTER_PERIOD_CLOCK_COUNT : integer;
      IGNORE_ACK                     : std_logic);
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

  component DTS_SI5344_Control is
    port (
      clk_sys_50Mhz : in  std_logic;
      reset         : in    std_logic;
      clk_DTS       : in  std_logic;
      reset_DTS     : in  std_logic;
      SI5344_RST_N  : out std_logic;
      SI5344_IN_SEL : out std_logic_vector(1 downto 0);
      SI5344_OE_N   : out std_logic;
      SI5344_LOL_N  : in  std_logic;
      SI5344_LOS_N  : in  std_logic;
      SI5344_INT_N  : in  std_logic;
      DTS_SI5344_SCL      : inout std_logic;
      DTS_SI5344_SDA      : inout std_logic;
      monitor       : out DTS_SI5344_Monitor_t;
      control       : in  DTS_SI5344_Control_t);
  end component DTS_SI5344_Control;

  component DTS_Convert_Generation is
    port (
      clk_DUNE           : in  std_logic;
      clk_sys            : in  std_logic;
      reset_DUNE         : in  std_logic;
      ready_DUNE         : in  std_logic;
      pdts_cmd           : in  std_logic_vector(3 downto 0);
      pdts_cmd_valid     : in  std_logic;
      pdts_timestamp     : in  std_logic_vector(63 downto 0);
      pdts_event_counter : in  std_logic_vector(31 downto 0);
      convert_DUNE       : out convert_t;
      clk_FEMB_128Mhz    : in  std_logic;
      convert_FEMB       : out convert_t;
      reset_FEMB_Convert_count : in std_logic;
      clk_EB             : in  std_logic;
      convert_EB         : out convert_array_t;
      convert_EB_acks    : in  std_logic_vector(DAQ_LINK_COUNT -1 downto 0);
      monitor            : out DTS_Convert_Monitor_t;
      control            : in  DTS_Convert_Control_t);
  end component DTS_Convert_Generation;

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
  
  component CDS_DATA_PLL is
    port (
      refclk   : in  std_logic := 'X';
      rst      : in  std_logic := 'X';
      outclk_0 : out std_logic;
      locked   : out std_logic);
  end component CDS_DATA_PLL;

  component CDS_BASE_PLL is
    port (
      refclk   : in  std_logic := 'X';
      rst      : in  std_logic := 'X';
      outclk_0 : out std_logic;
      locked   : out std_logic);
  end component CDS_BASE_PLL;
  component SimpleClock is
    port (
      inclk  : in  std_logic := 'X';
      outclk : out std_logic);
  end component SimpleClock;

  component DTS_tx is
    port (
      clk_sys_50Mhz : in  std_logic;
      clk_PDTS      : in  std_logic;
      clk_PDTS_d    : in  std_logic;
      DTS_data_in   : in  std_logic;
      DTS_data_out  : out std_logic;
      DTS_OUT_DSBL  : out std_logic;
      monitor       : out DTS_Tx_Monitor_t;
      control       : in  DTS_Tx_Control_t);
  end component DTS_tx;

  component PDTS_PLL is
    port (
      refclk   : in  std_logic := '0';
      rst      : in  std_logic := '0';
      outclk_0 : out std_logic;
      locked   : out std_logic);
  end component PDTS_PLL;
  
  signal  DTS_SI5344_OE_N_local : std_logic;
  
  -- SYS clock domain
  signal WIB_address : std_logic_vector(7 downto 0) := (others => '1');
  signal WIB_address_buffer : std_logic_vector(7 downto 0) := (others => '1');
  signal reset_req_SI5344 : std_logic := '0';
  
  -- DUNE 50Mhz clock domain
  signal DUNE_clk_sel : std_logic_vector(1 downto 0) := "10";
  signal clk_PDTS : std_logic := '0';
  signal reset_PDTS : std_logic := '0';
  signal clk_DUNE_in : std_logic := '0';
  signal clk_DTS_in_LOS : std_logic := '1';
  signal clk_DTS_in_LOL : std_logic := '1';
  signal clk_DTS_data : std_logic := '0';
  signal clk_DUNE_local : std_logic;
  signal clk_DTS_locked  : std_logic;
  signal DUNE_convert : std_logic := '0';
  signal reset_DTS    : std_logic;  
  signal ready_DTS    : std_logic;
  signal PD_cmd       : std_logic_vector(3 downto 0);
  signal PD_cmd_valid : std_logic;
  signal PD_cmd_strobe : std_logic;
  signal PD_timestamp : std_logic_vector(63 downto 0);
  signal PD_event_counter : std_logic_vector(31 downto 0);
  signal PDTS_state : std_logic_vector(3 downto 0);
  
  signal convert_FAKE : std_logic := '0';
  signal convert_count_FAKE : std_logic_vector(48 downto 0) := (others =>'0');
  signal DUNE_Convert_count : std_logic_vector(15 downto 0) := (others =>'0');
  signal DUNE_reset_count   : std_logic_vector(23 downto 0) := (others =>'0');
  signal DUNE_timestamp     : std_logic_vector(63 downto 0) := (others => '0');

  signal convert_DUNE_bits : std_logic_vector(103 downto 0);

  signal convert_fifo_wr : std_logic := '0';

  signal PDTS_pulse : std_logic_vector(15 downto 0) := (others => '0');

  signal  DTS_data_loopback_buffered : std_logic := '0';

  constant DTS_DATA_DELAY : integer := 10;--3;
  signal DTS_data_latched : std_logic_vector(DTS_DATA_DELAY-1 downto 0);

  signal PDTS_PLL_reset : std_logic;

  signal locked_DUNE_local : std_logic := '0';


  signal CMD_count_reset : std_logic_vector(15 downto 0);
  signal CMD_count       : uint32_array_t(15 downto 0);    

  signal history_monitor_start : std_logic;
  signal history_monitor_stop  : std_logic;
  
  signal PDTS_Monitor : Monitor_PDTS_EP_S_t;

  signal WIB_ID_Concat : std_logic_vector(7 downto 0);
  
begin  -- architecture behavioral

--  WIB_address <= WIB_ID.crate & WIB_ID.slot;

  ready_DUNE <= ready_DTS;
  ------------------------------------------------------------------------------
  -- sys_50Mhz  clock domain
  ------------------------------------------------------------------------------  

  ---------------------------------------
  -- CDS chip
  ---------------------------------------
  DTS_CDS_SOURCE             <= control.CDS.input_select;
  monitor.CDS.LOL            <= DTS_CDS_LOL;
  monitor.CDS.LOS            <= DTS_CDS_LOS;        
  monitor.CDS.I2C.byte_count <= control.CDS.I2C.byte_count;
  monitor.CDS.I2C.address    <= control.CDS.I2C.address;
  monitor.CDS.I2C.wr_data    <= control.CDS.I2C.wr_data;
  monitor.CDS.input_select   <= control.CDS.input_select;
  monitor.CDS.I2C.rw         <= control.CDS.I2C.rw;
  DTS_CDS_I2C: entity work.I2C_reg_master
    generic map (
      I2C_QUARTER_PERIOD_CLOCK_COUNT => 31,
      IGNORE_ACK                     => '0')
    port map (
      clk_sys     => clk_sys_50Mhz,
      reset       => control.CDS.I2C.reset,
      I2C_Address => "1000000",
      run         => control.CDS.I2C.run,
      rw          => control.CDS.I2C.rw,
      reg_addr    => control.CDS.I2C.address,
      rd_data     => monitor.CDS.I2C.rd_data,
      wr_data     => control.CDS.I2C.wr_data,
      byte_count  => control.CDS.I2C.byte_count,
      done        => monitor.CDS.I2C.done,
      error       => monitor.CDS.I2C.error,
      SDA         => DTS_CDS_SDA,
      SCLK        => DTS_CDS_SCL);

  ---------------------------------------
  -- DTS clock cleanup
  ---------------------------------------
  DTS_SI5344_OE_N <= DTS_SI5344_OE_N_local;
  DTS_SI5344_Control_1: entity work.DTS_SI5344_Control
    port map (
      clk_sys_50Mhz => clk_sys_50Mhz,
      reset         => reset,
      clk_DTS       => clk_PDTS,
      reset_DTS     => '0',--reset_req_SI5344, -- '0',
      SI5344_RST_N  => DTS_SI5344_RST_N,
      SI5344_IN_SEL => DTS_SI5344_IN_SEL,
      SI5344_OE_N   => DTS_SI5344_OE_N_local,
      SI5344_LOL_N  => DTS_SI5344_LOL_N,
      SI5344_LOS_N  => DTS_SI5344_LOS_N,
      SI5344_INT_N  => DTS_SI5344_INT_N,
      DTS_SI5344_SCL => DTS_SI5344_SCL,
      DTS_SI5344_SDA => DTS_SI5344_SDA,
      monitor       => monitor.SI5344,
      control       => control.SI5344);





  ------------------------------------------------------------------------------
  -- DUNE  clock domain
  ------------------------------------------------------------------------------  


  ---------------------------------------
  -- Put output clocks from the SI5344
  -- on the global clocking resources
  ---------------------------------------
  clk_DTS_data <= DTS_data_clk_P;
  
  -- The SI5344 must be configured before the DUNE clock is available.
  -- Local (non-PDTS) testing must select the second input of the SI5433
  clk_DUNE <= clk_PDTS;
--  PDTS_PLL_1: PDTS_PLL
--    port map (
--      refclk   => DTS_data_clk_P,--clk_DTS_data,
--      rst      => PDTS_PLL_reset,
--      outclk_0 => clk_DUNE_in,
--      locked   => clk_DTS_locked);
--  PDTS_PLL_reset <= (reset_req_SI5344 and control.PDTS.enable) or (not DTS_SI5344_LOL_N);
--  monitor.clk_DUNE_in_locked <= clk_DTS_locked;


  
  clk_DUNE_in <= DUNE_clk_in_P;
  clk_DTS_locked <= '1' when (DTS_SI5344_LOL_N = '1' and DTS_SI5344_LOS_N = '1' and DTS_SI5344_OE_N_local = '0') else '0';

  PDTS_PLL_reset <= (reset_req_SI5344 and control.PDTS.enable) or (not DTS_SI5344_LOL_N);
  monitor.clk_DUNE_in_locked <= clk_DTS_locked;
  ---------------------------------------
  -- Provide the locked signal for the
  -- DUNE clock
  ---------------------------------------  
  -- output if the DUNE clock is locked

  locked_DUNE <= locked_DUNE_local;
  clk_DUNE_lock_on: process (clk_sys_50Mhz,clk_DTS_locked) is
  begin  -- process clk_DUNE_lock_on
    if clk_DTS_locked = '0' then
      --if the 50Mhz DUNE clock is not locked, we are not locked
      locked_DUNE_local <= '0';    
    elsif clk_sys_50Mhz'event and clk_sys_50Mhz = '1' then
      monitor.clk_DUNE_in_reset  <= PDTS_PLL_reset;
      if control.PDTS.enable = '1' then
        --if we are in the RUN state, we are locked
        if PDTS_state = "1000" then
          locked_DUNE_local <= '1';
        end if;
      else
        -- we are locked if not in reset
        locked_DUNE_local <= '1';
      end if;
    end if;
  end process clk_DUNE_lock_on;

  ---------------------------------------
  -- The actual DUNE timing system
  ---------------------------------------
  monitor.PDTS.state <= PDTS_state;
  monitor.PDTS.timing_group <= control.PDTS.timing_group;
  monitor.PDTS.reset <= reset_DTS;
  monitor.PDTS.ready <= ready_DTS;  
  monitor.PDTS.enable <= control.PDTS.enable;
  reset_PDTS <= not control.PDTS.enable;
  clk_DTS_in_LOS <= (not DTS_SI5344_LOS_N);
  clk_DTS_in_LOL <= (not DTS_SI5344_LOL_N) or DTS_SI5344_OE_N_local;
  reset_DUNE <= '0' when PDTS_state = "1000" else '1';

--  input_latch: process (clk_DTS_data) is
--  begin  -- process input_latch
--    if clk_DTS_data'event and clk_DTS_data = '1' then  -- rising clock edge
--      DTS_data_latched <= DTS_data_P & DTS_data_latched(DTS_DATA_DELAY-1 downto 1);
--    end if;
--  end process input_latch;

  pass_std_logic_vector_2: entity work.pass_std_logic_vector
    generic map (
      DATA_WIDTH => 64,
      RESET_VAL  => x"0000000000000000")
    port map (
      clk_in   => clk_PDTS,
      clk_out  => clk_sys_50Mhz,
      reset    => '0',
      pass_in  => PD_timestamp,
      pass_out => monitor.PDTS.timestamp);

  pass_std_logic_vector_3: entity work.pass_std_logic_vector
    generic map (
      DATA_WIDTH => 32,
      RESET_VAL  => x"00000000")
    port map (
      clk_in   => clk_PDTS,
      clk_out  => clk_sys_50Mhz,
      reset    => '0',
      pass_in  => PD_event_counter,
      pass_out => monitor.PDTS.event_number);

  WIB_ID_concat <= WIB_ID.crate&WIB_ID.slot;
  PDTS_address_proc: process (clk_sys_50Mhz) is
  begin  -- process PDTS_address_proc
    if clk_sys_50Mhz'event and clk_sys_50Mhz = '1' then  -- rising clock edge
      wib_address_buffer <= wib_address;

      case WIB_ID_concat  is
        when x"00" => WIB_address <= x"40";
        when x"01" => WIB_address <= x"41";
        when x"02" => WIB_address <= x"42";
        when x"03" => WIB_address <= x"43";
        when x"04" => WIB_address <= x"44";
        when x"10" => WIB_address <= x"45";
        when x"11" => WIB_address <= x"46";
        when x"12" => WIB_address <= x"47";
        when x"13" => WIB_address <= x"48";
        when x"14" => WIB_address <= x"49";
        when x"20" => WIB_address <= x"4A";
        when x"21" => WIB_address <= x"4B";
        when x"22" => WIB_address <= x"4C";
        when x"23" => WIB_address <= x"4D";
        when x"24" => WIB_address <= x"4E";
        when x"30" => WIB_address <= x"4F";
        when x"31" => WIB_address <= x"50";
        when x"32" => WIB_address <= x"51";
        when x"33" => WIB_address <= x"52";
        when x"34" => WIB_address <= x"53";
        when x"40" => WIB_address <= x"54";
        when x"41" => WIB_address <= x"55";
        when x"42" => WIB_address <= x"56";
        when x"43" => WIB_address <= x"57";
        when x"44" => WIB_address <= x"58";
        when x"50" => WIB_address <= x"59";
        when x"51" => WIB_address <= x"5A";
        when x"52" => WIB_address <= x"5B";
        when x"53" => WIB_address <= x"5C";
        when x"54" => WIB_address <= x"5D";
        when x"60" => WIB_address <= x"5E";
        when x"61" => WIB_address <= x"5F";
        when x"62" => WIB_address <= x"60";
        when x"63" => WIB_address <= x"61";
        when x"64" => WIB_address <= x"62";
        when x"92" => WIB_address <= x"63";
        when x"94" => WIB_address <= x"64";                      
        when others => WIB_address <= x"65";
      end case;
      if control.PDTS.addr_override_en = '1' then
        WIB_address <= control.PDTS.override_addr;
      end if;
    end if;
  end process PDTS_address_proc;
  monitor.PDTS.addr <= WIB_address;
  monitor.PDTS.addr_override_en <= control.PDTS.addr_override_en;
  monitor.PDTS.override_addr <= control.PDTS.override_addr;
  
  pdts_endpoint_1: entity work.pdts_endpoint
    generic map (
      SCLK_FREQ => 50.0,
      EN_TX=> false,
      SIM => false)
    port map (
      sclk    => clk_sys_50Mhz,
      srst    => reset_PDTS,
      addr    => WIB_address_buffer,
      tgrp    => control.PDTS.timing_group,
      stat    => PDTS_state,

      rec_clk_50Mhz   => clk_DUNE_in,
      rec_clk_250Mhz => clk_DTS_data,
      rec_d     => DTS_data_P,--DTS_data_latched(0),--DTS_data_P,
      rec_clk_locked => clk_DTS_locked,--DTS_SI5344_LOL_N, -- not loss of lock is locked
      rec_clk_reset => reset_req_SI5344,

      txd => DTS_FP_CLK_OUT,
      sfp_los => '0',
      cdr_los => clk_DTS_in_LOS,
      cdr_lol => clk_DTS_in_LOL,
      sfp_tx_dis => DTS_FP_CLK_OUT_DSBL,
      clk     => clk_PDTS,
      rst     => reset_DTS,
      rdy     => ready_DTS,
      sync    => PD_cmd,
      sync_stb => PD_cmd_strobe,
--      sync_valid  => PD_cmd_valid,
      sync_first  => PD_cmd_valid,
      tstamp  => PD_timestamp,
      tsync_in => CMD_W_NULL,
      tsync_out => open,
      monitor => PDTS_monitor);

--  history_monitor_start <= '1' when PDTS_monitor.state = x"8" else '0';
--  history_monitor_stop  <= '1' when PDTS_monitor.state /= x"8" else '0';
  history_monitor_start <= '1' when PDTS_monitor.state = x"0" else '0';
  history_monitor_stop  <= '1' when PDTS_monitor.state /= x"2" else '0';

  history_monitor_1: entity work.history_monitor
    generic map (
      HISTORY_BIT_LENGTH => 8,
      SIGNAL_COUNT       => 25)--9)
    port map (
      clk                 => clk_sys_50Mhz,
      reset               => reset_PDTS,
      signals(0)          => PDTS_monitor.sfp_los_ok,
      signals(1)          => PDTS_monitor.cdr_ok,
      signals(2)          => PDTS_monitor.rxphy_locked_i,
      signals(3)          => PDTS_monitor.rx_err_i,
      signals(4)          => PDTS_monitor.rdy_i,
      signals(8 downto 5) => PDTS_monitor.state,
      signals(24 downto 9)=> PDTS_monitor.cctr_rnd,
      start               => history_monitor_start,
      stop                => history_monitor_stop,
      history_out         => monitor.history.data,
      history_presample   => monitor.history.presample,
      history_valid       => monitor.history.valid,
      history_ack         => control.history.ack);
  
  PD_event_counter <= (others => '0');
  
  
  ---------------------------------------
  -- Monitoring of the PDTS
  ---------------------------------------
  monitor.PDTS.CMD_count_reset <= control.PDTS.CMD_count_reset;
  pdts_cmd_counts: for iCMD in 15 downto 0 generate
    --Generate a pulse for each 
    PDTS_pulse(iCMD) <= '1' when PD_cmd_valid = '1' and PD_cmd_strobe = '1' and PD_cmd = std_logic_vector(to_unsigned(iCMD,4)) else '0';

    pass_reset: entity work.pass_std_logic_vector
      generic map (
        DATA_WIDTH => 1,
        RESET_VAL => "0")
      port map (
        clk_in   => clk_sys_50Mhz,
        clk_out  => clk_PDTS,
        reset    => '0',
        pass_in(0)  => control.PDTS.CMD_count_reset(iCMD),
        pass_out(0) => CMD_count_reset(iCMD));
   
    counter_1: entity work.counter
      port map (
        clk         => clk_PDTS,
        reset_async => '0',
        reset_sync  => CMD_count_reset(iCMD),
        enable      => '1',
        event       => PDTS_pulse(iCMD),
        count       => CMD_count(iCMD),
        at_max      => open);

    pass_std_logic_vector_1: entity work.pass_std_logic_vector
      port map (
        clk_in   => clk_PDTS,
        clk_out  => clk_sys_50Mhz,
        reset    => reset,
        pass_in  => CMD_count(iCMD),
        pass_out => monitor.PDTS.CMD_count(iCMD));
    
  end generate pdts_cmd_counts;  

  monitor.DTS_TX <= (others => '0');

  
  DTS_Convert_Generation_1: entity work.DTS_Convert_Generation
    port map (
      clk_DUNE           => clk_DUNE_in,--clk_PDTS,
      clk_sys            => clk_sys_50Mhz,
      reset_DUNE         => '0',
      ready_DUNE         => '1',
      pdts_cmd           => PD_cmd,
      pdts_cmd_valid     => PD_cmd_valid,
      pdts_timestamp     => PD_timestamp,
      pdts_event_counter => PD_event_counter,
      convert_DUNE       => convert_DUNE,
      clk_FEMB_128Mhz    => clk_FEMB_128Mhz,
      convert_FEMB       => convert_FEMB,
      reset_FEMB_Convert_count =>     reset_FEMB_Convert_count,
      clk_EB             => clk_EB,
      convert_EB         => convert_EB,
      convert_EB_acks    => convert_EB_acks,
      monitor            => monitor.DTS_Convert,
      control            => control.DTS_Convert);
  


end architecture behavioral;
