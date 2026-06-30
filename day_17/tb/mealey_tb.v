module mealey_tb();
reg clk,rst;
reg ip;
wire op;

mealey_fsm dut(clk,rst,ip,op);

always #5 clk=~clk;

initial begin
clk=1'b0;
rst=1'b0;
ip=1'b0;
#12; rst=1'b1;
#12; rst=1'b0;

#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b0;
#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b0;
#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b1;
#7 ip=1'b0;
#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b0;
#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b0;
#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b1;
#7 ip=1'b0;
#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b0;
#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b0;
#7 ip=1'b1;
#7 ip=1'b1;
#7 ip=1'b0;

$finish;
end

endmodule
