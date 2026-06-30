`timescale 1ns / 1ps
//=============================================================================
// Challenge Decoder
// Maps an 8-bit challenge and a 3-bit response-bit index into a pair
// of ring oscillator selection indices.
//
// Derivation:
//   ro_sel_a = challenge[7:4] XOR {1'b0, bit_index}
//   ro_sel_b = challenge[3:0] XOR {1'b0, bit_index}
//
// This ensures each of the 8 response bits compares a different RO pair
// derived from the same challenge word.
//=============================================================================

module challenge_decoder (
    input  wire [7:0] challenge,
    input  wire [2:0] bit_index,   // 0..7 selects which response bit
    output wire [3:0] ro_sel_a,
    output wire [3:0] ro_sel_b
);

    assign ro_sel_a = challenge[7:4] ^ {1'b0, bit_index};
    assign ro_sel_b = challenge[3:0] ^ {1'b0, bit_index};

endmodule
