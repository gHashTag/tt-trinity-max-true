// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf32_to_fp32.v
// GoldenFloat32 to IEEE754 FP32 Converter

`default_nettype none
module gf32_to_fp32 (
    input  wire [31:0] gf_in,
    output reg  [31:0] fp_out
);

    // GF32: [S(1) | E(12) | M(19)] - BIAS = 2047
    // FP32: [S(1) | E(8) | M(23)] - BIAS = 127

    wire        sign = gf_in[31];
    wire [11:0] gf_exp = gf_in[30:19];
    wire [18:0] gf_mant = gf_in[18:0];

    localparam GF_BIAS  = 12'd2047;
    localparam GF_MAX   = 12'd4095;
    localparam FP_BIAS  = 8'd127;
    localparam FP_MAX   = 8'd255;

    wire is_gf_zero    = (gf_exp == 12'd0) && (gf_mant == 19'd0);
    wire is_gf_inf     = (gf_exp == GF_MAX) && (gf_mant == 19'd0);
    wire is_gf_nan     = (gf_exp == GF_MAX) && (gf_mant != 19'd0);

    reg [11:0] unbiased_exp;
    reg [7:0]  fp_exp;
    reg [22:0] fp_mant;

    always @(*) begin
        if (is_gf_nan) begin
            fp_out = {sign, 8'hFF, 23'h1};
        end else if (is_gf_inf) begin
            fp_out = {sign, 8'hFF, 23'h0};
        end else if (is_gf_zero) begin
            fp_out = {sign, 8'h0, 23'h0};
        end else begin
            unbiased_exp = gf_exp - GF_BIAS;

            if (unbiased_exp[11]) begin
                fp_exp = 8'd0;
                fp_mant = {4'b0, gf_mant, 1'b0};
            end else if (unbiased_exp[10]) begin
                // Overflow
                fp_out = {sign, 8'hFF, 23'h0};
            end else if (({3'd0, unbiased_exp[7:0]} + FP_BIAS) >= FP_MAX) begin
                fp_out = {sign, 8'hFF, 23'h0};
            end else begin
                fp_exp = unbiased_exp[7:0] + FP_BIAS;
                fp_mant = {gf_mant, 4'b0};
                fp_out = {sign, fp_exp, fp_mant};
            end
        end
    end

endmodule

module fp32_to_gf32 (
    input  wire [31:0] fp_in,
    output reg  [31:0] gf_out
);

    // FP32: [S(1) | E(8) | M(23)] - BIAS = 127
    // GF32: [S(1) | E(12) | M(19)] - BIAS = 2047

    wire        sign = fp_in[31];
    wire [7:0]  fp_exp = fp_in[30:23];
    wire [22:0] fp_mant = fp_in[22:0];

    localparam FP_BIAS  = 8'd127;
    localparam FP_MAX   = 8'd255;
    localparam GF_BIAS  = 12'd2047;
    localparam GF_MAX   = 12'd4095;

    wire is_fp_zero    = (fp_exp == 8'd0) && (fp_mant == 23'd0);
    wire is_fp_inf     = (fp_exp == FP_MAX) && (fp_mant == 23'd0);
    wire is_fp_nan     = (fp_exp == FP_MAX) && (fp_mant != 23'd0);
    wire is_fp_subnorm = (fp_exp == 8'd0) && (fp_mant != 23'd0);

    reg [11:0] unbiased_exp;
    reg [11:0] gf_exp;
    reg [18:0] gf_mant;

    always @(*) begin
        if (is_fp_nan) begin
            gf_out = {sign, 12'd4095, 19'h1};
        end else if (is_fp_inf) begin
            gf_out = {sign, 12'd4095, 19'd0};
        end else if (is_fp_zero) begin
            gf_out = {sign, 12'd0, 19'd0};
        end else if (is_fp_subnorm) begin
            gf_exp = 12'd1;
            gf_mant = fp_mant[22:4];
            gf_out = {sign, gf_exp, gf_mant};
        end else begin
            unbiased_exp = {4'd0, fp_exp} - FP_BIAS;
            gf_exp = unbiased_exp + GF_BIAS;

            if (gf_exp[11]) begin
                gf_out = {sign, 12'd0, 19'd0};
            end else if (gf_exp[11:0] >= GF_MAX) begin
                gf_out = {sign, 12'd4095, 19'd0};
            end else begin
                gf_mant = fp_mant[22:4];
                gf_out = {sign, gf_exp, gf_mant};
            end
        end
    end

endmodule