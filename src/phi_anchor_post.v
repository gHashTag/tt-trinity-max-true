`default_nettype none
// phi_anchor_post.v — Trinity φ-anchor Power-On Self-Test
// Apache-2.0
//
// PhD anchor: φ² + φ⁻² = 3, derivable from φ = (1+√5)/2.
// We verify the equivalent INTEGER identity on the discrete Lucas chain:
//
//   L₂ = 3   (= φ² + φ⁻², by Binet's formula on Lucas numbers)
//   L_{n+1} = L_n + L_{n-1}  with L₁=1, L₂=3
//
// Strategy (silicon-friendly, 0 multipliers):
// On reset release we step a small counter through n=2..7 and check that the
// discrete recurrence produces (3, 4, 7, 11, 18, 29). All six matches latch
// `phi_ok = 1`. Any mismatch latches `phi_ok = 0` permanently (sticky-low POST).
//
// Total budget: ~120 gates (6 small comparators + 8-bit Lucas registers + FSM).

module phi_anchor_post (
    input  wire       clk,
    input  wire       rst_n,
    output reg        phi_ok,       // sticky 1 when chain proven
    output reg        post_done     // 1 cycle after final check
);

    // Lucas chain registers (8-bit fits up to L_11 = 199)
    reg [7:0] l_prev;   // L_{n-1}
    reg [7:0] l_curr;   // L_n
    reg [3:0] step;     // 0..6
    reg       running;

    // Expected values for n = 2..7
    function [7:0] lucas_expect;
        input [3:0] n;
        case (n)
            4'd2: lucas_expect = 8'd3;
            4'd3: lucas_expect = 8'd4;
            4'd4: lucas_expect = 8'd7;
            4'd5: lucas_expect = 8'd11;
            4'd6: lucas_expect = 8'd18;
            4'd7: lucas_expect = 8'd29;
            default: lucas_expect = 8'd0;
        endcase
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Seed: L₁ = 1, L₂ = 3
            l_prev    <= 8'd1;
            l_curr    <= 8'd3;
            step      <= 4'd2;     // currently holding L_2
            running   <= 1'b1;
            phi_ok    <= 1'b1;     // optimistic; cleared on first mismatch
            post_done <= 1'b0;
        end else if (running) begin
            // Verify l_curr matches expectation for current step
            if (l_curr !== lucas_expect(step)) begin
                phi_ok <= 1'b0;
            end
            if (step == 4'd7) begin
                running   <= 1'b0;
                post_done <= 1'b1;
            end else begin
                // Advance: L_{n+1} = L_n + L_{n-1}
                l_prev <= l_curr;
                l_curr <= l_curr + l_prev;
                step   <= step + 4'd1;
            end
        end
    end

endmodule
