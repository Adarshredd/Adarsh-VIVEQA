module mealey_fsm(clk,rst,ip,op);
input clk,rst;
input ip;
output op;

wire ipb,d1,d0,q0,qb0,q1,qb1;
assign ipb=~ip;

assign d1=q1 & qb0 & ipb | qb1 & q0 &ipb;
assign d0=q1 & qb0 | ip;
assign op= q0 & q1 & ip;

dff dff0(clk,rst,d0,q0,qb0);
dff dff1(clk,rst,d1,q1,qb1);

endmodule
