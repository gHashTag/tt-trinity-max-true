// tb_tri_token_accumulator.v — Self-checking testbench for tri_token_accumulator.
// Verilog-2005. Apache-2.0.
//
// Tests:
//  1. Reset: token_balance == 0, overflow_flag == 0.
//  2. 5 pulses with reward=1  → balance == 5.
//  3. 5 pulses with reward=4  → balance == 25.
//  4. Saturation: drive balance to 65535 via many pulses → overflow_flag, balance stays.
//  5. No accumulation when overflow_flag is set.

`timescale 1ns/1ps
`default_nettype none

module tb_tri_token_accumulator;

    // ------------------------------------------------------------------
    // DUT signals
    // ------------------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg        attest_pulse;
    reg  [2:0] reward_amount;
    wire [15:0] token_balance;
    wire        overflow_flag;

    // ------------------------------------------------------------------
    // DUT instantiation
    // ------------------------------------------------------------------
    tri_token_accumulator #(
        .WIDTH      (16),
        .REWARD_BITS(3)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .attest_pulse (attest_pulse),
        .reward_amount(reward_amount),
        .token_balance(token_balance),
        .overflow_flag(overflow_flag)
    );

    // ------------------------------------------------------------------
    // Clock: 10 ns period
    // ------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------
    // Helper task: send N attest pulses with given reward
    // ------------------------------------------------------------------
    integer i;
    task send_pulses;
        input integer n;
        input [2:0] rwd;
        begin
            reward_amount = rwd;
            for (i = 0; i < n; i = i + 1) begin
                attest_pulse = 1'b1;
                @(posedge clk); #1;
                attest_pulse = 1'b0;
                @(posedge clk); #1;
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Test counter
    // ------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    task check;
        input [15:0] got;
        input [15:0] exp;
        input [127:0] label;
        begin
            if (got === exp) begin
                $display("PASS  %0s: got=%0d (0x%04X)", label, got, got);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL  %0s: expected=%0d (0x%04X) got=%0d (0x%04X)",
                         label, exp, exp, got, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_bit;
        input got;
        input exp;
        input [127:0] label;
        begin
            if (got === exp) begin
                $display("PASS  %0s: got=%0b", label, got);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL  %0s: expected=%0b got=%0b", label, exp, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Main stimulus
    // ------------------------------------------------------------------
    initial begin
        pass_count   = 0;
        fail_count   = 0;
        attest_pulse = 1'b0;
        reward_amount = 3'd0;

        // ---- Test 1: Reset ----
        rst_n = 1'b0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        check(token_balance, 16'd0, "T1_reset_balance");
        check_bit(overflow_flag, 1'b0, "T1_reset_overflow");
        rst_n = 1'b1;
        @(posedge clk); #1;

        // ---- Test 2: 5 pulses reward=1 → balance=5 ----
        send_pulses(5, 3'd1);
        check(token_balance, 16'd5, "T2_5pulses_rwd1");
        check_bit(overflow_flag, 1'b0, "T2_no_overflow");

        // ---- Test 3: 5 more pulses reward=4 → balance=5+20=25 ----
        send_pulses(5, 3'd4);
        check(token_balance, 16'd25, "T3_5pulses_rwd4");

        // ---- Test 4: Saturate to 65535 ----
        // We need 65535-25 = 65510 more tokens.
        // Send 65510/7 = 9358 pulses of reward=7, then fill remainder.
        // 9358*7 = 65506 → balance=25+65506=65531; need 4 more.
        send_pulses(9358, 3'd7);
        check(token_balance, 16'd65531, "T4_pre_sat");
        // 4 more tokens with reward=4 → 65531+4=65535 (MAX)
        send_pulses(1, 3'd4);
        check(token_balance, 16'd65535, "T4_saturated");
        check_bit(overflow_flag, 1'b1, "T4_overflow_flag");

        // ---- Test 5: No accumulation after saturation ----
        attest_pulse  = 1'b1;
        reward_amount = 3'd7;
        @(posedge clk); #1;
        attest_pulse = 1'b0;
        @(posedge clk); #1;
        check(token_balance, 16'd65535, "T5_no_accum_when_sat");
        check_bit(overflow_flag, 1'b1, "T5_overflow_still");

        // ---- Test 6: Reset clears everything ----
        rst_n = 1'b0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        check(token_balance, 16'd0, "T6_reset_clears_balance");
        check_bit(overflow_flag, 1'b0, "T6_reset_clears_overflow");
        rst_n = 1'b1;

        // ---- Summary ----
        $display("----------------------------------------");
        $display("RESULT: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $finish;
    end

    // Timeout guard
    initial begin
        #5000000;
        $display("TIMEOUT - simulation exceeded limit");
        $finish;
    end

endmodule
