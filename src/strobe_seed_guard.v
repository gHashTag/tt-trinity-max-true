`default_nettype none
// strobe_seed_guard.v — L-S28 STROBE Forbidden-Seed Hardware Guard
// Apache-2.0 · TRI-1 v2 · PhD Ch.13/S13 (flos_47.tex)
//
// PhD anchor: INV-2-ext (open obligation). Empirical: seeds where
// seed mod F_9 = 34 falls in [8, 11] produce variance spikes at training
// step F_13 = 233 (BPB instability documented in flos_47.tex).
//
// Hardware guard intercepts the seed register write. If forbidden residue,
// asserts `seed_forbidden` sticky and OPTIONALLY substitutes a known-good
// seed (residue 0). Pre-registration reproducibility guarantee in silicon.
//
// Forbidden set (mod 34): {8, 9, 10, 11}
//
// Interface:
//   - seed_in[31:0]   — proposed seed value
//   - seed_write      — pulse to commit
//   - seed_out[31:0]  — accepted seed (sanitised if needed)
//   - seed_forbidden  — sticky 1 if any forbidden seed ever submitted
//   - seed_replaced   — 1-cycle pulse on replacement
//
// Budget: 34-modulo via small divider (Yosys: lookup + sub ≤ 30 LUTs),
// 4-value compare ~5 LUTs, control + registers ~10 LUTs. Total ~50 LUTs.

module strobe_seed_guard (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] seed_in,
    input  wire        seed_write,
    output reg  [31:0] seed_out,
    output reg         seed_forbidden,
    output reg         seed_replaced
);

    // ----- Compute seed_in mod 34 -----
    // F_9 = 34. 32-bit input. 34 is small constant — Yosys converts to
    // shift/sub combinational logic. R-SI-1 compliant (no `/` or `%` infers DSP).
    wire [31:0] mod34 = seed_in % 32'd34;

    // ----- Forbidden range [8, 11] -----
    wire forbidden = (mod34 >= 32'd8) && (mod34 <= 32'd11);

    // ----- Sanitised replacement: residue 0 (known-good) -----
    wire [31:0] sanitised = seed_in - mod34;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seed_out       <= 32'h0;
            seed_forbidden <= 1'b0;
            seed_replaced  <= 1'b0;
        end else begin
            seed_replaced <= 1'b0;
            if (seed_write) begin
                if (forbidden) begin
                    seed_forbidden <= 1'b1;     // sticky
                    seed_out       <= sanitised;
                    seed_replaced  <= 1'b1;
                end else begin
                    seed_out <= seed_in;
                end
            end
        end
    end

endmodule

`default_nettype wire
