library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_misc.all;

use work.Convert_IO.all;
use work.DTS_IO.all;
use work.WIB_Constants.all;
use ieee.numeric_std.all;
use work.types.all;

entity DTS_Convert_Generation is
  
  port (
    clk_DUNE   : in std_logic;
    clk_sys    : in std_logic;
    reset_DUNE : in std_logic;
    ready_DUNE : in std_logic;    
    pdts_cmd   : in std_logic_vector(3 downto 0);
    pdts_cmd_valid : in std_logic;
--    pdts_stat  : in std_logic_vector(3 downto 0);
    pdts_timestamp : in std_logic_vector(63 downto 0);
    pdts_event_counter : in std_logic_vector(31 downto 0);    

    -- DUNE generation
    convert_DUNE    : out   convert_t;
    -- FEMB capture (clk_FEMB_128Mhz)
    clk_FEMB_128Mhz : in    std_logic;
    convert_FEMB    : out   convert_t;
    reset_FEMB_Convert_count : in std_logic;
    -- Event Builder (clk_EB)
    clk_EB          : in    std_logic;
    convert_EB      : out   convert_array_t;
    convert_EB_acks : in  std_logic_vector(DAQ_LINK_COUNT-1 downto 0);

    monitor         : out DTS_Convert_Monitor_t;
    control         : in  DTS_Convert_Control_t
);

end entity DTS_Convert_Generation;

architecture behavioral of DTS_Convert_Generation is

  component CONVERT_FIFO is
    port (
      aclr    : in  STD_LOGIC;
      data    : IN  STD_LOGIC_VECTOR (104 DOWNTO 0);
      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (104 DOWNTO 0);
      rdempty : OUT STD_LOGIC;
      rdusedw : out STD_LOGIC_VECTOR(1 downto 0);
      wrfull  : OUT STD_LOGIC);
  end component CONVERT_FIFO;

  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;
  
  constant CONVERT_BIT_COUNT : integer := 104;

  constant PDTS_WIB_SYNC_COMMAND      : std_logic_vector(3 downto 0) := "0000";--"0101";
  constant PDTS_PERIODIC_SYNC_COMMAND : std_logic_vector(3 downto 0) := "0000";
  constant PDTS_TEST_PULSE_COMMAND : std_logic_vector(3 downto 0) := x"6";

  signal FEMB_stop : std_logic;
  signal FEMB_start : std_logic;
  signal halt_last : std_logic;

  
  -- clk_DUNE domain
  type cs_state_t is (CS_WAIT_FOR_SYNC,
                      CS_IN_SYNC,
                      CS_OUT_OF_SYNC,
                      CS_IDLE,
                      CS_FAKE_WAIT_FOR_SYNC,
                      CS_FAKE_IN_SYNC);
  signal convert_state : cs_state_t := CS_IDLE;
  signal convert_state_buffer : cs_state_t := CS_IDLE;

  constant CONVERT_PERIOD_50Mhz : integer := 25;
  signal convert_pulse_generator : std_logic_vector(CONVERT_PERIOD_50MHz-1 downto 0) := (CONVERT_PERIOD_50MHz-1 => '0', others => '0');
  signal converts_enabled      : std_logic := '0';

  signal expect_sync_counter   : unsigned(31 downto 0);
  signal missed_periodic_syncs : unsigned(31 downto 0) := x"00000000";
  signal out_of_sync           : std_logic := '1';
  signal last_good_sync        : std_logic_vector(63 downto 0);
  
  signal convert_fifo_wr : std_logic := '0';
  signal convert_fifo_wr_delay : std_logic_vector(CONVERT_PERIOD_50Mhz/2 downto 0);
  signal convert_DUNE_bits : std_logic_vector(CONVERT_BIT_COUNT downto 0) := (others => '0');
  
  -- FEMB 128Mhz clock domain
  signal convert_FEMB_bits : std_logic_vector(CONVERT_BIT_COUNT downto 0);
  signal FEMB_fifo_rd : std_logic;
  signal FEMB_fifo_empty : std_logic;
  signal FEMB_data_ready : std_logic;
  
  -- EB clock domain
  type convert_EB_bits_t is array (DAQ_LINK_COUNT-1 downto 0) of std_logic_vector(CONVERT_BIT_COUNT downto 0);
  signal convert_EB_bits : convert_EB_bits_t;
  signal EB_fifo_rd : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
--  signal EB_fifo_used : std_logic_vector(1 downto 0);
  signal EB_fifo_empty : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
--  constant EB_data_ready_delay : integer := 10;
--  signal EB_data_ready : std_logic_vector(EB_data_ready_delay-1 downto 0);
  signal EB_update : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
  signal eb_get_new_trigger : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
  

  constant TIMESTAMP_COUNTER_START : unsigned(63 downto 0) := x"0000000000000000";
  signal timestamp_counter         : unsigned(63 downto 0) := TIMESTAMP_COUNTER_START;
  signal timestamp_counter_buffer  : uint64_array_t(DAQ_LINK_COUNT-1 downto 0);
  signal timestamp                 : std_logic_vector(63 downto 0) := (others => '0');
  signal timestamp_counter_en      : std_logic             := '0';
  signal use_local_timestamp       : std_logic;
  
  signal fake_timestamp : unsigned(63 downto 0) := (others => '0');
  
  signal start_sync : std_logic := '0';

  signal FEMB_Convert_counter : unsigned(15 downto 0);

  --for FEMB hack
  signal DAQ_timestamps_before_sync : std_logic_vector(DAQ_LINK_COUNT-1 downto 0);
  signal EB_OOS : std_logic_vector(1 downto 0);
begin  -- architecture behavioral


  start_sync <= control.start_sync;
  
  ------------------------------------------------------------------------------
  -- DUNE clock domain
  ------------------------------------------------------------------------------

  state_monitor: process (clk_DUNE) is
  begin  -- process state_monitor
    if clk_DUNE'event and clk_DUNE = '1' then  -- rising clock edge
      case convert_state is
        when CS_WAIT_FOR_SYNC      => monitor.state <= x"0";
        when CS_IN_SYNC            => monitor.state <= x"1";
        when CS_OUT_OF_SYNC        => monitor.state <= x"2";
        when CS_IDLE               => monitor.state <= x"3";
        when CS_FAKE_WAIT_FOR_SYNC => monitor.state <= x"4";
        when CS_FAKE_IN_SYNC       => monitor.state <= x"5";
        when others => monitor.state <= x"F";
      end case;
    end if;
  end process state_monitor;
  

  ---------------------------------------
  -- Generate convert pulses
  ---------------------------------------
  -- set convert_DUNE signal
  convert_DUNE.trigger    <= converts_enabled and convert_pulse_generator(0);
  convert_DUNE.time_stamp <= pdts_timestamp when converts_enabled = '1' else (others => '0');
  converts_enabled <= control.converts_enabled;
  monitor.converts_enabled <= control.converts_enabled;
  monitor.halt <= control.halt;


  monitor.enable_fake <= control.enable_fake;


  convert_DUNE.cmd_start           <= FEMB_start;
--  convert_DUNE.cmd_stop            <= '1' when  pdts_cmd_valid = '1' and pdts_cmd = PDTS_CMD_STOP else '0';
  convert_DUNE.cmd_stop            <= FEMB_stop;
  convert_DUNE.cmd_calibrate       <= '1' when  pdts_cmd_valid = '1' and pdts_cmd = PDTS_TEST_PULSE_COMMAND else '0';
--  convert_DUNE.cmd_timestamp_reset <= '1' when  convert_state /= CS_WAIT_FOR_SYNC and pdts_cmd_valid = '1' and pdts_cmd = PDTS_PERIODIC_SYNC_COMMAND else '0';


  FEMB_stop_proc: process (clk_DUNE) is
  begin  -- process FEMB_stop_proc
    if clk_DUNE'event and clk_DUNE = '1' then  -- rising clock edge
      FEMB_stop <= '0';
      halt_last <= control.halt;
      --Send a stop command if the system is halted
      if halt_last = '0' and control.halt = '1' then
        FEMB_stop <= '1';
      end if;
    end if;
  end process FEMB_stop_proc;
  
  convert_generator: process (clk_DUNE) is
  begin  -- process convert_generator
    if clk_DUNE'event and clk_DUNE = '1' then  -- rising clock edge
      -------------------------------------------------------------------------
      -- Real DTS
      -------------------------------------------------------------------------
      
      FEMB_start <= '0';
      --Check if we should halt data taking
      if control.halt = '1' then
        convert_state <= CS_IDLE;
        convert_pulse_generator <= (others => '0');
      else
        case convert_state is
          when  CS_WAIT_FOR_SYNC =>
            ---------------------------------------------------
            -- CS_WAIT_FOR_SYNC
            ---------------------------------------------------          
            convert_pulse_generator <= (others => '0');
            --wait for sync command from timing system          
            if pdts_cmd_valid = '1' and pdts_cmd = PDTS_WIB_SYNC_COMMAND then
              convert_pulse_generator(CONVERT_PERIOD_50MHZ-1) <= '1';
              convert_state <= CS_IN_SYNC;
              FEMB_start <= '1';
            end if;
            
            
          when CS_IN_SYNC =>
            ---------------------------------------------------
            -- CS_IN_SYNC
            ---------------------------------------------------          
            -- cycle the trigger bit
            convert_pulse_generator <= convert_pulse_generator(0) & convert_pulse_generator(CONVERT_PERIOD_50MHZ-1 downto 1);
            --check if we are out of sync
            if out_of_sync = '1' then
              convert_state <= CS_OUT_OF_SYNC;
            end if;
          when CS_OUT_OF_SYNC =>
            ---------------------------------------------------
            -- CS_OUT_OF_SYNC
            ---------------------------------------------------          
            -- cycle the trigger bit
            convert_pulse_generator <= convert_pulse_generator(0) & convert_pulse_generator(CONVERT_PERIOD_50MHZ-1 downto 1);
          when CS_IDLE =>
            ---------------------------------------------------
            -- CS_IDLE
            ---------------------------------------------------
            if start_sync = '1' then
              if  control.enable_fake = '0'  then
                convert_state <= CS_WAIT_FOR_SYNC;
              else
                convert_state <= CS_FAKE_WAIT_FOR_SYNC;
              end if;
            end if;          
          when  CS_FAKE_WAIT_FOR_SYNC =>
            ---------------------------------------------------
            -- CS_WAIT_FOR_SYNC
            ---------------------------------------------------          
            convert_pulse_generator <= (others => '0');
            convert_pulse_generator(CONVERT_PERIOD_50MHZ-1) <= '1';
            convert_state <= CS_FAKE_IN_SYNC;
            FEMB_start <= '1';
          when CS_FAKE_IN_SYNC  =>
            ---------------------------------------------------
            -- CS_IN_SYNC
            ---------------------------------------------------          
            -- cycle the trigger bit
            convert_pulse_generator <= convert_pulse_generator(0) & convert_pulse_generator(CONVERT_PERIOD_50MHZ-1 downto 1);
            
          when others => convert_state <= CS_IDLE;
        end case;  
      end if;
    end if;
  end process convert_generator;


  ---------------------------------------
  -- Monitor convert and timing system for errors
  ---------------------------------------
  monitor.missed_periodic_syncs <= std_logic_vector(missed_periodic_syncs);
  monitor.last_good_sync        <= last_good_sync;
  monitor.out_of_sync           <= out_of_sync;
  monitor.sync_counter_period   <= control.sync_counter_period;
  convert_sync_proc: process (clk_DUNE) is
  begin  -- process convert_sync_proc
    if clk_DUNE'event and clk_DUNE = '1' then  -- rising clock edge
      convert_DUNE.cmd_timestamp_reset <= '0';
      case convert_state is
        when CS_WAIT_FOR_SYNC | CS_FAKE_WAIT_FOR_SYNC =>
          ---------------------------------------------------
          -- CS_WAIT_FOR_SYNC
          ---------------------------------------------------          
          last_good_sync <= (others => '1');
          out_of_sync <= '1';
          expect_sync_counter <= unsigned(control.sync_counter_period) -1;
          missed_periodic_syncs <= x"00000000";

          fake_timestamp <= x"0000000000000000";
          
          if pdts_cmd_valid = '1' and pdts_cmd = PDTS_WIB_SYNC_COMMAND then
            last_good_sync <= (others => '0');
            out_of_sync <= '0';
          end if;                      
        when CS_FAKE_IN_SYNC =>
          
          out_of_sync <= '0';
          if convert_pulse_generator(0) = '1' then
            fake_timestamp <= fake_timestamp + 1;
          end if;
        when CS_IN_SYNC =>
          ---------------------------------------------------
          -- CS_IN_SYNC
          ---------------------------------------------------
          out_of_sync <= '0';
          
          
          -- check for sync messages
          if pdts_cmd_valid = '1' and pdts_cmd = PDTS_PERIODIC_SYNC_COMMAND then
            convert_DUNE.cmd_timestamp_reset <= '1';
            
            --We have a sync command
            -- If things are working correctly, our trigger bit is at index 0
            if convert_pulse_generator(0) = '1' then
              if out_of_sync = '0' then
                last_good_sync <= pdts_timestamp;
              end if;
            else
              out_of_sync <= '1';
            end if;
          end if;

          -- check for missed sync messages          
          if expect_sync_counter = x"00000000" then
            expect_sync_counter <= unsigned(control.sync_counter_period) -1;
            if (pdts_cmd_valid = '0' or
                (pdts_cmd_valid = '1' and pdts_cmd /= PDTS_PERIODIC_SYNC_COMMAND))then              
              missed_periodic_syncs <= missed_periodic_syncs + 1;
            end if;
          else
            expect_sync_counter <= expect_sync_counter -1;
          end if;
          
        when others =>
          out_of_sync <= '1';
      end case;
    end if;
  end process convert_sync_proc;


  ---------------------------------------
  -- Feed convert fifos to other domains
  ---------------------------------------
  convert_fifo_feed: process (clk_DUNE) is
  begin  -- process convert_fifo_feed
    if clk_DUNE'event and clk_DUNE = '1' then  -- rising clock edge
      convert_fifo_wr_delay <= '0' & convert_fifo_wr_delay(convert_fifo_wr_delay'left downto 1);
      
      convert_fifo_wr <= '0';
      case convert_state is
        when CS_IN_SYNC | CS_OUT_OF_SYNC | CS_FAKE_IN_SYNC =>
          if convert_pulse_generator(0) = '1' then
            convert_fifo_wr <= converts_enabled;
            convert_fifo_wr_delay(convert_fifo_wr_delay'left) <= converts_enabled;
            convert_fifo_wr_delay(convert_fifo_wr_delay'left -1 downto 0) <= (others => '0');
            
            convert_DUNE_bits(104 downto 64) <= out_of_sync & x"FFFFFF" & x"FFFF";

            convert_DUNE_bits(63 downto 0) <= pdts_timestamp;

            if convert_state = CS_FAKE_IN_SYNC then
              convert_DUNE_bits(63 downto 0) <= std_logic_vector(fake_timestamp);
            end if;

          end if;
        when others => null;
      end case;
    end if;
  end process convert_fifo_feed;
  
  ------------------------------------------------------------------------------
  -- FEMB clock domain
  ------------------------------------------------------------------------------  
  --Run the FEMB processing on the DCC 128Mhz clock
--  FEMB_fifo_rd <= not FEMB_fifo_empty;
  CONVERT_FIFO_1: entity work.CONVERT_FIFO
    port map (
      aclr    => '0',--FEMB_stop,
      data    => convert_DUNE_bits,
      rdclk   => clk_FEMB_128Mhz,
      rdreq   => FEMB_fifo_rd,
      wrclk   => clk_DUNE,
      wrreq   => convert_fifo_wr,
      q       => convert_FEMB_bits,
      rdempty => FEMB_fifo_empty,
      rdusedw => open,
      wrfull  => open);

  
  
  FEMB_convert_generator : process (clk_FEMB_128Mhz) is
  begin  -- process FEMB_convert_generator
    if clk_FEMB_128Mhz'event and clk_FEMB_128Mhz = '1' then  -- rising clock edge
      convert_FEMB.trigger <= '0';
      
      FEMB_fifo_rd <= '0';
      if FEMB_fifo_empty = '0' and FEMB_fifo_rd = '0' then
        FEMB_fifo_rd <= '1';
      end if;

        
      FEMB_data_ready <= FEMB_fifo_rd;      
      if FEMB_data_ready = '1' then
        --femb counter.
        if reset_FEMB_Convert_count = '1' then
          FEMB_convert_counter <= x"0000";
        else
          FEMB_convert_counter <= FEMB_convert_counter + 1;
        end if;

        convert_FEMB.trigger       <= '1';        
        convert_FEMB.out_of_sync   <= convert_FEMB_bits(104);
        convert_FEMB.reset_count   <= convert_FEMB_bits(103 downto 80);
        convert_FEMB.convert_count <= convert_FEMB_bits(79 downto 64);
        convert_FEMB.time_stamp    <= x"000000000000" & std_logic_vector(FEMB_convert_counter);--convert_FEMB_bits(63 downto  0);
      end if;
    end if;
  end process FEMB_convert_generator;

  ------------------------------------------------------------------------------
  -- EventBuilder clock domain 
  ------------------------------------------------------------------------------
  monitor.use_local_timestamp <= control.use_local_timestamp;
  process (clk_EB) is
  begin  -- process
   if clk_EB'event and clk_EB = '1' then  -- rising clock edge
      use_local_timestamp <= control.use_local_timestamp;    
    end if;
  end process;

  eb_bad_FEMB_hack_proc : process (clk_EB) is
  begin
    if clk_EB'event and clk_EB = '1' then
      --THis syncs the state of the PDTS based convert state machine so that
      --we can pass bad timestamps for the FEMB that can't be synced. 
      EB_OOS(0) <= EB_OOS(1);
      convert_state_buffer <= convert_state;
      if (convert_state_buffer = CS_WAIT_FOR_SYNC) or (convert_state_buffer = CS_IDLE) then
        --We should allow bad timestamps to be used (controlled by a per
        --DAQ_LINK level)
        EB_OOS(1) <= '1';
      else
        --We should use the real timestamps
        EB_OOS(1) <= '0';
      end if;
    end if;
  end process eb_bad_FEMB_hack_proc;

  
  event_builder_converts: for iDAQLink in DAQ_LINK_COUNT-1 downto 0 generate
    CONVERT_FIFO_2: entity work.CONVERT_FIFO
      port map (
        aclr    => '0',--FEMB_Stop,
        data    => convert_DUNE_bits,
        rdclk   => clk_EB,
        rdreq   => EB_fifo_rd(iDAQLink),
        wrclk   => clk_DUNE,
        wrreq   => convert_fifo_wr,--convert_fifo_wr_delay(0), --convert_fifo_wr,
        q       => convert_EB_bits(iDAQLink),
        rdempty => EB_fifo_empty(iDAQLink),
        rdusedw => open,
        wrfull  => open);

    
    eb_capture: process (clk_EB) is
    begin  -- process eb_capture
      if clk_EB'event and clk_EB = '1' then  -- rising clock edge
        convert_EB(iDAQLink).trigger         <= '0';
        EB_fifo_rd(iDAQLink)                 <= '0';


        --Wait for a new timestamp to be available. 
        if (EB_fifo_rd(iDAQLink)         = '0' and
            EB_fifo_empty(iDAQLink)      = '0' and
            eb_get_new_trigger(iDAQLink) = '1') then
          --read the fifo
          EB_fifo_rd(iDAQLink)                  <= '1';
          --We no longer are waiting for a new timestamp
          eb_get_new_trigger(iDAQLink)          <= '0';
          convert_EB(iDAQLink).time_stamp_valid <= '0';
          convert_EB(iDAQLink).out_of_sync      <= '0';
          convert_EB(iDAQLink).reset_count      <= (others => '0');
          convert_EB(iDAQLink).convert_count    <= (others => '0');
          convert_EB(iDAQLink).time_stamp       <= (others => '0');
        end if;
        
        --wait for a ack statement from the EB.
        if convert_EB_acks(iDAQLink) = '1' then
          eb_get_new_trigger(iDAQLink)       <= '1';
          convert_EB(iDAQLink).time_stamp_valid <= '0';
        end if;

        --Wait for the data out of the fifo to be valid
        EB_update(iDAQLink) <= EB_fifo_rd(iDAQLink);

        if EB_update(iDAQLink) = '1' then
          convert_EB(iDAQLink).time_stamp_valid <= '1';
          convert_EB(iDAQLink).trigger       <= '1';
          convert_EB(iDAQLink).out_of_sync   <= convert_EB_bits(iDAQLink)(104);
          convert_EB(iDAQLink).reset_count   <= convert_EB_bits(iDAQLink)(103 downto 80);
          convert_EB(iDAQLink).convert_count <= convert_EB_bits(iDAQLink)(79 downto 64);          
          if use_local_timestamp = '1' then
            convert_EB(iDAQLink).time_stamp <= timestamp_counter_buffer(iDAQLink);
          else
            convert_EB(iDAQLink).time_stamp <= convert_EB_bits(iDAQLink)(63 downto  0);          
          end if;
        end if;

        DAQ_timestamps_before_sync(iDAQLink) <= control.DAQ_timestamps_before_sync(iDAQLink);
        if DAQ_timestamps_before_sync(iDAQLink) = '1' then
          if EB_OOS(0) = '1' then
            convert_EB(iDAQLink).time_stamp_valid <= '1';
            convert_EB(iDAQLink).time_stamp       <= x"DEADBEEF"&timestamp_counter_buffer(iDAQLink)(31 downto 0);
          end if;
        end if;
        
      end if;
    end process eb_capture;
    
  end generate event_builder_converts;
  monitor.DAQ_timestamps_before_sync <= control.DAQ_timestamps_before_sync;


--  EB_convert_generator : process (clk_EB) is
--  begin  -- process EB_convert_generator
--    if clk_EB'event and clk_EB = '1' then  -- rising clock edge
--      convert_EB.trigger <= '0';
--
--      EB_fifo_rd <= '0';
--      if ( (or_reduce(EB_data_ready) = '0' and EB_fifo_rd = '0') and -- no read happening and the
--                                                                     -- used value is getting updated
--           (EB_fifo_used(1) = '1') ) then --we have two or more triggers in the queue
--        EB_fifo_rd <= '1';
--      end if;
--      
--      
--      --Delay to put the timestamp change after it is used by the event builder
--      EB_data_ready <= EB_fifo_rd & EB_data_ready(EB_data_ready_delay-1 downto 1);
--      if EB_data_ready(0) = '1' then
--        convert_EB.trigger       <= '1';
--        convert_EB.out_of_sync   <= convert_EB_bits(104);
--        convert_EB.reset_count   <= convert_EB_bits(103 downto 80);
--        convert_EB.convert_count <= convert_EB_bits(79 downto 64);
--        if control.use_local_timestamp = '1' then
--          convert_EB.time_stamp <= std_logic_vector(timestamp_counter);
--        else
--          convert_EB.time_stamp <= convert_EB_bits(63 downto  0);          
--        end if;
--      end if;
--    end if;
--  end process EB_convert_generator;

  -- system time stamp and latching
  timestamp <= std_logic_vector(timestamp_counter);
  system_timing : process (clk_EB) is
  begin  -- process system_timing
    if clk_EB'event and clk_EB = '1' then  -- rising clock edge
      timestamp_counter(31 downto 0) <= timestamp_counter(31 downto 0) + 1;
      if timestamp_counter(31 downto 0) = x"FFFFFFFF" then
        timestamp_counter(63 downto 32) <= timestamp_counter(63 downto 32) + 1;
      end if;
      timestamp_counter_buffer <= (others => std_logic_vector(timestamp_counter));
--timestamp_counter <= timestamp_counter + 1;
    end if;
  end process system_timing;


end architecture behavioral;
