// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf16_to_fp16.v
// GoldenFloat16 to IEEE754 FP16 Converter

`default_nettype none
module gf16_to_fp16 (
    input  wire [15:0] gf_in,
    output reg  [15:0] fp_out
);

    // GF16: [S(1) | E(6) | M(9)] - BIAS = 31
    // FP16: [S(1) | E(5) | M(10)] - BIAS = 15

    wire        sign = gf_in[15];
    wire [5:0]  gf_exp = gf_in[14:9];
    wire [8:0]  gf_mant = gf_in[8:0];

    localparam GF_BIAS  = 6'd31;
    localparam GF_MAX   = 6'd63;
    localparam FP_BIAS  = 5'd15;
    localparam FP_MAX   = 5'd31;

    wire is_gf_zero    = (gf_exp == 6'd0) && (gf_mant == 9'd0);
    wire is_gf_inf     = (gf_exp == GF_MAX) && (gf_mant == 9'd0);
    wire is_gf_nan     = (gf_exp == GF_MAX) && (gf_mant != 9'd0);

    reg [5:0]  unbiased_exp;
    reg [4:0]  fp_exp;
    reg [9:0]  fp_mant;

    always @(*) begin
        if (is_gf_nan) begin
            // GF NaN → FP16 NaN
            fp_out = {sign, 5'h1F, 10'h1};
        end else if (is_gf_inf) begin
            // GF inf → FP16 inf
            fp_out = {sign, 5'h1F, 10'h0};
        end else if (is_gf_zero) begin
            // GF zero → FP16 zero
            fp_out = {sign, 5'h0, 10'h0};
        end else begin
            // Unbias GF exponent
            unbiased_exp = gf_exp - GF_BIAS;

            // Bias for FP16 and check range
            if (unbiased_exp[5]) begin
                // Negative exponent - subnormal or underflow
                fp_exp = 5'd0;
                fp_mant = {1'b0, gf_mant, 1'b0};  // Simplified subnormal
            end else if (unbiased_exp[4:0] + FP_BIAS >= FP_MAX) begin
                // Overflow
                fp_out = {sign, 5'h1F, 10'h0};
            end else begin
                fp_exp = unbiased_exp[4:0] + FP_BIAS;
                fp_mant = {gf_mant, 1'b0};  // Extend 9 bits to 10
                fp_out = {sign, fp_exp, fp_mant};
            end
        end
    end

endmodule

module fp16_to_gf16 (
    input  wire [15:0] fp_in,
    output reg  [15:0] gf_out
);

    // FP16: [S(1) | E(5) | M(10)] - BIAS = 15
    // GF16: [S(1) | E(6) | M(9)] - BIAS = 31

    wire        sign = fp_in[15];
    wire [4:0]  fp_exp = fp_in[14:10];
    wire [9:0]  fp_mant = fp_in[9:0];

    localparam FP_BIAS  = 5'd15;
    localparam FP_MAX   = 5'd31;
    localparam GF_BIAS  = 6'd31;
    localparam GF_MAX   = 6'd63;

    wire is_fp_zero    = (fp_exp == 5'd0) && (fp_mant == 10'd0);
    wire is_fp_inf     = (fp_exp == FP_MAX) && (fp_mant == 10'd0);
    wire is_fp_nan     = (fp_exp == FP_MAX) && (fp_mant != 10'd0);
    wire is_fp_subnorm = (fp_exp == 5'd0) && (fp_mant != 10'd0);

    reg [5:0]  unbiased_exp;
    reg [5:0]  gf_exp;
    reg [8:0]  gf_mant;

    always @(*) begin
        if (is_fp_nan) begin
            // FP16 NaN → GF16 NaN
            gf_out = {sign, 6'd63, 9'h1};
        end else if (is_fp_inf) begin
            // FP16 inf → GF16 inf
            gf_out = {sign, 6'd63, 9'd0};
        end else if (is_fp_zero) begin
            // FP16 zero → GF16 zero
            gf_out = {sign, 6'd0, 9'd0};
        end else if (is_fp_subnorm) begin
            // FP16 subnormal → GF16 normalized (approximate)
            gf_exp = 6'd1;
            gf_mant = fp_mant[9:1];
            gf_out = {sign, gf_exp, gf_mant};
        end else begin
            // Unbias FP16 exponent
            unbiased_exp = {1'b0, fp_exp} - FP_BIAS;

            // Bias for GF16
            gf_exp = unbiased_exp + GF_BIAS;

            if (gf_exp[5]) begin
                // Underflow
                gf_out = {sign, 6'd0, 9'd0};
            end else if (gf_exp[5:0] >= GF_MAX) begin
                // Overflow
                gf_out = {sign, 6'd63, 9'd0};
            end else begin
                gf_mant = fp_mant[9:1];  // Truncate 10 bits to 9
                gf_out = {sign, gf_exp, gf_mant};
            end
        end
    end

endmodule