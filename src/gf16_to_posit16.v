// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/gf16_to_posit16.v
// GoldenFloat16 to Posit16 Converter
// Posit16: [S(1) | R(1) | E(3) | M(11)] - es = 2

`default_nettype none
module gf16_to_posit16 (
    input  wire [15:0] gf_in,
    output reg  [15:0] posit_out
);

    // GF16: [S(1) | E(6) | M(9)] - BIAS = 31
    // Posit16: [S(1) | R(1) | E(3) | M(11)] with useed

    wire        sign = gf_in[15];
    wire [5:0]  gf_exp = gf_in[14:9];
    wire [8:0]  gf_mant = gf_in[8:0];

    localparam GF_BIAS  = 6'd31;
    localparam GF_MAX   = 6'd63;

    wire is_gf_zero = (gf_exp == 6'd0) && (gf_mant == 9'd0);
    wire is_gf_inf  = (gf_exp == GF_MAX) && (gf_mant == 9'd0);

    reg [5:0]  unbiased_exp;
    reg [3:0]  regime;
    reg [10:0] posit_mant;

    always @(*) begin
        if (is_gf_zero) begin
            posit_out = 16'h0;
        end else if (is_gf_inf) begin
            posit_out = sign ? 16'h8000 : 16'h7FFF;
        end else begin
            unbiased_exp = gf_exp - GF_BIAS;

            // Regime bits (simplified)
            if (unbiased_exp >= 4'd8) begin
                regime = {4'b1111};  // All ones
            end else begin
                regime = unbiased_exp[3:0];
            end

            // Mantissa (truncate 9 bits to 11 with zeros)
            posit_mant = {gf_mant, 2'b0};

            // Posit format: S | R | E | M
            posit_out = {sign, regime[0], unbiased_exp[2:0], posit_mant};
        end
    end

endmodule

module posit16_to_gf16 (
    input  wire [15:0] posit_in,
    output reg  [15:0] gf_out
);

    // Posit16: [S(1) | R(1) | E(3) | M(11)] - es = 2
    // GF16: [S(1) | E(6) | M(9)] - BIAS = 31

    wire        sign = posit_in[15];
    wire        regime_bit = posit_in[14];
    wire [2:0]  posit_exp = posit_in[13:11];
    wire [10:0] posit_mant = posit_in[10:0];

    localparam GF_BIAS  = 6'd31;
    localparam GF_MAX   = 6'd63;

    wire is_posit_zero = (posit_in == 16'h0);
    wire is_posit_inf  = (posit_in == 16'h7FFF) || (posit_in == 16'h8000);

    reg [5:0]  gf_exp;
    reg [8:0]  gf_mant;

    always @(*) begin
        if (is_posit_zero) begin
            gf_out = 16'h0;
        end else if (is_posit_inf) begin
            gf_out = sign ? 16'hFE00 : 16'h7E00;
        end else begin
            // Convert posit exponent to GF exponent (simplified)
            gf_exp = posit_exp + GF_BIAS;

            if (gf_exp[5]) begin
                gf_out = {sign, 6'd0, 9'd0};
            end else if (gf_exp[5:0] >= GF_MAX) begin
                gf_out = {sign, 6'd63, 9'd0};
            end else begin
                gf_mant = posit_mant[10:2];  // Truncate 11 to 9
                gf_out = {sign, gf_exp, gf_mant};
            end
        end
    end

endmodule