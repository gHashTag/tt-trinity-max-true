// SPDX-License-Identifier: Apache-2.0
// tb_integration_d2d.v — Integration test for D2D holographic mesh
// Tests cross-die communication with LAYER-FROZEN gate

`default_nettype none
`timescale 1ns / 1ps

module tb_integration_d2d;

    reg clk;
    reg rst_n;
    reg ena;

    // D2D signals
    wire d2d_n_tx, d2d_e_tx, d2d_s_tx, d2d_w_tx;
    reg  d2d_n_rx, d2d_e_rx, d2d_s_rx, d2d_w_rx;
    wire d2d_n_rx_q, d2d_e_rx_q, d2d_s_rx_q, d2d_w_rx_q;
    wire mesh_ok;

    // Cortex emulation
    reg [3:0] cortex_spike_count;
    reg [7:0] cortex_spike_vec;
    reg [3:0] gf_tag;
    reg layer_frozen;

    // Simulated external peer responses
    reg peer_n_tx, peer_e_tx, peer_s_tx, peer_w_tx;

    // DUT
    d2d_holo_mesh dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .ena         (ena),
        .spike_count (cortex_spike_count),
        .spike_vec   (cortex_spike_vec),
        .gf_tag      (gf_tag),
        .layer_frozen(layer_frozen),
        // RX from external (connected to simulated peer)
        .n_rx        (peer_n_tx),
        .e_rx        (peer_e_tx),
        .s_rx        (peer_s_tx),
        .w_rx        (peer_w_tx),
        .n_tx        (d2d_n_tx),
        .e_tx        (d2d_e_tx),
        .s_tx        (d2d_s_tx),
        .w_tx        (d2d_w_tx),
        .n_rx_q      (d2d_n_rx_q),
        .e_rx_q      (d2d_e_rx_q),
        .s_rx_q      (d2d_s_rx_q),
        .w_rx_q      (d2d_w_rx_q),
        .mesh_ok     (mesh_ok)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 50 MHz
    end

    // Test tracking
    integer pass_count = 0;
    integer fail_count = 0;

    task check_tx;
        input expected_n, expected_e, expected_s, expected_w;
        input [100*8:1] test_name;
        begin
            if ({d2d_n_tx, d2d_e_tx, d2d_s_tx, d2d_w_tx} !== {expected_n, expected_e, expected_s, expected_w}) begin
                $display("FAIL: %s | TX=%b expected=%b",
                         test_name, {d2d_n_tx, d2d_e_tx, d2d_s_tx, d2d_w_tx},
                         {expected_n, expected_e, expected_s, expected_w});
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s | TX(N,E,S,W)=%b",
                         test_name, {d2d_n_tx, d2d_e_tx, d2d_s_tx, d2d_w_tx});
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check_rx_q;
        input expected_n, expected_e, expected_s, expected_w;
        input [100*8:1] test_name;
        begin
            if ({d2d_n_rx_q, d2d_e_rx_q, d2d_s_rx_q, d2d_w_rx_q} !== {expected_n, expected_e, expected_s, expected_w}) begin
                $display("FAIL: %s | RX_Q=%b expected=%b",
                         test_name, {d2d_n_rx_q, d2d_e_rx_q, d2d_s_rx_q, d2d_w_rx_q},
                         {expected_n, expected_e, expected_s, expected_w});
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s | RX_Q(N,E,S,W)=%b",
                         test_name, {d2d_n_rx_q, d2d_e_rx_q, d2d_s_rx_q, d2d_w_rx_q});
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_integration_d2d.vcd");
        $dumpvars(0, tb_integration_d2d);
        $display("=== INTEGRATION TEST: D2D HOLOGRAPHIC MESH ===");

        // Initialize
        rst_n = 0;
        ena = 1'b1;
        cortex_spike_count = 4'h0;
        cortex_spike_vec = 8'h0;
        gf_tag = 4'h0;
        layer_frozen = 1'b0;
        peer_n_tx = 1'b0;
        peer_e_tx = 1'b0;
        peer_s_tx = 1'b0;
        peer_w_tx = 1'b0;
        #100;
        rst_n = 1;
        #100;

        // Test 1: Idle state
        $display("\nTest 1: Idle state (no activity)");
        check_tx(1'b0, 1'b0, 1'b0, 1'b0, "Idle TX");

        // Test 2: Low activity (count = 1 = 0001)
        $display("\nTest 2: Low activity");
        cortex_spike_count = 4'h1;
        cortex_spike_vec = 8'h01;
        #50;
        check_tx(1'b0, 1'b1, 1'b0, 1'b0, "Low activity TX (N=0, E=1, S=0, W=0)");

        // Test 3: High activity (count = 8 = 1000) → SYNC on W
        $display("\nTest 3: High activity (SYNC on W)");
        cortex_spike_count = 4'h8;
        cortex_spike_vec = 8'hFF;
        #50;
        check_tx(1'b1, 1'b0, gf_tag[0], 1'b1, "High activity TX (SYNC on W)");

        // Test 4: LAYER-FROZEN gate (SYNC blocked)
        $display("\nTest 4: LAYER-FROZEN gate (PhD Thm 36.1 R18)");
        layer_frozen = 1'b1;
        cortex_spike_count = 4'h8;
        #50;
        check_tx(1'b1, 1'b0, gf_tag[0], 1'b0, "LAYER-FROZEN: W TX = 0 (SYNC blocked)");

        // Test 5: LAYER-FROZEN release
        $display("\nTest 5: LAYER-FROZEN release");
        layer_frozen = 1'b0;
        #50;
        check_tx(1'b1, 1'b0, gf_tag[0], 1'b1, "LAYER-FROZEN released: W TX = 1");

        // Test 6: RX from peers
        $display("\nTest 6: RX from peer chips");
        peer_n_tx = 1'b1;
        peer_e_tx = 1'b0;
        peer_s_tx = 1'b1;
        peer_w_tx = 1'b0;
        #50;
        check_rx_q(1'b1, 1'b0, 1'b1, 1'b0, "RX latch from peers");

        // Test 7: GF16 tag routing
        $display("\nTest 7: GF16 tag routing (south TX)");
        cortex_spike_count = 4'h4;  // Middle activity
        gf_tag = 4'h1;               // Tag bit = 1
        #50;
        check_tx(1'b0, 1'b0, 1'b1, 1'b0, "GF16 tag on S TX");

        // Summary
        $display("\n=== TEST SUMMARY ===");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $display("Mesh OK: %d", mesh_ok);
        $finish;
    end

endmodule