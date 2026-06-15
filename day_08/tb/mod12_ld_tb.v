`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:34:09
// Design Name: 
// Module Name: mod12_ld_tb
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


module mod12_ld_tb;

reg clk, rst, ld;
reg  [3:0] load;
wire [3:0] count;

mod12_ld dut(.clk(clk), .rst(rst), .ld(ld), .load(load), .count(count));

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    ld  = 0;
    load = 0;

    #10 rst = 0;

    #30 load = 7;
         ld = 1;

    #10 ld = 0;

    #80 $finish;
end

endmodule
