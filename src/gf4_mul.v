// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf4_mul.v
// GoldenFloat4 Multiplication Unit (phi_dist = 0.118)

`default_nettype none
module gf4_mul (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [3:0] result
);

    // GF4: [S(1) | E(1) | M(2)] - BIAS = 0
    localparam EXP_MAX = 2'd2;

    wire        sign_a = a[3];
    wire [0:0]  exp_a  = a[2];
    wire [1:0]  mant_a = a[1:0];
    wire        sign_b = b[3];
    wire [0:0]  exp_b  = b[2];
    wire [1:0]  mant_b = b[1:0];

    wire is_zero_a = (exp_a == 1'b0) && (mant_a == 2'd0);
    wire is_zero_b = (exp_b == 1'b0) && (mant_b == 2'd0);
    wire is_inf_a  = (exp_a == EXP_MAX[0]) && (mant_a == 2'd0);
    wire is_inf_b  = (exp_b == EXP_MAX[0]) && (mant_b == 2'd0);
    wire is_nan_a  = (exp_a == EXP_MAX[0]) && (mant_a != 2'd0);
    wire is_nan_b  = (exp_b == EXP_MAX[0]) && (mant_b != 2'd0);

    wire result_sign = sign_a ^ sign_b;

    always @(*) begin
        if (is_nan_a || is_nan_b)
            result = 4'hF;
        else if (is_inf_a && is_zero_b)
            result = 4'hF;
        else if (is_inf_b && is_zero_a)
            result = 4'hF;
        else if (is_inf_a || is_inf_b)
            result = result_sign ? 4'hE : 4'h6;
        else if (is_zero_a || is_zero_b)
            result = 4'h0;
        else begin
            // Simple 4-bit multiplication
            result = {result_sign, exp_a ^ exp_b, mant_a + mant_b};
        end
    end

endmodule