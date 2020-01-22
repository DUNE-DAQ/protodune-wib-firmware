set_false_path -from {register_map:register_map_1|DTS_control.DTS_Convert.use_local_timestamp} -to {DTS:DTS_1|DTS_Convert_Generation:DTS_Convert_Generation_1|use_local_timestamp}

set_false_path -from {register_map:register_map_1|DTS_control.DTS_Convert.DAQ_timestamps_before_sync[*]} -to {DTS:DTS_1|DTS_Convert_Generation:DTS_Convert_Generation_1|DAQ_timestamps_before_sync[*]}

set_false_path -from {DTS:DTS_1|DTS_Convert_Generation:DTS_Convert_Generation_1|convert_state.*} -to {DTS:DTS_1|DTS_Convert_Generation:DTS_Convert_Generation_1|convert_state_buffer.*}