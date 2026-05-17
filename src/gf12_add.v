// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf12_add.v
// GoldenFloat12 Addition Unit - BEST phi approximation
// Layout: [S(1) | E(4) | M(7)] - BIAS = 7
// phi_distance: 0.047 (BEST in GF family!)

`default_nettype none
module gf12_add (
    input  wire [11:0] a,
    input  wire [11:0] b,
    output reg  [11:0] result
);

    localparam BIAS    = 3'd7;
    localparam EXP_MAX = 4'd15;

    wire        sign_a = a[11];
    wire [3:0]  exp_a  = a[10:7];
    wire [6:0]  mant_a = a[6:0];
    wire        sign_b = b[11];
    wire [3:0]  exp_b  = b[10:7];
    wire [6:0]  mant_b = b[6:0];

    wire is_zero_a    = (exp_a == 4'd0) && (mant_a == 7'd0);
    wire is_zero_b    = (exp_b == 4'd0) && (mant_b == 7'd0);
    wire is_special_a = (exp_a == EXP_MAX);
    wire is_special_b = (exp_b == EXP_MAX);
    wire is_inf_a     = is_special_a && (mant_a == 7'd0);
    wire is_inf_b     = is_special_b && (mant_b == 7'd0);
    wire is_nan_a     = is_special_a && (mant_a != 7'd0);
    wire is_nan_b     = is_special_b && (mant_b != 7'd0);

    wire a_larger = (exp_a > exp_b) || ((exp_a == exp_b) && (mant_a >= mant_b));

    reg [3:0]  big_exp, shift, result_exp;
    reg [7:0]  big_fm, small_fm;
    reg [8:0]  sum_m;
    reg        big_sign, small_sign, result_sign;
    reg [6:0]  norm;
    reg        g_bit, r_bit, s_bit;
    reg [7:0]  rounded;
    reg [3:0]  final_exp;
    reg [6:0]  final_mant;
    reg [11:0] fr;
    reg        cancel;

    always @(*) begin
        cancel = 0;
        result_exp = 0;
        norm = 0;
        g_bit = 0;
        r_bit = 0;
        s_bit = 0;
        rounded = 0;
        final_exp = 0;
        final_mant = 0;
        fr = 0;
        result_sign = 0;
        big_exp = 0;
        big_fm = 0;
        big_sign = 0;
        small_fm = 0;
        small_sign = 0;
        shift = 0;
        sum_m = 0;

        if (is_nan_a || is_nan_b)
            result = 12'hF01;
        else if (is_inf_a && is_inf_b && (sign_a != sign_b))
            result = 12'hF01;
        else if (is_inf_a)
            result = sign_a ? 12'hF00 : 12'h700;
        else if (is_inf_b)
            result = sign_b ? 12'hF00 : 12'h700;
        else if (is_zero_a && is_zero_b)
            result = 12'h000;
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

            shift = big_exp - (a_larger ? exp_b : exp_a);
            result_exp = big_exp;

            case (shift)
                4'd0:  small_fm = small_fm;
                4'd1:  small_fm = {1'b0, small_fm[6:1]};
                4'd2:  small_fm = {2'b00, small_fm[6:2]};
                4'd3:  small_fm = {3'b000, small_fm[6:3]};
                4'd4:  small_fm = {4'b0000, small_fm[6:4]};
                4'd5:  small_fm = {5'b00000, small_fm[6:5]};
                4'd6:  small_fm = {6'b000000, small_fm[6]};
                4'd7:  small_fm = 8'd0;
                default: small_fm = 8'd0;
            endcase

            if (big_sign == small_sign) begin
                sum_m = {1'b0, big_fm} + {1'b0, small_fm};
                result_sign = big_sign;
            end else begin
                sum_m = {1'b0, big_fm} - {1'b0, small_fm};
                result_sign = big_sign;
                if (sum_m == 9'd0)
                    cancel = 1;
            end

            if (!cancel) begin
                if (sum_m[8]) begin
                    result_exp = result_exp + 4'd1;
                    norm  = sum_m[7:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else if (sum_m[7]) begin
                    norm = sum_m[7:1];
                end else if (sum_m[6]) begin
                    norm = {sum_m[6:1], 1'b0};
                    result_exp = result_exp - 4'd1;
                end else if (sum_m[5]) begin
                    norm = {sum_m[5:1], 2'b00};
                    result_exp = result_exp - 4'd2;
                end else if (sum_m[4]) begin
                    norm = {sum_m[4:1], 3'b000};
                    result_exp = result_exp - 4'd3;
                end else if (sum_m[3]) begin
                    norm = {sum_m[3:1], 4'b0000};
                    result_exp = result_exp - 4'd4;
                end else if (sum_m[2]) begin
                    norm = {sum_m[2:1], 5'b00000};
                    result_exp = result_exp - 4'd5;
                end else if (sum_m[1]) begin
                    norm = {sum_m[1], 6'b000000};
                    result_exp = result_exp - 4'd6;
                end else begin
                    norm = {sum_m[0], 7'b0000000};
                    result_exp = result_exp - 4'd7;
                end

                if (g_bit && (r_bit || s_bit))
                    rounded = norm + 8'd1;
                else
                    rounded = norm;

                if (rounded < norm) begin
                    final_exp  = result_exp + 4'd1;
                    final_mant = 7'd0;
                end else begin
                    final_exp  = result_exp;
                    final_mant = rounded[6:0];
                end

                if (final_exp[3])
                    fr = result_sign ? 12'h800 : 12'h000;
                else if (final_exp[3:0] >= EXP_MAX)
                    fr = result_sign ? 12'hF00 : 12'h700;
                else
                    fr = {result_sign, final_exp[3:0], final_mant};

                result = fr;
            end else begin
                result = 12'h000;
            end
        end
    end

endmodule
