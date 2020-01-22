set_global_assignment -entity "PDTS_PLL" -library "lib_PDTS_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "PDTS_PLL" -library "lib_PDTS_PLL" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "PDTS_PLL" -library "lib_PDTS_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_PDTS_PLL" -name SPD_FILE [file join $::quartus(sip_path) "PDTS_PLL.spd"]

set_global_assignment -library "lib_PDTS_PLL" -name MISC_FILE [file join $::quartus(sip_path) "PDTS_PLL_sim/PDTS_PLL.vho"]
