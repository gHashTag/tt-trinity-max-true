`default_nettype none
module gf32_mul (
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

    wire is_zero_a = (exp_a == 12'd0) && (mant_a == 19'd0);
    wire is_zero_b = (exp_b == 12'd0) && (mant_b == 19'd0);
    wire is_inf_a  = (exp_a == EXP_MAX) && (mant_a == 19'd0);
    wire is_inf_b = (exp_b == EXP_MAX) && (mant_b == 19'd0);
    wire is_nan_a = (exp_a == EXP_MAX) && (mant_a != 19'd0);
    wire is_nan_b = (exp_b == EXP_MAX) && (mant_b != 19'd0);

    wire result_sign = sign_a ^ sign_b;

    reg [11:0] exp_product;
    reg [37:0] mant_product;
    reg [18:0] normalized_mant;
    reg [12:0] product_exp;
    reg       carry_out;

    always @(*) begin
        if (is_nan_a || is_nan_b)
            result = 32'hFFFFF801;
        else if (is_inf_a && is_zero_b)
            result = 32'hFFFFF801;
        else if (is_inf_b && is_zero_a)
            result = 32'hFFFFF801;
        else if (is_inf_a || is_inf_b)
            result = result_sign ? 32'hFFFFF800 : 32'h7FFF8000;
        else if (is_zero_a || is_zero_b)
            result = 32'h00000000;
        else begin
            exp_product = {1'b0, exp_a} + {1'b0, exp_b} - BIAS;
            mant_product = {1'b1, mant_a} * {1'b1, mant_b};

            if (mant_product[37] || mant_product[36]) begin
                product_exp = exp_product + 13'd2;
                normalized_mant = mant_product[37:19];
                carry_out = mant_product[18];
            end else if (mant_product[35]) begin
                product_exp = exp_product + 13'd1;
                normalized_mant = mant_product[36:18];
                carry_out = mant_product[17];
            end else if (mant_product[34]) begin
                product_exp = exp_product;
                normalized_mant = mant_product[35:17];
                carry_out = mant_product[16];
            end else begin
                product_exp = exp_product - 13'd1;
                normalized_mant = mant_product[34:16];
                carry_out = mant_product[15];
            end

            if (carry_out) begin
                product_exp = product_exp + 13'd1;
                if (normalized_mant == 19'h7FFFF)
                    result = result_sign ? 32'hFFFFF800 : 32'h7FFF8000;
                else
                    result = {result_sign, product_exp[11:0], normalized_mant[18:0]};
            end else begin
                if (product_exp[12] || (product_exp[11:0] >= EXP_MAX))
                    result = result_sign ? 32'hFFFFF800 : 32'h7FFF8000;
                else if (product_exp[11:0] == 12'd0)
                    result = {result_sign, 12'd0, 19'd0};
                else
                    result = {result_sign, product_exp[11:0], normalized_mant[18:0]};
            end
        end
    end

endmodule