`timescale 1ns / 1ps
//=============================================================================
// Response Generator
// Generates an 8-bit PUF response from an 8-bit challenge by sequencing
// 8 individual RO-pair measurements.
//
// For each response bit i (0..7):
//   - challenge_decoder derives RO pair indices from (challenge, i)
//   - measurement_controller measures both ROs' frequencies
//   - comparator produces 1-bit from count comparison
//   - Result stored in response[i]
//
// Instantiates: challenge_decoder, measurement_controller, comparator
//=============================================================================

module response_generator #(
    parameter integer GATE_CYCLES   = 65536,
    parameter integer SETTLE_CYCLES = 1024
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  challenge,
    input  wire [15:0] ro_osc_out,
    output wire [15:0] ro_enable,
    output reg  [7:0]  response,
    output reg         valid,
    output reg         busy,
    output wire [31:0] last_count_a,
    output wire [31:0] last_count_b
);

    //-------------------------------------------------------------------------
    // State machine
    //-------------------------------------------------------------------------
    localparam [2:0]
        ST_IDLE    = 3'd0,
        ST_DECODE  = 3'd1,
        ST_MEASURE = 3'd2,
        ST_WAIT    = 3'd3,
        ST_COMPARE = 3'd4,
        ST_NEXT    = 3'd5,
        ST_DONE    = 3'd6;

    reg [2:0] state;
    reg [2:0] bit_idx;
    reg [7:0] challenge_reg;
    reg [7:0] response_acc;

    //-------------------------------------------------------------------------
    // Challenge Decoder
    //-------------------------------------------------------------------------
    wire [3:0] ro_sel_a, ro_sel_b;

    challenge_decoder u_decoder (
        .challenge (challenge_reg),
        .bit_index (bit_idx),
        .ro_sel_a  (ro_sel_a),
        .ro_sel_b  (ro_sel_b)
    );

    //-------------------------------------------------------------------------
    // Measurement Controller
    //-------------------------------------------------------------------------
    reg  mc_start;
    wire mc_done, mc_busy;
    wire [31:0] mc_count_a, mc_count_b;

    measurement_controller #(
        .GATE_CYCLES   (GATE_CYCLES),
        .SETTLE_CYCLES (SETTLE_CYCLES)
    ) u_meas (
        .clk        (clk),
        .rst        (rst),
        .start      (mc_start),
        .ro_sel_a   (ro_sel_a),
        .ro_sel_b   (ro_sel_b),
        .ro_osc_out (ro_osc_out),
        .ro_enable  (ro_enable),
        .count_a    (mc_count_a),
        .count_b    (mc_count_b),
        .done       (mc_done),
        .busy       (mc_busy)
    );

    assign last_count_a = mc_count_a;
    assign last_count_b = mc_count_b;

    //-------------------------------------------------------------------------
    // Comparator
    //-------------------------------------------------------------------------
    wire cmp_bit;

    comparator u_cmp (
        .count_a      (mc_count_a),
        .count_b      (mc_count_b),
        .response_bit (cmp_bit)
    );

    //-------------------------------------------------------------------------
    // FSM
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state         <= ST_IDLE;
            bit_idx       <= 3'd0;
            challenge_reg <= 8'h00;
            response_acc  <= 8'h00;
            response      <= 8'h00;
            valid         <= 1'b0;
            busy          <= 1'b0;
            mc_start      <= 1'b0;
        end else begin
            mc_start <= 1'b0;
            valid    <= 1'b0;

            case (state)
                //-------------------------------------------------------------
                ST_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy          <= 1'b1;
                        challenge_reg <= challenge;
                        response_acc  <= 8'h00;
                        bit_idx       <= 3'd0;
                        state         <= ST_DECODE;
                    end
                end

                //-------------------------------------------------------------
                // Allow 1 cycle for challenge_decoder combinational output
                ST_DECODE: begin
                    state <= ST_MEASURE;
                end

                //-------------------------------------------------------------
                // Start measurement for current RO pair
                ST_MEASURE: begin
                    mc_start <= 1'b1;
                    state    <= ST_WAIT;
                end

                //-------------------------------------------------------------
                // Wait for measurement to complete
                ST_WAIT: begin
                    if (mc_done)
                        state <= ST_COMPARE;
                end

                //-------------------------------------------------------------
                // Latch comparator result into response accumulator
                ST_COMPARE: begin
                    response_acc[bit_idx] <= cmp_bit;
                    state <= ST_NEXT;
                end

                //-------------------------------------------------------------
                // Advance to next bit or finish
                ST_NEXT: begin
                    if (bit_idx == 3'd7) begin
                        state <= ST_DONE;
                    end else begin
                        bit_idx <= bit_idx + 1;
                        state   <= ST_DECODE;
                    end
                end

                //-------------------------------------------------------------
                ST_DONE: begin
                    response <= response_acc;
                    valid    <= 1'b1;
                    busy     <= 1'b0;
                    state    <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
