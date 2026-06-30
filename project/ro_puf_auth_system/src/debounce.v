`timescale 1ns / 1ps
//=============================================================================
// Button Debouncer
// Synchronizes and debounces an active-low push button input.
// Outputs active-high debounced level and a single-cycle press pulse.
//=============================================================================

module debounce #(
    parameter integer CLK_FREQ    = 24_000_000,
    parameter integer DEBOUNCE_MS = 20
)(
    input  wire clk,
    input  wire rst,
    input  wire btn_in,     // Raw button (active low: 0=pressed)
    output reg  btn_out,    // Debounced level (active high: 1=pressed)
    output reg  btn_pulse   // Single-cycle pulse on press event
);

    localparam integer COUNT_MAX = (CLK_FREQ / 1000) * DEBOUNCE_MS;
    localparam integer CW = $clog2(COUNT_MAX + 1);

    //-------------------------------------------------------------------------
    // 2-FF synchronizer
    //-------------------------------------------------------------------------
    reg sync_ff0, sync_ff1;

    always @(posedge clk) begin
        if (rst) begin
            sync_ff0 <= 1'b1;
            sync_ff1 <= 1'b1;
        end else begin
            sync_ff0 <= btn_in;
            sync_ff1 <= sync_ff0;
        end
    end

    // Invert synchronised input: active-high pressed signal
    wire btn_pressed = ~sync_ff1;

    //-------------------------------------------------------------------------
    // Debounce counter
    //-------------------------------------------------------------------------
    reg [CW-1:0] counter;
    reg           btn_prev;

    always @(posedge clk) begin
        if (rst) begin
            counter   <= {CW{1'b0}};
            btn_out   <= 1'b0;
            btn_prev  <= 1'b0;
            btn_pulse <= 1'b0;
        end else begin
            btn_prev  <= btn_out;
            btn_pulse <= 1'b0;

            if (btn_pressed != btn_out) begin
                if (counter >= COUNT_MAX[CW-1:0]) begin
                    counter <= {CW{1'b0}};
                    btn_out <= btn_pressed;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                counter <= {CW{1'b0}};
            end

            // Rising-edge detect on debounced output
            if (btn_out && !btn_prev)
                btn_pulse <= 1'b1;
        end
    end

endmodule
