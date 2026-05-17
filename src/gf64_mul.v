`default_nettype none
module gf64_mul (
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

    wire is_zero_a = (exp_a == 24'd0) && (mant_a == 39'd0);
    wire is_zero_b = (exp_b == 24'd0) && (mant_b == 39'd0);
    wire is_inf_a  = (exp_a == EXP_MAX) && (mant_a == 39'd0);
    wire is_inf_b  = (exp_b == EXP_MAX) && (mant_b == 39'd0);
    wire is_nan_a = (exp_a == EXP_MAX) && (mant_a != 39'd0);
    wire is_nan_b = (exp_b == EXP_MAX) && (mant_b != 39'd0);

    wire result_sign = sign_a ^ sign_b;

    reg [23:0] exp_product;
    reg [77:0] mant_product;
    reg [38:0] normalized_mant;
    reg [24:0] product_exp;
    reg       carry_out;

    always @(*) begin
        if (is_nan_a || is_nan_b)
            result = 64'hFFFFFFFFFF801;
        else if (is_inf_a && is_zero_b)
            result = 64'hFFFFFFFFFF801;
        else if (is_inf_b && is_zero_a)
            result = 64'hFFFFFFFFFF801;
        else if (is_inf_a || is_inf_b)
            result = result_sign ? 64'hFFFFFFFFFF800 : 64'h7FFFFFFFF800;
        else if (is_zero_a || is_zero_b)
            result = 64'h0000000000000000;
        else begin
            exp_product = {1'b0, exp_a} + {1'b0, exp_b} - BIAS;
            mant_product = {1'b1, mant_a} * {1'b1, mant_b};

            if (mant_product[77] || mant_product[76]) begin
                product_exp = exp_product + 25'd2;
                normalized_mant = mant_product[77:39];
                carry_out = mant_product[38];
            end else if (mant_product[75]) begin
                product_exp = exp_product + 25'd1;
                normalized_mant = mant_product[76:38];
                carry_out = mant_product[37];
            end else if (mant_product[74]) begin
                product_exp = exp_product;
                normalized_mant = mant_product[75:37];
                carry_out = mant_product[36];
            end else begin
                product_exp = exp_product - 25'd1;
                normalized_mant = mant_product[74:36];
                carry_out = mant_product[35];
            end

            if (carry_out) begin
                product_exp = product_exp + 25'd1;
                if (normalized_mant == 39'h7FFFFFFFFF)
                    result = result_sign ? 64'hFFFFFFFFFF800 : 64'h7FFFFFFFF800;
                else
                    result = {result_sign, product_exp[23:0], normalized_mant[38:0]};
            end else begin
                if (product_exp[24] || (product_exp[23:0] >= EXP_MAX))
                    result = result_sign ? 64'hFFFFFFFFFF800 : 64'h7FFFFFFFF800;
                else if (product_exp[23:0] == 24'd0)
                    result = {result_sign, 24'd0, 39'd0};
                else
                    result = {result_sign, product_exp[23:0], normalized_mant[38:0]};
            end
        end
    end

endmodule