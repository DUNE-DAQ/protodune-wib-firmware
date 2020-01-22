library ieee;
use ieee.std_logic_1164.all;
use work.DTS_IO.all;

entity DTS_tx is
  
  port (
    clk_sys_50Mhz : in  std_logic;
    clk_PDTS      : in  std_logic;
    clk_PDTS_d    : in  std_logic;
    DTS_data_in   : in  std_logic;
    DTS_data_out  : out std_logic;
    DTS_OUT_DSBL  : out std_logic;
    monitor       : out DTS_Tx_Monitor_t;
    control       : in  DTS_Tx_Control_t);
end entity DTS_tx;

architecture behavioral of DTS_tx is

  constant delay_length : integer := 10;
  signal buffered_data_out_delay : std_logic_vector(DELAY_LENGTH-1 downto 0) := (others => '0');
  
begin  -- architecture behavioral

  monitor.buffered_loopback <= control.buffered_loopback;
  
  --output enable control
  DTS_OUT_DSBL <= not control.OE;
  monitor.OE <= control.OE;
    
  --output control
  output_control: process (buffered_data_out_delay(0),control.buffered_loopback) is
  begin  -- process output_control
    if control.buffered_loopback = '1' then
      DTS_data_out <= buffered_data_out_delay(0);
    else
      DTS_data_out <= '0';
    end if;
  end process output_control;

  -- buffered output
  buffered_output: process (clk_PDTS_d) is
  begin  -- process buffered_output
    if clk_PDTS_d'event and clk_PDTS_d = '1' then  -- rising clock edge
      buffered_data_out_delay(DELAY_LENGTH-1 downto 0) <= DTS_data_in & buffered_data_out_delay(DELAY_LENGTH-1 downto 1) ;
    end if;
  end process buffered_output;
  
end architecture behavioral;
