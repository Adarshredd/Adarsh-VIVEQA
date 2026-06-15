`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:55:29
// Design Name: 
// Module Name: sr_latch_tb
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


module sr_latch_tb;

reg s, r;
wire q, q_bar;

sr_latch dut(.s(s), .r(r), .q(q), .q_bar(q_bar));

initial begin
    s = 0; r = 0; #10;  // Hold
    s = 1; r = 0; #10;  // Set
    s = 0; r = 0; #10;  // Hold
    s = 0; r = 1; #10;  // Reset
    s = 0; r = 0; #10;  // Hold
    s = 1; r = 1; #10;  // Invalid

    $finish;
end

endmodule
