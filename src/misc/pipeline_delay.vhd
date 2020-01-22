library IEEE;
use IEEE.std_logic_1164.all;


entity pipeline_delay is
  
  generic (
    WIDTH : integer := 32;
    DELAY : integer := 1);

  port (
    clk      : in  std_logic;
    data_in  : in  std_logic_vector(WIDTH-1 downto 0);
    data_out : out std_logic_vector(WIDTH-1 downto 0));

end entity pipeline_delay;

architecture behavioral of pipeline_delay is

  type pipeline_t is array (DELAY downto 0) of std_logic_vector(WIDTH-1 downto 0);
  signal pipeline : pipeline_t;
begin  -- architecture behavioral

  --Handles zero delay well (negative is a syntax error)
  pipeline(0) <= data_in;
  data_out    <= pipeline(DELAY);

  --only generate a pipeline if we really need one
  pipeline_needed: if DELAY > 0 generate   
    pipeline_proc: process (clk) is
    begin  -- process pipeline_proc
      if clk'event and clk = '1' then  -- rising clock edge
        pipeline(DELAY downto 1) <= pipeline(DELAY-1 downto 0);
      end if;
    end process pipeline_proc;    
  end generate pipeline_needed;

end architecture behavioral;
