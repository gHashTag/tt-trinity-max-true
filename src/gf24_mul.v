`default_nettype none
module gf24_mul (
    input  wire [23:0] a,
    input  wire [23:0] b,
    output reg  [23:0] result
);

    localparam BIAS    = 9'd255;
    localparam EXP_MAX = 9'd511;

    wire        sign_a = a[23];
    wire [8:0]  exp_a  = a[22:14];
    wire [13:0] mant_a = a[13:0];
    wire        sign_b = b[23];
    wire [8:0]  exp_b  = b[22:14];
    wire [13:0] mant_b = b[13:0];

    wire is_zero_a = (exp_a == 9'd0) && (mant_a == 14'd0);
    wire is_zero_b = (exp_b == 9'd0) && (mant_b == 14'd0);
    wire is_inf_a  = (exp_a == EXP_MAX) && (mant_a == 14'd0);
    wire is_inf_b = (exp_b == EXP_MAX) && (mant_b == 14'd0);
    wire is_nan_a = (exp_a == EXP_MAX) && (mant_a != 14'd0);
    wire is_nan_b = (exp_b == EXP_MAX) && (mant_b != 14'd0);

    wire result_sign = sign_a ^ sign_b;

    reg [8:0]  exp_product;
    reg [27:0] mant_product;
    reg [13:0] normalized_mant;
    reg [9:0]  product_exp;
    reg        carry_out;

    always @(*) begin
        if (is_nan_a || is_nan_b)
            result = 24'hFFF801;
        else if (is_inf_a && is_zero_b)
            result = 24'hFFF801;
        else if (is_inf_b && is_zero_a)
            result = 24'hFFF801;
        else if (is_inf_a || is_inf_b)
            result = result_sign ? 24'hFFF800 : 24'h7FF800;
        else if (is_zero_a || is_zero_b)
            result = 24'h000000;
        else begin
            exp_product = {1'b0, exp_a} + {1'b0, exp_b} - BIAS;
            mant_product = {1'b1, mant_a} * {1'b1, mant_b};

            if (mant_product[27] || mant_product[26]) begin
                product_exp = exp_product + 10'd2;
                normalized_mant = mant_product[27:14];
                carry_out = mant_product[13];
            end else if (mant_product[25]) begin
                product_exp = exp_product + 10'd1;
                normalized_mant = mant_product[26:13];
                carry_out = mant_product[12];
            end else if (mant_product[24]) begin
                product_exp = exp_product;
                normalized_mant = mant_product[25:12];
                carry_out = mant_product[11];
            end else begin
                product_exp = exp_product - 10'd1;
                normalized_mant = mant_product[24:11];
                carry_out = mant_product[10];
            end

            if (carry_out) begin
                product_exp = product_exp + 10'd1;
                if (normalized_mant == 14'h3FFF)
                    result = result_sign ? 24'hFFF800 : 24'h7FF800;
                else
                    result = {result_sign, product_exp[8:0], normalized_mant[13:0]};
            end else begin
                if (product_exp[9] || (product_exp[8:0] >= EXP_MAX))
                    result = result_sign ? 24'hFFF800 : 24'h7FF800;
                else if (product_exp[8:0] == 9'd0)
                    result = {result_sign, 9'd0, 14'd0};
                else
                    result = {result_sign, product_exp[8:0], normalized_mant[13:0]};
            end
        end
    end

endmodule