`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 09:46:02
// Design Name: 
// Module Name: block_ram
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

module block_ram(clk,addr,we,write_data,read_data);
input clk;
input [9:0]addr;
input we;
input [31:0]write_data;
output  [31:0]read_data;

reg [31:0]mem[0:1023];

always@(posedge clk)begin
   if(we)
    mem[addr] <=write_data;
 
end
  assign read_data =mem[addr];
endmodule