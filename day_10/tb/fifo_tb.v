`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 12:24:41
// Design Name: 
// Module Name: fifo_tb
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


module fifo_tb();
parameter DATA_WIDTH=8;
parameter DEPTH=16;

reg clk,rst;
reg rd_en,wr_en;
reg [DATA_WIDTH-1:0]write_data;
wire [DATA_WIDTH-1:0]read_data;
wire full,empty;

fifo #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH))
dut(clk,rst,wr_en,rd_en,write_data,read_data,full,empty);
integer i;
always #5 clk=~clk;

initial begin
clk=1'b0;
rst=1'b0;
rd_en=1'b0;
wr_en=1'b0;
write_data=8'h0;
#12 rst=1'b1;
#12 rst=1'b0;

#12 wr_en=1;
for(i=0;i<16;i=i+1)begin
write_data=i;
#12;
end
#12 wr_en=0; rd_en=1'b1;
#200;
$finish;
end
endmodule

