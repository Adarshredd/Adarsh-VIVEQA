module vending_machine_tb();
reg clk,rst;
reg [1:0]coin;
wire D,C;

vending_machine dut(clk,rst,coin,D,C);

always #5 clk=~clk;

initial begin
clk=1'b0;
rst=1'b0;
coin=2'b0;
#12; rst=1'b1;
#12; rst=1'b0;

#7 coin=2'b00;
#7 coin=2'b01;
#7 coin=2'b10;
#7 coin=2'b01;
#7 coin=2'b10;
#7 coin=2'b10;
#7 coin=2'b00;
#7 coin=2'b00;
#7 coin=2'b01;
#7 coin=2'b01;
#7 coin=2'b01;
#7 coin=2'b00;
#7 coin=2'b00;
#7 coin=2'b10;
#7 coin=2'b00;
#7 coin=2'b10;
#7 $finish;
end
endmodule
