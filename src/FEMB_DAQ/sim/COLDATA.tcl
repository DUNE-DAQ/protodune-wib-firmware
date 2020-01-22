restart -f

force -freeze sim:/coldata_simulator/clk 1 0, 0 {4 ns} -r 8 ns
force -freeze sim:/coldata_simulator/control.set_header x"00000000"
force -freeze sim:/coldata_simulator/control.set_reserved x"0000"
force -freeze sim:/coldata_simulator/fake_type "00"
force -freeze sim:/coldata_simulator/reset_sync 1 
force -freeze sim:/coldata_simulator/convert.trigger 0 
run 100 ns
force -freeze sim:/coldata_simulator/reset_sync 0
run 100 ns
force -freeze sim:/coldata_simulator/convert.trigger 1
run 8 ns
force -freeze sim:/coldata_simulator/convert.trigger 0
run 512 ns
force -freeze sim:/coldata_simulator/convert.trigger 1
run 8 ns
force -freeze sim:/coldata_simulator/convert.trigger 0
run 512 ns
force -freeze sim:/coldata_simulator/convert.trigger 1
run 8 ns
force -freeze sim:/coldata_simulator/convert.trigger 0
run 512 ns

run 1us
force -freeze sim:/coldata_simulator/fake_type "10"

run 100 ns
force -freeze sim:/coldata_simulator/reset_sync 0
run 100 ns
force -freeze sim:/coldata_simulator/convert.trigger 1
run 8 ns
force -freeze sim:/coldata_simulator/convert.trigger 0
run 512 ns
force -freeze sim:/coldata_simulator/convert.trigger 1
run 8 ns
force -freeze sim:/coldata_simulator/convert.trigger 0
run 512 ns
force -freeze sim:/coldata_simulator/convert.trigger 1
run 8 ns
force -freeze sim:/coldata_simulator/convert.trigger 0
run 512 ns

