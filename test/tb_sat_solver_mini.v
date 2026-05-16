// SPDX-License-Identifier: Apache-2.0
// tb_sat_solver_mini.v — Testbench for CLARA Gap-9 SAT solver mini
// 4 scenarios:
//   S1: trivial SAT     — single clause (x0 OR x1 OR x2), all vars unassigned → SAT
//   S2: trivial UNSAT   — x0 AND ~x0 (two unit clauses forcing contradiction)
//   S3: 3-clause chain  — unit propagation chain forces x0→x1→x2
//   S4: 16-clause hard  — pigeon-hole-style, mixed SAT
//
// Target: 12+ assertions PASS
//
// Clause encoding helper:
//   24-bit clause_data = {valid[23], lit2[22:19], lit1[18:15], lit0[14:11], pad[10:0]}
//   Each lit = {var[2:0], neg[0]}
//   e.g. x0 positive = {3'd0, 1'b0} = 4'h0
//        x0 negative = {3'd0, 1'b1} = 4'h1
//        x1 positive = {3'd1, 1'b0} = 4'h2
//        x1 negative = {3'd1, 1'b1} = 4'h3
//        x2 positive = {3'd2, 1'b0} = 4'h4
//        x2 negative = {3'd2, 1'b1} = 4'h5
//        etc.
//
// Clause word builder macro (inline):
//   valid=1, lit2={v2,n2}, lit1={v1,n1}, lit0={v0,n0}:
//   {1'b1, v2[2:0], n2, v1[2:0], n1, v0[2:0], n0, 11'h0}
//
// Timeout: 200 clocks per scenario

`default_nettype none
`timescale 1ns/1ps

module tb_sat_solver_mini;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg         load_clause;
    reg  [3:0]  clause_idx;
    reg  [23:0] clause_data;
    reg         start;

    wire        sat;
    wire        unsat;
    wire        done;
    wire [7:0]  assign_out;
    wire [3:0]  iter_count;

    // -----------------------------------------------------------------------
    // Instantiate DUT
    // -----------------------------------------------------------------------
    sat_solver_mini dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .load_clause (load_clause),
        .clause_idx  (clause_idx),
        .clause_data (clause_data),
        .start       (start),
        .sat         (sat),
        .unsat       (unsat),
        .done        (done),
        .assign_out  (assign_out),
        .iter_count  (iter_count)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Test counters
    integer pass_cnt;
    integer fail_cnt;
    integer timeout_cnt;

    // -----------------------------------------------------------------------
    // Helper task: load a clause
    // -----------------------------------------------------------------------
    task do_load_clause;
        input [3:0]  idx;
        input [23:0] data;
        begin
            @(negedge clk);
            load_clause <= 1'b1;
            clause_idx  <= idx;
            clause_data <= data;
            @(negedge clk);
            load_clause <= 1'b0;
        end
    endtask

    // Helper task: reset FSM and clear clauses
    task do_reset;
        integer i;
        begin
            @(negedge clk);
            rst_n = 1'b0;
            start = 1'b0;
            load_clause = 1'b0;
            repeat(4) @(negedge clk);
            rst_n = 1'b1;
            @(negedge clk);
            // Clear all clause slots
            load_clause = 1'b1;
            for (i = 0; i < 16; i = i + 1) begin
                clause_idx  = i[3:0];
                clause_data = 24'h0; // valid=0
                @(negedge clk);
            end
            load_clause = 1'b0;
            @(negedge clk);
        end
    endtask

    // Helper task: start solver and wait for done (timeout = 200 clocks)
    task do_start_and_wait;
        integer t;
        begin
            @(negedge clk);
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            t = 0;
            while (!done && t < 200) begin
                @(posedge clk);
                #1;
                t = t + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Assertion helper
    // -----------------------------------------------------------------------
    task assert_eq;
        input [63:0] actual;
        input [63:0] expected;
        input [127:0] label;
        begin
            if (actual === expected) begin
                $display("  PASS [%0s]: actual=%0d expected=%0d", label, actual, expected);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL [%0s]: actual=%0d expected=%0d", label, actual, expected);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    task assert_true;
        input       cond;
        input [127:0] label;
        begin
            if (cond) begin
                $display("  PASS [%0s]", label);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL [%0s]: condition was false", label);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    // -----------------------------------------------------------------------
    // Clause word builder function
    // {valid=1, lit2={v2,n2}[3:0], lit1={v1,n1}[3:0], lit0={v0,n0}[3:0], 11'h0}
    // -----------------------------------------------------------------------
    function [23:0] make_clause;
        input [2:0] v0; input n0;
        input [2:0] v1; input n1;
        input [2:0] v2; input n2;
        begin
            make_clause = {1'b1, v2, n2, v1, n1, v0, n0, 11'h0};
        end
    endfunction

    // -----------------------------------------------------------------------
    // MAIN
    // -----------------------------------------------------------------------
    integer t;

    initial begin
        pass_cnt    = 0;
        fail_cnt    = 0;
        load_clause = 0;
        clause_idx  = 0;
        clause_data = 0;
        start       = 0;
        rst_n       = 0;

        $display("==========================================================");
        $display(" CLARA Gap-9 sat_solver_mini testbench");
        $display("==========================================================");

        // ==================================================================
        // SCENARIO 1: Trivial SAT
        //   One clause: (x0 OR x1 OR x2)
        //   Expected: SAT, done=1, unsat=0, assign satisfies clause
        // ==================================================================
        $display("");
        $display("--- S1: Trivial SAT ---");
        do_reset;

        // Load clause 0: (x0 OR x1 OR x2) — all positive
        do_load_clause(4'd0, make_clause(3'd0, 1'b0, 3'd1, 1'b0, 3'd2, 1'b0));
        // Load clauses 1..15 as invalid (already cleared)

        do_start_and_wait;

        assert_true(done,  "S1_done");
        assert_true(sat,   "S1_sat");
        assert_true(!unsat,"S1_not_unsat");
        // At least one of x0, x1, x2 must be true in assign_out
        assert_true(assign_out[0] | assign_out[1] | assign_out[2], "S1_clause_satisfied");

        // ==================================================================
        // SCENARIO 2: Trivial UNSAT
        //   Clause 0: (x0) — unit clause forcing x0=1
        //   Clause 1: (~x0) — unit clause forcing x0=0
        //   Expected: UNSAT
        //
        //   Unit-only: clause with lit0=x0, lit1=lit2=same var x0 so always sat…
        //   Better: use 2 clauses each with same var but different polarity
        //   Clause 0: (x0 OR x0 OR x0) → unit x0=1
        //   Clause 1: (~x0 OR ~x0 OR ~x0) → unit x0=0
        //   Contradiction → UNSAT
        // ==================================================================
        $display("");
        $display("--- S2: Trivial UNSAT ---");
        do_reset;

        // Clause 0: (x0 OR x0 OR x0) → forces x0=1
        do_load_clause(4'd0, make_clause(3'd0, 1'b0, 3'd0, 1'b0, 3'd0, 1'b0));
        // Clause 1: (~x0 OR ~x0 OR ~x0) → forces x0=0
        do_load_clause(4'd1, make_clause(3'd0, 1'b1, 3'd0, 1'b1, 3'd0, 1'b1));

        do_start_and_wait;

        assert_true(done,  "S2_done");
        assert_true(unsat, "S2_unsat");
        assert_true(!sat,  "S2_not_sat");

        // ==================================================================
        // SCENARIO 3: 3-clause unit propagation chain
        //   Clause 0: (x0 OR x0 OR x0)    → forces x0=1
        //   Clause 1: (~x0 OR x1 OR x1)   → x0 assigned true → x1 must be true (unit if x0=1 and x1 undef)
        //      Wait: (~x0 OR x1 OR x1): if x0=1 → ~x0=false → need x1=true → unit on x1
        //   Clause 2: (~x1 OR x2 OR x2)   → x1=1 → need x2=true → unit on x2
        //   Expected: SAT, x0=1, x1=1, x2=1
        // ==================================================================
        $display("");
        $display("--- S3: 3-clause chain unit propagation ---");
        do_reset;

        // Clause 0: (x0 OR x0 OR x0)
        do_load_clause(4'd0, make_clause(3'd0, 1'b0, 3'd0, 1'b0, 3'd0, 1'b0));
        // Clause 1: (~x0 OR x1 OR x1)
        do_load_clause(4'd1, make_clause(3'd0, 1'b1, 3'd1, 1'b0, 3'd1, 1'b0));
        // Clause 2: (~x1 OR x2 OR x2)
        do_load_clause(4'd2, make_clause(3'd1, 1'b1, 3'd2, 1'b0, 3'd2, 1'b0));

        do_start_and_wait;

        assert_true(done,        "S3_done");
        assert_true(sat,         "S3_sat");
        assert_true(!unsat,      "S3_not_unsat");
        assert_true(assign_out[0],"S3_x0_true");
        assert_true(assign_out[1],"S3_x1_true");
        assert_true(assign_out[2],"S3_x2_true");

        // ==================================================================
        // SCENARIO 4: 16-clause formula (decision + unit-prop + SAT)
        //
        //   Strategy: load 16 clauses. First 8 are backbone clauses.
        //   After one decision (x0=1 decided by FSM), unit propagation
        //   fires on clauses that have two ASSIGNED false lits.
        //
        //   Execution trace with FSM:
        //     DECIDE: x0=1 (lowest unassigned)  → PROPAGATE
        //     PROPAGATE: clause 0 = x0|x1|x2 satisfied (x0=1)
        //                clause 1 = ~x0|~x1|x2 → x0=1,x1 unassigned→ not unit
        //                No unit, no conflict → DECIDE
        //     DECIDE: x1=1 → PROPAGATE
        //     PROPAGATE: clause 1=~x0|~x1|x2 → ~x0=F,~x1=F,x2=undef → UNIT x2=1
        //                assign x2=1, stay in PROPAGATE
        //     PROPAGATE next: all 16 clauses check for SAT
        //                After x0=x1=x2=1 all clauses become SAT → done
        //
        //   Encoding:
        //   Clause 1 = ~x0|~x1|x2: lit0={v=0,neg=1}, lit1={v=1,neg=1}, lit2={v=2,neg=0}
        //   After x0=1 and x1=1: ~x0=F, ~x1=F, x2=undef → unit on x2 (force x2=1)
        //
        //   All 16 clauses are satisfied by x0=x1=x2=1 with x3..x7 free
        // ==================================================================
        $display("");
        $display("--- S4: 16-clause (decision + unit-prop cascade, SAT) ---");
        do_reset;

        // 8 backbone clauses all satisfied by x0=x1=x2=1
        do_load_clause(4'd0,  make_clause(3'd0,1'b0, 3'd1,1'b0, 3'd2,1'b0)); // x0|x1|x2
        do_load_clause(4'd1,  make_clause(3'd0,1'b1, 3'd1,1'b1, 3'd2,1'b0)); // ~x0|~x1|x2 → unit x2 when x0=1,x1=1
        do_load_clause(4'd2,  make_clause(3'd0,1'b0, 3'd1,1'b1, 3'd2,1'b0)); // x0|~x1|x2
        do_load_clause(4'd3,  make_clause(3'd0,1'b1, 3'd1,1'b0, 3'd2,1'b0)); // ~x0|x1|x2
        do_load_clause(4'd4,  make_clause(3'd0,1'b0, 3'd2,1'b0, 3'd1,1'b0)); // x0|x2|x1 (dup permutation)
        do_load_clause(4'd5,  make_clause(3'd1,1'b0, 3'd2,1'b0, 3'd0,1'b0)); // x1|x2|x0
        do_load_clause(4'd6,  make_clause(3'd2,1'b0, 3'd0,1'b0, 3'd1,1'b0)); // x2|x0|x1
        do_load_clause(4'd7,  make_clause(3'd0,1'b0, 3'd1,1'b0, 3'd2,1'b1)); // x0|x1|~x2
        // 8 redundant clauses (each uses at least one of x0,x1,x2 positive)
        do_load_clause(4'd8,  make_clause(3'd0,1'b0, 3'd3,1'b0, 3'd4,1'b0)); // x0|x3|x4
        do_load_clause(4'd9,  make_clause(3'd1,1'b0, 3'd4,1'b0, 3'd5,1'b0)); // x1|x4|x5
        do_load_clause(4'd10, make_clause(3'd2,1'b0, 3'd5,1'b0, 3'd6,1'b0)); // x2|x5|x6
        do_load_clause(4'd11, make_clause(3'd0,1'b0, 3'd5,1'b0, 3'd7,1'b0)); // x0|x5|x7
        do_load_clause(4'd12, make_clause(3'd1,1'b0, 3'd6,1'b0, 3'd7,1'b0)); // x1|x6|x7
        do_load_clause(4'd13, make_clause(3'd2,1'b0, 3'd3,1'b0, 3'd7,1'b0)); // x2|x3|x7
        do_load_clause(4'd14, make_clause(3'd0,1'b0, 3'd3,1'b0, 3'd6,1'b0)); // x0|x3|x6
        do_load_clause(4'd15, make_clause(3'd1,1'b0, 3'd3,1'b0, 3'd5,1'b0)); // x1|x3|x5

        do_start_and_wait;

        assert_true(done,  "S4_done");
        assert_true(sat,   "S4_sat");
        assert_true(!unsat,"S4_not_unsat");
        // x0,x1 decided, x2 unit-propagated to 1
        assert_true(assign_out[0], "S4_x0_true");
        assert_true(assign_out[1] | assign_out[2], "S4_x1orx2_true");

        // ==================================================================
        // Final report
        // ==================================================================
        $display("");
        $display("==========================================================");
        $display(" FINAL: %0d PASS  %0d FAIL  (target: 12+ PASS)", pass_cnt, fail_cnt);
        $display("==========================================================");
        if (fail_cnt == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    // Safety watchdog
    initial begin
        #100000;
        $display("WATCHDOG: simulation timed out");
        $finish;
    end

endmodule
`default_nettype wire
