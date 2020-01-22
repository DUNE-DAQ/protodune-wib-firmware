#reset from register clock domain is being transferred to each of the individual register clock domains.
#reseter handles this, but requires a timing constraint
set_false_path -from {reseter:reseter_1|reset_buffer[1]} -to {register_map:register_map_1|reseter:\reset_proc*reset_buffer*};

#this goes to the async reset input of a shift register clocked by 128Mhz local domain, so we can ignore the timing on this.
set_false_path -from [get_registers {register_map:register_map_1|WIB_control.DAQ_PATH_RESET}] -to [get_registers {reseter_4*reset_buffer*}]



set_false_path -from [get_registers {register_map:register_map_1|register_map_bridge:register_map_bridge_1|register_map_pass*captureA*}] -to [get_registers {register_map:register_map_1|register_map_bridge:register_map_bridge_1|register_map_pass*captureB*}]



#set_multicycle_path for FEMB clock domain register read addressses
set_multicycle_path -from [get_registers *register_map*read_address_cap\[1\]*] -setup -end 2
set_multicycle_path -from [get_registers *register_map*read_address_cap\[1\]*] -hold -end 1

#3,0,2,1,6,7