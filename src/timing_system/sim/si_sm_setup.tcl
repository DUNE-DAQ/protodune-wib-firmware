vlib work

vcom ../../i2c/I2C_reg_master.vhd
vcom ../../pacd.vhd
vcom ../../types_package.vhd
vcom ../../WIB_Constants.vhd
vcom ../../FEMB_DAQ/COLDATA_package.vhd
vcom ../DCC_package.vhd
vcom ../DCC_SI5344_Control.vhd


vsim DCC_SI5344_Control

add wave -radix HEX -position insertpoint  \
    sim:/dcc_si5344_control/clk_sys_50Mhz \
    sim:/dcc_si5344_control/clk_DTS \
    sim:/dcc_si5344_control/SI5344_OE_N \
    sim:/dcc_si5344_control/reset_DTS \
    sim:/dcc_si5344_control/control.I2C.run \
    sim:/dcc_si5344_control/control.I2C.address \
    sim:/dcc_si5344_control/control.I2C.byte_count \
    sim:/dcc_si5344_control/control.I2C.rw \
    sim:/dcc_si5344_control/monitor.I2C.rd_data \
    sim:/dcc_si5344_control/control.I2C.wr_data\
    sim:/dcc_si5344_control/monitor.I2C.done\
    sim:/dcc_si5344_control/monitor.I2C.error\
    




add wave -radix HEX -position insertpoint  \
    sim:/dcc_si5344_control/state \
    sim:/dcc_si5344_control/reset_request_pulse \
    sim:/dcc_si5344_control/queued_reset_request \
    sim:/dcc_si5344_control/queued_user_request \
    sim:/dcc_si5344_control/I2C_run \
    sim:/dcc_si5344_control/I2C_done \
    sim:/dcc_si5344_control/I2C_reg_addr \
    sim:/dcc_si5344_control/I2C_byte_count \
    sim:/dcc_si5344_control/I2C_rw \
    sim:/dcc_si5344_control/I2C_rd_data \
    sim:/dcc_si5344_control/I2C_wr_data \



source si_sm_run.tcl
