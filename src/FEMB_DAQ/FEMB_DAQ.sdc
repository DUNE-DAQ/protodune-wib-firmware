#These are timing ignores for registers that monitor the FEMB RX transceivers.


#pll_locked
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}]  -to [get_registers {*register_map*read_data_delayed[1][2]}]

#rx_cal_busy
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][10]}]

#rx_is_lockedtoref
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][4]}]

#rx_is_lockedtodata
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][5]}]

#rx_errdetect
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][16]}]

#rx_disperr
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][17]}]

#rx_runningdisp
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][18]}]

#rx_patterndetect
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][20]}]

#rx_syncstatus
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][21]}]

#reconfig_busy
set_false_path -from [get_registers {*FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|COLDATA_RX:\refclk_group*SYNC_DATA*}] -to [get_registers {*register_map*read_data_delayed[1][9]}]