module alu_tb();
reg signed[3:0]A,B;
reg [3:0]control;
wire [3:0]result;
wire zero,negative;

alu dut(A,B,control,result,zero,negative);

initial begin
A=4'd0;B=4'd0;control=4'd0;
#5 A=4'd1;B=4'd2;control=4'd0;
#5 A=4'd2;B=4'd1;control=4'd1;
#5 A=4'd1;B=4'd2;control=4'd2;
#5 A=4'd1;B=4'd2;control=4'd3;
#5 A=4'd1;B=4'd2;control=4'd4;
#5 A=4'd1;B=4'd2;control=4'd5;
#5 A=4'd1;B=4'd2;control=4'd6;
#5 A=4'd1;B=4'd2;control=4'd7;
#5 A=4'd1;B=4'd2;control=4'd8;
#5 A=4'd1;B=4'd2;control=4'd9;
#5 A=4'd1;B=4'd2;control=4'd10;
#5 A=4'd1;B=4'd2;control=4'd11;
#5 $finish;

end
endmodule
