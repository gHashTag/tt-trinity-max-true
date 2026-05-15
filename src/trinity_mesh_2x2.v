`default_nettype none
// trinity_mesh_2x2.v - v0 mesh fabric: 4 GF16 tiles + 1 router with host injection/ejection.
// Apache-2.0
//
// This is the smallest real packet fabric: 4 addressable compute tiles behind one crossbar.
// It is honestly NOT a multi-hop 2D mesh; the path "router_2x2" is the placeholder name
// while pinout/topology are stabilised. A future trinity_router_xy.v will replace the
// crossbar without changing tile/host contracts.

`include "trinity_packet.vh"

module trinity_mesh_2x2 (
    input  wire                       clk,
    input  wire                       rst_n,

    // Host injection (issue packets to tiles)
    input  wire [`TRN_PKT_W-1:0]      host_in_pkt,
    input  wire                       host_in_valid,
    output wire                       host_in_ready,

    // Host ejection (RESULT packets from tiles)
    output wire [`TRN_PKT_W-1:0]      host_out_pkt,
    output wire                       host_out_valid,
    input  wire                       host_out_ready,

    // Debug
    output wire [15:0]                dbg_tile0_result
);

    wire [4*`TRN_PKT_W-1:0] t_pkt_flat;
    wire [3:0]              t_valid;
    wire [3:0]              t_ready;

    wire [4*`TRN_PKT_W-1:0] t_ret_pkt_flat;
    wire [3:0]              t_ret_valid;
    wire [3:0]              t_ret_ready;

    trinity_router_2x2 u_router (
        .clk            (clk),
        .rst_n          (rst_n),
        .host_in_pkt    (host_in_pkt),
        .host_in_valid  (host_in_valid),
        .host_in_ready  (host_in_ready),
        .host_out_pkt   (host_out_pkt),
        .host_out_valid (host_out_valid),
        .host_out_ready (host_out_ready),
        .t_pkt_flat     (t_pkt_flat),
        .t_valid        (t_valid),
        .t_ready        (t_ready),
        .t_ret_pkt_flat (t_ret_pkt_flat),
        .t_ret_valid    (t_ret_valid),
        .t_ret_ready    (t_ret_ready)
    );

    // Per-tile wires (sliced from the flat buses)
    wire [`TRN_PKT_W-1:0] t_in_pkt   [0:3];
    wire [`TRN_PKT_W-1:0] t_out_pkt  [0:3];
    wire [15:0]           tile_dbg   [0:3];

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : g_tile
            assign t_in_pkt[i] = t_pkt_flat[(i+1)*`TRN_PKT_W-1 -: `TRN_PKT_W];
            assign t_ret_pkt_flat[(i+1)*`TRN_PKT_W-1 -: `TRN_PKT_W] = t_out_pkt[i];

            // L-S20: enable DOT_WIDTH=8 (gf16_dot8 = 2x dot4 + adder) for 2x TOPS/tile.
            // Backwards compat: top-level legacy gf16_dot4 instance and the 0x47C0
            // canonical test path are independent of this tile parameter.
            trinity_gf16_tile #(.TILE_ID(i[1:0]), .DOT_WIDTH(8)) u_tile (
                .clk        (clk),
                .rst_n      (rst_n),
                .in_pkt     (t_in_pkt[i]),
                .in_valid   (t_valid[i]),
                .in_ready   (t_ready[i]),
                .out_pkt    (t_out_pkt[i]),
                .out_valid  (t_ret_valid[i]),
                .out_ready  (t_ret_ready[i]),
                .dbg_result (tile_dbg[i])
            );
        end
    endgenerate

    assign dbg_tile0_result = tile_dbg[0];

endmodule
