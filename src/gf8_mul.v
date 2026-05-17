// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf8_mul.v
// GoldenFloat8 Multiplication Unit (phi_dist = 0.132)

`default_nettype none
module gf8_mul (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output reg  [7:0] result
);

    // GF8: [S(1) | E(3) | M(4)] - BIAS = 3
    localparam BIAS    = 3'd3;
    localparam EXP_MAX = 3'd7;

    wire        sign_a = a[7];
    wire [2:0]  exp_a  = a[6:4];
    wire [3:0]  mant_a = a[3:0];
    wire        sign_b = b[7];
    wire [2:0]  exp_b  = b[6:4];
    wire [3:0]  mant_b = b[3:0];

    wire is_zero_a = (exp_a == 3'd0) && (mant_a == 4'd0);
    wire is_zero_b = (exp_b == 3'd0) && (mant_b == 4'd0);
    wire is_inf_a  = (exp_a == EXP_MAX) && (mant_a == 4'd0);
    wire is_inf_b  = (exp_b == EXP_MAX) && (mant_b == 4'd0);
    wire is_nan_a  = (exp_a == EXP_MAX) && (mant_a != 4'd0);
    wire is_nan_b  = (exp_b == EXP_MAX) && (mant_b != 4'd0);

    wire result_sign = sign_a ^ sign_b;

    reg [3:0]  exp_product;
    reg [8:0]  mant_product;
    reg [3:0]  normalized_mant;

    always @(*) begin
        if (is_nan_a || is_nan_b)
            result = 8'hF1;
        else if (is_inf_a && is_zero_b)
            result = 8'hF1;
        else if (is_inf_b && is_zero_a)
            result = 8'hF1;
        else if (is_inf_a || is_inf_b)
            result = result_sign ? 8'hF0 : 8'h70;
        else if (is_zero_a || is_zero_b)
            result = 8'h00;
        else begin
            exp_product = exp_a + exp_b - BIAS;
            mant_product = {1'b1, mant_a} * {1'b1, mant_b};

            if (mant_product[8])
                exp_product = exp_product + 4'd1;

            if (exp_product[3] || (exp_product[2:0] >= EXP_MAX))
                result = result_sign ? 8'hF0 : 8'h70;
            else if (exp_product[2:0] == 3'd0)
                result = {result_sign, 3'd0, 4'd0};
            else
                result = {result_sign, exp_product[2:0], mant_product[3:0]};
        end
    end

endmodule