`timescale 1ns / 1ps
//=============================================================================
// Authentication Controller
// Top-level PUF authentication state machine.
//
// Operations:
//   btn_enroll  : Generate PUF response, store in enrollment memory
//   btn_auth    : Generate PUF response, compare with stored enrollment
//   btn_measure : Generate PUF response, display only (no storage)
//   btn_clear   : Clear all enrollment data
//
// Enrollment Memory: 256 x 8-bit (indexed by 8-bit challenge)
// Hamming distance tolerance: THRESHOLD bits (default 1)
//
// Instantiates: response_generator
//=============================================================================

module authentication_controller #(
    parameter integer GATE_CYCLES   = 65536,
    parameter integer SETTLE_CYCLES = 1024,
    parameter integer THRESHOLD     = 1    // Max Hamming distance for auth pass
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        btn_enroll,
    input  wire        btn_auth,
    input  wire        btn_measure,
    input  wire        btn_clear,
    input  wire [7:0]  sw,
    input  wire [15:0] ro_osc_out,
    output wire [15:0] ro_enable,
    output reg  [7:0]  current_response,
    output reg  [7:0]  stored_response,
    output reg         auth_pass,
    output reg         auth_fail,
    output reg         enrolled,
    output reg         busy,
    output reg  [3:0]  state_out,
    output wire [31:0] last_count_a,
    output wire [31:0] last_count_b,
    output reg         measure_valid
);

    //-------------------------------------------------------------------------
    // State encoding
    //-------------------------------------------------------------------------
    localparam [3:0]
        ST_IDLE         = 4'd0,
        ST_ENROLLING    = 4'd1,
        ST_STORE        = 4'd2,
        ST_AUTHING      = 4'd3,
        ST_COMPARING    = 4'd4,
        ST_PASS         = 4'd5,
        ST_FAIL         = 4'd6,
        ST_MEASURING    = 4'd7,
        ST_MEAS_DONE   = 4'd8,
        ST_CLEARING     = 4'd9;

    reg [3:0] state;

    //-------------------------------------------------------------------------
    // Enrollment memory: 256 entries x 8 bits
    //-------------------------------------------------------------------------
    reg [7:0]   enroll_mem [0:255];
    reg [255:0] enroll_flags;  // 1 = challenge enrolled

    //-------------------------------------------------------------------------
    // Response Generator
    //-------------------------------------------------------------------------
    reg         rg_start;
    wire [7:0]  rg_response;
    wire        rg_valid;
    wire        rg_busy;

    response_generator #(
        .GATE_CYCLES   (GATE_CYCLES),
        .SETTLE_CYCLES (SETTLE_CYCLES)
    ) u_respgen (
        .clk          (clk),
        .rst          (rst),
        .start        (rg_start),
        .challenge    (sw),
        .ro_osc_out   (ro_osc_out),
        .ro_enable    (ro_enable),
        .response     (rg_response),
        .valid        (rg_valid),
        .busy         (rg_busy),
        .last_count_a (last_count_a),
        .last_count_b (last_count_b)
    );

    //-------------------------------------------------------------------------
    // Hamming distance calculator
    //-------------------------------------------------------------------------
    function [3:0] hamming_dist;
        input [7:0] a, b;
        reg [7:0] diff;
        integer k;
    begin
        diff = a ^ b;
        hamming_dist = 4'd0;
        for (k = 0; k < 8; k = k + 1)
            hamming_dist = hamming_dist + {3'd0, diff[k]};
    end
    endfunction

    //-------------------------------------------------------------------------
    // Status display timer (hold pass/fail state for visibility)
    //-------------------------------------------------------------------------
    localparam integer DISPLAY_HOLD = 24_000_000 * 2;  // 2 seconds
    localparam integer HW = $clog2(DISPLAY_HOLD + 1);
    reg [HW-1:0] hold_cnt;

    //-------------------------------------------------------------------------
    // FSM
    //-------------------------------------------------------------------------
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            state            <= ST_IDLE;
            current_response <= 8'h00;
            stored_response  <= 8'h00;
            auth_pass        <= 1'b0;
            auth_fail        <= 1'b0;
            enrolled         <= 1'b0;
            busy             <= 1'b0;
            state_out        <= 4'd0;
            measure_valid    <= 1'b0;
            rg_start         <= 1'b0;
            hold_cnt         <= {HW{1'b0}};
            enroll_flags     <= 256'd0;
            for (i = 0; i < 256; i = i + 1)
                enroll_mem[i] <= 8'h00;
        end else begin
            rg_start  <= 1'b0;
            auth_pass <= 1'b0;
            auth_fail <= 1'b0;
            state_out <= state;

            // Enrolled flag tracks current challenge
            enrolled <= enroll_flags[sw];

            case (state)
                //=============================================================
                ST_IDLE: begin
                    busy          <= 1'b0;
                    measure_valid <= 1'b0;

                    if (btn_enroll && !rg_busy) begin
                        rg_start <= 1'b1;
                        busy     <= 1'b1;
                        state    <= ST_ENROLLING;
                    end else if (btn_auth && !rg_busy) begin
                        if (enroll_flags[sw]) begin
                            rg_start        <= 1'b1;
                            busy            <= 1'b1;
                            stored_response <= enroll_mem[sw];
                            state           <= ST_AUTHING;
                        end else begin
                            // Not enrolled: flash fail
                            auth_fail <= 1'b1;
                            hold_cnt  <= {HW{1'b0}};
                            state     <= ST_FAIL;
                        end
                    end else if (btn_measure && !rg_busy) begin
                        rg_start <= 1'b1;
                        busy     <= 1'b1;
                        state    <= ST_MEASURING;
                    end else if (btn_clear) begin
                        state <= ST_CLEARING;
                    end
                end

                //=============================================================
                // ENROLLMENT: wait for response generator
                ST_ENROLLING: begin
                    if (rg_valid) begin
                        current_response     <= rg_response;
                        enroll_mem[sw]       <= rg_response;
                        enroll_flags[sw]     <= 1'b1;
                        hold_cnt             <= {HW{1'b0}};
                        state                <= ST_STORE;
                    end
                end

                //=============================================================
                // Brief display of enrollment result
                ST_STORE: begin
                    busy <= 1'b0;
                    if (hold_cnt >= DISPLAY_HOLD[HW-1:0] / 2) begin
                        state <= ST_IDLE;
                    end else begin
                        hold_cnt <= hold_cnt + 1;
                    end
                end

                //=============================================================
                // AUTHENTICATION: wait for response generator
                ST_AUTHING: begin
                    if (rg_valid) begin
                        current_response <= rg_response;
                        state            <= ST_COMPARING;
                    end
                end

                //=============================================================
                // Compare current vs stored using Hamming distance
                ST_COMPARING: begin
                    if (hamming_dist(current_response, stored_response) <= THRESHOLD[3:0]) begin
                        auth_pass <= 1'b1;
                        hold_cnt  <= {HW{1'b0}};
                        state     <= ST_PASS;
                    end else begin
                        auth_fail <= 1'b1;
                        hold_cnt  <= {HW{1'b0}};
                        state     <= ST_FAIL;
                    end
                end

                //=============================================================
                ST_PASS: begin
                    busy <= 1'b0;
                    if (hold_cnt >= DISPLAY_HOLD[HW-1:0]) begin
                        state <= ST_IDLE;
                    end else begin
                        hold_cnt <= hold_cnt + 1;
                    end
                end

                //=============================================================
                ST_FAIL: begin
                    busy <= 1'b0;
                    if (hold_cnt >= DISPLAY_HOLD[HW-1:0]) begin
                        state <= ST_IDLE;
                    end else begin
                        hold_cnt <= hold_cnt + 1;
                    end
                end

                //=============================================================
                // MEASURE: just display, no enrollment
                ST_MEASURING: begin
                    if (rg_valid) begin
                        current_response <= rg_response;
                        measure_valid    <= 1'b1;
                        hold_cnt         <= {HW{1'b0}};
                        state            <= ST_MEAS_DONE;
                    end
                end

                //=============================================================
                ST_MEAS_DONE: begin
                    busy <= 1'b0;
                    if (hold_cnt >= DISPLAY_HOLD[HW-1:0]) begin
                        state <= ST_IDLE;
                    end else begin
                        hold_cnt <= hold_cnt + 1;
                    end
                end

                //=============================================================
                ST_CLEARING: begin
                    enroll_flags <= 256'd0;
                    for (i = 0; i < 256; i = i + 1)
                        enroll_mem[i] <= 8'h00;
                    state <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
