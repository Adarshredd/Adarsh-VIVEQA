module dff_tb();
reg clk,rst;
reg D;

wire Q,Qb;

dff dut(clk,rst,D,Q,Qb);

always #5 clk=~clk;

initial begin
clk=1'b0;
rst=1'b0;
D=1'b0;
#12; rst=1'b1;
#12; rst=1'b0;
#12; D=1'b1;
#12; D=1'b0;
#12; D=1'b1;
#12; D=1'b1;
#12; D=1'b0;
#12; D=1'b0;
#12; D=1'b1;
#12; D=1'b1;
#12; D=1'b0;
#12; D=1'b1;
#12; D=1'b0;
#12; D=1'b1;
#12; D=1'b0;
#12; D=1'b1;
$finish;
end
endmodule
