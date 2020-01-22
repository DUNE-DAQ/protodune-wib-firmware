set_global_assignment -entity "FEMB_DTS_clk" -library "lib_FEMB_DTS_clk" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "FEMB_DTS_clk" -library "lib_FEMB_DTS_clk" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "FEMB_DTS_clk" -library "lib_FEMB_DTS_clk" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_FEMB_DTS_clk" -name SPD_FILE [file join $::quartus(sip_path) "FEMB_DTS_clk.spd"]

set_global_assignment -library "lib_FEMB_DTS_clk" -name MISC_FILE [file join $::quartus(sip_path) "FEMB_DTS_clk_sim/FEMB_DTS_clk.vho"]
