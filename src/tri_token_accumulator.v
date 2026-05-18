`default_nettype none
// tri_token_accumulator.v — $TRI hardware token accumulator for DePIN proof-of-compute.
// Apache-2.0
//
// WIDTH=16 → 64K tokens max per session (saturation).
// REWARD_BITS=3 → reward_amount[2:0] (0-7 tokens per attest pulse).
// For Gamma (8x4 die, largest): reward hard-wired to 3'd4 by top-level.
//
// R-SI-1: zero standalone `*` operators — uses only `+` and bit-selects.
// Verilog-2005 (`default_nettype none).
// Reset-safe: token_balance==0 and overflow_flag==0 under !rst_n.

module tri_token_accumulator #(
    parameter WIDTH       = 16,   // token counter width (max 65535)
    parameter REWARD_BITS = 3     // reward field width (max value = 2^REWARD_BITS - 1)
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     attest_pulse,      // 1-cycle pulse: valid job done
    input  wire [REWARD_BITS-1:0]   reward_amount,     // tokens to add per pulse
    output reg  [WIDTH-1:0]         token_balance,     // accumulated token count
    output wire                     overflow_flag      // all bits set = saturated at MAX
);

    // Overflow when all WIDTH bits are 1 (token_balance == 2^WIDTH - 1).
    // R-SI-1: &token_balance is a reduction — no standalone * used.
    assign overflow_flag = &token_balance;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            token_balance <= {WIDTH{1'b0}};
        end else begin
            if (attest_pulse && !overflow_flag) begin
                // Saturating add: reward_amount is zero-extended to WIDTH bits.
                // R-SI-1: uses only + operator; no standalone *.
                token_balance <= token_balance + {{(WIDTH-REWARD_BITS){1'b0}}, reward_amount};
            end
        end
    end

endmodule
