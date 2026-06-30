`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2026 10:53:48
// Design Name: 
// Module Name: rx_tb
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

module rx_tb();

reg clk, rst;
reg rx;

wire [7:0] rx_data;
wire rx_done;
wire parity_err;
wire frame_err;

parameter CLKS_PER_BIT = 2500;

uart_rx dut(clk, rst, rx, rx_data, rx_done, parity_err, frame_err);

always #20.8 clk = ~clk;

initial begin
    clk = 1'b0;
    rst = 1'b0;
    rx  = 1'b1;

    #40 rst = 1'b1;
    #40 rst = 1'b0;

    #100;

    rx = 1'b0;
    #(CLKS_PER_BIT*41.6);

    rx = 1'b1; #(CLKS_PER_BIT*41.6);
    rx = 1'b1; #(CLKS_PER_BIT*41.6);
    rx = 1'b0; #(CLKS_PER_BIT*41.6);
    rx = 1'b1; #(CLKS_PER_BIT*41.6);
    rx = 1'b0; #(CLKS_PER_BIT*41.6);
    rx = 1'b1; #(CLKS_PER_BIT*41.6);
    rx = 1'b0; #(CLKS_PER_BIT*41.6);
    rx = 1'b1; #(CLKS_PER_BIT*41.6);

    rx = 1'b1;
    #(CLKS_PER_BIT*41.6);

    rx = 1'b1;
    #(CLKS_PER_BIT*41.6);

    #100000;

    $stop;
end

endmodule