// SPDX-License-Identifier: Apache-2.0
// tb_integration_cortex.v — Integration test for neuromorphic cortex
// Tests cortex-mesh interaction and spike propagation

`default_nettype none
`timescale 1ns / 1ps

module tb_integration_cortex;

    reg clk;
    reg rst_n;
    reg ena;

    // Cortex inputs
    reg [3:0] gf_in0, gf_in1, gf_in2, gf_in3;
    reg [31:0] stim_bus;
    wire [3:0] spike_count;
    wire [7:0] spike_vec;
    wire cortex_ok;
    wire [7:0] membrane_dbg;

    // DUT
    trinity_cortex_8col dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .ena         (ena),
        .gf_in0      (gf_in0),
        .gf_in1      (gf_in1),
        .gf_in2      (gf_in2),
        .gf_in3      (gf_in3),
        .stim_bus    (stim_bus),
        .spike_count (spike_count),
        .spike_vec   (spike_vec),
        .cortex_ok   (cortex_ok)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 50 MHz
    end

    // Test tracking
    integer pass_count = 0;
    integer fail_count = 0;

    task check_spike_count;
        input [3:0] expected;
        input [100*8:1] test_name;
        begin
            if (spike_count !== expected) begin
                $display("FAIL: %s | spike_count=%d expected=%d",
                         test_name, spike_count, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s | spike_count=%d, vec=%b",
                         test_name, spike_count, spike_vec);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_integration_cortex.vcd");
        $dumpvars(0, tb_integration_cortex);
        $display("=== INTEGRATION TEST: NEUROMORPHIC CORTEX ===");

        // Initialize
        rst_n = 0;
        ena = 1'b1;
        gf_in0 = 4'h0;
        gf_in1 = 4'h0;
        gf_in2 = 4'h0;
        gf_in3 = 4'h0;
        stim_bus = 32'h0;
        #100;
        rst_n = 1;
        #100;

        // Test 1: Idle state
        $display("\nTest 1: Idle state (no spikes)");
        #200;
        check_spike_count(4'h0, "Idle state - no activity");

        // Test 2: Stimulate one column
        $display("\nTest 2: Single column stimulation");
        stim_bus[3:0] = 4'hF;  // Max stimulus to column 0
        #400;  // Wait for membrane to integrate
        check_spike_count(4'h1, "Single column spike");

        // Test 3: Stimulate all columns
        $display("\nTest 3: All columns stimulation");
        stim_bus = 32'hFFFFFFFF;  // Max stimulus to all columns
        #400;
        check_spike_count(4'h8, "All columns spike");

        // Test 4: Partial stimulation
        $display("\nTest 4: Partial stimulation");
        stim_bus = 32'h0F0F0F0F;  // Alternating columns
        #400;
        check_spike_count(4'h4, "Half columns spike");

        // Test 5: GF16 input coupling
        $display("\nTest 5: GF16 input coupling");
        stim_bus = 32'h0;
        gf_in0 = 4'hF;
        gf_in1 = 4'h0;
        gf_in2 = 4'hF;
        gf_in3 = 4'h0;
        #400;
        check_spike_count(4'h2, "GF16-driven spikes");

        // Test 6: Spike decay (refractory)
        $display("\nTest 6: Spike refractory period");
        stim_bus = 32'h0;
        gf_in0 = 4'h0;
        gf_in1 = 4'h0;
        gf_in2 = 4'h0;
        gf_in3 = 4'h0;
        #100;
        // After refractory, no immediate re-fire
        check_spike_count(4'h0, "Post-refractory state");

        // Summary
        $display("\n=== TEST SUMMARY ===");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $display("Cortex OK: %d", cortex_ok);
        $finish;
    end

endmodule