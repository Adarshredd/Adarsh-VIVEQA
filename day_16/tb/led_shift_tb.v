`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 14:43:16
// Design Name: 
// Module Name: led_shift_tb
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


module led_shift_tb;

    // -----------------------------------------------------------------------
    // Reduced parameter
    // -----------------------------------------------------------------------
    localparam DB_MAX = 4;  // 4-cycle debounce for simulation

    // -----------------------------------------------------------------------
    // Signals
    // -----------------------------------------------------------------------
    reg        clk;
    reg        rst;
    reg  [1:0] btn;
    wire [3:0] led;

    // -----------------------------------------------------------------------
    // DUT
    // -----------------------------------------------------------------------
    led_shift #(
        .DEBOUNCE_MAX(DB_MAX)
    ) uut (
        .clk (clk),
        .rst (rst),
        .btn (btn),
        .led (led)
    );

    // -----------------------------------------------------------------------
    // Clock generation - 40 ns period
    // -----------------------------------------------------------------------
    initial clk = 0;
    always #20 clk = ~clk;

    // -----------------------------------------------------------------------
    // Waveform dump
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("led_shift_tb.vcd");
        $dumpvars(0, led_shift_tb);
    end

    // -----------------------------------------------------------------------
    // Task: press button
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
    // Function: check if value is one-hot
    // -----------------------------------------------------------------------
    function is_one_hot;
        input [3:0] val;
        begin
            is_one_hot = (val == 4'b0001 || val == 4'b0010 ||
                          val == 4'b0100 || val == 4'b1000);
        end
    endfunction

    // -----------------------------------------------------------------------
    // Test variables
    // -----------------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer one_hot_ok;
    integer i;

    // -----------------------------------------------------------------------
    // Test sequence
    // -----------------------------------------------------------------------
    initial begin
        rst = 1;
        btn = 2'b00;
        pass_count = 0;
        fail_count = 0;
        one_hot_ok = 1;

        repeat (5) @(posedge clk);
        #1 rst = 0;
        repeat (3) @(posedge clk);
        #1;

        // ==================================================================
        // Test 1: Initial state after reset
        // ==================================================================
        $display("[TEST 1] Initial state after reset");
        if (led == 4'b0001) begin
            $display("  PASS: led = %b (expected 0001)", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: led = %b (expected 0001)", led);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 2: Full left rotation (4 presses → back to start)
        // ==================================================================
        $display("[TEST 2] Full left rotation");

        press_button(0);  // 0001 → 0010
        if (led == 4'b0010) begin
            $display("  PASS: after left 1, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: after left 1, led = %b (expected 0010)", led);
            fail_count = fail_count + 1;
        end

        press_button(0);  // 0010 → 0100
        if (led == 4'b0100) begin
            $display("  PASS: after left 2, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: after left 2, led = %b (expected 0100)", led);
            fail_count = fail_count + 1;
        end

        press_button(0);  // 0100 → 1000
        if (led == 4'b1000) begin
            $display("  PASS: after left 3, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: after left 3, led = %b (expected 1000)", led);
            fail_count = fail_count + 1;
        end

        press_button(0);  // 1000 → 0001 (wrap)
        if (led == 4'b0001) begin
            $display("  PASS: after left 4 (wrap), led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: after left 4 (wrap), led = %b (expected 0001)", led);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 3: Full right rotation (4 presses → back to start)
        // ==================================================================
        $display("[TEST 3] Full right rotation");

        press_button(1);  // 0001 → 1000
        if (led == 4'b1000) begin
            $display("  PASS: after right 1, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: after right 1, led = %b (expected 1000)", led);
            fail_count = fail_count + 1;
        end

        press_button(1);  // 1000 → 0100
        if (led == 4'b0100) begin
            $display("  PASS: after right 2, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: after right 2, led = %b (expected 0100)", led);
            fail_count = fail_count + 1;
        end

        press_button(1);  // 0100 → 0010
        if (led == 4'b0010) begin
            $display("  PASS: after right 3, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: after right 3, led = %b (expected 0010)", led);
            fail_count = fail_count + 1;
        end

        press_button(1);  // 0010 → 0001 (wrap)
        if (led == 4'b0001) begin
            $display("  PASS: after right 4 (wrap), led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: after right 4 (wrap), led = %b (expected 0001)", led);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 4: Alternating left/right
        // ==================================================================
        $display("[TEST 4] Alternating left/right");

        press_button(0);  // 0001 → 0010
        if (led == 4'b0010) begin
            $display("  PASS: left, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: left, led = %b (expected 0010)", led);
            fail_count = fail_count + 1;
        end

        press_button(1);  // 0010 → 0001
        if (led == 4'b0001) begin
            $display("  PASS: right, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: right, led = %b (expected 0001)", led);
            fail_count = fail_count + 1;
        end

        press_button(1);  // 0001 → 1000
        if (led == 4'b1000) begin
            $display("  PASS: right, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: right, led = %b (expected 1000)", led);
            fail_count = fail_count + 1;
        end

        press_button(0);  // 1000 → 0001
        if (led == 4'b0001) begin
            $display("  PASS: left, led = %b", led);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: left, led = %b (expected 0001)", led);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 5: One-hot property check (run through 8 random presses)
        // ==================================================================
        $display("[TEST 5] One-hot property verification (8 presses)");
        one_hot_ok = 1;
        for (i = 0; i < 8; i = i + 1) begin
            if (i % 3 == 0)
                press_button(1);  // right
            else
                press_button(0);  // left
            if (!is_one_hot(led)) begin
                $display("  FAIL: led = %b is NOT one-hot at press %0d", led, i);
                one_hot_ok = 0;
            end
        end
        if (one_hot_ok) begin
            $display("  PASS: one-hot property maintained for all 8 presses");
            pass_count = pass_count + 1;
        end else begin
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Summary
        // ==================================================================
        $display("");
        $display("==============================================");
        $display("  LED Shift Register - Test Summary");
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
