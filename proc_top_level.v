module proc_top_level(
	input [8:0] SW,
	input [1:0] KEY,
	output [9:0] LEDR,
	output [6:0] HEX5,
	output [3:0] tick_FSM
	);

wire [15:0] bus;
wire enable;
assign enable = 1'b1;
	
proc_extension my_proc(
	.din(SW),
	.rst(~KEY[0]),
	.clk(~KEY[1]),
	.bus(bus)
	);
	
tick_FSM my_FSM(
	.rst(~KEY[0]),
	.clk(~KEY[1]),
	.enable(enable),
	.tick(tick_FSM)
	);
	
assign LEDR = bus[9:0];
	
BCD_HEX5 hex5(
	.tick(tick_FSM),
	.X(HEX5)
	);

endmodule