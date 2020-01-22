library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use work.COLDATA_IO.all;
use work.FEMB_DAQ_IO.all;
use work.Convert_IO.all;
use work.CD_EB_BRIDGE.all;
use work.WIB_Constants.all;

entity CD_Stream_Processor is
  generic (
    IS_LINK_A : std_logic := '1');
  port (            
    --Data in (CD clock)
    clk_CD          : in std_logic;
    reset_CD        : in std_logic;
    COLDATA_stream  : in std_logic_vector(8 downto 0);
    COLDATA_valid   : in std_logic;
    convert         : in convert_t;

    --Data out (DAQ clock)
    clk_EVB         : in std_logic;
    --Per CD frame
    CD_to_EB_stream : out CD_Stream_t;    
    EB_rd           : in  std_logic;

    --Monitoring/control
    monitor         : out CD_Stream_Monitor_t;
    control         : in  CD_Stream_Control_t
    );  -- single COLDATA stream

end entity CD_Stream_Processor;

architecture behavioral of CD_Stream_Processor is


  signal reset_EVB_local  : std_logic := '1';
  
  component reseter is
    generic (
      DEPTH : integer);
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      reset       : out std_logic);
  end component reseter;
  
  component pacd is
    port (
      iPulseA : IN  std_logic;
      iClkA   : IN  std_logic;
      iRSTAn  : IN  std_logic;
      iClkB   : IN  std_logic;
      iRSTBn  : IN  std_logic;
      oPulseB : OUT std_logic);
  end component pacd;

  component CD_FIFO is
    port (
      aclr    : IN  STD_LOGIC := '0';
      data    : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
      rdempty : OUT STD_LOGIC;
      wrfull  : OUT STD_LOGIC);
  end component CD_FIFO;
  signal data_in_wr      : std_logic := '0';
  signal data_rd         : std_logic := '0';
  signal data_rd_comb    : std_logic := '0';
  signal data_fifo_FULL : std_logic := '0';
  signal data_out : std_logic_vector(31 downto 0);
  
  component CD_description_FIFO is
    port (
      aclr    : IN  STD_LOGIC := '0';
      data    : IN  STD_LOGIC_VECTOR (47 DOWNTO 0);
      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (47 DOWNTO 0);
      rdempty : OUT STD_LOGIC;
      rdusedw : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
      wrfull  : OUT STD_LOGIC);
  end component CD_description_FIFO;
  signal description_wr : std_logic := '0';
  signal description : std_logic_vector(47 downto 0) := (others => '0');
  signal description_fifo_full : std_logic := '0';
  signal description_fifo_used_rd : std_logic_vector(7 downto 0);
  signal event_info : std_logic_vector(47 downto 0) := (others => '0');
  signal eb_info_ack : std_logic := '0';
  signal no_frames_available : std_logic := '1';


  signal word_number : unsigned(5 downto 0) := (others => '0');
  signal write_count : unsigned(5 downto 0) := (others => '0');
  signal readout_count : integer range 15 downto 1 := 14;

  signal CD_delay  : std_logic_vector(8 downto 0);
  
  -------------------------------------------------------------------------------
  -- Errors from captured data
  -------------------------------------------------------------------------------
  
  signal data_errors : std_logic_vector(7 downto 0) := (others => '0');
  constant ERR_NOT_FINISHED : integer := 0;
  constant ERR_BAD_SOF      : integer := 1;
  constant ERR_LARGE_FRAME  : integer := 2;
  constant ERR_K_IN_FRAME   : integer := 3;
  constant ERR_CHSUM_BAD    : integer := 7;

  signal running_checksum   : unsigned(23 downto 0) := (others => '0');
  signal computed_checksum  : unsigned(23 downto 0) := (others => '0');
  signal stream_checksum    : unsigned(15 downto 0) := (others => '0');
  signal stream_timestamp   : std_logic_vector(15 downto 0) := (others => '0');
  signal stream_errors      : std_logic_vector(15 downto 0) := (others => '0');


  signal last_timestamp   : std_logic_vector(15 downto 0) := (others => '0');
  -- Error counters
  component timed_counter is
    generic (
      timer_count : std_logic_vector;
      DATA_WIDTH  : integer);
    port (
      clk         : in  std_logic;
      reset_async : in  std_logic;
      reset_sync  : in  std_logic;
      enable      : in  std_logic;
      event       : in  std_logic;
      timed_count : out std_logic_vector(DATA_WIDTH-1 downto 0));
  end component timed_counter;
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
  -- Error pulses
  signal error_BUFFER_FULL            : std_logic := '0';
  signal error_CONVERT_IN_WAIT_WINDOW : std_logic := '0';
  signal error_BAD_SOF                : std_logic := '0';
  signal error_UNEXPECTED_EOF         : std_logic := '0';
  signal error_MISSING_EOF            : std_logic := '0';
  signal error_KCHAR_IN_DATA          : std_logic := '0';
  signal error_BAD_CHSUM              : std_logic := '0';
  signal error_BAD_RO_START           : std_logic := '0';
  signal error_BAD_RO_START_CD_DOMAIN : std_logic := '0';
  signal error_BAD_WRITE_COUNT        : std_logic := '0';
  signal error_timestamp_incr         : std_logic := '0';
  signal pulse_packet_start           : std_logic := '0';


  -------------------------------------------------------------------------------
  -- Capture state machine
  -------------------------------------------------------------------------------   
  type Capture_state_t is (CAP_STATE_IDLE,        --Wait for idles to finish
                                                  --and to get a new page
                           CAP_STATE_START,       --Wati ffor the first frame
                           CAP_STATE_SKIP_WORD,   -- Skip the word after the
                                                  -- SOF due to
                                                  -- miscommunication on the
                                                  -- FEMB firmware
                           CAP_STATE_INIT,        --Wait for and IDLE character
                                                  --to show we are locked
                           CAP_STATE_PROCESS,     --Process the incomming data
                           CAP_STATE_END          --This is the first word
                                                  --after the last word of
                                                  --frame data
                           );
  signal capture_state : capture_state_t := CAP_STATE_INIT;
  constant CAPTURE_IDLE_COUNT_START : integer range 8 downto 0 := 6;
  -- updating this value from 4 because of the variable number due to slips. 4;
  --New value of 4 is due to swap of one idle and SOF words in the FEMB. when this
  --is fixed switch back to 5--5;--8;
  signal capture_idle_count : integer range 8 downto 0 := CAPTURE_IDLE_COUNT_START;
  
  -------------------------------------------------------------------------------
  -- Capture state machine
  -------------------------------------------------------------------------------   
  type readout_state_t is (RDOUT_STATE_IDLE,       --Waiting for a new valid page
                           RDOUT_STATE_CHECKING, --Compare checksums
                           RDOUT_STATE_WAIT,     --Wait for read to start

                                                   --errors, set ready for reading
                           RDOUT_STATE_READING     --FIFO-like readout of raw data
                           );
  signal readout_state : readout_state_t := RDOUT_STATE_IDLE;
  signal wait_for_first_real_trigger : std_logic := '1';
  -------------------------------------------------------------------------------
  -- capture delay
  -------------------------------------------------------------------------------
  signal   send_startup_pulse : std_logic := '1';  
  signal   start_EVB_pulse_CDCLK : std_logic := '0';
  signal   start_EVB_pulse_EVBCLK : std_logic := '0';
  constant READOUT_DELAY_COUNTDOWN_START : unsigned(7 downto 0) := x"0f";
  signal   readout_delay_countdown : unsigned(7 downto 0) := READOUT_DELAY_COUNTDOWN_START;
  signal   enable_readout : std_logic := '0';
  signal wait_done : std_logic := '0';  
  signal EB_rd_last : std_logic := '0';
  
begin  -- architecture behavioral

  
  -------------------------------------------------------------------------------
  -- resets
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------

  --Since a reset on either end of this should reset the pages, we take the or
  --of the resets in each of the clock domains as an async reset that must be
  --properly propogated to each domain's sync reset.
--  reset_local <= reset_CD or reset_EVB; --async
  
--  reseter_1: entity work.reseter
--    port map (
--      clk         => clk_CD,
--      reset_async => reset_EVB,
--      reset_sync  => reset_CD,
--      reset       => reset_CD_local);
--
  reseter_2: entity work.reseter
    generic map (
      DEPTH => 4)
    port map (
      clk         => clk_EVB,
      reset_async => reset_CD,
      reset_sync  => '0',
      reset       => reset_EVB_local);
  
  -------------------------------------------------------------------------------
  -- CD clock domain
  -------------------------------------------------------------------------------   

  -------------------------------------------------------------------------------
  --Delay the convert signal to take into account the loop-back delay
  -------------------------------------------------------------------------------

  monitor.wait_window <= control.wait_window;
  monitor.enable <= control.enable;

  capture_state_machine: process (clk_CD) is
  begin  -- process capture_state_machine
    if clk_CD'event and clk_CD = '1' then  -- rising clock edge

      CD_delay <= COLDATA_stream;

      --State machine
      
      if ((reset_CD = '1') or --2017-11-14 replace "and" with an "or"
          (control.enable = '0')) then
        --Sync reset or diabled link
        capture_state <= CAP_STATE_INIT;
      else
        if COLDATA_valid = '1' then          
          case capture_state is
            -------------------------------------------------------------
            when CAP_STATE_INIT =>
              --Wait for an idle character to be locked on
              capture_state <= CAP_STATE_INIT;
              if COLDATA_stream = IDLE_CHARACTER then
                --move on to parsing data
                capture_state <= CAP_STATE_IDLE;              
              end if;
              wait_for_first_real_trigger <= '1';            
            -------------------------------------------------------------
            when CAP_STATE_IDLE =>
              if COLDATA_stream = SOF_CHARACTER then
                capture_state <= CAP_STATE_START;
              end if;
            -------------------------------------------------------------
            when CAP_STATE_START =>
              capture_state <= CAP_STATE_SKIP_WORD;
            -------------------------------------------------------------
            when CAP_STATE_SKIP_WORD =>
              capture_state <= CAP_STATE_PROCESS;
            -------------------------------------------------------------
            when CAP_STATE_PROCESS =>
              capture_state <= CAP_STATE_PROCESS;
              if ((CDA_SWITCH = '0' and word_number = CDA_FRAME_SIZE-1) or
                  (CDA_SWITCH = '1' and word_number = CDF_FRAME_SIZE-1)) then
                capture_state <= CAP_STATE_END;
              end if;
            -------------------------------------------------------------
            when CAP_STATE_END =>
              capture_state <= CAP_STATE_IDLE;
              if COLDATA_stream = SOF_CHARACTER then
                capture_state <= CAP_STATE_START;
              end if;
            -------------------------------------------------------------
            when others => capture_state <= CAP_STATE_INIT;
          end case;
        end if;
      end if;      
    end if;
  end process capture_state_machine;

  capture_checksum: process (clk_CD) is
  begin  -- process capture_checksum
    if clk_CD'event and clk_CD = '1' then  -- rising clock edge
      if reset_CD = '1' then
        running_checksum <= (others => '0');
      else        
        if COLDATA_valid = '1' then
          case capture_state is
            when CAP_STATE_PROCESS =>
              
              --update checksum
              if ( (CDA_SWITCH = '0' and word_number = CDA_WORD_COLDATA_CHECKSUM_LSB) or
                   (CDA_SWITCH = '1' and word_number = CDF_WORD_COLDATA_CHECKSUM_LSB)) then
                running_checksum <= x"000000";
              elsif ( (CDA_SWITCH = '0' and word_number = CDA_FRAME_SIZE -1) or
                      (CDA_SWITCH = '1' and word_number = CDF_FRAME_SIZE -1)) then
                -- the last word was the last word of the frame, we can build the
                -- final checksum
                running_checksum(23 downto 16) <= (others => '0');
                running_checksum(15 downto  0) <= running_checksum(15 downto 0) + running_checksum(23 downto 16);
              else
                if word_number(0) = '1' then
                  --odd numbers are MSB of the counter
                  running_checksum <= running_checksum + unsigned(COLDATA_stream(7 downto 0) & x"00");
                else
                  --even numbers are the LSB of the counter
                  running_checksum <= running_checksum + unsigned(COLDATA_stream(7 downto 0)        );
                end if;
              end if;

            when others => NULL;
          end case;          
        end if;
      end if;
    end if;
  end process capture_checksum;
  
  
  capture_control: process (clk_CD) is
  begin  -- process capture_control
    if clk_CD'event and clk_CD = '1' then  -- rising clock edge

      --Error counter pule resets
      error_CONVERT_IN_WAIT_WINDOW <= '0';
      error_BAD_SOF <= '0';
      error_UNEXPECTED_EOF <= '0';
      error_MISSING_EOF <= '0';
      error_KCHAR_IN_DATA <= '0';
      error_BAD_CHSUM <= '0';
      error_BUFFER_FULL <= '0';
      error_timestamp_incr <= '0';

      error_BAD_WRITE_COUNT <= '0';
      pulse_packet_start <= '0';      

      data_in_wr <= '0';

      description_wr <= '0';
      if reset_CD = '1' then 
        capture_idle_count <= CAPTURE_IDLE_COUNT_START;
        data_errors(ERR_NOT_FINISHED) <= '0';
        word_number <= (others => '0');
        write_count <= (others => '0');
        stream_checksum <= (others => '0');
        stream_timestamp <= (others => '0');
        stream_errors <= (others => '0');
        last_timestamp <= (others => '0');
        data_errors <= (others => '0');
      else
        if COLDATA_valid = '1' then
          case capture_state is
            -------------------------------------------------------------
            when CAP_STATE_INIT =>
              capture_idle_count <= CAPTURE_IDLE_COUNT_START;
            -------------------------------------------------------------
            when CAP_STATE_START =>
              -- Start taking data
              data_in_wr <= '0';
              
              pulse_packet_start <= '1';
            -------------------------------------------------------------
            when CAP_STATE_SKIP_WORD =>
              data_errors(ERR_NOT_FINISHED) <= '0';
              
              word_number <= (others => '0');
              if data_fifo_FULL = '0' then
                data_in_wr <= '1';
                write_count <= write_count + 1;
              else
                data_in_wr <= '0';
                error_BUFFER_FULL <= '1';
              end if;


            -------------------------------------------------------------
            when CAP_STATE_PROCESS =>

              -----------------------------
              -- process the data word
              -----------------------------
              
              --Save incomming data to fifo
              if ((CDA_SWITCH = '0' and word_number = CDA_FRAME_SIZE - 1) or
                  (CDA_SWITCH = '1' and word_number = CDF_FRAME_SIZE - 1)) then
                data_in_wr <= '0';
              else
                --Here we need to change what we save based on the channel type A
                --or B
                if IS_LINK_A = '1' then
                  -- link A's writes
                  if ((word_number = CDF_WORD_COLDATA_TIME_2     - 1) or
                      (word_number = CDF_WORD_COLDATA_ERRORS_2   - 1) or
                      (word_number = CDF_WORD_COLDATA_RESERVED_2 - 1)) then
                    --We don't send these on because the are on Channel B
                    data_in_wr <= '0';
                  else
                    -- we want this data
                    if data_fifo_FULL = '0' then
                      data_in_wr <= '1';
                      write_count <= write_count + 1;
                    else
                      data_in_wr <= '0';
                      error_BUFFER_FULL <= '1';
                    end if;                  
                  end if;
                else
                  -- link B's writes
                  if ((word_number = CDF_WORD_COLDATA_TIME_1     - 1) or
                      (word_number = CDF_WORD_COLDATA_ERRORS_1   - 1) or
                      (word_number = CDF_WORD_COLDATA_RESERVED_1 - 1)) then
                    --We don't send these on because the are on Channel A
                    data_in_wr <= '0';
                  else
                    -- we want this data
                    if data_fifo_FULL = '0' then
                      data_in_wr <= '1';
                      write_count <= write_count + 1;
                    else
                      data_in_wr <= '0';
                      error_BUFFER_FULL <= '1';
                    end if;                  
                  end if;
                end if;              
              end if;


              --update word number
              word_number <= word_number + 1;
              


              -----------------------------
              -- Check for bad words (errors)
              -----------------------------
              
              --Check if it is idle
              if CD_delay = IDLE_CHARACTER then
                --There was an idle word in the data part of the frame,
                --mark the event as not finished since it is short, but capture
                --the full count for debugging
                error_UNEXPECTED_EOF <= '1';
                data_errors(ERR_NOT_FINISHED) <= '1';
              end if;
              
              --check for a k-char in the data stream
              if CD_delay(8) = '1' then
                data_errors(ERR_K_IN_FRAME) <= '1';
                error_KCHAR_IN_DATA <= '1';
              end if;

              
              
              --Cache useful things for error checking
              case word_number is
                when CDF_WORD_COLDATA_CHECKSUM_LSB =>
                  stream_checksum(15 downto 8)  <= unsigned(CD_delay(7 downto 0));
                when CDF_WORD_COLDATA_CHECKSUM_MSB =>
                  stream_checksum( 7 downto 0)  <= unsigned(CD_delay(7 downto 0));
                when CDF_WORD_COLDATA_TIME_1       =>
                  stream_timestamp( 7 downto 0) <= CD_delay(7 downto 0);
                when CDF_WORD_COLDATA_TIME_2       =>
                  stream_timestamp(15 downto 8) <= CD_delay(7 downto 0);
                when CDF_WORD_COLDATA_ERRORS_1       =>
                  stream_errors( 7 downto 0)    <= CD_delay(7 downto 0);
                when CDF_WORD_COLDATA_ERRORS_2       =>
                  stream_errors(15 downto 8)    <= CD_delay(7 downto 0);
                  
                  -- Check the stream_tiemstamp to see if it is the last
                  -- timestamp plus 1
                  if unsigned(stream_timestamp) /= (unsigned(last_timestamp) + 1) then
                    error_timestamp_incr <= '1';                  
                  end if;
                  --store the timestamp for the next frame
                  last_timestamp <= stream_timestamp;
                  
                when others => null;
              end case;                
            -------------------------------------------------------------
            when CAP_STATE_END =>
              --This is the word after the last word and should be an idle word
              
              --mark the data as finished (if it wasn't already set as not finished)
              --data_errors(WR_PAGE)(ERR_NOT_FINISHED) <= '0' or data_errors(WR_PAGE)(ERR_NOT_FINISHED);
              --compare the checksums and update the checksum error bit in the
              --capture errors
--            if std_logic_vector(stream_checksum) = std_logic_vector(unsigned(x"00"&running_checksum(15 downto 0)) + unsigned(x"0000"&running_checksum(23 downto 16)))(15 downto 0) then
              if stream_checksum = running_checksum(15 downto 0) then
                error_BAD_CHSUM <= '0';
                data_errors(ERR_CHSUM_BAD) <= '0';
              else
                error_BAD_CHSUM <= '1';
                data_errors(ERR_CHSUM_BAD) <= '1';
              end if;
              computed_checksum <= running_checksum;
              
              --Check that it ended correctly
              if CD_delay /= IDLE_CHARACTER then
                --The character after the 55 bytes wasn't an IDLE
                --force and end and mark it as bad
                data_errors(ERR_LARGE_FRAME) <= '1';
                error_MISSING_EOF <= '1';
              end if;

              --Write description to flag a new CD frame done
              description_wr <= '1';
              
              
              --Get ready for the idle processing state
              capture_idle_count <= CAPTURE_IDLE_COUNT_START-1;

              
              --capture the SOF character if we get this very early BC
              if COLDATA_stream = SOF_CHARACTER then
                if data_fifo_FULL = '0' then
                  data_in_wr <= '1';
                  write_count <= "000001";
                else
                  data_in_wr <= '0';
                  error_BUFFER_FULL <= '1';
                end if;              
              end if;


              if write_count /= x"38" then
                error_BAD_WRITE_COUNT <= '1';
              end if;
              
            -------------------------------------------------------------
            when CAP_STATE_IDLE =>
              --Update the idle count
              if capture_idle_count /= 0 then
                capture_idle_count <= capture_idle_count -1;
              end if;

              --capture the SOF character
              if COLDATA_stream = SOF_CHARACTER then
                if data_fifo_FULL = '0' then
                  data_in_wr <= '1';
                  write_count <= "000001";
                else
                  data_in_wr <= '0';
                  error_BUFFER_FULL <= '1';
                end if;              
              end if;

              
              if CD_delay = SOF_CHARACTER then
                --WE should have a new packet when capture_idle_count is a 1, but
                --if we haven't gotten one by 0, we have an error and we go back
                --to INIT
                
                if capture_idle_count > 1 then
                  --error, early SOF character
                  --start taking data anyways
                  error_CONVERT_IN_WAIT_WINDOW <= '1';                              
                end if;                                  
              elsif capture_idle_count = 0 then                                
                --We should have a SOF_CHARACTER now, so mark it bad if we don't
                error_BAD_SOF <= '1';
              end if;

            when others => capture_state <= CAP_STATE_INIT;
          end case;
        end if;
      end if;
    end if;
  end process capture_control;

  CD_to_EB_stream.data_out <= data_out;
  CD_FIFO_1: CD_FIFO
    port map (
      aclr    => reset_CD,
      data    => CD_delay(7 downto 0),
      rdclk   => clk_EVB,
      rdreq   => data_rd_comb,
      wrclk   => clk_CD,
      wrreq   => data_in_wr,
      q       => data_out,
      rdempty => open,
      wrfull  => data_fifo_FULL);

  description( 7 downto  0) <= data_errors;
  description(23 downto  8) <= stream_errors;
  description(39 downto 24) <= stream_timestamp;
  CD_description_FIFO_1: CD_description_FIFO
    port map (
      aclr    => reset_CD,
      data    => description,
      rdclk   => clk_EVB,
      rdreq   => eb_info_ack,
      wrclk   => clk_CD,
      wrreq   => description_wr,
      q       => event_info,
      rdempty => no_frames_available,
      rdusedw => description_fifo_used_rd,
      wrfull  => description_fifo_full);
  CD_to_EB_stream.valid <= '1' when (((not no_frames_available) and wait_done) = '1' and readout_state = RDOUT_STATE_WAIT) else '0';
  CD_to_EB_stream.capture_errors <= event_info(7 downto 0);
  CD_to_EB_stream.CD_errors      <= event_info(23 downto 8);
  CD_to_EB_stream.CD_timestamp   <= event_info(39 downto 24);
  
  data_rd_comb <= EB_rd or data_rd;
   
  readout_control: process (clk_EVB) is
  begin  -- process readout_control
    if clk_EVB'event and clk_EVB = '1' then  -- rising clock edge
      eb_info_ack <= '0';
      error_BAD_RO_START <= '0';
      data_rd <= '0';        
      if reset_EVB_local = '1'  then
        readout_state <= RDOUT_STATE_WAIT;
        --set for readout
        readout_count <= 14;
        wait_done <= '0';
        EB_rd_last <= '0';
      else

        EB_rd_last <= EB_rd;
        if EB_rd_last = '1' then
          if data_out(7 downto 0) /= x"BC" then
            error_BAD_RO_START <= '1';
          end if;
        end if;
        
        case readout_state is
          when RDOUT_STATE_WAIT =>

            if wait_done = '0' and description_fifo_used_rd(1 downto 0) = "10" then
              wait_done <= '1';
            end if;
            
            if EB_rd = '1' then
              readout_state <= RDOUT_STATE_READING;

              -- ack the description info
              eb_info_ack <= '1';
              
              data_rd <= '1';
            end if;
            
          when RDOUT_STATE_READING =>
            if readout_count = 2 then
              data_rd <= '0';

              -- we have queued up all the reads that are needed, so we are done
              readout_state <= RDOUT_STATE_WAIT;
              --set for readout
              readout_count <= 14;
              
            else
              readout_count <= readout_count -1;
              data_rd <= '1';
            end if;
          when others => readout_state <= RDOUT_STATE_WAIT;
        end case;
      end if;
    end if;
  end process readout_control;
























  
  -------------------------------------------------------------------------------
  -- Counters
  -------------------------------------------------------------------------------   
  counter_1: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_buffer_full,
      enable      => '1',
      event       => error_BUFFER_FULL,
      count       => monitor.counter_buffer_full,
      at_max      => open);
  counter_2: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_convert_in_wait_window,
      enable      => '1',
      event       => error_CONVERT_IN_WAIT_WINDOW,
      count       => monitor.counter_convert_in_wait_window,
      at_max      => open);
  counter_3: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_BAD_SOF,
      enable      => '1',
      event       => error_BAD_SOF,
      count       => monitor.counter_BAD_SOF,
      at_max      => open);
  counter_4: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_UNEXPECTED_EOF,
      enable      => '1',
      event       => error_UNEXPECTED_EOF,
      count       => monitor.counter_UNEXPECTED_EOF,
      at_max      => open);
  counter_5: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_MISSING_EOF,
      enable      => '1',
      event       => error_MISSING_EOF,
      count       => monitor.counter_MISSING_EOF,
      at_max      => open);
  counter_6: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_KCHAR_IN_DATA,
      enable      => '1',
      event       => error_KCHAR_IN_DATA,
      count       => monitor.counter_KCHAR_IN_DATA,
      at_max      => open);
  counter_7: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_BAD_CHSUM,
      enable      => '1',
      event       => error_BAD_CHSUM,
      count       => monitor.counter_BAD_CHSUM,
      at_max      => open);
  counter_8: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_packets,
      enable      => '1',
      event       => pulse_packet_start,
      count       => monitor.counter_packets,
      at_max      => open);
  counter_9: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_timestamp_incr,
      enable      => '1',
      event       => error_timestamp_incr,
      count       => monitor.counter_timestamp_incr,
      at_max      => open);
  counter_10: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_BAD_WRITE,
      enable      => '1',
      event       => error_BAD_WRITE_COUNT,
      count       => monitor.counter_BAD_WRITE,
      at_max      => open);


  --life is easier in the CD domain, so move this error pulse there
  pacd_1: entity work.pacd
    port map (
      iPulseA => error_BAD_RO_START,
      iClkA   => clk_EVB,
      iRSTAn  => '1',
      iClkB   => clk_CD,
      iRSTBn  => '1',
      oPulseB => error_BAD_RO_START_CD_DOMAIN);
  counter_11: entity work.counter
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => control.reset_counter_BAD_RO_START,
      enable      => '1',
      event       => error_BAD_RO_START_CD_DOMAIN,
      count       => monitor.counter_BAD_RO_START,
      at_max      => open);

  timed_counter_1: entity work.timed_counter
    generic map (
      timer_count => x"07A12000") --128000000
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => '0',--control.reset_timer_frames,
      enable      => '1',
      event       =>  pulse_packet_start,
      timed_count =>  monitor.timer_frames);
  timed_counter_2: entity work.timed_counter
    generic map (
      timer_count => x"07A12000") --128000000
    port map (
      clk         => clk_CD,
      reset_async => '0',
      reset_sync  => '0',--control.reset_timer_incr_error,
      enable      => '1',
      event       => error_timestamp_incr,
      timed_count => monitor.timer_incr_error);
  
end architecture behavioral;
