#We need to synchronize the "locked" signals from other clock domains to the register map's
#This is done with a ff buffer in the register map's domain, but we add a false path to that for the clock domain shift
#set_false_path -to [get_registers {*register_map_bridge*clk_domain_enabled_buf*}]