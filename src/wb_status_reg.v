`default_nettype none
// wb_status_reg.v — Trinity Wishbone-lite status register
// Apache-2.0
//
// Aggregates POST results from the φ-anchor, Lucas chain, and VSA matmul
// modules into a single read-only status byte exposed through uio_out.
//
// Layout (status_byte[7:0]):
//   bit 0: phi_ok        — φ²+φ⁻²=3 proven on silicon at POST
//   bit 1: lucas_ok      — Lucas ROM addressable + chain consistent
//   bit 2: matmul_ok     — 8×8 ternary XOR-popcount matmul completed
//   bit 3: post_done     — POST sequencer reached completion
//   bit 4: rcpt_valid    — most recent G4 RECEIPT latched
//   bit 5: hwrng_nonzero — LFSR has cycled at least once (always 1 post-reset+enable)
//   bit 6: rsvd          — 0
//   bit 7: alive         — toggles each POST_DONE; observable liveness bit

module wb_status_reg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       phi_ok,
    input  wire       lucas_ok,
    input  wire       matmul_ok,
    input  wire       post_done,
    input  wire       rcpt_valid,
    input  wire       hwrng_nonzero,
    output wire [7:0] status_byte
);

    reg alive;
    reg post_done_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alive       <= 1'b0;
            post_done_d <= 1'b0;
        end else begin
            post_done_d <= post_done;
            if (post_done && !post_done_d)
                alive <= ~alive;
        end
    end

    assign status_byte = {
        alive,            // [7]
        1'b0,             // [6] rsvd
        hwrng_nonzero,    // [5]
        rcpt_valid,       // [4]
        post_done,        // [3]
        matmul_ok,        // [2]
        lucas_ok,         // [1]
        phi_ok            // [0]
    };

endmodule
