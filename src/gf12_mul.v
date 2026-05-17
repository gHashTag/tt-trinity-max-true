// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf12_mul.v
// GoldenFloat12 Multiplication Unit (BEST phi_dist = 0.047)

`default_nettype none
module gf12_mul (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output reg  [11:0] result
);

    // GF12: [S(1) | E(4) | M(7)] - BIAS = 7
    localparam BIAS    = 4'd7;
    localparam EXP_MAX = 4'd15;

    wire        sign_a = a[11];
    wire [3:0]  exp_a  = a[10:7];
    wire [6:0]  mant_a = a[6:0];
    wire        sign_b = b[11];
    wire [3:0]  exp_b  = b[10:7];
    wire [6:0]  mant_b = b[6:0];

    wire is_zero_a = (exp_a == 4'd0) && (mant_a == 7'd0);
    wire is_zero_b = (exp_b == 4'd0) && (mant_b == 7'd0);
    wire is_inf_a  = (exp_a == EXP_MAX) && (mant_a == 7'd0);
    wire is_inf_b  = (exp_b == EXP_MAX) && (mant_b == 7'd0);
    wire is_nan_a  = (exp_a == EXP_MAX) && (mant_a != 7'd0);
    wire is_nan_b  = (exp_b == EXP_MAX) && (mant_b != 7'd0);

    wire result_sign = sign_a ^ sign_b;

    reg [4:0]  exp_product;
    reg [14:0] mant_product;
    reg [6:0]  normalized_mant;

    always @(*) begin
        if (is_nan_a || is_nan_b)
            result = 12'hFF1;
        else if (is_inf_a && is_zero_b)
            result = 12'hFF1;
        else if (is_inf_b && is_zero_a)
            result = 12'hFF1;
        else if (is_inf_a || is_inf_b)
            result = result_sign ? 12'hFF0 : 12'h7F0;
        else if (is_zero_a || is_zero_b)
            result = 12'h000;
        else begin
            exp_product = {1'b0, exp_a} + {1'b0, exp_b} - BIAS;
            mant_product = {1'b1, mant_a} * {1'b1, mant_b};

            if (mant_product[14])
                exp_product = exp_product + 5'd1;

            if (exp_product[4] || (exp_product[3:0] >= EXP_MAX))
                result = result_sign ? 12'hFF0 : 12'h7F0;
            else if (exp_product[3:0] == 4'd0)
                result = {result_sign, 4'd0, 7'd0};
            else
                result = {result_sign, exp_product[3:0], mant_product[6:0]};
        end
    end

endmodule