# constaint from 50Mhz domain to 128Mhz domain on convert_count_buffer and reset_count_buffer

#sys clock 50Mhz to FEMB 128Mhz
set_false_path -from [get_clocks {sys_pll_inst*[0]*divclk} -nocase] -to  [get_clocks {DCC_FEMB_PLL*divclk} -nocase]
#timing system 50Mhz to FEMB 128Mhz
set_false_path -from [get_clocks {sys_pll_inst*[0]*divclk} -nocase] -to  [get_clocks {DCC_FEMB_PLL*divclk} -nocase] 

#sys clock 50Mhz to RCE event builer 125Mhz
set_false_path -from [get_clocks {sys_pll_inst*[0]*divclk} -nocase] -to  [get_clocks {EventBuilder*} -nocase]
#timing system 50Mhz to RCE event builer 125Mhz
set_false_path -from [get_clocks {sys_pll_inst*[0]*divclk} -nocase] -to  [get_clocks {EventBuilder*} -nocase] 


