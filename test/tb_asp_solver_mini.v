// SPDX-License-Identifier: Apache-2.0
// tb_asp_solver_mini.v — Testbench for CLARA Gap-6 ASP solver
// 4 test scenarios:
//   Scenario 1: Simple positive chain (no negation)
//   Scenario 2: Negation-as-failure (classic not)
//   Scenario 3: No stable model — oscillation → capped after 8 iterations
//   Scenario 4: Full 16-rule program (8 positive + 4 NAF + 4 unconditional)
//
// Target: 10+ assertions PASS
// R-SI-1: zero * operator
// Verilog-2005 only

`default_nettype none
`timescale 1ns/1ps

module tb_asp_solver_mini;

    // ----------------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         load_rule;
    reg  [3:0]  rule_idx;
    reg  [23:0] rule_data;
    reg         start;

    wire [15:0] model_out;
    wire        stable;
    wire [3:0]  iter_count;
    wire        capped;

    // Instantiate DUT
    asp_solver_mini dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .load_rule  (load_rule),
        .rule_idx   (rule_idx),
        .rule_data  (rule_data),
        .start      (start),
        .model_out  (model_out),
        .stable     (stable),
        .iter_count (iter_count),
        .capped     (capped)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    integer errors;
    integer pass_cnt;

    // ----------------------------------------------------------------
    // Helper tasks
    // ----------------------------------------------------------------

    // Load a rule: {valid=1, head[3:0], pos_body[7:0], neg_body[7:0], _unused[2:0]}
    task load_one_rule;
        input [3:0]  idx;
        input [3:0]  head;
        input [7:0]  pos_body;
        input [7:0]  neg_body;
        begin
            @(negedge clk);
            load_rule <= 1'b1;
            rule_idx  <= idx;
            // rule_data: {valid[1], head[4], pos_body[8], neg_body[8], _unused[3]}
            rule_data <= {1'b1, head, pos_body, neg_body, 3'b000};
            @(negedge clk);
            load_rule <= 1'b0;
        end
    endtask

    // Clear a rule slot (valid=0)
    task clear_rule;
        input [3:0] idx;
        begin
            @(negedge clk);
            load_rule <= 1'b1;
            rule_idx  <= idx;
            rule_data <= 24'h0;
            @(negedge clk);
            load_rule <= 1'b0;
        end
    endtask

    // Assert helper
    task assert_eq;
        input [31:0] got;
        input [31:0] expected;
        input [63:0] label;
        begin
            if (got === expected) begin
                $display("  PASS [%0s]: got=%0h expected=%0h", label, got, expected);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL [%0s]: got=%0h expected=%0h", label, got, expected);
                errors = errors + 1;
            end
        end
    endtask

    // Wait for stable with timeout
    task wait_stable;
        input integer max_cycles;
        integer cnt;
        begin
            cnt = 0;
            while (!stable && cnt < max_cycles) begin
                @(posedge clk);
                #1;
                cnt = cnt + 1;
            end
            if (!stable)
                $display("  WARN: stable not asserted after %0d cycles", max_cycles);
        end
    endtask

    // Clear all 16 rule slots
    task clear_all_rules;
        integer k;
        begin
            for (k = 0; k < 16; k = k + 1)
                clear_rule(k[3:0]);
        end
    endtask

    // Reset DUT
    task do_reset;
        begin
            rst_n = 1'b0;
            start = 1'b0;
            load_rule = 1'b0;
            rule_idx  = 4'h0;
            rule_data = 24'h0;
            repeat(4) @(negedge clk);
            rst_n = 1'b1;
            @(negedge clk);
        end
    endtask

    // ================================================================
    // MAIN TEST
    // ================================================================
    initial begin
        errors   = 0;
        pass_cnt = 0;

        do_reset;

        // ============================================================
        // SCENARIO 1: Simple positive forward chain (no negation)
        // Program:
        //   r0: a0 <- (fact, pos_body=0, neg_body=0)   head=0
        //   r1: a1 <- a0                               head=1, pos=0x01
        //   r2: a2 <- a0 & a1                          head=2, pos=0x03
        //   r3: a3 <- a2                               head=3, pos=0x04
        //
        // TP sequence (model starts at 0):
        //   iter 1: r0 fires (pos=0,neg=0 → OK)  → model={a0}  =0x0001
        //   iter 2: r0,r1 fire                   → model={a0,a1}=0x0003
        //   iter 3: r0,r1,r2 fire                → model={a0,a1,a2}=0x0007
        //   iter 4: r0,r1,r2,r3 fire             → model={a0,a1,a2,a3}=0x000F
        //   iter 5: same → stable model = 0x000F
        // ============================================================
        $display("=== SCENARIO 1: Simple positive chain ===");

        // Load 4 rules
        // r0: head=0, pos=0x00 (unconditional fact), neg=0x00
        load_one_rule(4'd0, 4'd0, 8'h00, 8'h00);
        // r1: head=1, pos=0x01 (a0), neg=0x00
        load_one_rule(4'd1, 4'd1, 8'h01, 8'h00);
        // r2: head=2, pos=0x03 (a0 & a1), neg=0x00
        load_one_rule(4'd2, 4'd2, 8'h03, 8'h00);
        // r3: head=3, pos=0x04 (a2), neg=0x00
        load_one_rule(4'd3, 4'd3, 8'h04, 8'h00);

        // Trigger solve
        @(negedge clk);
        start <= 1'b1;
        @(negedge clk);
        start <= 1'b0;

        wait_stable(30);

        // ASSERTION 1: stable asserted
        assert_eq(stable, 1'b1, "S1_stable");
        // ASSERTION 2: model contains a0,a1,a2,a3 (bits 3:0)
        assert_eq(model_out[3:0], 4'hF, "S1_model_3:0");
        // ASSERTION 3: no atoms beyond bit 3 set
        assert_eq(model_out[15:4], 12'h000, "S1_model_15:4_zero");
        // ASSERTION 4: not capped (converged cleanly)
        assert_eq(capped, 1'b0, "S1_not_capped");

        // ============================================================
        // SCENARIO 2: Negation-as-failure
        // Program:
        //   r0: b0 <- not b1      head=0, pos=0x00, neg=0x02 (not a1)
        //   r1: b1 <- not b0      head=1, pos=0x00, neg=0x01 (not a0)
        //   (Classic ASP: two stable models exist: {b0} or {b1})
        //   (TP from empty model:)
        //     iter 1: model=0: r0 fires (neg_body bit 1 = b1 not in {}), r1 fires (neg bit 0 = b0 not in {})
        //             → new_model = {b0, b1} = 0x0003
        //     iter 2: model={b0,b1}: r0 checks neg=0x02 & m8=0x03 = 0x02 ≠ 0 → r0 blocked
        //             r1 checks neg=0x01 & m8=0x03 = 0x01 ≠ 0 → r1 blocked
        //             → new_model = 0x0000
        //     iter 3: back to {} → fires same as iter 1 → 0x0003 again
        //     → oscillation until cap at 8 iterations
        // ============================================================
        $display("=== SCENARIO 2: Negation-as-failure (classic) ===");

        do_reset;
        clear_all_rules;

        // r0: b0 <- not b1; head=0, pos=0x00, neg=0x02
        load_one_rule(4'd0, 4'd0, 8'h00, 8'h02);
        // r1: b1 <- not b0; head=1, pos=0x00, neg=0x01
        load_one_rule(4'd1, 4'd1, 8'h00, 8'h01);

        @(negedge clk);
        start <= 1'b1;
        @(negedge clk);
        start <= 1'b0;

        wait_stable(30);

        // ASSERTION 5: stable asserted (capped after 8 iterations)
        assert_eq(stable, 1'b1, "S2_stable");
        // ASSERTION 6: capped flag set (oscillation detected)
        assert_eq(capped, 1'b1, "S2_capped");
        // ASSERTION 7: iter_count == 8 (hit cap)
        assert_eq(iter_count, 4'd8, "S2_iter_count_8");

        // ============================================================
        // SCENARIO 3: NAF with definite stable model
        // Program:
        //   r0: c0 <- (fact)          head=0, pos=0x00, neg=0x00
        //   r1: c2 <- not c1          head=2, pos=0x00, neg=0x02 (not c1)
        //   c1 is never derived, so not c1 is always satisfied
        //   Stable model: {c0, c2} = 0x0005
        //
        // TP from empty:
        //   iter 1: r0 fires → c0; r1 fires (c1 not in model) → c2
        //           new_model = 0x0005
        //   iter 2: r0 fires → c0; r1 checks neg=0x02, m8=0x05→0x02&0x05=0 → fires → c2
        //           new_model = 0x0005 == model → STABLE
        // ============================================================
        $display("=== SCENARIO 3: NAF with definite stable model ===");

        do_reset;
        clear_all_rules;

        // r0: c0 <- fact; head=0, pos=0x00, neg=0x00
        load_one_rule(4'd0, 4'd0, 8'h00, 8'h00);
        // r1: c2 <- not c1; head=2, pos=0x00, neg=0x02
        load_one_rule(4'd1, 4'd2, 8'h00, 8'h02);

        @(negedge clk);
        start <= 1'b1;
        @(negedge clk);
        start <= 1'b0;

        wait_stable(30);

        // ASSERTION 8: stable
        assert_eq(stable, 1'b1, "S3_stable");
        // ASSERTION 9: model = {c0, c2} = 0x0005
        assert_eq(model_out[7:0], 8'h05, "S3_model_c0_c2");
        // ASSERTION 10: not capped
        assert_eq(capped, 1'b0, "S3_not_capped");

        // ============================================================
        // SCENARIO 4: Full 16-rule program
        // 4 unconditional facts + 4 positive-body rules + 4 NAF rules + 4 invalid
        //
        // Facts: d0,d1,d2,d3 (rules 0-3): head=0..3, pos=0x00, neg=0x00
        // Pos rules (rules 4-7):
        //   r4: d4 <- d0 & d1   head=4, pos=0x03
        //   r5: d5 <- d2 & d3   head=5, pos=0x0C
        //   r6: d6 <- d4 & d5   head=6, pos=0x30
        //   r7: d7 <- d6        head=7, pos=0x40
        // NAF rules (rules 8-11):
        //   r8:  d8  <- not d15   head=8,  pos=0x00, neg=0x80
        //   r9:  d9  <- d0, not d15  head=9, pos=0x01, neg=0x80
        //   r10: d10 <- d1, not d15  head=10, pos=0x02, neg=0x80
        //   r11: d11 <- d8, not d12  head=11, pos=0x00 (uses bit from higher), neg=0x10 -> d4
        //       Actually d8 not in pos_body domain [7:0], let's use atoms within range:
        //       r11: d11 <- d0, not d5   head=11, pos=0x01, neg=0x20
        // Invalid rules (rules 12-15): valid=0 → clear
        //
        // Expected stable model:
        //   d0..d3 set (facts)
        //   d4 <- 0x03 in model (d0,d1) → set
        //   d5 <- 0x0C in model (d2,d3) → set
        //   d6 <- 0x30 in model (d4,d5) → set  [0x30 = bits 5:4]
        //   d7 <- 0x40 in model (d6)    → set  [0x40 = bit 6]
        //   d8 <- not d15 (bit 7 of neg=0x80): d15 not in model → d8 set
        //   d9 <- d0 & not d15 → set
        //   d10 <- d1 & not d15 → set
        //   d11 <- d0 & not d5: d5 IS in model (bit 5 of neg=0x20) → blocked
        //   d15 not derived → model[15]=0
        //
        // Expected model: d0..d10 set = bits 0..10 = 0x07FF
        // ============================================================
        $display("=== SCENARIO 4: Full 16-rule program ===");

        do_reset;
        clear_all_rules;

        // Unconditional facts: d0..d3
        load_one_rule(4'd0,  4'd0,  8'h00, 8'h00); // d0
        load_one_rule(4'd1,  4'd1,  8'h00, 8'h00); // d1
        load_one_rule(4'd2,  4'd2,  8'h00, 8'h00); // d2
        load_one_rule(4'd3,  4'd3,  8'h00, 8'h00); // d3

        // Positive body chain
        load_one_rule(4'd4,  4'd4,  8'h03, 8'h00); // d4 <- d0&d1
        load_one_rule(4'd5,  4'd5,  8'h0C, 8'h00); // d5 <- d2&d3
        load_one_rule(4'd6,  4'd6,  8'h30, 8'h00); // d6 <- d4&d5
        load_one_rule(4'd7,  4'd7,  8'h40, 8'h00); // d7 <- d6

        // NAF rules
        load_one_rule(4'd8,  4'd8,  8'h00, 8'h80); // d8  <- not d7(bit7)
        load_one_rule(4'd9,  4'd9,  8'h01, 8'h80); // d9  <- d0, not d7
        load_one_rule(4'd10, 4'd10, 8'h02, 8'h80); // d10 <- d1, not d7
        load_one_rule(4'd11, 4'd11, 8'h01, 8'h20); // d11 <- d0, not d5(bit5)

        // Rules 12..15: invalid (cleared — valid=0 by default from reset)
        // They were set to 0 by reset / clear_all_rules already.
        // Explicitly clear to be safe:
        clear_rule(4'd12);
        clear_rule(4'd13);
        clear_rule(4'd14);
        clear_rule(4'd15);

        @(negedge clk);
        start <= 1'b1;
        @(negedge clk);
        start <= 1'b0;

        wait_stable(40);

        // ASSERTION 11: stable
        assert_eq(stable, 1'b1, "S4_stable");

        // ASSERTION 12: d0..d7 set (bits 7:0 all high)
        assert_eq(model_out[7:0], 8'hFF, "S4_d0_d7_all_set");

        // ASSERTION 13: d8,d9,d10 set; d11 blocked by d5
        // d7 IS in model → neg_body=0x80 check: bit 7 of neg = d7's bit → model[7]=1 → r8,r9,r10 BLOCKED
        // Wait: d7 uses head=7. d7's bit is model[7].
        // neg_body=0x80 means neg bit 7 = atom index 7 = d7.
        // model[7:0] = 0xFF → d7 IS present → neg_ok = ~|(0x80 & 0xFF) = ~|0x80 = 0
        // So r8,r9,r10 are BLOCKED because d7 is in model.
        // d11: pos=0x01 (d0 present✓), neg=0x20 (bit5=d5): model[5]=1 → blocked.
        // Expected: bits 8..11 all zero
        assert_eq(model_out[11:8], 4'h0, "S4_d8_d11_blocked");

        // ASSERTION 14: not capped
        assert_eq(capped, 1'b0, "S4_not_capped");

        // ASSERTION 15: model[15:12] = 0
        assert_eq(model_out[15:12], 4'h0, "S4_upper_bits_zero");

        // ============================================================
        // SUMMARY
        // ============================================================
        $display("");
        $display("=== SUMMARY ===");
        $display("  PASS: %0d", pass_cnt);
        $display("  FAIL: %0d", errors);

        if (errors == 0)
            $display("  ALL ASSERTIONS PASSED");
        else
            $display("  SOME ASSERTIONS FAILED");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #100000;
        $display("TIMEOUT: simulation exceeded 100us");
        $finish;
    end

endmodule
`default_nettype wire
