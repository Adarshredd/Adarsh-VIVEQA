`timescale 1ns / 1ps
//=============================================================================
// Frequency Count Comparator
// Compares two 32-bit frequency counts and produces a 1-bit PUF response.
//   response_bit = 1 if count_a > count_b, else 0
//=============================================================================

module comparator (
    input  wire [31:0] count_a,
    input  wire [31:0] count_b,
    output wire        response_bit
);

    assign response_bit = (count_a > count_b) ? 1'b1 : 1'b0;

endmodule
