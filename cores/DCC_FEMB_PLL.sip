set_global_assignment -entity "DCC_FEMB_PLL" -library "lib_DCC_FEMB_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "DCC_FEMB_PLL" -library "lib_DCC_FEMB_PLL" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "DCC_FEMB_PLL" -library "lib_DCC_FEMB_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_DCC_FEMB_PLL" -name SPD_FILE [file join $::quartus(sip_path) "DCC_FEMB_PLL.spd"]

set_global_assignment -library "lib_DCC_FEMB_PLL" -name MISC_FILE [file join $::quartus(sip_path) "DCC_FEMB_PLL_sim/DCC_FEMB_PLL.vho"]
