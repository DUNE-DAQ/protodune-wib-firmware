-- we keep track of how many "extra words" we currently have
-- if "extra words" goes above or equal to WORD_COUNT, then we go up by WORD_COUNT - "extra words" else we go up by EXTRA_WORD_COUNT
-- This implies that there are ... ceiling(WORD_COUNT/EXTRA_WORD_COUNT) + 1


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Constants parameters for the FEMB_Gearbox
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
library ieee;
use work.WIB_Constants.all;
package Gearbox_constants is
  constant WORD_COUNT       : integer := 4;--2; -- normal size
  constant BYTES_PER_WORD   : integer := 2;
  constant BITS_PER_BYTE    : integer := 9;
  constant EXTRA_WORD_COUNT : integer := GEARBOX_EXTRA_WORD_COUNT;
end package Gearbox_constants;

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--Monitor and control package
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package GB_IO is
  
  type GB_Monitor_t is record
    enable_counter_underflow : std_logic;
    counter_underflow        : std_logic_vector(31 downto 0);    
  end record GB_Monitor_t;
  
  type GB_Control_t is record
    reset_counter_underflow  : std_logic;
    enable_counter_underflow : std_logic;
  end record GB_Control_t;
  constant DEFAULT_GB_CONTROL : GB_Control_t := (reset_counter_underflow  => '1',
                                                 enable_counter_underflow => '1');
end package GB_IO; 

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Gearbox
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
--This component handles converting a series of odd numbered WORD_SIZE words in
-- an event into blocks that must always be an even number of WORDS_SIZE words.
-- This is done by normally taking in 2 words every clock except at the end of
-- an event where there are 3 words.   This relies on the input stream to give
-- a clock tick of nothing every two 3 word inputs. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use work.types.all;
use work.Gearbox_constants.all;
use work.GB_IO.all;
entity Gearbox is
  generic (
    DEFAULT_WORDS : std_logic_vector((BYTES_PER_WORD * BITS_PER_BYTE)-1 downto 0) := "1"&x"3c"&"1"&x"3c");
  port (
    clk                : in  std_logic;
    reset              : in  std_logic;
    data_in            : in  std_logic_vector(((WORD_COUNT + EXTRA_WORD_COUNT)*BYTES_PER_WORD * BITS_PER_BYTE) - 1 downto 0);
    data_in_count      : in  std_logic_vector(7 downto 0);
    data_out           : out std_logic_vector(( WORD_COUNT                    *BYTES_PER_WORD * BITS_PER_BYTE)  -1 downto 0);
    special_word_request : out std_logic_vector(7 downto 0); --combinatorical
    monitor            : out GB_Monitor_t;
    control            : in  GB_Control_t);

end entity Gearbox;

architecture behavioral of Gearbox is
  --Error counter primative
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

  component pipeline_delay is
    generic (
      WIDTH : integer;
      DELAY : integer);
    port (
      clk      : in  std_logic;
      data_in  : in  std_logic_vector(WIDTH-1 downto 0);
      data_out : out std_logic_vector(WIDTH-1 downto 0));
  end component pipeline_delay;
  
  type word_array_t is array (integer range <>) of std_logic_vector(BYTES_PER_WORD * BITS_PER_BYTE -1 downto 0);
  
  signal counter_underflow : std_logic_vector(31 downto 0);
  
  -------------------------------------------------------------------------------
  -- state machine
  -------------------------------------------------------------------------------
  type shift_register_state_t is (SR_STATE_1,SR_STATE_2,SR_STATE_3);--(SR_STATE_5,SR_STATE_6,SR_STATE_7);
  signal sr_state : shift_register_state_t := SR_STATE_1;
  signal extra_words : integer range 4*WORD_COUNT downto 0:= 0;
  signal data_in_count_int : integer range 4*WORD_COUNT downto 0 := WORD_COUNT;
  
  -------------------------------------------------------------------------------
  -- Input rearrangement
  -------------------------------------------------------------------------------
  signal words_in : word_array_t(WORD_COUNT + EXTRA_WORD_COUNT - 1 downto 0) := (others => DEFAULT_WORDS);--word_array_t(2 downto 0) := (others => DEFAULT_WORDS);

  -------------------------------------------------------------------------------
  -- Slipping gear box
  -------------------------------------------------------------------------------
  --Shift register with a constant number of words being pulled out.
  --This shift register has a variable number of words put in, but on average
  --it is the same as being pulled out and only differs by +1 or -2 for one
  --tick rarely over a long period
  signal word_sr : word_array_t(2*WORD_COUNT + WORD_COUNT + EXTRA_WORD_COUNT - 1 downto 0) := (others => DEFAULT_WORDS);--word_array_t(7 downto 0) := (others => DEFAULT_WORDS);

  -------------------------------------------------------------------------------
  -- Error pulses
  -------------------------------------------------------------------------------
  signal underflow_error : std_logic := '0';  
  
begin  -- architecture behavioral  
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  -- Convert inputs std_logic_vector into an array of words
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  input_type_rearrange: for iWord in WORD_COUNT + EXTRA_WORD_COUNT -1  downto 0 generate --WORD_COUNT_MAX -1  downto 0 generate
    words_in(iWord) <= data_in(BITS_PER_BYTE*BYTES_PER_WORD*(iWord+1)-1  downto BITS_PER_BYTE*BYTES_PER_WORD*iWord);
  end generate input_type_rearrange;

  data_in_count_int <= to_integer(unsigned(data_in_count));
  
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  --Main process, state machine and shift register operation
  -------------------------------------------------------------------------------
  -------------------------------------------------------------------------------
  shift_register_state_machine : process (clk, reset) is
  begin  -- process shift_register_state_machine
    if reset = '1' then                 -- asynchronous reset (active high)
      word_sr <= (others => DEFAULT_WORDS);
      sr_state <= SR_STATE_1;--SR_STATE_6;
      extra_words <= 0;
      underflow_error <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge
      underflow_error <= '0';
      
      --update extra words
      if EXTRA_WORD_COUNT = 0 then
        --shift old words
        for iWord in WORD_COUNT - 1 downto 0 loop
          word_sr(iWord) <= word_sr(iWord + WORD_COUNT);
        end loop;  -- iWord

        for iData_in_count in WORD_COUNT downto 0 loop
          if (data_in_count_int = iData_in_count) then              
            --add in new words
            for iWord in iData_in_count -1 downto 0 loop
              word_sr(WORD_COUNT + iWord) <= words_in(iWord);
            end loop;  -- iWord              
          end if;
        end loop;  -- data_in_count        
      else        
        extra_words <= extra_words + data_in_count_int - WORD_COUNT;
        if (extra_words + data_in_count_int) < WORD_COUNT then
          extra_words <= 0;
          underflow_error <= '1';
        end if;
        
        for iExtra_words in WORD_COUNT downto 0 loop
          if extra_words = iExtra_words then
            --shift old words
            for iWord in WORD_COUNT + iExtra_words - 1 downto 0 loop
              word_sr(iWord) <= word_sr(iWord + WORD_COUNT);
            end loop;  -- iWord
            
            for iData_in_count in WORD_COUNT + EXTRA_WORD_COUNT downto 0 loop
--            if ( (iData_in_count + iExtra_words <= WORD_COUNT ) and
--                 (data_in_count_int = iData_in_count)) then              
              if (data_in_count_int = iData_in_count) then              
                --add in new words
                for iWord in iData_in_count -1 downto 0 loop
--                word_sr(2*WORD_COUNT + iExtra_words + iWord) <= words_in(iWord);
                  word_sr(WORD_COUNT + iExtra_words + iWord) <= words_in(iWord);
                end loop;  -- iWord              
                --word_sr(2*WORD_COUNT + iExtra_words + iData_in_count - 1 downto 2*WORD_COUNT + iExtra_words) <= words_in(iData_in_count -1 downto 0);     
                
              end if;
            end loop;  -- data_in_count
          end if;
        end loop;  -- iExtraWords
      end if;

      --Output the bottom of our shift register
      for iWord in WORD_COUNT -1 downto 0 loop
        data_out((iWord+1)*BYTES_PER_WORD*BITS_PER_BYTE - 1 downto iWord*BYTES_PER_WORD*BITS_PER_BYTE) <= word_sr(iWord);        
      end loop;  -- iWord

    end if;
  end process shift_register_state_machine;


  --Update special request size
  special_word_update: process (extra_words,data_in_count_int) is
  begin  -- process special_word_update

    --Default we want extra word count
    special_word_request <= std_logic_vector(to_unsigned(EXTRA_WORD_COUNT,8));
    
--2017-11-21--    if extra_words = WORD_COUNT - EXTRA_WORD_COUNT then
    if extra_words >= WORD_COUNT then
      --we have too many extra words, one word count or more's worth, send zero
      --words for one clock tick
      special_word_request <= std_logic_vector(to_unsigned(0,8));
    else
      special_word_request <= std_logic_vector(to_unsigned(WORD_COUNT - extra_words,8));
--      special_word_request <= std_logic_vector(to_unsigned(EXTRA_WORD_COUNT,8));
    end if;
    
  end process special_word_update;


  
-------------------------------------------------------------------------------
-- Counters
-------------------------------------------------------------------------------
  monitor.enable_counter_underflow <= control.enable_counter_underflow;

  pipeline_delay_1: entity work.pipeline_delay
    generic map (
      WIDTH => 32,
      DELAY => 0)
    port map (
      clk      => clk,
      data_in  => counter_underflow,
      data_out => monitor.counter_underflow);
  
  counter_1: entity work.counter
    generic map (
      roll_over   => '0')
    port map (
      clk         => clk,
      reset_async => '0',
      reset_sync  => control.reset_counter_underflow,
      enable      => control.enable_counter_underflow,
      event       => underflow_error,
      count       => counter_underflow,
      at_max      => open);

  
end architecture behavioral;


