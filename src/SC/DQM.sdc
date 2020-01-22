# the header info and system status signals are used to pass extra info from the DQM to the udp io module
# They are valid once the DQM starts sending data to the tx HSDP fifo and aren't used or changed until the fifo reaches its pre-defined size
# We are safe to ignore the timing on these signals since it will take many many clock ticks for this signal to reach the destination

set_false_path -from [get_registers {DQM:DQM_1|packet_out.header_user_info*}] -to [get_registers {UDP_IO:UDP_IO_2|tx_frame:tx_frame_inst|local_header_user_info*}]

set_false_path -from [get_registers {DQM:DQM_1|packet_out.system_status*}] -to [get_registers {UDP_IO:UDP_IO_2|tx_frame:tx_frame_inst|local_system_status*}]