// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/fp8_e5m2_quantizer.v
// FP8 E5M2 Quantization Unit (OCP FP8)
// Format: [S(1) | EXP(5) | MANT(2)], bias = 15
// Used in Transformer inference acceleration

`default_nettype none
module fp8_e5m2_quantizer (
    input  wire signed [15:0] fp16_in,   // FP16 input
    output reg  [7:0]    fp8_out       // FP8 E5M2 output
);

    wire        sign = fp16_in[15];
    wire [4:0]  exp16 = fp16_in[14:10];
    wire [9:0]  mant16 = fp16_in[9:0];

    // FP16 bias = 15, FP8 bias = 15 (same!)
    // exp8 = exp16

    wire [4:0]  exp8 = exp16;
    wire [1:0]  mant8 = mant16[9:8];

    reg  [4:0]  exp_clamped;
    reg  [1:0]  mant_rounded;
    reg  [7:0]  sticky;

    always @(*) begin
        // Check for special values
        if (exp16 == 5'd31) begin
            // Infinity or NaN in FP16
            if (mant16 == 10'd0)
                fp8_out = {sign, 5'd31, 2'd0};  // Infinity
            else
                fp8_out = {sign, 5'd31, 2'd1};  // NaN
        end else if (exp16 == 5'd0) begin
            // Zero or denormal in FP16
            fp8_out = {sign, 8'd0};  // Zero
        end else begin
            // Clamp exponent to FP8 range
            if (exp8 > 5'd30)
                exp_clamped = 5'd30;
            else if (exp8 == 5'd0)
                exp_clamped = 5'd0;
            else
                exp_clamped = exp8;

            // Round mantissa with sticky bit
            sticky = |mant16[7:0];
            if (mant16[8] && (mant16[7] || sticky))
                mant_rounded = mant8 + 2'd1;
            else
                mant_rounded = mant8;

            // Handle mantissa overflow
            if (mant_rounded == 2'd3 && exp_clamped < 5'd30) begin
                exp_clamped = exp_clamped + 5'd1;
                mant_rounded = 2'd0;
            end

            fp8_out = {sign, exp_clamped[4:0], mant_rounded[1:0]};
        end
    end

endmodule

// FP8 E5M2 Dequantization Unit
module fp8_e5m2_dequantizer (
    input  wire [7:0]    fp8_in,       // FP8 E5M2 input
    output reg  signed [15:0] fp16_out   // FP16 output
);

    wire        sign = fp8_in[7];
    wire [4:0]  exp8 = fp8_in[6:2];
    wire [1:0]  mant8 = fp8_in[1:0];

    reg  [9:0]  mant16;

    always @(*) begin
        if (exp8 == 5'd0) begin
            // Zero or denormal (treat as zero for simplicity)
            fp16_out = {sign, 15'd0};
        end else if (exp8 == 5'd31) begin
            // Infinity or NaN
            if (mant8 == 2'd0)
                fp16_out = {sign, 5'd31, 10'd0};  // Infinity
            else
                fp16_out = {sign, 5'd31, 10'd1};  // NaN
        end else begin
            // exp16 = exp8 (same bias)
            mant16 = {mant8, 8'd0};  // Zero-extend mantissa
            fp16_out = {sign, exp8, mant16};
        end
    end

endmodule