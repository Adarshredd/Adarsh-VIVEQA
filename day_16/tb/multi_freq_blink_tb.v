//============================================================================
// Testbench: multi_freq_blink_tb
// Description: Verifies multi_freq_blink with reduced counter parameters.
//              HALF_1HZ is set to 12 (instead of 12,000,000) so that LED
//              toggles are visible within a short simulation window.
//
// Expected LED toggle counts per counter cycle (12 clocks):
//   LED[0] 1 Hz : toggle at count 11                          (1× per cycle)
//   LED[1] 2 Hz : toggle at count 5, 11                       (2× per cycle)
//   LED[2] 4 Hz : toggle at count 2, 5, 8, 11                 (4× per cycle)
//   LED[3] 8 Hz : toggle at count 0 (1-1), 2 (err)...
//     With HALF_1HZ=12: STEP_8HZ=12/8=1 (integer division = 1)
//     Thresholds: 0, 1, 2, 3, 4, 5, 6, 11  - that's not right.
//     Let's use HALF_1HZ=16 for cleaner division by 8.
//       STEP_8HZ=2, STEP_4HZ=4, STEP_2HZ=8
//       8Hz thresholds: 1, 3, 5, 7, 9, 11, 13, 15
//       4Hz thresholds: 3, 7, 11, 15
//       2Hz thresholds: 7, 15
//       1Hz threshold:  15
//     Perfect - all thresholds are distinct and evenly spaced.
//============================================================================

`timescale 1ns / 1ps

module multi_freq_blink_tb;

    // -----------------------------------------------------------------------
    // Reduced parameter - must be divisible by 8 for clean thresholds
    // -----------------------------------------------------------------------
    localparam HALF_1HZ_SIM = 16;

    // -----------------------------------------------------------------------
    // Signals
    // -----------------------------------------------------------------------
    reg        clk;
    reg        rst;
    wire [3:0] led;

    // -----------------------------------------------------------------------
    // DUT instantiation with parameter override
    // -----------------------------------------------------------------------
    multi_freq_blink #(
        .HALF_1HZ(HALF_1HZ_SIM)
    ) uut (
        .clk (clk),
        .rst (rst),
        .led (led)
    );

    // -----------------------------------------------------------------------
    // Clock generation - 24 MHz (41.667 ns period, ~20.83 ns half)
    // Using 20 ns half-period for simulation simplicity
    // -----------------------------------------------------------------------
    initial clk = 0;
    always #20 clk = ~clk;  // 25 MHz approx, fine for functional test

    // -----------------------------------------------------------------------
    // Waveform dump
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("multi_freq_blink_tb.vcd");
        $dumpvars(0, multi_freq_blink_tb);
    end

    // -----------------------------------------------------------------------
    // Test sequence
    // -----------------------------------------------------------------------
    // We need to observe multiple full counter cycles to see all LEDs toggle.
    // One counter cycle = HALF_1HZ_SIM = 16 clocks.
    // Run for 8 full cycles = 128 clocks to see LED[0] toggle 8 times.

    integer i;
    integer cycle;

    // Toggle counters for verification
    integer led0_toggles, led1_toggles, led2_toggles, led3_toggles;
    reg [3:0] led_prev;

    initial begin
        // Initialize
        rst = 1;
        led0_toggles = 0;
        led1_toggles = 0;
        led2_toggles = 0;
        led3_toggles = 0;
        led_prev = 4'b0000;

        // Hold reset for 3 clocks
        repeat (3) @(posedge clk);
        #1 rst = 0;

        // Wait 1 clock for reset to take effect
        @(posedge clk);
        #1 led_prev = led;

        // Run for 8 counter cycles (8 × 16 = 128 clocks)
        // Count LED toggles
        for (i = 0; i < 128; i = i + 1) begin
            @(posedge clk);
            #1;  // small delay to let outputs settle
            if (led[0] != led_prev[0]) led0_toggles = led0_toggles + 1;
            if (led[1] != led_prev[1]) led1_toggles = led1_toggles + 1;
            if (led[2] != led_prev[2]) led2_toggles = led2_toggles + 1;
            if (led[3] != led_prev[3]) led3_toggles = led3_toggles + 1;
            led_prev = led;
        end

        // ---------------------------------------------------------------
        // Verify toggle counts
        // In 8 counter cycles:
        //   LED[0] (1 Hz): 1 toggle/cycle × 8 = 8 toggles
        //   LED[1] (2 Hz): 2 toggles/cycle × 8 = 16 toggles
        //   LED[2] (4 Hz): 4 toggles/cycle × 8 = 32 toggles
        //   LED[3] (8 Hz): 8 toggles/cycle × 8 = 64 toggles
        // ---------------------------------------------------------------
        $display("==============================================");
        $display("  Multi-Frequency Blink - Test Results");
        $display("==============================================");
        $display("  LED[0] (1 Hz) toggles: %0d (expected 8)", led0_toggles);
        $display("  LED[1] (2 Hz) toggles: %0d (expected 16)", led1_toggles);
        $display("  LED[2] (4 Hz) toggles: %0d (expected 32)", led2_toggles);
        $display("  LED[3] (8 Hz) toggles: %0d (expected 64)", led3_toggles);
        $display("----------------------------------------------");

        if (led0_toggles == 8 && led1_toggles == 16 &&
            led2_toggles == 32 && led3_toggles == 64) begin
            $display("  >>> PASS - All LEDs toggle at correct rates <<<");
        end else begin
            $display("  >>> FAIL - Toggle counts do not match <<<");
        end

        $display("==============================================");
        $display("");

        #100;
        $finish;
    end

endmodule
