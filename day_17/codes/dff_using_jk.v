module dff(clk,rst,D,Q,Qb);
input clk,rst;
input D;
output Q,Qb;

wire Db;

not(Db,D);

jk_ff jk2d(.clk(clk),.rst(rst),.J(D),.K(Db),.Q(Q),.Qb(Qb));

endmodule
