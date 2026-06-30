`timescale 1ns / 1ps
//=============================================================================
// UART Receiver — 8N1, configurable baud rate
// 2-FF synchronizer on rx_in. Mid-bit sampling for noise immunity.
//=============================================================================

module uart_rx #(
    parameter integer CLK_FREQ  = 24_000_000,
    parameter integer BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        rx_in,
    output reg  [7:0]  rx_data,
    output reg         rx_valid
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;
    localparam integer CBW          = $clog2(CLKS_PER_BIT);

    localparam [2:0]
        S_IDLE  = 3'd0,
        S_START = 3'd1,
        S_DATA  = 3'd2,
        S_STOP  = 3'd3;

    //-------------------------------------------------------------------------
    // 2-FF synchronizer
    //-------------------------------------------------------------------------
    reg rx_ff0, rx_ff1;

    always @(posedge clk) begin
        if (rst) begin
            rx_ff0 <= 1'b1;
            rx_ff1 <= 1'b1;
        end else begin
            rx_ff0 <= rx_in;
            rx_ff1 <= rx_ff0;
        end
    end

    //-------------------------------------------------------------------------
    // Receiver state machine
    //-------------------------------------------------------------------------
    reg [2:0]     state;
    reg [CBW-1:0] clk_cnt;
    reg [2:0]     bit_idx;
    reg [7:0]     shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            clk_cnt   <= {CBW{1'b0}};
            bit_idx   <= 3'd0;
            shift_reg <= 8'h00;
            rx_data   <= 8'h00;
            rx_valid  <= 1'b0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                //-------------------------------------------------------------
                S_IDLE: begin
                    clk_cnt <= {CBW{1'b0}};
                    bit_idx <= 3'd0;
                    if (rx_ff1 == 1'b0)   // Falling edge = start bit
                        state <= S_START;
                end

                //-------------------------------------------------------------
                // Sample at mid-point of start bit to verify
                S_START: begin
                    if (clk_cnt == HALF_BIT[CBW-1:0] - 1) begin
                        clk_cnt <= {CBW{1'b0}};
                        if (rx_ff1 == 1'b0)
                            state <= S_DATA;
                        else
                            state <= S_IDLE;  // False start
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                //-------------------------------------------------------------
                // Sample each data bit at its mid-point
                S_DATA: begin
                    if (clk_cnt == CLKS_PER_BIT[CBW-1:0] - 1) begin
                        clk_cnt <= {CBW{1'b0}};
                        shift_reg <= {rx_ff1, shift_reg[7:1]};  // LSB first
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
                    if (clk_cnt == CLKS_PER_BIT[CBW-1:0] - 1) begin
                        clk_cnt <= {CBW{1'b0}};
                        if (rx_ff1 == 1'b1) begin  // Valid stop bit
                            rx_data  <= shift_reg;
                            rx_valid <= 1'b1;
                        end
                        state <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
