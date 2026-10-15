`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the processor.

Please enter your student ID:

*/
module proc_tb;
    // TODO: Implement the logic of your testbench here
	 wire clk;
	 wire rst;
	 wire [8:0] din;
	 
	 reg [8:0] SW;
	 reg [1:0] KEY;
	 
	 assign din = SW;
	 assign clk = KEY[1];
	 assign rst = KEY[0];
	 
	 wire [15:0] bus;
	 wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
	 
	 localparam NUM_DIRECTED = 20;
	 localparam NUM_RANDOM   = 500;     // FAQ: recommended minimum 500 cases per task
	 reg [NUM_DIRECTED+NUM_RANDOM:1] test_result = 0;
	 integer test_count = 0;
	 integer pass_count = 0;
	 integer fail_count = 0;
	 integer i;

	 // ---- random test campaign: reference model + stimulus ----
	 reg  [15:0] model [0:7];      // expected value of R0..R7
	 reg  [31:0] rnd;
	 reg  [1:0]  op_sel;
	 reg  [2:0]  rx, ry;
	 reg  [8:0]  instr, imm;
	 reg  [15:0] expected;
	 integer     seed, n, k, mismatches;

	 function [15:0] get_reg;
		input [2:0] idx;
		begin
			case (idx)
				3'd0: get_reg = R0;
				3'd1: get_reg = R1;
				3'd2: get_reg = R2;
				3'd3: get_reg = R3;
				3'd4: get_reg = R4;
				3'd5: get_reg = R5;
				3'd6: get_reg = R6;
				default: get_reg = R7;
			endcase
		end
	 endfunction
	 
	 simple_proc test_proc(
		.clk(clk),
		.rst(rst),
		.din(din),
		.bus(bus),
		.R0(R0),
		.R1(R1),
		.R2(R2),
		.R3(R3),
		.R4(R4),
		.R5(R5),
		.R6(R6),
		.R7(R7)
	 );
	 
	 task reset_processor;
	 begin
		KEY[0] = 1;
		@(posedge clk);
		#1;
		KEY[0] = 0;
	 end
	 endtask
	 
	 initial begin
		SW = 9'b0;
		KEY[1] = 0;
		
		// reset the processor
		reset_processor;
		
		// check reset
		if (R0 == 16'd0 && R1 == 16'd0 && R2 == 16'd0 && R3 == 16'd0 && R4 == 16'd0 && R5 == 16'd0 && R6 == 16'd0 && R7 == 16'd0)
			$display("RESET PASS");
		else 
			$display("RESET FAIL");
			
		// Testing movi
		// Test 1: movi: register, +
		test_count = test_count + 1;
		$display("TEST 1: MOVI R1, 5");
		
		// reset the processor
		reset_processor;
		
		SW = 9'b111_001_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b000_000_101;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		if (R1 == 16'd5) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[1] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[1] = 0;
		end
		
		// Test 2: movi: register, -
		test_count = test_count + 1;
		$display("TEST 2: MOVI R5, -9");
		
		// reset the processor
		reset_processor;
		
		SW = 9'b111_101_000;
		// Tick 1: Read in input value
		@(posedge clk);
	
		SW = 9'b111_110_111;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		if (R5 == -16'd9) begin
			$display("PASS: R5 = %d", R5);
			pass_count = pass_count + 1;
			test_result[2] = 1;
		end
		else begin
			$display("FAIL: R5 = %d", R5);
			fail_count = fail_count + 1;
			test_result[2] = 0;
		end
		
		// Test 3: add: +,+. output = positive
		test_count = test_count + 1;
		$display("TEST 3: ADD R1, R2 | Let R1 = 1, R2 = 2");
		
		// reset the processor
		reset_processor;
		
		// Movi R1, 1
		SW = 9'b111_001_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b000_000_001;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// Movi R2, 2
		SW = 9'b111_010_000;
		// Tick 1: Read in input value
		@(posedge clk);
	
		SW = 9'b000_000_010;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		$display("R1 = %d, R2 = %d", R1, R2);
		
		SW = 9'b001_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd3) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[3] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[3] = 0;
		end
		
		// Test 4: add: +input,-input. output = positive
		test_count = test_count + 1;
		$display("TEST 4: ADD R1, R2 | Let R1 = 5, R2 = -3");
		
		// reset the processor
		reset_processor;
		
		// Movi R1, 5
		SW = 9'b111_001_000;
		// Tick 1: Read in input value
		@(posedge clk);
	
		SW = 9'b000_000_101;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// Movi R2, -3
		SW = 9'b111_010_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b111_111_101;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		$display("R1 = %d, R2 = %d", R1, R2);
	
		SW = 9'b001_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd2) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[4] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[4] = 0;
		end
		
		// Test 5: add: +input,-input. output = negative
		test_count = test_count + 1;
		$display("TEST 5: ADD R1, R2 | Let R1 = 5, R2 = -9");
		
		// reset the processor
		reset_processor;
		
		// Movi R1, 5
		SW = 9'b111_001_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b000_000_101;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// Movi R2, -9
		SW = 9'b111_010_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b111_110_111;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		$display("R1 = %d, R2 = %d", R1, R2);
		
		SW = 9'b001_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == -16'd4) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[5] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[5] = 0;
		end
		
		// Test 6: add: -input,+input. output = positive
		test_count = test_count + 1;
		$display("TEST 6: ADD R1, R2 | Let R1 = -2, R2 = 7");
		
		// reset the processor
		reset_processor;
		
		// Movi R1, -2
		SW = 9'b111_001_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b111_111_110;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// Movi R2, 7
		SW = 9'b111_010_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b000_000_111;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		$display("R1 = %d, R2 = %d", R1, R2);
		
		SW = 9'b001_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd5) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[6] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[6] = 0;
		end
		
		// Test 7: add: -input,+input. output = negative
		test_count = test_count + 1;
		$display("TEST 7: ADD R1, R2 | Let R1 = -10, R2 = 4");
		
		// reset the processor
		reset_processor;
		
		// Movi R1, -10
		SW = 9'b111_001_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b111_110_110;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// Movi R2, 4
		SW = 9'b111_010_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b000_000_100;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		$display("R1 = %d, R2 = %d", R1, R2);
		
		SW = 9'b001_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == -16'd6) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[7] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[7] = 0;
		end
		
		// Test 8: add: -input,-input. output = negative
		test_count = test_count + 1;
		$display("TEST 8: ADD R1, R2 | Let R1 = -9, R2 = -27");
		
		// reset the processor
		reset_processor;
		
		// Movi R1, -9
		SW = 9'b111_001_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b111_110_111;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// Movi R2, -27
		SW = 9'b111_010_000;
		// Tick 1: Read in input value
		@(posedge clk);
		SW = 9'b111_100_101;
		// Tick 2: immediate value overwrites Rx
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		$display("R1 = %d, R2 = %d", R1, R2);
		
		SW = 9'b001_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == -16'd36) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[8] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[8] = 0;
		end
		
		// Test 9: addi: +reg, +input. output = positive
		test_count = test_count + 1;
		$display("TEST 9: ADDI R1, 6 | R1 starts at 4");
		
		reset_processor;
		
		// MOVI R1 = 4
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b000_000_100;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// ADDI, 6
		SW = 9'b010_001_000;
		@(posedge clk);
		SW = 9'b000_000_110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd10) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[9] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[9] = 0;
		end
		
		// Test 10: addi: +reg, -input. output = positive
		test_count = test_count + 1;
		$display("TEST 10: ADDI R1, -1 | R1 starts at 9");
		
		reset_processor;
		
		// MOVI R1 = 9
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b000_001_001;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// ADDI, -1
		SW = 9'b010_001_000;
		@(posedge clk);
		SW = 9'b111_111_111;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd8) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[10] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[10] = 0;
		end
		
		// Test 11: addi: +reg, -input. output = negative
		test_count = test_count + 1;
		$display("TEST 11: ADDI R1, -55 | R1 starts at 9");
		
		reset_processor;
		
		// MOVI R1 = 9
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b000_001_001;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// ADDI. -55
		SW = 9'b010_001_000;
		@(posedge clk);
		SW = 9'b111_001_001;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == -16'd46) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[11] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[11] = 0;
		end
		
		// Test 12: addi: -reg, +input. output = positive
		test_count = test_count + 1;
		$display("TEST 12: ADDI R1, 6 | R1 starts at -2");
		
		reset_processor;
		
		// MOVI R1 = -2
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b111_111_110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// ADDI, 6
		SW = 9'b010_001_000;
		@(posedge clk);
		SW = 9'b000_000_110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd4) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[12] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[12] = 0;
		end
		
		// Test 13: addi: -reg, +input. output = negative
		test_count = test_count + 1;
		$display("TEST 13: ADDI R1, 10 | R1 starts at -32");
		
		reset_processor;
		
		// MOVI R1 = -32
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b111_100_000;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// ADDI, 10
		SW = 9'b010_001_000;
		@(posedge clk);
		SW = 9'b000_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == -16'd22) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[13] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[13] = 0;
		end
		
		// Test 14: addi: -reg, -input
		test_count = test_count + 1;
		$display("TEST 14: ADDI R1, -5 | R1 starts at -10");

		reset_processor;

		// MOVI R1, -10
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b111_110_110;
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk);

		// ADDI R1, -5
		SW = 9'b010_001_000;
		@(posedge clk);
		SW = 9'b111_111_011;
		@(posedge clk); 
		@(posedge clk); 
		@(posedge clk);

		#1;
		if (R1 == -16'd15) begin
			 $display("PASS: R1 = %d", R1);
			 pass_count = pass_count + 1;
			 test_result[14] = 1;
		end
		else begin
			 $display("FAIL: R1 = %d", R1);
			 fail_count = fail_count + 1;
			 test_result[14] = 0;
		end
		
		// Test 15: sub: +reg, +reg. output = positive
		test_count = test_count + 1;
		$display("TEST 15: SUB R1, R2 | Let R1 = 17, R2 = 5");
		
		reset_processor;
		
		// MOVI R1 = 17
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b000_010_001;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// MOVI R2 = 5
		SW = 9'b111_010_000;
		@(posedge clk);
		SW = 9'b000_000_101;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// SUB R1,R2
		SW = 9'b011_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd12) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[15] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[15] = 0;
		end
		
		// Test 16: sub: +reg, +reg. output = negative
		test_count = test_count + 1;
		$display("TEST 16: SUB R1, R2 | Let R1 = 6, R2 = 7");
		
		reset_processor;
		
		// MOVI R1 = 6
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b000_000_110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// MOVI R2 = 7
		SW = 9'b111_010_000;
		@(posedge clk);
		SW = 9'b000_000_111;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// SUB R1,R2
		SW = 9'b011_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == -16'd1) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[16] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[16] = 0;
		end
		
		// Test 17: sub: +reg, -reg. output = positive
		test_count = test_count + 1;
		$display("TEST 17: SUB R1, R2 | Let R1 = 10, R2 = -20");
		
		reset_processor;
		
		// MOVI R1 = 10
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b000_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// MOVI R2 = -20
		SW = 9'b111_010_000;
		@(posedge clk);
		SW = 9'b111_101_100;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// SUB R1,R2
		SW = 9'b011_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd30) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[17] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[17] = 0;
		end
		
		// Test 18: sub: -reg ,+reg. output = negative
		test_count = test_count + 1;
		$display("TEST 18: SUB R1, R2 | Let R1 = -30, R2 = 4");
		
		reset_processor;
		
		// MOVI R1 = -30
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b111_100_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// MOVI R2 = 4
		SW = 9'b111_010_000;
		@(posedge clk);
		SW = 9'b000_000_100;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// SUB R1,R2
		SW = 9'b011_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == -16'd34) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[18] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[18] = 0;
		end
		
		// Test 19: sub: -reg, -reg. output = positive
		test_count = test_count + 1;
		$display("TEST 19: SUB R1, R2 | Let R1 = -17, R2 = -39");
		
		reset_processor;
		
		// MOVI R1 = -17
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b111_101_111;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// MOVI R2 = -39
		SW = 9'b111_010_000;
		@(posedge clk);
		SW = 9'b111_011_001;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// SUB R1,R2
		SW = 9'b011_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == 16'd22) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[19] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[19] = 0;
		end
		
		// Test 20: sub: -reg, -reg. output = negative
		test_count = test_count + 1;
		$display("TEST 20: SUB R1, R2 | Let R1 = -30, R2 = -7");
		
		reset_processor;
		
		// MOVI R1 = -30
		SW = 9'b111_001_000;
		@(posedge clk);
		SW = 9'b111_100_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// MOVI R2 = -7
		SW = 9'b111_010_000;
		@(posedge clk);
		SW = 9'b111_111_001;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// SUB R1,R2
		SW = 9'b011_001_010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		if (R1 == -16'd23) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[20] = 1;
		end
		else begin
			$display("FAIL: R1 = %d", R1);
			fail_count = fail_count + 1;
			test_result[20] = 0;
		end
		
		// =====================================================================
		// RANDOM TEST CAMPAIGN
		// NUM_RANDOM random instructions (movi / add / addi / sub, random
		// registers including Rx == Ry, random 9-bit immediates covering the
		// full -256..255 range). After EVERY instruction all eight registers
		// are compared with a reference model, so a wrong result, a write to
		// the wrong register, or an accidental write to another register are
		// all caught. 16-bit overflow wraps around (two's complement); the
		// model wraps the same way. Fixed seed -> repeatable run.
		// =====================================================================
		seed = 2072;
		$display("========================");
		$display("RANDOM TESTS: %0d instructions, seed %0d (only failures are printed)", NUM_RANDOM, seed);

		reset_processor;
		for (k = 0; k < 8; k = k + 1)
			model[k] = 16'd0;

		for (n = 1; n <= NUM_RANDOM; n = n + 1) begin
			rnd    = $random(seed);
			op_sel = rnd[1:0];
			rx     = rnd[4:2];
			ry     = rnd[7:5];
			imm    = rnd[16:8];

			case (op_sel)
				2'd0: begin instr = {3'b111, rx, 3'b000}; expected = {{7{imm[8]}}, imm};              end // movi
				2'd1: begin instr = {3'b001, rx, ry};     expected = model[rx] + model[ry];           end // add
				2'd2: begin instr = {3'b010, rx, 3'b000}; expected = model[rx] + {{7{imm[8]}}, imm};  end // addi
				default: begin instr = {3'b011, rx, ry};  expected = model[rx] - model[ry];           end // sub
			endcase

			// run the instruction through its 4 ticks (same timing as the directed tests)
			SW = instr;
			@(posedge clk);
			SW = imm;
			@(posedge clk);
			@(posedge clk);
			@(posedge clk);
			#1;

			model[rx] = expected;
			test_count = test_count + 1;
			mismatches = 0;
			for (k = 0; k < 8; k = k + 1)
				if (get_reg(k) !== model[k])
					mismatches = mismatches + 1;

			if (mismatches == 0) begin
				pass_count = pass_count + 1;
				test_result[test_count] = 1;
			end
			else begin
				fail_count = fail_count + 1;
				test_result[test_count] = 0;
				$display("FAIL random #%0d: instr = %b_%b_%b, imm = %0d", n, instr[8:6], instr[5:3], instr[2:0], $signed(imm));
				for (k = 0; k < 8; k = k + 1)
					if (get_reg(k) !== model[k])
						$display("     R%0d = %0d, expected %0d", k, $signed(get_reg(k)), $signed(model[k]));
			end
		end
		$display("RANDOM TESTS done");

		$display("========================");
		$display("TEST SUMMARY");
		$display("Total Tests: %0d (%0d directed + %0d random)", test_count, NUM_DIRECTED, NUM_RANDOM);
		$display("Total PASS: %d", pass_count);
		$display("Total FAIL: %d", fail_count);
		
		if (fail_count == 0) begin
			$display("All tests passed.");
		end
		else begin
			$display("Failed Tests:");
			for (i = 1; i <= test_count; i = i + 1) begin
				if (test_result[i] == 0) begin
					$display("Test[%0d] FAIL", i);
				end
			end
		end
		
		$display("========================");
	 end
	 
	 always begin
		#5 KEY[1] = ~KEY[1];
	 end
	 
	 
endmodule