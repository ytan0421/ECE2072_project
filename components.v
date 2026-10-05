/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual components to be used in 
    the CPU.

Please enter your name and student ID: 36445444

*/
module sign_extend(in, ext);
	/* 
	 * This module sign extends the 9-bit Din to a 16-bit output.
	 */
	 
	// TODO: Declare inputs and outputs
		input [8:0] in;
		output [15:0] ext;
		
	// TODO: implement logic
	assign ext = {{7{in[8]}}, in};
		
endmodule



module tick_FSM(rst, clk, enable, tick);
	/* 
	 * This module implements a tick FSM that will be used to
	 * control the actions of the control unit
	 */

	// TODO: Declare inputs and outputs
	input rst, clk, enable;
	output reg [3:0] tick;
	
	reg [3:0] next_tick;
	parameter A = 4'b0001, B = 4'b0010, C = 4'b0100, D = 4'b1000; 
	
    // TODO: implement FSM
	always @(*) begin
		case (tick)
			A:
				if (enable)
					next_tick = B;
				else 
					next_tick = A;
			B:
				if (enable)
					next_tick = C;
				else 
					next_tick = B;
			C:
				if (enable)
					next_tick = D;
				else 
					next_tick = C;
			D:
				if (enable)
					next_tick = A;
				else 
					next_tick = D;
		default:
			next_tick = A;
		endcase
	end
		
	always @(posedge clk) begin
		if (rst)
			tick <= A;
		else
			tick <= next_tick;
	 end
	 
endmodule

module multiplexer(SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
	/* 
	 * This module takes 10 inputs and places the correct input onto the bus.
	 */
	// TODO: Declare inputs and outputs
	input [15:0] R0, R1, R2, R3, R4, R5, R6, R7, G;
	input [8:0] SignExtDin;
	input [3:0] sel;
	output reg [15:0] Bus;
	
	// TODO: implement logic
	always @(*) begin
		case (sel)
			4'b0000:
				Bus = R0;
			4'b0001:
				Bus = R1;
			4'b0010:
				Bus = R2;
			4'b0011:
				Bus = R3;
			4'b0100:
				Bus = R4;
			4'b0101:
				Bus = R5;
			4'b0110:
				Bus = R6;
			4'b0111:
				Bus = R7;
			4'b1000:
				Bus = G;
			4'b1001:
				Bus = {{7{SignExtDin[8]}},SignExtDin};
			default:
				Bus = 16'b0;
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
	output reg [15:0] result;

	// TODO: Implement ALU Logic:
	always @(*) begin
		case (alu_op)
			3'b000:
				result = input_a * input_b;
			3'b001:
				result = input_a + input_b;
			3'b010:
				result = input_a - input_b;
			3'b011:
				if ($signed(input_a) >= 0)
					result = input_b << $signed(input_a);
				else
					result = $signed(input_b) >>> (-$signed(input_a));
				default:
					result = 16'b0;
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
	input [N-1:0] data_in;
	input r_in, clk, rst;
	output reg [N-1:0] Q;
	
	// TODO: Implement register logic:
		always @(posedge clk) begin
			if (rst)
				Q <= {N{1'b0}};
			else if (r_in)
				Q <= data_in;
		end
			
endmodule

