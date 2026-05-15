`default_nettype none
// trinity_usb3_fifo_bridge.v
// Apache-2.0
//
// Boundary stub for the FTDI FT60x ("FT600"/"FT601") synchronous-FIFO USB-3 link.
// This is NOT yet a full FT601 controller. It is a synthesizable shim that turns the
// `(rxf_n, txe_n, rd_n, wr_n, oe_n, data[31:0])` 245-style FIFO interface into the
// Trinity 32-bit packet handshake `(pkt, valid, ready)` used by `trinity_router_2x2`.
//
// In v0 (this PR) the bridge is a SAFE pass-through skeleton:
//   - On host->FPGA: when the FT60x asserts RXF# (== data available) and the Trinity
//     side is ready, the bridge reads one 32-bit word and presents it as one packet.
//   - On FPGA->host: when the Trinity side has a valid packet and TXE# (== room
//     available) is asserted, the bridge drives one 32-bit word out.
//
// Things deliberately LEFT AS TODO until a real carrier board exists:
//   - precise FT601 RD#/WR# / OE# turn-around timing (see FT60x datasheet "Timing
//     Characteristics" tables).
//   - byte-enables (`BE[3:0]`) for short-packet alignment.
//   - clock-domain crossing between the FT60x 100 MHz `ft_clk` and the Trinity
//     50 MHz `clk` (here we ASSUME they are the same domain; the real bridge will
//     need an async FIFO).
//   - back-pressure on bursts and OE# tri-state direction control on a real PCB.
//
// This module is NOT instantiated by `tt_um_ghtag_trinity_gf16` — TinyTapeout has no
// FT60x lines. It is intended to be instantiated by a future board-top wrapper
// (e.g. QMTECH XC7A100T carrier with an FT601 daughterboard). It compiles stand-alone
// so the boundary contract is type-checked today.

`include "trinity_packet.vh"

module trinity_usb3_fifo_bridge (
    input  wire                       clk,
    input  wire                       rst_n,

    // ---- FT60x "245-sync" FIFO side (external pins on a future board) ----
    // Per FTDI convention these are active-LOW.
    input  wire                       ft_rxf_n,    // host->FPGA data available
    input  wire                       ft_txe_n,    // FPGA->host space available
    output wire                       ft_rd_n,     // assert to pop a word from FT60x
    output wire                       ft_wr_n,     // assert to push a word to FT60x
    output wire                       ft_oe_n,     // OE# for bus direction (read=0)
    inout  wire [31:0]                ft_data,     // 32-bit bidirectional bus

    // ---- Trinity packet side (host injection/ejection on the router) ----
    output reg  [`TRN_PKT_W-1:0]      host_in_pkt,
    output reg                        host_in_valid,
    input  wire                       host_in_ready,

    input  wire [`TRN_PKT_W-1:0]      host_out_pkt,
    input  wire                       host_out_valid,
    output wire                       host_out_ready
);

    // ---- Bus direction ----
    // Read from FT60x when it has data AND we can forward it on. Otherwise default
    // to "drive FPGA->host" so we can issue WR# when we have a packet to send.
    //
    // Half-duplex arbitration: ft_data is bidirectional and OE# is shared, so the
    // bridge MUST NOT read and write in the same cycle. We round-robin: a sticky
    // `dir_write` toggle flips after every accepted transfer so a steady stream of
    // host operands cannot starve the result drain (and vice versa).
    reg  dir_write;
    wire can_read  = (~ft_rxf_n) && (~host_in_valid || host_in_ready);
    wire can_write = (~ft_txe_n) &&  host_out_valid;
    wire do_read   = can_read  && (!can_write || !dir_write);
    wire do_write  = can_write && (!can_read  ||  dir_write);

    assign ft_oe_n  = ~do_read;             // OE# low when reading
    assign ft_rd_n  = ~do_read;             // RD# low for one cycle per word (skeleton)
    assign ft_wr_n  = ~do_write;            // WR# low for one cycle per word (skeleton)

    // Drive the bus only when writing; tri-state otherwise.
    assign ft_data  = do_write ? host_out_pkt : 32'hzzzzzzzz;

    // ---- Host -> FPGA: one FIFO word becomes one Trinity packet ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            host_in_pkt   <= {`TRN_PKT_W{1'b0}};
            host_in_valid <= 1'b0;
            dir_write     <= 1'b0;
        end else begin
            // Accepted by router -> drop valid
            if (host_in_valid && host_in_ready)
                host_in_valid <= 1'b0;

            if (do_read) begin
                host_in_pkt   <= ft_data;
                host_in_valid <= 1'b1;
                dir_write     <= 1'b1;   // give writer a turn next cycle
            end else if (do_write) begin
                dir_write     <= 1'b0;   // give reader a turn next cycle
            end
        end
    end

    // ---- FPGA -> host: ready iff TXE# tells us the FT60x has space.
    assign host_out_ready = ~ft_txe_n;

    // Silence lint on unused signals (the skeleton does not yet use them all)
    wire _unused = &{1'b0, 1'b0};

endmodule
