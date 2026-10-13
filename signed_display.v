/*
 * Shows a 16-bit value in decimal on HEX4..HEX0 (active-low 7-seg, bit 7 = decimal point).
 * When SIGNED = 1 and the value is negative, its magnitude is shown and every
 * decimal point is lit to mark the number as negative (per the Task 3 footnote).
 *
 * Binary -> BCD uses the double-dabble (shift-and-add-3) algorithm instead of
 * / and %, which avoids large divider circuits and width-truncation warnings.
 */
module signed_display(value, HEX0, HEX1, HEX2, HEX3, HEX4);

	parameter SIGNED = 1;

	input  [15:0] value;
	output [7:0]  HEX0, HEX1, HEX2, HEX3, HEX4;

	wire        negative;
	wire [15:0] magnitude;
	reg  [19:0] bcd;
	integer i;

	assign negative  = (SIGNED != 0) && value[15];
	assign magnitude = negative ? (~value + 16'd1) : value;

	// Double dabble: before each shift, add 3 to any BCD digit that is 5 or more.
	always @(*) begin
		bcd = 20'd0;
		for (i = 15; i >= 0; i = i - 1) begin
			if (bcd[3:0]   >= 4'd5) bcd[3:0]   = bcd[3:0]   + 4'd3;
			if (bcd[7:4]   >= 4'd5) bcd[7:4]   = bcd[7:4]   + 4'd3;
			if (bcd[11:8]  >= 4'd5) bcd[11:8]  = bcd[11:8]  + 4'd3;
			if (bcd[15:12] >= 4'd5) bcd[15:12] = bcd[15:12] + 4'd3;
			bcd = {bcd[18:0], magnitude[i]};
		end
	end

	BCD hex0(.data(bcd[3:0]),   .X(HEX0[6:0]));
	BCD hex1(.data(bcd[7:4]),   .X(HEX1[6:0]));
	BCD hex2(.data(bcd[11:8]),  .X(HEX2[6:0]));
	BCD hex3(.data(bcd[15:12]), .X(HEX3[6:0]));
	BCD hex4(.data(bcd[19:16]), .X(HEX4[6:0]));

	// Decimal points are active-low: on (0) when the number is negative.
	assign HEX0[7] = ~negative;
	assign HEX1[7] = ~negative;
	assign HEX2[7] = ~negative;
	assign HEX3[7] = ~negative;
	assign HEX4[7] = ~negative;

endmodule
