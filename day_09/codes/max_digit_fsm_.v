`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 14:34:19
// Design Name: 
// Module Name: max_digit_fsm_
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


module max_digit_fsm (
    input  wire       clk,      // 24 MHz system clock
    input  wire       rst,      // Active-high synchronous reset
    input  wire [1:0] din,      // 2-bit input digit (0, 1, 2, or 3)
    output reg  [1:0] max_out   // 2-bit output: largest digit seen
);

    //------------------------------------------------------------------------
    // State Encoding (Binary - state value equals output value)
    //------------------------------------------------------------------------
    localparam [1:0] MAX_0 = 2'd0,  // Maximum seen = 0
                     MAX_1 = 2'd1,  // Maximum seen = 1
                     MAX_2 = 2'd2,  // Maximum seen = 2
                     MAX_3 = 2'd3;  // Maximum seen = 3 (absorbing)

    //------------------------------------------------------------------------
    // State Registers
    //------------------------------------------------------------------------
    reg [1:0] state, next_state;

    //------------------------------------------------------------------------
    // Block 1: State Register (Sequential)
    // Synchronous reset, updates state on rising clock edge
    //------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            state <= MAX_0;
        else
            state <= next_state;
    end

    //------------------------------------------------------------------------
    // Block 2: Next-State Logic (Combinational)
    //
    // Rule: transition to the state corresponding to max(current_state, din)
    // This means: if din > current state, go to the din state.
    //             if din <= current state, stay in current state.
    //------------------------------------------------------------------------
    always @(*) begin
        case (state)
            MAX_0: begin
                // Current max = 0, any input >= 1 raises the max
                if (din >= 2'd3)
                    next_state = MAX_3;
                else if (din >= 2'd2)
                    next_state = MAX_2;
                else if (din >= 2'd1)
                    next_state = MAX_1;
                else
                    next_state = MAX_0;
            end

            MAX_1: begin
                // Current max = 1, only inputs >= 2 raise the max
                if (din >= 2'd3)
                    next_state = MAX_3;
                else if (din >= 2'd2)
                    next_state = MAX_2;
                else
                    next_state = MAX_1;
            end

            MAX_2: begin
                // Current max = 2, only input 3 raises the max
                if (din >= 2'd3)
                    next_state = MAX_3;
                else
                    next_state = MAX_2;
            end

            MAX_3: begin
                // Absorbing state: max is already 3, cannot increase
                next_state = MAX_3;
            end

            default: next_state = MAX_0;
        endcase
    end

    //------------------------------------------------------------------------
    // Block 3: Output Logic (Combinational - Moore)
    //
    // Output equals the current state value. Since state encoding matches
    // the output value, the output is simply the state register.
    //------------------------------------------------------------------------
    always @(*) begin
        case (state)
            MAX_0:   max_out = 2'd0;
            MAX_1:   max_out = 2'd1;
            MAX_2:   max_out = 2'd2;
            MAX_3:   max_out = 2'd3;
            default: max_out = 2'd0;
        endcase
    end

endmodule

