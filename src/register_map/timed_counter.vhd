-------------------------------------------------------------------------------
-- Generic counter with timer feature
-- Dan Gastler
-- Process count pulses and provide a buffered value of count
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;


entity timed_counter is

  generic (
    timer_count  : std_logic_vector;
    DATA_WIDTH   : integer          := 32);
  port (         
    clk          : in  std_logic;
    reset_async  : in  std_logic;
    reset_sync   : in  std_logic;
    enable       : in  std_logic;
    event        : in  std_logic;
    update_pulse : out std_logic;
    timed_count  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );

end entity timed_counter;

architecture behavioral of timed_counter is
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

  constant event_counter_max : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '1');
  constant event_counter_min : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  constant timer_count_max   : unsigned(DATA_WIDTH-1 downto 0) := unsigned(timer_count);

  signal timer_counter : unsigned(DATA_WIDTH-1 downto 0);
  signal event_count : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal reset_event_counter : std_logic;
  
begin 
  counter_1: entity work.counter
    generic map (
      roll_over   => '1',
      end_value   => event_counter_max,
      start_value => event_counter_min,
      DATA_WIDTH  => DATA_WIDTH)
    port map (
      clk         => clk,
      reset_async => reset_async,
      reset_sync  => reset_event_counter,
      enable      => enable,
      event       => event,
      count       => event_count,
      at_max      => open);

  counter_proc: process (clk, reset_async) is
  begin  -- process counter
    if reset_async = '1' then           -- asynchronous reset (active high)
      timer_counter <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      --Run counter from zero to timer_count_max
      timer_counter <= timer_counter + 1;
      if timer_counter = timer_count_max then
        timer_counter <= (others => '0');
      end if;

      --Hold at zero in reset
      if reset_sync = '1' or enable = '0' then
        timer_counter <= (others => '0');
      end if;
    end if;
  end process counter_proc;

  --Hold the counter in reset if timer_counter is zero
  reset_event_counter <= not or_reduce(std_logic_vector(timer_counter));
  
  timer_control: process (clk, reset_async) is
  begin  -- process timer_control
    if reset_async = '1' then           -- asynchronous reset (active high)
      timed_count <= (others => '0');
    elsif clk'event and clk = '1' then  -- rising clock edge
      update_pulse <= '0';
      if timer_counter = timer_count_max then
        timed_count <= std_logic_vector(event_count);
        update_pulse <= '1';
      elsif reset_sync = '1' or enable = '0' then
        timed_count <= (others=>'0');
      end if;
    end if;
  end process timer_control;
  
end architecture behavioral;

