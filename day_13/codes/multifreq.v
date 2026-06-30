`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2026 12:42:09
// Design Name: 
// Module Name: multifreq
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


module multifreq(clk,led);
input clk;
output reg [3:0]led;

reg [23:0]counter;

always@(posedge clk)begin //8HZ
  if(counter ==24'd1_499_999)begin
        counter <=24'd0;
		led[0] <=~led[0];
  end else counter <=counter +1;
end 

always@(posedge led[0])begin //4HZ
	led[1] <=~led[1];
end

always@(posedge led[1])begin //2HZ
	led[2] <=~led[2];
end

always@(posedge led[2])begin //3HZ
	led[3]<=~led[3];
end

endmodule
