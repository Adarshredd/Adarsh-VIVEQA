`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 09:47:14
// Design Name: 
// Module Name: block_ram_tb
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


module block_ram_tb();
reg clk;
reg [9:0]addr;
reg we;
reg [31:0]write_data;
wire [31:0]read_data;

block_ram dut(clk,addr,we,write_data,read_data);

always #5 clk=~clk;

initial begin
clk=1'h0;
addr=10'h0;
we=1'h0;
write_data=32'h0;
#7 we=1'h1; write_data=32'h0;addr=10'h0;
#7 we=1'h1; write_data=32'h1;addr=10'h1;
#7 we=1'h1; write_data=32'h2;addr=10'h2;
#7 we=1'h1; write_data=32'h3;addr=10'h3;
#7 we=1'h1; write_data=32'h4;addr=10'h4;
#7 we=1'h1; write_data=32'h5;addr=10'h5;
#7 we=1'h1; write_data=32'h6;addr=10'h6;
#7 we=1'h1; write_data=32'h7;addr=10'h7;
#7 we=1'h1; write_data=32'h8;addr=10'h8;
#7 we=1'h1; write_data=32'h9;addr=10'h9;
#7 we=1'h1; write_data=32'hA;addr=10'hA;
#7 we=1'h1; write_data=32'hB;addr=10'hB;
#7 we=1'h0;
#7 addr=10'h0;
#7 addr=10'h1;
#7 addr=10'h2;
#7 addr=10'h3;
#7 addr=10'h4;
#7 addr=10'h5;
#7 addr=10'h6;
#7 addr=10'h7;
#7 addr=10'h8;
#7 addr=10'h9;
#7 addr=10'hA;
#7 addr=10'hB;
#20 $finish;
end

initial begin
$monitor("addr=%h,we=%h,write_data=%h,read_data=%h",addr,we,write_data,read_data);
end

endmodule

