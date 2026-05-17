`default_nettype none
module gf20_mul (
    input  wire [19:0] a,
    input  wire [19:0] b,
    output reg  [19:0] result
);

    // GF20: 1 sign + 7 exp + 12 mant = 20 bits
    localparam BIAS    = 7'd63;
    localparam EXP_MAX = 7'd127;

    wire        sign_a = a[19];
    wire [6:0]  exp_a  = a[18:12];
    wire [11:0] mant_a = a[11:0];
    wire        sign_b = b[19];
    wire [6:0]  exp_b  = b[18:12];
    wire [11:0] mant_b = b[11:0];

    wire is_zero_a = (exp_a == 7'd0) && (mant_a == 12'd0);
    wire is_zero_b = (exp_b == 7'd0) && (mant_b == 12'd0);
    wire is_inf_a  = (exp_a == EXP_MAX) && (mant_a == 12'd0);
    wire is_inf_b  = (exp_b == EXP_MAX) && (mant_b == 12'd0);
    wire is_nan_a  = (exp_a == EXP_MAX) && (mant_a != 12'd0);
    wire is_nan_b  = (exp_b == EXP_MAX) && (mant_b != 12'd0);

    wire result_sign = sign_a ^ sign_b;

    reg [6:0]  exp_product;
    reg [23:0] mant_product;
    reg [11:0] normalized_mant;
    reg [7:0]  product_exp;
    reg        carry_out;

    always @(*) begin
        if (is_nan_a || is_nan_b)
            result = 20'hFF801;
        else if (is_inf_a && is_zero_b)
            result = 20'hFF801;
        else if (is_inf_b && is_zero_a)
            result = 20'hFF801;
        else if (is_inf_a || is_inf_b)
            result = result_sign ? 20'hFF800 : 20'h7F800;
        else if (is_zero_a || is_zero_b)
            result = 20'h00000;
        else begin
            exp_product = {1'b0, exp_a} + {1'b0, exp_b} - BIAS;
            mant_product = {1'b1, mant_a} * {1'b1, mant_b};

            if (mant_product[23] || mant_product[22]) begin
                product_exp = exp_product + 8'd2;
                normalized_mant = mant_product[23:12];
                carry_out = mant_product[11];
            end else if (mant_product[21]) begin
                product_exp = exp_product + 8'd1;
                normalized_mant = mant_product[22:11];
                carry_out = mant_product[10];
            end else if (mant_product[20]) begin
                product_exp = exp_product;
                normalized_mant = mant_product[21:10];
                carry_out = mant_product[9];
            end else begin
                product_exp = exp_product - 8'd1;
                normalized_mant = mant_product[20:9];
                carry_out = mant_product[8];
            end

            if (carry_out) begin
                product_exp = product_exp + 8'd1;
                if (normalized_mant == 12'hFFF)
                    result = result_sign ? 20'hFF800 : 20'h7F800;
                else
                    result = {result_sign, product_exp[6:0], normalized_mant[11:0]};
            end else begin
                if (product_exp[7] || (product_exp[6:0] >= EXP_MAX))
                    result = result_sign ? 20'hFF800 : 20'h7F800;
                else if (product_exp[6:0] == 7'd0)
                    result = {result_sign, 7'd0, 12'd0};
                else
                    result = {result_sign, product_exp[6:0], normalized_mant[11:0]};
            end
        end
    end

endmodule