#false path for near constant channel enable
set_false_path -through [get_nets {*FEMB_EventBuilder*COLDATA_en*}]
#set_false_path -through [get_nets {*FEMB_EventBuilder*frame_valid*}]
set_false_path -through [get_nets {*COLDATA_en*}]
#set_false_path -from [get_nets {*register_map*COLDATA_en*}] -to [get_nets {*EventBuilder*FEMB_EventBuilder*}]