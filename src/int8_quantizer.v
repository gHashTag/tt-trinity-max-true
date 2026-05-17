`default_nettype none
module int8_quantizer (
    input  wire signed [31:0] value,
    input  wire [7:0]  scale,
    output reg  [7:0]  result
);

    wire signed [7:0] scaled = value >>> scale;

    always @(*) begin
        if (scaled > 8'd127)
            result = 8'd127;
        else if (scaled < -8'd128)
            result = 8'd128;
        else
            result = scaled[7:0];
    end

endmodule