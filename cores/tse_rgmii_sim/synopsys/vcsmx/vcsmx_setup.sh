
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

# ACDS 15.1 185 linux 2016.08.13.18:40:57

# ----------------------------------------
# vcsmx - auto-generated simulation script

# ----------------------------------------
# This script can be used to simulate the following IP:
#     tse_rgmii
# To create a top-level simulation script which compiles other
# IP, and manages other system issues, copy the following template
# and adapt it to your needs:
# 
# # Start of template
# # If the copied and modified template file is "vcsmx_sim.sh", run it as:
# #   ./vcsmx_sim.sh
# #
# # Do the file copy, dev_com and com steps
# source vcsmx_setup.sh \
# SKIP_ELAB=1 \
# SKIP_SIM=1
# 
# # Compile the top level module
# vlogan +v2k +systemverilogext+.sv "$QSYS_SIMDIR/../top.sv"
# 
# # Do the elaboration and sim steps
# # Override the top-level name
# # Override the user-defined sim options, so the simulation runs 
# # forever (until $finish()).
# source vcsmx_setup.sh \
# SKIP_FILE_COPY=1 \
# SKIP_DEV_COM=1 \
# SKIP_COM=1 \
# TOP_LEVEL_NAME="'-top top'" \
# USER_DEFINED_SIM_OPTIONS=""
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
# initialize variables
TOP_LEVEL_NAME="tse_rgmii"
QSYS_SIMDIR="./../../"
QUARTUS_INSTALL_DIR="/opt/altera/15.1/quartus/"
SKIP_FILE_COPY=0
SKIP_DEV_COM=0
SKIP_COM=0
SKIP_ELAB=0
SKIP_SIM=0
USER_DEFINED_ELAB_OPTIONS=""
USER_DEFINED_SIM_OPTIONS="+vcs+finish+100"

# ----------------------------------------
# overwrite variables - DO NOT MODIFY!
# This block evaluates each command line argument, typically used for 
# overwriting variables. An example usage:
#   sh <simulator>_setup.sh SKIP_ELAB=1 SKIP_SIM=1
for expression in "$@"; do
  eval $expression
  if [ $? -ne 0 ]; then
    echo "Error: This command line argument, \"$expression\", is/has an invalid expression." >&2
    exit $?
  fi
done

# ----------------------------------------
# initialize simulation properties - DO NOT MODIFY!
ELAB_OPTIONS=""
SIM_OPTIONS=""
if [[ `vcs -platform` != *"amd64"* ]]; then
  :
else
  :
fi

# ----------------------------------------
# create compilation libraries
mkdir -p ./libraries/work/
mkdir -p ./libraries/i_phyip_terminator_0/
mkdir -p ./libraries/i_custom_phyip_0/
mkdir -p ./libraries/i_tse_pcs_0/
mkdir -p ./libraries/altera_ver/
mkdir -p ./libraries/lpm_ver/
mkdir -p ./libraries/sgate_ver/
mkdir -p ./libraries/altera_mf_ver/
mkdir -p ./libraries/altera_lnsim_ver/
mkdir -p ./libraries/arriav_ver/
mkdir -p ./libraries/arriav_hssi_ver/
mkdir -p ./libraries/arriav_pcie_hip_ver/
mkdir -p ./libraries/altera/
mkdir -p ./libraries/lpm/
mkdir -p ./libraries/sgate/
mkdir -p ./libraries/altera_mf/
mkdir -p ./libraries/altera_lnsim/
mkdir -p ./libraries/arriav/

# ----------------------------------------
# copy RAM/ROM files to simulation directory

# ----------------------------------------
# compile device library files
if [ $SKIP_DEV_COM -eq 0 ]; then
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v"                     -work altera_ver         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"                              -work lpm_ver            
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"                                 -work sgate_ver          
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"                             -work altera_mf_ver      
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"                         -work altera_lnsim_ver   
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/synopsys/arriav_atoms_ncrypt.v"          -work arriav_ver         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/synopsys/arriav_hmi_atoms_ncrypt.v"      -work arriav_ver         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/arriav_atoms.v"                          -work arriav_ver         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/synopsys/arriav_hssi_atoms_ncrypt.v"     -work arriav_hssi_ver    
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/arriav_hssi_atoms.v"                     -work arriav_hssi_ver    
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/synopsys/arriav_pcie_hip_atoms_ncrypt.v" -work arriav_pcie_hip_ver
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QUARTUS_INSTALL_DIR/eda/sim_lib/arriav_pcie_hip_atoms.v"                 -work arriav_pcie_hip_ver
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_syn_attributes.vhd"               -work altera             
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_standard_functions.vhd"           -work altera             
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/alt_dspbuilder_package.vhd"              -work altera             
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_europa_support_lib.vhd"           -work altera             
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives_components.vhd"        -work altera             
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.vhd"                   -work altera             
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/220pack.vhd"                             -work lpm                
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.vhd"                            -work lpm                
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate_pack.vhd"                          -work sgate              
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.vhd"                               -work sgate              
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf_components.vhd"                -work altera_mf          
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.vhd"                           -work altera_mf          
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim_components.vhd"             -work altera_lnsim       
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/arriav_atoms.vhd"                        -work arriav             
  vhdlan $USER_DEFINED_COMPILE_OPTIONS                "$QUARTUS_INSTALL_DIR/eda/sim_lib/arriav_components.vhd"                   -work arriav             
fi

# ----------------------------------------
# compile design files in correct order
if [ $SKIP_COM -eq 0 ]; then
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_phyip_terminator/synopsys/altera_eth_tse_phyip_terminator.v"     -work i_phyip_terminator_0
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_phyip_terminator/synopsys/altera_tse_fake_master.v"              -work i_phyip_terminator_0
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_functions.sv"                                -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_custom.sv"                                   -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_custom_nr.sv"                                    -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_custom_native.sv"                                -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_resync.sv"                                      -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_common_h.sv"                                -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_common.sv"                                  -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_pcs8g_h.sv"                                 -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_pcs8g.sv"                                   -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_csr_selector.sv"                                -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_mgmt2dec.sv"                                    -work i_custom_phyip_0    
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_wait_generate.v"                                  -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_to_xcvr.sv"                           -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_to_ip.sv"                             -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/sv_reconfig_bundle_merger.sv"                            -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_h.sv"                                            -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_avmm_csr.sv"                                     -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_tx_pma_ch.sv"                                         -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_tx_pma.sv"                                            -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_rx_pma.sv"                                            -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_pma.sv"                                               -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_pcs_ch.sv"                                            -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_pcs.sv"                                               -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_avmm.sv"                                         -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_native.sv"                                       -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_plls.sv"                                         -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_xcvr_data_adapter.sv"                                 -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_reconfig_bundle_to_basic.sv"                          -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_reconfig_bundle_to_xcvr.sv"                           -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_8g_rx_pcs_rbc.sv"                                -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_8g_tx_pcs_rbc.sv"                                -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_common_pcs_pma_interface_rbc.sv"                 -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_common_pld_pcs_interface_rbc.sv"                 -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_pipe_gen1_2_rbc.sv"                              -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_rx_pcs_pma_interface_rbc.sv"                     -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_rx_pld_pcs_interface_rbc.sv"                     -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_tx_pcs_pma_interface_rbc.sv"                     -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/av_hssi_tx_pld_pcs_interface_rbc.sv"                     -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/altera_xcvr_reset_control.sv"                            -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_reset_counter.sv"                               -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_arbiter.sv"                                     -work i_custom_phyip_0    
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_xcvr_custom_phy/alt_xcvr_m2s.sv"                                         -work i_custom_phyip_0    
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_eth_tse_pcs_pma_phyip.v"           -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_align_sync.v"                  -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_dec10b8b.v"                    -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_dec_func.v"                    -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_enc8b10b.v"                    -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_autoneg.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_carrier_sense.v"               -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_clk_gen.v"                     -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_sgmii_clk_div.v"               -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_sgmii_clk_enable.v"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_rx_encapsulation.v"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_tx_encapsulation.v"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_rx_encapsulation_strx_gx.v"    -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_pcs_control.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_pcs_host_control.v"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_mdio_reg.v"                    -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_mii_rx_if_pcs.v"               -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_mii_tx_if_pcs.v"               -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_rx_sync.v"                     -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_sgmii_clk_cntl.v"              -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_colision_detect.v"             -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_rx_converter.v"                -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_rx_fifo_rd.v"                  -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_rx_converter.v"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_sgmii.v"                   -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_sgmii_strx_gx.v"           -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_tx_converter.v"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_tx_converter.v"                -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_1000_base_x.v"             -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_1000_base_x_strx_gx.v"     -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_pcs.v"                     -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_pcs_strx_gx.v"             -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_rx.v"                      -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_top_tx.v"                      -work i_tse_pcs_0         
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_reset_sequencer.sv"            -work i_tse_pcs_0         
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_reset_ctrl_lego.sv"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_xcvr_resync.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_gxb_aligned_rxsync.v"          -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_eth_tse_std_synchronizer.v"        -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_eth_tse_std_synchronizer_bundle.v" -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_false_path_marker.v"           -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_reset_synchronizer.v"          -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_clock_crosser.v"               -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_a_fifo_13.v"                   -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_a_fifo_24.v"                   -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_a_fifo_34.v"                   -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_a_fifo_opt_1246.v"             -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_a_fifo_opt_14_44.v"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_a_fifo_opt_36_10.v"            -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_gray_cnt.v"                    -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_sdpm_altsyncram.v"             -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_altsyncram_dpm_fifo.v"         -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_bin_cnt.v"                     -work i_tse_pcs_0         
  vlogan +v2k -sverilog $USER_DEFINED_COMPILE_OPTIONS "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ph_calculator.sv"              -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_sdpm_gen.v"                    -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_dec_x10.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x10.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x10_wrapper.v"         -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_dec_x14.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x14.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x14_wrapper.v"         -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_dec_x2.v"                  -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x2.v"                  -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x2_wrapper.v"          -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_dec_x23.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x23.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x23_wrapper.v"         -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_dec_x36.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x36.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x36_wrapper.v"         -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_dec_x40.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x40.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x40_wrapper.v"         -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_dec_x30.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x30.v"                 -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_enc_x30_wrapper.v"         -work i_tse_pcs_0         
  vlogan +v2k $USER_DEFINED_COMPILE_OPTIONS           "$QSYS_SIMDIR/altera_eth_tse_pcs_pma_phyip/synopsys/altera_tse_ecc_status_crosser.v"          -work i_tse_pcs_0         
  vhdlan -xlrm $USER_DEFINED_COMPILE_OPTIONS          "$QSYS_SIMDIR/tse_rgmii.vhd"                                                                                            
fi

# ----------------------------------------
# elaborate top level design
if [ $SKIP_ELAB -eq 0 ]; then
  vcs -lca -t ps $ELAB_OPTIONS $USER_DEFINED_ELAB_OPTIONS $TOP_LEVEL_NAME
fi

# ----------------------------------------
# simulate
if [ $SKIP_SIM -eq 0 ]; then
  ./simv $SIM_OPTIONS $USER_DEFINED_SIM_OPTIONS
fi
