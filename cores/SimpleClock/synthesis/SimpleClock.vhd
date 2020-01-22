-- SimpleClock.vhd

-- Generated using ACDS version 16.0 211

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SimpleClock is
	port (
		inclk  : in  std_logic := '0'; --  altclkctrl_input.inclk
		outclk : out std_logic         -- altclkctrl_output.outclk
	);
end entity SimpleClock;

architecture rtl of SimpleClock is
	component SimpleClock_altclkctrl_0 is
		port (
			inclk  : in  std_logic := 'X'; -- inclk
			outclk : out std_logic         -- outclk
		);
	end component SimpleClock_altclkctrl_0;

begin

	altclkctrl_0 : component SimpleClock_altclkctrl_0
		port map (
			inclk  => inclk,  --  altclkctrl_input.inclk
			outclk => outclk  -- altclkctrl_output.outclk
		);

end architecture rtl; -- of SimpleClock
