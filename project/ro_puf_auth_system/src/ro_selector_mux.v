`timescale 1ns / 1ps
//=============================================================================
// Ring Oscillator Selector Multiplexer
// Dual 16:1 mux to select a pair of RO outputs for frequency comparison.
// Uses explicit case statements to prevent synthesis optimisation of the
// dynamic bit-select which can sever the RO signal paths.
//=============================================================================

module ro_selector_mux (
    input  wire [15:0] ro_out,
    input  wire [3:0]  sel_a,
    input  wire [3:0]  sel_b,
    output reg         mux_a,
    output reg         mux_b
);

    always @(*) begin
        case (sel_a)
            4'd0:  mux_a = ro_out[0];
            4'd1:  mux_a = ro_out[1];
            4'd2:  mux_a = ro_out[2];
            4'd3:  mux_a = ro_out[3];
            4'd4:  mux_a = ro_out[4];
            4'd5:  mux_a = ro_out[5];
            4'd6:  mux_a = ro_out[6];
            4'd7:  mux_a = ro_out[7];
            4'd8:  mux_a = ro_out[8];
            4'd9:  mux_a = ro_out[9];
            4'd10: mux_a = ro_out[10];
            4'd11: mux_a = ro_out[11];
            4'd12: mux_a = ro_out[12];
            4'd13: mux_a = ro_out[13];
            4'd14: mux_a = ro_out[14];
            default: mux_a = ro_out[15];
        endcase
    end

    always @(*) begin
        case (sel_b)
            4'd0:  mux_b = ro_out[0];
            4'd1:  mux_b = ro_out[1];
            4'd2:  mux_b = ro_out[2];
            4'd3:  mux_b = ro_out[3];
            4'd4:  mux_b = ro_out[4];
            4'd5:  mux_b = ro_out[5];
            4'd6:  mux_b = ro_out[6];
            4'd7:  mux_b = ro_out[7];
            4'd8:  mux_b = ro_out[8];
            4'd9:  mux_b = ro_out[9];
            4'd10: mux_b = ro_out[10];
            4'd11: mux_b = ro_out[11];
            4'd12: mux_b = ro_out[12];
            4'd13: mux_b = ro_out[13];
            4'd14: mux_b = ro_out[14];
            default: mux_b = ro_out[15];
        endcase
    end

endmodule