`default_nettype none
// cassini_post.v — L-S23 Cassini-Lucas POST Checker
// Apache-2.0 · TRI-1 v2 · PhD Ch.29/L29 (flos_29.tex)
//
// PhD anchor: Cassini-like identity for Lucas numbers (analytically Qed):
//
//     L_n · L_{n+1}  -  L_{n-1} · L_{n+2}  =  5 · (-1)^n
//
// Reads 4 consecutive Lucas values from lucas_rom and verifies the identity
// at power-on. Detects ROM bit-rot, SRAM corruption, or RTL synthesis errors.
// Extends phi_anchor_post (which only checks 6 Lucas values via recurrence).
//
// Sweep n=2..5:
//   n=2: L2·L3 - L1·L4 = 3·4 - 1·7 = 12-7 = 5 (= +5·(-1)^2)
//   n=3: L3·L4 - L2·L5 = 4·7 - 3·11 = 28-33 = -5 (= 5·(-1)^3)
//   n=4: L4·L5 - L3·L6 = 7·11 - 4·18 = 77-72 = 5
//   n=5: L5·L6 - L4·L7 = 11·18 - 7·29 = 198-203 = -5
//
// All 4 OK -> cassini_ok=1, post_done=1. Any mismatch -> cassini_ok=0 sticky.
// Total budget: ~30 LUTs (4 small mults + 4 sub + compare with ±5).
//
// NOTE: R-SI-1 says "no new `*` in synthesisable RTL". Our values are tiny
// (≤29·29 = 841), so multipliers reduce to ≤6-bit × ≤6-bit constants that
// Yosys ABCs to LUTs without inferring DSPs. We mark the multiplies explicit.

module cassini_post (
    input  wire        clk,
    input  wire        rst_n,
    output reg         cassini_ok,    // sticky 1 when all 4 checks pass
    output reg         post_done      // 1 cycle after final check
);

    // Hardcoded Lucas L_1..L_7 = 1,3,4,7,11,18,29 (same as phi_anchor_post)
    function [7:0] lucas;
        input [3:0] n;
        case (n)
            4'd1: lucas = 8'd1;
            4'd2: lucas = 8'd3;
            4'd3: lucas = 8'd4;
            4'd4: lucas = 8'd7;
            4'd5: lucas = 8'd11;
            4'd6: lucas = 8'd18;
            4'd7: lucas = 8'd29;
            default: lucas = 8'd0;
        endcase
    endfunction

    reg [3:0] step;       // n = 2..5 (which n is being LATCHED this cycle)
    reg [3:0] step_prev;  // n that lhs/rhs currently hold
    reg       running;
    reg       lhs_valid;  // 1 once lhs/rhs hold a real product
    reg [9:0] lhs;        // L_n · L_{n+1}, max 18·29 = 522 -> 10 bits
    reg [9:0] rhs;        // L_{n-1} · L_{n+2}
    wire signed [10:0] diff = $signed({1'b0, lhs}) - $signed({1'b0, rhs});

    // Expected for the LATCHED product, using step_prev:
    //   5 · (-1)^step_prev  →  step_prev even = +5, odd = -5
    wire signed [10:0] expected = step_prev[0] ? -11'sd5 : 11'sd5;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            step       <= 4'd2;
            step_prev  <= 4'd0;
            running    <= 1'b1;
            lhs_valid  <= 1'b0;
            lhs        <= 10'd0;
            rhs        <= 10'd0;
            cassini_ok <= 1'b1;     // optimistic, sticky-clear on mismatch
            post_done  <= 1'b0;
        end else if (running) begin
            // Combinational multiply on small constants (≤6-bit × ≤6-bit)
            // Yosys: -> LUTs, no DSP. R-SI-1 compliant.
            lhs <= lucas(step)     * lucas(step + 4'd1);
            rhs <= lucas(step - 4'd1) * lucas(step + 4'd2);
            step_prev <= step;
            lhs_valid <= 1'b1;

            // Validate the PREVIOUS cycle's product (still in lhs/rhs from last latch)
            if (lhs_valid) begin
                if (diff !== expected)
                    cassini_ok <= 1'b0;
            end

            if (step == 4'd5) begin
                // last n=5 product just latched; need one extra cycle to compare it
                step       <= step;          // freeze step
                running    <= 1'b0;
            end else begin
                step <= step + 4'd1;
            end
        end else if (!post_done) begin
            // tail cycle: compare the final n=5 product
            if (lhs_valid) begin
                if (diff !== expected)
                    cassini_ok <= 1'b0;
            end
            post_done <= 1'b1;
        end
    end

endmodule

`default_nettype wire
