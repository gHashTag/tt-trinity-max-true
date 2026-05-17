// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf4_add.v
// GoldenFloat4 Addition Unit - Extreme Compression
// Layout: [S(1) | E(1) | M(2)] - BIAS = 0
// φ-distance: 0.118 (not optimal, but minimal bits)

`default_nettype none
module gf4_add (
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [3:0] result
);

    localparam BIAS    = 1'd0;
    localparam EXP_MAX = 1'd1;

    wire        sign_a = a[3];
    wire        exp_a  = a[2];
    wire [1:0]  mant_a = a[1:0];
    wire        sign_b = b[3];
    wire        exp_b  = b[2];
    wire [1:0]  mant_b = b[1:0];

    wire is_zero_a    = (exp_a == 1'd0) && (mant_a == 2'd0);
    wire is_zero_b    = (exp_b == 1'd0) && (mant_b == 2'd0);
    wire is_special_a = (exp_a == EXP_MAX);
    wire is_special_b = (exp_b == EXP_MAX);
    wire is_inf_a     = is_special_a && (mant_a == 2'd0);
    wire is_inf_b     = is_special_b && (mant_b == 2'd0);
    wire is_nan_a     = is_special_a && (mant_a != 2'd0);
    wire is_nan_b     = is_special_b && (mant_b != 2'd0);

    wire a_larger = (exp_a > exp_b) || ((exp_a == exp_b) && (mant_a >= mant_b));

    reg [1:0]  big_exp, result_exp;
    reg [2:0]  big_fm, small_fm;
    reg [3:0]  sum_m;
    reg        big_sign, small_sign, result_sign;
    reg [2:0]  norm;
    reg        cancel;

    always @(*) begin
        cancel = 0;
        result_exp = 0;
        norm = 0;
        result_sign = 0;
        big_exp = 0;
        big_fm = 0;
        big_sign = 0;
        small_fm = 0;
        small_sign = 0;
        sum_m = 0;

        if (is_nan_a || is_nan_b)
            result = 4'hE;  // NaN pattern for GF4
        else if (is_inf_a && is_inf_b && (sign_a != sign_b))
            result = 4'hE;  // NaN
        else if (is_inf_a)
            result = sign_a ? 4'hC : 4'h4;  // Inf
        else if (is_inf_b)
            result = sign_b ? 4'hC : 4'h4;  // Inf
        else if (is_zero_a && is_zero_b)
            result = 4'h0;  // Zero
        else if (is_zero_a)
            result = b;
        else if (is_zero_b)
            result = a;
        else begin
            if (a_larger) begin
                big_exp    = exp_a;
                big_fm     = {1'b1, mant_a};
                big_sign   = sign_a;
                small_fm   = {1'b1, mant_b};
                small_sign = sign_b;
            end else begin
                big_exp    = exp_b;
                big_fm     = {1'b1, mant_b};
                big_sign   = sign_b;
                small_fm   = {1'b1, mant_a};
                small_sign = sign_a;
            end

            result_exp = big_exp;

            if (big_sign == small_sign) begin
                sum_m = {1'b0, big_fm} + {1'b0, small_fm};
                result_sign = big_sign;
            end else begin
                sum_m = {1'b0, big_fm} - {1'b0, small_fm};
                result_sign = big_sign;
                if (sum_m == 4'd0)
                    cancel = 1;
            end

            if (!cancel) begin
                if (sum_m[3]) begin
                    norm = sum_m[2:0];
                end else if (sum_m[2]) begin
                    norm = {sum_m[2:1], 1'b0};
                    result_exp = result_exp - 1'b1;
                end else if (sum_m[1]) begin
                    norm = {sum_m[1], 2'b00};
                    result_exp = result_exp - 2'b10;
                end else if (sum_m[0]) begin
                    norm = {1'b1, 3'b000};
                    result_exp = result_exp - 2'b11;
                end else begin
                    norm = 3'b0;
                    result_exp = result_exp - 2'b10;
                end

                if (result_exp[1])
                    result = result_sign ? 4'h8 : 4'h0;  // Underflow
                else if (result_exp[0] >= EXP_MAX)
                    result = result_sign ? 4'hC : 4'h4;  // Overflow to Inf
                else
                    result = {result_sign, result_exp, norm[1:0]};
            end else begin
                result = 4'h0;  // Cancel to zero
            end
        end
    end

endmodule