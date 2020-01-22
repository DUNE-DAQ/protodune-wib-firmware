#set false path between raw link clock domain latched rate count and its crossing over to the 128Mhz clock domain's register_map register.   This is latched on the read side by a pulse that correctly can cross the clock domain boundary and will be stable by the time the read side reads.

set_false_path -from [get_registers {FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1*timed_counter_1|timed_count[*]}] -to [get_registers {FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|monitor*.raw_sof_rate*}]

#Using the DAQ path reset signal to async reset via the reseters in FEMB_Rx.
set_false_path -from {reseter:reseter_4|reset_buffer[4]} -to {FEMB_DAQ:FEMBs|FEMB_Rx:FEMB_Rx_1|*reseter_1|reset_buffer[*]}