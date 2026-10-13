// Task 2 top level (DE10-Lite). Matches Figure 7.
module simple_proc_top_level(
	input  [8:0] SW,
	input  [1:0] KEY,
	output [9:0] LEDR,
	output [6:0] HEX5
	);

wire [15:0] bus;
wire [3:0]  tick;

simple_proc my_proc(
	.clk(~KEY[1]),
	.rst(~KEY[0]),
	.enable(1'b1),        // processor permanently ON for Task 2
	.din(SW[8:0]),
	.bus(bus),
	.tick(tick)
	);

assign LEDR = bus[9:0];

BCD_HEX5 hex5(
	.tick(tick),
	.X(HEX5)
	);

endmodule
