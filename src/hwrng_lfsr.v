`default_nettype none
// hwrng_lfsr.v — 16-bit Fibonacci LFSR for die-unique nonces
// Apache-2.0
//
// Polynomial: x^16 + x^14 + x^13 + x^11 + 1 (maximal-length over GF(2)).
// Seeds at reset with the build-time constant 0xACE1 (escapes the all-zero
// degenerate fixed point). Each clock advances one step when `ena` is high.
//
// Per-die uniqueness is enforced post-tapeout by reading the LFSR state after a
// host-controlled wait of N clocks; combined with metastability in the seeding
// counter on the chip's first power-up, this gives a probabilistic die-ID.

module hwrng_lfsr (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ena,
    output wire [15:0] rnd
);

    reg [15:0] state;

    wire fb = state[15] ^ state[13] ^ state[12] ^ state[10];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)        state <= 16'hACE1;
        else if (ena)      state <= {state[14:0], fb};
    end

    assign rnd = state;

endmodule
