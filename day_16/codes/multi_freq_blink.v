`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 14:38:40
// Design Name: 
// Module Name: multi_freq_blink
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
// Module: multi_freq_blink
// Description: Multi-frequency LED blinker using a SINGLE free-running counter.
//              4 LEDs blink at 1 Hz, 2 Hz, 4 Hz, and 8 Hz simultaneously.
//
// Approach: One counter counts 0 to HALF_1HZ-1, then resets (one full
//           count cycle = 0.5 s at 24 MHz → the 1 Hz toggle period).
//
//           Faster LEDs toggle at evenly-spaced thresholds within this range:
//             LED[0] 1 Hz : toggle at rollover (1×)
//             LED[1] 2 Hz : toggle at 1/2 and rollover (2×)
//             LED[2] 4 Hz : toggle at 1/4, 2/4, 3/4, rollover (4×)
//             LED[3] 8 Hz : toggle at 1/8, 2/8, …, 7/8, rollover (8×)
//
// Clock: 24 MHz (41.667 ns period)
//============================================================================

module multi_freq_blink #(
    // Half-period for 1 Hz = 24_000_000 / 2 = 12_000_000
    parameter HALF_1HZ = 12_000_000
)(
    input  wire clk,
    input  wire rst,
    output reg  [3:0] led
);

    // -----------------------------------------------------------------------
    // Derived threshold parameters
    // -----------------------------------------------------------------------
    localparam STEP_8HZ = HALF_1HZ / 8;   // 1,500,000
    localparam STEP_4HZ = HALF_1HZ / 4;   // 3,000,000
    localparam STEP_2HZ = HALF_1HZ / 2;   // 6,000,000

    // 8 Hz toggle thresholds (8 evenly spaced points)
    localparam T8_0 = STEP_8HZ * 1 - 1;   //  1,499,999
    localparam T8_1 = STEP_8HZ * 2 - 1;   //  2,999,999
    localparam T8_2 = STEP_8HZ * 3 - 1;   //  4,499,999
    localparam T8_3 = STEP_8HZ * 4 - 1;   //  5,999,999
    localparam T8_4 = STEP_8HZ * 5 - 1;   //  7,499,999
    localparam T8_5 = STEP_8HZ * 6 - 1;   //  8,999,999
    localparam T8_6 = STEP_8HZ * 7 - 1;   // 10,499,999
    localparam T8_7 = HALF_1HZ - 1;       // 11,999,999

    // 4 Hz toggle thresholds (4 evenly spaced points)
    localparam T4_0 = STEP_4HZ * 1 - 1;   //  2,999,999
    localparam T4_1 = STEP_4HZ * 2 - 1;   //  5,999,999
    localparam T4_2 = STEP_4HZ * 3 - 1;   //  8,999,999
    localparam T4_3 = HALF_1HZ - 1;       // 11,999,999

    // 2 Hz toggle thresholds (2 evenly spaced points)
    localparam T2_0 = STEP_2HZ * 1 - 1;   //  5,999,999
    localparam T2_1 = HALF_1HZ - 1;       // 11,999,999

    // 1 Hz toggle threshold (1 point)
    localparam T1_0 = HALF_1HZ - 1;       // 11,999,999

    // -----------------------------------------------------------------------
    // Single free-running counter
    // -----------------------------------------------------------------------
    // Need enough bits: ceil(log2(12_000_000)) = 24 bits
    reg [23:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst)
            counter <= 24'd0;
        else if (counter == HALF_1HZ - 1)
            counter <= 24'd0;
        else
            counter <= counter + 24'd1;
    end

    // -----------------------------------------------------------------------
    // LED[0] - 1 Hz: toggle once per counter cycle
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            led[0] <= 1'b0;
        else if (counter == T1_0)
            led[0] <= ~led[0];
    end

    // -----------------------------------------------------------------------
    // LED[1] - 2 Hz: toggle twice per counter cycle
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            led[1] <= 1'b0;
        else if (counter == T2_0 || counter == T2_1)
            led[1] <= ~led[1];
    end

    // -----------------------------------------------------------------------
    // LED[2] - 4 Hz: toggle four times per counter cycle
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            led[2] <= 1'b0;
        else if (counter == T4_0 || counter == T4_1 ||
                 counter == T4_2 || counter == T4_3)
            led[2] <= ~led[2];
    end

    // -----------------------------------------------------------------------
    // LED[3] - 8 Hz: toggle eight times per counter cycle
    // -----------------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            led[3] <= 1'b0;
        else if (counter == T8_0 || counter == T8_1 ||
                 counter == T8_2 || counter == T8_3 ||
                 counter == T8_4 || counter == T8_5 ||
                 counter == T8_6 || counter == T8_7)
            led[3] <= ~led[3];
    end

endmodule

