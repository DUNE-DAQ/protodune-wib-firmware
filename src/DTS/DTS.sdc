#create_clock -period 4 -name DTS_data_virt_clk

#set_false_path -from [get_registers {*control.buffered_loopback}] -to [get_ports {DTS_FP_CLK_OUT}]
#set false_path -from [get_registers {*control.buffered_loopback}] -to [get_registers {*buffered_data_out_delay[0]}]

set_false_path -from [get_registers {*pdts_synchro:*|da*}] -to [get_registers {*pdts_synchro:*|db*}] 

#set_input_delay -clock { DTS_data_virt_clk } -max  0.0 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_virt_clk } -min -0.0 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_virt_clk } -max  0.84 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_virt_clk } -min -0.84 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_virt_clk } -max  2 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_virt_clk } -min -1.5 [get_ports {DTS_data_P}]



#test
#set_input_delay -clock { DTS_data_clk_P } -max  0.84 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_clk_P } -min -0.84 [get_ports {DTS_data_P}]

#try1
#set_input_delay -clock { DTS_data_clk_P } -max 0 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_clk_P } -min -0 [get_ports {DTS_data_P}]
#try2
#set_input_delay -clock { DTS_data_clk_P } -max 2 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_clk_P } -min -2 [get_ports {DTS_data_P}]
#try3
#set_input_delay -clock { DTS_data_clk_P } -max 0.84 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_clk_P } -min -0.84 [get_ports {DTS_data_P}]
#try4
#set_input_delay -clock { DTS_data_clk_P } -max -0.84 [get_ports {DTS_data_P}]
#set_input_delay -clock { DTS_data_clk_P } -min -0.84 [get_ports {DTS_data_P}]








set_false_path -from {register_map:register_map_1|DTS_control.DTS_Convert.use_local_timestamp} -to {DTS:DTS_1|DTS_Convert_Generation:DTS_Convert_Generation_1|convert_EB.time_stamp*}

set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[0]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:0:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[1]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:1:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[2]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:2:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[3]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:3:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[4]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:4:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[5]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:5:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[6]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:6:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[7]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:7:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[8]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:8:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[9]}  -to {DTS:DTS_1|counter:\pdts_cmd_counts:9:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[10]} -to {DTS:DTS_1|counter:\pdts_cmd_counts:10:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[11]} -to {DTS:DTS_1|counter:\pdts_cmd_counts:11:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[12]} -to {DTS:DTS_1|counter:\pdts_cmd_counts:12:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[13]} -to {DTS:DTS_1|counter:\pdts_cmd_counts:13:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[14]} -to {DTS:DTS_1|counter:\pdts_cmd_counts:14:counter_1|*}
set_false_path -from {register_map:register_map_1|DTS_control.PDTS.CMD_count_reset[15]} -to {DTS:DTS_1|counter:\pdts_cmd_counts:15:counter_1|*}