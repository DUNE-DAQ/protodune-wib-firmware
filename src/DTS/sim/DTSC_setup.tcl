vlib work

vcom ../../../cores/CONVERT_FIFO.vhd
vcom ../../types_package.vhd
vcom ../Convert_package.vhd
vcom ../DTS_package.vhd
vcom ../DTS_Convert_Generation.vhd


vsim DTS_Convert_Generation

add wave -radix HEX -position insertpoint  \
    sim:/dts_convert_generation/clk_FEMB_128Mhz \
    sim:/dts_convert_generation/clk_EB \
    sim:/dts_convert_generation/clk_DUNE \
    sim:/dts_convert_generation/pdts_timestamp \
    sim:/dts_convert_generation/pdts_event_counter \
    sim:/dts_convert_generation/pdts_cmd_valid \
    sim:/dts_convert_generation/pdts_cmd \

add wave -radix HEX -position insertpoint  \
    sim:/dts_convert_generation/control.converts_enabled \
    sim:/dts_convert_generation/control.use_local_timestamp \
    sim:/dts_convert_generation/FAKE_DTS \
    sim:/dts_convert_generation/control.halt \
    sim:/dts_convert_generation/control.start_sync \
    sim:/dts_convert_generation/control.sync_counter_period \

add wave -radix HEX -position insertpoint  \
    sim:/dts_convert_generation/out_of_sync \
    sim:/dts_convert_generation/missed_periodic_syncs \
    sim:/dts_convert_generation/last_good_sync \
    sim:/dts_convert_generation/expect_sync_counter \
    sim:/dts_convert_generation/converts_enabled \
    sim:/dts_convert_generation/convert_state \
    sim:/dts_convert_generation/convert_pulse_generator \
    sim:/dts_convert_generation/convert_fifo_wr \
    sim:/dts_convert_generation/convert_DUNE_bits \
    sim:/dts_convert_generation/convert_DUNE \

source DTSC_run.tcl
