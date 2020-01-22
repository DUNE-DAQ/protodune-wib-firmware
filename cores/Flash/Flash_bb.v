
module Flash (
	clkin,
	rden,
	addr,
	reset,
	dataout,
	busy,
	data_valid,
	write,
	datain,
	illegal_write,
	wren,
	read_status,
	status_out,
	fast_read,
	bulk_erase,
	illegal_erase,
	read_address,
	shift_bytes);	

	input		clkin;
	input		rden;
	input	[23:0]	addr;
	input		reset;
	output	[7:0]	dataout;
	output		busy;
	output		data_valid;
	input		write;
	input	[7:0]	datain;
	output		illegal_write;
	input		wren;
	input		read_status;
	output	[7:0]	status_out;
	input		fast_read;
	input		bulk_erase;
	output		illegal_erase;
	output	[23:0]	read_address;
	input		shift_bytes;
endmodule
