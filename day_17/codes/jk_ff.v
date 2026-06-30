module jk_ff(clk,rst,J,K,Q,Qb);
input clk,rst;
input J,K;
output reg Q;
output Qb;

always @(posedge clk)begin
 if(rst)
    Q<=1'b0;
 else begin
	case({J,K})
    2'b00: Q<=Q;
	2'b01: Q<=1'b0;
	2'b10: Q<=1'b1;
	2'b11: Q<=~Q;
	endcase
	end
end
assign Qb=~Q;
endmodule
