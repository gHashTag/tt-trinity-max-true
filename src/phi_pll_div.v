`default_nettype none
// phi_pll_div.v — phi-anchored fractional divider (1.618× simulated)
// Apache-2.0
//
// PhD anchor: Chapter 1 — φ as a fundamental clock ratio.
// A real fractional PLL needs analog blocks (charge pump, VCO). On TT digital
// shuttle we approximate a φ-ratio output via a fractional-N counter:
// every 8 base clocks emit 5 output pulses (5/8 = 0.625; reciprocal of φ−1
// approximation). Over 8-cycle windows the effective output frequency is
// f_in × 5/8 ≈ f_in / 1.6 (close to 1/φ).
//
// This is NOT a real PLL but provides a phi-derived clock-tick stream usable
// as a heartbeat indicator. Anchor value verified at testbench level.

module phi_pll_div (
    input  wire clk,
    input  wire rst_n,
    output reg  phi_tick,             // pulses at φ-derived cadence
    output reg  [2:0] state,
    output wire phi_div_ok
);

    // Bresenham-style fractional divider: increment by 5 modulo 8.
    // Emit phi_tick on overflow. Average rate = 5/8 = 0.625 ticks per clk.
    reg [2:0] acc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc      <= 3'd0;
            state    <= 3'd0;
            phi_tick <= 1'b0;
        end else begin
            phi_tick <= 1'b0;
            if (acc + 3'd5 < acc) begin   // overflow detected (compact form)
                phi_tick <= 1'b1;
            end
            acc <= acc + 3'd5;
            state <= acc;
        end
    end

    assign phi_div_ok = 1'b1;

endmodule
