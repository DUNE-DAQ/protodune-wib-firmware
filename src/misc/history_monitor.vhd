-------------------------------------------------------------------------------
-- history monitor
-- Dan Gastler
-- capture a set of signals with a history of 2^HISTORY_BIT_LENGTH samples with 2^HISTORY_BIT_LENGTH-1 samples after an
-- error condition
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity history_monitor is
  
  generic (
    HISTORY_BIT_LENGTH : integer := 7;
    SIGNAL_COUNT       : integer := 1);

  port (
    clk               : in std_logic;
    reset             : in std_logic;
    signals           : in std_logic_vector(SIGNAL_COUNT-1 downto 0);
    start             : in std_logic;
    stop              : in std_logic;
    history_out       : out std_logic_vector(SIGNAL_COUNT-1 downto 0);
    history_presample : out std_logic;
    history_valid     : out std_logic;
    history_ack       : in  std_logic);

end entity history_monitor;

architecture behavioral of history_monitor is

  type sample_t is record
    valid      : std_logic;
    presample : std_logic;
    data       : std_logic_vector(SIGNAL_COUNT-1 downto 0);
  end record sample_t;
  type sample_array_t is array (2**HISTORY_BIT_LENGTH -1 downto 0) of sample_t;
  signal sample_array : sample_array_t;
  signal buffer_sample : sample_t;
  
  signal valid_sample_count : unsigned(HISTORY_BIT_LENGTH-1 downto 0);
  signal valid_sample_count_latched : unsigned(HISTORY_BIT_LENGTH-1 downto 0);
  signal next_sample_index  : unsigned(HISTORY_BIT_LENGTH-1 downto 0);

  type SM_t is (SM_RESET,SM_START,SM_CAPTURE,SM_END_CAPTURE,SM_IDLE);
  signal state : SM_t;
begin  -- architecture behavioral



  capture_state: process (clk, reset) is
  begin  -- process capture_state
    if reset = '1' then                 -- asynchronous reset (active high)
      state <= SM_RESET;
    elsif clk'event and clk = '1' then  -- rising clock edge
      case state is
        when SM_RESET =>
          state <= SM_IDLE;
        when SM_IDLE  =>
          if start = '1' then
            state <= SM_START;
          end if;
        when SM_START =>
          state <= SM_CAPTURE;
        when SM_CAPTURE =>
          if stop = '1' then
            state <= SM_END_CAPTURE;
            valid_sample_count_latched <= valid_sample_count(HISTORY_BIT_LENGTH-2 downto 0) & '0';
--multiply by two
          end if;
        when SM_END_CAPTURE =>
          if or_reduce(std_logic_vector(valid_sample_count)) = '0' then
            state <= SM_IDLE;
          end if;
        when others => state <= SM_RESET;
      end case;
    end if;
  end process capture_state;


  capture_proc: process (clk) is
  begin  -- process capture_proc
    if clk'event and clk = '1' then  -- rising clock edge
      --Buffer the incomming samples
      buffer_sample.valid     <= '1';
      buffer_sample.data      <= signals;
      buffer_sample.presample <= '1';
      
      --capture state machine
      case state is
        ---------------------------------
        -- RESET or START
        ---------------------------------
        when SM_RESET | SM_START =>
          --reset samples
          sample_array <= (others => ('0','0',(others => '0')));
          next_sample_index  <= (others => '0');
          valid_sample_count <= (others => '0');
        ---------------------------------
        -- CAPTURE presamples
        ---------------------------------
        when SM_CAPTURE =>
          --Capture the current input
          sample_array(to_integer(next_sample_index)) <= buffer_sample;
          sample_array(to_integer(next_sample_index)).presample <= '1';
          
          --Move to the next sample
          next_sample_index <= next_sample_index + 1;
          
          --Keep track of the number of valid samples, but don't let this count
          --get larger than half of the buffer.
          if and_reduce(std_logic_vector(valid_sample_count(HISTORY_BIT_LENGTH-2 downto 0))) = '0' then
            valid_sample_count <= valid_sample_count + 1;
          end if;
        ---------------------------------
        -- Capture post samples
        ---------------------------------
        when SM_END_CAPTURE =>
                    
          if or_reduce(std_logic_vector(valid_sample_count(HISTORY_BIT_LENGTH-2 downto 0))) = '1' then
            --Capture the current input
            sample_array(to_integer(next_sample_index)) <= buffer_sample;
            sample_array(to_integer(next_sample_index)).presample <= '0';

            -- Count down the existing presamples to get an equal number of post_samples
            valid_sample_count <= valid_sample_count - 1;

            --Move to the next sample
            next_sample_index <= next_sample_index + 1;
          else
            next_sample_index <= next_sample_index - valid_sample_count_latched;
          end if;

        ---------------------------------
        -- IDLE or READOUT
        ---------------------------------
        when SM_IDLE =>
          if history_ack = '1' then
            --move back in the waveform until the user stops (invalid data)
            next_sample_index <= next_sample_index +1;
            -- to be safe, invalidate this data
            sample_array(to_integer(next_sample_index)).valid <= '0';
          end if;
        when others => null;
      end case;
    end if;

    --output last captured sample
    history_out       <= sample_array(to_integer(next_sample_index)).data;
    history_presample <= sample_array(to_integer(next_sample_index)).presample;
    history_valid     <= sample_array(to_integer(next_sample_index)).valid;

  end process capture_proc;

  


end architecture behavioral;
