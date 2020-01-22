library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

use work.WIB_Constants.all;
use work.COLDATA_IO.all;
--
use work.FEMB_DAQ_IO.all;
use work.Convert_IO.all;
--use work.EB_IO.all;
use work.types.all;
use work.DQM_Packet.all;
use work.DQM_IO.all;
use work.WIB_IO.all;

entity DQM is
  port (
    clk_128Mhz : in std_logic;
    reset      : in std_logic;

    convert : in convert_t;
    WIB_ID  : in WIB_ID_t;
    
    packet_out  : out DQM_Packet_t;
    packet_free : in  std_logic;

    monitor  : out DQM_Monitor_t;
    control  : in  DQM_Control_t;
    FEMB_DQM : in  FEMB_DQM_t
    );

end entity DQM;

architecture behavioral of DQM is


  -------------------------------------------------------------------------------
  --components
  -------------------------------------------------------------------------------
  component DQM_FIFO is
    port (
      clock : in  std_logic;
      data  : in  std_logic_vector (15 downto 0);
      rdreq : in  std_logic;
      wrreq : in  std_logic;
      empty : out std_logic;
      full  : out std_logic;
      q     : out std_logic_vector (15 downto 0));
  end component DQM_FIFO;
  -------------------------------------------------------------------------------
  -- signals
  -------------------------------------------------------------------------------
  signal fifo_in  : std_logic_vector(15 downto 0) := (others => '0');
  signal fifo_out : std_logic_vector(15 downto 0) := (others => '0');
  signal fifo_rd  : std_logic                     := '0';
  signal fifo_wr  : std_logic                     := '0';

  type DQMS_state_t is (DQMS_S_IDLE, DQMS_S_WAIT_FOR_UDP_PACKET, DQMS_S_WAIT_FOR_TOSEND_PACKET, DQMS_S_STREAM);
  signal DQMS_state : DQMS_state_t := DQMS_S_IDLE;

  type DQMC_state_t is (DQMC_S_IDLE, DQMC_S_WAIT_FOR_EMPTY_PACKET, DQMC_S_START_PACKET,
                        DQMC_S_JACK,
                        DQMC_S_CD_SINGLESTREAM_START, DQMC_S_CD_SINGLESTREAM_WAIT, DQMC_S_CD_SINGLESTREAM_CAPTURE);
  signal DQMC_state : DQMC_state_t := DQMC_S_IDLE;

  signal write_index : integer range 1 downto 0 := 1;
  signal read_index  : integer range 1 downto 0 := 0;
  signal mem_switch  : std_logic                := '0';

  signal packet_out_fifo_wr_delay : std_logic := '0';
  signal packet_system_status    : uint32_array_t(1 downto 0) := (others => (others => '0'));
  signal packet_header_user_info : uint64_array_t(1 downto 0) := (others => (others => '0'));
  signal packet_size             : uint16_array_t(1 downto 0) := (others => (others => '0'));
  signal size_left               : unsigned(15 downto 0)      := x"0000";

  signal stream_number : integer range LINK_COUNT downto 1;


  --other signals
  signal jack_counter : unsigned(7 downto 0) := x"00";
  signal jack_start : unsigned(7 downto 0) := x"00";
  signal jack_end : unsigned(7 downto 0) := x"00";
  
  
begin  -- architecture behavioral

  monitor.enable_DQM <= control.enable_DQM;
  monitor.DQM_type   <= control.DQM_type;
  monitor.CD_SS      <= control.CD_SS;

  DQM_FIFO_1 : DQM_FIFO
    port map (
      clock => clk_128Mhz,
      data  => fifo_in,
      rdreq => fifo_rd,
      wrreq => fifo_wr,
      empty => open,
      full  => open,
      q     => fifo_out);

  local_fifo_to_remote_fifo: process (clk_128Mhz, reset) is
  begin  -- process local_fifo_to_remote_fifo
    if reset = '1' then                 -- asynchronous reset (active high)
      packet_out.fifo_wr <= '0';
      packet_out_fifo_wr_delay <= '0';
    elsif clk_128Mhz'event and clk_128Mhz = '1' then  -- rising clock edge
      -- setup correct delay for output data
      packet_out_fifo_wr_delay <= fifo_rd;
      packet_out.fifo_wr <= packet_out_fifo_wr_delay;

      packet_out.fifo_data <= fifo_out;
    end if;
  end process local_fifo_to_remote_fifo;

  
  DQM_send : process (clk_128Mhz, reset) is
  begin  -- process DQM_send
    if reset = '1' then                 -- asynchronous reset (active high)
    elsif clk_128Mhz'event and clk_128Mhz = '1' then  -- rising clock edge
      case DQMS_state is

        when DQMS_S_IDLE =>
          -- Idle state that waits for DQM to be enabled
          DQMS_state         <= DQMS_S_IDLE;

          --Check if we are sending DQM
          if control.enable_DQM = '1' then
            DQMS_state <= DQMS_S_WAIT_FOR_UDP_PACKET;
          end if;

        when DQMS_S_WAIT_FOR_UDP_PACKET =>
          if packet_free = '1' then
            DQMS_state <= DQMS_S_WAIT_FOR_TOSEND_PACKET;
          end if;
        when DQMS_S_WAIT_FOR_TOSEND_PACKET =>
          --Wait for the builder process to hand us a packet
          if mem_switch = '1' and packet_size(read_index) /= x"0000" then
            --Update packet header info for UDP core 
            packet_out.system_status    <= packet_system_status(read_index);
            packet_out.header_user_info <= packet_header_user_info(read_index);

            --Begin streaming local FIFO to UDP core
            size_left  <= unsigned(packet_size(read_index))-1 ;
            fifo_rd    <= '1';
            DQMS_state <= DQMS_S_STREAM;
          end if;
        when DQMS_S_STREAM =>
          --Stream out data
          --This take place in local_fifo_to_remote_fifo process above
 
          --Wait for end of data.
          size_left <= size_left -1;
          if size_left = x"0001" then
            fifo_rd    <= '0';
            DQMS_state <= DQMS_S_IDLE;
          end if;
        when others => null;
      end case;
    end if;
  end process DQM_send;




  DQM_caputre_manager : process (clk_128Mhz, reset) is
  begin  -- process DQM_caputre_manager
    if reset = '1' then                 -- asynchronous reset (active high)
      write_index <= 1;
      read_index  <= 0;
    elsif clk_128Mhz'event and clk_128Mhz = '1' then  -- rising clock edge

      -- handle swapping of memories between capture and send
      mem_switch <= '0';
      if (DQMS_state = DQMS_S_WAIT_FOR_TOSEND_PACKET and
          DQMC_state = DQMC_S_WAIT_FOR_EMPTY_PACKET  and
          mem_switch = '0' and -- allow the other machines to move to the new
                               -- states after mem_switch triggers them
          control.enable_DQM = '1') then  -- only do this when the DQM is enabled) then
        write_index      <= read_index;
        read_index       <= write_index;
        mem_switch <= '1';
      end if;
    end if;
  end process DQM_caputre_manager;



  
  DQM_capture : process (clk_128Mhz, reset) is
  begin  -- process DQM_capture
    if reset = '1' then                 -- asynchronous reset (active high)
      DQMC_state <= DQMC_S_IDLE;
    elsif clk_128Mhz'event and clk_128Mhz = '1' then  -- rising clock edge
      case DQMC_state is
        when DQMC_S_IDLE =>
          --Check if we are sending DQM
          if control.enable_DQM = '1' then
            DQMC_state <= DQMC_S_WAIT_FOR_EMPTY_PACKET;
          end if;
        when DQMC_S_WAIT_FOR_EMPTY_PACKET =>
          --Wait for the builder process to hand us a packet
          if mem_switch = '1' then
            DQMC_state <= DQMC_S_START_PACKET;
          end if;
        when DQMC_S_START_PACKET =>
          packet_system_status(write_index)(3 downto 0)  <= WIB_ID.crate;
          packet_system_status(write_index)(7 downto 4)  <= WIB_ID.slot;
          packet_system_status(write_index)(31 downto 8) <= std_logic_vector(convert.time_stamp(23 downto 0));

          case control.DQM_type is
            when x"0" =>
              --Jack's defaults
              stream_number                                          <= to_integer(unsigned(control.CD_SS.FEMB_number & control.CD_SS.CD_number & control.CD_SS.stream_number)) + 1;
              DQMC_state <= DQMC_S_JACK;
              fifo_in <= x"FACE";
              fifo_wr <= '1';
              jack_counter <= x"00";
              packet_size(write_index) <= x"01";
              packet_header_user_info(write_index) <= (others => '0');
              if control.CD_SS.sub_stream_number = '0' then
                jack_start <= x"08";
                jack_end   <= x"21";
              else
                jack_start <= x"22";
                jack_end   <= x"39";
              end if;
            when x"1" =>              
              DQMC_state <= DQMC_S_CD_SINGLESTREAM_WAIT;
              stream_number                                          <= to_integer(unsigned(control.CD_SS.FEMB_number & control.CD_SS.CD_number & control.CD_SS.stream_number)) + 1;
            when others =>
              DQMC_state <= DQMC_S_START_PACKET;
          end case;

        -------------------------------------------------------------------------
        -- SBND version
        -------------------------------------------------------------------------
        when DQMC_S_JACK =>
          fifo_wr <= '0';


          if jack_counter = x"00" then
            if FEMB_DQM.COLDATA_stream(stream_number) = SOF_CHARACTER then
              jack_counter <= x"01";
            end if;
          else                      
            jack_counter <= jack_counter + 1;
            if jack_counter >= jack_start then 
              --jack_counter is greater than 8, so send the sample data
              -- the fifo we are writing to is 16 bits, but the data is 8bit,
              -- so we use the LSB of jack_counter to write every other word
              -- and we fill the 16 bit written word 8bits at a time.
              if jack_counter(0) = '0' then
                fifo_in( 7 downto  0) <= FEMB_DQM.COLDATA_stream(stream_number)(7 downto 0);
              else
                fifo_in(15 downto  8) <= FEMB_DQM.COLDATA_stream(stream_number)(7 downto 0);
                fifo_wr <= '1';
                packet_size(write_index) <= std_logic_vector(unsigned(packet_size(write_index)) + 1);   
              end if;
            end if;

            -- End of data
            if jack_counter = jack_end then --x"39" then --0x22
              fifo_wr <= '0';
              DQMC_state               <= DQMC_S_IDLE;
            end if;
          end if;
        -------------------------------------------------------------------------
        -- COLDATA single stream capture mode begin
        -------------------------------------------------------------------------
        when DQMC_S_CD_SINGLESTREAM_WAIT =>
          if FEMB_DQM.COLDATA_stream(stream_number) = SOF_CHARACTER then

            --Cache info for packet header
            packet_header_user_info(write_index)(15 downto 0)  <= std_logic_vector(convert.convert_count);
            packet_header_user_info(write_index)(19 downto 16) <= x"0";
            packet_header_user_info(write_index)(20)           <= control.CD_SS.stream_number;
            packet_header_user_info(write_index)(21)           <= control.CD_SS.CD_number;
            packet_header_user_info(write_index)(23 downto 22) <= control.CD_SS.FEMB_number;
            packet_header_user_info(write_index)(59 downto 24) <= x"000000000";
            packet_header_user_info(write_index)(63 downto 60) <= x"0";

            
            --Start streaming the data
            fifo_wr                  <= '1';
            fifo_in                  <= "0000000" & FEMB_DQM.COLDATA_Stream(stream_number)(8 downto 0);
            packet_size(write_index) <= x"01";
            DQMC_state               <= DQMC_S_CD_SINGLESTREAM_CAPTURE;
          end if;
        when DQMC_S_CD_SINGLESTREAM_CAPTURE =>
          fifo_wr                  <= '1';
          fifo_in                  <= "0000000" & FEMB_DQM.COLDATA_Stream(stream_number)(8 downto 0);
          packet_size(write_index) <= std_logic_vector(unsigned(packet_size(write_index)) + 1);

          
          if ((CDA_SWITCH = '0' and packet_size(write_index) = x"00"&"00"&std_logic_vector(CDA_FRAME_SIZE)) or
              (CDA_SWITCH = '1' and packet_size(write_index) = x"00"&"00"&std_logic_vector(CDF_FRAME_SIZE)) or
              
              (FEMB_DQM.COLDATA_Stream(stream_number)(8) = '1' )) then
            DQMC_state               <= DQMC_S_IDLE;
            fifo_wr                  <= '0';
            packet_size(write_index) <= packet_size(write_index);
          end if;
        -------------------------------------------------------------------------
        -- COLDATA single stream capture mode end
        -------------------------------------------------------------------------
        when others => null;
      end case;
    end if;
  end process DQM_capture;




end architecture behavioral;
