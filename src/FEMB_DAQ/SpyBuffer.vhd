library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

entity SpyBuffer is
  
  generic (
    SAMPLE_WIDTH : integer := 9);

  port (
    clk_wr     : in  std_logic;
    data_in    : in  std_logic_vector(SAMPLE_WIDTH-1 downto 0);
    arm        : in  std_logic;
    state      : out std_logic_vector(1 downto 0);
    sw_trig    : in  std_logic;
    ext_en     : in  std_logic;
    ext_trig   : in  std_logic;
    word_en    : in  std_logic;
    word_trig  : in  std_logic_vector(SAMPLE_WIDTH-1 downto 0);
    
    clk_rd     : in  std_logic;
    fifo_rd    : in  std_logic;
    fifo_empty : out std_logic;
    fifo_data  : out std_logic_vector(SAMPLE_WIDTH-1 downto 0)    
    );
end entity SpyBuffer;

architecture behavioral of SpyBuffer is

  component Stream_SpyBuffer is
    port (
      aclr    : IN  STD_LOGIC := '0';
      data    : IN  STD_LOGIC_VECTOR (8 DOWNTO 0);
      rdclk   : IN  STD_LOGIC;
      rdreq   : IN  STD_LOGIC;
      wrclk   : IN  STD_LOGIC;
      wrreq   : IN  STD_LOGIC;
      q       : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
      rdempty : OUT STD_LOGIC;
      wrfull  : OUT STD_LOGIC);
  end component Stream_SpyBuffer;
  
  -------------------------------------------------------------------------------
  -- spy buffer signals
  -------------------------------------------------------------------------------
  type spy_buffer_state_t is (SPY_BUFFER_STATE_IDLE,
                              SPY_BUFFER_STATE_WAIT,
                              SPY_BUFFER_STATE_CAPTURE);
  signal spy_buffer_state        : spy_buffer_state_t := SPY_BUFFER_STATE_IDLE;
  signal spy_buffer_write_enable : std_logic := '0';
  signal spy_buffer_full         : std_logic := '0';

  signal latched_ext_en          : std_logic;
  signal latched_word_en         : std_logic;
  signal latched_word_trig       : std_logic_vector(SAMPLE_WIDTH-1 downto 0);

  signal data_delay              : std_logic_vector(SAMPLE_WIDTH-1 downto 0);  
  signal fifo_reset              : std_logic := '0';
  
begin

-------------------------------------------------------------------------------
-- Spy buffer
-------------------------------------------------------------------------------
  state <= "01" when spy_buffer_state = SPY_BUFFER_STATE_IDLE else
           "10" when spy_buffer_state = SPY_BUFFER_STATE_WAIT else
           "11" when spy_buffer_state = SPY_BUFFER_STATE_CAPTURE else
           "00";
  spy_buffer_control: process (clk_wr) is
  begin  -- process spy_buffer_control
    if clk_wr'event and clk_wr = '1' then  -- rising clock edge
      --fifo reset pulse disable
      fifo_reset <= '0';

      --Delay data for one clock tick
      data_delay <= data_in;
      
      if arm = '1' then
        -- Force us into the wait state
        spy_buffer_state <= SPY_BUFFER_STATE_WAIT;
        --Reset FIFO data
        fifo_reset <= '1';
        --latch trigger values
        latched_ext_en    <= ext_en;
        latched_word_en   <= word_en;  
        latched_word_trig <= word_trig;        
      else
        --state machine control
        case spy_buffer_state is
          ---------------------------------------------------
          when SPY_BUFFER_STATE_IDLE => NULL;
          ---------------------------------------------------
          when SPY_BUFFER_STATE_WAIT =>
            if latched_ext_en = '1' and ext_trig = '1' then
              spy_buffer_state <= SPY_BUFFER_STATE_CAPTURE;
            elsif latched_word_en = '1' and data_in = latched_word_trig then
              spy_buffer_state <= SPY_BUFFER_STATE_CAPTURE;
            elsif sw_trig = '1' then
              spy_buffer_state <= SPY_BUFFER_STATE_CAPTURE;
            end if;
          ---------------------------------------------------            
          when SPY_BUFFER_STATE_CAPTURE =>
            if spy_buffer_full = '1' then
              spy_buffer_state <= SPY_BUFFER_STATE_IDLE;
            end if;
          ---------------------------------------------------
          when others => spy_buffer_state <= SPY_BUFFER_STATE_IDLE;
        end case;
      end if;
      
    end if;
  end process spy_buffer_control;

  
  spy_buffer_write_enable <= '1' when (spy_buffer_state = SPY_BUFFER_STATE_CAPTURE and spy_buffer_full = '0')
                             else '0';

  Stream_SpyBuffer_1: Stream_SpyBuffer
    port map (
      aclr    => fifo_reset,
      data    => data_delay,
      rdclk   => clk_rd,
      rdreq   => fifo_rd,
      wrclk   => clk_wr,
      wrreq   => spy_buffer_write_enable,
      q       => fifo_data,
      rdempty => fifo_empty,
      wrfull  => spy_buffer_full);

end architecture behavioral;
