`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 14:31:06
// Design Name: 
// Module Name: fsm_110
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fsm_110_detector (
    input  wire clk,    // 24 MHz system clock
    input  wire rst,    // Active-high synchronous reset
    input  wire din,    // Serial data input (1 bit per clock)
    output reg  out     // Toggled output: flips on each "011" detection
);

    //------------------------------------------------------------------------
    // State Encoding (Binary)
    //------------------------------------------------------------------------
    localparam [1:0] S_IDLE = 2'b00,  // No bits matched
                     S_0    = 2'b01,  // Received '0' (1st bit of pattern)
                     S_01   = 2'b10,  // Received '0','1' (2nd bit matched)
                     S_011  = 2'b11;  // Received '0','1','1' - DETECTION!

    //------------------------------------------------------------------------
    // State Registers
    //------------------------------------------------------------------------
    reg [1:0] state, next_state;

    //------------------------------------------------------------------------
    // Internal detection signal
    // Goes high for one clock cycle when FSM enters S_011
    //------------------------------------------------------------------------
    wire detect;
    assign detect = (state == S_011);

    //------------------------------------------------------------------------
    // Block 1: State Register (Sequential)
    // Synchronous reset, updates state on rising clock edge
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    //------------------------------------------------------------------------
    // Block 2: Next-State Logic (Combinational)
    //
    // Transition rules:
    //   S_IDLE + 0 → S_0        (0 starts the pattern)
    //   S_IDLE + 1 → S_IDLE     (1 doesn't start pattern)
    //   S_0    + 0 → S_0        (new 0 restarts; could be new start)
    //   S_0    + 1 → S_01       (0→1 matched)
    //   S_01   + 0 → S_0        (overlap: 0 restarts the pattern)
    //   S_01   + 1 → S_011      (0→1→1 complete match!)
    //   S_011  + 0 → S_0        (overlap: 0 starts new pattern)
    //   S_011  + 1 → S_IDLE     (1 alone can't start pattern 0,1,1)
    //------------------------------------------------------------------------
    always @(*) begin
        case (state)
            S_IDLE: begin
                if (din == 1'b0)
                    next_state = S_0;
                else
                    next_state = S_IDLE;
            end

            S_0: begin
                if (din == 1'b1)
                    next_state = S_01;
                else
                    next_state = S_0;   // Another 0; restart
            end

            S_01: begin
                if (din == 1'b1)
                    next_state = S_011;  // Pattern complete!
                else
                    next_state = S_0;    // Overlap: 0 restarts
            end

            S_011: begin
                if (din == 1'b0)
                    next_state = S_0;    // Overlap: 0 starts new
                else
                    next_state = S_IDLE; // 1 can't start pattern
            end

            default: next_state = S_IDLE;
        endcase
    end

    //------------------------------------------------------------------------
    // Block 3: Output Logic (Sequential - Toggle Register)
    //
    // The output is a toggle register that flips every time the FSM
    // enters the detection state S_011. This is Moore-style: the
    // detection is purely a function of the current state.
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            out <= 1'b0;
        else if (detect)
            out <= ~out;
    end

endmodule
