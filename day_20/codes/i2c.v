`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 10:41:38
// Design Name: 
// Module Name: i2c
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


module i2c_master#(
parameter CLK_DIV=4
)(
input clk,rst,en,rw,
input [6:0]slave_addr,
input [7:0]reg_addr,data_wr,
output reg [7:0]data_rd,
output reg busy,ack_err,
output scl,
inout sda
);

localparam IDLE=0,
           START=1,
           WR_ADDR=2,
           WR_ADDR_ACK=3,
           WR_REG=4,
           WR_REG_ACK=5,
           WR_DATA=6,
           WR_DATA_ACK=7,
           REP_START=8,
           RD_ADDR=9,
           RD_ADDR_ACK=10,
           RD_DATA=11,
           RD_NACK=12,
           STOP=13;

reg [3:0]state;
reg [7:0]shift_reg;
reg [7:0]next_byte;
reg [2:0]bit_cnt;
reg [1:0]phase;
reg rw_save;
reg sda_out,sda_oe,scl_en;

assign sda=sda_oe?sda_out:1'bz;
assign scl=scl_en?phase[1]:1'b1;

always@(posedge clk) begin

if(rst) begin
    state<=IDLE;
    shift_reg<=0;
    next_byte<=0;
    bit_cnt<=7;
    phase<=0;
    rw_save<=0;
    data_rd<=0;
    busy<=0;
    ack_err<=0;
    sda_out<=1;
    sda_oe<=1;
    scl_en<=0;
end
else begin

ack_err<=0;

if(state==IDLE)
    phase<=0;
else
    phase<=phase+1;

case(state)

IDLE: begin
    busy<=0;
    scl_en<=0;
    sda_oe<=1;
    sda_out<=1;

    if(en) begin
        busy<=1;
        rw_save<=rw;
        shift_reg<={slave_addr,1'b0};
        bit_cnt<=7;
        phase<=0;
        state<=START;
    end
end

START: begin
    scl_en<=0;

    case(phase)
        0:sda_out<=1;
        2:sda_out<=0;
        3:begin
            scl_en<=1;
            sda_out<=shift_reg[7];
            phase<=0;
            state<=WR_ADDR;
        end
    endcase
end


WR_ADDR,
WR_REG,
WR_DATA,
RD_ADDR: begin

    if(phase==0) begin
        sda_oe<=1;
        sda_out<=shift_reg[7];
        shift_reg<={shift_reg[6:0],1'b0};
    end

    if(phase==3) begin
        if(bit_cnt)
            bit_cnt<=bit_cnt-1;
        else begin
            bit_cnt<=7;
            phase<=0;

            case(state)
                WR_ADDR:state<=WR_ADDR_ACK;
                WR_REG:state<=WR_REG_ACK;
                WR_DATA:state<=WR_DATA_ACK;
                RD_ADDR:state<=RD_ADDR_ACK;
            endcase
        end
    end
end

WR_ADDR_ACK,
WR_REG_ACK,
WR_DATA_ACK,
RD_ADDR_ACK: begin

    if(phase==0) begin
        sda_oe<=0;
        sda_out<=1;
    end

    if(phase==3) begin

        if(sda!==1'b0) begin
            ack_err<=1;
            phase<=0;
            state<=STOP;
        end
        else begin

            phase<=0;

            case(state)

            WR_ADDR_ACK: begin
                shift_reg<=reg_addr;
                state<=WR_REG;
            end

            WR_REG_ACK: begin
                if(!rw_save) begin
                    shift_reg<=data_wr;
                    state<=WR_DATA;
                end
                else begin
                    shift_reg<={slave_addr,1'b1};
                    bit_cnt<=7;
                    state<=REP_START;
                end
            end

            WR_DATA_ACK: begin
                state<=STOP;
            end

            RD_ADDR_ACK: begin
                shift_reg<=0;
                bit_cnt<=7;
                state<=RD_DATA;
            end

            endcase
        end
    end
end


REP_START: begin
    scl_en<=0;

    case(phase)
        0:sda_out<=1;
        2:sda_out<=0;
        3:begin
            scl_en<=1;
            sda_oe<=1;
            sda_out<=shift_reg[7];
            phase<=0;
            state<=RD_ADDR;
        end
    endcase
end

RD_DATA: begin
    sda_oe<=0;

    if(phase==3) begin
        if(bit_cnt) begin
            shift_reg<={shift_reg[6:0],sda};
            bit_cnt<=bit_cnt-1;
        end
        else begin
            data_rd<={shift_reg[6:0],sda};
            bit_cnt<=7;
            phase<=0;
            state<=RD_NACK;
        end
    end
end

RD_NACK: begin
    sda_oe<=1;
    sda_out<=1;

    if(phase==3) begin
        phase<=0;
        state<=STOP;
    end
end

STOP: begin
    scl_en<=0;

    case(phase)
        0:sda_out<=0;
        2:sda_out<=1;
        3:begin
            busy<=0;
            sda_oe<=1;
            sda_out<=1;
            phase<=0;
            state<=IDLE;
        end
    endcase
end

default: state<=IDLE;

endcase

end

end

endmodule
