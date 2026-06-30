`timescale 1ns / 1ps
//=============================================================================
// UART Controller
// Higher-level UART protocol handler. On dump_trigger, transmits a formatted
// PUF status report over UART.
//
// Output format (ASCII hex):
//   "PUF AUTH SYSTEM\r\n"
//   "CHL:XX\r\n"           (challenge hex)
//   "RSP:XX\r\n"           (current response hex)
//   "STO:XX\r\n"           (stored response hex)
//   "CTA:XXXXXXXX\r\n"     (count_a hex)
//   "CTB:XXXXXXXX\r\n"     (count_b hex)
//   "STS:X\r\n"            (state hex)
//   "ENR:X\r\n"            (enrolled flag)
//   "\r\n"
//
// Instantiates: uart_tx, uart_rx
//=============================================================================

module uart_controller #(
    parameter integer CLK_FREQ  = 24_000_000,
    parameter integer BAUD_RATE = 115200
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        dump_trigger,
    input  wire [7:0]  challenge,
    input  wire [7:0]  current_response,
    input  wire [7:0]  stored_response,
    input  wire        auth_pass,
    input  wire        auth_fail,
    input  wire        enrolled,
    input  wire [31:0] count_a,
    input  wire [31:0] count_b,
    input  wire [3:0]  state_in,
    output wire        uart_txd,
    input  wire        uart_rxd
);

    //-------------------------------------------------------------------------
    // Hex-to-ASCII function
    //-------------------------------------------------------------------------
    function [7:0] hex_ascii;
        input [3:0] nibble;
        hex_ascii = (nibble < 4'd10) ? (8'h30 + {4'd0, nibble})
                                      : (8'h37 + {4'd0, nibble});
    endfunction

    //-------------------------------------------------------------------------
    // UART TX instance
    //-------------------------------------------------------------------------
    reg        tx_start;
    reg  [7:0] tx_byte;
    wire       tx_busy;
    wire       tx_done;
    wire       tx_out_w;

    uart_tx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_tx (
        .clk      (clk),
        .rst      (rst),
        .tx_data  (tx_byte),
        .tx_start (tx_start),
        .tx_out   (tx_out_w),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done)
    );

    assign uart_txd = tx_out_w;

    //-------------------------------------------------------------------------
    // UART RX instance (active but not used for commands in this design)
    //-------------------------------------------------------------------------
    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_rx (
        .clk      (clk),
        .rst      (rst),
        .rx_in    (uart_rxd),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

    //-------------------------------------------------------------------------
    // Message ROM — fixed template with field slots
    // Total message layout (each entry is a byte):
    //   Bytes 0-14:   "PUF AUTH SYSTEM"
    //   Bytes 15-16:  \r\n
    //   Bytes 17-20:  "CHL:"
    //   Bytes 21-22:  <chl_hi> <chl_lo>
    //   Bytes 23-24:  \r\n
    //   Bytes 25-28:  "RSP:"
    //   Bytes 29-30:  <rsp_hi> <rsp_lo>
    //   Bytes 31-32:  \r\n
    //   Bytes 33-36:  "STO:"
    //   Bytes 37-38:  <sto_hi> <sto_lo>
    //   Bytes 39-40:  \r\n
    //   Bytes 41-44:  "CTA:"
    //   Bytes 45-52:  <cta 8 hex digits>
    //   Bytes 53-54:  \r\n
    //   Bytes 55-58:  "CTB:"
    //   Bytes 59-66:  <ctb 8 hex digits>
    //   Bytes 67-68:  \r\n
    //   Bytes 69-72:  "STS:"
    //   Byte  73:     <sts>
    //   Bytes 74-75:  \r\n
    //   Bytes 76-79:  "ENR:"
    //   Byte  80:     <enr>
    //   Bytes 81-82:  \r\n
    //   Bytes 83-84:  \r\n  (trailing blank line)
    //   Total = 85 bytes
    //-------------------------------------------------------------------------
    localparam integer MSG_LEN = 85;

    //-------------------------------------------------------------------------
    // Snapshot registers
    //-------------------------------------------------------------------------
    reg [7:0]  snap_chl, snap_rsp, snap_sto;
    reg [31:0] snap_cta, snap_ctb;
    reg [3:0]  snap_sts;
    reg        snap_enr;

    //-------------------------------------------------------------------------
    // Byte lookup — returns the byte at position 'idx' in the message
    //-------------------------------------------------------------------------
    reg [7:0] cur_byte;
    reg [6:0] msg_idx;

    always @(*) begin
        case (msg_idx)
            // "PUF AUTH SYSTEM\r\n"
            7'd0:  cur_byte = "P";
            7'd1:  cur_byte = "U";
            7'd2:  cur_byte = "F";
            7'd3:  cur_byte = " ";
            7'd4:  cur_byte = "A";
            7'd5:  cur_byte = "U";
            7'd6:  cur_byte = "T";
            7'd7:  cur_byte = "H";
            7'd8:  cur_byte = " ";
            7'd9:  cur_byte = "S";
            7'd10: cur_byte = "Y";
            7'd11: cur_byte = "S";
            7'd12: cur_byte = "T";
            7'd13: cur_byte = "E";
            7'd14: cur_byte = "M";
            7'd15: cur_byte = 8'h0D;
            7'd16: cur_byte = 8'h0A;
            // "CHL:XX\r\n"
            7'd17: cur_byte = "C";
            7'd18: cur_byte = "H";
            7'd19: cur_byte = "L";
            7'd20: cur_byte = ":";
            7'd21: cur_byte = hex_ascii(snap_chl[7:4]);
            7'd22: cur_byte = hex_ascii(snap_chl[3:0]);
            7'd23: cur_byte = 8'h0D;
            7'd24: cur_byte = 8'h0A;
            // "RSP:XX\r\n"
            7'd25: cur_byte = "R";
            7'd26: cur_byte = "S";
            7'd27: cur_byte = "P";
            7'd28: cur_byte = ":";
            7'd29: cur_byte = hex_ascii(snap_rsp[7:4]);
            7'd30: cur_byte = hex_ascii(snap_rsp[3:0]);
            7'd31: cur_byte = 8'h0D;
            7'd32: cur_byte = 8'h0A;
            // "STO:XX\r\n"
            7'd33: cur_byte = "S";
            7'd34: cur_byte = "T";
            7'd35: cur_byte = "O";
            7'd36: cur_byte = ":";
            7'd37: cur_byte = hex_ascii(snap_sto[7:4]);
            7'd38: cur_byte = hex_ascii(snap_sto[3:0]);
            7'd39: cur_byte = 8'h0D;
            7'd40: cur_byte = 8'h0A;
            // "CTA:XXXXXXXX\r\n"
            7'd41: cur_byte = "C";
            7'd42: cur_byte = "T";
            7'd43: cur_byte = "A";
            7'd44: cur_byte = ":";
            7'd45: cur_byte = hex_ascii(snap_cta[31:28]);
            7'd46: cur_byte = hex_ascii(snap_cta[27:24]);
            7'd47: cur_byte = hex_ascii(snap_cta[23:20]);
            7'd48: cur_byte = hex_ascii(snap_cta[19:16]);
            7'd49: cur_byte = hex_ascii(snap_cta[15:12]);
            7'd50: cur_byte = hex_ascii(snap_cta[11:8]);
            7'd51: cur_byte = hex_ascii(snap_cta[7:4]);
            7'd52: cur_byte = hex_ascii(snap_cta[3:0]);
            7'd53: cur_byte = 8'h0D;
            7'd54: cur_byte = 8'h0A;
            // "CTB:XXXXXXXX\r\n"
            7'd55: cur_byte = "C";
            7'd56: cur_byte = "T";
            7'd57: cur_byte = "B";
            7'd58: cur_byte = ":";
            7'd59: cur_byte = hex_ascii(snap_ctb[31:28]);
            7'd60: cur_byte = hex_ascii(snap_ctb[27:24]);
            7'd61: cur_byte = hex_ascii(snap_ctb[23:20]);
            7'd62: cur_byte = hex_ascii(snap_ctb[19:16]);
            7'd63: cur_byte = hex_ascii(snap_ctb[15:12]);
            7'd64: cur_byte = hex_ascii(snap_ctb[11:8]);
            7'd65: cur_byte = hex_ascii(snap_ctb[7:4]);
            7'd66: cur_byte = hex_ascii(snap_ctb[3:0]);
            7'd67: cur_byte = 8'h0D;
            7'd68: cur_byte = 8'h0A;
            // "STS:X\r\n"
            7'd69: cur_byte = "S";
            7'd70: cur_byte = "T";
            7'd71: cur_byte = "S";
            7'd72: cur_byte = ":";
            7'd73: cur_byte = hex_ascii(snap_sts);
            7'd74: cur_byte = 8'h0D;
            7'd75: cur_byte = 8'h0A;
            // "ENR:X\r\n"
            7'd76: cur_byte = "E";
            7'd77: cur_byte = "N";
            7'd78: cur_byte = "R";
            7'd79: cur_byte = ":";
            7'd80: cur_byte = snap_enr ? "1" : "0";
            7'd81: cur_byte = 8'h0D;
            7'd82: cur_byte = 8'h0A;
            // Trailing \r\n
            7'd83: cur_byte = 8'h0D;
            7'd84: cur_byte = 8'h0A;
            default: cur_byte = 8'h00;
        endcase
    end

    //-------------------------------------------------------------------------
    // State machine
    //-------------------------------------------------------------------------
    localparam [1:0]
        ST_IDLE    = 2'd0,
        ST_SEND    = 2'd1,
        ST_WAIT_TX = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state    <= ST_IDLE;
            tx_start <= 1'b0;
            tx_byte  <= 8'h00;
            msg_idx  <= 7'd0;
            snap_chl <= 8'h00;
            snap_rsp <= 8'h00;
            snap_sto <= 8'h00;
            snap_cta <= 32'h00000000;
            snap_ctb <= 32'h00000000;
            snap_sts <= 4'h0;
            snap_enr <= 1'b0;
        end else begin
            tx_start <= 1'b0;

            case (state)
                //-------------------------------------------------------------
                ST_IDLE: begin
                    if (dump_trigger) begin
                        // Snapshot current values
                        snap_chl <= challenge;
                        snap_rsp <= current_response;
                        snap_sto <= stored_response;
                        snap_cta <= count_a;
                        snap_ctb <= count_b;
                        snap_sts <= state_in;
                        snap_enr <= enrolled;
                        msg_idx  <= 7'd0;
                        state    <= ST_SEND;
                    end
                end

                //-------------------------------------------------------------
                ST_SEND: begin
                    if (msg_idx >= MSG_LEN[6:0]) begin
                        state <= ST_IDLE;
                    end else if (!tx_busy) begin
                        tx_byte  <= cur_byte;
                        tx_start <= 1'b1;
                        state    <= ST_WAIT_TX;
                    end
                end

                //-------------------------------------------------------------
                ST_WAIT_TX: begin
                    if (tx_done) begin
                        msg_idx <= msg_idx + 1;
                        state   <= ST_SEND;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
