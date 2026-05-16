// SPDX-License-Identifier: Apache-2.0
// redteam_filter_tb.v — Testbench for CLARA Gap-1 adversarial detector
// Pure Verilog-2005. Tests each of the 5 detector categories.

`timescale 1ns/1ps
`default_nettype none

module redteam_filter_tb;

    // DUT inputs
    reg  [7:0]  reported_fuel;
    reg  [7:0]  actual_fuel;
    reg  [63:0] action_history;
    reg  [7:0]  timeline_offset;
    reg  [7:0]  compute_demand;
    reg  [3:0]  proof_trace_len;

    // DUT outputs
    wire [4:0]  attack_detected;
    wire        filter_block;

    // Test pass counter
    integer pass_count;
    integer fail_count;

    // Instantiate DUT
    redteam_filter dut (
        .reported_fuel   (reported_fuel),
        .actual_fuel     (actual_fuel),
        .action_history  (action_history),
        .timeline_offset (timeline_offset),
        .compute_demand  (compute_demand),
        .proof_trace_len (proof_trace_len),
        .attack_detected (attack_detected),
        .filter_block    (filter_block)
    );

    // Task: check a single test
    task check;
        input [63:0] test_id;
        input [4:0]  expected_detected;
        input        expected_block;
        input [8*40-1:0] test_name;
        begin
            #1; // allow combinational settle
            if ((attack_detected === expected_detected) && (filter_block === expected_block)) begin
                $display("PASS [%0d] %s | attack_detected=%05b filter_block=%b",
                    test_id, test_name, attack_detected, filter_block);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL [%0d] %s | got attack_detected=%05b filter_block=%b | expected attack_detected=%05b filter_block=%b",
                    test_id, test_name, attack_detected, filter_block, expected_detected, expected_block);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Safe baseline: all inputs benign
    task set_baseline;
        begin
            reported_fuel   = 8'd70;
            actual_fuel     = 8'd65;  // diff=5, safe
            // 16 slots with 4 different actions (0,1,2,3 x4 each) — no exhaustion
            action_history  = {4'd3,4'd2,4'd1,4'd0, 4'd3,4'd2,4'd1,4'd0,
                                4'd3,4'd2,4'd1,4'd0, 4'd3,4'd2,4'd1,4'd0};
            timeline_offset = 8'd10;    // small, safe (signed)
            compute_demand  = 8'd50;    // positive, safe
            proof_trace_len = 4'd5;     // ≤10, safe
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=== CLARA Gap-1 redteam_filter testbench ===");
        $display("5 categories: fuel | action | timeline | resource | trace");
        $display("");

        // -------------------------------------------------------
        // T1: Baseline — no attacks, all safe inputs
        // -------------------------------------------------------
        set_baseline();
        check(1, 5'b00000, 1'b0, "T1 baseline no-attack              ");

        // -------------------------------------------------------
        // T2: fuel_deception — reported 90%, actual 15% → diff=75 > 30
        // -------------------------------------------------------
        set_baseline();
        reported_fuel = 8'd90;
        actual_fuel   = 8'd15;
        check(2, 5'b00001, 1'b1, "T2 fuel_deception 90-15=75>30       ");

        // -------------------------------------------------------
        // T3: fuel_deception — exact threshold boundary: diff=30 → NOT triggered
        // -------------------------------------------------------
        set_baseline();
        reported_fuel = 8'd60;
        actual_fuel   = 8'd30;   // diff=30 exactly, NOT > 30
        check(3, 5'b00000, 1'b0, "T3 fuel_deception boundary=30 safe  ");

        // -------------------------------------------------------
        // T4: fuel_deception — diff=31 → triggered
        // -------------------------------------------------------
        set_baseline();
        reported_fuel = 8'd61;
        actual_fuel   = 8'd30;   // diff=31 > 30
        check(4, 5'b00001, 1'b1, "T4 fuel_deception diff=31 triggered ");

        // -------------------------------------------------------
        // T5: action_exhaustion — action 5 repeated 12/16 times (75% > 70%)
        // -------------------------------------------------------
        set_baseline();
        // 12 slots of action=5, 4 slots of action=0,1,2,3
        action_history = {4'd5,4'd5,4'd5,4'd5, 4'd5,4'd5,4'd5,4'd5,
                           4'd5,4'd5,4'd5,4'd5, 4'd3,4'd2,4'd1,4'd0};
        check(5, 5'b00010, 1'b1, "T5 action_exhaustion 12/16 of act5  ");

        // -------------------------------------------------------
        // T6: action_exhaustion — action 7 repeated 11/16 → NOT triggered (11 ≤ 11)
        // -------------------------------------------------------
        set_baseline();
        action_history = {4'd7,4'd7,4'd7,4'd7, 4'd7,4'd7,4'd7,4'd7,
                           4'd7,4'd7,4'd7,4'd0, 4'd1,4'd2,4'd3,4'd4};
        check(6, 5'b00000, 1'b0, "T6 action_exhaustion 11/16 boundary ");

        // -------------------------------------------------------
        // T7: action_exhaustion — action 2 all 16 slots → max exhaustion
        // -------------------------------------------------------
        set_baseline();
        action_history = {4'd2,4'd2,4'd2,4'd2, 4'd2,4'd2,4'd2,4'd2,
                           4'd2,4'd2,4'd2,4'd2, 4'd2,4'd2,4'd2,4'd2};
        check(7, 5'b00010, 1'b1, "T7 action_exhaustion all-same 16/16 ");

        // -------------------------------------------------------
        // T8: timeline_manipulation — offset=+60 (>50) triggers
        // -------------------------------------------------------
        set_baseline();
        timeline_offset = 8'd60;    // unsigned rep of +60, > 50
        check(8, 5'b00100, 1'b1, "T8 timeline +60>50 triggered        ");

        // -------------------------------------------------------
        // T9: timeline_manipulation — negative offset: 8'hC8 = -56 → |offset|=56>50
        // -------------------------------------------------------
        set_baseline();
        timeline_offset = 8'hC8;    // 2's complement of -56 = 0xC8
        check(9, 5'b00100, 1'b1, "T9 timeline -56 abs=56>50 triggered ");

        // -------------------------------------------------------
        // T10: timeline_manipulation — safe: offset=50 exactly NOT triggered
        // -------------------------------------------------------
        set_baseline();
        timeline_offset = 8'd50;    // exactly 50, NOT > 50
        check(10, 5'b00000, 1'b0, "T10 timeline offset=50 boundary safe");

        // -------------------------------------------------------
        // T11: resource_poisoning — negative demand: 8'hCE = -50
        // -------------------------------------------------------
        set_baseline();
        compute_demand = 8'hCE;     // negative (bit7=1)
        check(11, 5'b01000, 1'b1, "T11 resource negative demand -50    ");

        // -------------------------------------------------------
        // T12: resource_poisoning — excessive demand: 200 > 150
        // -------------------------------------------------------
        set_baseline();
        compute_demand = 8'd200;    // 200 > 150, but bit7=1 (>128) also fires sign
        check(12, 5'b01000, 1'b1, "T12 resource excessive demand 200   ");

        // -------------------------------------------------------
        // T13: resource_poisoning — demand=120 (positive, ≤150) NOT triggered
        // Note: spec uses signed interpretation; 150 = 0x96 has bit7=1 so fires.
        // Safe values must be ≤127 (positive in 2's complement) AND ≤150.
        // -------------------------------------------------------
        set_baseline();
        compute_demand = 8'd120;    // 0x78, bit7=0, 120 ≤ 150, safe
        check(13, 5'b00000, 1'b0, "T13 resource demand=120 safe        ");

        // -------------------------------------------------------
        // T14: proof_trace_overflow — len=11 > 10 triggers
        // -------------------------------------------------------
        set_baseline();
        proof_trace_len = 4'd11;
        check(14, 5'b10000, 1'b1, "T14 proof_trace len=11>10 triggered ");

        // -------------------------------------------------------
        // T15: proof_trace_overflow — len=10 safe (NOT > 10)
        // -------------------------------------------------------
        set_baseline();
        proof_trace_len = 4'd10;
        check(15, 5'b00000, 1'b0, "T15 proof_trace len=10 boundary safe");

        // -------------------------------------------------------
        // T16: proof_trace_overflow — len=15 maximum 4-bit → triggered
        // -------------------------------------------------------
        set_baseline();
        proof_trace_len = 4'd15;
        check(16, 5'b10000, 1'b1, "T16 proof_trace len=15 max triggered");

        // -------------------------------------------------------
        // T17: Multiple attacks simultaneously (fuel + timeline + trace)
        // -------------------------------------------------------
        set_baseline();
        reported_fuel   = 8'd90;
        actual_fuel     = 8'd20;    // fuel diff=70 > 30
        timeline_offset = 8'd80;    // > 50
        proof_trace_len = 4'd12;    // > 10
        check(17, 5'b10101, 1'b1, "T17 multi-attack fuel+tl+trace     ");

        // -------------------------------------------------------
        // T18: All 5 attacks simultaneously
        // -------------------------------------------------------
        reported_fuel   = 8'd90;
        actual_fuel     = 8'd5;     // fuel diff=85 > 30
        action_history  = {4'd9,4'd9,4'd9,4'd9, 4'd9,4'd9,4'd9,4'd9,
                            4'd9,4'd9,4'd9,4'd9, 4'd9,4'd9,4'd9,4'd9}; // 16/16 action 9
        timeline_offset = 8'd100;   // > 50
        compute_demand  = 8'hFF;    // negative (bit7=1)
        proof_trace_len = 4'd15;    // > 10
        check(18, 5'b11111, 1'b1, "T18 all-5-attacks simultaneously   ");

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("");
        $display("=== SUMMARY: %0d/%0d tests PASSED ===", pass_count, pass_count + fail_count);
        if (fail_count == 0) begin
            $display("ALL TESTS PASS — CLARA Gap-1 redteam_filter GREEN");
        end else begin
            $display("FAILURES: %0d — AMBER/RED", fail_count);
        end
        $finish;
    end

endmodule
`default_nettype wire
