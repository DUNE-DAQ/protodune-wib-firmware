
module RemoteReload (
	busy,
	clock,
	data_out,
	param,
	read_param,
	reconfig,
	reset,
	reset_timer,
	write_param,
	data_in);	

	output		busy;
	input		clock;
	output	[23:0]	data_out;
	input	[2:0]	param;
	input		read_param;
	input		reconfig;
	input		reset;
	input		reset_timer;
	input		write_param;
	input	[23:0]	data_in;
endmodule
