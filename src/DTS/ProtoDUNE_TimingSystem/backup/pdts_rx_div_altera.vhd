-- pdts_rx_div_altera
--
-- Clock divider for rx side
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.pdts_defs.all;


entity pdts_rx_div_altera is
	port(
		sclk: in std_logic;
		clk: out std_logic;
		phase_rst: in std_logic;
		phase_locked: out std_logic
	);
		
end pdts_rx_div_altera;

architecture rtl of pdts_rx_div_altera is

  component PDTS_PLL is
    port (
      refclk   : in  std_logic := '0';
      rst      : in  std_logic := '0';
      outclk_0 : out std_logic;
      locked   : out std_logic);
  end component PDTS_PLL;
  
begin

  PDTS_PLL_1: PDTS_PLL
    port map (
      refclk   => sclk,
      rst      => phase_rst,
      outclk_0 => clk,
      locked   => phase_locked);
  
end rtl;
