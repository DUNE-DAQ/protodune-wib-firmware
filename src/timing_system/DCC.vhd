library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use work.DCC_IO.all;
use work.Convert_IO.all;
use work.WIB_IO.all;
use work.pdts_defs.all;

entity DCC is
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
    monitor         : out   DCC_Monitor_t;
    control         : in    DCC_Control_t
    );

end entity DCC;

architecture behavioral of DCC is

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
      count       : out unsigned(DATA_WIDTH-1 downto 0);
      at_max      : out std_logic);
  end component counter;
  
  component DUNE_50Mhz_mux is
    port (
      inclk3x   : in  std_logic                    := 'X';
      inclk2x   : in  std_logic                    := 'X';
      inclk1x   : in  std_logic                    := 'X';
      inclk0x   : in  std_logic                    := 'X';
      clkselect : in  std_logic_vector(1 downto 0) := (others => 'X');
      outclk    : out std_logic);
  end component DUNE_50Mhz_mux;

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
      rec_clk_locked : in std_logic; -- recovered clock locked
      rec_clk_reset : out std_logic; -- reset of SI5344
      sfp_los : in  std_logic;
      cdr_los : in  std_logic;
      cdr_lol : in  std_logic;
      clk     : out std_logic;
      rst     : out std_logic;
      rdy     : out std_logic;
      sync    : out std_logic_vector(SCMD_W-1 downto 0);
      sync_v  : out std_logic;
      tstamp  : out std_logic_vector(8 * TSTAMP_WDS - 1 downto 0); -- Timestamp out
      evtctr  : out std_logic_vector(8 * EVTCTR_WDS - 1 downto 0) -- Event counter out
      );
  end component pdts_endpoint;

  component CONVERT_FIFO is
    port (
      data    : IN  STD_LOGIC_VECTOR (103 DOWNTO 0);
      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (103 DOWNTO 0);
      rdempty : OUT STD_LOGIC;
      wrfull  : OUT STD_LOGIC);
  end component CONVERT_FIFO;

  component FAKE_DTS is
    port (
      clk_DUNE      : in  std_logic;
      reset         : in  std_logic;
      convert       : out std_logic;
      reset_count   : out std_logic_vector(23 downto 0);
      convert_count : out std_logic_vector(15 downto 0);
      monitor       : out FAKE_DTS_Monitor_t;
      control       : in  FAKE_DTS_Control_t);
  end component FAKE_DTS;

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

  component DCC_SI5344_Control is
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
  end component DCC_SI5344_Control;

  component SimpleClock is
    port (
      inclk  : in  std_logic := 'X';
      outclk : out std_logic);
  end component SimpleClock;
  component global
    port (
      a_in : in std_logic;
      a_out : out std_logic);
  end component;	

  
  -- SYS clock domain
  signal WIB_address : std_logic_vector(7 downto 0) := (others => '1');
  signal reset_req_SI5344 : std_logic := '0';
  
  -- DUNE 50Mhz clock domain
  signal DUNE_clk_sel : std_logic_vector(1 downto 0) := "10";
  signal clk_PDTS : std_logic := '0';
  signal reset_PDTS : std_logic := '0';
  signal clk_DUNE_in : std_logic := '0';
  signal clk_DTS_data : std_logic := '0';
  signal clk_DUNE_local : std_logic;
  signal clk_DUNE_in_LOL : std_logic := '1' ;
  signal clk_DUNE_in_LOS : std_logic := '1';
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
  
  -- DUNE 128Mhz clock domain
  signal FEMB_convert : std_logic := '0';
  signal convert_FEMB_bits : std_logic_vector(103 downto 0);
  signal convert_read_FEMB : std_logic := '0';
  signal convert_fifo_FEMB_empty : std_logic := '1';
  
  -- EB clock domain
  signal EB_convert : std_logic := '0';
  constant TIMESTAMP_COUNTER_START : unsigned(63 downto 0) := x"0000000000000000";
  signal timestamp_counter         : unsigned(63 downto 0) := TIMESTAMP_COUNTER_START;
  signal timestamp                 : std_logic_vector(63 downto 0) := (others => '0');
  signal timestamp_counter_en      : std_logic             := '0';
  signal convert_EB_bits : std_logic_vector(103 downto 0);
  signal convert_read_EB : std_logic := '0';
  signal convert_fifo_EB_empty : std_logic := '1';

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
      reset       => reset,
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

  DCC_SI5344_Control_1: entity work.DCC_SI5344_Control
    port map (
      clk_sys_50Mhz => clk_sys_50Mhz,
      reset         => reset,
      clk_DTS       => clk_PDTS,
      reset_DTS     => reset_req_SI5344,
      SI5344_RST_N  => DTS_SI5344_RST_N,
      SI5344_IN_SEL => DTS_SI5344_IN_SEL,
      SI5344_OE_N   => DTS_SI5344_OE_N,
      SI5344_LOL_N  => DTS_SI5344_LOL_N,
      SI5344_LOS_N  => DTS_SI5344_LOS_N,
      SI5344_INT_N  => DTS_SI5344_INT_N,
      DTS_SI5344_SCL => DTS_SI5344_SCL,
      DTS_SI5344_SDA => DTS_SI5344_SDA,
      monitor       => monitor.SI5344,
      control       => control.SI5344);

  ---------------------------------------
  -- Generate DUNE clock
  ---------------------------------------

  --Allow us to bypass the PDTS and use the local system clock
  monitor.DUNE_clk_sel <= control.DUNE_clk_sel;
  DUNE_clk_sel         <= control.DUNE_clk_sel & '1';
--  DUNE_50Mhz_mux_2: DUNE_50Mhz_mux
--    port map (
--      inclk3x   => clk_sys_50Mhz,
--      inclk2x   => 'X',
--      inclk1x   => clk_PDTS,
--      inclk0x   => 'X',
--      clkselect => DUNE_clk_sel,
--      outclk    => clk_DUNE_local);
  clk_DUNE_local <= clk_PDTS;
  -- Send out DUNE clock to FPGA
  clk_DUNE <= clk_DUNE_local;

  -- output if the DUNE clock is locked
  clk_DUNE_lock_on: process (PDTS_state,DUNE_clk_sel) is
  begin  -- process clk_DUNE_lock_on
    locked_DUNE <= '0';
    case DUNE_clk_sel is
      when "11" =>
        --Always locked when using the local clock
        locked_DUNE <= '1';
      when "10" =>
        -- locked depends on many things in PDTS, but is locked when we are in
        -- PDTS_stat == RUN
        if PDTS_state = "1000" then
          locked_DUNE <= '1';
        end if;
      when others => null;
    end case;
  end process clk_DUNE_lock_on;



  ------------------------------------------------------------------------------
  -- DUNE  clock domain
  ------------------------------------------------------------------------------  
  -- put DUNE clock on clock routing

  dune_clk_buffer: SimpleClock
    port map (
      inclk  => DUNE_clk_in_P,
      outclk => clk_DUNE_in);
  PDTS_clk_buffer: SimpleClock
    port map (
      inclk  => DTS_data_clk_P,
      outclk => clk_DTS_data);
  
--  dune_clk_buffer: global
--    port map (
--      a_in  => DUNE_clk_in_P,
--      a_out => clk_DUNE_in);
--  PDTS_clk_buffer: global
--    port map (
--      a_in  => DTS_data_clk_P,
--      a_out => clk_DTS_data);


  monitor.PDTS.state <= PDTS_state;
  monitor.PDTS.timing_group <= control.PDTS.timing_group;
  monitor.PDTS.cdr_los <= DTS_CDS_LOS;
  monitor.PDTS.cdr_lol <= DTS_CDS_LOL;
  monitor.PDTS.reset <= reset_DTS;
  monitor.PDTS.ready <= ready_DTS;
  monitor.PDTS.enable <= control.PDTS.enable;
  reset_PDTS <= not control.PDTS.enable;

  clk_DUNE_in_LOL <= not DTS_SI5344_LOL_N;
  clk_DUNE_in_LOS <= not DTS_SI5344_LOS_N;
  
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
      rec_d     => DTS_data_P,
      rec_clk_locked => DTS_SI5344_LOL_N, -- not loss of lock is locked
      rec_clk_reset => reset_req_SI5344,
      
      sfp_los => '0',
      cdr_los => clk_DUNE_in_LOS,--DTS_CDS_LOS,
      cdr_lol => clk_DUNE_in_LOL,--DTS_CDS_LOL,
      clk     => clk_PDTS,
      rst     => reset_DTS,
      rdy     => ready_DTS,
      sync    => PD_cmd,
      sync_v  => PD_cmd_valid,
      tstamp  => PD_timestamp,
      evtctr  => PD_event_counter);

  

  monitor.PDTS.CMD_count_reset <= control.PDTS.CMD_count_reset;
  pdts_cmd_counts: for iCMD in 15 downto 0 generate
    --Generate a pulse for each 
    PDTS_pulse(iCMD) <= '1' when PD_cmd_valid = '1' and PD_cmd = std_logic_vector(to_unsigned(iCMD,4)) else '0';
    
    counter_1: entity work.counter
      port map (
        clk         => clk_DUNE_local,
        reset_async => '0',
        reset_sync  => control.PDTS.CMD_count_reset(iCMD),
        enable      => '1',
        event       => PDTS_pulse(iCMD),
        count       => monitor.PDTS.CMD_count(iCMD),
        at_max      => open);
  end generate pdts_cmd_counts;
  
  reset_DUNE <= '0' when PDTS_state = "1000" else '1';


  
--  monitor.FAKE_DTS.reset_count <= control.FAKE_DTS.reset_count;
  FAKE_DTS_1: entity work.FAKE_DTS
    port map (
      clk_DUNE      => clk_DUNE_local,
      reset         => reset,
      convert       => convert_FAKE,
      reset_count   => convert_count_FAKE(39 downto 16),
      convert_count => convert_count_FAKE(15 downto  0),
      monitor       => monitor.FAKE_DTS,
      control       => control.FAKE_DTS);

  monitor.local_triggering <= control.local_triggering;
  trigger_system: process (control.local_triggering) is
  begin  -- process trigger_system
    if control.local_triggering = '0' then
      if PD_cmd_valid = '1' and PD_cmd = x"f" then
        DUNE_convert <= '1';
        DUNE_timestamp <= x"00000000"&PD_timestamp(31 downto 0);
        DUNE_convert_count <= PD_event_counter(15 downto 0);
        DUNE_reset_count <= x"00" & PD_event_counter(31 downto 16);
      else
        DUNE_convert <= '0';
      end if;
    else
      if convert_FAKE = '1' then
        DUNE_convert <= '1';
        DUNE_timestamp <= (others => '0');
        DUNE_convert_count <= convert_count_FAKE(15 downto 0);
        DUNE_reset_count   <= convert_count_FAKE(23 downto 0);
      else
        DUNE_convert <= '0';
      end if;
    end if;
  end process trigger_system;

  
  
  
  ------------------------------------------------------------------------------
  -- DCC Commands and Triggering
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  DUNE_convert_generator: process (clk_DUNE_local, reset) is
  begin  -- process DUNE_convert_generator
    if reset = '1' then                 -- asynchronous reset (active high)
      convert_DUNE.trigger       <= '0';
      --Reset to end values for debugging
      convert_DUNE.reset_count   <= (others => '1');
      convert_DUNE.convert_count <= (others => '1');      
    elsif clk_DUNE_local'event and clk_DUNE_local = '1' then  -- rising clock edge

      convert_DUNE.trigger <= '0';
      convert_fifo_wr      <= '0';

      if DUNE_convert = '1' then
        convert_DUNE.trigger       <= '1';        
        convert_DUNE.reset_count   <= DUNE_reset_count;
        convert_DUNE.convert_count <= DUNE_convert_count;
        convert_DUNE.time_stamp    <= DUNE_timestamp;    
        monitor.reset_count        <= DUNE_reset_count;  
        monitor.convert_count      <= DUNE_convert_count;
        monitor.time_stamp         <= DUNE_timestamp;    
        convert_fifo_wr            <= '1';
      end if;
     
    end if;
  end process DUNE_convert_generator;
  convert_DUNE_bits <= DUNE_reset_count & DUNE_convert_count & DUNE_timestamp;
  
  
  ------------------------------------------------------------------------------
  -- FEMB clock domain
  ------------------------------------------------------------------------------  
  --Run the FEMB processing on the DCC 128Mhz clock

  CONVERT_FIFO_1: entity work.CONVERT_FIFO
    port map (
      data    => convert_DUNE_bits,
      rdclk   => clk_FEMB_128Mhz,
      rdreq   => convert_read_FEMB,
      wrclk   => clk_DUNE_local,
      wrreq   => convert_fifo_wr,
      q       => convert_FEMB_bits,
      rdempty => convert_fifo_FEMB_empty,
      wrfull  => open);

  
  
  FEMB_convert_generator : process (clk_FEMB_128Mhz, reset) is
  begin  -- process FEMB_convert_generator
    if reset = '1' then                 -- asynchronous reset (active high)
      convert_FEMB.trigger       <= '0';
      --Reset to end values for debugging
      convert_FEMB.reset_count   <= (others => '1');
      convert_FEMB.convert_count <= (others => '1');
    elsif clk_FEMB_128Mhz'event and clk_FEMB_128Mhz = '1' then  -- rising clock edge

      convert_FEMB.trigger <= '0';
      convert_read_FEMB    <= '0';
      
      if convert_fifo_FEMB_empty = '0' and convert_read_FEMB = '0' then
        convert_read_FEMB          <= '1';
        convert_FEMB.trigger       <= '1';
        convert_FEMB.reset_count   <= convert_FEMB_bits(103 downto 80);
        convert_FEMB.convert_count <= convert_FEMB_bits(79 downto 64);
        convert_FEMB.time_stamp    <= convert_FEMB_bits(63 downto  0);
      end if;
    end if;
  end process FEMB_convert_generator;

  ------------------------------------------------------------------------------
  -- EventBuilder clock domain 
  ------------------------------------------------------------------------------  
  CONVERT_FIFO_2: entity work.CONVERT_FIFO
    port map (
      data    => convert_DUNE_bits,
      rdclk   => clk_EB,
      rdreq   => convert_read_EB,
      wrclk   => clk_DUNE_local,
      wrreq   => convert_fifo_wr,
      q       => convert_EB_bits,
      rdempty => convert_fifo_EB_empty,
      wrfull  => open);

  monitor.local_timestamp <= control.local_timestamp;
  EB_convert_generator : process (clk_EB, reset) is
  begin  -- process EB_convert_generator
    if reset = '1' then                 -- asynchronous reset (active high)
      convert_EB.trigger       <= '0';
      --Reset to end values for debugging
      convert_EB.reset_count   <= (others => '1');
      convert_EB.convert_count <= (others => '1');
    elsif clk_EB'event and clk_EB = '1' then  -- rising clock edge

      convert_EB.trigger <= '0';
      convert_read_EB    <= '0';
      
      if convert_fifo_EB_empty = '0' and convert_read_EB = '0' then
        convert_read_EB          <= '1';
        convert_EB.trigger       <= '1';
        convert_EB.reset_count   <= convert_EB_bits(103 downto 80);
        convert_EB.convert_count <= convert_EB_bits(79 downto 64);
        if control.local_timestamp = '1' then
          convert_EB.time_stamp <= std_logic_vector(timestamp_counter);
        else
          convert_EB.time_stamp <= convert_EB_bits(63 downto  0);          
        end if;
      end if;
    end if;
  end process EB_convert_generator;

  -- system time stamp and latching
  timestamp <= std_logic_vector(timestamp_counter);
  system_timing : process (clk_EB, reset) is
  begin  -- process system_timing
    if reset = '1' then                 -- asynchronous reset (active high)
      timestamp_counter    <= TIMESTAMP_COUNTER_START;
    elsif clk_EB'event and clk_EB = '1' then  -- rising clock edge
        timestamp_counter <= timestamp_counter + 1;
    end if;
  end process system_timing;

end architecture behavioral;
