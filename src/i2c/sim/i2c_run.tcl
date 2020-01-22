restart -f

force -freeze sim:/i2c_reg_master/clk_sys 1 0, 0 {10000 ps} -r 20000

force -freeze sim:/i2c_reg_master/reset 1 0
run 20ns
force -freeze sim:/i2c_reg_master/reset 0 0
run 2000ns
force -freeze sim:/i2c_reg_master/I2C_Address 1000000 0
force -freeze sim:/i2c_reg_master/rw 1
force -freeze sim:/i2c_reg_master/run 1
force -freeze sim:/i2c_reg_master/reg_addr x"01"
force -freeze sim:/i2c_reg_master/byte_count 100
force -freeze sim:/i2c_reg_master/wr_data x"12345679"

run 20ns
force -freeze sim:/i2c_reg_master/run 0

#start
run 800 ns

#i2c address
run 6400 ns
force -freeze sim:/i2c_reg_master/SDA 0 0
run 800ns
noforce sim:/i2c_reg_master/SDA

# reg address
run 6400 ns
force -freeze sim:/i2c_reg_master/SDA 0 0
run 800ns
noforce sim:/i2c_reg_master/SDA

run 200us

####resetart
###run 800ns
###
#### reg address
###run 6400 ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###
###
####slave sends data
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###run 800ns
###
####slave sends data
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###run 800ns
###
####slave sends data
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###run 800ns
###
####slave sends data
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###force -freeze sim:/i2c_reg_master/SDA 1 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###run 800ns
###
###run 4000ns
###
####star write
###
###force -freeze sim:/i2c_reg_master/I2C_Address 1000000 0
###force -freeze sim:/i2c_reg_master/rw 0
###force -freeze sim:/i2c_reg_master/run 1
###force -freeze sim:/i2c_reg_master/reg_addr x"55"
###force -freeze sim:/i2c_reg_master/byte_count 100
###force -freeze sim:/i2c_reg_master/wr_data x"12345679"
###
###run 20ns
###force -freeze sim:/i2c_reg_master/run 0
###
####start
###run 800 ns
###
####i2c address
###run 6400 ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###
#### reg address
###run 6400 ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###
#### data 0
###run 6400 ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###
#### data 1
###run 6400 ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###
#### data 2
###run 6400 ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###
#### data 3
###run 6400 ns
###force -freeze sim:/i2c_reg_master/SDA 0 0
###run 800ns
###noforce sim:/i2c_reg_master/SDA
###
###run 2000ns
