library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use work.DTS_IO.all;
use work.Convert_IO.all;
use work.WIB_IO.all;
use work.pdts_defs.all;
use work.types.all;

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
    clk_FEMB_128Mhz : in    std_logic;
    convert_FEMB    : out   convert_t;
    -- Event Builder (clk_EB)
    clk_EB          : in    std_logic;
    convert_EB      : out   convert_t;
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
      SCLK_FREQ : real);
    port (
      sclk    : in  std_logic;
      srst    : in  std_logic;
      addr    : in  std_logic_vector(7 downto 0);
      tgrp    : in  std_logic_vector(1 downto 0);
      stat    : out std_logic_vector(3 downto 0);
      rec_clk: in std_logic; -- CDR recovered 50Mhz clock
      rec_d_clk : in std_logic; -- CDR recovered 250Mhz clock
      rec_d: in std_logic; -- CDR recovered data (rec_clk domain)
      rec_d_out: out std_logic; -- CDR recovered data (rec_clk domain)
      rec_clk_locked : in std_logic; -- recovered clock locked
      rec_clk_reset : out std_logic; -- reset of SI5344
      sfp_los : in  std_logic;
      cdr_los : in  std_logic;
      cdr_lol : in  std_logic;
      clk     : out std_logic;
      rst     : out std_logic;
      rdy     : out std_logic;
      sync    : out std_logic_vector(SCMD_W - 1 downto 0);
      sync_v  : out std_logic;
      tstamp  : out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0);
      evtctr  : out std_logic_vector(8 * EVTCTR_WDS - 1 downto 0));
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
      clk_EB             : in  std_logic;
      convert_EB         : out convert_t;
      monitor            : out DTS_Convert_Monitor_t;
      control            : in  DTS_Convert_Control_t);
  end component DTS_Convert_Generation;

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

  constant DTS_DATA_DELAY : integer := 3;
  signal DTS_data_latched : std_logic_vector(DTS_DATA_DELAY-1 downto 0);

  signal PDTS_PLL_reset : std_logic;

  signal locked_DUNE_local : std_logic := '0';


  signal CMD_count_reset : std_logic_vector(15 downto 0);
  signal CMD_count       : uint32_array_t(15 downto 0);    

  signal resetter_event : std_logic := '0';
  signal reset_PDTS_last : std_logic := '0';
  
begin  -- architecture behavioral

  WIB_address <= WIB_ID.crate & WIB_ID.slot;

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
--  CDS_BASE_PLL_1: CDS_BASE_PLL
--    port map (
--      refclk   => DUNE_clk_in_P,
--      rst      => '0',
--      outclk_0 => clk_DUNE_in,
--      locked   => open);

--  dune_clk_buffer: SimpleClock
--    port map (
--      inclk  => DUNE_clk_in_P,
--      outclk => clk_DUNE_in);
  CDS_DATA_PLL_1: CDS_DATA_PLL
    port map (
      refclk   => DTS_data_clk_P,
      rst      => '0',
      outclk_0 => clk_DTS_data,
      locked   => open);
  
--  PDTS_clk_buffer: SimpleClock
--    port map (
--      inclk  => DTS_data_clk_P,
--      outclk => clk_DTS_data);

  -- The SI5344 must be configured before the DUNE clock is available.
  -- Local (non-PDTS) testing must select the second input of the SI5433
  clk_DUNE <= clk_PDTS;

  PDTS_PLL_1: PDTS_PLL
    port map (
      refclk   => DTS_data_clk_P,--clk_DTS_data,
      rst      => PDTS_PLL_reset,
      outclk_0 => clk_DUNE_in,
      locked   => clk_DTS_locked);
  --  clk_DTS_locked <= not clk_DTS_in_LOL;
  PDTS_PLL_reset <= (reset_req_SI5344 and control.PDTS.enable) or (not DTS_SI5344_LOL_N);
  --PDTS_PLL_reset <= reset_req_SI5344 when control.PDTS.enable ; 
  monitor.clk_DUNE_in_locked <= clk_DTS_locked;
--  monitor.clk_DUNE_in_reset  <= PDTS_PLL_reset;
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
--  clk_DUNE_lock_on: process (PDTS_state,control.PDTS.enable) is
--  begin  -- process clk_DUNE_lock_on
--    locked_DUNE <= '0';
--    case control.PDTS.enable is
--      when '1' =>
--        -- using protodune timing system
--        if PDTS_state = "1000" then
--          locked_DUNE <= '1';
--        end if;
--      when others =>
--        locked_DUNE <= clk_DTS_locked;--DTS_SI5344_LOL_N and DTS_SI5344_LOS_N;
--    end case;
--  end process clk_DUNE_lock_on;
--

  ---------------------------------------
  -- The actual DUNE timing system
  ---------------------------------------
  monitor.PDTS.state <= PDTS_state;
  monitor.PDTS.timing_group <= control.PDTS.timing_group;
  monitor.PDTS.reset <= reset_DTS;
  monitor.PDTS.ready <= ready_DTS;  
  monitor.PDTS.enable <= control.PDTS.enable;
--  reset_PDTS <= not control.PDTS.enable;
  clk_DTS_in_LOS <= (not DTS_SI5344_LOS_N);
  clk_DTS_in_LOL <= (not DTS_SI5344_LOL_N) or DTS_SI5344_OE_N_local;
  reset_DUNE <= '0' when PDTS_state = "1000" else '1';

  input_latch: process (clk_DTS_data) is
  begin  -- process input_latch
    if clk_DTS_data'event and clk_DTS_data = '1' then  -- rising clock edge
      DTS_data_latched <= DTS_data_P & DTS_data_latched(DTS_DATA_DELAY-1 downto 1);
    end if;
  end process input_latch;

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


  counter_2: entity work.counter
    generic map (
      roll_over   => '0',
      end_value   => x"FFFFFFFF",
      start_value => x"00000000",
      DATA_WIDTH  => 32)
    port map (
      clk         => clk_sys_50Mhz,
      reset_async => '0',
      reset_sync  => control.PDTS.resetter_count_reset,
      enable      => '1',
      event       => resetter_event,
      count       => monitor.PDTS.resetter_count,
      at_max      => open);
  monitor.PDTS.enable_resetter <= control.PDTS.enable_resetter;
  monitor.PDTS.resetter_count_reset <= control.PDTS.resetter_count_reset;
  PDTS_resetter: process (clk_sys_50Mhz) is
  begin  -- process PDTS_resetter
    if clk_sys_50Mhz'event and clk_sys_50Mhz = '1' then  -- rising clock edge      
      --Default behavior is to hold the PDTS in reset only when we don't have
      --it enabled. 
      reset_PDTS <= not control.PDTS.enable;
      if control.PDTS.enable_resetter = '1' then
        --If this option is set, then we will cause a reset of PDTS
        -- when the PDTS is enabled, but in the error state x"C"
        if control.PDTS.enable = '1' and PDTS_state = "1100" then          
          reset_PDTS <= '1';
        end if;
      end if;

      --Create a signal that counts the number of times we start resetting the
      --system from error
      reset_PDTS_last <= reset_PDTS;
      resetter_event <= '0';
      if reset_PDTS = '1' and reset_PDTS_last = '0' then
        --on a rising edge of reset_PDTS
        resetter_event <= '1';
      end if;
    end if;
  end process PDTS_resetter;
  
  monitor.PDTS.event_number <= PD_event_counter;
  pdts_endpoint_1: entity work.pdts_endpoint
    generic map (
      SCLK_FREQ => 50.0)
    port map (
      sclk    => clk_sys_50Mhz,
      srst    => reset_PDTS,
      addr    => WIB_address,
      tgrp    => control.PDTS.timing_group,
      stat    => PDTS_state,

      rec_clk   => clk_DUNE_in,
      rec_d_clk => clk_DTS_data,
      rec_d     => DTS_data_latched(0),--DTS_data_P,
      rec_d_out =>  DTS_data_loopback_buffered,
      rec_clk_locked => clk_DTS_locked,--DTS_SI5344_LOL_N, -- not loss of lock is locked
      rec_clk_reset => reset_req_SI5344,
      
      sfp_los => '0',
      cdr_los => clk_DTS_in_LOS,
      cdr_lol => clk_DTS_in_LOL,
      clk     => clk_PDTS,
      rst     => reset_DTS,
      rdy     => ready_DTS,
      sync    => PD_cmd,
      sync_v  => PD_cmd_valid,
      tstamp  => PD_timestamp,
      evtctr  => PD_event_counter);

  
  
  ---------------------------------------
  -- Monitoring of the PDTS
  ---------------------------------------
  monitor.PDTS.CMD_count_reset <= control.PDTS.CMD_count_reset;
  pdts_cmd_counts: for iCMD in 15 downto 0 generate
    --Generate a pulse for each 
    PDTS_pulse(iCMD) <= '1' when PD_cmd_valid = '1' and PD_cmd = std_logic_vector(to_unsigned(iCMD,4)) else '0';

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


--  DTS_FP_CLK_OUT <= DTS_data_latched;
  DTS_tx_1: entity work.DTS_tx
    port map (
      clk_sys_50Mhz => clk_sys_50Mhz,
      clk_PDTS      => clk_DUNE_in,
      clk_PDTS_d    => clk_DTS_data,
      DTS_data_in   => DTS_data_latched(0),--DTS_data_loopback_buffered,
      DTS_data_out  => DTS_FP_CLK_OUT,
      DTS_OUT_DSBL  => DTS_FP_CLK_OUT_DSBL,
      monitor       => monitor.DTS_Tx,
      control       => control.DTS_Tx);
--  DTS_FP_CLK_OUT <= DTS_data_P;

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
      clk_EB             => clk_EB,
      convert_EB         => convert_EB,
      monitor            => monitor.DTS_Convert,
      control            => control.DTS_Convert);
  


end architecture behavioral;
