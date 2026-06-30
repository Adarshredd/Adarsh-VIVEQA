`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 14:35:55
// Design Name: 
// Module Name: max_digit_fsm_tb
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


module max_digit_fsm_tb;

    //------------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------------
    parameter CLK_PERIOD = 42; // ~24 MHz

    //------------------------------------------------------------------------
    // Testbench Signals
    //------------------------------------------------------------------------
    reg        clk;
    reg        rst;
    reg  [1:0] din;
    wire [1:0] max_out;

    //------------------------------------------------------------------------
    // Test tracking
    //------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer test_num;

    //------------------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------------------
    max_digit_fsm uut (
        .clk     (clk),
        .rst     (rst),
        .din     (din),
        .max_out (max_out)
    );

    //------------------------------------------------------------------------
    // Clock Generation: 24 MHz (42 ns period)
    //------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    //------------------------------------------------------------------------
    // Waveform Dump
    //------------------------------------------------------------------------
    initial begin
        $dumpfile("max_digit_fsm.vcd");
        $dumpvars(0, max_digit_fsm_tb);
    end

    //------------------------------------------------------------------------
    // Task: Apply one input digit and wait one clock cycle
    //------------------------------------------------------------------------
    task apply_digit;
        input [1:0] digit;
        begin
            din = digit;
            @(posedge clk);
            #1; // Small delay for output to settle
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Check output and report PASS/FAIL
    //------------------------------------------------------------------------
    task check_max;
        input [1:0] expected;
        input [79:0] msg;
        begin
            test_num = test_num + 1;
            if (max_out === expected) begin
                $display("[PASS] Test %0d: %s | din=%0d, max_out=%0d (expected=%0d)",
                         test_num, msg, din, max_out, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s | din=%0d, max_out=%0d (expected=%0d)",
                         test_num, msg, din, max_out, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    //------------------------------------------------------------------------
    // Main Test Sequence
    //------------------------------------------------------------------------
    initial begin
        // Initialize
        pass_count = 0;
        fail_count = 0;
        test_num   = 0;
        rst        = 1;
        din        = 2'd0;

        $display("===========================================================");
        $display("  Maximum Digit Tracker FSM Testbench");
        $display("===========================================================");

        //--------------------------------------------------------------------
        // Apply Reset (2 clock cycles)
        //--------------------------------------------------------------------
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;
        check_max(2'd0, "AfterRst ");

        //--------------------------------------------------------------------
        // Test 1: Gradual increase with noise
        // Sequence: 0, 0, 1, 0, 3, 2
        // Expected: 0, 0, 1, 1, 3, 3
        //--------------------------------------------------------------------
        $display("-----------------------------------------------------------");
        $display("  Test Group 1: Gradual increase (0,0,1,0,3,2)");
        $display("-----------------------------------------------------------");

        apply_digit(2'd0);
        check_max(2'd0, "din=0    ");

        apply_digit(2'd0);
        check_max(2'd0, "din=0    ");

        apply_digit(2'd1);
        check_max(2'd1, "din=1    ");

        apply_digit(2'd0);
        check_max(2'd1, "din=0 max");

        apply_digit(2'd3);
        check_max(2'd3, "din=3    ");

        apply_digit(2'd2);
        check_max(2'd3, "din=2 abs");

        //--------------------------------------------------------------------
        // Test 2: Immediate maximum
        // Sequence: 3, 0, 0, 0
        // Expected: 3, 3, 3, 3
        //--------------------------------------------------------------------
        $display("-----------------------------------------------------------");
        $display("  Test Group 2: Immediate max (3,0,0,0)");
        $display("-----------------------------------------------------------");

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        apply_digit(2'd3);
        check_max(2'd3, "din=3 imm");

        apply_digit(2'd0);
        check_max(2'd3, "din=0 abs");

        apply_digit(2'd0);
        check_max(2'd3, "din=0 abs");

        apply_digit(2'd0);
        check_max(2'd3, "din=0 abs");

        //--------------------------------------------------------------------
        // Test 3: Reset and re-test
        // Sequence: 2, 1, 3, 0
        // Expected: 2, 2, 3, 3
        //--------------------------------------------------------------------
        $display("-----------------------------------------------------------");
        $display("  Test Group 3: Reset + new sequence (2,1,3,0)");
        $display("-----------------------------------------------------------");

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;
        check_max(2'd0, "AfterRst ");

        apply_digit(2'd2);
        check_max(2'd2, "din=2    ");

        apply_digit(2'd1);
        check_max(2'd2, "din=1 max");

        apply_digit(2'd3);
        check_max(2'd3, "din=3    ");

        apply_digit(2'd0);
        check_max(2'd3, "din=0 abs");

        //--------------------------------------------------------------------
        // Test 4: Sequential ascending
        // Sequence: 0, 1, 2, 3
        // Expected: 0, 1, 2, 3
        //--------------------------------------------------------------------
        $display("-----------------------------------------------------------");
        $display("  Test Group 4: Ascending (0,1,2,3)");
        $display("-----------------------------------------------------------");

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        apply_digit(2'd0);
        check_max(2'd0, "din=0    ");

        apply_digit(2'd1);
        check_max(2'd1, "din=1    ");

        apply_digit(2'd2);
        check_max(2'd2, "din=2    ");

        apply_digit(2'd3);
        check_max(2'd3, "din=3    ");

        //--------------------------------------------------------------------
        // Results Summary
        //--------------------------------------------------------------------
        $display("===========================================================");
        $display("  RESULTS: %0d PASSED, %0d FAILED out of %0d tests",
                 pass_count, fail_count, test_num);
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** SOME TESTS FAILED ***");
        $display("===========================================================");

        #(CLK_PERIOD * 5);
        $finish;
    end

endmodule

