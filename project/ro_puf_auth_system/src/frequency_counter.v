`timescale 1ns / 1ps
//=============================================================================
// Frequency Counter
// Counts rising edges of an asynchronous oscillator signal over a fixed
// gate window (GATE_CYCLES system clock cycles).
//
// Fix: TIMER_WIDTH uses $clog2(GATE_CYCLES+1) so that GATE_CYCLES=65536
// gets 17 bits instead of 16, preventing the -1 truncation overflow.
//=============================================================================

module frequency_counter #(
    parameter integer GATE_CYCLES = 65536
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        osc_signal,
    input  wire        start,
    output reg  [31:0] count,
    output reg         valid
);

    //-------------------------------------------------------------------------
    // 3-FF synchronizer for asynchronous oscillator signal
    //-------------------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) reg [2:0] osc_sync;

    always @(posedge clk) begin
        if (rst)
            osc_sync <= 3'b000;
        else
            osc_sync <= {osc_sync[1:0], osc_signal};
    end

    wire osc_rising = osc_sync[1] & ~osc_sync[2];

    //-------------------------------------------------------------------------
    // Gate timer - width calculated from GATE_CYCLES+1 to avoid overflow
    // e.g. GATE_CYCLES=65536 → $clog2(65537)=17 bits
    //-------------------------------------------------------------------------
    localparam TIMER_WIDTH = $clog2(GATE_CYCLES + 1);

    reg [TIMER_WIDTH-1:0] gate_timer;
    reg                   counting;
    reg [31:0]            edge_count;

    always @(posedge clk) begin
        if (rst) begin
            gate_timer <= {TIMER_WIDTH{1'b0}};
            counting   <= 1'b0;
            edge_count <= 32'd0;
            count      <= 32'd0;
            valid      <= 1'b0;
        end else if (start) begin
            gate_timer <= {TIMER_WIDTH{1'b0}};
            counting   <= 1'b1;
            edge_count <= 32'd0;
            valid      <= 1'b0;
        end else if (counting) begin
            if (osc_rising)
                edge_count <= edge_count + 32'd1;

            if (gate_timer == GATE_CYCLES[TIMER_WIDTH-1:0] - 1) begin
                counting <= 1'b0;
                count    <= edge_count + (osc_rising ? 32'd1 : 32'd0);
                valid    <= 1'b1;
            end else begin
                gate_timer <= gate_timer + 1;
            end
        end
    end

endmodule