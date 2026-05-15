`default_nettype none
// ring27_memory.v — 27-cell circular ternary memory (3³ sacred constant)
// Apache-2.0
//
// PhD anchor: CANON_DE_ZIGFICATION / t27 RING spec. 27 = 3³.
// Each cell holds 2-bit ternary value. Single read port + single write port.
// On every clock with shift=1, the ring rotates by one position — a low-cost
// associative-memory primitive for VSA cleanup operations.

module ring27_memory (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        shift,           // rotate ring by one position
    input  wire        wr_en,
    input  wire [4:0]  addr,            // 0..26
    input  wire [1:0]  wr_data,
    output wire [1:0]  rd_data,
    output wire        ring_ok
);

    reg [1:0] cells [0:26];
    integer i;

    assign rd_data = (addr < 5'd27) ? cells[addr] : 2'b10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Seed pattern: alternating +1, -1, 0 (canonical Trinity ternary frame)
            for (i = 0; i < 27; i = i + 1) begin
                case (i % 3)
                    0: cells[i] <= 2'b00;  // +1
                    1: cells[i] <= 2'b01;  // -1
                    default: cells[i] <= 2'b10;  // 0
                endcase
            end
        end else begin
            if (wr_en && addr < 5'd27)
                cells[addr] <= wr_data;
            if (shift) begin
                // Rotate left by one
                cells[0] <= cells[26];
                for (i = 1; i < 27; i = i + 1)
                    cells[i] <= cells[i-1];
            end
        end
    end

    assign ring_ok = 1'b1;

endmodule
