`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:49:44
// Design Name: 
// Module Name: updn_ctr_tb
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


module updn_ctr_tb;

reg clk, rst, ud, ld;
reg [3:0] load;
wire [3:0] count;

updn_ctr dut(.clk(clk), .rst(rst), .ud(ud), .ld(ld), .load(load), .count(count));

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    ud  = 1;
    ld  = 0;
    load = 0;

    #10 rst = 0;
    #40 ud = 0;
    #30 load = 9; ld = 1;
    #10 ld = 0; ud = 1;

    #50 $finish;
end

endmodule
