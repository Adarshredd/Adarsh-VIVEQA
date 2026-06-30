module jk_ff_tb();
reg clk,rst;
reg J,K;

wire Q,Qb;

jk_ff dut(clk,rst,J,K,Q,Qb);

always #5 clk=~clk;

initial begin
clk=1'b0;
rst=1'b0;
J=1'b0;
K=1'b0;
#12; rst=1'b1;
#12; rst=1'b0;
#12; J=1'b0 ; K=1'b1;
#12; J=1'b1; K=1'b0;
#12; J=1'b0;K=1'b1;
#12; J=1'b0;K=1'b0;
#12; J=1'b1;K=1'b1;

$finish;
end
endmodule
