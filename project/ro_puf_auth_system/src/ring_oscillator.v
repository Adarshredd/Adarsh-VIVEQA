`timescale 1ns / 1ps
//=============================================================================
// Ring Oscillator - Xilinx LUT Primitive Implementation
// Target: XC7A35T (Artix-7)
//
// 5-stage inverter chain with AND-gate enable using LUT1/LUT2 primitives.
// Placement constrained to SLICE_X0Y{RO_INDEX} via XDC file.
//
// Topology:
//   enable --+
//            v
//   +---> [LUT2:AND] -> [LUT1:INV0] -> [INV1] -> [INV2] -> [INV3] -> [INV4] --+
//   |                                                                            |
//   +----------------------------------------------------------------------------+
//
// Total inversions: 5 (odd) -> oscillates when enable=1
// When enable=0, AND output=0, loop is quenched.
//=============================================================================

(* DONT_TOUCH = "yes" *)
(* KEEP_HIERARCHY = "yes" *)
module ring_oscillator #(
    parameter integer RO_INDEX = 0
)(
    input  wire enable,
    output wire osc_out
);

    //-------------------------------------------------------------------------
    // Internal nets
    //-------------------------------------------------------------------------
    (* ALLOW_COMBINATORIAL_LOOPS = "true", DONT_TOUCH = "yes" *)
    wire and_out;

    wire inv0_out;
    wire inv1_out;
    wire inv2_out;
    wire inv3_out;

    (* ALLOW_COMBINATORIAL_LOOPS = "true", DONT_TOUCH = "yes" *)
    wire inv4_out;

    //-------------------------------------------------------------------------
    // AND gate: enable gating with feedback
    // LUT2 INIT = 4'b1000 => O = I0 & I1
    //   I0 = enable, I1 = inv4_out (feedback)
    //-------------------------------------------------------------------------
    (* DONT_TOUCH = "yes", KEEP = "true" *)
    LUT2 #(
        .INIT (4'b1000)
    ) lut_and (
        .O  (and_out),
        .I0 (enable),
        .I1 (inv4_out)
    );

    //-------------------------------------------------------------------------
    // 5-stage inverter chain
    // LUT1 INIT = 2'b01 => O = ~I0
    //-------------------------------------------------------------------------
    (* DONT_TOUCH = "yes", KEEP = "true" *)
    LUT1 #(.INIT(2'b01)) lut_inv0 (
        .O  (inv0_out),
        .I0 (and_out)
    );

    (* DONT_TOUCH = "yes", KEEP = "true" *)
    LUT1 #(.INIT(2'b01)) lut_inv1 (
        .O  (inv1_out),
        .I0 (inv0_out)
    );

    (* DONT_TOUCH = "yes", KEEP = "true" *)
    LUT1 #(.INIT(2'b01)) lut_inv2 (
        .O  (inv2_out),
        .I0 (inv1_out)
    );

    (* DONT_TOUCH = "yes", KEEP = "true" *)
    LUT1 #(.INIT(2'b01)) lut_inv3 (
        .O  (inv3_out),
        .I0 (inv2_out)
    );

    (* DONT_TOUCH = "yes", KEEP = "true" *)
    LUT1 #(.INIT(2'b01)) lut_inv4 (
        .O  (inv4_out),
        .I0 (inv3_out)
    );

    //-------------------------------------------------------------------------
    // Output tap: last inverter stage
    //-------------------------------------------------------------------------
    assign osc_out = inv4_out;

endmodule
