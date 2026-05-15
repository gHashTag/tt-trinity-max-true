`default_nettype none
// trinity_mesh_adapter_stub.v
// Apache-2.0
//
// Boundary stub for an external radio / backhaul module (LoRa, ESP32 Wi-Fi,
// BLE-mesh, etc.). The radio itself lives OFF the die. This shim turns a
// simple framed serial-byte interface to that external module into the
// Trinity 32-bit packet handshake `(pkt, valid, ready)`.
//
// This is a deliberate non-PHY:
//   - NO LoRa modem in fabric. No Wi-Fi PHY. No DSP/RF in the FPGA.
//   - The external radio (SX1262 / ESP32-C6 / ...) is reached over an
//     ordinary SPI or UART link from the carrier board.
//   - This stub assumes the simplest model: a byte-aligned framed link
//     where the radio MCU pushes one 32-bit Trinity packet at a time
//     after it has reassembled an RF frame. That is enough to validate
//     the on-die packet API for the future G3 "2-node mesh" gate.
//
// In v0 the module is a SAFE pass-through: each accepted ingress word
// becomes a Trinity packet on `host_in_pkt`; each Trinity packet on
// `host_out_pkt` is offered to the egress word port. Real framing,
// CRC, retransmit, and multi-hop XY routing are deferred to gates G3/G5.
//
// This module is NOT instantiated by `tt_um_ghtag_trinity_gf16`. It is
// intended for a future board top.

`include "trinity_packet.vh"

module trinity_mesh_adapter_stub (
    input  wire                       clk,
    input  wire                       rst_n,

    // ---- External-radio "wire" side (typically driven by an MCU/radio SoC
    //      that has already reassembled a frame into one 32-bit word).
    input  wire [`TRN_PKT_W-1:0]      ext_in_word,
    input  wire                       ext_in_valid,
    output wire                       ext_in_ready,

    output wire [`TRN_PKT_W-1:0]      ext_out_word,
    output wire                       ext_out_valid,
    input  wire                       ext_out_ready,

    // ---- Trinity packet side (host injection/ejection on the router) ----
    output reg  [`TRN_PKT_W-1:0]      host_in_pkt,
    output reg                        host_in_valid,
    input  wire                       host_in_ready,

    input  wire [`TRN_PKT_W-1:0]      host_out_pkt,
    input  wire                       host_out_valid,
    output wire                       host_out_ready
);

    // ---- ext -> Trinity (ingress) ----
    // Accept a word when the router can take it now (or we have no pending
    // word). One word in == one packet in.
    assign ext_in_ready = ~host_in_valid || host_in_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            host_in_pkt   <= {`TRN_PKT_W{1'b0}};
            host_in_valid <= 1'b0;
        end else begin
            if (host_in_valid && host_in_ready)
                host_in_valid <= 1'b0;

            if (ext_in_valid && ext_in_ready) begin
                host_in_pkt   <= ext_in_word;
                host_in_valid <= 1'b1;
            end
        end
    end

    // ---- Trinity -> ext (egress) ----
    // Direct passthrough: the external link is treated as transparent.
    assign ext_out_word   = host_out_pkt;
    assign ext_out_valid  = host_out_valid;
    assign host_out_ready = ext_out_ready;

    // Silence lint
    wire _unused = &{1'b0, 1'b0};

endmodule
