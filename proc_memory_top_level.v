module proc_memory_top_level(
    input [9:0] SW,
    input [1:0] KEY,

    output [9:0] LEDR,

    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5,

    output [3:0] tick_FSM
);
	 wire [15:0] bus;
    wire [15:0] display;
	 wire [15:0] PC;
	 wire [8:0] din;

	 instruction_memory memory(
    .address(PC),
    .data(din)
	);

    proc_extension my_proc(

        .clk(~KEY[1]),
        .rst(~KEY[0]),

        .din(din),
		  .enable(SW[9]),
        .bus(bus),

        .display(display),
		  .PC(PC)
    );

    assign LEDR = bus[9:0];


    wire [3:0] digit0;
    wire [3:0] digit1;
    wire [3:0] digit2;
    wire [3:0] digit3;
    wire [3:0] digit4;

    assign digit4 = display / 10000;
    assign digit3 = (display % 10000) / 1000;
    assign digit2 = (display % 1000) / 100;
    assign digit1 = (display % 100) / 10;
    assign digit0 = display % 10;


    BCD hex0(
        .data(digit0),
        .X(HEX0)
    );

    BCD hex1(
        .data(digit1),
        .X(HEX1)
    );

    BCD hex2(
        .data(digit2),
        .X(HEX2)
    );

    BCD hex3(
        .data(digit3),
        .X(HEX3)
    );

    BCD hex4(
        .data(digit4),
        .X(HEX4)
    );

    tick_FSM my_FSM(

        .rst(~KEY[0]),
        .clk(~KEY[1]),
        .enable(SW[9]),
        .tick(tick_FSM)

    );

    BCD_HEX5 hex5(
        .tick(tick_FSM),
        .X(HEX5)
    );

endmodule