library ieee;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use work.DCC_IO.all;

entity FAKE_DTS is

  port (
    clk_DUNE          : in  std_logic;
    reset             : in  std_logic;    
    convert           : out std_logic;
    reset_count       : out std_logic_vector(23 downto 0);
    convert_count     : out std_logic_vector(15 downto 0);
    --UDP control and monitoring
    monitor           : out FAKE_DTS_Monitor_t;
    control           : in  FAKE_DTS_Control_t);

end entity FAKE_DTS;

architecture behavioral of FAKE_DTS is

  -- DUNE clock domain
  constant CONVERT_PERIOD_50Mhz : integer := 25;
  signal convert_pulse_generator : std_logic_vector(CONVERT_PERIOD_50MHz-1 downto 0) := (CONVERT_PERIOD_50MHz-1 => '1', others => '0');
  
  signal convert_pipeline        : std_logic_vector(1 downto 0) := "00";  -- convert trigger in the DCC 50 domain

  constant CONVERT_COUNTER_START : unsigned(15 downto 0) := x"0001";
  constant RESET_COUNTER_START   : unsigned(23 downto 0) := x"000000";
  signal reset_counter           : unsigned(23 downto 0) := RESET_COUNTER_START;
  signal convert_counter         : unsigned(15 downto 0) := CONVERT_COUNTER_START;

  
begin  -- architecture behavioral

  -- Generate the stream of 2Mhz pulses for the COLDATA ASICs from the 50Mhz clock
  monitor.enable <= control.enable;
  convert_pulser: process (clk_DUNE, reset) is
  begin  -- process convert_pulser
    if reset = '1' then                 -- asynchronous reset (active high)
      --Reset the shift register
      convert_pulse_generator <= (CONVERT_PERIOD_50MHz-1 => '1', others => '0');  
      convert_pipeline <= (others => '0');                          
    elsif clk_DUNE'event and clk_DUNE = '1' then  -- rising clock edge
      if control.enable = '1' then
        -- shift register
        for iBit in CONVERT_PERIOD_50Mhz-1 downto 1 loop
          convert_pulse_generator(iBit-1) <= convert_pulse_generator(iBit);
        end loop;  -- iBit
        convert_pulse_generator(CONVERT_PERIOD_50Mhz-1) <= convert_pulse_generator(0);
        
        -- trigger pulse
        convert_pipeline(0) <= convert_pulse_generator(1);
      else
        convert_pipeline(0) <= '0';
      end if;
      convert_pipeline(1) <= convert_pipeline(0);
    end if;
  end process convert_pulser;
  
  -- Keep track of convert and reset times.
  -- The convert pulse is sent to the FEMB and EventBuilder domains via a pacd.
  -- At this point, the convert_count and reset_count have already been buffered
  -- and can be safely latched by the other domains.
  -- We delay the convert pulse by 1 DCC_50Mhz clocks before updating them for
  -- the next trigger. The other domains should have already latched them
  -- during the last 50Mhz clock tick and they should have had many clock ticks
  -- by now.
  monitor.reset_count <= control.reset_count;
  DUNE_convert_builder : process (clk_DUNE, reset) is
  begin
    if reset = '1' then  -- asynchronous reset (active high)      
      --reset counters
      convert_counter      <= CONVERT_COUNTER_START;
      reset_counter        <= RESET_COUNTER_START;

    elsif clk_DUNE'event and clk_DUNE = '1' then  -- rising clock edge

      if control.reset_count = '1' then
        --reset counters
        convert_counter      <= CONVERT_COUNTER_START;
        reset_counter        <= RESET_COUNTER_START;
      else

        if convert_pipeline(0) = '1' then
          --Update convert and reset counters
          if convert_counter = x"FFFF" then
            convert_counter <= x"0000";
            if reset_counter = x"FFFFFF" then
              reset_counter <= x"000000";
            else
              reset_counter <= reset_counter + 1;
            end if;
          else
            convert_counter <= convert_counter + 1;
          end if;
        end if;
        
      end if;

    end if;
  end process DUNE_convert_builder;

  convert       <= convert_pipeline(1);
  reset_count   <= std_logic_vector(reset_counter);
  convert_count <= std_logic_vector(convert_counter);
  
end architecture behavioral;
