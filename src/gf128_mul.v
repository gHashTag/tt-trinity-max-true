`default_nettype none
module gf128_mul (
    input  wire [127:0] a,
    input  wire [127:0] b,
    output reg  [127:0] result
);

    // GF128: 1 sign + 48 exp + 79 mant = 128 bits
    localparam BIAS    = 48'd140737488355327;
    localparam EXP_MAX = 48'd281474976710655;

    wire        sign_a = a[127];
    wire [47:0] exp_a  = a[126:79];
    wire [78:0] mant_a = a[78:0];
    wire        sign_b = b[127];
    wire [47:0] exp_b  = b[126:79];
    wire [78:0] mant_b = b[78:0];

    wire is_zero_a = (exp_a == 48'd0) && (mant_a == 79'd0);
    wire is_zero_b = (exp_b == 48'd0) && (mant_b == 79'd0);
    wire is_inf_a  = (exp_a == EXP_MAX) && (mant_a == 79'd0);
    wire is_inf_b  = (exp_b == EXP_MAX) && (mant_b == 79'd0);
    wire is_nan_a = (exp_a == EXP_MAX) && (mant_a != 79'd0);
    wire is_nan_b = (exp_b == EXP_MAX) && (mant_b != 79'd0);

    wire result_sign = sign_a ^ sign_b;

    reg [47:0] exp_product;
    reg [157:0] mant_product;
    reg [78:0] normalized_mant;
    reg [48:0] product_exp;
    reg       carry_out;

    always @(*) begin
        if (is_nan_a || is_nan_b)
            result = 128'hFFFFFFFFFFFFFFFFFFFFF801;
        else if (is_inf_a && is_zero_b)
            result = 128'hFFFFFFFFFFFFFFFFFFFFF801;
        else if (is_inf_b && is_zero_a)
            result = 128'hFFFFFFFFFFFFFFFFFFFFF801;
        else if (is_inf_a || is_inf_b)
            result = result_sign ? 128'hFFFFFFFFFFFFFFFFFFFFF800 : 128'h7FFFFFFFFFFFFFFFF800;
        else if (is_zero_a || is_zero_b)
            result = 128'h000000000000000000000000;
        else begin
            exp_product = {1'b0, exp_a} + {1'b0, exp_b} - BIAS;
            mant_product = {1'b1, mant_a} * {1'b1, mant_b};

            // Product normalization: find leading bits
            if (mant_product[157] || mant_product[156]) begin
                product_exp = exp_product + 49'd2;
                normalized_mant = mant_product[157:79];
                carry_out = mant_product[78];
            end else if (mant_product[155]) begin
                product_exp = exp_product + 49'd1;
                normalized_mant = mant_product[156:78];
                carry_out = mant_product[77];
            end else if (mant_product[154]) begin
                product_exp = exp_product;
                normalized_mant = mant_product[155:77];
                carry_out = mant_product[76];
            end else begin
                product_exp = exp_product - 49'd1;
                normalized_mant = mant_product[154:76];
                carry_out = mant_product[75];
            end

            if (carry_out) begin
                product_exp = product_exp + 49'd1;
                if (normalized_mant == 79'h7FFFFFFFFFFFFFFFFFF)
                    result = result_sign ? 128'hFFFFFFFFFFFFFFFFFFFFF800 : 128'h7FFFFFFFFFFFFFFFF800;
                else
                    result = {result_sign, product_exp[47:0], normalized_mant[78:0]};
            end else begin
                if (product_exp[48] || (product_exp[47:0] >= EXP_MAX))
                    result = result_sign ? 128'hFFFFFFFFFFFFFFFFFFFFF800 : 128'h7FFFFFFFFFFFFFFFF800;
                else if (product_exp[47:0] == 48'd0)
                    result = {result_sign, 48'd0, 79'd0};
                else
                    result = {result_sign, product_exp[47:0], normalized_mant[78:0]};
            end
        end
    end

endmodule