module alu(A,B,control,result,zero,negative);
input signed [3:0]A,B;
input [3:0]control;
output reg [3:0]result;
output zero,negative;

always @(*)begin
 case(control)
 4'd0:result=A+B;
 4'd1:result=A-B;
 4'd2:result=A&B;
 4'd3:result=A|B;
 4'd4:result=A^B;
 4'd5:result=A>>2;
 4'd6:result=A<<2;
 4'd7:result=A*B;
 4'd8:result=A+1;
 4'd9:result=A-1;
 4'd10:result=~A;
 4'd11:result=~B;
 default: result=4'd0;
 endcase
end

assign zero=~|result;
assign negative=result[3];

endmodule
