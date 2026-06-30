`timescale 1ns / 1ps
//=============================================================================
// MAX7219 7-Segment Display Driver
// SPI-like serial interface. Displays 8 hex digits from display_data[31:0].
//   display_data[31:28] = digit 7 (leftmost)
//   display_data[3:0]   = digit 0 (rightmost)
//
// Initializes decode mode, intensity, scan limit, and normal operation.
// On 'update' pulse, writes all 8 digits.
//=============================================================================

module max7219_driver #(
    parameter integer CLK_FREQ   = 24_000_000,
    parameter integer SPI_CLK_HZ = 1_000_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] display_data,
    input  wire        update,
    output reg         seg_din,
    output reg         seg_clk,
    output reg         seg_load
);

    localparam integer SPI_HALF = CLK_FREQ / (SPI_CLK_HZ * 2);
    localparam integer SW = (SPI_HALF <= 1) ? 1 : $clog2(SPI_HALF + 1);

    //-------------------------------------------------------------------------
    // Hex-to-segment LUT (MAX7219 segment mapping: DP-A-B-C-D-E-F-G)
    //-------------------------------------------------------------------------
    function [7:0] hex_seg;
        input [3:0] h;
        case (h)
            4'h0: hex_seg = 8'h7E;   4'h1: hex_seg = 8'h30;
            4'h2: hex_seg = 8'h6D;   4'h3: hex_seg = 8'h79;
            4'h4: hex_seg = 8'h33;   4'h5: hex_seg = 8'h5B;
            4'h6: hex_seg = 8'h5F;   4'h7: hex_seg = 8'h70;
            4'h8: hex_seg = 8'h7F;   4'h9: hex_seg = 8'h7B;
            4'hA: hex_seg = 8'h77;   4'hB: hex_seg = 8'h1F;
            4'hC: hex_seg = 8'h4E;   4'hD: hex_seg = 8'h3D;
            4'hE: hex_seg = 8'h4F;   4'hF: hex_seg = 8'h47;
        endcase
    endfunction

    //-------------------------------------------------------------------------
    // State machine
    //-------------------------------------------------------------------------
    localparam [2:0]
        ST_INIT  = 3'd0,
        ST_IDLE  = 3'd1,
        ST_LOAD  = 3'd2,
        ST_SHIFT = 3'd3,
        ST_LATCH = 3'd4,
        ST_NEXT  = 3'd5,
        ST_DIGS  = 3'd6;

    reg [2:0]    state;
    reg [15:0]   shift_reg;
    reg [4:0]    bit_cnt;
    reg [SW-1:0] div_cnt;
    reg [3:0]    cmd_idx;
    reg [31:0]   data_buf;
    reg          is_init;

    //-------------------------------------------------------------------------
    // Command word generator (combinational)
    //-------------------------------------------------------------------------
    reg [15:0] cmd_word;

    always @(*) begin
        cmd_word = 16'h0000;
        if (is_init) begin
            case (cmd_idx)
                4'd0: cmd_word = 16'h0900;  // Decode: none
                4'd1: cmd_word = 16'h0A07;  // Intensity: 15/32
                4'd2: cmd_word = 16'h0B07;  // Scan limit: 8 digits
                4'd3: cmd_word = 16'h0C01;  // Normal operation
                4'd4: cmd_word = 16'h0F00;  // Display test: off
                default: cmd_word = 16'h0000;
            endcase
        end else begin
            case (cmd_idx)
                4'd0: cmd_word = {8'h01, hex_seg(data_buf[3:0])};     // Digit 0
                4'd1: cmd_word = {8'h02, hex_seg(data_buf[7:4])};     // Digit 1
                4'd2: cmd_word = {8'h03, hex_seg(data_buf[11:8])};    // Digit 2
                4'd3: cmd_word = {8'h04, hex_seg(data_buf[15:12])};   // Digit 3
                4'd4: cmd_word = {8'h05, hex_seg(data_buf[19:16])};   // Digit 4
                4'd5: cmd_word = {8'h06, hex_seg(data_buf[23:20])};   // Digit 5
                4'd6: cmd_word = {8'h07, hex_seg(data_buf[27:24])};   // Digit 6
                4'd7: cmd_word = {8'h08, hex_seg(data_buf[31:28])};   // Digit 7
                default: cmd_word = 16'h0000;
            endcase
        end
    end

    //-------------------------------------------------------------------------
    // FSM
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state     <= ST_INIT;
            seg_din   <= 1'b0;
            seg_clk   <= 1'b0;
            seg_load  <= 1'b1;
            shift_reg <= 16'h0000;
            bit_cnt   <= 5'd0;
            div_cnt   <= {SW{1'b0}};
            cmd_idx   <= 4'd0;
            data_buf  <= 32'h00000000;
            is_init   <= 1'b1;
        end else begin
            case (state)
                //-------------------------------------------------------------
                ST_INIT: begin
                    is_init <= 1'b1;
                    cmd_idx <= 4'd0;
                    state   <= ST_LOAD;
                end

                //-------------------------------------------------------------
                ST_IDLE: begin
                    seg_load <= 1'b1;
                    seg_clk  <= 1'b0;
                    if (update) begin
                        data_buf <= display_data;
                        is_init  <= 1'b0;
                        cmd_idx  <= 4'd0;
                        state    <= ST_DIGS;
                    end
                end

                //-------------------------------------------------------------
                ST_DIGS: begin
                    state <= ST_LOAD;
                end

                //-------------------------------------------------------------
                ST_LOAD: begin
                    shift_reg <= cmd_word;
                    seg_load  <= 1'b0;
                    seg_din   <= cmd_word[15];
                    bit_cnt   <= 5'd16;
                    div_cnt   <= {SW{1'b0}};
                    seg_clk   <= 1'b0;
                    state     <= ST_SHIFT;
                end

                //-------------------------------------------------------------
                ST_SHIFT: begin
                    if (div_cnt >= SPI_HALF[SW-1:0] - 1) begin
                        div_cnt <= {SW{1'b0}};
                        if (seg_clk == 1'b0) begin
                            // Rising edge: MAX7219 latches current DIN
                            seg_clk <= 1'b1;
                            bit_cnt <= bit_cnt - 1;
                        end else begin
                            // Falling edge: shift and prepare next bit
                            seg_clk   <= 1'b0;
                            shift_reg <= {shift_reg[14:0], 1'b0};
                            if (bit_cnt == 5'd0) begin
                                state <= ST_LATCH;
                            end else begin
                                seg_din <= shift_reg[14];
                            end
                        end
                    end else begin
                        div_cnt <= div_cnt + 1;
                    end
                end

                //-------------------------------------------------------------
                ST_LATCH: begin
                    seg_clk  <= 1'b0;
                    seg_load <= 1'b1;  // Rising edge of LOAD latches data
                    div_cnt  <= div_cnt + 1;
                    if (div_cnt >= SPI_HALF[SW-1:0]) begin
                        div_cnt <= {SW{1'b0}};
                        state   <= ST_NEXT;
                    end
                end

                //-------------------------------------------------------------
                ST_NEXT: begin
                    cmd_idx <= cmd_idx + 1;
                    if (is_init) begin
                        if (cmd_idx >= 4'd4)
                            state <= ST_IDLE;
                        else
                            state <= ST_LOAD;
                    end else begin
                        if (cmd_idx >= 4'd7)
                            state <= ST_IDLE;
                        else
                            state <= ST_DIGS;
                    end
                end

                default: state <= ST_INIT;
            endcase
        end
    end

endmodule
