set_global_assignment -entity "RCE_link_PLL" -library "lib_RCE_link_PLL" -name IP_TOOL_NAME "altera_xcvr_pll_av"
set_global_assignment -entity "RCE_link_PLL" -library "lib_RCE_link_PLL" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "RCE_link_PLL" -library "lib_RCE_link_PLL" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_RCE_link_PLL" -name SPD_FILE [file join $::quartus(sip_path) "RCE_link_PLL.spd"]

set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/RCE_link_PLL.vhd"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/altera_xcvr_functions.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/mentor/altera_xcvr_functions.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/av_xcvr_h.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/av_xcvr_plls.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/av_reconfig_bundle_to_xcvr.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/av_xcvr_avmm_csr.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/mentor/av_xcvr_h.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/mentor/av_xcvr_plls.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/mentor/av_reconfig_bundle_to_xcvr.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/mentor/av_xcvr_avmm_csr.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/alt_xcvr_resync.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/mentor/alt_xcvr_resync.sv"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/plain_files.txt"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/mentor_files.txt"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/cadence_files.txt"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/synopsys_files.txt"]
set_global_assignment -library "lib_RCE_link_PLL" -name MISC_FILE [file join $::quartus(sip_path) "RCE_link_PLL_sim/altera_xcvr_pll_av/aldec_files.txt"]
