`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 10:08:03
// Design Name: 
// Module Name: simple_dual_port_ram_tb
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


module simple_dual_port_ram_tb();
reg clk;
reg [9:0]w_addr;
reg [9:0]r_addr;
reg we;
reg re;
reg [31:0]write_data;
wire [31:0]read_data;

simple_dual_port_ram dut(clk,w_addr,r_addr,we,re,write_data,read_data);

always #5clk=~clk;

initial begin
//Initializing all the INPUT Signals
clk=1'b0;
w_addr=10'h0;
r_addr=10'h0;
we=1'b0;
re=1'b0;
write_data=32'h0;

#12
//Test case Starts here
we=1'b1;
#12 w_addr=10'h1; write_data=32'h1;
#12 w_addr=10'h2; write_data=32'h2;
#12 w_addr=10'h3; write_data=32'h3;
#12 w_addr=10'h4; write_data=32'h4;
#12 w_addr=10'h5; write_data=32'h5;

#12 re=1'b1;
#12 w_addr=10'h6; write_data=32'h6; r_addr=10'h1; //Writing addr 6 data 6 and read from addr 1
#12 w_addr=10'h7; write_data=32'h7; r_addr=10'h2;
#12 w_addr=10'h8; write_data=32'h8; r_addr=10'h3;
#12 w_addr=10'h9; write_data=32'h9; r_addr=10'h4;
#12 w_addr=10'hA; write_data=32'hA; r_addr=10'h5;
#24 we=1'b0;re=1'b0;
$finish;

end
endmodule