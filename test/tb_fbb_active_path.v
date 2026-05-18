// SPDX-License-Identifier: Apache-2.0
// tb_fbb_active_path.v — Testbench for Forward Body Bias Active Path
`default_nettype none
`timescale 1ns/1ps

module tb_fbb_active_path;

    reg        clk;
    reg        rst_n;
    reg        enable;
    reg  [7:0]  temp_mon;     // Temperature monitor (0-255)
    reg  [7:0]  activity;      // Activity level (0-255)
    wire [7:0]  fbb_level;     // FBB voltage level
    wire       fbb_enable;    // FBB enable signal

    fbb_active_path dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .temp_mon(temp_mon),
        .activity(activity),
        .fbb_level(fbb_level),
        .fbb_enable(fbb_enable)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz
    end

    integer pass_count = 0;
    integer fail_count = 0;

    task check_fbb;
        input [7:0] expected_level;
        input       expected_enable;
        input [100*8:1] test_name;
        begin
            if (fbb_level !== expected_level || fbb_enable !== expected_enable) begin
                $display("FAIL: %s | got=%d/%d expected=%d/%d",
                         test_name, fbb_level, fbb_enable, expected_level, expected_enable);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s | fbb=%d enable=%d",
                         test_name, fbb_level, fbb_enable);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_fbb_active_path.vcd");
        $dumpvars(0, tb_fbb_active_path);
        $display("=== FBB ACTIVE PATH TESTBENCH ===");

        // Initialize
        rst_n = 0;
        enable = 0;
        temp_mon = 8'd0;
        activity = 8'd0;
        #20;
        rst_n = 1;

        // Test 1: Reset state
        $display("\nTest 1: Reset state");
        #20;
        check_fbb(8'd0, 1'b0, "Reset state");

        // Test 2: Enable FBB
        $display("\nTest 2: Enable FBB");
        enable = 1'b1;
        #20;
        check_fbb(8'd0, 1'b0, "FBB enabled, idle");

        // Test 3: Normal temperature, moderate activity
        $display("\nTest 3: Normal operation");
        temp_mon = 8'd100;  // Normal temp
        activity = 8'd128;  // Moderate activity
        #20;
        // FBB level depends on temp + activity
        $display("INFO: FBB level=%d at temp=%d activity=%d", fbb_level, temp_mon, activity);

        // Test 4: High temperature (should reduce FBB)
        $display("\nTest 4: High temperature");
        temp_mon = 8'd200;  // High temp
        activity = 8'd128;
        #20;
        $display("INFO: FBB level=%d at high temp", fbb_level);

        // Test 5: High activity (should increase FBB)
        $display("\nTest 5: High activity");
        temp_mon = 8'd100;
        activity = 8'd200;  // High activity
        #20;
        $display("INFO: FBB level=%d at high activity", fbb_level);

        // Test 6: Disable FBB
        $display("\nTest 6: Disable FBB");
        enable = 1'b0;
        #20;
        check_fbb(8'd0, 1'b0, "FBB disabled");

        // Test 7: Edge cases
        $display("\nTest 7: Edge cases");
        enable = 1'b1;
        temp_mon = 8'd0;    // Minimum temp
        activity = 8'd255; // Max activity
        #20;
        $display("INFO: FBB level=%d at min temp, max activity", fbb_level);

        temp_mon = 8'd255;  // Max temp
        activity = 8'd0;    // Min activity
        #20;
        $display("INFO: FBB level=%d at max temp, min activity", fbb_level);

        // Summary
        $display("\n=== TEST SUMMARY ===");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $finish;
    end

endmodule