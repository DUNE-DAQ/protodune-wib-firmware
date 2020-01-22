	Flash u0 (
		.clkin         (<connected-to-clkin>),         //         clkin.clk
		.rden          (<connected-to-rden>),          //          rden.rden
		.addr          (<connected-to-addr>),          //          addr.addr
		.reset         (<connected-to-reset>),         //         reset.reset
		.dataout       (<connected-to-dataout>),       //       dataout.dataout
		.busy          (<connected-to-busy>),          //          busy.busy
		.data_valid    (<connected-to-data_valid>),    //    data_valid.data_valid
		.write         (<connected-to-write>),         //         write.write
		.datain        (<connected-to-datain>),        //        datain.datain
		.illegal_write (<connected-to-illegal_write>), // illegal_write.illegal_write
		.wren          (<connected-to-wren>),          //          wren.wren
		.read_status   (<connected-to-read_status>),   //   read_status.read_status
		.status_out    (<connected-to-status_out>),    //    status_out.status_out
		.fast_read     (<connected-to-fast_read>),     //     fast_read.fast_read
		.bulk_erase    (<connected-to-bulk_erase>),    //    bulk_erase.bulk_erase
		.illegal_erase (<connected-to-illegal_erase>), // illegal_erase.illegal_erase
		.read_address  (<connected-to-read_address>),  //  read_address.read_address
		.shift_bytes   (<connected-to-shift_bytes>)    //   shift_bytes.shift_bytes
	);

