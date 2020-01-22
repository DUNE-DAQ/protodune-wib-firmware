set_global_assignment -entity "PLL_128" -library "lib_PLL_128" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "PLL_128" -library "lib_PLL_128" -name IP_TOOL_VERSION "14.1"
set_global_assignment -entity "PLL_128" -library "lib_PLL_128" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_PLL_128" -name SPD_FILE [file join $::quartus(sip_path) "PLL_128.spd"]

set_global_assignment -library "lib_PLL_128" -name MISC_FILE [file join $::quartus(sip_path) "PLL_128_sim/PLL_128.vho"]
