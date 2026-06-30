//============================================================================
// Testbench: adjustable_blink_tb
// Description: Verifies adjustable_blink with reduced parameters.
//              Debounce reduced to 4 cycles. Divider values reduced to
//              small numbers for fast simulation.
//
// Tests:
//   1. Default speed (index 1 → 1 Hz equivalent)
//   2. Press btn[0] to increase speed, verify LED frequency changes
//   3. Press btn[1] to decrease speed, verify LED frequency changes
//   4. Clamp test: press btn[0] past max (index 4), verify no overflow
//   5. Clamp test: press btn[1] past min (index 0), verify no underflow
//============================================================================

`timescale 1ns / 1ps

module adjustable_blink_tb;

    // -----------------------------------------------------------------------
    // Reduced parameters for simulation
    // -----------------------------------------------------------------------
    localparam DB_MAX     = 4;        // 4-cycle debounce
    localparam SIM_DIV_0  = 31;       // 0.5 Hz equivalent (slowest)
    localparam SIM_DIV_1  = 15;       // 1.0 Hz equivalent (default)
    localparam SIM_DIV_2  = 7;        // 2.0 Hz equivalent
    localparam SIM_DIV_3  = 3;        // 4.0 Hz equivalent
    localparam SIM_DIV_4  = 1;        // 8.0 Hz equivalent (fastest)

    // -----------------------------------------------------------------------
    // Signals
    // -----------------------------------------------------------------------
    reg        clk;
    reg        rst;
    reg  [1:0] btn;
    wire       led;

    // -----------------------------------------------------------------------
    // DUT
    // -----------------------------------------------------------------------
    adjustable_blink #(
        .DEBOUNCE_MAX (DB_MAX),
        .DIV_0        (SIM_DIV_0),
        .DIV_1        (SIM_DIV_1),
        .DIV_2        (SIM_DIV_2),
        .DIV_3        (SIM_DIV_3),
        .DIV_4        (SIM_DIV_4)
    ) uut (
        .clk (clk),
        .rst (rst),
        .btn (btn),
        .led (led)
    );

    // -----------------------------------------------------------------------
    // Clock generation - 40 ns period (25 MHz, close enough for functional test)
    // -----------------------------------------------------------------------
    initial clk = 0;
    always #20 clk = ~clk;

    // -----------------------------------------------------------------------
    // Waveform dump
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("adjustable_blink_tb.vcd");
        $dumpvars(0, adjustable_blink_tb);
    end

    // -----------------------------------------------------------------------
    // Task: press a button (assert for DB_MAX+2 clocks, then release)
    // -----------------------------------------------------------------------
    task press_button;
        input integer idx;
        begin
            btn[idx] = 1'b1;
            repeat (DB_MAX + 4) @(posedge clk);
            #1;
            btn[idx] = 1'b0;
            repeat (DB_MAX + 4) @(posedge clk);
            #1;
        end
    endtask

    // -----------------------------------------------------------------------
    // Task: measure LED half-period (count clocks between two toggles)
    // -----------------------------------------------------------------------
    integer measured_half_period;
    reg     led_snapshot;

    task measure_led_period;
        begin
            measured_half_period = 0;
            @(posedge clk);
            #1 led_snapshot = led;
            // Wait for first toggle
            while (led == led_snapshot) begin
                @(posedge clk);
                #1;
            end
            // Now count until next toggle
            led_snapshot = led;
            measured_half_period = 0;
            while (led == led_snapshot) begin
                @(posedge clk);
                #1;
                measured_half_period = measured_half_period + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Test sequence
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer expected_hp;

    initial begin
        rst  = 1;
        btn  = 2'b00;
        pass_count = 0;
        fail_count = 0;

        repeat (5) @(posedge clk);
        #1 rst = 0;

        // Wait a few clocks for system to settle
        repeat (5) @(posedge clk);

        // ==================================================================
        // Test 1: Default speed (index 1 → DIV_1 = 15)
        // ==================================================================
        $display("[TEST 1] Default speed - expect half-period = %0d", SIM_DIV_1 + 1);
        measure_led_period;
        expected_hp = SIM_DIV_1 + 1;  // counter goes 0..DIV_1, so DIV_1+1 clocks
        if (measured_half_period == expected_hp) begin
            $display("  PASS: measured %0d clocks", measured_half_period);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: measured %0d clocks, expected %0d", measured_half_period, expected_hp);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 2: Press btn[0] to go faster (index 1 → 2 → DIV_2 = 7)
        // ==================================================================
        $display("[TEST 2] Speed up - press btn[0], expect half-period = %0d", SIM_DIV_2 + 1);
        press_button(0);
        measure_led_period;
        expected_hp = SIM_DIV_2 + 1;
        if (measured_half_period == expected_hp) begin
            $display("  PASS: measured %0d clocks", measured_half_period);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: measured %0d clocks, expected %0d", measured_half_period, expected_hp);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 3: Press btn[0] twice more (index 2 → 3 → 4, fastest)
        // ==================================================================
        $display("[TEST 3] Speed up to max - press btn[0] twice");
        press_button(0);  // index 3
        press_button(0);  // index 4
        measure_led_period;
        expected_hp = SIM_DIV_4 + 1;
        if (measured_half_period == expected_hp) begin
            $display("  PASS: at max speed, measured %0d clocks", measured_half_period);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: measured %0d clocks, expected %0d", measured_half_period, expected_hp);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 4: Clamp at max - press btn[0] 3 more times, should stay at 4
        // ==================================================================
        $display("[TEST 4] Clamp at max - press btn[0] 3 more times");
        press_button(0);
        press_button(0);
        press_button(0);
        measure_led_period;
        expected_hp = SIM_DIV_4 + 1;
        if (measured_half_period == expected_hp) begin
            $display("  PASS: clamped at max, measured %0d clocks", measured_half_period);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: measured %0d clocks, expected %0d", measured_half_period, expected_hp);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 5: Press btn[1] to slow down (index 4 → 3 → DIV_3 = 3)
        // ==================================================================
        $display("[TEST 5] Slow down - press btn[1]");
        press_button(1);  // index 3
        measure_led_period;
        expected_hp = SIM_DIV_3 + 1;
        if (measured_half_period == expected_hp) begin
            $display("  PASS: measured %0d clocks", measured_half_period);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: measured %0d clocks, expected %0d", measured_half_period, expected_hp);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 6: Slow down to min (index 3 → 2 → 1 → 0)
        // ==================================================================
        $display("[TEST 6] Slow down to min - press btn[1] 3 times");
        press_button(1);  // index 2
        press_button(1);  // index 1
        press_button(1);  // index 0
        measure_led_period;
        expected_hp = SIM_DIV_0 + 1;
        if (measured_half_period == expected_hp) begin
            $display("  PASS: at min speed, measured %0d clocks", measured_half_period);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: measured %0d clocks, expected %0d", measured_half_period, expected_hp);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 7: Clamp at min - press btn[1] 3 more times
        // ==================================================================
        $display("[TEST 7] Clamp at min - press btn[1] 3 more times");
        press_button(1);
        press_button(1);
        press_button(1);
        measure_led_period;
        expected_hp = SIM_DIV_0 + 1;
        if (measured_half_period == expected_hp) begin
            $display("  PASS: clamped at min, measured %0d clocks", measured_half_period);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: measured %0d clocks, expected %0d", measured_half_period, expected_hp);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Summary
        // ==================================================================
        $display("");
        $display("==============================================");
        $display("  Adjustable Blink - Test Summary");
        $display("==============================================");
        $display("  Passed: %0d / %0d", pass_count, pass_count + fail_count);
        $display("  Failed: %0d / %0d", fail_count, pass_count + fail_count);
        if (fail_count == 0)
            $display("  >>> ALL TESTS PASSED <<<");
        else
            $display("  >>> SOME TESTS FAILED <<<");
        $display("==============================================");

        #200;
        $finish;
    end

endmodule
