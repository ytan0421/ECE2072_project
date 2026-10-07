/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual components to be used in 
    the CPU.

Please enter your name and student ID:

*/
module sign_extend(in, ext);
	/* 
	 * This module sign extends the 9-bit Din to a 16-bit output.
	 */
	// TODO: Declare inputs and outputs
	input[8:0] in;
	output[15:0] ext;
	// TODO: implement logic
	assign ext[15:9] = {7{in[8]}};
	assign ext[8:0] = in;
	
endmodule



module tick_FSM(rst, clk, enable, tick);
	/* 
	 * This module implements a tick FSM that will be used to
	 * control the actions of the control unit
	 */

	// TODO: Declare inputs and outputs
	input enable;
	input rst;
	input clk;
	output reg[3:0] tick;
	
    // TODO: implement FSM
	 
	 always @(posedge clk) begin
		if (rst) begin
			tick <= 4'b0001;
		end
		
		else if (enable) begin
			case(tick)
				4'b0001: tick <= 4'b0010;
				4'b0010: tick <= 4'b0100;
				4'b0100: tick <= 4'b1000;
				4'b1000: tick <= 4'b0001;
			endcase
		end
	 end
	 
endmodule

module multiplexer(SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
	/* 
	 * This module takes 10 inputs and places the correct input onto the bus.
	 */
	// TODO: Declare inputs and outputs
	input [15:0] R0, R1, R2, R3, R4, R5, R6, R7, G;
	input [15:0] SignExtDin;
	input [3:0] sel;
	output reg[15:0] Bus;
	// TODO: implement logic
	
	always @(*) begin
		case (sel)
			4'b0000: Bus = R0;
			4'b0001: Bus = R1;
			4'b0010: Bus = R2;
			4'b0011: Bus = R3;
			4'b0100: Bus = R4;
			4'b0101: Bus = R5;
			4'b0110: Bus = R6;
			4'b0111: Bus = R7;
			4'b1000: Bus = G;
			4'b1001: Bus = SignExtDin;
			
			default: Bus = 16'b0;
		endcase
	end
	
endmodule

module ALU (input_a, input_b, alu_op, result);
	/* 
	 * This module implements the arithmetic logic unit of the processor.
	 */
	// TODO: declare inputs and outputs
	input [15:0] input_a;
	input [15:0] input_b;
	input [2:0] alu_op;
	output reg[15:0] result;
	
	reg [15:0] intermediate;

	// TODO: Implement ALU Logic:
	always @(*) begin
		case (alu_op)
			3'b000: result = input_a * input_b;
			3'b001: result = input_a + input_b;
			3'b010: result = input_a - input_b;
			3'b011: begin
				if (input_a[15] == 0) begin
					result = input_b <<< input_a;
				end
				else begin
					intermediate = (~input_a) + 1;
					result = input_b >> intermediate;
				end
			end
			default: result = 16'd0;
		endcase
	end
endmodule

module register_n(data_in, r_in, clk, Q, rst);

	// To set parameter N during instantiation, you can use:
	// register_n #(.N(num_bits)) reg_IR(.....), 
	// where num_bits is how many bits you want to set N to
	// and "..." is your usual input/output signals

	parameter N = 16;

	/* 
	 * This module implements registers that will be used in the processor.
	 */
	// TODO: Declare inputs, outputs, and parameter:
	input [N-1:0]data_in;
	input r_in;
	input clk;
	input rst;
	output reg [N-1:0] Q;
	// TODO: Implement register logic:
	always @(posedge clk) begin
		if (rst) begin
			Q <= {N{1'b0}};
		end
		else if (r_in) begin
			Q <= data_in;
		end
	end
endmodule

