`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2026 00:07:53
// Design Name: 
// Module Name: rc_adder4
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


module fa_1bit(
    input a,b,cin,
    output sum,cout
);

assign sum = a ^ b ^ cin;
assign cout = (a & b) | (b & cin) | (a & cin);

endmodule

module rc_adder4(
    input [3:0] a,b,
    input cin,
    output [3:0] sum,
    output cout
);

wire [2:0] c;

fa_1bit a1(a[0],b[0],cin,sum[0],c[0]);
fa_1bit a2(a[1],b[1],c[0],sum[1],c[1]);
fa_1bit a3(a[2],b[2],c[1],sum[2],c[2]);
fa_1bit a4(a[3],b[3],c[2],sum[3],cout);

endmodule
