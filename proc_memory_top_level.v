// Task 4 top level (DE10-Lite). Matches Figure 11.
module proc_memory_top_level(
	input        MAX10_CLK1_50,   // 50 MHz board clock
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

wire        clk_10hz;
wire [15:0] bus;
wire [15:0] display;
wire [15:0] PC;
wire [8:0]  din;
wire [3:0]  tick;

// Processor clock: 50 MHz -> 10 Hz (as in Lab 4).
clock_divider #(.OUT_HZ(10)) div(
	.clk_in(MAX10_CLK1_50),
	.clk_out(clk_10hz)
	);

// Two-flip-flop synchronisers for the asynchronous button/switch (style guide item 8).
reg rst_ff1, rst_sync, en_ff1, en_sync;
always @(posedge clk_10hz) begin
	rst_ff1  <= ~KEY[0];
	rst_sync <= rst_ff1;
	en_ff1   <= SW[9];
	en_sync  <= en_ff1;
end

instr_rom memory(
	.address(PC),
	.clock(MAX10_CLK1_50), 
	.q(din)
	);

proc_memory my_proc(
	.clk(clk_10hz),
	.rst(rst_sync),
	.enable(en_sync),
	.din(din),
	.bus(bus),
	.display(display),
	.PC(PC),
	.tick(tick)
	);

assign LEDR = bus[9:0];

signed_display #(.SIGNED(0)) disp(
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
