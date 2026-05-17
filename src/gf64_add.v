// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf64_add.v
// GoldenFloat64 Addition Unit
// Layout: [S(1) | E(24) | M(39)] - BEST phi_dist = 0.003 - BIAS = 8388607

`default_nettype none
module gf64_add (
    input  wire [63:0] a,
    input  wire [63:0] b,
    output reg  [63:0] result
);

    localparam BIAS    = 24'd8388607;
    localparam EXP_MAX = 24'd16777215;

    wire        sign_a = a[63];
    wire [23:0] exp_a  = a[62:39];
    wire [38:0] mant_a = a[38:0];
    wire        sign_b = b[63];
    wire [23:0] exp_b  = b[62:39];
    wire [38:0] mant_b = b[38:0];

    wire is_zero_a    = (exp_a == 24'd0) && (mant_a == 39'd0);
    wire is_zero_b    = (exp_b == 24'd0) && (mant_b == 39'd0);
    wire is_special_a = (exp_a == EXP_MAX);
    wire is_special_b = (exp_b == EXP_MAX);
    wire is_inf_a     = is_special_a && (mant_a == 39'd0);
    wire is_inf_b     = is_special_b && (mant_b == 39'd0);
    wire is_nan_a     = is_special_a && (mant_a != 39'd0);
    wire is_nan_b     = is_special_b && (mant_b != 39'd0);

    wire a_larger = (exp_a > exp_b) || ((exp_a == exp_b) && (mant_a >= mant_b));

    reg [24:0] big_exp, shift, result_exp;
    reg [40:0] big_fm, small_fm;
    reg [41:0] sum_m;
    reg        big_sign, small_sign, result_sign;
    reg [40:0] norm;
    reg        g_bit, r_bit, s_bit;
    reg [41:0] rounded;
    reg [24:0] final_exp;
    reg [38:0] final_mant;
    reg [63:0] fr;
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
            result = 64'hFFFFFFFFFFF801;
        else if (is_inf_a && is_inf_b && (sign_a != sign_b))
            result = 64'hFFFFFFFFFFF801;
        else if (is_inf_a)
            result = sign_a ? 64'hFFFFFFFFFFF800 : 64'h7FFFFFFFFFF800;
        else if (is_inf_b)
            result = sign_b ? 64'hFFFFFFFFFFF800 : 64'h7FFFFFFFFFF800;
        else if (is_zero_a && is_zero_b)
            result = 64'h0000000000000000;
        else if (is_zero_a)
            result = b;
        else if (is_zero_b)
            result = a;
        else begin
            if (a_larger) begin
                big_exp    = {1'b0, exp_a};
                big_fm     = {1'b1, mant_a};
                big_sign   = sign_a;
                small_fm   = {1'b1, mant_b};
                small_sign = sign_b;
            end else begin
                big_exp    = {1'b0, exp_b};
                big_fm     = {1'b1, mant_b};
                big_sign   = sign_b;
                small_fm   = {1'b1, mant_a};
                small_sign = sign_a;
            end

            shift = big_exp - {1'b0, (a_larger ? exp_b : exp_a)};
            result_exp = big_exp;

            // Barrel shifter for small_fm alignment
            if (shift < 25'd40)
                small_fm = small_fm >> shift;
            else
                small_fm = 41'd0;

            if (big_sign == small_sign) begin
                sum_m = {1'b0, big_fm} + {1'b0, small_fm};
                result_sign = big_sign;
            end else begin
                sum_m = {1'b0, big_fm} - {1'b0, small_fm};
                result_sign = big_sign;
                if (sum_m == 42'd0)
                    cancel = 1;
            end

            if (!cancel) begin
                if (sum_m[41]) begin
                    result_exp = result_exp + 25'd1;
                    norm  = sum_m[40:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else if (sum_m[40]) begin
                    result_exp = result_exp + 25'd1;
                    norm  = sum_m[40:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else begin
                    // Leading zero count and normalization
                    if (sum_m[39]) begin
                        norm = sum_m[39:0];
                    end else if (sum_m[38]) begin
                        norm = {sum_m[38:0], 1'b0};
                        result_exp = result_exp - 25'd1;
                    end else if (sum_m[37]) begin
                        norm = {sum_m[37:0], 2'b00};
                        result_exp = result_exp - 25'd2;
                    end else if (sum_m[36]) begin
                        norm = {sum_m[36:0], 3'b000};
                        result_exp = result_exp - 25'd3;
                    end else if (sum_m[35]) begin
                        norm = {sum_m[35:0], 4'b0000};
                        result_exp = result_exp - 25'd4;
                    end else if (sum_m[34]) begin
                        norm = {sum_m[34:0], 5'b00000};
                        result_exp = result_exp - 25'd5;
                    end else if (sum_m[33]) begin
                        norm = {sum_m[33:0], 6'b000000};
                        result_exp = result_exp - 25'd6;
                    end else if (sum_m[32]) begin
                        norm = {sum_m[32:0], 7'b0000000};
                        result_exp = result_exp - 25'd7;
                    end else if (sum_m[31]) begin
                        norm = {sum_m[31:0], 8'b00000000};
                        result_exp = result_exp - 25'd8;
                    end else if (sum_m[30]) begin
                        norm = {sum_m[30:0], 9'b000000000};
                        result_exp = result_exp - 25'd9;
                    end else if (sum_m[29]) begin
                        norm = {sum_m[29:0], 10'b0000000000};
                        result_exp = result_exp - 25'd10;
                    end else if (sum_m[28]) begin
                        norm = {sum_m[28:0], 11'b00000000000};
                        result_exp = result_exp - 25'd11;
                    end else if (sum_m[27]) begin
                        norm = {sum_m[27:0], 12'b000000000000};
                        result_exp = result_exp - 25'd12;
                    end else if (sum_m[26]) begin
                        norm = {sum_m[26:0], 13'b0000000000000};
                        result_exp = result_exp - 25'd13;
                    end else if (sum_m[25]) begin
                        norm = {sum_m[25:0], 14'b00000000000000};
                        result_exp = result_exp - 25'd14;
                    end else if (sum_m[24]) begin
                        norm = {sum_m[24:0], 15'b000000000000000};
                        result_exp = result_exp - 25'd15;
                    end else if (sum_m[23]) begin
                        norm = {sum_m[23:0], 16'b0000000000000000};
                        result_exp = result_exp - 25'd16;
                    end else if (sum_m[22]) begin
                        norm = {sum_m[22:0], 17'b00000000000000000};
                        result_exp = result_exp - 25'd17;
                    end else if (sum_m[21]) begin
                        norm = {sum_m[21:0], 18'b000000000000000000};
                        result_exp = result_exp - 25'd18;
                    end else if (sum_m[20]) begin
                        norm = {sum_m[20:0], 19'b0000000000000000000};
                        result_exp = result_exp - 25'd19;
                    end else if (sum_m[19]) begin
                        norm = {sum_m[19:0], 20'b00000000000000000000};
                        result_exp = result_exp - 25'd20;
                    end else if (sum_m[18]) begin
                        norm = {sum_m[18:0], 21'b00000000000000000000};
                        result_exp = result_exp - 25'd21;
                    end else if (sum_m[17]) begin
                        norm = {sum_m[17:0], 22'b000000000000000000000};
                        result_exp = result_exp - 25'd22;
                    end else if (sum_m[16]) begin
                        norm = {sum_m[16:0], 23'b000000000000000000000};
                        result_exp = result_exp - 25'd23;
                    end else if (sum_m[15]) begin
                        norm = {sum_m[15:0], 24'b0000000000000000000000};
                        result_exp = result_exp - 25'd24;
                    end else if (sum_m[14]) begin
                        norm = {sum_m[14:0], 25'b00000000000000000000000};
                        result_exp = result_exp - 25'd25;
                    end else if (sum_m[13]) begin
                        norm = {sum_m[13:0], 26'b000000000000000000000000};
                        result_exp = result_exp - 25'd26;
                    end else if (sum_m[12]) begin
                        norm = {sum_m[12:0], 27'b0000000000000000000000000};
                        result_exp = result_exp - 25'd27;
                    end else if (sum_m[11]) begin
                        norm = {sum_m[11:0], 28'b00000000000000000000000000};
                        result_exp = result_exp - 25'd28;
                    end else if (sum_m[10]) begin
                        norm = {sum_m[10:0], 29'b000000000000000000000000000};
                        result_exp = result_exp - 25'd29;
                    end else if (sum_m[9]) begin
                        norm = {sum_m[9:0], 30'b0000000000000000000000000000};
                        result_exp = result_exp - 25'd30;
                    end else if (sum_m[8]) begin
                        norm = {sum_m[8:0], 31'b00000000000000000000000000000};
                        result_exp = result_exp - 25'd31;
                    end else if (sum_m[7]) begin
                        norm = {sum_m[7:0], 32'b000000000000000000000000000000};
                        result_exp = result_exp - 25'd32;
                    end else if (sum_m[6]) begin
                        norm = {sum_m[6:0], 33'b0000000000000000000000000000000};
                        result_exp = result_exp - 25'd33;
                    end else if (sum_m[5]) begin
                        norm = {sum_m[5:0], 34'b00000000000000000000000000000000};
                        result_exp = result_exp - 25'd34;
                    end else if (sum_m[4]) begin
                        norm = {sum_m[4:0], 35'b0000000000000000000000000000000000};
                        result_exp = result_exp - 25'd35;
                    end else if (sum_m[3]) begin
                        norm = {sum_m[3:0], 36'b00000000000000000000000000000000000};
                        result_exp = result_exp - 25'd36;
                    end else if (sum_m[2]) begin
                        norm = {sum_m[2:0], 37'b0000000000000000000000000000000000};
                        result_exp = result_exp - 25'd37;
                    end else if (sum_m[1]) begin
                        norm = {sum_m[1:0], 38'b00000000000000000000000000000000000};
                        result_exp = result_exp - 25'd38;
                    end else begin
                        norm = {sum_m[0], 39'b0000000000000000000000000000000000};
                        result_exp = result_exp - 25'd39;
                    end
                    g_bit = 1'b0;
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end

                if (g_bit && (r_bit || s_bit))
                    rounded = norm + 42'd1;
                else
                    rounded = norm;

                if (rounded < norm) begin
                    final_exp  = result_exp + 25'd1;
                    final_mant = 39'd0;
                end else begin
                    final_exp  = result_exp;
                    final_mant = norm[38:0];
                end

                if (final_exp[24])
                    fr = result_sign ? 64'h8000000000000000 : 64'h0000000000000000;
                else if (final_exp[23:0] >= EXP_MAX)
                    fr = result_sign ? 64'hFFFFFFFFFFF800 : 64'h7FFFFFFFFFF800;
                else
                    fr = {result_sign, final_exp[23:0], final_mant};

                result = fr;
            end else begin
                result = 64'h0000000000000000;
            end
        end
    end

endmodule