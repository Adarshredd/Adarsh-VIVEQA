`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:27:48
// Design Name: 
// Module Name: mod12_ld
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


module mod12_ld (
    input        clk, rst, ld,
    input  [3:0] load,
    output reg [3:0] count
);

always @(posedge clk) begin
    if (rst)
        count <= 0;
    else if (ld)
        count <= load;
    else
        count <= (count == 11) ? 0 : count + 1;
end

endmodule