`default_nettype none
// crc32_receipt.v — CRC-32 RECEIPT checksum
// Apache-2.0
//
// Polynomial: 0x04C11DB7 (IEEE 802.3, CRC-32). Bit-serial implementation; one
// byte per cycle when `valid` is asserted. Total budget ~250 gates.
//
// Initial value: 0xFFFFFFFF. Final value: bit-reversed, XORed with 0xFFFFFFFF
// per IEEE 802.3 convention. We expose the raw register too for low-level testing.

module crc32_receipt (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,        // synchronous reset of CRC state
    input  wire        valid,        // byte_in is valid this cycle
    input  wire [7:0]  byte_in,
    output reg  [31:0] crc_raw,
    output wire [31:0] crc_final     // bit-reversed, XOR 0xFFFFFFFF
);

    integer i;
    reg [31:0] next;
    reg [7:0]  b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_raw <= 32'hFFFFFFFF;
        end else if (start) begin
            crc_raw <= 32'hFFFFFFFF;
        end else if (valid) begin
            next = crc_raw;
            // Reflect input byte (LSB first per IEEE 802.3)
            b = {byte_in[0], byte_in[1], byte_in[2], byte_in[3],
                 byte_in[4], byte_in[5], byte_in[6], byte_in[7]};
            next = next ^ {b, 24'h000000};
            for (i = 0; i < 8; i = i + 1) begin
                if (next[31]) next = (next << 1) ^ 32'h04C11DB7;
                else          next = (next << 1);
            end
            crc_raw <= next;
        end
    end

    // Final = reflect(crc_raw) ^ 0xFFFFFFFF
    genvar g;
    wire [31:0] rev;
    generate
        for (g = 0; g < 32; g = g + 1) begin : g_rev
            assign rev[g] = crc_raw[31 - g];
        end
    endgenerate
    assign crc_final = rev ^ 32'hFFFFFFFF;

endmodule
