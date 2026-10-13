/*
 * ECE2072 Bonus Challenge - x72 communication processor
 *
 * Design choice:
 * - Opcode 000 is repurposed as TX (type-1 instruction).
 * - R6 is replaced by a read-only RX register.
 * - R7 is used as the display register directly, so the old DISP opcode
 *   is implemented as a software pseudo-instruction:
 *       movi r7, 0
 *       add  r7, rX
 * - Communication uses a 16-bit parallel data path with a 2-wire
 *   request/acknowledge handshake. This is asynchronous between boards;
 *   request and acknowledge are synchronised through two flip-flops.
 */

module proc_bonus(
    input        clk,
    input        rst,
    input        enable,
    input  [8:0] din,

    // Communication inputs from the other processor
    input  [15:0] rx_data,
    input         rx_req,
    input         tx_ack,

    // Communication outputs to the other processor
    output [15:0] tx_data,
    output        tx_req,
    output        rx_ack,

    // Processor outputs
    output [15:0] bus,
    output [15:0] display,
    output reg [15:0] PC,
    output [3:0] tick,
    output [15:0] R0,
    output [15:0] R1,
    output [15:0] R2,
    output [15:0] R3,
    output [15:0] R4,
    output [15:0] R5,
    output [15:0] R6,
    output [15:0] R7
);

    // ------------------------------------------------------------
    // Control signals
    // ------------------------------------------------------------
    reg R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in;
    reg A_in, G_in, IR_in;
    reg [2:0] alu_op;
    reg [3:0] bus_control;
    wire [15:0] A_out, G_out, alu_out;   // driven by instances -> must be wires
    wire [8:0] IR_out;
    reg [15:0] next_PC;

    // ------------------------------------------------------------
    // Communication state
    // ------------------------------------------------------------
    reg [15:0] tx_data_reg;
    reg tx_req_reg;
    reg rx_ack_reg;

    reg tx_ack_ff1, tx_ack_ff2;
    reg rx_req_ff1, rx_req_ff2;

    wire tx_ready;
    wire tx_start;
    wire rx_load;
    wire fsm_enable;

    assign tx_data = tx_data_reg;
    assign tx_req  = tx_req_reg;
    assign rx_ack  = rx_ack_reg;

    // The receiver is always ready to receive independently of the CPU
    // instruction currently being executed.
    assign rx_load = rx_req_ff2 & ~rx_ack_reg;

    // A transfer is complete only when the returned acknowledgement
    // matches our request level.
    assign tx_ready = (tx_req_reg == tx_ack_ff2);

    // TX is opcode 000. The source register is IR[5:3].
    assign tx_start = (tick == 4'b0010) &&
                      (IR_out[8:6] == 3'b000) &&
                      tx_ready;

    // Hold a TX instruction in tick 2 while an earlier TX handshake
    // is still being completed. Once both request and acknowledge are
    // low, the instruction can launch and the FSM may advance.
    assign fsm_enable = enable &&
                        !((tick == 4'b0010) &&
                          (IR_out[8:6] == 3'b000) &&
                          (tx_req_reg || tx_ack_ff2));

    // ------------------------------------------------------------
    // Registers
    // ------------------------------------------------------------
    register_n #(.N(16)) reg_R0(
        .data_in(bus), .r_in(R0_in), .clk(clk), .Q(R0), .rst(rst)
    );

    register_n #(.N(16)) reg_R1(
        .data_in(bus), .r_in(R1_in), .clk(clk), .Q(R1), .rst(rst)
    );

    register_n #(.N(16)) reg_R2(
        .data_in(bus), .r_in(R2_in), .clk(clk), .Q(R2), .rst(rst)
    );

    register_n #(.N(16)) reg_R3(
        .data_in(bus), .r_in(R3_in), .clk(clk), .Q(R3), .rst(rst)
    );

    register_n #(.N(16)) reg_R4(
        .data_in(bus), .r_in(R4_in), .clk(clk), .Q(R4), .rst(rst)
    );

    register_n #(.N(16)) reg_R5(
        .data_in(bus), .r_in(R5_in), .clk(clk), .Q(R5), .rst(rst)
    );

    // R6 is the dedicated RX register. It can only be written by RX.
    register_n #(.N(16)) reg_RX(
        .data_in(rx_data),
        .r_in(rx_load),
        .clk(clk),
        .Q(R6),
        .rst(rst)
    );

    register_n #(.N(16)) reg_R7(
        .data_in(bus), .r_in(R7_in), .clk(clk), .Q(R7), .rst(rst)
    );

    register_n #(.N(16)) reg_A(
        .data_in(bus), .r_in(A_in), .clk(clk), .Q(A_out), .rst(rst)
    );

    register_n #(.N(16)) reg_G(
        .data_in(alu_out), .r_in(G_in), .clk(clk), .Q(G_out), .rst(rst)
    );

    register_n #(.N(9)) reg_IR(
        .data_in(din), .r_in(IR_in), .clk(clk), .Q(IR_out), .rst(rst)
    );

    // R7 continuously drives the hex display. This replaces the old
    // dedicated display register / DISP opcode.
    assign display = R7;

    // ------------------------------------------------------------
    // Datapath components
    // ------------------------------------------------------------
    multiplexer mul(
        .SignExtDin(din),
        .R0(R0), .R1(R1), .R2(R2), .R3(R3),
        .R4(R4), .R5(R5), .R6(R6), .R7(R7),
        .G(G_out),
        .sel(bus_control),
        .Bus(bus)
    );

    ALU alu(
        .input_a(A_out),
        .input_b(bus),
        .alu_op(alu_op),
        .result(alu_out)
    );

    tick_FSM fsm(
        .rst(rst),
        .clk(clk),
        .enable(fsm_enable),
        .tick(tick)
    );

    // ------------------------------------------------------------
    // Synchronisers and communication handshake
    // ------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            tx_ack_ff1 <= 1'b0;
            tx_ack_ff2 <= 1'b0;
            rx_req_ff1 <= 1'b0;
            rx_req_ff2 <= 1'b0;

            tx_data_reg <= 16'b0;
            tx_req_reg <= 1'b0;
            rx_ack_reg <= 1'b0;
        end
        else begin
            // Synchronise asynchronous inputs from the other board.
            tx_ack_ff1 <= tx_ack;
            tx_ack_ff2 <= tx_ack_ff1;
            rx_req_ff1 <= rx_req;
            rx_req_ff2 <= rx_req_ff1;

            // TX handshake.
            if (tx_req_reg && tx_ack_ff2) begin
                tx_req_reg <= 1'b0;
            end
            else if (tx_start) begin
                tx_data_reg <= bus;
                tx_req_reg <= 1'b1;
            end

            // RX handshake.
            // A rising request causes the RX register to capture rx_data.
            // After the request falls, the acknowledgement follows it low.
            if (rx_req_ff2 != rx_ack_reg) begin
                rx_ack_reg <= rx_req_ff2;
            end
        end
    end

    // ------------------------------------------------------------
    // Main control unit
    // ------------------------------------------------------------
    always @(*) begin
        // Defaults
        IR_in = 1'b0;
        A_in  = 1'b0;
        G_in  = 1'b0;

        R0_in = 1'b0;
        R1_in = 1'b0;
        R2_in = 1'b0;
        R3_in = 1'b0;
        R4_in = 1'b0;
        R5_in = 1'b0;
        R6_in = 1'b0;   // R6 is RX-only
        R7_in = 1'b0;

        bus_control = 4'b0000;
        alu_op = 3'b000;
        next_PC = PC;

        case (tick)
            // ----------------------------------------------------
            // TICK 1: fetch instruction
            // ----------------------------------------------------
            4'b0001: begin
                IR_in = 1'b1;
            end

            // ----------------------------------------------------
            // TICK 2: select first operand / source register
            // ----------------------------------------------------
            4'b0010: begin
                case (IR_out[8:6])
                    // 000 = TX Rn
                    3'b000: begin
                        bus_control = {1'b0, IR_out[5:3]};
                    end

                    // 001 = ADD Ra, Rb
                    3'b001: begin
                        bus_control = {1'b0, IR_out[5:3]};
                        A_in = 1'b1;
                    end

                    // 010 = ADDI Ra, imm
                    3'b010: begin
                        bus_control = {1'b0, IR_out[5:3]};
                        A_in = 1'b1;
                        next_PC = PC + 16'd1;
                    end

                    // 011 = SUB Ra, Rb
                    3'b011: begin
                        bus_control = {1'b0, IR_out[5:3]};
                        A_in = 1'b1;
                    end

                    // 100 = MULT Ra, Rb
                    3'b100: begin
                        bus_control = {1'b0, IR_out[5:3]};
                        A_in = 1'b1;
                    end

                    // 101 = SSI Ra, imm
                    3'b101: begin
                        bus_control = {1'b0, IR_out[5:3]};
                        A_in = 1'b1;
                        next_PC = PC + 16'd1;
                    end

                    // 110 = BEZ Rn, imm
                    3'b110: begin
                        bus_control = {1'b0, IR_out[5:3]};
                        next_PC = PC + 16'd1;
                    end

                    // 111 = MOVI Rn, imm
                    3'b111: begin
                        next_PC = PC + 16'd1;
                    end

                    default: begin
                    end
                endcase
            end

            // ----------------------------------------------------
            // TICK 3/4 ALU execution, register writeback, branch
            // ----------------------------------------------------
            4'b0100: begin
                case (IR_out[8:6])
                    3'b000: begin
                        // TX: communication block captures bus in parallel.
                    end

                    3'b001: begin
                        bus_control = {1'b0, IR_out[2:0]};
                        alu_op = 3'b001;
                        G_in = 1'b1;
                    end

                    3'b010: begin
                        bus_control = 4'b1001;
                        alu_op = 3'b001;
                        G_in = 1'b1;
                    end

                    3'b011: begin
                        bus_control = {1'b0, IR_out[2:0]};
                        alu_op = 3'b010;
                        G_in = 1'b1;
                    end

                    3'b100: begin
                        bus_control = {1'b0, IR_out[2:0]};
                        alu_op = 3'b000;
                        G_in = 1'b1;
                    end

                    3'b101: begin
                        // A holds Rx, bus holds the immediate:
                        // op 100 = input_a shifted by input_b (Rx shifted by imm).
                        bus_control = 4'b1001;
                        alu_op = 3'b100;
                        G_in = 1'b1;
                    end

                    3'b110: begin
                        // BEZ: if Rx == 0, branch by the signed immediate.
                        bus_control = {1'b0, IR_out[5:3]};
                        if (bus == 16'b0)
                            next_PC = PC + 16'd1 +
                                      ({{7{din[8]}}, din} << 1);
                        else
                            next_PC = PC + 16'd1;
                    end

                    3'b111: begin
                        // MOVI writes the sign-extended immediate directly.
                        bus_control = 4'b1001;
                        case (IR_out[5:3])
                            3'b000: R0_in = 1'b1;
                            3'b001: R1_in = 1'b1;
                            3'b010: R2_in = 1'b1;
                            3'b011: R3_in = 1'b1;
                            3'b100: R4_in = 1'b1;
                            3'b101: R5_in = 1'b1;
                            3'b110: begin end // R6 is RX-only
                            3'b111: R7_in = 1'b1;
                            default: begin end
                        endcase
                    end

                    default: begin
                    end
                endcase
            end

            // ----------------------------------------------------
            // TICK 4: writeback / PC advance
            // ----------------------------------------------------
            4'b1000: begin
                case (IR_out[8:6])
                    3'b000: begin
                        // TX is a one-register instruction.
                        next_PC = PC + 16'd2;
                    end

                    3'b001: begin
                        bus_control = 4'b1000;
                        case (IR_out[5:3])
                            3'b000: R0_in = 1'b1;
                            3'b001: R1_in = 1'b1;
                            3'b010: R2_in = 1'b1;
                            3'b011: R3_in = 1'b1;
                            3'b100: R4_in = 1'b1;
                            3'b101: R5_in = 1'b1;
                            3'b110: begin end
                            3'b111: R7_in = 1'b1;
                            default: begin end
                        endcase
                        next_PC = PC + 16'd2;
                    end

                    3'b010: begin
                        bus_control = 4'b1000;
                        case (IR_out[5:3])
                            3'b000: R0_in = 1'b1;
                            3'b001: R1_in = 1'b1;
                            3'b010: R2_in = 1'b1;
                            3'b011: R3_in = 1'b1;
                            3'b100: R4_in = 1'b1;
                            3'b101: R5_in = 1'b1;
                            3'b110: begin end
                            3'b111: R7_in = 1'b1;
                            default: begin end
                        endcase
                        next_PC = PC + 16'd1;
                    end

                    3'b011: begin
                        bus_control = 4'b1000;
                        case (IR_out[5:3])
                            3'b000: R0_in = 1'b1;
                            3'b001: R1_in = 1'b1;
                            3'b010: R2_in = 1'b1;
                            3'b011: R3_in = 1'b1;
                            3'b100: R4_in = 1'b1;
                            3'b101: R5_in = 1'b1;
                            3'b110: begin end
                            3'b111: R7_in = 1'b1;
                            default: begin end
                        endcase
                        next_PC = PC + 16'd2;
                    end

                    3'b100: begin
                        bus_control = 4'b1000;
                        case (IR_out[5:3])
                            3'b000: R0_in = 1'b1;
                            3'b001: R1_in = 1'b1;
                            3'b010: R2_in = 1'b1;
                            3'b011: R3_in = 1'b1;
                            3'b100: R4_in = 1'b1;
                            3'b101: R5_in = 1'b1;
                            3'b110: begin end
                            3'b111: R7_in = 1'b1;
                            default: begin end
                        endcase
                        next_PC = PC + 16'd2;
                    end

                    3'b101: begin
                        bus_control = 4'b1000;
                        case (IR_out[5:3])
                            3'b000: R0_in = 1'b1;
                            3'b001: R1_in = 1'b1;
                            3'b010: R2_in = 1'b1;
                            3'b011: R3_in = 1'b1;
                            3'b100: R4_in = 1'b1;
                            3'b101: R5_in = 1'b1;
                            3'b110: begin end
                            3'b111: R7_in = 1'b1;
                            default: begin end
                        endcase
                        next_PC = PC + 16'd1;
                    end

                    3'b110: begin
                        // BEZ handled during tick 3/4 calculation above.
                    end

                    3'b111: begin
                        next_PC = PC + 16'd1;
                    end

                    default: begin
                    end
                endcase
            end

            default: begin
            end
        endcase
    end

    // Synchronous program counter reset/update.
    always @(posedge clk) begin
        if (rst)
            PC <= 16'd0;
        else if (fsm_enable)   // PC only moves when the tick FSM moves
            PC <= next_PC;
    end

endmodule
