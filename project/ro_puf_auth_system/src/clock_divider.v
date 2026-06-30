`timescale 1ns / 1ps
//=============================================================================
// Clock Divider
// Generates a 50%-duty-cycle clock output from the system clock.
// DIV_FACTOR must be an even integer >= 2.
// Output frequency = clk frequency / DIV_FACTOR
//=============================================================================

module clock_divider #(
    parameter integer DIV_FACTOR = 2
)(
    input  wire clk,
    input  wire rst,
    output reg  clk_out
);

    localparam integer HALF = DIV_FACTOR / 2;
    localparam integer CW   = (HALF <= 1) ? 1 : $clog2(HALF);

    reg [CW-1:0] counter;

    always @(posedge clk) begin
        if (rst) begin
            counter <= {CW{1'b0}};
            clk_out <= 1'b0;
        end else begin
            if (counter == HALF[CW-1:0] - 1) begin
                counter <= {CW{1'b0}};
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
