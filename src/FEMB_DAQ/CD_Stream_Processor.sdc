#timing system passing has been taken care of with latching of values and delay of capture signal
#set_false_path -from [get_registers {*CD_Stream_Processor_1|stream_timestamp*}] -to [get_registers {*CD_Stream_Processor_1|CD_to_EB_stream.CD_timestamp*}]

#data errors to capture errors timing
#set_false_path -from [get_registers {*CD_Stream_Processor*data_errors*}] -to [get_registers {*CD_Stream_Processor*capture_errors*}]
#set_false_path -from [get_registers {*CD_Stream_Processor*stream_errors*}] -to [get_registers {*CD_Stream_Processor*CD_errors*}]

#ignore timing between RD/WR_page and capture/readout_domain_RD/WR_page_copy since they are synchronized by a domain crossing safe signal
#set_false_path -from [get_registers {*CD_Stream_Processor*_page*}] -to [get_registers {*D_Stream_Processor*_domain_*_page_copy*}]

#ignore use of synchronous reset in one clock domain in another clock domain as async reset (FEMB clk)
set_false_path -from [get_registers {reseter_4*reset_buffer*}] -to [get_registers {*CD_Stream_Processor*reseter*reset_buffer*}]

#ignore use of synchronous reset in one clock domain in another clock domain as async reset (EVB clk)
set_false_path -from [get_registers {reseter_5*reset_buffer*}] -to [get_registers {*CD_Stream_Processor*reseter*reset_buffer*}]

#reset of coldata side to ev side of fifo readout
set_false_path -from [get_registers {reseter_4*reset_buffer*}] -to [get_registers {*CD_Stream_Processor*CD_*FIFO*}]