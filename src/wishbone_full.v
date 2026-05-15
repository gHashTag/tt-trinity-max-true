`default_nettype none
// wishbone_full.v — Wishbone B4-lite full read/write peripheral hub
// Apache-2.0
//
// PhD anchor: Wave 7 (Trinity SoC) preview — host-controlled register access.
// Provides 16 read/write addressable 8-bit registers. Bus protocol is a
// minimal subset of Wishbone B4 (CYC + STB + WE + ADR + DAT_W → DAT_R + ACK).
// Designed for ~600 gates; lives behind the existing TT pins via load_mode
// multiplexer.

module wishbone_full (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        wb_cyc,
    input  wire        wb_stb,
    input  wire        wb_we,
    input  wire [3:0]  wb_adr,
    input  wire [7:0]  wb_dat_w,
    output reg  [7:0]  wb_dat_r,
    output reg         wb_ack,
    // Probe inputs from upstream modules (status snapshot)
    input  wire [7:0]  status_byte,
    input  wire [7:0]  matmul_lo,        // matmul C[0][0] low byte
    input  wire [7:0]  rcpt_chk,
    input  wire [7:0]  bpb_lo,           // BPB total_loss low byte
    output wire        wb_ok
);

    reg [7:0] regs [0:15];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_dat_r <= 8'b0;
            wb_ack   <= 1'b0;
            for (i = 0; i < 16; i = i + 1) regs[i] <= 8'b0;
        end else begin
            wb_ack <= 1'b0;
            // Refresh read-only mirror registers each cycle
            regs[0] <= status_byte;
            regs[1] <= matmul_lo;
            regs[2] <= rcpt_chk;
            regs[3] <= bpb_lo;
            // regs[4..15] writable scratch
            if (wb_cyc && wb_stb && !wb_ack) begin
                if (wb_we && wb_adr >= 4'd4) begin
                    regs[wb_adr] <= wb_dat_w;
                end
                wb_dat_r <= regs[wb_adr];
                wb_ack   <= 1'b1;
            end
        end
    end

    assign wb_ok = 1'b1;

endmodule
