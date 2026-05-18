// SPDX-License-Identifier: Apache-2.0
// tb_nf4_quantizer.v — Testbench for NF4 Quantizer
`default_nettype none
`timescale 1ns/1ps

module tb_nf4_quantizer;

    reg  signed [15:0] fp16_in;
    reg  [3:0]  scale_idx;
    wire [3:0]  nf4_out;

    nf4_quantizer dut (
        .fp16_in(fp16_in),
        .scale_idx(scale_idx),
        .nf4_out(nf4_out)
    );

    // NF4 levels from Normal(0,1) quantiles
    // 8'h8: 0.000, 8'h9: 0.091, 8'h0: 0.185, 8'h1: 0.284,
    // 8'h2: 0.394, 8'h3: 0.525, 8'h4: 0.696, 8'h5: 1.000,
    // 8'h6: 0.696, 8'h7: 0.525, 8'h8: 0.394, 8'h9: 0.284,
    // 8'hA: 0.185, 8'hB: 0.091, 8'hC: 0.000, 8'hD: -0.091,
    // 8'hE: -0.185, 8'hF: -0.284

    integer pass_count = 0;
    integer fail_count = 0;

    task check_nf4;
        input [3:0] expected;
        input [100*8:1] test_name;
        begin
            if (nf4_out !== expected) begin
                $display("FAIL: %s | fp16_in=%d scale=%d | got=%d expected=%d",
                         test_name, fp16_in, scale_idx, nf4_out, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s | fp16_in=%d scale=%d | nf4=%d",
                         test_name, fp16_in, scale_idx, nf4_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_nf4_quantizer.vcd");
        $dumpvars(0, tb_nf4_quantizer);
        $display("=== NF4 QUANTIZER TESTBENCH ===");
        $display("QLoRA NormalFloat4 quantization");

        // Test 1: Zero input
        $display("\nTest 1: Zero input");
        fp16_in = 16'd0; scale_idx = 4'd3; #1;
        check_nf4(4'h8, "Zero input");

        // Test 2: Small positive
        $display("\nTest 2: Small positive");
        fp16_in = 16'd500; scale_idx = 4'd3; #1;
        check_nf4(4'h9, "Small positive (~0.091)");

        // Test 3: Medium positive
        fp16_in = 16'd2000; scale_idx = 4'd3;
        check_nf4(4'h0, "Medium positive (~0.185)");

        // Test 4: Large positive
        fp16_in = 16'd4000; scale_idx = 4'd3;
        check_nf4(4'h1, "Large positive (~0.284)");

        // Test 5: Very large positive (clamp to max)
        fp16_in = 16'd6000; scale_idx = 4'd3;
        check_nf4(4'h5, "Very large positive (clamp)");

        // Test 6: Small negative
        $display("\nTest 6: Negative values");
        fp16_in = -16'd500; scale_idx = 4'd3;
        check_nf4(4'h8, "Small negative (~0)");

        fp16_in = -16'd1000; scale_idx = 4'd3;
        check_nf4(4'h7, "Medium negative (~-0.091)");

        // Test 7: Large negative
        fp16_in = -16'd4000; scale_idx = 4'd3;
        check_nf4(4'hD, "Large negative (~-0.284)");

        // Test 8: Very large negative (clamp)
        fp16_in = -16'd6000; scale_idx = 4'd3;
        check_nf4(4'hF, "Very large negative (clamp)");

        // Test 9: Different scale (scale_idx=0, 0.5x)
        $display("\nTest 9: Different scales");
        scale_idx = 4'd0; // 0.5x
        fp16_in = 16'd4000;
        check_nf4(4'h0, "Scale 0.5x - medium");

        scale_idx = 4'd1; // 0.25x
        check_nf4(4'h8, "Scale 0.25x - zero");

        // Summary
        $display("\n=== TEST SUMMARY ===");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $finish;
    end

endmodule