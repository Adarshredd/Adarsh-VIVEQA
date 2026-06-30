`timescale 1ns / 1ps
//=============================================================================
// Measurement Controller
// Controls a single RO-pair frequency measurement cycle.
//
// Operation sequence:
//   1. On 'start': enable selected RO pair
//   2. Wait SETTLE_CYCLES for RO oscillation to stabilize
//   3. Start both frequency counters simultaneously
//   4. Wait for both counters to complete (valid)
//   5. Latch count results and assert 'done'
//
// Instantiates: ro_selector_mux, 2x frequency_counter
//=============================================================================

module measurement_controller #(
    parameter integer GATE_CYCLES   = 65536,
    parameter integer SETTLE_CYCLES = 1024
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [3:0]  ro_sel_a,
    input  wire [3:0]  ro_sel_b,
    input  wire [15:0] ro_osc_out,   // Raw outputs from all 16 ROs
    output reg  [15:0] ro_enable,
    output wire [31:0] count_a,
    output wire [31:0] count_b,
    output reg         done,
    output reg         busy
);

    //-------------------------------------------------------------------------
    // State machine
    //-------------------------------------------------------------------------
    localparam [2:0]
        ST_IDLE    = 3'd0,
        ST_ENABLE  = 3'd1,
        ST_SETTLE  = 3'd2,
        ST_COUNT   = 3'd3,
        ST_WAIT    = 3'd4,
        ST_DONE    = 3'd5;

    reg [2:0]  state;
    reg [15:0] settle_cnt;
    reg        fc_start;   // Frequency counter start pulse

    //-------------------------------------------------------------------------
    // RO Selector Mux
    //-------------------------------------------------------------------------
    wire mux_a, mux_b;

    ro_selector_mux u_mux (
        .ro_out (ro_osc_out),
        .sel_a  (ro_sel_a),
        .sel_b  (ro_sel_b),
        .mux_a  (mux_a),
        .mux_b  (mux_b)
    );

    //-------------------------------------------------------------------------
    // Frequency Counters (one per channel)
    //-------------------------------------------------------------------------
    wire [31:0] fc_count_a, fc_count_b;
    wire        fc_valid_a, fc_valid_b;

    frequency_counter #(
        .GATE_CYCLES (GATE_CYCLES)
    ) u_fc_a (
        .clk        (clk),
        .rst        (rst),
        .osc_signal (mux_a),
        .start      (fc_start),
        .count      (fc_count_a),
        .valid      (fc_valid_a)
    );

    frequency_counter #(
        .GATE_CYCLES (GATE_CYCLES)
    ) u_fc_b (
        .clk        (clk),
        .rst        (rst),
        .osc_signal (mux_b),
        .start      (fc_start),
        .count      (fc_count_b),
        .valid      (fc_valid_b)
    );

    assign count_a = fc_count_a;
    assign count_b = fc_count_b;

    //-------------------------------------------------------------------------
    // FSM
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state      <= ST_IDLE;
            ro_enable  <= 16'h0000;
            settle_cnt <= 16'd0;
            fc_start   <= 1'b0;
            done       <= 1'b0;
            busy       <= 1'b0;
        end else begin
            fc_start <= 1'b0;
            done     <= 1'b0;

            case (state)
                //-------------------------------------------------------------
                ST_IDLE: begin
                    busy      <= 1'b0;
                    ro_enable <= 16'h0000;
                    if (start) begin
                        busy  <= 1'b1;
                        state <= ST_ENABLE;
                    end
                end

                //-------------------------------------------------------------
                // Enable selected RO pair
                ST_ENABLE: begin
                    ro_enable  <= (16'd1 << ro_sel_a) | (16'd1 << ro_sel_b);
                    settle_cnt <= 16'd0;
                    state      <= ST_SETTLE;
                end

                //-------------------------------------------------------------
                // Wait for oscillation to stabilize
                ST_SETTLE: begin
                    if (settle_cnt >= SETTLE_CYCLES[15:0] - 1) begin
                        fc_start <= 1'b1;
                        state    <= ST_COUNT;
                    end else begin
                        settle_cnt <= settle_cnt + 1;
                    end
                end

                //-------------------------------------------------------------
                // Frequency counters are running
                ST_COUNT: begin
                    state <= ST_WAIT;
                end

                //-------------------------------------------------------------
                // Wait for both counters to finish
                ST_WAIT: begin
                    if (fc_valid_a && fc_valid_b) begin
                        state <= ST_DONE;
                    end
                end

                //-------------------------------------------------------------
                ST_DONE: begin
                    done      <= 1'b1;
                    ro_enable <= 16'h0000;
                    state     <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
