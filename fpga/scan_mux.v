module scan_mux(
	input wire data_i,
	input wire scan_i,
	input wire scan_enable_i, 

	output wire res_o);

assign res_o = scan_enable_i ? scan_i : data_i;
endmodule
