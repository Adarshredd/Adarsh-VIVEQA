`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:51:52
// Design Name: 
// Module Name: mux4_1
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


module mux4_1 (
    input  [3:0] a,
    input  [1:0] sel,
    output out
);

wire x, y;

mux2_1 m1(a[1:0], sel[0], x);
mux2_1 m2(a[3:2], sel[0], y);
mux2_1 m3({y, x}, sel[1], out);

endmodule

module mux2_1 (
    input  [1:0] a,
    input  sel,
    output out
);

assign out = sel ? a[1] : a[0];

endmodule