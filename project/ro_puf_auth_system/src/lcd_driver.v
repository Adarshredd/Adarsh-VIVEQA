`timescale 1ns / 1ps
//=============================================================================
// LCD Driver — 16x2 Character LCD, 8-bit parallel mode
//
// Initialization sequence: Function Set (0x38) -> Display ON (0x0C) ->
//   Entry Mode (0x06) -> Clear Display (0x01)
//
// Data format:
//   line1[127:120] = first character of line 1
//   line1[7:0]     = last character of line 1
//   (same for line2)
//
// On 'update' pulse: latches both lines and writes all 32 characters.
// 'ready' asserted when idle and accepting new data.
//=============================================================================


module lcd_driver #(
    parameter integer CLK_FREQ = 24_000_000
)(
    input  wire          clk,
    input  wire          rst,
    input  wire [127:0]  line1,
    input  wire [127:0]  line2,
    input  wire          update,
    output reg           lcd_rs,
    output wire          lcd_rw,
    output reg           lcd_en,
    output reg  [7:0]    lcd_d,
    output reg           ready
);

    assign lcd_rw = 1'b0;  // Always write

    //-------------------------------------------------------------------------
    // Timing constants (clock cycles)
    //-------------------------------------------------------------------------
    localparam integer T_40MS   = (CLK_FREQ / 1000) * 40;   // Power-on wait
    localparam integer T_CMD    = (CLK_FREQ / 1000000) * 50; // 50 us cmd wait
    localparam integer T_CLEAR  = (CLK_FREQ / 1000) * 2;    // 2 ms clear wait
    localparam integer T_EN     = 12;                         // Enable pulse (~500ns)

    localparam integer TW = $clog2(T_40MS + 1);

    //-------------------------------------------------------------------------
    // State machine
    //-------------------------------------------------------------------------
    localparam [3:0]
        ST_POWERON   = 4'd0,
        ST_INIT      = 4'd1,
        ST_IDLE      = 4'd2,
        ST_ADDR      = 4'd3,
        ST_WRITE     = 4'd4,
        ST_EXEC_SETUP = 4'd5,
        ST_EXEC_EN    = 4'd6,
        ST_EXEC_WAIT  = 4'd7;

    reg [3:0]    state;
    reg [3:0]    return_state;
    reg [TW-1:0] wait_cnt;
    reg [TW-1:0] wait_target;
    reg [3:0]    init_step;
    reg [4:0]    char_idx;
    reg          line_sel;        // 0 = line1, 1 = line2
    reg [127:0]  line1_buf;
    reg [127:0]  line2_buf;
    reg [7:0]    wr_byte;
    reg          wr_rs;
    reg [3:0]    en_cnt;

    //-------------------------------------------------------------------------
    // Character extraction helper
    //-------------------------------------------------------------------------
    function [7:0] get_char;
        input [127:0] line_data;
        input [3:0]   idx;
    begin
        case (idx)
            4'd0:  get_char = line_data[127:120];
            4'd1:  get_char = line_data[119:112];
            4'd2:  get_char = line_data[111:104];
            4'd3:  get_char = line_data[103:96];
            4'd4:  get_char = line_data[95:88];
            4'd5:  get_char = line_data[87:80];
            4'd6:  get_char = line_data[79:72];
            4'd7:  get_char = line_data[71:64];
            4'd8:  get_char = line_data[63:56];
            4'd9:  get_char = line_data[55:48];
            4'd10: get_char = line_data[47:40];
            4'd11: get_char = line_data[39:32];
            4'd12: get_char = line_data[31:24];
            4'd13: get_char = line_data[23:16];
            4'd14: get_char = line_data[15:8];
            4'd15: get_char = line_data[7:0];
        endcase
    end
    endfunction

    //-------------------------------------------------------------------------
    // Main FSM
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state        <= ST_POWERON;
            return_state <= ST_INIT;
            wait_cnt     <= {TW{1'b0}};
            wait_target  <= T_40MS[TW-1:0];
            init_step    <= 4'd0;
            char_idx     <= 5'd0;
            line_sel     <= 1'b0;
            lcd_rs       <= 1'b0;
            lcd_en       <= 1'b0;
            lcd_d        <= 8'h00;
            ready        <= 1'b0;
            line1_buf    <= 128'd0;
            line2_buf    <= 128'd0;
            wr_byte      <= 8'h00;
            wr_rs        <= 1'b0;
            en_cnt       <= 4'd0;
        end else begin
            case (state)
                //=============================================================
                ST_POWERON: begin
                    ready <= 1'b0;
                    if (wait_cnt >= wait_target) begin
                        wait_cnt  <= {TW{1'b0}};
                        init_step <= 4'd0;
                        state     <= ST_INIT;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end

                //=============================================================
                ST_INIT: begin
                    case (init_step)
                        4'd0: begin  // Function Set: 8-bit, 2-line, 5x8
                            wr_byte      <= 8'h38;
                            wr_rs        <= 1'b0;
                            wait_target  <= T_CMD[TW-1:0];
                            return_state <= ST_INIT;
                            init_step    <= 4'd1;
                            state        <= ST_EXEC_SETUP;
                        end
                        4'd1: begin  // Display ON, cursor OFF
                            wr_byte      <= 8'h0C;
                            wr_rs        <= 1'b0;
                            wait_target  <= T_CMD[TW-1:0];
                            return_state <= ST_INIT;
                            init_step    <= 4'd2;
                            state        <= ST_EXEC_SETUP;
                        end
                        4'd2: begin  // Entry Mode: increment, no shift
                            wr_byte      <= 8'h06;
                            wr_rs        <= 1'b0;
                            wait_target  <= T_CMD[TW-1:0];
                            return_state <= ST_INIT;
                            init_step    <= 4'd3;
                            state        <= ST_EXEC_SETUP;
                        end
                        4'd3: begin  // Clear Display
                            wr_byte      <= 8'h01;
                            wr_rs        <= 1'b0;
                            wait_target  <= T_CLEAR[TW-1:0];
                            return_state <= ST_INIT;
                            init_step    <= 4'd4;
                            state        <= ST_EXEC_SETUP;
                        end
                        default: begin
                            state <= ST_IDLE;
                        end
                    endcase
                end

                //=============================================================
                ST_IDLE: begin
                    ready  <= 1'b1;
                    lcd_en <= 1'b0;
                    if (update) begin
                        ready     <= 1'b0;
                        line1_buf <= line1;
                        line2_buf <= line2;
                        line_sel  <= 1'b0;
                        char_idx  <= 5'd0;
                        state     <= ST_ADDR;
                    end
                end

                //=============================================================
                // Set DDRAM address for current line
                ST_ADDR: begin
                    wr_byte      <= (line_sel == 1'b0) ? 8'h80 : 8'hC0;
                    wr_rs        <= 1'b0;
                    wait_target  <= T_CMD[TW-1:0];
                    return_state <= ST_WRITE;
                    char_idx     <= 5'd0;
                    state        <= ST_EXEC_SETUP;
                end

                //=============================================================
                // Write characters sequentially
                ST_WRITE: begin
                    if (char_idx == 5'd16) begin
                        if (line_sel == 1'b0) begin
                            line_sel <= 1'b1;
                            state    <= ST_ADDR;
                        end else begin
                            state <= ST_IDLE;
                        end
                    end else begin
                        if (line_sel == 1'b0)
                            wr_byte <= get_char(line1_buf, char_idx[3:0]);
                        else
                            wr_byte <= get_char(line2_buf, char_idx[3:0]);
                        wr_rs        <= 1'b1;
                        wait_target  <= T_CMD[TW-1:0];
                        return_state <= ST_WRITE;
                        char_idx     <= char_idx + 1;
                        state        <= ST_EXEC_SETUP;
                    end
                end

                //=============================================================
                // Sub-state: setup data on bus
                ST_EXEC_SETUP: begin
                    lcd_rs <= wr_rs;
                    lcd_d  <= wr_byte;
                    lcd_en <= 1'b0;
                    en_cnt <= 4'd0;
                    state  <= ST_EXEC_EN;
                end

                //=============================================================
                // Sub-state: pulse enable high
                ST_EXEC_EN: begin
                    lcd_en <= 1'b1;
                    if (en_cnt >= T_EN[3:0]) begin
                        lcd_en   <= 1'b0;
                        wait_cnt <= {TW{1'b0}};
                        state    <= ST_EXEC_WAIT;
                    end else begin
                        en_cnt <= en_cnt + 1;
                    end
                end

                //=============================================================
                // Sub-state: wait for command execution time
                ST_EXEC_WAIT: begin
                    lcd_en <= 1'b0;
                    if (wait_cnt >= wait_target) begin
                        wait_cnt <= {TW{1'b0}};
                        state    <= return_state;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end

                default: state <= ST_POWERON;
            endcase
        end
    end

endmodule
