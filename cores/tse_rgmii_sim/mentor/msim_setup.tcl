
# (C) 2001-2016 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ----------------------------------------
# Auto-generated simulation script msim_setup.tcl
# ----------------------------------------
# This script can be used to simulate the following IP:
#     tse_rgmii
# To create a top-level simulation script which compiles other
# IP, and manages other system issues, copy the following template
# and adapt it to your needs:
# 
# # Start of template
# # If the copied and modified template file is "mentor.do", run it as:
# #   vsim -c -do mentor.do
# #
# # Source the generated sim script
# source msim_setup.tcl
# # Compile eda/sim_lib contents first
# dev_com
# # Override the top-level name (so that elab is useful)
# set TOP_LEVEL_NAME top
# # Compile the standalone IP.
# com
# # Compile the user top-level
# vlog -sv ../../top.sv
# # Elaborate the design.
# elab
# # Run the simulation
# run -a
# # Report success to the shell
# exit -code 0
# # End of template
# ----------------------------------------
# If tse_rgmii is one of several IP cores in your
# Quartus project, you can generate a simulation script
# suitable for inclusion in your top-level simulation
# script by running the following command line:
# 
# ip-setup-simulation --quartus-project=<quartus project>
# 
# ip-setup-simulation will discover the Altera IP
# within the Quartus project, and generate a unified
# script which supports all the Altera IP within the design.
# ----------------------------------------
# ACDS 15.1 185 linux 2016.08.13.18:40:57

# ----------------------------------------
# Initialize variables
if ![info exists SYSTEM_INSTANCE_NAME] { 
  set SYSTEM_INSTANCE_NAME ""
} elseif { ![ string match "" $SYSTEM_INSTANCE_NAME ] } { 
  set SYSTEM_INSTANCE_NAME "/$SYSTEM_INSTANCE_NAME"
}

if ![info exists TOP_LEVEL_NAME] { 
  set TOP_LEVEL_NAME "tse_rgmii"
}

if ![info exists QSYS_SIMDIR] { 
  set QSYS_SIMDIR "./../"
}

if ![info exists QUARTUS_INSTALL_DIR] { 
  set QUARTUS_INSTALL_DIR "/opt/altera/15.1/quartus/"
}

if ![info exists USER_DEFINED_COMPILE_OPTIONS] { 
  set USER_DEFINED_COMPILE_OPTIONS ""
}
if ![info exists USER_DEFINED_ELAB_OPTIONS] { 
  set USER_DEFINED_ELAB_OPTIONS ""
}

# ----------------------------------------
# Initialize simulation properties - DO NOT MODIFY!
set ELAB_OPTIONS ""
set SIM_OPTIONS ""
if ![ string match "*-64 vsim*" [ vsim -version ] ] {
} else {
}

# ----------------------------------------
# Copy ROM/RAM files to simulation directory
alias file_copy {
  echo "\[exec\] file_copy"
}

# ----------------------------------------
# Create compilation libraries
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib          ./libraries/     
ensure_lib          ./libraries/work/
vmap       work     ./libraries/work/
vmap       work_lib ./libraries/work/
if ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
  ensure_lib                     ./libraries/altera_ver/         
  vmap       altera_ver          ./libraries/altera_ver/         
  ensure_lib                     ./libraries/lpm_ver/            
  vmap       lpm_ver             ./libraries/lpm_ver/            
  ensure_lib                     ./libraries/sgate_ver/          
  vmap       sgate_ver           ./libraries/sgate_ver/          
  ensure_lib                     ./libraries/altera_mf_ver/      
  vmap       altera_mf_ver       ./libraries/altera_mf_ver/      
  ensure_lib                     ./libraries/altera_lnsim_ver/   
  vmap       altera_lnsim_ver    ./libraries/altera_lnsim_ver/   
  ensure_lib                     ./libraries/arriav_ver/         
  vmap       arriav_ver          ./libraries/arriav_ver/         
  ensure_lib                     ./libraries/arriav_hssi_ver/    
  vmap       arriav_hssi_ver     ./libraries/arriav_hssi_ver/    
  ensure_lib                     ./libraries/arriav_pcie_hip_ver/
  vmap       arriav_pcie_hip_ver ./libraries/arriav_pcie_hip_ver/
  ensure_lib                     ./libraries/altera/             
  vmap       altera              ./libraries/altera/             
  ensure_lib                     ./libraries/lpm/                
  vmap       lpm                 ./libraries/lpm/                
  ensure_lib                     ./libraries/sgate/              
  vmap       sgate               ./libraries/sgate/              
  ensure_lib                     ./libraries/altera_mf/          
  vmap       altera_mf           ./libraries/altera_mf/          
  ensure_lib                     ./libraries/altera_lnsim/       
  vmap       altera_lnsim        ./libraries/altera_lnsim/       
  ensure_lib                     ./libraries/arriav/             
  vmap       arriav              ./libraries/arriav/             
}
ensure_lib                      ./libraries/i_phyip_terminator_0/
vmap       i_phyip_terminator_0 ./libraries/i_phyip_terminator_0/
ensure_lib                      ./libraries/i_custom_phyip_0/    
vmap       i_custom_phyip_0     ./libraries/i_custom_phyip_0/    
ensure_lib                      ./libraries/i_tse_pcs_0/         
vmap       i_tse_pcs_0          ./libraries/i_tse_pcs_0/         

# ----------------------------------------
# Compile device library files
alias dev_com {
  echo "\[exec\] dev_com"
  if ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] {
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                     -work altera_ver         
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                              -work lpm_ver            
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                 -work sgate_ver          
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                             -work altera_mf_ver      
    eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/altera_lnsim_for_vhdl.sv"         -work altera_lnsim_ver   
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/arriav_atoms_ncrypt.v"            -work arriav_ver         
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/arriav_hmi_atoms_ncrypt.v"        -work arriav_ver         
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/arriav_atoms_for_vhdl.v"          -work arriav_ver         
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/arriav_hssi_atoms_ncrypt.v"       -work arriav_hssi_ver    
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/arriav_hssi_atoms_for_vhdl.v"     -work arriav_hssi_ver    
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/arriav_pcie_hip_atoms_ncrypt.v"   -work arriav_pcie_hip_ver
    eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/mentor/arriav_pcie_hip_atoms_for_vhdl.v" -work arriav_pcie_hip_ver
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_syn_attributes.vhd"               -work altera             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_standard_functions.vhd"           -work altera             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/alt_dspbuilder_package.vhd"              -work altera             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_europa_support_lib.vhd"           -work altera             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives_components.vhd"        -work altera             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.vhd"                   -work altera             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220pack.vhd"                             -work lpm                
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.vhd"                            -work lpm                
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate_pack.vhd"                          -work sgate              
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.vhd"                               -work sgate              
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf_components.vhd"                -work altera_mf          
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.vhd"                           -work altera_mf          
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim_components.vhd"             -work altera_lnsim       
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/arriav_atoms.vhd"                        -work arriav             
    eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QUARTUS_INSTALL_DIR/eda/sim_lib/arriav_components.vhd"                   -work arriav             
  }
}

# ----------------------------------------
# Compile the design files in correct order
alias com {
  echo "\[exec\] com"
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_phyip_terminator/mentor/altera_eth_tse_phyip_terminator.v"     -work i_phyip_terminator_0
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_phyip_terminator/mentor/altera_tse_fake_master.v"              -work i_phyip_terminator_0
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_functions.sv"                              -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/altera_xcvr_functions.sv"                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_custom.sv"                                 -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/altera_xcvr_custom.sv"                          -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_custom_nr.sv"                                  -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_custom_native.sv"                              -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_xcvr_custom_nr.sv"                           -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_xcvr_custom_native.sv"                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_resync.sv"                                    -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_resync.sv"                             -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_common_h.sv"                              -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_common.sv"                                -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_pcs8g_h.sv"                               -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_pcs8g.sv"                                 -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_selector.sv"                              -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_mgmt2dec.sv"                                  -work i_custom_phyip_0    
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_wait_generate.v"                                -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_csr_common_h.sv"                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_csr_common.sv"                         -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_csr_pcs8g_h.sv"                        -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_csr_pcs8g.sv"                          -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_csr_selector.sv"                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_mgmt2dec.sv"                           -work i_custom_phyip_0    
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/altera_wait_generate.v"                         -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_to_xcvr.sv"                         -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_to_ip.sv"                           -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_merger.sv"                          -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/sv_reconfig_bundle_to_xcvr.sv"                  -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/sv_reconfig_bundle_to_ip.sv"                    -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/sv_reconfig_bundle_merger.sv"                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_h.sv"                                          -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_avmm_csr.sv"                                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_tx_pma_ch.sv"                                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_tx_pma.sv"                                          -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_rx_pma.sv"                                          -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_pma.sv"                                             -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_pcs_ch.sv"                                          -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_pcs.sv"                                             -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_avmm.sv"                                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_native.sv"                                     -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_plls.sv"                                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_data_adapter.sv"                               -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_reconfig_bundle_to_basic.sv"                        -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_reconfig_bundle_to_xcvr.sv"                         -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_xcvr_h.sv"                                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_xcvr_avmm_csr.sv"                            -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_tx_pma_ch.sv"                                -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_tx_pma.sv"                                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_rx_pma.sv"                                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_pma.sv"                                      -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_pcs_ch.sv"                                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_pcs.sv"                                      -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_xcvr_avmm.sv"                                -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_xcvr_native.sv"                              -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_xcvr_plls.sv"                                -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_xcvr_data_adapter.sv"                        -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_reconfig_bundle_to_basic.sv"                 -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_reconfig_bundle_to_xcvr.sv"                  -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_8g_rx_pcs_rbc.sv"                              -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_8g_tx_pcs_rbc.sv"                              -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_common_pcs_pma_interface_rbc.sv"               -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_common_pld_pcs_interface_rbc.sv"               -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_pipe_gen1_2_rbc.sv"                            -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_rx_pcs_pma_interface_rbc.sv"                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_rx_pld_pcs_interface_rbc.sv"                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_tx_pcs_pma_interface_rbc.sv"                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_tx_pld_pcs_interface_rbc.sv"                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_8g_rx_pcs_rbc.sv"                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_8g_tx_pcs_rbc.sv"                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_common_pcs_pma_interface_rbc.sv"        -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_common_pld_pcs_interface_rbc.sv"        -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_pipe_gen1_2_rbc.sv"                     -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_rx_pcs_pma_interface_rbc.sv"            -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_rx_pld_pcs_interface_rbc.sv"            -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_tx_pcs_pma_interface_rbc.sv"            -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/av_hssi_tx_pld_pcs_interface_rbc.sv"            -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_reset_control.sv"                          -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_reset_counter.sv"                             -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/altera_xcvr_reset_control.sv"                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_reset_counter.sv"                      -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_arbiter.sv"                                   -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_m2s.sv"                                       -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_arbiter.sv"                            -work i_custom_phyip_0    
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/mentor/alt_xcvr_m2s.sv"                                -work i_custom_phyip_0    
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_eth_tse_pcs_pma_phyip.v"           -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_align_sync.v"                  -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_dec10b8b.v"                    -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_dec_func.v"                    -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_enc8b10b.v"                    -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_autoneg.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_carrier_sense.v"               -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_clk_gen.v"                     -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_sgmii_clk_div.v"               -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_sgmii_clk_enable.v"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_rx_encapsulation.v"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_tx_encapsulation.v"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_rx_encapsulation_strx_gx.v"    -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_pcs_control.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_pcs_host_control.v"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_mdio_reg.v"                    -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_mii_rx_if_pcs.v"               -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_mii_tx_if_pcs.v"               -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_rx_sync.v"                     -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_sgmii_clk_cntl.v"              -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_colision_detect.v"             -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_rx_converter.v"                -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_rx_fifo_rd.v"                  -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_rx_converter.v"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_sgmii.v"                   -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_sgmii_strx_gx.v"           -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_tx_converter.v"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_tx_converter.v"                -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_1000_base_x.v"             -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_1000_base_x_strx_gx.v"     -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_pcs.v"                     -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_pcs_strx_gx.v"             -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_rx.v"                      -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_top_tx.v"                      -work i_tse_pcs_0         
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_reset_sequencer.sv"            -work i_tse_pcs_0         
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_reset_ctrl_lego.sv"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_xcvr_resync.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_gxb_aligned_rxsync.v"          -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_eth_tse_std_synchronizer.v"        -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_eth_tse_std_synchronizer_bundle.v" -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_false_path_marker.v"           -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_reset_synchronizer.v"          -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_clock_crosser.v"               -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_a_fifo_13.v"                   -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_a_fifo_24.v"                   -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_a_fifo_34.v"                   -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_a_fifo_opt_1246.v"             -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_a_fifo_opt_14_44.v"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_a_fifo_opt_36_10.v"            -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_gray_cnt.v"                    -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_sdpm_altsyncram.v"             -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_altsyncram_dpm_fifo.v"         -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_bin_cnt.v"                     -work i_tse_pcs_0         
  eval  vlog -sv $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ph_calculator.sv"              -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_sdpm_gen.v"                    -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_dec_x10.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x10.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x10_wrapper.v"         -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_dec_x14.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x14.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x14_wrapper.v"         -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_dec_x2.v"                  -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x2.v"                  -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x2_wrapper.v"          -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_dec_x23.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x23.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x23_wrapper.v"         -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_dec_x36.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x36.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x36_wrapper.v"         -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_dec_x40.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x40.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x40_wrapper.v"         -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_dec_x30.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x30.v"                 -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_enc_x30_wrapper.v"         -work i_tse_pcs_0         
  eval  vlog $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/mentor/altera_tse_ecc_status_crosser.v"          -work i_tse_pcs_0         
  eval  vcom $USER_DEFINED_COMPILE_OPTIONS     "$QSYS_SIMDIR/tse_rgmii.vhd"                                                                                          
}

# ----------------------------------------
# Elaborate top level design
alias elab {
  echo "\[exec\] elab"
  eval vsim -t ps $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS -L work -L work_lib -L i_phyip_terminator_0 -L i_custom_phyip_0 -L i_tse_pcs_0 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L arriav_ver -L arriav_hssi_ver -L arriav_pcie_hip_ver -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L arriav $TOP_LEVEL_NAME
}

# ----------------------------------------
# Elaborate the top level design with novopt option
alias elab_debug {
  echo "\[exec\] elab_debug"
  eval vsim -novopt -t ps $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS -L work -L work_lib -L i_phyip_terminator_0 -L i_custom_phyip_0 -L i_tse_pcs_0 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L arriav_ver -L arriav_hssi_ver -L arriav_pcie_hip_ver -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L arriav $TOP_LEVEL_NAME
}

# ----------------------------------------
# Compile all the design files and elaborate the top level design
alias ld "
  dev_com
  com
  elab
"

# ----------------------------------------
# Compile all the design files and elaborate the top level design with -novopt
alias ld_debug "
  dev_com
  com
  elab_debug
"

# ----------------------------------------
# Print out user commmand line aliases
alias h {
  echo "List Of Command Line Aliases"
  echo
  echo "file_copy                     -- Copy ROM/RAM files to simulation directory"
  echo
  echo "dev_com                       -- Compile device library files"
  echo
  echo "com                           -- Compile the design files in correct order"
  echo
  echo "elab                          -- Elaborate top level design"
  echo
  echo "elab_debug                    -- Elaborate the top level design with novopt option"
  echo
  echo "ld                            -- Compile all the design files and elaborate the top level design"
  echo
  echo "ld_debug                      -- Compile all the design files and elaborate the top level design with -novopt"
  echo
  echo 
  echo
  echo "List Of Variables"
  echo
  echo "TOP_LEVEL_NAME                -- Top level module name."
  echo "                                 For most designs, this should be overridden"
  echo "                                 to enable the elab/elab_debug aliases."
  echo
  echo "SYSTEM_INSTANCE_NAME          -- Instantiated system module name inside top level module."
  echo
  echo "QSYS_SIMDIR                   -- Qsys base simulation directory."
  echo
  echo "QUARTUS_INSTALL_DIR           -- Quartus installation directory."
  echo
  echo "USER_DEFINED_COMPILE_OPTIONS  -- User-defined compile options, added to com/dev_com aliases."
  echo
  echo "USER_DEFINED_ELAB_OPTIONS     -- User-defined elaboration options, added to elab/elab_debug aliases."
}
file_copy
h
