`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.06.2026 23:48:05
// Design Name: 
// Module Name: updn_ctr
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


module updn_ctr (
    input clk, rst, ud, ld,
    input [3:0] load,
    output reg [3:0] count
);

always @(posedge clk) begin
    if (rst)
        count <= 0;
    else if (ld)
        count <= load;
    else if (ud)
        count <= count + 1;
    else
        count <= count - 1;
end

endmodule