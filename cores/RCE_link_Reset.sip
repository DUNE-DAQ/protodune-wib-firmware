set_global_assignment -entity "RCE_link_Reset" -library "lib_RCE_link_Reset" -name IP_TOOL_NAME "altera_xcvr_reset_control"
set_global_assignment -entity "RCE_link_Reset" -library "lib_RCE_link_Reset" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "RCE_link_Reset" -library "lib_RCE_link_Reset" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_RCE_link_Reset" -name SPD_FILE [file join $::quartus(sip_path) "RCE_link_Reset.spd"]

set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/RCE_link_Reset.vhd"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/altera_xcvr_functions.sv"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/mentor/altera_xcvr_functions.sv"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/alt_xcvr_resync.sv"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/mentor/alt_xcvr_resync.sv"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/altera_xcvr_reset_control.sv"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/alt_xcvr_reset_counter.sv"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/mentor/altera_xcvr_reset_control.sv"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/mentor/alt_xcvr_reset_counter.sv"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/plain_files.txt"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/mentor_files.txt"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/cadence_files.txt"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/synopsys_files.txt"]
set_global_assignment -library "lib_RCE_link_Reset" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_Reset_sim/altera_xcvr_reset_control/aldec_files.txt"]
