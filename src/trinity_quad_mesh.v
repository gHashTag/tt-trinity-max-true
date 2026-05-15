`default_nettype none
// trinity_quad_mesh.v - 16-cell compute pool = 4× trinity_mesh_2x2 bank fan-out.
// Apache-2.0
//
// MAX-TRUE FLAGSHIP component. Splits a single packet bus across 4 parallel
// trinity_mesh_2x2 instances (= 4 banks × 4 GF16 tiles = 16 cells). Bank
// selector lives in lane[2:1] of the packet, preserving lane[0] for legacy
// operand_lane plumbing inside each tile and lane[3] for upstream cluster
// selection in trinity_max_true_dual.
//
// Routing contract:
//   lane[2:1] = bank_sel  -> picks 1 of 4 mesh_2x2 banks
//   lane[0]   = preserved -> passed unchanged to the selected bank
//   dst[27:26]= tile_id   -> selects 1 of 4 tiles inside the bank
//   payload   = unchanged
//
// Backward-compat: when only bank 0 is addressed, behaviour is byte-identical
// to a standalone trinity_mesh_2x2 (canonical 0x47C0 GF16 dot4 path preserved
// by the master FSM upstream).
//
// R-SI-1: zero NEW $mul. All multiplication lives inside legacy gf16_mul.v,
// grandfathered under TRI_NET_SHUTTLE_TRIAD.md Rule 2 / tt-trinity-gf16#4.
// Sacred Physics: bank routing is XOR/AND only — no analog mixing, no PLL
// drift, no float arithmetic.

`include "trinity_packet.vh"

module trinity_quad_mesh (
    input  wire                       clk,
    input  wire                       rst_n,

    // Host injection
    input  wire [`TRN_PKT_W-1:0]      host_in_pkt,
    input  wire                       host_in_valid,
    output wire                       host_in_ready,

    // Host ejection
    output wire [`TRN_PKT_W-1:0]      host_out_pkt,
    output wire                       host_out_valid,
    input  wire                       host_out_ready,

    // Debug: tile 0 result of bank 0 (preserves Mid debug contract)
    output wire [15:0]                dbg_tile0_result
);

    // ------------------------------------------------------------------
    // Bank selector: lane[2:1] = pkt[22:21]
    // ------------------------------------------------------------------
    wire [1:0] bank_sel = host_in_pkt[22:21];

    // Per-bank fan-out of host injection
    wire [3:0] bank_valid;
    wire [3:0] bank_ready;

    assign bank_valid[0] = host_in_valid && (bank_sel == 2'd0);
    assign bank_valid[1] = host_in_valid && (bank_sel == 2'd1);
    assign bank_valid[2] = host_in_valid && (bank_sel == 2'd2);
    assign bank_valid[3] = host_in_valid && (bank_sel == 2'd3);

    // Host-in is ready when the selected bank is ready
    assign host_in_ready =
        (bank_sel == 2'd0) ? bank_ready[0] :
        (bank_sel == 2'd1) ? bank_ready[1] :
        (bank_sel == 2'd2) ? bank_ready[2] :
                              bank_ready[3];

    // ------------------------------------------------------------------
    // Per-bank ejection
    // ------------------------------------------------------------------
    wire [`TRN_PKT_W-1:0] bank_out_pkt   [0:3];
    wire [3:0]            bank_out_valid;
    wire [3:0]            bank_out_ready;
    wire [15:0]           bank_dbg       [0:3];

    // Simple priority encoder for ejection: bank 0 > 1 > 2 > 3.
    // In steady state only one bank emits a RESULT/RECEIPT per cycle because
    // only one bank was injected into; this is conservative for v0.
    wire [1:0] eject_sel =
        bank_out_valid[0] ? 2'd0 :
        bank_out_valid[1] ? 2'd1 :
        bank_out_valid[2] ? 2'd2 :
                            2'd3;

    assign host_out_pkt =
        (eject_sel == 2'd0) ? bank_out_pkt[0] :
        (eject_sel == 2'd1) ? bank_out_pkt[1] :
        (eject_sel == 2'd2) ? bank_out_pkt[2] :
                              bank_out_pkt[3];

    assign host_out_valid = |bank_out_valid;

    assign bank_out_ready[0] = host_out_ready && (eject_sel == 2'd0);
    assign bank_out_ready[1] = host_out_ready && (eject_sel == 2'd1);
    assign bank_out_ready[2] = host_out_ready && (eject_sel == 2'd2);
    assign bank_out_ready[3] = host_out_ready && (eject_sel == 2'd3);

    // ------------------------------------------------------------------
    // 4× trinity_mesh_2x2 banks (= 16 GF16 cells total)
    // ------------------------------------------------------------------
    genvar b;
    generate
        for (b = 0; b < 4; b = b + 1) begin : g_bank
            trinity_mesh_2x2 u_bank (
                .clk             (clk),
                .rst_n           (rst_n),
                .host_in_pkt     (host_in_pkt),
                .host_in_valid   (bank_valid[b]),
                .host_in_ready   (bank_ready[b]),
                .host_out_pkt    (bank_out_pkt[b]),
                .host_out_valid  (bank_out_valid[b]),
                .host_out_ready  (bank_out_ready[b]),
                .dbg_tile0_result(bank_dbg[b])
            );
        end
    endgenerate

    assign dbg_tile0_result = bank_dbg[0];

    // Silence lint on unused bank debug
    wire _unused_qm = &{1'b0, bank_dbg[1], bank_dbg[2], bank_dbg[3], 1'b0};

endmodule
