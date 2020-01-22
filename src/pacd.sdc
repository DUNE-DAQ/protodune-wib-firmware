#remove timing from the part of pacd that crosses the clock domain barrier. 
set_false_path -from [get_registers {*pacd*t}] -to [get_registers {*pacd*d[*}]