vlib work
vcom ../timing_system/Convert_package.vhd
vcom ../register_map/counter.vhd
vcom ../types_package.vhd
vcom ../WIB_Constants.vhd
vcom COLDATA_package.vhd
vcom FEMB_DAQ_package.vhd
vcom COLDATA_Simulator.vhd
vsim COLDATA_Simulator

add wave -radix HEX -position insertpoint  \
    sim:/coldata_simulator/clk \
    sim:/coldata_simulator/reset_sync \
    sim:/coldata_simulator/data_out_stream1 \
    sim:/coldata_simulator/data_out_stream2 \
    sim:/coldata_simulator/convert.trigger \
    sim:/coldata_simulator/set_reserved \
    sim:/coldata_simulator/set_header \
    sim:/coldata_simulator/COLDATA_buffer \
    sim:/coldata_simulator/iCOLDATA_buffer \
    sim:/coldata_simulator/fake_data_counter \
    sim:/coldata_simulator/fake_data_bytes \
    sim:/coldata_simulator/fake_type

source sim/COLDATA.tcl
