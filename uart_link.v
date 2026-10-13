/*
 * ECE2072 Bonus - serial (UART) link between two x72 boards.
 *
 * Replaces the 18-wire parallel bus with ONE wire per direction.
 * Frame: 1 start bit (0), 16 data bits (LSB first), 1 stop bit (1)  = 18 bits.
 * Line is high (1) when idle.
 *
 * Runs on the 50 MHz board clock. The processor runs on the 10 Hz clock, so the
 * processor side uses the same 4-phase request/acknowledge handshake that
 * proc_bonus already has, and every signal crossing between the two clock
 * domains goes through two flip-flops:
 *
 *   TX: proc raises tx_req (tx_data held stable) -> this module sends the frame
 *       -> raises tx_ack -> proc lowers tx_req -> this module lowers tx_ack.
 *   RX: a complete frame is placed on rx_data and rx_req is raised -> proc loads
 *       R6 and raises rx_ack -> rx_req is lowered -> proc lowers rx_ack.
 *       A frame that arrives while the previous handshake is still running is
 *       dropped (the sender is far slower than the handshake, so this does not
 *       happen in normal use).
 */
module uart_link(clk, rst, tx_req, tx_data, tx_ack, rx_data, rx_req, rx_ack, txd, rxd);

	parameter CLKS_PER_BIT = 5208;   // 50 MHz / 9600 baud

	input             clk, rst;

	input             tx_req;        // from proc (10 Hz domain)
	input      [15:0] tx_data;       // from proc, stable while tx_req is high
	output reg        tx_ack;        // to proc

	output reg [15:0] rx_data;       // to proc
	output reg        rx_req;        // to proc
	input             rx_ack;        // from proc (10 Hz domain)

	output reg        txd;           // serial out (to the other board's rxd)
	input             rxd;           // serial in  (from the other board's txd)

	localparam T_IDLE = 2'd0, T_SEND = 2'd1, T_DONE = 2'd2;
	localparam R_IDLE = 2'd0, R_START = 2'd1, R_DATA = 2'd2, R_STOP = 2'd3;

	// Two-flip-flop synchronisers for everything coming from another clock domain.
	reg tx_req_ff1, tx_req_sync;
	reg rx_ack_ff1, rx_ack_sync;
	reg rxd_ff1,    rxd_sync;

	always @(posedge clk) begin
		if (rst) begin
			tx_req_ff1  <= 1'b0;
			tx_req_sync <= 1'b0;
			rx_ack_ff1  <= 1'b0;
			rx_ack_sync <= 1'b0;
			rxd_ff1     <= 1'b1;
			rxd_sync    <= 1'b1;
		end
		else begin
			tx_req_ff1  <= tx_req;
			tx_req_sync <= tx_req_ff1;
			rx_ack_ff1  <= rx_ack;
			rx_ack_sync <= rx_ack_ff1;
			rxd_ff1     <= rxd;
			rxd_sync    <= rxd_ff1;
		end
	end

	// ------------------------------------------------------------
	// Transmitter
	// ------------------------------------------------------------
	reg [1:0]  tx_state;
	reg [17:0] tx_shift;
	reg [4:0]  tx_bits_left;
	reg [15:0] tx_count;

	always @(posedge clk) begin
		if (rst) begin
			tx_state     <= T_IDLE;
			tx_shift     <= 18'h3FFFF;
			tx_bits_left <= 5'd0;
			tx_count     <= 16'd0;
			tx_ack       <= 1'b0;
			txd          <= 1'b1;
		end
		else begin
			case (tx_state)
				T_IDLE: begin
					txd <= 1'b1;
					if (tx_req_sync) begin
						tx_shift     <= {1'b1, tx_data, 1'b0};   // stop, data, start
						tx_bits_left <= 5'd18;
						tx_count     <= 16'd0;
						tx_state     <= T_SEND;
					end
				end

				T_SEND: begin
					txd <= tx_shift[0];
					if (tx_count == CLKS_PER_BIT - 1) begin
						tx_count     <= 16'd0;
						tx_shift     <= {1'b1, tx_shift[17:1]};
						tx_bits_left <= tx_bits_left - 5'd1;
						if (tx_bits_left == 5'd1) begin
							tx_ack   <= 1'b1;                     // frame finished
							tx_state <= T_DONE;
						end
					end
					else begin
						tx_count <= tx_count + 16'd1;
					end
				end

				T_DONE: begin
					txd <= 1'b1;
					if (!tx_req_sync) begin                      // proc has seen the ack
						tx_ack   <= 1'b0;
						tx_state <= T_IDLE;
					end
				end

				default: tx_state <= T_IDLE;
			endcase
		end
	end

	// ------------------------------------------------------------
	// Receiver (samples each bit in the middle of the bit period)
	// ------------------------------------------------------------
	reg [1:0]  rx_state;
	reg [15:0] rx_shift;
	reg [3:0]  rx_bit;
	reg [15:0] rx_count;

	always @(posedge clk) begin
		if (rst) begin
			rx_state <= R_IDLE;
			rx_shift <= 16'd0;
			rx_bit   <= 4'd0;
			rx_count <= 16'd0;
			rx_data  <= 16'd0;
			rx_req   <= 1'b0;
		end
		else begin
			// Handshake with the processor: drop the request once it is acknowledged.
			if (rx_req && rx_ack_sync)
				rx_req <= 1'b0;

			case (rx_state)
				R_IDLE: begin
					rx_count <= 16'd0;
					if (!rxd_sync)                              // falling edge = start bit
						rx_state <= R_START;
				end

				R_START: begin
					if (rx_count == (CLKS_PER_BIT / 2) - 1) begin
						rx_count <= 16'd0;
						rx_bit   <= 4'd0;
						if (!rxd_sync)
							rx_state <= R_DATA;                 // genuine start bit
						else
							rx_state <= R_IDLE;                 // glitch, ignore
					end
					else begin
						rx_count <= rx_count + 16'd1;
					end
				end

				R_DATA: begin
					if (rx_count == CLKS_PER_BIT - 1) begin
						rx_count <= 16'd0;
						rx_shift <= {rxd_sync, rx_shift[15:1]};  // LSB first
						if (rx_bit == 4'd15)
							rx_state <= R_STOP;
						else
							rx_bit <= rx_bit + 4'd1;
					end
					else begin
						rx_count <= rx_count + 16'd1;
					end
				end

				R_STOP: begin
					if (rx_count == CLKS_PER_BIT - 1) begin
						rx_count <= 16'd0;
						rx_state <= R_IDLE;
						// Valid stop bit and previous word already collected: hand it over.
						if (rxd_sync && !rx_req && !rx_ack_sync) begin
							rx_data <= rx_shift;
							rx_req  <= 1'b1;
						end
					end
					else begin
						rx_count <= rx_count + 16'd1;
					end
				end

				default: rx_state <= R_IDLE;
			endcase
		end
	end

endmodule
