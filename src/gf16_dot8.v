// gf16_dot8.v — 8-lane GF16 dot-product (L-S20 dot8 expansion)
// Architecture: two gf16_dot4 instances in parallel + one gf16_add to combine.
// This doubles MAC throughput (2× TOPS/tile) while preserving the canonical
// dot4 primitive unchanged (constitutional: 0x47C0 test vector unaffected).
//
// dot8(a[0..7], b[0..7]) = dot4(a[0..3], b[0..3]) + dot4(a[4..7], b[4..7])
//
// EPIC: gHashTag/trinity-fpga#51
// DOI: 10.5281/zenodo.19227877
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module gf16_dot8 (
    // Lower 4 lanes (lanes 0..3) — maps to existing dot4 operand positions
    input  wire [15:0] a0, a1, a2, a3,
    input  wire [15:0] b0, b1, b2, b3,
    // Upper 4 lanes (lanes 4..7)
    input  wire [15:0] a4, a5, a6, a7,
    input  wire [15:0] b4, b5, b6, b7,
    // Sum of both dot4s
    output wire [15:0] result
);

    wire [15:0] dot_lo, dot_hi;

    // Lower half — identical to existing gf16_dot4 with same operand naming
    gf16_dot4 u_dot_lo (
        .a0(a0), .a1(a1), .a2(a2), .a3(a3),
        .b0(b0), .b1(b1), .b2(b2), .b3(b3),
        .result(dot_lo)
    );

    // Upper half — lanes 4..7
    gf16_dot4 u_dot_hi (
        .a0(a4), .a1(a5), .a2(a6), .a3(a7),
        .b0(b4), .b1(b5), .b2(b6), .b3(b7),
        .result(dot_hi)
    );

    // Accumulate both halves in GF16 arithmetic
    gf16_add u_acc (
        .a(dot_lo),
        .b(dot_hi),
        .result(result)
    );

endmodule
