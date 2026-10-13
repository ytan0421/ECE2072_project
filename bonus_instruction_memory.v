/*
 * Program for the Bonus Challenge. Load the same design on BOTH boards.
 *
 * Each board sends the number set on its own switches SW[8:1] (0-255) and
 * displays the number received from the other board:
 *
 *   loop:
 *     movi r0, <switches>   // immediate comes from SW[8:1], re-read every loop
 *     tx   r0               // send it to the other board
 *     movi r7, 0            // R7 is the display register
 *     add  r7, r6           // display = RX register (value from the other board)
 *     movi r1, 0
 *     bez  r1, loop         // always jump back
 *
 * So board A shows board B's switches, and board B shows board A's switches.
 */
module bonus_instruction_memory(
    input      [15:0] address,
    input      [7:0]  value,      // synchronised SW[8:1] from the top level
    output reg [8:0]  data
);

    always @(*) begin
        case (address)
            // loop: movi r0, value
            16'd0:  data = 9'b111000000;
            16'd1:  data = {1'b0, value};     // positive 9-bit immediate (0-255)

            // tx r0
            16'd2:  data = 9'b000000000;
            16'd3:  data = 9'b000000000;

            // movi r7, 0
            16'd4:  data = 9'b111111000;
            16'd5:  data = 9'b000000000;

            // add r7, r6
            16'd6:  data = 9'b001111110;
            16'd7:  data = 9'b000000000;

            // movi r1, 0
            16'd8:  data = 9'b111001000;
            16'd9:  data = 9'b000000000;

            // bez r1, -6  -> target = 10 + 2 + 2*(-6) = 0 (back to "loop")
            16'd10: data = 9'b110001000;
            16'd11: data = 9'b111111010;

            default: data = 9'b000000000;
        endcase
    end
endmodule