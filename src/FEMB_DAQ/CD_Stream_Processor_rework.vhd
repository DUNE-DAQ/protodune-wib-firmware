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
    convert         : in convert_t;

    --Data out (DAQ clock)
    clk_EVB         : in std_logic;
    reset_EVB       : in std_logic;
    --Per CD frame
    CD_to_EB_stream : out CD_Stream_t;    
    EB_rd           : in  std_logic;

    --Monitoring/control
    monitor         : out CD_Stream_Monitor_t;
    control         : in  CD_Stream_Control_t
    );  -- single COLDATA stream

end entity CD_Stream_Processor;

architecture behavioral of CD_Stream_Processor is


  signal reset_local      : std_logic := '1';
  signal reset_CD_local : std_logic := '1';
  signal reset_EVB_local  : std_logic := '1';
  
  component reseter is
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
  -------------------------------------------------------------------------------
  --Buffer RAM
  ------------------------------------------------------------------------------- 
  component CDRAM is
    port (
      data      : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
      rdaddress : IN  STD_LOGIC_VECTOR (5 DOWNTO 0);
      rdclock   : IN  STD_LOGIC;
      wraddress : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
      wrclock   : IN  STD_LOGIC := '1';
      wren      : IN  STD_LOGIC := '0';
      q         : OUT STD_LOGIC_VECTOR (31 DOWNTO 0));
  end component CDRAM;
  constant PAGE_COUNT : integer := 4;
  constant RD_page_DEFAULT : integer range 0 to 3 := 3;
  constant WR_page_DEFAULT : integer range 0 to 3 := 0;

  signal RD_page          : integer range 0 to 3 := RD_page_DEFAULT;
  signal WR_page          : integer range 0 to 3 := WR_page_DEFAULT;
  signal capture_domain_RD_page_copy : integer range 0 to 3 := RD_page_DEFAULT;
  signal readout_domain_WR_page_copy : integer range 0 to 3 := WR_page_DEFAULT;
  signal capture_domain_RD_page_update : std_logic := '0';
  signal readout_domain_RD_page_update : std_logic := '0';
  signal capture_domain_WR_page_update : std_logic := '0';
  signal readout_domain_WR_page_update : std_logic := '0';
  signal wr_page_update_done : std_logic := '0';
  
  signal rd_address       : unsigned(3 downto 0) := "0000";
  signal wr_address       : unsigned(5 downto 0) := ADDR_CHECKSUM_1;--"000000";
  signal data_out_address : std_logic_vector(5 downto 0) := "000000";
  signal data_in_address  : std_logic_vector(7 downto 0) := x"00";
  
  signal data_in_wr      : std_logic := '0';
--  signal data_out_local  : std_logic_vector(15 downto 0) := (others => '0');
  signal data_out_valid_delay : std_logic_vector(1 downto 0) := (others => '0');


  signal word_number : unsigned(5 downto 0) := (others => '0');


  signal CD_delay  : std_logic_vector(8 downto 0);
  
  -------------------------------------------------------------------------------
  -- Convert trigger delay signals
  ------------------------------------------------------------------------------- 
  type convert_array_t is array (integer range PAGE_COUNT-1 downto 0) of convert_t;
  signal captured_convert : convert_array_t := (others => DEFAULT_CONVERT);
  
--  signal convert_delay : std_logic_vector(COLDATA_CONVERT_PERIOD_128MHZ downto 0) := (others => '0');
--  signal convert_buffer : convert_t;
--  signal convert_delayed : convert_t;
--  signal wait_window_counter : unsigned(7 downto 0) := x"00";
  
  -------------------------------------------------------------------------------
  -- Errors from captured data
  -------------------------------------------------------------------------------
  
  type byte_array_t is array (0 to PAGE_COUNT-1) of std_logic_vector(7 downto 0);
  signal data_errors : byte_array_t := (others => (others => '0'));
  constant ERR_NOT_FINISHED : integer := 0;
  constant ERR_BAD_SOF      : integer := 1;
  constant ERR_LARGE_FRAME  : integer := 2;
  constant ERR_K_IN_FRAME   : integer := 3;
  constant ERR_CHSUM_BAD    : integer := 7;
  type unsigned16_array_t is array (0 to PAGE_COUNT-1) of unsigned(15 downto 0);
  type uint16_array_t  is array (0 to PAGE_COUNT-1) of std_logic_vector(15 downto 0);
  signal running_checksum : unsigned(15 downto 0) := (others => '0');
  signal computed_checksum  : unsigned16_array_t := (others => (others => '0'));
  signal stream_checksum  : unsigned16_array_t := (others => (others => '0'));
  signal stream_timestamp : uint16_array_t := (others => (others => '0'));
  signal stream_errors    : uint16_array_t := (others => (others => '0'));
  -- Error counters
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
  signal error_BUFFER_FULL : std_logic := '0';
  signal error_CONVERT_IN_WAIT_WINDOW : std_logic := '0';
  signal error_BAD_SOF  : std_logic := '0';
  signal error_UNEXPECTED_EOF  : std_logic := '0';
  signal error_MISSING_EOF  : std_logic := '0';
  signal error_KCHAR_IN_DATA  : std_logic := '0';
  signal error_BAD_CHSUM : std_logic := '0';
  signal pulse_packet_start : std_logic := '0';

  
  -------------------------------------------------------------------------------
  -- Capture state machine
  -------------------------------------------------------------------------------   
  type Capture_state_t is (CAP_STATE_IDLE,        --Wait for idles to finish
                                                  --and to get a new page
                           CAP_STATE_START,       --Wati ffor the first frame
                           CAP_STATE_INIT,        --Wait for and IDLE character
                                                  --to show we are locked
                           CAP_STATE_PROCESS,     --Process the incomming data
                           CAP_STATE_END          --This is the first word
                                                  --after the last word of
                                                  --frame data
                           );
  signal capture_state : capture_state_t := CAP_STATE_INIT;
  constant CAPTURE_IDLE_COUNT_START : integer range 8 downto 0 := 5;--8;
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

  


begin  -- architecture behavioral

  
  -------------------------------------------------------------------------------
  -- resets
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------

  --Since a reset on either end of this should reset the pages, we take the or
  --of the resets in each of the clock domains as an async reset that must be
  --properly propogated to each domain's sync reset.
  reset_local <= reset_CD or reset_EVB; --async
  
  reseter_1: entity work.reseter
    port map (
      clk         => clk_CD,
      reset_async => reset_local,
      reset_sync  => '0',
      reset       => reset_CD_local);

  reseter_2: entity work.reseter
    port map (
      clk         => clk_EVB,
      reset_async => reset_local,
      reset_sync  => '0',
      reset       => reset_EVB_local);
  
  -------------------------------------------------------------------------------
  -- CD clock domain
  -------------------------------------------------------------------------------   

  -------------------------------------------------------------------------------
  --Delay the convert signal to take into account the loop-back delay
  -------------------------------------------------------------------------------
--  monitor.convert_delay <= control.convert_delay;


  -- this passes a one clock pulse indicating that the RD_page has been updated
  pacd_1: entity work.pacd
    port map (
      iPulseA => readout_domain_RD_page_update,
      iClkA   => clk_EVB,
      iRSTAn  => '1',
      iClkB   => clk_CD,
      iRSTBn  => '1',
      oPulseB => capture_domain_RD_page_update);

  -- This process updates the capture clock domain's copy of the RD_page when
  -- an update pulse is sent from the readout clock domain
  capture_page: process (clk_CD) is    
  begin  -- process capture_index
    if clk_CD'event and clk_CD = '1' then  -- rising clock edge
      if reset_CD_local = '1' then      
        capture_domain_RD_page_copy <= RD_page_DEFAULT;
      else
        if capture_domain_RD_page_update = '1' then
          capture_domain_RD_page_copy <= RD_page;
        end if;
      end if;
    end if;
  end process capture_page;

  monitor.wait_window <= control.wait_window;
  monitor.enable <= control.enable;


  capture_state_machine: process (clk_CD) is
  begin  -- process capture_state_machine
    if clk_CD'event and clk_CD = '1' then  -- rising clock edge

      
      CD_delay <= COLDATA_stream;

      --State machine
      
      if ((reset_CD_local = '1') and
          (control.enable = '0')) then
        --Sync reset or diabled link
        capture_state <= CAP_STATE_INIT;
      else
        case capture_state is
          -------------------------------------------------------------
          when CAP_STATE_INIT =>
            --Wait for an idle character to be locked on
            capture_state <= CAP_STATE_INIT;
            if COLDATA_stream = IDLE_CHARACTER then
              --move on to parsing data
              capture_state <= CAP_STATE_IDLE;
            end if;
          -------------------------------------------------------------
          when CAP_STATE_IDLE =>
            --Keep monitoring idles
            capture_state <= CAP_STATE_IDLE;
            --If we have memory to write to and we get a SOF_CHARACTER, then
            --process the data
            if wr_page_update_done = '1' then
              if COLDATA_stream = SOF_CHARACTER then
                capture_state <= CAP_STATE_START;
              end if;
            end if;
          -------------------------------------------------------------
          when CAP_STATE_START =>
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
          -------------------------------------------------------------
          when others => capture_state <= CAP_STATE_INIT;
        end case;
      end if;      
    end if;
  end process capture_state_machine;

  
  capture_control: process (clk_CD) is
  begin  -- process capture_control
    if clk_CD'event and clk_CD = '1' then  -- rising clock edge

      --Error counter pule resets
      error_BUFFER_FULL <= '0';
      error_CONVERT_IN_WAIT_WINDOW <= '0';
      error_BAD_SOF <= '0';
      error_UNEXPECTED_EOF <= '0';
      error_MISSING_EOF <= '0';
      error_KCHAR_IN_DATA <= '0';
      error_BAD_CHSUM <= '0';

      pulse_packet_start <= '0';      
      capture_domain_WR_page_update <= '0';      
      data_in_wr <= '0';

      
      if reset_CD_local = '1' then 
        WR_page <= WR_page_DEFAULT;
      else
        case capture_state is
          -------------------------------------------------------------
          when CAP_STATE_INIT =>
            capture_idle_count <= CAPTURE_IDLE_COUNT_START;
          -------------------------------------------------------------
          when CAP_STATE_START =>
            -- Start taking data
            pulse_packet_start <= '1';

            --Capture the current convert
            captured_convert(WR_PAGE) <= convert;
            
            data_errors(WR_PAGE)(ERR_NOT_FINISHED) <= '0';
            
            word_number <= (others => '0');
            wr_address <= ADDR_CHECKSUM_1;    
            
            data_in_wr <= '1';

            -- wr page update must have been done if we are here
            wr_page_update_done <= '0';

          -------------------------------------------------------------
          when CAP_STATE_PROCESS =>
            -----------------------------
            -- Check for bad words (errors)
            -----------------------------
            
            --Check if it is idle
            if CD_delay = IDLE_CHARACTER then
              --There was an idle word in the data part of the frame,
              --mark the event as not finished since it is short, but capture
              --the full count for debugging
              error_UNEXPECTED_EOF <= '1';
              data_errors(WR_PAGE)(ERR_NOT_FINISHED) <= '1';
            end if;
            
            --check for a k-char in the data stream
            if CD_delay(8) = '1' then
              data_errors(WR_PAGE)(ERR_K_IN_FRAME) <= '1';
              error_KCHAR_IN_DATA <= '1';
            end if;
            
            -----------------------------
            -- process the data word
            -----------------------------
            
            --Save incomming data to ram
            if ((CDA_SWITCH = '0' and word_number = CDA_FRAME_SIZE-1) or
                (CDA_SWITCH = '1' and word_number = CDF_FRAME_SIZE-1)) then
              --wr_address = FRAME_SIZE-1 then
              data_in_wr <= '0';
            else
              data_in_wr <= '1';
            end if;
            
            -- choose next RAM address
            --We either have real or FPGA COLDATA ASICs
            -- This will change slightly where and what data we save in the RAM
            if CDA_SWITCH = '0' then
              --Real coldata ASICS, so each stream has half the data and no redundancy
              case wr_address is
                when ADDR_CHECKSUM_1   => wr_address <= ADDR_CHECKSUM_2;
                when ADDR_CHECKSUM_2   => wr_address <= ADDR_TIMESTAMP;
                when ADDR_TIMESTAMP    => wr_address <= ADDR_ERRORS;
                when ADDR_ERRORS       => wr_address <= ADDR_RESERVED;
                when ADDR_RESERVED     => wr_address <= ADDR_ADC_HEADER_1;
                when ADDR_ADC_HEADER_1 => wr_address <= ADDR_ADC_HEADER_2;
                when ADDR_ADC_HEADER_2 => wr_address <= ADDR_DATA_START;
                when others            => wr_address <= wr_address + 1;
              end case;
            else
              --FPGA coldata ASICs, so we have redundancy in our time stamps,
              --errors and reserved words.  (also packing of data is
              --different, but the WIB doesn't care)
              if IS_LINK_A = '1' then
                --This is a link A, so what we want to stream out is the LSB
                --of redundant words
                case wr_address is
                  when ADDR_CHECKSUM_1   => wr_address <= ADDR_CHECKSUM_2;
                  when ADDR_CHECKSUM_2   => wr_address <= ADDR_TIMESTAMP;
                  when ADDR_TIMESTAMP    => wr_address <= ADDR_TIMESTAMP_R;
                  when ADDR_TIMESTAMP_R  => wr_address <= ADDR_ERRORS;
                  when ADDR_ERRORS       => wr_address <= ADDR_ERRORS_R;
                  when ADDR_ERRORS_R     => wr_address <= ADDR_RESERVED;
                  when ADDR_RESERVED     => wr_address <= ADDR_RESERVED_R;
                  when ADDR_RESERVED_R   => wr_address <= ADDR_ADC_HEADER_1;
                  when ADDR_ADC_HEADER_1 => wr_address <= ADDR_ADC_HEADER_2;
                  when ADDR_ADC_HEADER_2 => wr_address <= ADDR_DATA_START;
                  when others            => wr_address <= wr_address + 1;
                end case;                
              else
                --THis is a link B, so we want to stream out the MSB of
                --redundant words
                case wr_address is
                  when ADDR_CHECKSUM_1   => wr_address <= ADDR_CHECKSUM_2;
                  when ADDR_CHECKSUM_2   => wr_address <= ADDR_TIMESTAMP_R;
                  when ADDR_TIMESTAMP_R  => wr_address <= ADDR_TIMESTAMP;
                  when ADDR_TIMESTAMP    => wr_address <= ADDR_ERRORS_R;
                  when ADDR_ERRORS_R     => wr_address <= ADDR_ERRORS;
                  when ADDR_ERRORS       => wr_address <= ADDR_RESERVED_R;
                  when ADDR_RESERVED_R   => wr_address <= ADDR_RESERVED;
                  when ADDR_RESERVED     => wr_address <= ADDR_ADC_HEADER_1;
                  when ADDR_ADC_HEADER_1 => wr_address <= ADDR_ADC_HEADER_2;
                  when ADDR_ADC_HEADER_2 => wr_address <= ADDR_DATA_START;
                  when others            => wr_address <= wr_address + 1;
                end case;                
                
              end if;

              --update word number
              word_number <= word_number + 1;
              
              --update checksum
              if ( (CDA_SWITCH = '0' and word_number = CDA_WORD_COLDATA_CHECKSUM_MSB) or
                   (CDA_SWITCH = '1' and word_number = CDF_WORD_COLDATA_CHECKSUM_MSB)) then
                running_checksum <= x"0000";
              else
                running_checksum <= running_checksum + unsigned(CD_delay(7 downto 0)  );  
              end if;
              
              
              --Cache useful things for error checking
              if CDA_SWITCH = '0' then              
                case word_number is
                  when CDA_WORD_COLDATA_CHECKSUM_LSB =>
                    stream_checksum(WR_page)( 7 downto 0)    <= unsigned(CD_delay(7 downto 0));   
                  when CDA_WORD_COLDATA_CHECKSUM_MSB =>
                    stream_checksum(WR_page)(15 downto 8)    <= unsigned(CD_delay(7 downto 0));
                  when CDA_WORD_COLDATA_TIME         =>
                    if IS_LINK_A = '1' then
                      stream_timestamp(WR_page)( 7 downto 0) <= CD_delay(7 downto 0);
                    else
                      stream_timestamp(WR_page)(15 downto 8) <= CD_delay(7 downto 0);  
                    end if;                    
                  when CDA_WORD_COLDATA_ERRORS       =>
                    if IS_LINK_A = '1' then
                      stream_errors(WR_page)( 7 downto 0)    <= CD_delay(7 downto 0);
                    else
                      stream_errors(WR_page)(15 downto 8)    <= CD_delay(7 downto 0); 
                    end if;                    
                  when others => null;
                end case;
              else
                case word_number is
                  when CDF_WORD_COLDATA_CHECKSUM_LSB =>
                    stream_checksum(WR_page)( 7 downto 0)  <= unsigned(CD_delay(7 downto 0));
                  when CDF_WORD_COLDATA_CHECKSUM_MSB =>
                    stream_checksum(WR_page)(15 downto 8)  <= unsigned(CD_delay(7 downto 0));
                  when CDF_WORD_COLDATA_TIME_1       =>
                    stream_timestamp(WR_page)( 7 downto 0) <= CD_delay(7 downto 0);
                  when CDF_WORD_COLDATA_TIME_2       =>
                    stream_timestamp(WR_page)(15 downto 8) <= CD_delay(7 downto 0);
                  when CDF_WORD_COLDATA_ERRORS_1       =>
                    stream_errors(WR_page)( 7 downto 0)    <= CD_delay(7 downto 0);
                  when CDF_WORD_COLDATA_ERRORS_2       =>
                    stream_errors(WR_page)(15 downto 8)    <= CD_delay(7 downto 0);   
                  when others => null;
                end case;                
              end if;
            end if;           
          -------------------------------------------------------------
          when CAP_STATE_END =>
            --This is the word after the last word and should be an idle word
              
            --mark the data as finished (if it wasn't already set as not finished)
            --data_errors(WR_PAGE)(ERR_NOT_FINISHED) <= '0' or data_errors(WR_PAGE)(ERR_NOT_FINISHED);
            --compare the checksums and update the checksum error bit in the
            --capture errors
            if stream_checksum(WR_PAGE) = running_checksum then
              error_BAD_CHSUM <= '0';
              data_errors(WR_PAGE)(ERR_CHSUM_BAD) <= '0';
            else
              error_BAD_CHSUM <= '1';
              data_errors(WR_PAGE)(ERR_CHSUM_BAD) <= '1';
            end if;
            computed_checksum(WR_page) <= running_checksum;
            
            --Check that it ended correctly
            if CD_delay /= IDLE_CHARACTER then
              --The character after the 55 bytes wasn't an IDLE
              --force and end and mark it as bad
              data_errors(WR_PAGE)(ERR_LARGE_FRAME) <= '1';
              error_MISSING_EOF <= '1';
            end if;
            
            --Get ready for the idle processing state
            capture_idle_count <= CAPTURE_IDLE_COUNT_START-1;

          -------------------------------------------------------------
          when CAP_STATE_IDLE =>
            --Update the idle count
            if capture_idle_count /= 0 then
              capture_idle_count <= capture_idle_count -1;
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


            if wr_page_update_done = '0' then
              -- We haven't switched buffers yet, so try
              -- We need to switch buffers before we can do anything else
              capture_domain_WR_page_update <= '1';
              wr_page_update_done <= '1';
              if    WR_page = 0 and Capture_Domain_RD_page_Copy /= 1 then
                WR_page <= 1;
              elsif WR_page = 1 and Capture_Domain_RD_page_Copy /= 2 then
                WR_page <= 2;
              elsif WR_page = 2 and Capture_Domain_RD_page_Copy /= 3 then
                WR_page <= 3;
              elsif WR_page = 3 and Capture_Domain_RD_page_Copy /= 0 then
                WR_page <= 0;
              else
                -- We can't switch buffers, so die
                error_BUFFER_FULL <= '1';
                capture_domain_WR_page_update <= '0';
                wr_page_update_done <= '0';
              end if;            
            end if;


          when others => capture_state <= CAP_STATE_INIT;
        end case;
      end if;        
    end if;
  end process capture_control;
















  -- 256 byte RAM holding 4x64 bytes for 4 55byte events
  COLDATA_RAM: CDRAM
    port map (
      data      => CD_delay(7 downto 0),--COLDATA_stream(7 downto 0),
      rdaddress => data_out_address,
      rdclock   => clk_EVB,
      wraddress => data_in_address,
      wrclock   => clk_CD,
      wren      => data_in_wr,
      q         => CD_to_EB_stream.data_out);
  --Build RAM address out of page number and page address
  data_out_address <= std_logic_vector(to_unsigned(RD_page,2)) & std_logic_vector(rd_address);
  data_in_address  <= std_logic_vector(to_unsigned(WR_page,2)) & std_logic_vector(wr_address);

  --Speeds up the access time to the ram by one clock tick over the clocked
  --process readout control
--  EB_readout_control: process (rd_address,readout_state,EB_rd) is
--  begin  -- process EB_readout_control
--    if (readout_state = RDOUT_STATE_CHECKING) then
--      if  EB_rd = '1' then
--        rd_address <= rd_address + 1;
--      else
--        -- Set readout pipeline to the beginning
--        rd_address <= (others => '0');        
--      end if;      
--    elsif (readout_state = RDOUT_STATE_READING) then
--      if rd_address <= (ADDR_DATA_END(5 downto 2)) then
--        rd_address <= rd_address + 1;
--      end if;
--    else
--      -- Set readout pipeline to the beginning
--      rd_address <= (others => '0');              
--    end if;
--  end process EB_readout_control;

  -------------------------------------------------------------------------------
  -- Event builder clock domain
  -------------------------------------------------------------------------------   

  -- this passes a one clock pulse indicating that the WR_page has been updated
  pacd_2: entity work.pacd
    port map (
      iPulseA => capture_domain_WR_page_update,
      iClkA   => clk_CD,
      iRSTAn  => '1',
      iClkB   => clk_EVB,
      iRSTBn  => '1',
      oPulseB => readout_domain_WR_page_update);


  
  -- This process updates the readout clock domain's copy of the WR_page when
  -- an update pulse is sent from the capture clock domain
  readout_page: process (clk_EVB) is    
  begin  -- process capture_index
    if clk_EVB'event and clk_EVB = '1' then  -- rising clock edge
      if reset_EVB_local = '1' then  
        readout_domain_WR_page_copy <= WR_page_DEFAULT;
      else   
        if readout_domain_WR_page_update = '1' then
          readout_domain_WR_page_copy <= WR_page;
        end if;
      end if;
    end if;
  end process readout_page;


  
  readout_control: process (clk_EVB) is
  begin  -- process readout_control
    if clk_EVB'event and clk_EVB = '1' then  -- rising clock edge
      if reset_EVB_local = '1' then
        CD_to_EB_stream.valid <= '0';
        RD_page <= RD_page_DEFAULT;
        readout_state <= RDOUT_STATE_IDLE;        
      else        
        readout_domain_RD_page_update <= '0';
        
        case readout_state is
          when RDOUT_STATE_IDLE =>

            --Jump to checking state if there is a new valid page
            readout_state <= RDOUT_STATE_CHECKING  ;

            --NOT NEEDED ANYMORE
            -- queue the read of the checksum for this frame
            --          rd_address <= WORD_COLDATA_TIME;
            
            -- poll for next open page with valid data
            readout_domain_RD_page_update <= '1'; --update the other clock domain
            if    RD_page = 0 and readout_domain_WR_page_copy /= 1 then
              RD_page <= 1;
            elsif RD_page = 1 and readout_domain_WR_page_copy /= 2 then
              RD_page <= 2;
            elsif RD_page = 2 and readout_domain_WR_page_copy /= 3 then
              RD_page <= 3;
            elsif RD_page = 3 and readout_domain_WR_page_copy /= 0 then
              RD_page <= 0;

            else
              -- If no new data, stay in idle
              readout_state <= RDOUT_STATE_IDLE;
              readout_domain_RD_page_update <= '0';
            end if;
            
          when RDOUT_STATE_READING =>
            rd_address <= rd_address + 1;
            -- reading data, waiting for data to be all read out
            -- address must be zero before this            
            if rd_address = (ADDR_DATA_END(5 downto 2)) then
              readout_state <= RDOUT_STATE_IDLE;
              CD_to_EB_stream.valid <= '0';
            end if;
            
          when RDOUT_STATE_CHECKING   =>
            --Mark frame as valid
            CD_to_EB_stream.valid <= '1';

            -- Present the COLDATA errors and the timestamp
            CD_to_EB_stream.CD_errors <= stream_errors(RD_page);
            CD_to_EB_stream.CD_timestamp <= stream_timestamp(RD_page);

            --Present the captured errors (from the WR side)
            CD_to_EB_stream.capture_errors <= data_errors(RD_page);          

            
            --Wait for CD stream readout signal
            readout_state <= RDOUT_STATE_WAIT;

--            rd_address <= (others => '0');
            rd_address <= ADDR_PADDING(5 downto 2);
            
          when RDOUT_STATE_WAIT =>            
            if EB_rd = '1' then
              readout_state <= RDOUT_STATE_READING;
              rd_address <= rd_address + 1;
            end if;
          when others => readout_state <= RDOUT_STATE_IDLE;
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
  
end architecture behavioral;
