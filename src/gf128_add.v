// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf128_add.v
// GoldenFloat128 Addition Unit (Verilog-2005 compliant)
// Layout: [S(1) | E(48) | M(79)] - phi_dist = 0.010 - BIAS = 140737488355327

`default_nettype none
module gf128_add (
    input  wire [127:0] a,
    input  wire [127:0] b,
    output reg  [127:0] result
);

    localparam BIAS    = 48'd140737488355327;
    localparam EXP_MAX = 48'd281474976710655;

    wire        sign_a = a[127];
    wire [47:0] exp_a  = a[126:79];
    wire [78:0] mant_a = a[78:0];
    wire        sign_b = b[127];
    wire [47:0] exp_b  = b[126:79];
    wire [78:0] mant_b = b[78:0];

    wire is_zero_a    = (exp_a == 48'd0) && (mant_a == 79'd0);
    wire is_zero_b    = (exp_b == 48'd0) && (mant_b == 79'd0);
    wire is_special_a = (exp_a == EXP_MAX);
    wire is_special_b = (exp_b == EXP_MAX);
    wire is_inf_a     = is_special_a && (mant_a == 79'd0);
    wire is_inf_b     = is_special_b && (mant_b == 79'd0);
    wire is_nan_a     = is_special_a && (mant_a != 79'd0);
    wire is_nan_b     = is_special_b && (mant_b != 79'd0);

    wire a_larger = (exp_a > exp_b) || ((exp_a == exp_b) && (mant_a >= mant_b));

    reg [48:0] big_exp, shift, result_exp;
    reg [80:0] big_fm, small_fm;
    reg [81:0] sum_m;
    reg       big_sign, small_sign, result_sign;
    reg [80:0] norm;
    reg       g_bit, r_bit, s_bit;
    reg [81:0] rounded;
    reg [48:0] final_exp;
    reg [78:0] final_mant;
    reg [127:0] fr;
    reg       cancel;
    reg [6:0]  lzc;  // Leading zero counter (max 79 bits needs 7 bits)

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
        lzc = 0;

        if (is_nan_a || is_nan_b)
            result = 128'hFFFFFFFFFFF801;
        else if (is_inf_a && is_inf_b && (sign_a != sign_b))
            result = 128'hFFFFFFFFFFF801;
        else if (is_inf_a)
            result = sign_a ? 128'hFFFFFFFFFFF800 : 128'h7FFFFFFFFFF800;
        else if (is_inf_b)
            result = sign_b ? 128'hFFFFFFFFFFF800 : 128'h7FFFFFFFFFF800;
        else if (is_zero_a && is_zero_b)
            result = 128'h0000000000000000;
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
            if (shift < 49'd80)
                small_fm = small_fm >> shift;
            else
                small_fm = 81'd0;

            if (big_sign == small_sign) begin
                sum_m = {1'b0, big_fm} + {1'b0, small_fm};
                result_sign = big_sign;
            end else begin
                sum_m = {1'b0, big_fm} - {1'b0, small_fm};
                result_sign = big_sign;
                if (sum_m == 82'd0)
                    cancel = 1;
            end

            if (!cancel) begin
                if (sum_m[81]) begin
                    result_exp = result_exp + 49'd1;
                    norm  = sum_m[80:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else if (sum_m[80]) begin
                    result_exp = result_exp + 49'd1;
                    norm  = sum_m[80:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else begin
                    // Leading zero count using priority encoder
                    lzc = 0;
                    if (!sum_m[79]) lzc = lzc + 1;
                    if (!sum_m[78] && lzc == 1) lzc = lzc + 1;
                    if (!sum_m[77] && lzc == 2) lzc = lzc + 1;
                    if (!sum_m[76] && lzc == 3) lzc = lzc + 1;
                    if (!sum_m[75] && lzc == 4) lzc = lzc + 1;
                    if (!sum_m[74] && lzc == 5) lzc = lzc + 1;
                    if (!sum_m[73] && lzc == 6) lzc = lzc + 1;
                    if (!sum_m[72] && lzc == 7) lzc = lzc + 1;

                    case (lzc)
                        7'd0: norm = sum_m[79:0];
                        7'd1: begin norm = {sum_m[78:0], 1'b0}; result_exp = result_exp - 49'd1; end
                        7'd2: begin norm = {sum_m[77:0], 2'b00}; result_exp = result_exp - 49'd2; end
                        7'd3: begin norm = {sum_m[76:0], 3'b000}; result_exp = result_exp - 49'd3; end
                        7'd4: begin norm = {sum_m[75:0], 4'b0000}; result_exp = result_exp - 49'd4; end
                        7'd5: begin norm = {sum_m[74:0], 5'b00000}; result_exp = result_exp - 49'd5; end
                        7'd6: begin norm = {sum_m[73:0], 6'b000000}; result_exp = result_exp - 49'd6; end
                        7'd7: begin norm = {sum_m[72:0], 7'b0000000}; result_exp = result_exp - 49'd7; end
                        default: begin norm = {1'b1, 79'b0}; result_exp = result_exp - 49'd79; end
                    endcase

                    g_bit = 1'b0;
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end

                if (g_bit && (r_bit || s_bit))
                    rounded = norm + 82'd1;
                else
                    rounded = norm;

                if (rounded < norm) begin
                    final_exp  = result_exp + 49'd1;
                    final_mant = 79'd0;
                end else begin
                    final_exp  = result_exp;
                    final_mant = norm[78:0];
                end

                if (final_exp[48])
                    fr = result_sign ? 128'h8000000000000000 : 128'h0000000000000000;
                else if (final_exp[47:0] >= EXP_MAX)
                    fr = result_sign ? 128'hFFFFFFFFFFF800 : 128'h7FFFFFFFFFF800;
                else
                    fr = {result_sign, final_exp[47:0], final_mant};

                result = fr;
            end else begin
                result = 128'h0000000000000000;
            end
        end
    end

endmodule