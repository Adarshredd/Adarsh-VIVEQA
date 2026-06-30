`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 14:38:40
// Design Name: 
// Module Name: adjustable_blink
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


//============================================================================
// Module: adjustable_blink
// Description: Single-LED blinker with button-adjustable speed.
//              5 speed levels: 0.5 Hz, 1 Hz, 2 Hz, 4 Hz, 8 Hz.
//              btn[0] increases speed, btn[1] decreases speed.
//              Includes counter-based button debounce (20 ms at 24 MHz).
//
// Clock: 24 MHz (41.667 ns period)
//============================================================================

module adjustable_blink#(
    // Debounce count: 20 ms × 24 MHz = 480,000 cycles
    parameter DEBOUNCE_MAX = 480_000,

    // Half-period divider values for each speed level
    parameter DIV_0 = 24_000_000 - 1,  // 0.5 Hz → 23,999,999
    parameter DIV_1 = 12_000_000 - 1,  // 1.0 Hz → 11,999,999
    parameter DIV_2 =  6_000_000 - 1,  // 2.0 Hz →  5,999,999
    parameter DIV_3 =  3_000_000 - 1,  // 4.0 Hz →  2,999,999
    parameter DIV_4 =  1_500_000 - 1   // 8.0 Hz →  1,499,999
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] btn,    // btn[0]=faster, btn[1]=slower
    output reg        led
);

    // -----------------------------------------------------------------------
    // Speed index register (0 to 4)
    // -----------------------------------------------------------------------
    reg [2:0] speed_index;

    // -----------------------------------------------------------------------
    // Lookup table: speed index → half-period divider value
    // -----------------------------------------------------------------------
    reg [24:0] half_period;

    always @(*) begin
        case (speed_index)
            3'd0:    half_period = DIV_0;  // 0.5 Hz
            3'd1:    half_period = DIV_1;  // 1.0 Hz
            3'd2:    half_period = DIV_2;  // 2.0 Hz
            3'd3:    half_period = DIV_3;  // 4.0 Hz
            3'd4:    half_period = DIV_4;  // 8.0 Hz
            default: half_period = DIV_1;  // default 1 Hz
        endcase
    end

    // -----------------------------------------------------------------------
    // Button debounce - btn[0] (faster)
    // -----------------------------------------------------------------------
    reg [18:0] db_cnt_0;
    reg        btn0_reg;
    reg        btn0_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            db_cnt_0 <= 19'd0;
            btn0_reg <= 1'b0;
        end else begin
            if (btn[0] != btn0_reg) begin
                if (db_cnt_0 == DEBOUNCE_MAX - 1) begin
                    btn0_reg <= btn[0];
                    db_cnt_0 <= 19'd0;
                end else begin
                    db_cnt_0 <= db_cnt_0 + 19'd1;
                end
            end else begin
                db_cnt_0 <= 19'd0;
            end
        end
    end

    // Edge detection for btn[0]
    always @(posedge clk or posedge rst) begin
        if (rst)
            btn0_prev <= 1'b0;
        else
            btn0_prev <= btn0_reg;
    end

    wire btn0_press = btn0_reg & ~btn0_prev;  // rising edge

    // -----------------------------------------------------------------------
    // Button debounce - btn[1] (slower)
    // -----------------------------------------------------------------------
    reg [18:0] db_cnt_1;
    reg        btn1_reg;
    reg        btn1_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            db_cnt_1 <= 19'd0;
            btn1_reg <= 1'b0;
        end else begin
            if (btn[1] != btn1_reg) begin
                if (db_cnt_1 == DEBOUNCE_MAX - 1) begin
                    btn1_reg <= btn[1];
                    db_cnt_1 <= 19'd0;
                end else begin
                    db_cnt_1 <= db_cnt_1 + 19'd1;
                end
            end else begin
                db_cnt_1 <= 19'd0;
            end
        end
    end

    // Edge detection for btn[1]
    always @(posedge clk or posedge rst) begin
        if (rst)
            btn1_prev <= 1'b0;
        else
            btn1_prev <= btn1_reg;
    end

    wire btn1_press = btn1_reg & ~btn1_prev;  // rising edge

    // -----------------------------------------------------------------------
    // Speed index control with clamping
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            speed_index <= 3'd1;  // default: 1 Hz
        end else begin
            if (btn0_press && speed_index < 3'd4)
                speed_index <= speed_index + 3'd1;  // faster
            else if (btn1_press && speed_index > 3'd0)
                speed_index <= speed_index - 3'd1;  // slower
        end
    end

    // -----------------------------------------------------------------------
    // LED blink counter
    // -----------------------------------------------------------------------
    reg [24:0] blink_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            blink_cnt <= 25'd0;
            led       <= 1'b0;
        end else begin
            if (blink_cnt >= half_period) begin
                blink_cnt <= 25'd0;
                led       <= ~led;
            end else begin
                blink_cnt <= blink_cnt + 25'd1;
            end
        end
    end

endmodule
