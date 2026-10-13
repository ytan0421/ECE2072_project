// Converts the one-hot tick (0001/0010/0100/1000) to 1/2/3/4 and shows it on a 7-seg.
module BCD_HEX5 (
    input  [3:0] tick,
    output [6:0] X
);

reg [3:0] data;

always @(*) begin
	case (tick)
		4'b0001: data = 4'd1;
		4'b0010: data = 4'd2;
		4'b0100: data = 4'd3;
		4'b1000: data = 4'd4;
		default: data = 4'd0;   // invalid one-hot state shows 0 (also prevents a latch)
	endcase
end

BCD seg(
	.data(data),
	.X(X)
	);

endmodule
