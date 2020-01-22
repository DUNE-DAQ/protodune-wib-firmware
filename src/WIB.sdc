#************************************************************
# THIS IS A WIZARD-GENERATED FILE.                           
#
# Version 13.0.0 Build 156 04/24/2013 SJ Full Version
#
#************************************************************

# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.






# Clock constraints

set altera_reserved_tck { altera_reserved_tck }

create_clock -period 20.00 -name clk_in_50Mhz  [ get_ports clk_in_50Mhz ]


create_clock -period 7.8125 -name FEMB_Rx_refclk_P_0 [get_ports FEMB_Rx_refclk_P[0]]
create_clock -period 7.8125 -name FEMB_Rx_refclk_P_1 [get_ports FEMB_Rx_refclk_P[1]]
create_clock -period 7.8125 -name clk_FEMB_128Mhz_P  [get_ports clk_FEMB_128Mhz_P]

create_clock -period 8.0    -name RCE_Tx_refclk_P [get_ports RCE_Tx_refclk_P]
create_clock -period 8.317  -name FELIX_Tx_refclk_P [get_ports FELIX_Tx_refclk_P]


create_clock -period 8.0   -name SFP_refclk_P  [get_ports SFP_refclk_P]

create_clock -period 20ns    -name DUNE_clk_in_P [get_ports DUNE_clk_in_P]

#test
create_clock -period 4ns    -name DTS_data_clk_P [get_ports DTS_data_clk_P]

#create_clock -period 20ns   -name DTS_clk_P  [get_ports DTS_clk_P]

create_clock -period 10ns    -name DTS_FEMB_clk_P [get_ports DTS_FEMB_clk_P]

## Automatically constrain PLL and other generated clocks
#derive_pll_clocks -create_base_clocks
#
## Automatically calculate clock uncertainty to jitter and other effects.
#derive_clock_uncertainty

set_clock_groups \
    -exclusive \
    -group [get_clocks {FEMB_Rx_refclk_P_0 FEMB_Rx_refclk_P_1 clk_FEMB_128Mhz_P}] \
    -group [get_clocks FELIX_Tx_refclk_P] \
    -group [get_clocks RCE_Tx_refclk_P] \
    -group [get_clocks clk_in_50Mhz]  \
    -group [get_clocks {DTS_data_clk_P DUNE_clk_in_P}] \
    -group [get_clocks {EventBuilder_1|*tx_pma_ch.tx_cgb|pclk[*]}] \
    -group [get_clocks {SFP_refclk_P}]\
    -group [get_clocks {sys_pll_inst|sys_pll_inst|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]}] \
    -group [get_clocks {sys_pll_inst|sys_pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}] \
    -group [get_clocks {sys_pll_inst|sys_pll_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}] \
    -group [get_clocks DTS_FEMB_clk_P] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:1:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:1:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:1:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:1:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:2:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:2:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:2:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:2:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:3:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:3:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:3:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:3:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:4:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[0].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:4:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[1].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:4:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[2].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma] \
    -group [get_clocks FEMBs|FEMB_Rx_1|\refclk_group:4:COLDATA_Rx_1|coldata_rx_inst|gen_native_inst.av_xcvr_native_insts[3].gen_bonded_group_native.av_xcvr_native_inst|inst_av_pcs|ch[0].inst_av_pcs_ch|inst_av_hssi_8g_rx_pcs|wys|rcvdclkpma]
								
# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty



# tsu/th constraints

# tco constraints

# tpd constraints


#test for FEMB comm
#set_output_delay -clock { DTS_FEMB_clk_P } 0.1 [get_ports {DUNE_clk_out_P DCC_FPGA_CMD_P}] #don't do this
###
create_generated_clock -name FEMB_output_clk -source [get_ports DTS_FEMB_clk_P] [get_ports DUNE_clk_out_P]
set_output_delay -max -clock FEMB_output_clk             [expr {  5 - 0.250 }] [get_ports DCC_FPGA_CMD_P]
set_output_delay -min -clock FEMB_output_clk             [expr {  5 + 0.250 }] [get_ports DCC_FPGA_CMD_P]

###set_output_delay -max -clock FEMB_output_clk             [expr { 10 - 0.250 }] [get_ports DCC_FPGA_CMD_P]
###set_output_delay -max -clock FEMB_output_clk -clock_fall [expr { 10 - 0.250 }] [get_ports DCC_FPGA_CMD_P] -add
###set_output_delay -min -clock FEMB_output_clk              0.250                [get_ports DCC_FPGA_CMD_P]
###set_output_delay -min -clock FEMB_output_clk -clock_fall  0.250                [get_ports DCC_FPGA_CMD_P] -add
###
###set_false_path -setup -end -rise_from [get_clocks 
######



#Async reset
set_false_path -from [get_registers {*sys_rst*RST_OUT*}]

#slot and crate are constant
set_false_path -from [get_nodes {SLOT_ADDR*}]
set_false_path -from [get_nodes {CRATE_ADDR*}]

set_false_path -from {register_map:register_map_1|WIB_control.DAQ_PATH_RESET} -to {reseter:reseter_5|reset_buffer*}
set_false_path -from {register_map:register_map_1|WIB_control.DAQ_PATH_RESET} -to {reseter:reseter_4|reset_buffer*}

#sub module timing constraints
source src/EventBuilder/DAQ_LINK_EventBuilder.sdc
source src/FEMB_DAQ/FEMB_Rx.sdc
source src/FEMB_DAQ/CD_Stream_Processor.sdc
source src/FEMB_DAQ/FEMB_DAQ.sdc
source src/pacd.sdc
source src/udp_io/tx_frame.sdc
source src/timing_system/DCC.sdc
source src/SC/DQM.sdc
source src/udp_io/udp_io.sdc
source src/register_map/register_map.sdc
source src/register_map/register_map_bridge.sdc
source src/DTS/DTS.sdc
source src/pass_time_domain.sdc
source src/DTS/DTS_Convert_Generation.sdc