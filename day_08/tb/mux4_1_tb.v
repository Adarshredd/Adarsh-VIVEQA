`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:52:49
// Design Name: 
// Module Name: mux4_1_tb
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


module mux4_1_tb;

reg  [3:0] a;
reg  [1:0] sel;
wire out;

mux4_1 dut(.a(a), .sel(sel), .out(out));

initial begin
    a = 4'b1010;

    sel = 0; #10;
    sel = 1; #10;
    sel = 2; #10;
    sel = 3; #10;

    $finish;
end

endmodule
