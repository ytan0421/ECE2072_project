module proc_extension_top_level(
	input [9:0] SW,
	input [1:0] KEY,
	
	output [9:0] LEDR,
	
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	
	output [3:0] tick_FSM
	);

wire [15:0] bus,display;
wire [3:0] digit0, digit1, digit2, digit3, digit4;

assign digit4 = display / 10000;
assign digit3 = (display % 10000) / 1000;
assign digit2 = (display % 1000) / 100;
assign digit1 = (display % 100) / 10;
assign digit0 = display % 10;

proc_extension my_proc(
	.din(SW[8:0]),
	.rst(~KEY[0]),
	.clk(~KEY[1]),
	.bus(bus),
	.display(display)
	);
	
assign LEDR = bus[9:0];
	
tick_FSM my_FSM(
	.rst(~KEY[0]),
	.clk(~KEY[1]),
	.enable(SW[9]),
	.tick(tick_FSM)
	);
	
	BCD hex0 (
	.data(digit0),
	.X(HEX0)
	);
	
	BCD hex1 (
	.data(digit1),
	.X(HEX1)
	);
	
	BCD hex2 (
	.data(digit2),
	.X(HEX2)
	);
	
	BCD hex3 (
	.data(digit3),
	.X(HEX3)
	);
	
	
	BCD hex4 (
	.data(digit4),
	.X(HEX4)
	);


BCD_HEX5 hex5(
	.tick(tick_FSM),
	.X(HEX5)
	);

endmodule