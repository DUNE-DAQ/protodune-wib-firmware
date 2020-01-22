library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed."+";
use ieee.std_logic_signed."-";
use ieee.std_logic_signed."=";

use work.WIB_Constants.all;
use work.COLDATA_IO.all;
use work.FEMB_DAQ_IO.all;
use work.Convert_IO.all;
use work.types.all;

entity COLDATA_Simulator is
  port (
    clk              : in  std_logic;
    reset_sync       : in  std_logic;
    data_out_stream1 : out std_logic_vector(8 downto 0);
    data_out_stream2 : out std_logic_vector(8 downto 0);
    convert          : in  convert_t;
    monitor          : out Fake_CD_Monitor_t;
    control          : in  Fake_CD_Control_t
    );
end entity COLDATA_Simulator;

architecture behavioral of COLDATA_Simulator is

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

  
  -------------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------------
  constant FRAME_SIZE : integer := to_integer(CDF_FRAME_SIZE); --bigger ofthe two sizes--56;  -- packet size
  constant FRAME_PERIOD : integer := 64; -- number of words sent out in 500ns
  
  -------------------------------------------------------------------------------
  -- types
  -------------------------------------------------------------------------------
  type COLDATA_buffer_t is array (integer range <>) of std_logic_vector(15 downto 0);  
  
  
  -------------------------------------------------------------------------------
  -- Signals
  -------------------------------------------------------------------------------
  signal COLDATA_buffer : COLDATA_buffer_t(FRAME_SIZE downto 0) := (others => (others =>'0'));
  signal iCOLDATA_buffer : integer range 0 to FRAME_PERIOD := FRAME_PERIOD;
  signal COLDATA_CD_errors_checksum : COLDATA_buffer_t(2 downto 1) := (others => (others => '0'));
  signal fake_data_bytes   : std_logic_vector(15 downto 0) := x"0100";
  signal fake_data_counter : std_logic_vector(95 downto 0) := x"007006005004003002001000";

  signal set_reserved : std_logic_vector(15 downto 0) := x"0000";
  signal set_header   : std_logic_vector(31 downto 0) := x"00000000";
  signal timestamp    : std_logic_vector(15 downto 0);  
  signal fake_type    : std_logic_vector(1 downto 0) := "01";

  signal inject_CD_errors          : std_logic_vector(15 downto 0)  := (others => '0');
  signal inject_BAD_checksum       : std_logic_vector(1 downto 0)  := (others => '0');
  signal inject_BAD_SOF            : std_logic_vector(1 downto 0)  := (others => '0');
  signal inject_LARGE_FRAME        : std_logic_vector(1 downto 0)  := (others => '0');
  signal inject_K_CHAR             : std_logic_vector(1 downto 0)  := (others => '0');
  signal inject_SHORT_FRAME        : std_logic_vector(1 downto 0)  := (others => '0');
  signal queued_inject_CD_errors    : std_logic_vector(15 downto 0)  := (others => '0');
  signal queued_inject_BAD_checksum : std_logic_vector(1 downto 0)  := (others => '0');
  signal queued_inject_BAD_SOF      : std_logic_vector(1 downto 0)  := (others => '0');
  signal queued_inject_LARGE_FRAME  : std_logic_vector(1 downto 0)  := (others => '0');
  signal queued_inject_K_CHAR       : std_logic_vector(1 downto 0)  := (others => '0');
  signal queued_inject_SHORT_FRAME  : std_logic_vector(1 downto 0)  := (others => '0');

  signal data_out_stream_buffer : data_8b10b_t(LINKS_PER_CDA downto 1);
--  signal data_out_stream1_buffer : std_logic_vector(8 downto 0) := '0' & x"00";
--  signal data_out_stream2_buffer : std_logic_vector(8 downto 0) := '0' & x"00";

  signal pulse_packet_A : std_logic := '0';
  signal pulse_packet_B : std_logic := '0';

  
begin  -- architecture behavioral
  monitor.fake_data_type <= control.fake_data_type;
  monitor.set_reserved   <= control.set_reserved;
  monitor.set_header     <= control.set_header;
  monitor.fake_stream_type <= control.fake_stream_type;
--  monitor.data_A <= data_out_stream_buffer(1);
--  monitor.data_B <= data_out_stream_buffer(2);
  
  monitor.inject_CD_errors    <= control.inject_CD_errors;   
  monitor.inject_BAD_CHECKSUM <= control.inject_BAD_CHECKSUM;  
  monitor.inject_BAD_SOF      <= control.inject_BAD_SOF;     
  monitor.inject_LARGE_FRAME  <= control.inject_LARGE_FRAME;   
  monitor.inject_K_CHAR       <= control.inject_K_CHAR;      
  monitor.inject_SHORT_FRAME  <= control.inject_SHORT_FRAME; 

  counter_1: entity work.counter
    port map (
      clk         => clk,
      reset_async => '0',
      reset_sync  => control.reset_counter_packets_1_A,
      enable      => '1',
      event       => pulse_packet_A,
      count       => monitor.counter_packets_A,
      at_max      => open);
  counter_2: entity work.counter
    port map (
      clk         => clk,
      reset_async => '0',
      reset_sync  => control.reset_counter_packets_1_B,
      enable      => '1',
      event       => pulse_packet_B,
      count       => monitor.counter_packets_B,
      at_max      => open);

  
  error_injection: process (clk) is
  begin  -- process error_injection
    if clk'event and clk = '1' then  -- rising clock edge
      if reset_sync = '1' then
        queued_inject_CD_errors    <= (others => '0');
        queued_inject_BAD_checksum <= (others => '0');
        queued_inject_BAD_SOF      <= (others => '0');
        queued_inject_LARGE_FRAME  <= (others => '0');
        queued_inject_K_CHAR       <= (others => '0');
        queued_inject_SHORT_FRAME  <= (others => '0');        
      else        
        if control.inject_errors = '1' then
          queued_inject_CD_errors    <= control.inject_CD_errors;   
          queued_inject_BAD_checksum <= control.inject_BAD_CHECKSUM;
          queued_inject_BAD_SOF      <= control.inject_BAD_SOF;
          queued_inject_LARGE_FRAME  <= control.inject_LARGE_FRAME;
          queued_inject_K_CHAR       <= control.inject_K_CHAR;
          queued_inject_SHORT_FRAME  <= control.inject_SHORT_FRAME;
        elsif convert.trigger = '1' and iCOLDATA_buffer = 56 then        
          queued_inject_CD_errors    <= (others => '0');
          queued_inject_BAD_checksum <= (others => '0');
          queued_inject_BAD_SOF      <= (others => '0');
          queued_inject_LARGE_FRAME  <= (others => '0');
          queued_inject_K_CHAR       <= (others => '0');
          queued_inject_SHORT_FRAME  <= (others => '0');        
        end if;
      end if;
    end if;
  end process error_injection;
  
  
  COLDATA_state_control: process (clk) is
  begin  -- process COLDATA_state_machine_control
    if clk'event and clk = '1' then  -- rising clock edge
      if reset_sync = '1' then
        iCOLDATA_buffer <= to_integer(CDF_FRAME_SIZE)+1;
      else        
        --Send/write state machine controller
        if iCOLDATA_buffer = CDF_FRAME_SIZE+1 then
          if convert.trigger = '1' then
            iCOLDATA_buffer <= 0;
            set_header   <= control.set_header;
            set_reserved <= control.set_reserved;
            timestamp    <= std_logic_vector(convert.convert_count(15 downto 0));
            fake_type    <= control.fake_data_type;

            inject_CD_errors    <= queued_inject_CD_errors;   
            inject_BAD_checksum <= queued_inject_BAD_checksum;
            inject_BAD_SOF      <= queued_inject_BAD_SOF;     
            inject_LARGE_FRAME  <= queued_inject_LARGE_FRAME; 
            inject_K_CHAR       <= queued_inject_K_CHAR;      
            inject_SHORT_FRAME  <= queued_inject_SHORT_FRAME;         
          end if;
        else
          iCOLDATA_buffer <= iCOLDATA_buffer + 1;
        end if;      
      end if;
    end if;
  end process COLDATA_state_control;


  
  data_out_stream1 <= data_out_stream_buffer(1);
  data_out_stream2 <= data_out_stream_buffer(2);
  COLDATA_send_data: process (clk) is
  begin  -- process COLDATA_gen_data
    if clk'event and clk = '1' then  -- rising clock edge

      if reset_sync = '1' then            
        data_out_stream_buffer(1) <= IDLE_CHARACTER;
        data_out_stream_buffer(2) <= IDLE_CHARACTER;
        pulse_packet_A <= '0';
        pulse_packet_B <= '0';        
      else     
        pulse_packet_A <= '0';
        pulse_packet_B <= '0';

        --Send out fake data
        case iCOLDATA_buffer is
          when 0 =>
            --SOF character
            data_out_stream_buffer(1) <= SOF_CHARACTER;
            data_out_stream_buffer(2) <= SOF_CHARACTER;

            pulse_packet_A <= '1';
            pulse_packet_B <= '1';
            
            --cause bad SOF character if desired
            if inject_BAD_SOF(0) = '1' then
              data_out_stream_buffer(1) <= '0'& x"00";
            end if;
            if inject_BAD_SOF(1) = '1' then
              data_out_stream_buffer(2) <= '0'& x"00";
            end if;

            --update teh checksum in case we have CD errors (we can always use
            --these since the default CD_errors are 0
            COLDATA_CD_errors_checksum(1) <= COLDATA_buffer(1) + inject_CD_errors( 7 downto 0);
            COLDATA_CD_errors_checksum(2) <= COLDATA_buffer(2) + inject_CD_errors(15 downto 8);
            
          when 1 =>
            -- Checksum LSB
            data_out_stream_buffer(1) <= '0'&COLDATA_CD_errors_checksum(1)(7 downto 0);
            data_out_stream_buffer(2) <= '0'&COLDATA_CD_errors_checksum(2)(7 downto 0);

            if fake_type = "10" then
              --Perserve simple counter mode data
              data_out_stream_buffer(1) <= '0'&COLDATA_buffer(iCOLDATA_buffer)( 7 downto 0);
              data_out_stream_buffer(2) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(15 downto 8);
            end if;
            
          when 2 =>
            -- Checksum MSB
            data_out_stream_buffer(1) <= '0'&COLDATA_CD_errors_checksum(1)(15 downto 8);
            data_out_stream_buffer(2) <= '0'&COLDATA_CD_errors_checksum(2)(15 downto 8);

            --Inject bad checksum error if desired
            if inject_BAD_CHECKSUM(0) = '1' then
              data_out_stream_buffer(1) <= '0'& not COLDATA_buffer(0)(15 downto 8);
            end if;
            if inject_BAD_CHECKSUM(1) = '1' then
              data_out_stream_buffer(2) <= '0'& not COLDATA_buffer(1)(15 downto 8);
            end if;

            if fake_type = "10" then
              --Perserve simple counter mode data
              data_out_stream_buffer(1) <= '0'&COLDATA_buffer(iCOLDATA_buffer)( 7 downto 0);
              data_out_stream_buffer(2) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(15 downto 8);
            end if;
                        
          when 3 to 4 | 7 to 40 | 42 to 57 =>
            data_out_stream_buffer(1) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(7 downto 0);
            data_out_stream_buffer(2) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(15 downto 8);

          when 5 =>
            --Same as 3 to 55 case, only injects CD errors (normally zero)
            data_out_stream_buffer(1) <= '0'&inject_CD_errors( 7 downto 0);
            data_out_stream_buffer(2) <= '0'&inject_CD_errors( 7 downto 0);

            if fake_type = "10" then
              --Perserve simple counter mode data
              data_out_stream_buffer(1) <= '0'&COLDATA_buffer(iCOLDATA_buffer)( 7 downto 0);
              data_out_stream_buffer(2) <= '0'&COLDATA_buffer(iCOLDATA_buffer)( 7 downto 0);
            end if;
          when 6 =>
            --Same as 3 to 55 case, only injects CD errors (normally zero)
            data_out_stream_buffer(1) <= '0'&inject_CD_errors(15 downto 8);
            data_out_stream_buffer(2) <= '0'&inject_CD_errors(15 downto 8);

            if fake_type = "10" then
              --Perserve simple counter mode data
              data_out_stream_buffer(1) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(15 downto 8);
              data_out_stream_buffer(2) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(15 downto 8);
            end if;

            
          when 41 =>
            --Same as 3 to 55 case, but allows for K-char in data error injection
            data_out_stream_buffer(1) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(7 downto 0);
            data_out_stream_buffer(2) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(15 downto 8);

            --cause k-char in data error
            if inject_K_CHAR(0) = '1' then
              data_out_stream_buffer(1) <= '1'&x"DC";
            end if;
            if inject_K_CHAR(1) = '1' then
              data_out_stream_buffer(2) <= '1'&x"DC";
            end if;
            
          when 58 =>
            --Same as 3 to 55 case, but allows for short event error injection
            data_out_stream_buffer(1) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(7 downto 0);
            data_out_stream_buffer(2) <= '0'&COLDATA_buffer(iCOLDATA_buffer)(15 downto 8);

            --Cause a short frame error
            if inject_SHORT_FRAME(0) = '1' then
              data_out_stream_buffer(1) <= IDLE_CHARACTER;
            end if;
            if inject_SHORT_FRAME(1) = '1' then
              data_out_stream_buffer(2) <= IDLE_CHARACTER;
            end if;
            
          when 59 =>
            data_out_stream_buffer(1) <= IDLE_CHARACTER;
            data_out_stream_buffer(2) <= IDLE_CHARACTER;
            --cause a large frame error
            if inject_LARGE_FRAME(0) = '1' then
              data_out_stream_buffer(1) <= '0'&x"00";
            end if;
            if inject_LARGE_FRAME(1) = '1' then
              data_out_stream_buffer(2) <= '0'&x"00";
            end if;
            
          when others =>
            data_out_stream_buffer(1) <= IDLE_CHARACTER;
            data_out_stream_buffer(2) <= IDLE_CHARACTER;          

        end case;

        --Override fake data for idle
        if control.fake_stream_type(1) = '0' then
          -- send out a stream of idle characters
          data_out_stream_buffer(1) <= IDLE_CHARACTER;
        end if;
        if control.fake_stream_type(2) = '0' then
          -- send out a stream of idle characters
          data_out_stream_buffer(2) <= IDLE_CHARACTER;
        end if;
        
      end if;
    end if;
  end process COLDATA_send_data;

  COLDATA_gen_data: process (clk) is
  begin  -- process COLDATA_data
    if clk'event and clk = '1' then  -- rising clock edge
      if reset_sync = '1' then       
        COLDATA_buffer <=  (others => (others =>'0'));
        fake_data_counter <= x"003003002002001001000000";
        fake_data_bytes   <= x"0100";
      else
        
        if fake_type(0) = '0' then
          --State machine for data generation (with fake samples)
          case iCOLDATA_buffer is
            when 0 => null; -- SOF
            when 1 => null; -- checksum LSB
            when 2 => null; -- checksum MSB
            when 3 =>
              --set timestamp
              COLDATA_buffer(3) <= timestamp(7 downto 0) & timestamp(7 downto 0);
              --update the checksums
              COLDATA_buffer(1) <= x"00"&timestamp( 7 downto 0); --Channel A checksum
              COLDATA_buffer(2) <= x"00"&timestamp( 7 downto 0); --Channel B checksum
            when 4 =>
              --set timestamp
              COLDATA_buffer(4) <= timestamp(15 downto 8) & timestamp(15 downto 8);
              --update the checksums
              COLDATA_buffer(1) <= x"00"&timestamp(15 downto 8); --Channel A checksum
              COLDATA_buffer(2) <= x"00"&timestamp(15 downto 8); --Channel B checksum             
            when 5 =>
              --set errors (injected errors done by send process)
              COLDATA_buffer(5) <= x"0000";
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + x"00";
              COLDATA_buffer(2) <= COLDATA_buffer(2) + x"00";
            when 6 =>
              --set errors (injected errors done by send process)
              COLDATA_buffer(6) <= x"0000";
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + x"00";
              COLDATA_buffer(2) <= COLDATA_buffer(2) + x"00";
            when 7 =>
              --set reserved
              COLDATA_buffer(7) <= control.set_reserved(7 downto 0)&control.set_reserved(7 downto 0);
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + set_reserved( 7 downto 0);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + set_reserved( 7 downto 0);
            when 8 =>
              --set reserved
              COLDATA_buffer(8) <= control.set_reserved(15 downto 8)&control.set_reserved(15 downto 8);
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + set_reserved(15 downto 8);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + set_reserved(15 downto 8);

            when 9 =>
              --set header bits 1
              COLDATA_buffer(9) <= set_header(15 downto 0);
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + set_header( 7 downto 0);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + set_header(15 downto 8);
            when 10 =>
              --set header bits 1
              COLDATA_buffer(10) <= set_header(31 downto 16);
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + set_header(23 downto 16);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + set_header(31 downto 24);
            when  11|17|23|29|35|41|47|53 =>
              -- I'm sorry these states are hard to follow, but the reason for
              -- the cryptic bit ranges is that we are packing 96 bits of 12 bit
              -- words into groups of two 8 bit words.
              -- To add to the confusion, we have one format where the wrap
              -- around is on the 16 bit boundary, and anothe where the wrap
              -- around is on the 8 bit boundary and the first 8 bit boundary has
              -- the odd numbered 12 bit groups and the even numbered samples
              -- are in the second 8 bit boundary.
              -- The logic of this code is to group the logic in a multiple of 12
              -- bits and 16 bits, so 96 bits.
              -- We generate 8, 12 bit samples and stuff them in the 96 bits and
              -- then process them as 8/16 bit words to get to 96.
              -- fake type = "00" is the 16 bit wrap around, "11" is the 8 bit
              -- wrap around. 

              -- data (counter)
              COLDATA_buffer(iCOLDATA_buffer)( 7 downto  0) <= fake_data_counter( 7 downto  0);
              COLDATA_buffer(iCOLDATA_buffer)(15 downto  8) <= fake_data_counter(19 downto 12);
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + fake_data_counter( 7  downto  0);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + fake_data_counter(19  downto 12);
            when 12|18|24|30|36|42|48|54 =>
              -- data (counter)
              COLDATA_buffer(iCOLDATA_buffer)( 7 downto  0) <= fake_data_counter(27 downto 24) & fake_data_counter(11 downto  8);
              COLDATA_buffer(iCOLDATA_buffer)(15 downto  8) <= fake_data_counter(39 downto 36) & fake_data_counter(23 downto 20);
              
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + (fake_data_counter(27 downto 24) & fake_data_counter(11 downto  8));
              COLDATA_buffer(2) <= COLDATA_buffer(2) + (fake_data_counter(39 downto 36) & fake_data_counter(23 downto 20));
            when 13|19|25|31|37|43|49|55 =>
              -- data (counter)
              COLDATA_buffer(iCOLDATA_buffer)( 7 downto  0) <= fake_data_counter(35 downto 28);
              COLDATA_buffer(iCOLDATA_buffer)(15 downto  8) <= fake_data_counter(47 downto 40);
              
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + fake_data_counter(35 downto 28);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + fake_data_counter(47 downto 40);
            when 14|20|26|32|38|44|50|56 =>
              -- data (counter)
              COLDATA_buffer(iCOLDATA_buffer)( 7 downto  0) <= fake_data_counter(55 downto 48);
              COLDATA_buffer(iCOLDATA_buffer)(15 downto  8) <= fake_data_counter(67 downto 60);
              
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + fake_data_counter(55 downto 48);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + fake_data_counter(67 downto 60);              
            when 15|21|27|33|39|45|51|57 =>
              -- data (counter)
              COLDATA_buffer(iCOLDATA_buffer)( 7 downto  0) <= fake_data_counter(75 downto 72) & fake_data_counter(59 downto 56);
              COLDATA_buffer(iCOLDATA_buffer)(15 downto  8) <= fake_data_counter(87 downto 84) & fake_data_counter(71 downto 68);
              
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + (fake_data_counter(75 downto 72) & fake_data_counter(59 downto 56));
              COLDATA_buffer(2) <= COLDATA_buffer(2) + (fake_data_counter(87 downto 84) & fake_data_counter(71 downto 68));
            when 16|28|40|52|58 =>
              -- data (counter)
              COLDATA_buffer(iCOLDATA_buffer)( 7 downto  0) <= fake_data_counter(83 downto 76);
              COLDATA_buffer(iCOLDATA_buffer)(15 downto  8) <= fake_data_counter(95 downto 88);
              
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + fake_data_counter(83 downto 76);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + fake_data_counter(95 downto 88);

              --increment all the counters by eight for the next round
              for iBit in 0 to 7 loop
                fake_data_counter((iBit*12) + 11 downto iBit*12) <= fake_data_counter((iBit*12) + 11 downto iBit*12) + 4;
              end loop;  -- iBit
            when 22|34|46  =>
              -- data (counter)
              COLDATA_buffer(iCOLDATA_buffer)( 7 downto  0) <= fake_data_counter(83 downto 76);
              COLDATA_buffer(iCOLDATA_buffer)(15 downto  8) <= fake_data_counter(95 downto 88);
              
              --update the checksums
              COLDATA_buffer(1) <= COLDATA_buffer(1) + fake_data_counter(83 downto 76);
              COLDATA_buffer(2) <= COLDATA_buffer(2) + fake_data_counter(95 downto 88);

              --subtract four from all the counters to get back to the sample
              --count for the next ADC chip group
              for iBit in 0 to 7 loop
                fake_data_counter((iBit*12) + 11 downto iBit*12) <= fake_data_counter((iBit*12) + 11 downto iBit*12) - 4;
              end loop;  -- iBit
            when others => null;
          end case;
        else          
          --State machine for data generation (with fake data bytes)
          case iCOLDATA_buffer is          
            when 0 => null; -- SOF
            when 1 to 58 =>
              -- data (counter)
              COLDATA_buffer(iCOLDATA_buffer)( 7 downto  0) <= std_logic_vector(to_unsigned(iCOLDATA_buffer,8));
              COLDATA_buffer(iCOLDATA_buffer)(15 downto  8) <= std_logic_vector(to_unsigned(iCOLDATA_buffer,8));            
            when others => null;
          end case;
        end if;
      end if;
    end if;
  end process COLDATA_gen_data;
end architecture behavioral;
