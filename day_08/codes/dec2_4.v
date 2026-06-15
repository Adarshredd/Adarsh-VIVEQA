`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 22:29:57
// Design Name: 
// Module Name: dec2_4
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


module dec2_4 (
    input  [1:0] a,
    output [3:0] y
);

assign y = {a[1] & a[0],
            a[1] & ~a[0],
            ~a[1] & a[0],
            ~a[1] & ~a[0]};

endmodule
