`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:59:19
// Design Name: 
// Module Name: fa_1bit_tb
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


module fa_1bit_tb;

reg a,b,cin;
wire sum,cout;

fa_1bit dut(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));

initial begin
    {a,b,cin} = 3'b000; #10;
    {a,b,cin} = 3'b001; #10;
    {a,b,cin} = 3'b010; #10;
    {a,b,cin} = 3'b011; #10;
    {a,b,cin} = 3'b100; #10;
    {a,b,cin} = 3'b101; #10;
    {a,b,cin} = 3'b110; #10;
    {a,b,cin} = 3'b111; #10;
    $finish;
end

endmodule