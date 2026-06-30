`timescale 1ns / 1ps
//=============================================================================
// Buzzer Controller
// Generates audible feedback for authentication results.
//   auth_pass pulse -> 2 kHz tone, 200 ms duration (single beep)
//   auth_fail pulse -> 1 kHz tone, 3 x 100 ms beeps with 100 ms gaps
//=============================================================================

module buzzer_controller #(
    parameter integer CLK_FREQ = 24_000_000
)(
    input  wire clk,
    input  wire rst,
    input  wire auth_pass,
    input  wire auth_fail,
    output reg  buzzer
);

    //-------------------------------------------------------------------------
    // Tone parameters (in clock cycles)
    //-------------------------------------------------------------------------
    localparam integer HALF_2KHZ   = CLK_FREQ / (2 * 2000);   // 6000
    localparam integer HALF_1KHZ   = CLK_FREQ / (2 * 1000);   // 12000
    localparam integer DUR_200MS   = CLK_FREQ / 5;             // 4_800_000
    localparam integer DUR_100MS   = CLK_FREQ / 10;            // 2_400_000

    localparam integer TW = $clog2(HALF_1KHZ);
    localparam integer DW = $clog2(DUR_200MS + 1);

    //-------------------------------------------------------------------------
    // State encoding
    //-------------------------------------------------------------------------
    localparam [2:0]
        ST_IDLE      = 3'd0,
        ST_PASS_BEEP = 3'd1,
        ST_FAIL_BEEP = 3'd2,
        ST_FAIL_GAP  = 3'd3;

    reg [2:0]    state;
    reg [TW-1:0] tone_cnt;
    reg [DW-1:0] dur_cnt;
    reg [1:0]    beep_num;     // 0,1,2 for three fail beeps
    reg          tone_out;
    reg [TW-1:0] half_period;
    reg [DW-1:0] duration;

    always @(posedge clk) begin
        if (rst) begin
            state       <= ST_IDLE;
            tone_cnt    <= {TW{1'b0}};
            dur_cnt     <= {DW{1'b0}};
            beep_num    <= 2'd0;
            tone_out    <= 1'b0;
            buzzer      <= 1'b0;
            half_period <= HALF_2KHZ[TW-1:0];
            duration    <= DUR_200MS[DW-1:0];
        end else begin
            case (state)
                //-------------------------------------------------------------
                ST_IDLE: begin
                    buzzer   <= 1'b0;
                    tone_out <= 1'b0;
                    if (auth_pass) begin
                        half_period <= HALF_2KHZ[TW-1:0];
                        duration    <= DUR_200MS[DW-1:0];
                        dur_cnt     <= {DW{1'b0}};
                        tone_cnt    <= {TW{1'b0}};
                        state       <= ST_PASS_BEEP;
                    end else if (auth_fail) begin
                        half_period <= HALF_1KHZ[TW-1:0];
                        duration    <= DUR_100MS[DW-1:0];
                        dur_cnt     <= {DW{1'b0}};
                        tone_cnt    <= {TW{1'b0}};
                        beep_num    <= 2'd0;
                        state       <= ST_FAIL_BEEP;
                    end
                end

                //-------------------------------------------------------------
                ST_PASS_BEEP: begin
                    // Generate tone
                    if (tone_cnt >= half_period) begin
                        tone_cnt <= {TW{1'b0}};
                        tone_out <= ~tone_out;
                    end else begin
                        tone_cnt <= tone_cnt + 1;
                    end
                    buzzer <= tone_out;

                    // Duration tracking
                    if (dur_cnt >= duration) begin
                        buzzer <= 1'b0;
                        state  <= ST_IDLE;
                    end else begin
                        dur_cnt <= dur_cnt + 1;
                    end
                end

                //-------------------------------------------------------------
                ST_FAIL_BEEP: begin
                    // Generate tone
                    if (tone_cnt >= half_period) begin
                        tone_cnt <= {TW{1'b0}};
                        tone_out <= ~tone_out;
                    end else begin
                        tone_cnt <= tone_cnt + 1;
                    end
                    buzzer <= tone_out;

                    // Duration tracking
                    if (dur_cnt >= duration) begin
                        buzzer   <= 1'b0;
                        tone_out <= 1'b0;
                        dur_cnt  <= {DW{1'b0}};
                        tone_cnt <= {TW{1'b0}};
                        if (beep_num == 2'd2) begin
                            state <= ST_IDLE;
                        end else begin
                            state <= ST_FAIL_GAP;
                        end
                    end else begin
                        dur_cnt <= dur_cnt + 1;
                    end
                end

                //-------------------------------------------------------------
                ST_FAIL_GAP: begin
                    buzzer <= 1'b0;
                    if (dur_cnt >= duration) begin
                        dur_cnt  <= {DW{1'b0}};
                        beep_num <= beep_num + 1;
                        state    <= ST_FAIL_BEEP;
                    end else begin
                        dur_cnt <= dur_cnt + 1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
