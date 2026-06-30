`timescale 1ns / 1ps
//=============================================================================
// LED Controller
// Displays system state and PUF response on 8 LEDs.
//
// State-based patterns:
//   IDLE(0)          : heartbeat on led[0]
//   ENROLLING(1)     : scanning bar left
//   STORE(2)         : led[1] solid
//   AUTHENTICATING(3): scanning bar right
//   COMPARING(4)     : fast blink all
//   AUTH_PASS(5)     : all LEDs on
//   AUTH_FAIL(6)     : alternating odd/even blink
//   MEASURING(7)     : chasing pattern
//   MEASURE_DONE(8)  : display response byte
//   CLEARING(9)      : all LEDs rapid blink
//=============================================================================

module led_controller #(
    parameter integer CLK_FREQ = 24_000_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [3:0]  state,
    input  wire        enrolled,
    input  wire        auth_pass,
    input  wire        auth_fail,
    input  wire        busy,
    input  wire [7:0]  response,
    output reg  [7:0]  led
);

    //-------------------------------------------------------------------------
    // Animation clock dividers
    //-------------------------------------------------------------------------
    localparam integer HEARTBEAT_DIV = CLK_FREQ / 2;       // 0.5 Hz toggle
    localparam integer SCAN_DIV      = CLK_FREQ / 8;       // 8 Hz scan
    localparam integer BLINK_DIV     = CLK_FREQ / 4;       // 4 Hz blink
    localparam integer FAST_DIV      = CLK_FREQ / 10;      // 10 Hz fast

    localparam integer DW = $clog2(HEARTBEAT_DIV + 1);

    reg [DW-1:0] anim_cnt;
    reg [2:0]    scan_pos;
    reg          blink_toggle;
    reg          heartbeat;

    always @(posedge clk) begin
        if (rst) begin
            anim_cnt     <= {DW{1'b0}};
            scan_pos     <= 3'd0;
            blink_toggle <= 1'b0;
            heartbeat    <= 1'b0;
        end else begin
            anim_cnt <= anim_cnt + 1;

            // Heartbeat (slowest)
            if (anim_cnt == HEARTBEAT_DIV[DW-1:0]) begin
                heartbeat <= ~heartbeat;
            end

            // Scan position
            if (anim_cnt[DW-3:0] == {(DW-2){1'b0}})
                scan_pos <= scan_pos + 1;

            // Blink toggle (medium)
            if (anim_cnt[DW-4:0] == {(DW-3){1'b0}})
                blink_toggle <= ~blink_toggle;
        end
    end

    //-------------------------------------------------------------------------
    // LED output mux based on auth_controller state
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            led <= 8'h00;
        end else begin
            case (state)
                4'd0: // IDLE
                    led <= {7'b0000000, heartbeat};

                4'd1: // ENROLLING
                    led <= 8'h01 << scan_pos;

                4'd2: // STORE (enrolled)
                    led <= 8'b00000010;

                4'd3: // AUTHENTICATING
                    led <= 8'h80 >> scan_pos;

                4'd4: // COMPARING
                    led <= blink_toggle ? 8'hFF : 8'h00;

                4'd5: // AUTH_PASS
                    led <= 8'hFF;

                4'd6: // AUTH_FAIL
                    led <= blink_toggle ? 8'hAA : 8'h55;

                4'd7: // MEASURING
                    led <= 8'h03 << scan_pos[1:0];

                4'd8: // MEASURE_DONE
                    led <= response;

                4'd9: // CLEARING
                    led <= blink_toggle ? 8'hFF : 8'h00;

                default:
                    led <= 8'h00;
            endcase
        end
    end

endmodule
