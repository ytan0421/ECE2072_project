/*
 * ECE2072 Bonus Challenge top level (DE10-Lite) - serial (UART) version.
 *
 * The same design goes on both boards. Uses the Arduino header (female sockets),
 * so ordinary male-to-male jumper wires plug straight in. Port names match the
 * project's existing pin assignments:
 *   UART_RXD = PIN_AB5 = Arduino socket D0   (serial in)
 *   UART_TXD = PIN_AB6 = Arduino socket D1   (serial out)
 * Only 3 wires (D0 and D1 crossed over):
 *   Board A D1 (TX) -> Board B D0 (RX)
 *   Board B D1 (TX) -> Board A D0 (RX)
 *   Board A GND     -> Board B GND
 *
 * Controls: SW9 = run/pause, KEY0 = reset, SW[8:1] = number to send (0-255),
 *           SW0 = LED debug view.
 *
 * The processor (proc_bonus) is unchanged: it still talks a request/acknowledge
 * handshake, and uart_link turns that into a 16-bit serial frame at 9600 baud.
 */
module bonus_top_level(
	input        MAX10_CLK1_50,
	input  [9:0] SW,
	input  [1:0] KEY,
	output       UART_TXD,
	input        UART_RXD,
	output [9:0] LEDR,
	output [7:0] HEX0,
	output [7:0] HEX1,
	output [7:0] HEX2,
	output [7:0] HEX3,
	output [7:0] HEX4,
	output [6:0] HEX5
	);

	wire        clk_10hz;
	wire [8:0]  din;
	wire [15:0] bus;
	wire [15:0] display;
	wire [15:0] PC;
	wire [3:0]  tick;

	// Handshake signals between the processor (10 Hz) and the UART (50 MHz)
	wire [15:0] tx_data, rx_data;
	wire        tx_req, tx_ack, rx_req, rx_ack;
	wire        txd;
	wire [15:0] r6;

	clock_divider #(.OUT_HZ(10)) div(
		.clk_in(MAX10_CLK1_50),
		.clk_out(clk_10hz)
		);

	// Synchronise the reset button and run switch to the processor clock.
	// SW[8:1] = the number this board sends (also synchronised).
	reg rst_ff1, rst_sync, en_ff1, en_sync;
	reg [7:0] value_ff1, value_sync;
	always @(posedge clk_10hz) begin
		rst_ff1    <= ~KEY[0];
		rst_sync   <= rst_ff1;
		en_ff1     <= SW[9];
		en_sync    <= en_ff1;
		value_ff1  <= SW[8:1];
		value_sync <= value_ff1;
	end

	// Same reset, synchronised to the 50 MHz UART clock.
	reg rst50_ff1, rst50_sync;
	always @(posedge MAX10_CLK1_50) begin
		rst50_ff1  <= rst_sync;
		rst50_sync <= rst50_ff1;
	end

	assign UART_TXD = txd;

	bonus_instruction_memory memory(
		.address(PC),
		.value(value_sync),
		.data(din)
		);

	proc_bonus my_proc(
		.clk(clk_10hz),
		.rst(rst_sync),
		.enable(en_sync),
		.din(din),

		.rx_data(rx_data),
		.rx_req(rx_req),
		.tx_ack(tx_ack),

		.tx_data(tx_data),
		.tx_req(tx_req),
		.rx_ack(rx_ack),

		.bus(bus),
		.display(display),
		.PC(PC),
		.tick(tick),
		.R6(r6)
		);

	uart_link #(.CLKS_PER_BIT(5208)) link(
		.clk(MAX10_CLK1_50),
		.rst(rst50_sync),
		.tx_req(tx_req),
		.tx_data(tx_data),
		.tx_ack(tx_ack),
		.rx_data(rx_data),
		.rx_req(rx_req),
		.rx_ack(rx_ack),
		.txd(txd),
		.rxd(UART_RXD)
		);

	// ------------------------------------------------------------
	// Debug view (SW[0] = 1). SW[0] = 0 gives the normal bus display.
	//   LEDR9    : level on UART_RXD  (should be ON when the other board's TX is connected)
	//   LEDR8    : level on UART_TXD  (should be ON when idle)
	//   LEDR7    : flips every time a frame is SENT
	//   LEDR6    : flips every time a frame is RECEIVED
	//   LEDR5..0 : low 6 bits of R6, the RX register (42 = 101010)
	// ------------------------------------------------------------
	reg tx_ack_d, rx_req_d, tx_flip, rx_flip;
	always @(posedge MAX10_CLK1_50) begin
		tx_ack_d <= tx_ack;
		rx_req_d <= rx_req;
		if (tx_ack & ~tx_ack_d) tx_flip <= ~tx_flip;
		if (rx_req & ~rx_req_d) rx_flip <= ~rx_flip;
	end

	assign LEDR = SW[0] ? {UART_RXD, UART_TXD, tx_flip, rx_flip, r6[5:0]} : bus[9:0];

	signed_display #(.SIGNED(1)) disp(
		.value(display),
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3),
		.HEX4(HEX4)
		);

	BCD_HEX5 hex5(
		.tick(tick),
		.X(HEX5)
		);

endmodule