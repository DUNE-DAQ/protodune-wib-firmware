vlib work

vcom ../I2C_reg_master.vhd

#vsim I2C_reg_master -gIGNORE_ACK=0
vsim I2C_reg_master -gIGNORE_ACK=0 -gUSE_RESTART_FOR_READ_SEQUENCE=0

add wave -radix HEX -position insertpoint  \
    sim:/i2c_reg_master/clk_sys \
    sim:/i2c_reg_master/reset \
    sim:/i2c_reg_master/SDA \
    sim:/i2c_reg_master/SCLK

add wave -radix HEX -position insertpoint  \
    sim:/i2c_reg_master/I2C_Address \
    sim:/i2c_reg_master/rw \
    sim:/i2c_reg_master/run \
    sim:/i2c_reg_master/reg_addr \
    sim:/i2c_reg_master/byte_count \
    sim:/i2c_reg_master/rd_data \
    sim:/i2c_reg_master/wr_data 



    
add wave -radix HEX -position insertpoint  \
    sim:/i2c_reg_master/i2c_addr \
    sim:/i2c_reg_master/transfer_direction \
    sim:/i2c_reg_master/transaction_length \
    sim:/i2c_reg_master/state \
    sim:/i2c_reg_master/stop_start_counter \
    sim:/i2c_reg_master/enable_clock \
    sim:/i2c_reg_master/i2c_counter \
    sim:/i2c_reg_master/bit_sequence \
    sim:/i2c_reg_master/addr \
    sim:/i2c_reg_master/ack \
    sim:/i2c_reg_master/error \
    sim:/i2c_reg_master/done \
    sim:/i2c_reg_master/data 


source i2c_run.tcl
