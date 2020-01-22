set_global_assignment -entity "COLDATA_fPLL" -library "lib_COLDATA_fPLL" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "COLDATA_fPLL" -library "lib_COLDATA_fPLL" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "COLDATA_fPLL" -library "lib_COLDATA_fPLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_COLDATA_fPLL" -name SPD_FILE [file join $::quartus(sip_path) "COLDATA_fPLL.spd"]

set_global_assignment -library "lib_COLDATA_fPLL" -name MISC_FILE [file join $::quartus(sip_path) "COLDATA_fPLL_sim/COLDATA_fPLL.vho"]
