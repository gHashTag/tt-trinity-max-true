`default_nettype none
module gf32_add (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result
);

    localparam BIAS    = 12'd2047;
    localparam EXP_MAX = 12'd4095;

    wire        sign_a = a[31];
    wire [11:0] exp_a  = a[30:19];
    wire [18:0] mant_a = a[18:0];
    wire        sign_b = b[31];
    wire [11:0] exp_b  = b[30:19];
    wire [18:0] mant_b = b[18:0];

    wire is_zero_a    = (exp_a == 12'd0) && (mant_a == 19'd0);
    wire is_zero_b    = (exp_b == 12'd0) && (mant_b == 19'd0);
    wire is_special_a = (exp_a == EXP_MAX);
    wire is_special_b = (exp_b == EXP_MAX);
    wire is_inf_a     = is_special_a && (mant_a == 19'd0);
    wire is_inf_b     = is_special_b && (mant_b == 19'd0);
    wire is_nan_a     = is_special_a && (mant_a != 19'd0);
    wire is_nan_b     = is_special_b && (mant_b != 19'd0);

    wire a_larger = (exp_a > exp_b) || ((exp_a == exp_b) && (mant_a >= mant_b));

    reg [12:0] big_exp, shift, result_exp;
    reg [20:0] big_fm, small_fm;
    reg [21:0] sum_m;
    reg       big_sign, small_sign, result_sign;
    reg [20:0] norm;
    reg       g_bit, r_bit, s_bit;
    reg [21:0] rounded;
    reg [12:0] final_exp;
    reg [18:0] final_mant;
    reg [31:0] fr;
    reg       cancel;

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
            result = 32'hFFFFF801;
        else if (is_inf_a && is_inf_b && (sign_a != sign_b))
            result = 32'hFFFFF801;
        else if (is_inf_a)
            result = sign_a ? 32'hFFFFF800 : 32'h7FFF8000;
        else if (is_inf_b)
            result = sign_b ? 32'hFFFFF800 : 32'h7FFF8000;
        else if (is_zero_a && is_zero_b)
            result = 32'h00000000;
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
                13'd0: small_fm = small_fm;
                13'd1:  small_fm = {1'b0, small_fm[20:1]};
                13'd2:  small_fm = {2'b00, small_fm[20:2]};
                13'd3:  small_fm = {3'b000, small_fm[20:3]};
                13'd4:  small_fm = {4'b0000, small_fm[20:4]};
                13'd5:  small_fm = {5'b00000, small_fm[20:5]};
                13'd6:  small_fm = {6'b000000, small_fm[20:6]};
                13'd7:  small_fm = {7'b0000000, small_fm[20:7]};
                13'd8:  small_fm = {8'b00000000, small_fm[20:8]};
                13'd9:  small_fm = {9'b000000000, small_fm[20:9]};
                13'd10: small_fm = {10'b0000000000, small_fm[20:10]};
                13'd11: small_fm = {11'b00000000000, small_fm[20:11]};
                13'd12: small_fm = {12'b000000000000, small_fm[20:12]};
                13'd13: small_fm = {13'b0000000000000, small_fm[20:13]};
                13'd14: small_fm = {14'b00000000000000, small_fm[20:14]};
                13'd15: small_fm = {15'b000000000000000, small_fm[20:15]};
                13'd16: small_fm = {16'b0000000000000000, small_fm[20:16]};
                13'd17: small_fm = {17'b00000000000000000, small_fm[20:17]};
                13'd18: small_fm = {18'b000000000000000000, small_fm[20:18]};
                13'd19: small_fm = {19'b000000000000000000, small_fm[20:19]};
                13'd20: small_fm = {20'b0000000000000000000, small_fm[20]};
                default: small_fm = 22'd0;
            endcase

            if (big_sign == small_sign) begin
                sum_m = {1'b0, big_fm} + {1'b0, small_fm};
                result_sign = big_sign;
            end else begin
                sum_m = {1'b0, big_fm} - {1'b0, small_fm};
                result_sign = big_sign;
                if (sum_m == 23'd0)
                    cancel = 1;
            end

            if (!cancel) begin
                if (sum_m[21]) begin
                    result_exp = result_exp + 13'd1;
                    norm  = sum_m[20:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else if (sum_m[20]) begin
                    result_exp = result_exp + 13'd1;
                    norm  = sum_m[20:1];
                    g_bit = sum_m[0];
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end else begin
                    if (sum_m[19]) begin
                        norm = sum_m[19:0];
                    end else if (sum_m[18]) begin
                        norm = {sum_m[18:0], 1'b0};
                        result_exp = result_exp - 13'd1;
                    end else if (sum_m[17]) begin
                        norm = {sum_m[17:0], 2'b00};
                        result_exp = result_exp - 13'd2;
                    end else if (sum_m[16]) begin
                        norm = {sum_m[16:0], 3'b000};
                        result_exp = result_exp - 13'd3;
                    end else if (sum_m[15]) begin
                        norm = {sum_m[15:0], 4'b0000};
                        result_exp = result_exp - 13'd4;
                    end else if (sum_m[14]) begin
                        norm = {sum_m[14:0], 5'b00000};
                        result_exp = result_exp - 13'd5;
                    end else if (sum_m[13]) begin
                        norm = {sum_m[13:0], 6'b000000};
                        result_exp = result_exp - 13'd6;
                    end else if (sum_m[12]) begin
                        norm = {sum_m[12:0], 7'b0000000};
                        result_exp = result_exp - 13'd7;
                    end else if (sum_m[11]) begin
                        norm = {sum_m[11:0], 8'b00000000};
                        result_exp = result_exp - 13'd8;
                    end else if (sum_m[10]) begin
                        norm = {sum_m[10:0], 9'b000000000};
                        result_exp = result_exp - 13'd9;
                    end else if (sum_m[9]) begin
                        norm = {sum_m[9:0], 10'b0000000000};
                        result_exp = result_exp - 13'd10;
                    end else if (sum_m[8]) begin
                        norm = {sum_m[8:0], 11'b00000000000};
                        result_exp = result_exp - 13'd11;
                    end else if (sum_m[7]) begin
                        norm = {sum_m[7:0], 12'b000000000000};
                        result_exp = result_exp - 13'd12;
                    end else if (sum_m[6]) begin
                        norm = {sum_m[6:0], 13'b0000000000000};
                        result_exp = result_exp - 13'd13;
                    end else if (sum_m[5]) begin
                        norm = {sum_m[5:0], 14'b00000000000000};
                        result_exp = result_exp - 13'd14;
                    end else if (sum_m[4]) begin
                        norm = {sum_m[4:0], 15'b000000000000000};
                        result_exp = result_exp - 13'd15;
                    end else if (sum_m[3]) begin
                        norm = {sum_m[3:0], 16'b0000000000000000};
                        result_exp = result_exp - 13'd16;
                    end else if (sum_m[2]) begin
                        norm = {sum_m[2:0], 17'b00000000000000000};
                        result_exp = result_exp - 13'd17;
                    end else if (sum_m[1]) begin
                        norm = {sum_m[1:0], 18'b000000000000000000};
                        result_exp = result_exp - 13'd18;
                    end else begin
                        norm = {sum_m[0], 19'b000000000000000000};
                        result_exp = result_exp - 13'd19;
                    end
                    g_bit = 1'b0;
                    r_bit = 1'b0;
                    s_bit = 1'b0;
                end

                if (g_bit && (r_bit || s_bit))
                    rounded = norm + 22'd1;
                else
                    rounded = norm;

                if (rounded < norm) begin
                    final_exp  = result_exp + 13'd1;
                    final_mant = 19'd0;
                end else begin
                    final_exp  = result_exp;
                    final_mant = norm[18:0];
                end

                if (final_exp[12])
                    fr = result_sign ? 32'h80000000 : 32'h00000000;
                else if (final_exp[11:0] >= EXP_MAX)
                    fr = result_sign ? 32'hFFFFF800 : 32'h7FFF8000;
                else
                    fr = {result_sign, final_exp[11:0], final_mant};

                result = fr;
            end else begin
                result = 32'h00000000;
            end
        end
    end

endmodule