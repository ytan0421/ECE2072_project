`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the individual 
    components used in the processor.

Please enter your student ID:

*/
module components_tb;
    // TODO: Implement the logic of your testbench here
	 
	 // sign extender task
	 reg [8:0] in;
	 wire [15:0] ext;
	 integer signext_tests = 0, signext_errors = 0;
	 
	 sign_extend sign_extend_test(
		.in(in),
		.ext(ext)
	 );
	 
	 task check_sign_extend;
    reg [15:0] expected;

    begin
        expected = {{7{in[8]}}, in};
        if (ext !== expected) begin
            $display("FAIL [Sign Extend]: input = %b, expected = %b, got = %b", in, expected, ext);
            signext_errors = signext_errors + 1;
        end
        else begin
            $display("PASS [Sign Extend]: input = %b, output = %b", in, ext);
        end
		  signext_tests = signext_tests + 1;
    end
	endtask
	 
	 // tick fsm task
	 reg enable, rst, tick_clk;
	 wire[3:0] tick;
	 integer tick_tests = 0;
	 integer tick_errors = 0;
	 
	 tick_FSM tick_FSM_test(
		.enable(enable),
		.rst(rst),
		.clk(tick_clk),
		.tick(tick)
	 );
	 
	 task check_tick;
		input [3:0] expected;
		begin
			if (tick !== expected) begin
            $display("FAIL [Tick FSM]: rst = %b, enable = %b, expected = %b, got = %b", rst, enable, expected, tick);
				tick_errors = tick_errors + 1;
			end
			else begin
				$display("PASS [Tick FSM]: rst = %b, enable = %b, expected = %b, got = %b", rst, enable, expected, tick);
			end
			tick_tests = tick_tests + 1;
		end
	 endtask
	 
	 // the multiplexer task
	 reg [15:0] SignExtDin;
	 reg [15:0] R0, R1, R2, R3, R4, R5, R6, R7, G;
	 reg [3:0] sel;
	 wire [15:0] Bus;
	 integer multiplexer_tests = 0, multiplexer_errors = 0;
	 
	 multiplexer multiplexer_test(
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
		.Bus(Bus)
	 );
	 
	 task check_multiplexer;
		 reg [15:0] expected;
		 
		 begin
		 
			case (sel)
				4'b0000: expected = SignExtDin;
				4'b0001: expected = R0;
				4'b0010: expected = R1;
				4'b0011: expected = R2;
				4'b0100: expected = R3;
				4'b0101: expected = R4;
				4'b0110: expected = R5;
				4'b0111: expected = R6;
				4'b1000: expected = R7;
				4'b1001: expected = G;
				
				default: expected = 16'b0;
			endcase
			if (Bus !== expected) begin
				$display("FAIL [Multiplexer]: expected = %b, got = %b", expected, Bus);
				multiplexer_errors = multiplexer_errors + 1;
			end
			else begin
			$display("PASS [Multiplexer]: expected = %b, got = %b", expected, Bus);
			end
			multiplexer_tests = multiplexer_tests + 1;
		 end
	 endtask
	 
	 // the alu task
	 reg [15:0] input_a, input_b;
	 reg [2:0] alu_op;
	 wire [15:0] result;
	 integer alu_tests = 0, alu_errors = 0;
	 
	 ALU ALU_test(
		.input_a(input_a),
		.input_b(input_b),
		.alu_op(alu_op),
		.result(result)
	 );
	 
	 task check_alu;
		reg [15:0] expected;
		reg [15:0] intermediate;
		
		begin
		
			case (alu_op)
				3'b000: expected = input_a * input_b;
				3'b001: expected = input_a + input_b;
				3'b010: expected = input_a - input_b;
				3'b011: begin
					if (input_a[15] == 0) begin
						expected = input_b <<< input_a;
					end
					else begin
						intermediate = (~input_a) + 1;
						expected = input_b >> intermediate;
					end
				end
				default: expected = 16'd0;
			endcase
			
			if (result !== expected) begin
				$display("FAIL [ALU]: input_a = %b, input_b = %b, alu_op = %b, expected = %b, got = %b", input_a, input_b, alu_op, expected, result);
				alu_errors = alu_errors + 1;
			end
			else begin
				$display("PASS [ALU]: input_a = %b, input_b = %b, alu_op = %b, expected = %b, got = %b", input_a, input_b, alu_op, expected, result);
			end
			alu_tests = alu_tests + 1;
		end
	 endtask
	 
	 // register task
	 reg[15:0] data_in;
	 reg r_in;
	 reg reg_clk;
	 wire [15:0] Q;
	 reg rst;
	 integer register_tests = 0, register_errors = 0;
	 register_n register_test(
		 .data_in(data_in),
		 .r_in(r_in),
		 .clk(reg_clk),
		 .Q(Q),
		 .rst(rst)
	 );
	 
	 task check_register;
		reg[15:0] expected;
		begin
			if (Q !== expected) begin
				$display("FAIL [Register]: data_in = %b, r_in = %b, rst = %b, expected = %b, got = %b", data_in, r_in, rst, expected, Q);
				register_errors = register_errors + 1;
			end
			else begin
				$display("PASS [Register]: data_in = %b, r_in = %b, rst = %b, expected = %b, got = %b", data_in, r_in, rst, expected, Q);
			end
			register_tests = register_tests + 1;
		end
	 endtask
	
	initial begin
		tick_clk = 0;
		reg_clk = 0;
    end
	 
	 always begin
		#5 tick_clk = ~tick_clk;
	 end
	 
	 always begin
		#5 reg_clk = ~reg_clk;
	 end
	 
	 initial begin
		 // Sign extender tests
		 in = 9'b000000000;
		 #1;
		 check_sign_extend;
		 
		 in = 9'b000001010;
		 #1;
		 check_sign_extend;
		 
		 in = 9'b111111110;
		 #1;
		 check_sign_extend;
		 
		 in = 9'b100000000;
		 #1;
		 check_sign_extend;
		 // Tick FSM tests
		 rst = 1;
		 enable = 0;
		 #10;
		 check_tick(4'b0001);
		 
		 rst = 0;
		 enable = 1;
		 #10;
		 check_tick(4'b0010);
		 #10;
		 check_tick(4'b0100);
		 #10;
		 check_tick(4'b1000);
		 #10;
		 check_tick(4'b0001);
		 
		 rst = 0;
		 enable = 0;
		 #10;
		 check_tick(4'b0001);
		 
		 // Multiplexer tests
		 SignExtDin = 16'd0; R0 = 16'd1; R1 = 16'd2; R2 = 16'd3; R3 = 16'd4; R4 = 16'd5; R5 = 16'd6; R6 = 16'd7; R7 = 16'd8; G = 16'd9; 
		 sel = 4'b0000;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b0001;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b0010;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b0011;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b0100;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b0101;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b0110;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b0111;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b1000;
		 #1;
		 check_multiplexer;
		 
		 sel = 4'b1001;
		 #1;
		 check_multiplexer;
		 // ALU tests
		 
		 // multiply
		 // +, +
		 alu_op = 3'b000;
		 input_a = 16'd5;
		 input_b = 16'd3;
		 #1;
		 check_alu;
		 
		 // -, +
		 alu_op = 3'b000;
		 input_a = -16'd5;
		 input_b = 16'd3;
		 #1;
		 check_alu;
		 // +, -
		 alu_op = 3'b000;
		 input_a = 16'd5;
		 input_b = -16'd3;
		 #1;
		 check_alu;
		 // -, -
		 alu_op = 3'b000;
		 input_a = -16'd5;
		 input_b = -16'd3;
		 #1;
		 check_alu;
		 
		 // addition
		 // +, +
		 alu_op = 3'b001;
		 input_a = 16'd5;
		 input_b = 16'd3;
		 #1;
		 check_alu;
		 // -, +
		 alu_op = 3'b001;
		 input_a = -16'd5;
		 input_b = 16'd3;
		 #1;
		 check_alu;
		 // +, -
		 alu_op = 3'b001;
		 input_a = 16'd5;
		 input_b = -16'd3;
		 #1;
		 check_alu;
		 // -, -
		 alu_op = 3'b001;
		 input_a = -16'd5;
		 input_b = -16'd3;
		 #1;
		 check_alu;
		 
		 // subtration
		 // +, +
		 alu_op = 3'b010;
		 input_a = 16'd5;
		 input_b = 16'd3;
		 #1;
		 check_alu;
		 // -, +
		 alu_op = 3'b010;
		 input_a = -16'd5;
		 input_b = 16'd3;
		 #1;
		 check_alu;
		 // +, -
		 alu_op = 3'b010;
		 input_a = 16'd5;
		 input_b = -16'd3;
		 #1;
		 check_alu;
		 // -, -
		 alu_op = 3'b010;
		 input_a = -16'd5;
		 input_b = -16'd3;
		 #1;
		 check_alu;
		 
		 //signed shift
		 // +,+
		 alu_op = 3'b011;
		 input_a = 16'd2;
		 input_b = 16'd8;
		 #1;
		 check_alu;
		 
		 // -,+
		 alu_op = 3'b011;
		 input_a = -16'd2;
		 input_b = 16'd8;
		 #1;
		 check_alu;
		 
		 //+,-
		 alu_op = 3'b011;
		 input_a = 16'd2;
		 input_b = -16'd8;
		 #1;
		 check_alu;
		 
		 // -,-
		 alu_op = 3'b011;
		 input_a = -16'd2;
		 input_b = -16'd8;
		 #1;
		 check_alu;
	
		 // Register tests
		 // check reset
		 rst = 1;
		 r_in = 0;
		 #10;
		 check_register(16'd0);
		 
		 // check reset priority
		 rst = 1;
		 r_in = 1;
		 #10;
		 check_register(16'd0);
		 
		 // check if the data load correctly
		 rst = 0;
		 r_in = 1;
		 data_in = 16'd35;
		 #10;
		 check_register(data_in);
		 data_in = 16'd97;
		 #10;
		 check_register(data_in);
		 
		 // check hold
		 rst = 0;
		 r_in = 0;
		 #10;
		 check_register(data_in);
		 
		 
		 // Final summary
		 $display("Sign extender tests = %d|Errors = %d", signext_tests, signext_errors);
		 $display("Tick FSM tests = %d|Errors = %d", tick_tests, tick_errors);
		 $display("ALU tests = %d|Errors = %d", alu_tests, alu_errors);
		 $display("Multiplexer tests = %d|Errors = %d", multiplexer_tests, multiplexer_errors);
		 $display("Register tests = %d|Errors = %d", register_tests, register_errors);
		 $finish;

end

		
endmodule
