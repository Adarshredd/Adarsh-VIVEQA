`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2026 00:02:27
// Design Name: 
// Module Name: pri_enc8_3
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


module pri_enc8_3(
    input [7:0] in,
    output [2:0] out
);

assign out[0] = ~in[6] & (~in[4] & ~in[2] & in[1] | ~in[4] & in[3] | in[5]) | in[7];
assign out[1] = ~in[5] & ~in[4] & (in[2] | in[3]) | in[6] | in[7];
assign out[2] = in[4] | in[5] | in[6] | in[7];

endmodule
