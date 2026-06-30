`timescale 1ns / 1ps
//=============================================================================
// Testbench: Ring Oscillator PUF Authentication System
//
// Exercises:
//   1. Power-on reset and initialization
//   2. Enrollment of a challenge
//   3. Successful authentication (same challenge)
//   4. Failed authentication (different challenge enrolled)
//   5. Measurement-only mode
//   6. UART dump
//   7. Clear operation
//
// Note: Ring oscillators are simulated with simple inverter delays;
//       actual PUF entropy is only meaningful in silicon.
//=============================================================================

module tb_top;

    //-------------------------------------------------------------------------
    // Clock and reset
    //-------------------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always #20.833 clk = ~clk;  // 24 MHz -> 41.667 ns period

    //-------------------------------------------------------------------------
    // DUT signals
    //-------------------------------------------------------------------------
    reg  [7:0] sw;
    wire [7:0] led;

    reg  btn_enroll;
    reg  btn_auth;
    reg  btn_measure;
    reg  btn_clear;
    reg  btn_uart_dump;
    reg  btn_reserved;

    wire       lcd_rs, lcd_rw, lcd_en;
    wire [7:0] lcd_d;

    wire seg_din, seg_load, seg_clk_w;
    wire uart_tx_w;
    reg  uart_rx_r;
    wire buzzer;

    //-------------------------------------------------------------------------
    // DUT instantiation
    //-------------------------------------------------------------------------
    top u_dut (
        .clk_24mhz     (clk),
        .sw             (sw),
        .led            (led),
        .btn_enroll     (btn_enroll),
        .btn_auth       (btn_auth),
        .btn_measure    (btn_measure),
        .btn_clear      (btn_clear),
        .btn_uart_dump  (btn_uart_dump),
        .btn_reserved   (btn_reserved),
        .lcd_rs         (lcd_rs),
        .lcd_rw         (lcd_rw),
        .lcd_en         (lcd_en),
        .lcd_d          (lcd_d),
        .seg_din        (seg_din),
        .seg_load       (seg_load),
        .seg_clk        (seg_clk_w),
        .uart_tx        (uart_tx_w),
        .uart_rx        (uart_rx_r),
        .buzzer         (buzzer)
    );

    //-------------------------------------------------------------------------
    // Shortened timing parameters for simulation
    // Override GATE_CYCLES for faster simulation
    //-------------------------------------------------------------------------
    // In real hardware GATE_CYCLES=65536 (~2.73ms per measurement, ~22ms per response)
    // For simulation: we rely on default parameters, but the testbench
    // uses long enough waits.

    //-------------------------------------------------------------------------
    // Tasks: Button press simulation
    //-------------------------------------------------------------------------
    task press_button;
        input integer btn_id;
        begin
            case (btn_id)
                0: begin btn_enroll    = 1'b0; #1_000_000; btn_enroll    = 1'b1; end
                1: begin btn_auth      = 1'b0; #1_000_000; btn_auth      = 1'b1; end
                2: begin btn_measure   = 1'b0; #1_000_000; btn_measure   = 1'b1; end
                3: begin btn_clear     = 1'b0; #1_000_000; btn_clear     = 1'b1; end
                4: begin btn_uart_dump = 1'b0; #1_000_000; btn_uart_dump = 1'b1; end
                5: begin btn_reserved  = 1'b0; #1_000_000; btn_reserved  = 1'b1; end
            endcase
        end
    endtask

    task wait_idle;
        begin
            // Wait until auth_state returns to IDLE (state 0)
            // Poll DUT state output via LED or internal signal
            wait (u_dut.auth_state == 4'd0);
            #100_000;
        end
    endtask

    task wait_ms;
        input integer ms;
        begin
            #(ms * 1_000_000);
        end
    endtask

    //-------------------------------------------------------------------------
    // UART RX monitor (captures TX output from DUT)
    //-------------------------------------------------------------------------
    localparam integer CLKS_PER_BIT = 24_000_000 / 115200;
    localparam integer BIT_PERIOD   = CLKS_PER_BIT * 42;  // ~41.667ns * 208 = ~8680ns

    reg [7:0] uart_rx_byte;
    integer   uart_rx_bit;

    task uart_monitor_byte;
        begin
            // Wait for start bit
            @(negedge uart_tx_w);
            #(BIT_PERIOD / 2);  // Mid-point of start bit

            // Sample 8 data bits
            for (uart_rx_bit = 0; uart_rx_bit < 8; uart_rx_bit = uart_rx_bit + 1) begin
                #BIT_PERIOD;
                uart_rx_byte[uart_rx_bit] = uart_tx_w;
            end

            #BIT_PERIOD;  // Stop bit
            $write("%c", uart_rx_byte);
        end
    endtask

    //-------------------------------------------------------------------------
    // UART capture process
    //-------------------------------------------------------------------------
    reg uart_monitor_en;
    initial uart_monitor_en = 1'b1;

    always begin
        if (uart_monitor_en) begin
            uart_monitor_byte;
        end else begin
            #1000;
        end
    end

    //-------------------------------------------------------------------------
    // Main test sequence
    //-------------------------------------------------------------------------
    initial begin
        $display("==============================================");
        $display("  RO-PUF Authentication System Testbench");
        $display("==============================================");

        // Initialize all inputs
        sw             = 8'h00;
        btn_enroll     = 1'b1;  // Active low: not pressed
        btn_auth       = 1'b1;
        btn_measure    = 1'b1;
        btn_clear      = 1'b1;
        btn_uart_dump  = 1'b1;
        btn_reserved   = 1'b1;
        uart_rx_r      = 1'b1;  // UART idle

        //---------------------------------------------------------------------
        // Wait for power-on reset to complete
        //---------------------------------------------------------------------
        $display("\n[%0t] Waiting for power-on reset...", $time);
        #500;  // POR is only 8 clock cycles
        wait (u_dut.por_rst == 1'b0);
        $display("[%0t] POR complete.", $time);

        // Wait for LCD initialization (~50ms simulated)
        wait_ms(1);

        //---------------------------------------------------------------------
        // Test 1: Enrollment
        //---------------------------------------------------------------------
        $display("\n[%0t] TEST 1: Enrolling challenge 0xA5...", $time);
        sw = 8'hA5;
        #100_000;
        press_button(0);  // btn_enroll

        // Wait for response generation (8 measurements × ~2.73ms = ~22ms)
        // In simulation with default GATE_CYCLES=65536:
        $display("[%0t] Waiting for enrollment to complete...", $time);
        wait (u_dut.auth_state == 4'd2);  // ST_STORE
        $display("[%0t] Enrollment complete. Response = 0x%02h",
                 $time, u_dut.auth_cur_response);
        wait_idle;

        //---------------------------------------------------------------------
        // Test 2: Successful Authentication
        //---------------------------------------------------------------------
        $display("\n[%0t] TEST 2: Authenticating challenge 0xA5...", $time);
        sw = 8'hA5;
        #100_000;
        press_button(1);  // btn_auth

        $display("[%0t] Waiting for authentication...", $time);
        // Wait for PASS or FAIL state
        wait (u_dut.auth_state == 4'd5 || u_dut.auth_state == 4'd6);
        if (u_dut.auth_state == 4'd5) begin
            $display("[%0t] AUTH PASS (expected). Buzzer = %b", $time, buzzer);
        end else begin
            $display("[%0t] AUTH FAIL. Response = 0x%02h, Stored = 0x%02h",
                     $time, u_dut.auth_cur_response, u_dut.auth_sto_response);
        end
        wait_idle;

        //---------------------------------------------------------------------
        // Test 3: Measurement only
        //---------------------------------------------------------------------
        $display("\n[%0t] TEST 3: Measure-only mode, challenge 0x3C...", $time);
        sw = 8'h3C;
        #100_000;
        press_button(2);  // btn_measure

        $display("[%0t] Waiting for measurement...", $time);
        wait (u_dut.auth_state == 4'd8);  // MEAS_DONE
        $display("[%0t] Measurement done. Response = 0x%02h",
                 $time, u_dut.auth_cur_response);
        $display("[%0t] Count A = %0d, Count B = %0d",
                 $time, u_dut.auth_count_a, u_dut.auth_count_b);
        wait_idle;

        //---------------------------------------------------------------------
        // Test 4: UART Dump
        //---------------------------------------------------------------------
        $display("\n[%0t] TEST 4: UART dump...", $time);
        press_button(4);  // btn_uart_dump

        // Wait for UART transmission (~80 chars at 115200 baud ≈ 7ms)
        wait_ms(10);
        $display("\n[%0t] UART dump complete.", $time);

        //---------------------------------------------------------------------
        // Test 5: Failed Authentication (unenrolled challenge)
        //---------------------------------------------------------------------
        $display("\n[%0t] TEST 5: Auth on unenrolled challenge 0xFF...", $time);
        sw = 8'hFF;
        #100_000;
        press_button(1);  // btn_auth

        wait (u_dut.auth_state == 4'd6);  // ST_FAIL
        $display("[%0t] AUTH FAIL (expected - not enrolled). Buzzer = %b",
                 $time, buzzer);
        wait_idle;

        //---------------------------------------------------------------------
        // Test 6: Clear all enrollments
        //---------------------------------------------------------------------
        $display("\n[%0t] TEST 6: Clearing all enrollments...", $time);
        press_button(3);  // btn_clear
        #500_000;
        $display("[%0t] Clear complete.", $time);

        //---------------------------------------------------------------------
        // Test 7: Auth after clear (should fail)
        //---------------------------------------------------------------------
        $display("\n[%0t] TEST 7: Auth after clear on 0xA5...", $time);
        sw = 8'hA5;
        #100_000;
        press_button(1);  // btn_auth

        wait (u_dut.auth_state == 4'd6);  // ST_FAIL
        $display("[%0t] AUTH FAIL (expected - cleared). Buzzer = %b",
                 $time, buzzer);
        wait_idle;

        //---------------------------------------------------------------------
        // Done
        //---------------------------------------------------------------------
        $display("\n==============================================");
        $display("  All tests complete.");
        $display("==============================================");

        #5_000_000;
        $finish;
    end

    //-------------------------------------------------------------------------
    // Timeout watchdog
    //-------------------------------------------------------------------------
    initial begin
        // Maximum simulation time: 500ms
        #500_000_000;
        $display("\n[%0t] TIMEOUT: Simulation exceeded 500ms limit.", $time);
        $finish;
    end

    //-------------------------------------------------------------------------
    // VCD dump for waveform viewing
    //-------------------------------------------------------------------------
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
