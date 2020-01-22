restart -f

force -freeze sim:/dcc_si5344_control/clk_sys_50Mhz 1 0, 0 {10000 ps} -r 20000
force -freeze sim:/dcc_si5344_control/clk_DTS 1 0, 0 {10000 ps} -r 19900

force -freeze sim:/dcc_si5344_control/reset_DTS 0 0

force -freeze sim:/dcc_si5344_control/control.I2C.run 0 0
force -freeze sim:/dcc_si5344_control/control.I2C.address x"00" 0
force -freeze sim:/dcc_si5344_control/control.I2C.byte_count "000" 0
force -freeze sim:/dcc_si5344_control/control.I2C.rw 1 0
#force -freeze sim:/dcc_si5344_control/control.I2C.rd_data x"00000000" 0
force -freeze sim:/dcc_si5344_control/control.I2C.wr_data x"00000000" 0

#20*19.9 ns
run 398 ns

force -freeze sim:/dcc_si5344_control/reset_DTS 1 0
run 19.9 ns
force -freeze sim:/dcc_si5344_control/reset_DTS 0 0

run 19980.1 ns
force -freeze sim:/dcc_si5344_control/control.I2C.run 1 0
run 20ns
force -freeze sim:/dcc_si5344_control/control.I2C.run 0 0

run 400 us
force -freeze sim:/dcc_si5344_control/reset_DTS 1 0
run 25 ns
force -freeze sim:/dcc_si5344_control/reset_DTS 0 0

run 1 ms
