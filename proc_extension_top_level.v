// Task 3 top level (DE10-Lite). Matches Figure 9.
module proc_extension_top_level(
	input  [9:0] SW,
	input  [1:0] KEY,
	output [9:0] LEDR,
	output [7:0] HEX0,
	output [7:0] HEX1,
	output [7:0] HEX2,
	output [7:0] HEX3,
	output [7:0] HEX4,
	output [6:0] HEX5
	);

wire [15:0] bus;
wire [15:0] display;
wire [3:0]  tick;

proc_extension my_proc(
	.clk(~KEY[1]),
	.rst(~KEY[0]),
	.enable(SW[9]),
	.din(SW[8:0]),
	.bus(bus),
	.display(display),
	.tick(tick)
	);

assign LEDR = bus[9:0];

// Signed 16-bit decimal on HEX4..HEX0, decimal points lit when negative.
signed_display #(.SIGNED(1)) disp(
	.value(display),
	.HEX0(HEX0),
	.HEX1(HEX1),
	.HEX2(HEX2),
	.HEX3(HEX3),
	.HEX4(HEX4)
	);

BCD_HEX5 hex5(
	.tick(tick),
	.X(HEX5)
	);

endmodule
