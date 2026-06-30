`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 14:38:40
// Design Name: 
// Module Name: led_shift
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
// Module: led_shift
// Description: 4-bit LED shift register with button-controlled rotation.
//              btn[0] rotates left, btn[1] rotates right.
//              One-hot pattern maintained: only one LED on at a time.
//              Includes counter-based button debounce (20 ms at 24 MHz).
//
// Clock: 24 MHz (41.667 ns period)
//============================================================================

module led_shift #(
    // Debounce count: 20 ms × 24 MHz = 480,000 cycles
    parameter DEBOUNCE_MAX = 480_000
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] btn,    // btn[0]=left, btn[1]=right
    output reg  [3:0] led
);

    // -----------------------------------------------------------------------
    // Button debounce - btn[0] (rotate left)
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

    always @(posedge clk or posedge rst) begin
        if (rst)
            btn0_prev <= 1'b0;
        else
            btn0_prev <= btn0_reg;
    end

    wire btn0_press = btn0_reg & ~btn0_prev;

    // -----------------------------------------------------------------------
    // Button debounce - btn[1] (rotate right)
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

    always @(posedge clk or posedge rst) begin
        if (rst)
            btn1_prev <= 1'b0;
        else
            btn1_prev <= btn1_reg;
    end

    wire btn1_press = btn1_reg & ~btn1_prev;

    // -----------------------------------------------------------------------
    // LED shift register with rotation
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led <= 4'b0001;  // initial: rightmost LED on
        end else begin
            if (btn0_press) begin
                // Rotate left: {led[2:0], led[3]}
                led <= {led[2:0], led[3]};
            end else if (btn1_press) begin
                // Rotate right: {led[0], led[3:1]}
                led <= {led[0], led[3:1]};
            end
        end
    end

endmodule
