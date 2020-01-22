

#False path between the UDP clock sync reset and the FEMB clocked FIFO writing
set_false_path -from {reseter:reseter_2|reset_buffer[1]} -to {UDP_IO:UDP_IO_2|tx_frame:tx_frame_inst|tx_packet_fifo:inst_tx_packet_fifo|dcfifo:dcfifo_component|dcfifo_o3s1:auto_generated|dffpipe_3dc:wraclr*}


#False path between the register map bridge reset onthe read cycle fifo (clk UDP) and the write side of that fifo
#this should probably be more general, but I don't know how to write the rule that would skip the UDP to UDP clock transfers
set_false_path -from {register_map:register_map_1|register_map_bridge:register_map_bridge_1|read_cycle_data_fifo_reset[0]} -to {register_map:register_map_1|register_map_bridge:register_map_bridge_1|IOREG_READ_DATA_FIFO:\read_fifos:1:IOREG_READ_DATA_FIFO_1|dcfifo:dcfifo_component|dcfifo_smo1:auto_generated|dffpipe_3dc:wraclr*}; 