`timescale 1ns / 1ps
//=============================================================================
// Top-Level Module: Ring Oscillator PUF Authentication System
// Target Board: AT-STLN-ARTIX7-001 (XC7A35T, 24MHz clock)
//
// Hierarchy:
//   top
//   ├── ring_oscillator [0:15] (generate)
//   ├── debounce [0:5]         (6 buttons)
//   ├── authentication_controller
//   │   └── response_generator
//   │       ├── challenge_decoder
//   │       ├── measurement_controller
//   │       │   ├── ro_selector_mux
//   │       │   └── frequency_counter [0:1]
//   │       └── comparator
//   ├── uart_controller
//   │   ├── uart_tx
//   │   └── uart_rx
//   ├── lcd_driver
//   ├── max7219_driver
//   ├── led_controller
//   ├── buzzer_controller
//   └── clock_divider
//=============================================================================

module top #(
    parameter integer CLK_FREQ = 24_000_000
) (
    //--- Clock
    input  wire       clk_24mhz,

    //--- Slide Switches
    input  wire [7:0] sw,

    //--- LEDs
    output wire [7:0] led,

    //--- Push Buttons (active low)
    input  wire       btn_enroll,
    input  wire       btn_auth,
    input  wire       btn_measure,
    input  wire       btn_clear,
    input  wire       btn_uart_dump,
    // input  wire       btn_reserved,

    //--- 16x2 LCD (8-bit mode)
//     output wire       lcd_rs,
//     output wire       lcd_rw,
//     output wire       lcd_en,
//     output wire [7:0] lcd_d,

//    --- MAX7219 7-Segment Display
     output wire       seg_din,
     output wire       seg_load,
     output wire       seg_clk,

    //--- UART
    output wire       uart_tx,
    input  wire       uart_rx,

    //--- Buzzer
    output wire       buzzer
);

    //--- Dummy Wires for Unconnected Board Peripherals ---
    wire btn_reserved = 1'b1;
//   wire lcd_rs;
//    wire lcd_rw;
//    wire lcd_en;
//    wire [7:0] lcd_d;
//    wire seg_din;
//    wire seg_load;
//    wire seg_clk;
//    wire buzzer;

    //=========================================================================
    // Power-On Reset
    //=========================================================================
    reg [7:0] por_sr = 8'h00;
    wire por_rst = ~(&por_sr);

    always @(posedge clk_24mhz)
        por_sr <= {por_sr[6:0], 1'b1};

    //=========================================================================
    // Button Debouncers
    //=========================================================================
    wire db_enroll, db_auth, db_measure, db_clear, db_dump, db_reset;
    wire pulse_enroll, pulse_auth, pulse_measure, pulse_clear, pulse_dump, pulse_reset;

    debounce #(.CLK_FREQ(CLK_FREQ)) u_db_enroll (
        .clk(clk_24mhz), .rst(por_rst), .btn_in(btn_enroll),
        .btn_out(db_enroll), .btn_pulse(pulse_enroll)
    );
    debounce #(.CLK_FREQ(CLK_FREQ)) u_db_auth (
        .clk(clk_24mhz), .rst(por_rst), .btn_in(btn_auth),
        .btn_out(db_auth), .btn_pulse(pulse_auth)
    );
    debounce #(.CLK_FREQ(CLK_FREQ)) u_db_measure (
        .clk(clk_24mhz), .rst(por_rst), .btn_in(btn_measure),
        .btn_out(db_measure), .btn_pulse(pulse_measure)
    );
    debounce #(.CLK_FREQ(CLK_FREQ)) u_db_clear (
        .clk(clk_24mhz), .rst(por_rst), .btn_in(btn_clear),
        .btn_out(db_clear), .btn_pulse(pulse_clear)
    );
    debounce #(.CLK_FREQ(CLK_FREQ)) u_db_dump (
        .clk(clk_24mhz), .rst(por_rst), .btn_in(btn_uart_dump),
        .btn_out(db_dump), .btn_pulse(pulse_dump)
    );
    debounce #(.CLK_FREQ(CLK_FREQ)) u_db_reset (
        .clk(clk_24mhz), .rst(por_rst), .btn_in(btn_reserved),
        .btn_out(db_reset), .btn_pulse(pulse_reset)
    );

    // System reset: POR or manual reset button
    wire sys_rst = por_rst | db_reset;

    //=========================================================================
    // Ring Oscillators (16 instances)
    //=========================================================================
    wire [15:0] ro_osc_out;
    wire [15:0] ro_enable;

    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : gen_ro
            ring_oscillator #(
                .RO_INDEX (gi)
            ) u_ro (
                .enable  (ro_enable[gi]),
                .osc_out (ro_osc_out[gi])
            );
        end
    endgenerate

    //=========================================================================
    // Authentication Controller
    //=========================================================================
    wire [7:0]  auth_cur_response;
    wire [7:0]  auth_sto_response;
    wire        auth_pass_pulse;
    wire        auth_fail_pulse;
    wire        auth_enrolled;
    wire        auth_busy;
    wire [3:0]  auth_state;
    wire [31:0] auth_count_a;
    wire [31:0] auth_count_b;
    wire        auth_meas_valid;

    authentication_controller #(
        .GATE_CYCLES   (65536),
        .SETTLE_CYCLES (1024),
        .THRESHOLD     (1)
    ) u_auth (
        .clk              (clk_24mhz),
        .rst              (sys_rst),
        .btn_enroll       (pulse_enroll),
        .btn_auth         (pulse_auth),
        .btn_measure      (pulse_measure),
        .btn_clear        (pulse_clear),
        .sw               (sw),
        .ro_osc_out       (ro_osc_out),
        .ro_enable        (ro_enable),
        .current_response (auth_cur_response),
        .stored_response  (auth_sto_response),
        .auth_pass        (auth_pass_pulse),
        .auth_fail        (auth_fail_pulse),
        .enrolled         (auth_enrolled),
        .busy             (auth_busy),
        .state_out        (auth_state),
        .last_count_a     (auth_count_a),
        .last_count_b     (auth_count_b),
        .measure_valid    (auth_meas_valid)
    );

    //=========================================================================
    // UART Controller
    //=========================================================================
    uart_controller #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (115200)
    ) u_uart (
        .clk              (clk_24mhz),
        .rst              (sys_rst),
        .dump_trigger     (pulse_dump),
        .challenge        (sw),
        .current_response (auth_cur_response),
        .stored_response  (auth_sto_response),
        .auth_pass        (auth_pass_pulse),
        .auth_fail        (auth_fail_pulse),
        .enrolled         (auth_enrolled),
        .count_a          (auth_count_a),
        .count_b          (auth_count_b),
        .state_in         (auth_state),
        .uart_txd         (uart_tx),
        .uart_rxd         (uart_rx)
    );

    //=========================================================================
    // LCD Driver
    //=========================================================================
    // LCD text formatting
    reg [127:0] lcd_line1, lcd_line2;
    reg         lcd_update;
    wire        lcd_ready;

    wire        lcd_rs_w, lcd_en_w;
    wire [7:0]  lcd_d_w;

    lcd_driver #(.CLK_FREQ(CLK_FREQ)) u_lcd (
        .clk    (clk_24mhz),
        .rst    (sys_rst),
        .line1  (lcd_line1),
        .line2  (lcd_line2),
        .update (lcd_update),
        .lcd_rs (lcd_rs_w),
        .lcd_rw (lcd_rw),
        .lcd_en (lcd_en_w),
        .lcd_d  (lcd_d_w),
        .ready  (lcd_ready)
    );

    assign lcd_rs = lcd_rs_w;
    assign lcd_en = lcd_en_w;
    assign lcd_d  = lcd_d_w;

    //--- LCD Text Formatter ---
    // Helper function: nibble to ASCII hex char
    function [7:0] nib2hex;
        input [3:0] n;
        nib2hex = (n < 4'd10) ? (8'h30 + {4'd0, n}) : (8'h41 + {4'd0, n} - 8'd10);
    endfunction

    // State name strings (packed 16 chars each)
    function [127:0] state_string;
        input [3:0] s;
        case (s)
            //              "1234567890123456"
            4'd0: state_string = "RO-PUF AUTH SYS ";
            4'd1: state_string = "  ENROLLING...  ";
            4'd2: state_string = "   ENROLLED!    ";
            4'd3: state_string = "AUTHENTICATING..";
            4'd4: state_string = "  COMPARING...  ";
            4'd5: state_string = " ** AUTH PASS **";
            4'd6: state_string = " !! AUTH FAIL !!";
            4'd7: state_string = "  MEASURING...  ";
            4'd8: state_string = " MEASURE  DONE  ";
            4'd9: state_string = "  CLEARING...   ";
            default: state_string = "                ";
        endcase
    endfunction

    // Update LCD periodically
    reg [19:0] lcd_refresh_cnt;
    reg        lcd_trig;

    always @(posedge clk_24mhz) begin
        if (sys_rst) begin
            lcd_refresh_cnt <= 20'd0;
            lcd_trig        <= 1'b0;
        end else begin
            lcd_trig <= 1'b0;
            if (lcd_refresh_cnt == 20'd999_999) begin  // ~24 Hz refresh
                lcd_refresh_cnt <= 20'd0;
                lcd_trig        <= 1'b1;
            end else begin
                lcd_refresh_cnt <= lcd_refresh_cnt + 1;
            end
        end
    end

    always @(posedge clk_24mhz) begin
        if (sys_rst) begin
            lcd_line1  <= "RO-PUF AUTH SYS ";
            lcd_line2  <= "SW:00 RSP:00 E:0";
            lcd_update <= 1'b0;
        end else begin
            lcd_update <= 1'b0;
            if (lcd_trig && lcd_ready) begin
                lcd_line1 <= state_string(auth_state);
                // Line 2: "SW:XX RSP:XX E:X"
                lcd_line2 <= {"S","W",":",
                              nib2hex(sw[7:4]), nib2hex(sw[3:0]),
                              " ","R","S","P",":",
                              nib2hex(auth_cur_response[7:4]),
                              nib2hex(auth_cur_response[3:0]),
                              " ","E",":",
                              auth_enrolled ? "Y" : "N"};
                lcd_update <= 1'b1;
            end
        end
    end

    //=========================================================================
    // MAX7219 7-Segment Display
    //=========================================================================
    reg [31:0] seg_display_data;
    reg        seg_update;
    reg [19:0] seg_refresh_cnt;

    max7219_driver #(
        .CLK_FREQ   (CLK_FREQ),
        .SPI_CLK_HZ (1_000_000)
    ) u_seg (
        .clk          (clk_24mhz),
        .rst          (sys_rst),
        .display_data (seg_display_data),
        .update       (seg_update),
        .seg_din      (seg_din),
        .seg_clk      (seg_clk),
        .seg_load     (seg_load)
    );

    // Display: upper 4 digits = count_a[15:0], lower 4 digits = count_b[15:0]
    // In idle: show challenge and response
    always @(posedge clk_24mhz) begin
        if (sys_rst) begin
            seg_display_data <= 32'h00000000;
            seg_update       <= 1'b0;
            seg_refresh_cnt  <= 20'd0;
        end else begin
            seg_update <= 1'b0;
            seg_refresh_cnt <= seg_refresh_cnt + 1;

            if (seg_refresh_cnt == 20'd999_999) begin
                seg_refresh_cnt <= 20'd0;
                seg_update      <= 1'b1;

                case (auth_state)
                    4'd0: // IDLE: show challenge and response
                        seg_display_data <= {16'h0000, sw, auth_cur_response};
                    4'd5, 4'd6: // PASS/FAIL: show stored vs current
                        seg_display_data <= {8'h00, auth_sto_response,
                                             8'h00, auth_cur_response};
                    4'd8: // MEASURE_DONE: show counts
                        seg_display_data <= {auth_count_a[15:0],
                                             auth_count_b[15:0]};
                    default:
                        seg_display_data <= {16'h0000, sw, auth_cur_response};
                endcase
            end
        end
    end

    //=========================================================================
    // LED Controller
    //=========================================================================
    wire [7:0] led_out;

    led_controller #(.CLK_FREQ(CLK_FREQ)) u_led (
        .clk       (clk_24mhz),
        .rst       (sys_rst),
        .state     (auth_state),
        .enrolled  (auth_enrolled),
        .auth_pass (auth_pass_pulse),
        .auth_fail (auth_fail_pulse),
        .busy      (auth_busy),
        .response  (auth_cur_response),
        .led       (led_out)
    );

    assign led = led_out;

    //=========================================================================
    // Buzzer Controller
    //=========================================================================
    wire buzzer_out;

    buzzer_controller #(.CLK_FREQ(CLK_FREQ)) u_buzzer (
        .clk       (clk_24mhz),
        .rst       (sys_rst),
        .auth_pass (auth_pass_pulse),
        .auth_fail (auth_fail_pulse),
        .buzzer    (buzzer_out)
    );

    assign buzzer = buzzer_out;

    //=========================================================================
    // Clock Divider (available for debug; unused in main data path)
    //=========================================================================
    wire clk_1mhz;

    clock_divider #(.DIV_FACTOR(CLK_FREQ / 1_000_000)) u_clkdiv (
        .clk     (clk_24mhz),
        .rst     (sys_rst),
        .clk_out (clk_1mhz)
    );

endmodule
