// SPDX-License-Identifier: Apache-2.0
// tb_integration_mesh.v — Integration test for GF16 mesh routing
// Tests packet flow through trinity_max_true_20pe

`default_nettype none
`timescale 1ns/1ps

// Include packet protocol
`define TRN_PKT_W 32
`define TRN_OP_LOAD_A 4'd1
`define TRN_OP_LOAD_B 4'd2
`define TRN_OP_COMPUTE 4'd3
`define TRN_OP_READ_RES 4'd6

// Packet macros
`define TRN_MK_PKT(op,dst,src,lane,payload) {op, 3'b0, dst, src, lane, 4'b0, payload}
`define TRN_PKT_DST(pkt) pkt[27:26]
`define TRN_PKT_SRC(pkt) pkt[25:24]
`define TRN_PKT_OP(pkt) pkt[31:28]
`define TRN_PKT_LANE(pkt) pkt[23:20]
`define TRN_PKT_PAYLOAD(pkt) pkt[15:0]

module tb_integration_mesh;

    reg clk;
    reg rst_n;
    reg ena;

    // Host interface
    reg [31:0] host_in_pkt;
    reg        host_in_valid;
    wire       host_in_ready;
    wire [31:0] host_out_pkt;
    wire       host_out_valid;
    reg        host_out_ready;

    // Debug
    wire [15:0] dbg_tile0;

    // DUT
    trinity_max_true_20pe dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .host_in_pkt     (host_in_pkt),
        .host_in_valid   (host_in_valid),
        .host_in_ready   (host_in_ready),
        .host_out_pkt    (host_out_pkt),
        .host_out_valid  (host_out_valid),
        .host_out_ready  (host_out_ready),
        .dbg_tile0_result(dbg_tile0)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 50 MHz
    end

    // Test tracking
    integer pass_count = 0;
    integer fail_count = 0;

    task check_result;
        input [15:0] expected;
        input [100*8:1] test_name;
        begin
            if (dbg_tile0 !== expected) begin
                $display("FAIL: %s | got=%h expected=%h",
                         test_name, dbg_tile0, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: %s | result=%h",
                         test_name, dbg_tile0);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Send packet task
    task send_pkt;
        input [31:0] pkt;
        begin
            host_in_pkt = pkt;
            host_in_valid = 1'b1;
            @(posedge clk);
            while (!host_in_ready) @(posedge clk);
            host_in_valid = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb_integration_mesh.vcd");
        $dumpvars(0, tb_integration_mesh);
        $display("=== INTEGRATION TEST: GF16 MESH ROUTING ===");

        // Initialize
        rst_n = 0;
        ena = 1'b1;
        host_in_valid = 1'b0;
        host_out_ready = 1'b1;
        #100;
        rst_n = 1;
        #100;

        // Test 1: Load operands and compute
        $display("\nTest 1: Single tile load-compute-read");
        // Load A lane 0
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b00, 2'b11, 4'd0, 16'h3E00));  // 1.0
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b00, 2'b11, 4'd1, 16'h4000));  // 2.0
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b00, 2'b11, 4'd2, 16'h4100));  // 3.0
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b00, 2'b11, 4'd3, 16'h4200));  // 4.0
        // Load B lane 0 (same as A for canonical)
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b00, 2'b11, 4'd0, 16'h3E00));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b00, 2'b11, 4'd1, 16'h4000));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b00, 2'b11, 4'd2, 16'h4100));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b00, 2'b11, 4'd3, 16'h4200));
        // Compute
        send_pkt(`TRN_MK_PKT(`TRN_OP_COMPUTE, 2'b00, 2'b11, 4'd0, 16'h0000));
        // Read result
        send_pkt(`TRN_MK_PKT(`TRN_OP_READ_RES, 2'b00, 2'b11, 4'd0, 16'h0000));
        #50;
        check_result(16'h47C0, "Canonical dot4(1,2,3,4)");

        // Test 2: Multiple tiles
        $display("\nTest 2: Multiple tile routing");
        // Load tile 1
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b01, 2'b11, 4'd0, 16'h0000));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b01, 2'b11, 4'd0, 16'h0000));
        send_pkt(`TRN_MK_PKT(`TRN_OP_COMPUTE, 2'b01, 2'b11, 4'd0, 16'h0000));
        #50;

        // Test 3: Boundary conditions
        $display("\nTest 3: Boundary conditions");
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b00, 2'b11, 4'd0, 16'h0000));  // Zero
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b00, 2'b11, 4'd1, 16'h0000));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b00, 2'b11, 4'd2, 16'h0000));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_A, 2'b00, 2'b11, 4'd3, 16'h0000));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b00, 2'b11, 4'd0, 16'h7E00));  // +Inf
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b00, 2'b11, 4'd1, 16'h7E00));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b00, 2'b11, 4'd2, 16'h7E00));
        send_pkt(`TRN_MK_PKT(`TRN_OP_LOAD_B, 2'b00, 2'b11, 4'd3, 16'h7E00));
        send_pkt(`TRN_MK_PKT(`TRN_OP_COMPUTE, 2'b00, 2'b11, 4'd0, 16'h0000));
        #50;

        // Summary
        $display("\n=== TEST SUMMARY ===");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $finish;
    end

endmodule