
set outFile "src/fw_version.vhd"
set outFile_fd [open $outFile "w"]

set unixtime [clock seconds]
set cent  [string map {" " "0"} [clock format $unixtime -format {%C}]]
set year  [string map {" " "0"} [clock format $unixtime -format {%y}]]
set month [string map {" " "0"} [clock format $unixtime -format {%m}]]
set day   [string map {" " "0"} [clock format $unixtime -format {%d}]]
set hour  [string map {" " "0"} [clock format $unixtime -format {%k}]]
set min   [string map {" " "0"} [clock format $unixtime -format {%M}]]
set sec   [string map {" " "0"} [clock format $unixtime -format {%S}]]

puts $outFile_fd "library ieee;"
puts $outFile_fd "use ieee.std_logic_1164.all;"
puts $outFile_fd "-- timestamp package"
puts $outFile_fd "package FW_TIMESTAMP is"
puts $outFile_fd "  constant TS_CENT     : std_logic_vector(7 downto 0) := x\"${cent}\";"
puts $outFile_fd "  constant TS_YEAR     : std_logic_vector(7 downto 0) := x\"${year}\";"
puts $outFile_fd "  constant TS_MONTH    : std_logic_vector(7 downto 0) := x\"${month}\";"
puts $outFile_fd "  constant TS_DAY      : std_logic_vector(7 downto 0) := x\"${day}\";"
puts $outFile_fd "  constant TS_HOUR     : std_logic_vector(7 downto 0) := x\"${hour}\";"
puts $outFile_fd "  constant TS_MIN      : std_logic_vector(7 downto 0) := x\"${min}\";"
puts $outFile_fd "  constant TS_SEC      : std_logic_vector(7 downto 0) := x\"${sec}\";"
puts $outFile_fd "end package FW_TIMESTAMP;"

close $outFile_fd
