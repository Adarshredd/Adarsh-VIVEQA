`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2026 00:09:10
// Design Name: 
// Module Name: rc_adder4_tb
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


module rc_adder4_tb;

reg [3:0] a,b;
reg cin;
wire [3:0] sum;
wire cout;

rc_adder4 dut(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));

initial begin
    a = 4'd0;  b = 4'd0;  cin = 0; #10;
    a = 4'd5;  b = 4'd3;  cin = 0; #10;
    a = 4'd8;  b = 4'd7;  cin = 0; #10;
    a = 4'd9;  b = 4'd6;  cin = 1; #10;
    a = 4'd15; b = 4'd15; cin = 0; #10;
    $finish;
end

endmodule