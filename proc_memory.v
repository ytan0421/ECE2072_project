/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement the extended version of CPU.

Please enter your student ID: 36445444


*/

module proc_memory(clk, rst, din, enable, bus, R0, R1, R2, R3, R4, R5, R6, R7, display, PC);

    // Note: The skeleton you are provided with includes output ports to output the values of the internal registers R0 - R7, for the purpose of test benching. When instantiating the processor to program your DE10-lite, you can leave these ports unused.

    // TODO: Declare inputs and outputs:
		input clk, rst;
		input enable;
		input [8:0] din;
		output reg [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
		output [15:0] bus, display;
		output reg [15:0] PC;
	
    // TODO: declare wires:
    reg R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in, A_in, G_in, IR_in, hex_in;
	 reg [2:0] alu_op;
	 reg [3:0] bus_control;
	 reg [3:0] tick;
	 reg [15:0] A_out, G_out, alu_out, next_PC;
	 reg [8:0] IR_out;

    // TODO: instantiate registers:
    register_n #(.N(16)) reg_R0(
		.data_in(bus),
		.r_in(R0_in),
		.clk(clk),
		.Q(R0),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_R1(
		.data_in(bus),
		.r_in(R1_in),
		.clk(clk),
		.Q(R1),
		.rst(rst)
		);
	
	register_n #(.N(16)) reg_R2(
		.data_in(bus),
		.r_in(R2_in),
		.clk(clk),
		.Q(R2),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_R3(
		.data_in(bus),
		.r_in(R3_in),
		.clk(clk),
		.Q(R3),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_R4(
		.data_in(bus),
		.r_in(R4_in),
		.clk(clk),
		.Q(R4),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_R5(
		.data_in(bus),
		.r_in(R5_in),
		.clk(clk),
		.Q(R5),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_R6(
		.data_in(bus),
		.r_in(R6_in),
		.clk(clk),
		.Q(R6),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_R7(
		.data_in(bus),
		.r_in(R7_in),
		.clk(clk),
		.Q(R7),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_A(
		.data_in(bus),
		.r_in(A_in),
		.clk(clk),
		.Q(A_out),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_G(
		.data_in(alu_out),
		.r_in(G_in),
		.clk(clk),
		.Q(G_out),
		.rst(rst)
		);
		
	register_n #(.N(9)) reg_IR(
		.data_in(din),
		.r_in(IR_in),
		.clk(clk),
		.Q(IR_out),
		.rst(rst)
		);
		
	register_n #(.N(16)) reg_hex(
		.data_in(bus),
		.r_in(hex_in),
		.clk(clk),
		.Q(display),
		.rst(rst)
		);
		
    // TODO: instantiate Multiplexer:
    multiplexer mul(
		.SignExtDin(din),
		.R0(R0),
		.R1(R1),
		.R2(R2),
		.R3(R3),
		.R4(R4),
		.R5(R5),
		.R6(R6),
		.R7(R7),
		.G(G_out),
		.sel(bus_control),
		.Bus(bus)
		);
    
    // TODO: instantiate ALU:
    ALU alu(
		.input_a(A_out),
		.input_b(bus),
		.alu_op(alu_op),
		.result(alu_out)
		);
    
    // TODO: instantiate tick counter:
    tick_FSM fsm(
		.rst(rst),
		.clk(clk),
		.enable(enable),
		.tick(tick)
		);
    
    // TODO: define control unit:
    always @(*) begin
        // TODO: Turn off all control signals:
			IR_in = 1'b0;
			A_in  = 1'b0;
			G_in  = 1'b0;
			hex_in = 1'b0;

			R0_in = 1'b0;
			R1_in = 1'b0;
			R2_in = 1'b0;
			R3_in = 1'b0;
			R4_in = 1'b0;
			R5_in = 1'b0;
			R6_in = 1'b0;
			R7_in = 1'b0;

			bus_control = 4'b0000;
			alu_op  = 3'b000;
			
			next_PC = PC;
			
        // TODO: Turn on specific control signals based on current tick:
        case (tick)
            4'b0001:
                begin
						  IR_in = 1'b1;
                end
            
            4'b0010:
                begin
                    case (IR_out[8:6])
						  3'b000: begin
								bus_control = {1'b0,IR_out[5:3]};
								hex_in = 1'b1;
						  end
						  3'b001: begin
								bus_control = {1'b0,IR_out[5:3]};
								A_in = 1'b1;
							end
						  3'b010: begin
								bus_control = {1'b0,IR_out[5:3]};
								A_in = 1'b1;
								next_PC = PC + 16'd1;
								end
						  3'b011: begin
								bus_control = {1'b0,IR_out[5:3]};
								A_in = 1'b1;
								end
						  3'b100: begin
								bus_control = {1'b0,IR_out[5:3]};
								A_in = 1'b1;
						  end
						  3'b101: begin
								bus_control = {1'b0,IR_out[5:3]};
								A_in = 1'b1;
								next_PC = PC + 16'd1;
							end
						  3'b110: begin
								next_PC = PC + 16'd1;
						  end
						  3'b111: begin
								next_PC = PC + 16'b1;
								end
						  endcase
                end
            
            4'b0100:
                begin
                    case (IR_out[8:6])
						  3'b000: begin
						  end
						  3'b001: begin
								bus_control = {1'b0,IR_out[2:0]};
								alu_op = 3'b001;
								G_in = 1'b1;
								end
						  3'b010: begin
								bus_control = 4'b1001;
								alu_op = 3'b001;
								G_in = 1'b1;
								end
						  3'b011: begin
								bus_control = {1'b0,IR_out[2:0]};
								alu_op = 3'b010;
								G_in = 1'b1;
								end
						  3'b100: begin
								bus_control = {1'b0,IR_out[2:0]};
								alu_op = 3'b000;
								G_in = 1'b1;
						  end
						  3'b101: begin
								bus_control = 4'b1001;
								alu_op = 3'b011;
								G_in = 1'b1;
						  end
						  3'b110: begin
								bus_control = {1'b0, IR_out[5:3]};
								if (bus == 1'b0)
									next_PC = PC + 16'd1 + ({{7{din[8]}}, din} << 1);
								else
									next_PC = PC + 16'd1;
						  end
						  3'b111: begin
								bus_control = 4'b1001;
								case (IR_out[5:3])
								3'b000:
									R0_in = 1'b1;
								3'b001:
									R1_in = 1'b1;
								3'b010:
									R2_in = 1'b1;
								3'b011:
									R3_in = 1'b1;
								3'b100:
									R4_in = 1'b1;
								3'b101:
									R5_in = 1'b1;
								3'b110:
									R6_in = 1'b1;
								3'b111:
									R7_in = 1'b1;
								endcase
						  end
							endcase
                end
            
            4'b1000:
                begin
					 case (IR_out[8:6])
					 3'b000: begin
						next_PC = PC + 16'd2;
						  end
					 3'b001: begin
						bus_control = 4'b1000;
						case (IR_out[5:3])
						3'b000:
							R0_in = 1'b1;
						3'b001:
							R1_in = 1'b1;
						3'b010:
							R2_in = 1'b1;
						3'b011:
							R3_in = 1'b1;
						3'b100:
							R4_in = 1'b1;
						3'b101:
							R5_in = 1'b1;
						3'b110:
							R6_in = 1'b1;
						3'b111:
							R7_in = 1'b1;
						endcase
						next_PC = PC + 16'd2;
					end
					3'b010: begin
						bus_control = 4'b1000;
						case (IR_out[5:3])
						3'b000:
							R0_in = 1'b1;
						3'b001:
							R1_in = 1'b1;
						3'b010:
							R2_in = 1'b1;
						3'b011:
							R3_in = 1'b1;
						3'b100:
							R4_in = 1'b1;
						3'b101:
							R5_in = 1'b1;
						3'b110:
							R6_in = 1'b1;
						3'b111:
							R7_in = 1'b1;
						endcase
						next_PC = PC + 16'd1;
					end
					3'b011: begin
						bus_control = 4'b1000;
						case (IR_out[5:3])
						3'b000:
							R0_in = 1'b1;
						3'b001:
							R1_in = 1'b1;
						3'b010:
							R2_in = 1'b1;
						3'b011:
							R3_in = 1'b1;
						3'b100:
							R4_in = 1'b1;
						3'b101:
							R5_in = 1'b1;
						3'b110:
							R6_in = 1'b1;
						3'b111:
							R7_in = 1'b1;
						endcase
						next_PC = PC + 16'd2;
					end
					3'b100: begin
						bus_control = 4'b1000;
						case (IR_out[5:3])
						3'b000:
							R0_in = 1'b1;
						3'b001:
							R1_in = 1'b1;
						3'b010:
							R2_in = 1'b1;
						3'b011:
							R3_in = 1'b1;
						3'b100:
							R4_in = 1'b1;
						3'b101:
							R5_in = 1'b1;
						3'b110:
							R6_in = 1'b1;
						3'b111:
							R7_in = 1'b1;
						endcase
						next_PC = PC + 16'd2;
					end
					3'b101: begin
						bus_control = 4'b1000;
						case (IR_out[5:3])
						3'b000:
							R0_in = 1'b1;
						3'b001:
							R1_in = 1'b1;
						3'b010:
							R2_in = 1'b1;
						3'b011:
							R3_in = 1'b1;
						3'b100:
							R4_in = 1'b1;
						3'b101:
							R5_in = 1'b1;
						3'b110:
							R6_in = 1'b1;
						3'b111:
							R7_in = 1'b1;
						endcase
						next_PC = PC + 16'd1;
					end
					3'b110: begin
					end
					3'b111: begin
						next_PC = PC + 1'd1;
					end
					endcase
				end
            
            default:
                begin
                end

        endcase
    end
	 
	 always @(posedge clk) begin
    if (rst)
        PC <= 16'd0;
    else if (enable)
        PC <= next_PC;
end

endmodule