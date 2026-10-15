`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment
This file contains a Verilog test bench to test the correctness of the
extended processor (Task 3: proc_extension).

Please enter your student ID:

Compile in ModelSim: components.v, proc_extension.v, proc_extension_tb.v
Simulate proc_extension_tb, then: run -all

Test plan
  A. Regression  : one test each of movi / add / addi / sub, to show the
                   Task 2 instructions still work after the extension.
  B. mult        : signs (+*+, +*-, -*-), multiply by 0, same register
                   (square), and 16-bit wrap-around of large products.
  C. ssi         : left shift, right shift of positive and negative values
                   (arithmetic shift keeps the sign), shift by 0, shift into
                   the sign bit.
  D. disp        : positive and negative values, highest register (R7),
                   display HOLDS its value while other instructions run,
                   disp does not change any register, reset clears display.
  E. enable      : enable = 0 freezes the processor, enable = 1 resumes.
  F. random      : 500 random instructions using ALL seven instructions,
                   random registers and immediates, checked after every
                   instruction against a reference model of R0-R7 AND the
                   display register (FAQ: recommended minimum 500 cases).
  Overflow: all arithmetic wraps around in 16 bits (two's complement); the
  reference model wraps the same way, and tests B6 / random tests rely on it.

Instruction encoding used (IR = op[8:6] rx[5:3] ry[2:0]):
  disp 000 | add 001 | addi 010 | sub 011 | mult 100 | ssi 101 | movi 111
*/
module proc_extension_tb;

	// Inputs driven the same way as the board (SW / KEY), as in the Task 2 testbench
	wire clk;
	wire rst;
	wire [8:0] din;

	reg [8:0] SW;
	reg [1:0] KEY;
	reg       EN;            // enable input (SW[9] on the board)

	assign din = SW;
	assign clk = KEY[1];
	assign rst = KEY[0];

	wire [15:0] bus;
	wire [15:0] display;
	wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;

	localparam NUM_RANDOM = 500;
	localparam NUM_TESTS  = 40 + NUM_RANDOM;
	reg [NUM_TESTS:1] test_result;
	integer test_count = 0;
	integer pass_count = 0;
	integer fail_count = 0;
	integer i;

	// Opcodes
	localparam OP_DISP = 3'b000, OP_ADD  = 3'b001, OP_ADDI = 3'b010, OP_SUB = 3'b011,
	           OP_MULT = 3'b100, OP_SSI  = 3'b101, OP_MOVI = 3'b111;

	proc_extension test_proc(
		.clk(clk),
		.rst(rst),
		.din(din),
		.enable(EN),
		.bus(bus),
		.display(display),
		.R0(R0),
		.R1(R1),
		.R2(R2),
		.R3(R3),
		.R4(R4),
		.R5(R5),
		.R6(R6),
		.R7(R7)
	);

	// Clock: period 10 ns
	always begin
		#5 KEY[1] = ~KEY[1];
	end

	// ------------------------------------------------------------------
	// Helper tasks
	// ------------------------------------------------------------------

	// Synchronous reset: hold rst over one rising edge, release just after it.
	task reset_processor;
	begin
		KEY[0] = 1;
		@(posedge clk);
		#1;
		KEY[0] = 0;
	end
	endtask

	// Run one instruction through all 4 ticks.
	//   instr : 9-bit instruction word, put on din during tick 1
	//   imm   : 9-bit immediate, put on din from tick 2 onwards (0 if unused)
	// Ends 1 ns after the 4th rising edge, so registers have been written.
	task run_instr;
		input [8:0] instr;
		input [8:0] imm;
	begin
		SW = instr;
		@(posedge clk);      // tick 1: IR <= instr
		SW = imm;
		@(posedge clk);      // tick 2
		@(posedge clk);      // tick 3
		@(posedge clk);      // tick 4
		#1;
	end
	endtask

	// Shorthands for each instruction
	task movi; input [2:0] rx; input [8:0] imm;
	begin run_instr({OP_MOVI, rx, 3'b000}, imm); end endtask

	task addi; input [2:0] rx; input [8:0] imm;
	begin run_instr({OP_ADDI, rx, 3'b000}, imm); end endtask

	task ssi;  input [2:0] rx; input [8:0] imm;
	begin run_instr({OP_SSI, rx, 3'b000}, imm); end endtask

	task add;  input [2:0] rx; input [2:0] ry;
	begin run_instr({OP_ADD, rx, ry}, 9'd0); end endtask

	task sub;  input [2:0] rx; input [2:0] ry;
	begin run_instr({OP_SUB, rx, ry}, 9'd0); end endtask

	task mult; input [2:0] rx; input [2:0] ry;
	begin run_instr({OP_MULT, rx, ry}, 9'd0); end endtask

	task disp; input [2:0] rx;
	begin run_instr({OP_DISP, rx, 3'b000}, 9'd0); end endtask

	// Read register Rn by number
	function [15:0] get_reg;
		input [2:0] n;
	begin
		case (n)
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

	// Start a new numbered test
	task start_test;
		input [8*60:1] name;
	begin
		test_count = test_count + 1;
		$display("TEST %0d: %0s", test_count, name);
	end
	endtask

	// Compare a value and record PASS / FAIL for the current test
	task check;
		input [8*12:1] what;       // e.g. "R1", "display"
		input [15:0]   actual;
		input [15:0]   expected;
	begin
		if (actual === expected) begin
			$display("   PASS: %0s = %0d", what, $signed(actual));
			pass_count = pass_count + 1;
			test_result[test_count] = 1;
		end
		else begin
			$display("   FAIL: %0s = %0d (0x%h), expected %0d (0x%h)",
				what, $signed(actual), actual, $signed(expected), expected);
			fail_count = fail_count + 1;
			test_result[test_count] = 0;
		end
	end
	endtask

	// Snapshot of all registers, to prove an instruction changed nothing
	reg [15:0] snap [0:7];
	task snapshot_regs;
		integer k;
	begin
		for (k = 0; k < 8; k = k + 1)
			snap[k] = get_reg(k);
	end
	endtask

	// ------------------------------------------------------------------
	// Reference model for the random campaign
	// ------------------------------------------------------------------
	reg  [15:0] model [0:7];
	reg  [15:0] model_display;
	reg  [31:0] rnd;
	reg  [2:0]  r_op, r_x, r_y;
	reg  [8:0]  r_imm;
	reg  [15:0] imm_ext, expected;
	integer     seed, n, mismatches;
	reg  [8*4:1] op_txt;

	// ssi: value shifted by amount (same rule as the ALU's signed shift)
	function [15:0] shift_model;
		input [15:0] amount;
		input [15:0] value;
	begin
		if ($signed(amount) >= 0)
			shift_model = value << amount;
		else
			shift_model = $signed(value) >>> (-$signed(amount));
	end
	endfunction

	// ------------------------------------------------------------------
	// Test sequence
	// ------------------------------------------------------------------
	reg regs_same;
	integer k;

	initial begin
		SW = 9'b0;
		KEY = 2'b00;
		EN = 1'b1;
		test_result = {NUM_TESTS{1'b0}};

		$display("========================");
		$display("TASK 3 TESTBENCH: proc_extension");
		$display("========================");

		reset_processor;
		if (R0 == 16'd0 && R1 == 16'd0 && R2 == 16'd0 && R3 == 16'd0 &&
		    R4 == 16'd0 && R5 == 16'd0 && R6 == 16'd0 && R7 == 16'd0 && display == 16'd0)
			$display("RESET PASS (all registers and display = 0)");
		else
			$display("RESET FAIL");

		// ============ A. Regression of Task 2 instructions ============
		$display("--- A. Task 2 instructions still work ---");

		start_test("MOVI R1, -9");
		reset_processor;
		movi(3'd1, -9'sd9);
		check("R1", R1, -16'sd9);

		start_test("ADD R1, R2 | R1 = 5, R2 = -3");
		reset_processor;
		movi(3'd1, 9'sd5);
		movi(3'd2, -9'sd3);
		add(3'd1, 3'd2);
		check("R1", R1, 16'sd2);

		start_test("ADDI R1, -55 | R1 = 9");
		reset_processor;
		movi(3'd1, 9'sd9);
		addi(3'd1, -9'sd55);
		check("R1", R1, -16'sd46);

		start_test("SUB R1, R2 | R1 = -30, R2 = -7");
		reset_processor;
		movi(3'd1, -9'sd30);
		movi(3'd2, -9'sd7);
		sub(3'd1, 3'd2);
		check("R1", R1, -16'sd23);

		// ============ B. mult ============
		$display("--- B. MULT ---");

		start_test("MULT R1, R2 | R1 = 6, R2 = 7  (+ * +)");
		reset_processor;
		movi(3'd1, 9'sd6);
		movi(3'd2, 9'sd7);
		mult(3'd1, 3'd2);
		check("R1", R1, 16'sd42);

		start_test("MULT R1, R2 | R1 = 5, R2 = -3  (+ * -)");
		reset_processor;
		movi(3'd1, 9'sd5);
		movi(3'd2, -9'sd3);
		mult(3'd1, 3'd2);
		check("R1", R1, -16'sd15);

		start_test("MULT R3, R5 | R3 = -4, R5 = -8  (- * -)");
		reset_processor;
		movi(3'd3, -9'sd4);
		movi(3'd5, -9'sd8);
		mult(3'd3, 3'd5);
		check("R3", R3, 16'sd32);

		start_test("MULT R1, R2 | R1 = 123, R2 = 0  (multiply by zero)");
		reset_processor;
		movi(3'd1, 9'sd123);
		mult(3'd1, 3'd2);                  // R2 is 0 after reset
		check("R1", R1, 16'd0);

		start_test("MULT R4, R4 | R4 = -12  (same register, square)");
		reset_processor;
		movi(3'd4, -9'sd12);
		mult(3'd4, 3'd4);
		check("R4", R4, 16'sd144);

		start_test("MULT R1, R2 twice | R1 = R2 = 255  (keeps low 16 bits)");
		reset_processor;
		movi(3'd1, 9'sd255);
		movi(3'd2, 9'sd255);
		mult(3'd1, 3'd2);                  // 255*255   = 65025 (0xFE01), fits in 16 bits
		mult(3'd1, 3'd2);                  // 65025*255 = 16581375 -> low 16 bits = 767
		check("R1", R1, 16'd767);

		// ============ C. ssi ============
		$display("--- C. SSI ---");

		start_test("SSI R1, 2 | R1 = 3  (shift left)");
		reset_processor;
		movi(3'd1, 9'sd3);
		ssi(3'd1, 9'sd2);
		check("R1", R1, 16'sd12);

		start_test("SSI R1, -3 | R1 = 64  (shift right, positive)");
		reset_processor;
		movi(3'd1, 9'sd64);
		ssi(3'd1, -9'sd3);
		check("R1", R1, 16'sd8);

		start_test("SSI R2, -2 | R2 = -64  (arithmetic right, keeps sign)");
		reset_processor;
		movi(3'd2, -9'sd64);
		ssi(3'd2, -9'sd2);
		check("R2", R2, -16'sd16);

		start_test("SSI R6, 0 | R6 = 7  (shift by zero)");
		reset_processor;
		movi(3'd6, 9'sd7);
		ssi(3'd6, 9'sd0);
		check("R6", R6, 16'sd7);

		start_test("SSI R1, 15 | R1 = 1  (shift into the sign bit)");
		reset_processor;
		movi(3'd1, 9'sd1);
		ssi(3'd1, 9'sd15);
		check("R1", R1, 16'h8000);

		start_test("SSI R1, -1 | R1 = -1  (-1 stays -1 on right shift)");
		reset_processor;
		movi(3'd1, -9'sd1);
		ssi(3'd1, -9'sd1);
		check("R1", R1, -16'sd1);

		// ============ D. disp ============
		$display("--- D. DISP ---");

		start_test("DISP R1 | R1 = 42");
		reset_processor;
		movi(3'd1, 9'sd42);
		disp(3'd1);
		check("display", display, 16'sd42);

		start_test("DISP R2 | R2 = -100  (negative value)");
		reset_processor;
		movi(3'd2, -9'sd100);
		disp(3'd2);
		check("display", display, -16'sd100);

		start_test("DISP R7 | R7 = 77  (highest register number)");
		reset_processor;
		movi(3'd7, 9'sd77);
		disp(3'd7);
		check("display", display, 16'sd77);

		start_test("DISP holds value while other instructions run");
		reset_processor;
		movi(3'd1, 9'sd42);
		disp(3'd1);                        // display = 42
		movi(3'd1, 9'sd9);                 // change R1 ...
		add(3'd1, 3'd1);                   // ... and again (R1 = 18)
		mult(3'd1, 3'd1);                  // ... and again (R1 = 324)
		check("display", display, 16'sd42);   // still 42 until the next disp

		start_test("DISP shows a computed result | mult 6 * -7");
		reset_processor;
		movi(3'd3, 9'sd6);
		movi(3'd4, -9'sd7);
		mult(3'd3, 3'd4);
		disp(3'd3);
		check("display", display, -16'sd42);

		start_test("DISP does not change any register");
		reset_processor;
		movi(3'd0, 9'sd10);
		movi(3'd3, -9'sd20);
		movi(3'd7, 9'sd30);
		snapshot_regs;
		disp(3'd3);
		regs_same = 1'b1;
		for (k = 0; k < 8; k = k + 1)
			if (get_reg(k) !== snap[k]) begin
				regs_same = 1'b0;
				$display("   R%0d changed from %0d to %0d", k, $signed(snap[k]), $signed(get_reg(k)));
			end
		check("regs same", {15'd0, regs_same}, 16'd1);

		start_test("Reset clears the display");
		movi(3'd1, 9'sd99);
		disp(3'd1);                        // display = 99
		reset_processor;
		check("display", display, 16'd0);

		// ============ E. enable ============
		$display("--- E. ENABLE ---");

		start_test("ENABLE = 0 freezes the processor | try MOVI R3, 77");
		reset_processor;
		EN = 1'b0;
		movi(3'd3, 9'sd77);                // 4 clocks with enable off
		check("R3", R3, 16'd0);            // nothing written

		start_test("ENABLE = 1 resumes | MOVI R3, 77");
		EN = 1'b1;
		movi(3'd3, 9'sd77);
		check("R3", R3, 16'sd77);

		// ============ F. random campaign ============
		seed = 2072;
		$display("--- F. RANDOM: %0d instructions, seed %0d (only failures are printed) ---", NUM_RANDOM, seed);
		EN = 1'b1;
		reset_processor;
		for (k = 0; k < 8; k = k + 1) model[k] = 16'd0;
		model_display = 16'd0;

		for (n = 1; n <= NUM_RANDOM; n = n + 1) begin
			rnd = $random(seed);
			r_x = rnd[2:0];
			r_y = rnd[5:3];
			// pick one of the 7 instructions with equal probability
			case ({1'b0, rnd[31:8]} % 7)
				0: r_op = OP_MOVI;
				1: r_op = OP_ADD;
				2: r_op = OP_ADDI;
				3: r_op = OP_SUB;
				4: r_op = OP_MULT;
				5: r_op = OP_SSI;
				default: r_op = OP_DISP;
			endcase
			// immediates: full 9-bit range, except ssi uses -20..+20 so shifts are meaningful
			if (r_op == OP_SSI)
				r_imm = ($random(seed) % 21);
			else
				r_imm = $random(seed);
			imm_ext = {{7{r_imm[8]}}, r_imm};

			case (r_op)
				OP_MOVI: begin op_txt = "movi"; expected = imm_ext;                         end
				OP_ADD:  begin op_txt = "add "; expected = model[r_x] + model[r_y];         end
				OP_ADDI: begin op_txt = "addi"; expected = model[r_x] + imm_ext;            end
				OP_SUB:  begin op_txt = "sub "; expected = model[r_x] - model[r_y];         end
				OP_MULT: begin op_txt = "mult"; expected = model[r_x] * model[r_y];         end
				OP_SSI:  begin op_txt = "ssi "; expected = shift_model(imm_ext, model[r_x]); end
				default: begin op_txt = "disp"; expected = model[r_x];                      end
			endcase

			if (r_op == OP_MOVI || r_op == OP_ADDI || r_op == OP_SSI)
				run_instr({r_op, r_x, 3'b000}, r_imm);
			else if (r_op == OP_DISP)
				run_instr({r_op, r_x, 3'b000}, 9'd0);
			else
				run_instr({r_op, r_x, r_y}, 9'd0);

			if (r_op == OP_DISP) model_display = expected;   // disp writes H only
			else                 model[r_x]    = expected;

			test_count = test_count + 1;
			mismatches = 0;
			for (k = 0; k < 8; k = k + 1)
				if (get_reg(k) !== model[k]) mismatches = mismatches + 1;
			if (display !== model_display) mismatches = mismatches + 1;

			if (mismatches == 0) begin
				pass_count = pass_count + 1;
				test_result[test_count] = 1;
			end
			else begin
				fail_count = fail_count + 1;
				test_result[test_count] = 0;
				$display("FAIL random #%0d: %0s r%0d, r%0d / imm %0d", n, op_txt, r_x, r_y, $signed(r_imm));
				for (k = 0; k < 8; k = k + 1)
					if (get_reg(k) !== model[k])
						$display("     R%0d = %0d, expected %0d", k, $signed(get_reg(k)), $signed(model[k]));
				if (display !== model_display)
					$display("     display = %0d, expected %0d", $signed(display), $signed(model_display));
			end
		end
		$display("--- F. RANDOM done ---");

		// ============ Summary ============
		$display("========================");
		$display("TEST SUMMARY");
		$display("Total Tests: %0d (%0d directed + %0d random)", test_count, test_count - NUM_RANDOM, NUM_RANDOM);
		$display("Total PASS : %0d", pass_count);
		$display("Total FAIL : %0d", fail_count);

		if (fail_count == 0) begin
			$display("All tests passed.");
		end
		else begin
			$display("Failed Tests:");
			for (i = 1; i <= test_count; i = i + 1) begin
				if (test_result[i] == 0)
					$display("Test[%0d] FAIL", i);
			end
		end
		$display("========================");
		$stop;
	end

endmodule
