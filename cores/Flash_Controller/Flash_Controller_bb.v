
module Flash_Controller (
	addr,
	asmi_dataoe,
	asmi_dataout,
	asmi_dclk,
	asmi_scein,
	asmi_sdoin,
	bulk_erase,
	busy,
	clkin,
	data_valid,
	datain,
	dataout,
	fast_read,
	illegal_erase,
	illegal_write,
	rden,
	read_address,
	read_status,
	reset,
	shift_bytes,
	status_out,
	wren,
	write);	

	input	[23:0]	addr;
	output	[3:0]	asmi_dataoe;
	input	[3:0]	asmi_dataout;
	output		asmi_dclk;
	output		asmi_scein;
	output	[3:0]	asmi_sdoin;
	input		bulk_erase;
	output		busy;
	input		clkin;
	output		data_valid;
	input	[7:0]	datain;
	output	[7:0]	dataout;
	input		fast_read;
	output		illegal_erase;
	output		illegal_write;
	input		rden;
	output	[23:0]	read_address;
	input		read_status;
	input		reset;
	input		shift_bytes;
	output	[7:0]	status_out;
	input		wren;
	input		write;
endmodule
