module instruction_memory(
    input [15:0] address,
    output reg [8:0] data
);

    always @(*) begin

        case (address)

            16'd0:
                data = 9'b111000000;

            16'd1:
                data = 9'b000000101;

            16'd2:
                data = 9'b001000000;

            16'd3:
                data = 9'b000000000;

            16'd4:
                data = 9'b000000000;

            16'd5:
                data = 9'b000000000;


            default:
                data = 9'b000000000;

        endcase

    end

endmodule