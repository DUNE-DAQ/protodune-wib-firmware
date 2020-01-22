restart -f

force -freeze sim:/dts_convert_generation/clk_DUNE 1 0, 0 {10000 ps} -r 20000
force -freeze sim:/dts_convert_generation/clk_EB 1 0, 0 {31250 ps} -r 62500
force -freeze sim:/dts_convert_generation/clk_FEMB_128Mhz 1 0, 0 {3906.25 ps} -r 7812.5

force -freeze sim:/dts_convert_generation/pdts_timestamp x"0000000012345678" 0
force -freeze sim:/dts_convert_generation/pdts_event_counter x"00000000" 0
force -freeze sim:/dts_convert_generation/pdts_cmd_valid 0 0
force -freeze sim:/dts_convert_generation/pdts_cmd x"4" 0

force -freeze sim:/dts_convert_generation/control.converts_enabled 0 0
force -freeze sim:/dts_convert_generation/control.use_local_timestamp 0 0
force -freeze sim:/dts_convert_generation/FAKE_DTS 1 0
force -freeze sim:/dts_convert_generation/control.halt 0 0
force -freeze sim:/dts_convert_generation/control.start_sync 0 0
force -freeze sim:/dts_convert_generation/control.sync_counter_period x"00000640" 0

run 100ns

force -freeze sim:/dts_convert_generation/control.start_sync 1 0
run 20ns
force -freeze sim:/dts_convert_generation/control.start_sync 0 0

run 100ns

force -freeze sim:/dts_convert_generation/pdts_cmd_valid 1 0
force -freeze sim:/dts_convert_generation/pdts_cmd x"5" 0
run 20ns
force -freeze sim:/dts_convert_generation/pdts_cmd_valid 0 0
force -freeze sim:/dts_convert_generation/pdts_cmd x"4" 0
force -freeze sim:/dts_convert_generation/pdts_timestamp x"0000000100000000" 0

run  32 us

force -freeze sim:/dts_convert_generation/pdts_cmd_valid 1 0, 0 {20 ps} -r 32000000
force -freeze sim:/dts_convert_generation/pdts_timestamp x"0000000200000000" 0
run  16 us

force -freeze sim:/dts_convert_generation/pdts_timestamp x"0000000300000000" 0
run  32 us

force -freeze sim:/dts_convert_generation/pdts_timestamp x"0000000400000000" 0
run  32 us

run 16 us
noforce sim:/dts_convert_generation/pdts_cmd_valid
force -freeze sim:/dts_convert_generation/pdts_cmd_valid 1 0
run 20ns
force -freeze sim:/dts_convert_generation/pdts_cmd_valid 0 0

run 31990ns



