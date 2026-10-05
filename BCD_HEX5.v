module BCD_HEX5 (
    input [3:0] tick,
    output [6:0] X,
);

reg [3:0] data

always @(*) begin
	case (tick)
	4'b0001:
		data = 4'b0001;
	4'b0010:
		data = 4'b0010;
	4'b0100:
		data = 4'b0011;
	4'b1000:
		data = 4'b0100;
	endcase
end

assign X[0] = ~((~data[3] & ~data[2] & ~data[0]) | (data[3] & ~data[2] & ~data[1]) | (~data[3] & data[2] & data[0]) | (~data[3] & data[1]));

assign X[1] = ~((~data[3] & ~data[2]) | (~data[3] & ~data[1] & ~data[0]) | (~data[3] & data[1] & data[0]) | (~data[2] & ~data[1]));

assign X[2] = ~((~data[2] & ~data[1]) | (~data[3] & data[0]) | (~data[3] & data[2]));

assign X[3] = ~((data[3] & ~data[2] & ~data[1]) | (~data[3] & data[2] & ~data[1] & data[0]) | (~data[3] & ~data[2] & ~data[0]) | (~data[3] & ~data[2] & data[1]) | (~data[3] & data[1] & ~data[0]));

assign X[4] = ~((~data[2] & ~data[1] & ~data[0]) | (~data[3] & data[1] & ~data[0]));

assign X[5] = ~((data[3] & ~data[2] & ~data[1]) | (~data[3] & data[2] & ~data[1]) | (~data[3] & data[2] & ~data[0]) | (~data[3] & ~data[1] & ~data[0]));

assign X[6] = ~((data[3] & ~data[2] & ~data[1]) | (~data[3] & data[2] & ~data[1]) | (~data[3] & ~data[2] & data[1]) | (~data[3] & data[1] & ~data[0]));

endmodule
