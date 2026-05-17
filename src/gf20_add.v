`default_nettype none
module gf20_add (
    input  wire [19:0] a,
    input  wire [19:0] b,
    output reg  [19:0] result
);

    // GF20: 1 sign + 7 exp + 12 mant = 20 bits
    // Layout: [S|E6..E0|M11..M0] = [19|18..12|11..0]

    localparam BIAS    = 7'd63;
    localparam EXP_MAX = 7'd127;

    wire        sign_a = a[19];
    wire [6:0]  exp_a  = a[18:12];
    wire [11:0] mant_a = a[11:0];
    wire        sign_b = b[19];
    wire [6:0]  exp_b  = b[18:12];
    wire [11:0] mant_b = b[11:0];

    wire is_zero_a    = (exp_a == 7'd0) && (mant_a == 12'd0);
    wire is_zero_b    = (exp_b == 7'd0) && (mant_b == 12'd0);
    wire is_special_a = (exp_a == EXP_MAX);
    wire is_special_b = (exp_b == EXP_MAX);
    wire is_inf_a     = is_special_a && (mant_a == 12'd0);
    wire is_inf_b     = is_special_b && (mant_b == 12'd0);
    wire is_nan_a     = is_special_a && (mant_a != 12'd0);
    wire is_nan_b     = is_special_b && (mant_b != 12'd0);

    wire a_larger = (exp_a > exp_b) || ((exp_a == exp_b) && (mant_a >= mant_b));

    reg [7:0]  big_exp, shift, result_exp;
    reg [13:0] big_fm, small_fm;
    reg [14:0] sum_m;
    reg        big_sign, small_sign, result_sign;
    reg [12:0] norm;
    reg        g_bit, r_bit, s_bit;
    reg [13:0] rounded;
    reg [7:0]  final_exp;
    reg [11:0] final_mant;
    reg [19:0] fr;
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
            result = 20'hFF801;
        else if (is_inf_a && is_inf_b && (sign_a != sign_b))
            result = 20'hFF801;
        else if (is_inf_a)
            result = sign_a ? 20'hFF800 : 20'h7F800;
        else if (is_inf_b)
            result = sign_b ? 20'hFF800 : 20'h7F800;
        else if (is_zero_a && is_zero_b)
            result = 20'h00000;
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

            case (shift)
                8'd0:  small_fm = small_fm;
                8'd1:  small_fm = {1'b0, small_fm[13:1]};
                8'd2:  small_fm = {2'b00, small_fm[13:2]};
                8'd3:  small_fm = {3'b000, small_fm[13:3]};
                8'd4:  small_fm = {4'b0000, small_fm[13:4]};
                8'd5:  small_fm = {5'b00000, small_fm[13:5]};
                8'd6:  small_fm = {6'b000000, small_fm[13:6]};
                8'd7:  small_fm = {7'b0000000, small_fm[13:7]};
                8'd8:  small_fm = {8'b00000000, small_fm[13:8]};
                8'd9:  small_fm = {9'b000000000, small_fm[13:9]};
                8'd10: small_fm = {10'b0000000000, small_fm[13:10]};
                8'd11: small_fm = {11'b00000000000, small_fm[13:11]};
                8'd12: small_fm = {12'b000000000000, small_fm[13]};
                default: small_fm = 14'd0;
            endcase

            if (big_sign == small_sign) begin
                sum_m = {1'b0, big_fm} + {1'b0, small_fm};
                result_sign = big_sign;
            end else begin
                sum_m = {1'b0, big_fm} - {1'b0, small_fm};
                result_sign = big_sign;
                if (sum_m == 15'd0)
                    cancel = 1;
            end

            if (!cancel) begin
                if (sum_m[14]) begin
                    result_exp = result_exp + 8'd1;
                    norm  = sum_m[13:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else if (sum_m[13]) begin
                    result_exp = result_exp + 8'd1;
                    norm  = sum_m[13:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else begin
                    if (sum_m[12]) begin
                        norm = sum_m[12:0];
                    end else if (sum_m[11]) begin
                        norm = {sum_m[11:0], 1'b0};
                        result_exp = result_exp - 8'd1;
                    end else if (sum_m[10]) begin
                        norm = {sum_m[10:0], 2'b00};
                        result_exp = result_exp - 8'd2;
                    end else if (sum_m[9]) begin
                        norm = {sum_m[9:0], 3'b000};
                        result_exp = result_exp - 8'd3;
                    end else if (sum_m[8]) begin
                        norm = {sum_m[8:0], 4'b0000};
                        result_exp = result_exp - 8'd4;
                    end else if (sum_m[7]) begin
                        norm = {sum_m[7:0], 5'b00000};
                        result_exp = result_exp - 8'd5;
                    end else if (sum_m[6]) begin
                        norm = {sum_m[6:0], 6'b000000};
                        result_exp = result_exp - 8'd6;
                    end else if (sum_m[5]) begin
                        norm = {sum_m[5:0], 7'b0000000};
                        result_exp = result_exp - 8'd7;
                    end else if (sum_m[4]) begin
                        norm = {sum_m[4:0], 8'b00000000};
                        result_exp = result_exp - 8'd8;
                    end else if (sum_m[3]) begin
                        norm = {sum_m[3:0], 9'b000000000};
                        result_exp = result_exp - 8'd9;
                    end else if (sum_m[2]) begin
                        norm = {sum_m[2:0], 10'b0000000000};
                        result_exp = result_exp - 8'd10;
                    end else if (sum_m[1]) begin
                        norm = {sum_m[1:0], 11'b00000000000};
                        result_exp = result_exp - 8'd11;
                    end else begin
                        norm = {sum_m[0], 12'b000000000000};
                        result_exp = result_exp - 8'd12;
                    end
                    g_bit = 1'b0;
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end

                if (g_bit && (r_bit || s_bit))
                    rounded = norm + 14'd1;
                else
                    rounded = norm;

                if (rounded < norm) begin
                    final_exp  = result_exp + 8'd1;
                    final_mant = 12'd0;
                end else begin
                    final_exp  = result_exp;
                    final_mant = norm[11:0];
                end

                if (final_exp[7])
                    fr = result_sign ? 20'h80000 : 20'h00000;
                else if (final_exp[6:0] >= EXP_MAX)
                    fr = result_sign ? 20'hFF800 : 20'h7F800;
                else
                    fr = {result_sign, final_exp[6:0], final_mant};

                result = fr;
            end else begin
                result = 20'h00000;
            end
        end
    end

endmodule