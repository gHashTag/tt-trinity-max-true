`default_nettype none
// nca_entropy_monitor.v — L-S24 NCA Entropy Band Monitor
// Apache-2.0 · TRI-1 v2 · PhD Ch.16/S16 (flos_50.tex), INV-4 (12 Qed)
//
// PhD anchor:
//   - nca_grid_trinity_structure Qed: NCA grid = 81 = 3^4
//   - k9_max_entropy_in_band     Qed: H ≤ ln(9) ≈ 2.197 < 2.8 nats
//   - INV-4 NcaEntropyBand       Qed: H ∈ [1.5, 2.8] nats
//
// Hardware: counts non-zero trits in 81-cell NCA window. Uses the trit population
// as a proxy for entropy (H_proxy = popcount(nonzero) / 81). Real H is ln of
// effective alphabet, but for a {-1,0,+1} cell the trinary-zero rate maps
// monotonically to entropy. Two LUT-based thresholds map popcount -> band check.
//
// Mapping (from INV-4): activation rate p_active = popcount/81 ∈ [0.382, 0.999]
// corresponds to H ∈ [1.5, 2.8] nats. We pre-compute the integer popcount
// equivalents: popcount_low = ceil(0.382·81) = 31, popcount_high = 80.
//
// Interface:
//   - trits_in[161:0]   — 81 trits packed as 2 bits/cell (00=0, 01=+1, 10=-1, 11=inv)
//   - sample            — assert 1 cycle to latch and check
//   - entropy_violation — pulse 1 if popcount out of [31, 80]
//   - in_band           — combinational: current sample is in band
//
// Budget: 81-trit popcount ~30 LUT (3-bit add tree), 2 comparators ~4 LUT,
// FF storage ~16 LUT, control ~10 LUT. Total ~60 LUT.

module nca_entropy_monitor #(
    parameter integer LOW_THRESH  = 7'd31,   // ceil(0.382 * 81)
    parameter integer HIGH_THRESH = 7'd80    // 81 - 1 (saturated)
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [161:0] trits_in,            // 81 cells × 2 bits
    input  wire         sample,
    output reg          entropy_violation,   // 1-cycle pulse
    output wire         in_band,             // combinational
    output reg  [6:0]   last_popcount        // diagnostic
);

    // ---- 81-trit nonzero population count ----
    // For each 2-bit cell c: nonzero = (c[1] | c[0]) — both 00=zero, all else nonzero
    wire [80:0] is_nonzero;
    genvar i;
    generate
        for (i = 0; i < 81; i = i + 1) begin : cell_gen
            assign is_nonzero[i] = trits_in[2*i] | trits_in[2*i+1];
        end
    endgenerate

    // Adder tree (synthesised as 3-bit + 4-bit + ... + 7-bit accumulator)
    integer k;
    reg [6:0] popcount_comb;
    always @* begin
        popcount_comb = 7'd0;
        for (k = 0; k < 81; k = k + 1)
            popcount_comb = popcount_comb + {6'd0, is_nonzero[k]};
    end

    // Threshold checks (combinational + registered)
    wire below = (popcount_comb < LOW_THRESH);
    wire above = (popcount_comb > HIGH_THRESH);
    assign in_band = ~(below | above);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            entropy_violation <= 1'b0;
            last_popcount     <= 7'd0;
        end else begin
            entropy_violation <= 1'b0;
            if (sample) begin
                last_popcount <= popcount_comb;
                if (below | above)
                    entropy_violation <= 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
