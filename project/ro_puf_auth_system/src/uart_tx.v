`timescale 1ns / 1ps
//=============================================================================
// UART Transmitter — 8N1, configurable baud rate
// Idle line is high. Sends LSB first.
//=============================================================================

module uart_tx #(
    parameter integer CLK_FREQ  = 24_000_000,
    parameter integer BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  tx_data,
    input  wire        tx_start,
    output reg         tx_out,
    output reg         tx_busy,
    output reg         tx_done
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer CBW = $clog2(CLKS_PER_BIT);

    localparam [2:0]
        S_IDLE  = 3'd0,
        S_START = 3'd1,
        S_DATA  = 3'd2,
        S_STOP  = 3'd3,
        S_DONE  = 3'd4;

    reg [2:0]       state;
    reg [CBW-1:0]   clk_cnt;
    reg [2:0]       bit_idx;
    reg [7:0]       shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            tx_out    <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
            clk_cnt   <= {CBW{1'b0}};
            bit_idx   <= 3'd0;
            shift_reg <= 8'h00;
        end else begin
            tx_done <= 1'b0;

            case (state)
                //-------------------------------------------------------------
                S_IDLE: begin
                    tx_out  <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy   <= 1'b1;
                        clk_cnt   <= {CBW{1'b0}};
                        state     <= S_START;
                    end
                end

                //-------------------------------------------------------------
                S_START: begin
                    tx_out <= 1'b0;  // Start bit
                    if (clk_cnt == CLKS_PER_BIT[CBW-1:0] - 1) begin
                        clk_cnt <= {CBW{1'b0}};
                        bit_idx <= 3'd0;
                        state   <= S_DATA;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                //-------------------------------------------------------------
                S_DATA: begin
                    tx_out <= shift_reg[0];  // LSB first
                    if (clk_cnt == CLKS_PER_BIT[CBW-1:0] - 1) begin
                        clk_cnt   <= {CBW{1'b0}};
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        if (bit_idx == 3'd7)
                            state <= S_STOP;
                        else
                            bit_idx <= bit_idx + 1;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                //-------------------------------------------------------------
                S_STOP: begin
                    tx_out <= 1'b1;  // Stop bit
                    if (clk_cnt == CLKS_PER_BIT[CBW-1:0] - 1) begin
                        clk_cnt <= {CBW{1'b0}};
                        state   <= S_DONE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                //-------------------------------------------------------------
                S_DONE: begin
                    tx_done <= 1'b1;
                    tx_busy <= 1'b0;
                    state   <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
