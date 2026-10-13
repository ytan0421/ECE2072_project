/*
 * Divides the 50 MHz board clock (MAX10_CLK1_50) down to OUT_HZ (default 10 Hz).
 * The output toggles every IN_HZ / (2 * OUT_HZ) input cycles.
 */
module clock_divider(clk_in, clk_out);

	parameter IN_HZ  = 50_000_000;
	parameter OUT_HZ = 10;
	parameter HALF_PERIOD = IN_HZ / (2 * OUT_HZ);   // 2,500,000 for 10 Hz

	input      clk_in;
	output reg clk_out;

	reg [24:0] count;

	initial begin
		count   = 25'd0;
		clk_out = 1'b0;
	end

	always @(posedge clk_in) begin
		if (count == HALF_PERIOD - 1) begin
			count   <= 25'd0;
			clk_out <= ~clk_out;
		end
		else begin
			count <= count + 25'd1;
		end
	end

endmodule
