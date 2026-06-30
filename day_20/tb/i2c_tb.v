`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 11:46:26
// Design Name: 
// Module Name: i2c_tb
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


`timescale 1ns/1ps

module i2c_master_tb;

reg clk,rst,en,rw;
reg [6:0]slave_addr;
reg [7:0]reg_addr,data_wr;

wire [7:0]data_rd;
wire busy,ack_err,scl;
wire sda;

reg sda_drv,sda_oe;

assign sda=sda_oe?sda_drv:1'bz;

i2c_master dut(
.clk(clk),
.rst(rst),
.en(en),
.rw(rw),
.slave_addr(slave_addr),
.reg_addr(reg_addr),
.data_wr(data_wr),
.data_rd(data_rd),
.busy(busy),
.ack_err(ack_err),
.scl(scl),
.sda(sda)
);

always #5 clk=~clk;

// Simple slave model (ACK only)
always @(negedge scl) begin
    if(busy) begin
        sda_oe<=1;
        sda_drv<=0;
    end
end

always @(posedge scl) begin
    sda_oe<=0;
end

initial begin
    clk=0;
    rst=1;
    en=0;
    rw=0;
    sda_drv=1;
    sda_oe=0;

    slave_addr=7'h68;
    reg_addr=8'h75;
    data_wr=8'hAA;

    #20;
    rst=0;

    // Write transaction
    #20;
    rw=0;
    en=1;
    #10;
    en=0;

    wait(!busy);

    #100;

    // Read transaction
    rw=1;
    en=1;
    #10;
    en=0;

    wait(!busy);

    #100;

    $finish;
end

endmodule
