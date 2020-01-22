set_global_assignment -entity "DCC_DUNE_PLL" -library "lib_DCC_DUNE_PLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "DCC_DUNE_PLL" -library "lib_DCC_DUNE_PLL" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "DCC_DUNE_PLL" -library "lib_DCC_DUNE_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_DCC_DUNE_PLL" -name SPD_FILE [file join $::quartus(sip_path) "DCC_DUNE_PLL.spd"]

set_global_assignment -library "lib_DCC_DUNE_PLL" -name MISC_FILE [file join $::quartus(sip_path) "DCC_DUNE_PLL_sim/DCC_DUNE_PLL.vho"]
