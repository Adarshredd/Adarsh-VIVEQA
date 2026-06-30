`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.06.2026 11:34:07
// Design Name: 
// Module Name: fifo
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


module fifo#(parameter DATA_WIDTH=8,
             parameter DEPTH=16
)(clk,rst,wr_en,rd_en,write_data,read_data,full,empty);
input clk,rst;
input rd_en,wr_en;
input[DATA_WIDTH-1:0]write_data;
output reg [DATA_WIDTH-1:0]read_data;
output full,empty;

reg [DATA_WIDTH-1:0]mem[0:DEPTH-1];

localparam PTR=$clog2(DEPTH);

reg [PTR:0]wr_ptr,rd_ptr;

assign empty=(wr_ptr==rd_ptr);
assign full=(wr_ptr[PTR]!=rd_ptr[PTR]) && (wr_ptr[PTR-1:0]==rd_ptr[PTR-1:0]);

always @ (posedge clk)begin
	if(rst)begin
		wr_ptr <=1'b0;
	end else if(wr_en && !full)begin
	    mem[wr_ptr[PTR-1:0]] <=write_data;
		wr_ptr <=wr_ptr + 1'b1;
	end
end

always @ (posedge clk)begin
	if(rst)begin
		rd_ptr <=1'b0;
	end else if (rd_en && !empty)begin
		read_data <=mem[rd_ptr[PTR-1:0]];
		rd_ptr <=rd_ptr+1;
	end
end 
endmodule
