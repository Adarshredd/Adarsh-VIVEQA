`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.06.2026 14:35:32
// Design Name: 
// Module Name: fsm_110_detector_tb
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


module fsm_110_detector_tb;

    //------------------------------------------------------------------------
    // Parameters
    //------------------------------------------------------------------------
    parameter CLK_PERIOD = 42; // ~24 MHz

    //------------------------------------------------------------------------
    // Testbench Signals
    //------------------------------------------------------------------------
    reg  clk;
    reg  rst;
    reg  din;
    wire out;

    //------------------------------------------------------------------------
    // Test tracking
    //------------------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer test_num;

    //------------------------------------------------------------------------
    // DUT Instantiation
    //------------------------------------------------------------------------
    fsm_110_detector uut (
        .clk (clk),
        .rst (rst),
        .din (din),
        .out (out)
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
        $dumpfile("fsm_110_detector.vcd");
        $dumpvars(0, fsm_110_detector_tb);
    end

    //------------------------------------------------------------------------
    // Task: Send one bit and wait one clock cycle
    //------------------------------------------------------------------------
    task send_bit;
        input bit_val;
        begin
            din = bit_val;
            @(posedge clk);
            #1; // Small delay for output to settle
        end
    endtask

    //------------------------------------------------------------------------
    // Task: Check output and report PASS/FAIL
    //------------------------------------------------------------------------
    task check_output;
        input expected;
        input [79:0] msg; // 10-char message tag
        begin
            test_num = test_num + 1;
            if (out === expected) begin
                $display("[PASS] Test %0d: %s | out=%b (expected=%b)",
                         test_num, msg, out, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s | out=%b (expected=%b)",
                         test_num, msg, out, expected);
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
        din        = 0;

        $display("===========================================================");
        $display("  FSM 110 Detector Testbench (LSB First → detect 0,1,1)");
        $display("===========================================================");

        //--------------------------------------------------------------------
        // Apply Reset (2 clock cycles)
        //--------------------------------------------------------------------
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;
        check_output(1'b0, "AfterReset");

        //--------------------------------------------------------------------
        // Test 1: Triple overlapping detection
        // Input sequence: 0, 1, 1, 0, 1, 1, 0, 1, 1
        // Detection at: cycle 3 (toggle 0→1), cycle 6 (1→0), cycle 9 (0→1)
        //--------------------------------------------------------------------
        $display("-----------------------------------------------------------");
        $display("  Test Group 1: Triple overlapping (0,1,1,0,1,1,0,1,1)");
        $display("-----------------------------------------------------------");

        // Bit 1: din=0 → state goes to S_0, no detection yet
        send_bit(1'b0);
        check_output(1'b0, "Seq1 bit0");

        // Bit 2: din=1 → state goes to S_01, no detection yet
        send_bit(1'b1);
        check_output(1'b0, "Seq1 bit1");

        // Bit 3: din=1 → state goes to S_011, DETECTION #1! Toggle: 0→1
        send_bit(1'b1);
        check_output(1'b1, "Detect#1 ");

        // Bit 4: din=0 → state goes to S_0 (overlap), output stays toggled
        send_bit(1'b0);
        check_output(1'b1, "Seq2 bit0");

        // Bit 5: din=1 → state goes to S_01
        send_bit(1'b1);
        check_output(1'b1, "Seq2 bit1");

        // Bit 6: din=1 → state goes to S_011, DETECTION #2! Toggle: 1→0
        send_bit(1'b1);
        check_output(1'b0, "Detect#2 ");

        // Bit 7: din=0 → state goes to S_0 (overlap)
        send_bit(1'b0);
        check_output(1'b0, "Seq3 bit0");

        // Bit 8: din=1 → state goes to S_01
        send_bit(1'b1);
        check_output(1'b0, "Seq3 bit1");

        // Bit 9: din=1 → state goes to S_011, DETECTION #3! Toggle: 0→1
        send_bit(1'b1);
        check_output(1'b1, "Detect#3 ");

        //--------------------------------------------------------------------
        // Test 2: Mixed sequence with reset
        // Reset, then: 1, 0, 0, 1, 1, 0, 1, 1
        //--------------------------------------------------------------------
        $display("-----------------------------------------------------------");
        $display("  Test Group 2: Mixed sequence (1,0,0,1,1,0,1,1)");
        $display("-----------------------------------------------------------");

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;
        check_output(1'b0, "Reset2   ");

        // din=1 → S_IDLE (1 doesn't start pattern)
        send_bit(1'b1);
        check_output(1'b0, "Mix  din1");

        // din=0 → S_0
        send_bit(1'b0);
        check_output(1'b0, "Mix  din0");

        // din=0 → S_0 (restart with new 0)
        send_bit(1'b0);
        check_output(1'b0, "Mix din0b");

        // din=1 → S_01
        send_bit(1'b1);
        check_output(1'b0, "Mix  din1");

        // din=1 → S_011, DETECTION! Toggle 0→1
        send_bit(1'b1);
        check_output(1'b1, "MixDet#1 ");

        // din=0 → S_0 (overlap)
        send_bit(1'b0);
        check_output(1'b1, "MixO din0");

        // din=1 → S_01
        send_bit(1'b1);
        check_output(1'b1, "MixO din1");

        // din=1 → S_011, DETECTION! Toggle 1→0
        send_bit(1'b1);
        check_output(1'b0, "MixDet#2 ");

        //--------------------------------------------------------------------
        // Test 3: No detection - all 1s
        //--------------------------------------------------------------------
        $display("-----------------------------------------------------------");
        $display("  Test Group 3: No detection (all 1s)");
        $display("-----------------------------------------------------------");

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        send_bit(1'b1);
        send_bit(1'b1);
        send_bit(1'b1);
        send_bit(1'b1);
        check_output(1'b0, "No detect");

        //--------------------------------------------------------------------
        // Test 4: No detection - all 0s
        //--------------------------------------------------------------------
        $display("-----------------------------------------------------------");
        $display("  Test Group 4: No detection (all 0s)");
        $display("-----------------------------------------------------------");

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        send_bit(1'b0);
        send_bit(1'b0);
        send_bit(1'b0);
        send_bit(1'b0);
        check_output(1'b0, "No detect");

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
