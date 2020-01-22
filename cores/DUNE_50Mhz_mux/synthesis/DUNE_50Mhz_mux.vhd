-- DUNE_50Mhz_mux.vhd

-- Generated using ACDS version 14.1 186 at 2016.11.02.14:11:12

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DUNE_50Mhz_mux is
	port (
		inclk3x   : in  std_logic                    := '0';             --  altclkctrl_input.inclk3x
		inclk2x   : in  std_logic                    := '0';             --                  .inclk2x
		inclk1x   : in  std_logic                    := '0';             --                  .inclk1x
		inclk0x   : in  std_logic                    := '0';             --                  .inclk0x
		clkselect : in  std_logic_vector(1 downto 0) := (others => '0'); --                  .clkselect
		outclk    : out std_logic                                        -- altclkctrl_output.outclk
	);
end entity DUNE_50Mhz_mux;

architecture rtl of DUNE_50Mhz_mux is
	component DUNE_50Mhz_mux_altclkctrl_0 is
		port (
			inclk3x   : in  std_logic                    := 'X';             -- inclk3x
			inclk2x   : in  std_logic                    := 'X';             -- inclk2x
			inclk1x   : in  std_logic                    := 'X';             -- inclk1x
			inclk0x   : in  std_logic                    := 'X';             -- inclk0x
			clkselect : in  std_logic_vector(1 downto 0) := (others => 'X'); -- clkselect
			outclk    : out std_logic                                        -- outclk
		);
	end component DUNE_50Mhz_mux_altclkctrl_0;

begin

	altclkctrl_0 : component DUNE_50Mhz_mux_altclkctrl_0
		port map (
			inclk3x   => inclk3x,   --  altclkctrl_input.inclk3x
			inclk2x   => inclk2x,   --                  .inclk2x
			inclk1x   => inclk1x,   --                  .inclk1x
			inclk0x   => inclk0x,   --                  .inclk0x
			clkselect => clkselect, --                  .clkselect
			outclk    => outclk     -- altclkctrl_output.outclk
		);

end architecture rtl; -- of DUNE_50Mhz_mux