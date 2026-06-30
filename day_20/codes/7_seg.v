`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.06.2026 12:05:29
// Design Name: 
// Module Name: 7_seg
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


module seg_display (
    input  wire clk_24mhz,

    output reg seg_cs  = 1'b1,
    output reg seg_clk = 1'b0,
    output reg seg_din = 1'b0
);

    // =========================================================
    // d0 = Hours      (leftmost,  slowest)
    // d1 = Minutes
    // d2 = Seconds
    // d3 = Tenths     (rightmost, fastest)
    // =========================================================
    reg [3:0] d0 = 0;
    reg [3:0] d1 = 0;
    reg [3:0] d2 = 0;
    reg [3:0] d3 = 0;

    // =========================================================
    // 100 ms tick  (24,000,000 × 0.1 = 2,400,000 cycles)
    // reg needs 22 bits (2^22 = 4,194,304 > 2,400,000)
    // =========================================================
    reg [21:0] tick_cnt    = 0;
    reg        tick_100ms  = 0;

    always @(posedge clk_24mhz) begin
        if (tick_cnt == 22'd2_399_999) begin
            tick_cnt  <= 0;
            tick_100ms <= 1;
        end else begin
            tick_cnt  <= tick_cnt + 1;
            tick_100ms <= 0;
        end
    end

    // =========================================================
    // Stopwatch counter - d3 ticks every 100 ms
    // Rolls: d3(0-9) → d2(0-9 seconds) → d1(0-9 tens-sec)
    //      → d0(0-9 hundreds-sec)
    // =========================================================
    always @(posedge clk_24mhz) begin
        if (tick_100ms) begin
            if (d3 == 9) begin
                d3 <= 0;
                if (d2 == 9) begin
                    d2 <= 0;
                    if (d1 == 9) begin
                        d1 <= 0;
                        if (d0 == 9)
                            d0 <= 0;   // full rollover
                        else
                            d0 <= d0 + 1;
                    end else
                        d1 <= d1 + 1;
                end else
                    d2 <= d2 + 1;
            end else
                d3 <= d3 + 1;
        end
    end

    // =========================================================
    // 1 MHz SPI tick  (24 MHz / 24 = 1 MHz)
    // =========================================================
    reg [4:0] seg_tick_div = 0;
    wire      seg_tick     = (seg_tick_div == 23);

    always @(posedge clk_24mhz) begin
        if (seg_tick) seg_tick_div <= 0;
        else          seg_tick_div <= seg_tick_div + 1;
    end

    // =========================================================
    // MAX7219 SPI FSM
    // cmd 0-3  : one-time init (sent on power-up, then skipped)
    // cmd 4-7  : live digit refresh loop
    //
    // MAX7219 digit registers:
    //   REG 0x01 → rightmost digit → d3 (tenths,  fastest)
    //   REG 0x02 → next digit      → d2 (seconds)
    //   REG 0x03 → next digit      → d1 (minutes)
    //   REG 0x04 → leftmost digit  → d0 (hours,   slowest)
    // =========================================================
    reg [5:0]  seg_state = 0;
    reg [15:0] seg_shift = 0;
    reg [2:0]  curr_dig  = 0;

    always @(posedge clk_24mhz) begin
        if (seg_tick) begin

            // ---- STATE 0 : load SPI word, assert CS ----
            if (seg_state == 0) begin
                seg_cs  <= 0;
                seg_clk <= 0;
                case (curr_dig)
                    3'd0: seg_shift <= 16'h0C01; // Shutdown  : normal op
                    3'd1: seg_shift <= 16'h09FF; // Decode    : Code-B all
                    3'd2: seg_shift <= 16'h0A08; // Intensity : mid
                    3'd3: seg_shift <= 16'h0B03; // Scan limit: 4 digits

                    // d3=tenths on rightmost, d0=hours on leftmost
                    3'd4: seg_shift <= {8'h01, 4'h0, d3}; // rightmost
                    3'd5: seg_shift <= {8'h02, 4'h0, d2};
                    3'd6: seg_shift <= {8'h03, 4'h0, d1};
                    3'd7: seg_shift <= {8'h04, 4'h0, d0}; // leftmost
                endcase
                seg_state <= 1;
            end

            // ---- STATES 1-32 : clock out 16 bits MSB first ----
            else if (seg_state <= 32) begin
                if (seg_state[0]) begin      // odd : put bit, CLK low
                    seg_din <= seg_shift[15];
                    seg_clk <= 0;
                end else begin               // even: rising CLK edge
                    seg_clk   <= 1;
                    seg_shift <= {seg_shift[14:0], 1'b0};
                end
                seg_state <= seg_state + 1;
            end

            // ---- STATE 33 : latch (CS high), next command ----
            else begin
                seg_cs  <= 1;
                seg_clk <= 0;
                // After init cmds 0-3, loop only digit cmds 4-7
                curr_dig  <= (curr_dig < 7) ? curr_dig + 1 : 3'd4;
                seg_state <= 0;
            end

        end
    end

endmodule

