/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual the CPU.

Please enter your student ID:

*/
module simple_proc(clk, rst, din, bus, R0, R1, R2, R3, R4, R5, R6, R7);

    // Note: The skeleton you are provided with includes output ports to output the values of the internal registers R0 - R7, for the purpose of test benching. When instantiating the processor to program your DE10-lite, you can leave these ports unused.

    // TODO: Declare inputs and outputs:
	 input clk, rst;
	 input [8:0] din;
	 output [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
	 output [15:0] bus;

    // TODO: declare wires:
    wire [15:0] SignExtDin, A, G, result;
	 reg [3:0] sel;
	 reg [2:0] alu_op;
	 
	 reg A_in, G_in, ir_in;
	 reg R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in;
	 wire enable;
	 wire [3:0] tick;
	 wire [8:0] instruction;
	 
	 wire [8:6] opcode, add, addi, sub, movi;
	 wire [5:3] Rx;
	 wire [2:0] Ry;
	 
	 assign enable = 1'b1;
	 
	 assign opcode = instruction[8:6];
	 assign Rx = instruction[5:3];
	 assign Ry = instruction[2:0];
	 
	 assign add = 3'b001;
	 assign addi = 3'b010;
	 assign sub = 3'b011;
	 assign movi = 3'b111;
	 
	 sign_extend sign_extension(
		.in(din),
		.ext(SignExtDin)
	 );
	 
    // TODO: instantiate registers:
    register_n register_a(
		.data_in(bus),
		.r_in(A_in),
		.clk(clk),
		.Q(A),
		.rst(rst)
	 );
	 
	 register_n register_g(
		.data_in(result),
		.r_in(G_in),
		.clk(clk),
		.Q(G),
		.rst(rst)
	 );
	 
	 register_n #(.N(9)) instruction_register(
		.data_in(din),
		.r_in(ir_in),
		.clk(clk),
		.Q(instruction),
		.rst(rst)
	 );
	 
	 register_n reg_R0(.data_in(bus), .r_in(R0_in), .clk(clk), .Q(R0), .rst(rst));
	 
	 register_n reg_R1(.data_in(bus), .r_in(R1_in), .clk(clk), .Q(R1), .rst(rst));
	 
	 register_n reg_R2(.data_in(bus), .r_in(R2_in), .clk(clk), .Q(R2), .rst(rst));
	 
	 register_n reg_R3(.data_in(bus), .r_in(R3_in), .clk(clk), .Q(R3), .rst(rst));
	 
	 register_n reg_R4(.data_in(bus), .r_in(R4_in), .clk(clk), .Q(R4), .rst(rst));
	 
	 register_n reg_R5(.data_in(bus), .r_in(R5_in), .clk(clk), .Q(R5), .rst(rst));
	 
	 register_n reg_R6(.data_in(bus), .r_in(R6_in), .clk(clk), .Q(R6), .rst(rst));
	 
	 register_n reg_R7(.data_in(bus), .r_in(R7_in), .clk(clk), .Q(R7), .rst(rst));
	 
	 
    
    // TODO: instantiate Multiplexer:
    multiplexer mux(
		.SignExtDin(SignExtDin),
		.R0(R0),
		.R1(R1),
		.R2(R2),
		.R3(R3),
		.R4(R4),
		.R5(R5),
		.R6(R6),
		.R7(R7),
		.G(G),
		.sel(sel),
		.Bus(bus)
	 );
    
    // TODO: instantiate ALU:
    ALU alu(
		.input_a(A),
		.input_b(bus),
		.alu_op(alu_op),
		.result(result)
	 );
    
    // TODO: instantiate tick counter:
    tick_FSM tick_fsm(
		.enable(enable),
		.rst(rst),
		.clk(clk),
		.tick(tick)
	 );
    
    // TODO: define control unit:
    always @(*) begin
        // TODO: Turn off all control signals:
		  A_in = 0;
		  G_in = 0;
		  ir_in = 0;
		  
		  R0_in = 0;
		  R1_in = 0;
		  R2_in = 0;
		  R3_in = 0;
		  R4_in = 0;
		  R5_in = 0;
		  R6_in = 0;
		  R7_in = 0;
		  
		  sel = 4'b0000;
		  alu_op = 3'b000;

        // TODO: Turn on specific control signals based on current tick:
        case (tick)
            4'b0001:
                begin
                    // TODO
						  ir_in = 1;
                end
            
            4'b0010:
                begin
                    // TODO
						  if ((opcode == add) || (opcode == sub)) begin
								sel = {1'b0, Rx};
								A_in = 1;
						  end
						  else if (opcode == addi) begin
								sel = 4'b1001;
								A_in = 1;
						  end
						  else if (opcode == movi) begin
								sel = 4'b1001;
								case (Rx)
									3'b000: R0_in = 1;
									3'b001: R1_in = 1;
									3'b010: R2_in = 1;
									3'b011: R3_in = 1;
									3'b100: R4_in = 1;
									3'b101: R5_in = 1;
									3'b110: R6_in = 1;
									3'b111: R7_in = 1;
								endcase
						  end
                end 
            
            4'b0100:
                begin
                    // TODO
						  if (opcode == add) begin
								sel = {1'b0, Ry};
								alu_op = 3'b001;
								G_in = 1;
						  end
						  else if (opcode == addi) begin
								sel = {1'b0, Rx};
								alu_op = 3'b001;
								G_in = 1;
						  end
						  else if (opcode == sub) begin
								sel = {1'b0, Ry};
								alu_op = 3'b010;
								G_in = 1;
						  end
                end
            
            4'b1000:
                begin
                    // TODO
						  if ((opcode == add)|| (opcode == addi) || (opcode == sub)) begin
								sel = 4'b1000;
								case (Rx)
									3'b000: R0_in = 1;
									3'b001: R1_in = 1;
									3'b010: R2_in = 1;
									3'b011: R3_in = 1;
									3'b100: R4_in = 1;
									3'b101: R5_in = 1;
									3'b110: R6_in = 1;
									3'b111: R7_in = 1;
								endcase
						  end
						  
                end
            
            default:
                begin
                    // TODO
                end

        endcase

    end

endmodule