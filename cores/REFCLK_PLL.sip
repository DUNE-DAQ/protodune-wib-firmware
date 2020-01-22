set_global_assignment -entity "REFCLK_PLL" -library "lib_REFCLK_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "REFCLK_PLL" -library "lib_REFCLK_PLL" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "REFCLK_PLL" -library "lib_REFCLK_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_REFCLK_PLL" -name SPD_FILE [file join $::quartus(sip_path) "REFCLK_PLL.spd"]

set_global_assignment -library "lib_REFCLK_PLL" -name MISC_FILE [file join $::quartus(sip_path) "REFCLK_PLL_sim/REFCLK_PLL.vho"]
