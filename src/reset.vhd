library ieee;
use ieee.std_logic_1164.all;

entity reseter is
  generic (
    DEPTH : integer := 2);
  port (
    clk         : in  std_logic;
    reset_async : in  std_logic;
    reset_sync  : in  std_logic;
    reset       : out std_logic);

end entity reseter;

architecture Behavioral of reseter is

  signal reset_buffer : std_logic_vector(DEPTH-1 downto 0) := (others => '1');
    
begin  -- architecture Behavioral

  reset <= reset_buffer(DEPTH-1);
reset_proc: process (clk, reset_async) is
begin  -- process reset_proc
  if reset_async = '1' then             -- asynchronous reset (active high)
    reset_buffer <= (others => '1');
--    reset_buffer(0) <= '1';
  elsif clk'event and clk = '1' then    -- rising clock edge
    reset_buffer(0) <= reset_sync;
    reset_buffer(DEPTH-1 downto 1) <= reset_buffer(DEPTH-2 downto 0);
  end if;
end process reset_proc;
  

end architecture Behavioral;

