`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 22:46:55
// Design Name: 
// Module Name: jk_ff
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module jk_ff (
    input  j, k, clk,
    output reg q, q_bar
);

parameter HOLD   = 2'b00,
          TOGGLE = 2'b01,
          SET    = 2'b10,
          RESET  = 2'b11;

always @(posedge clk) begin
    case ({j, k})
        HOLD   : q <= q;
        TOGGLE : q <= ~q;
        SET    : q <= 1'b1;
        RESET  : q <= 1'b0;
    endcase
end

always @(*)
    q_bar = ~q;

endmodule
