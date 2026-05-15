`default_nettype none
// gf16_mesh_2x2_top.v — L-S38 TTSKY26c 2×2 GF16 mesh top
// Integrates 4 × trinity_gf16_tile (DOT_WIDTH=4 for canonical 0x47C0 dot4 compliance)
// with a round-robin NoC stub providing North/South/East/West link handshake ports.
//
// Tile layout (flat 2-bit tile_id):
//   tile_id 2'b00 → row=0,col=0  (NW)
//   tile_id 2'b01 → row=0,col=1  (NE)
//   tile_id 2'b10 → row=1,col=0  (SW)
//   tile_id 2'b11 → row=1,col=1  (SE)
//
// NoC stub: North/South/East/West 4-bit data flit + req/ack handshake.
// Round-robin arbitration: combinational, no `*`, no DSP (R-SI-1).
// Pipeline FFs tagged (* keep *)(* no_retiming *) per silicon spec.
//
// Apache-2.0
// DOI: 10.5281/zenodo.19227877

`include "trinity_packet.vh"

module gf16_mesh_2x2_top (
    input  wire                    clk,
    input  wire                    rst_n,

    // Host injection (to tiles via internal router)
    input  wire [`TRN_PKT_W-1:0]   host_in_pkt,
    input  wire                    host_in_valid,
    output wire                    host_in_ready,

    // Host ejection (result packets from tiles)
    output wire [`TRN_PKT_W-1:0]   host_out_pkt,
    output wire                    host_out_valid,
    input  wire                    host_out_ready,

    // ── NoC stub ports (4-bit flit + req/ack) ──────────────────────────────
    // North link (mesh north boundary)
    input  wire [3:0]              noc_north_flit_in,
    input  wire                    noc_north_req_in,
    output wire                    noc_north_ack_out,
    output wire [3:0]              noc_north_flit_out,
    output wire                    noc_north_req_out,
    input  wire                    noc_north_ack_in,

    // South link
    input  wire [3:0]              noc_south_flit_in,
    input  wire                    noc_south_req_in,
    output wire                    noc_south_ack_out,
    output wire [3:0]              noc_south_flit_out,
    output wire                    noc_south_req_out,
    input  wire                    noc_south_ack_in,

    // East link
    input  wire [3:0]              noc_east_flit_in,
    input  wire                    noc_east_req_in,
    output wire                    noc_east_ack_out,
    output wire [3:0]              noc_east_flit_out,
    output wire                    noc_east_req_out,
    input  wire                    noc_east_ack_in,

    // West link
    input  wire [3:0]              noc_west_flit_in,
    input  wire                    noc_west_req_in,
    output wire                    noc_west_ack_out,
    output wire [3:0]              noc_west_flit_out,
    output wire                    noc_west_req_out,
    input  wire                    noc_west_ack_in,

    // Debug: per-tile result visibility
    output wire [15:0]             dbg_tile0_result,
    output wire [15:0]             dbg_tile1_result,
    output wire [15:0]             dbg_tile2_result,
    output wire [15:0]             dbg_tile3_result
);

    // =========================================================================
    // Internal router buses
    // =========================================================================
    wire [4*`TRN_PKT_W-1:0] t_pkt_flat;     // router → tiles (forward)
    wire [3:0]               t_valid;
    wire [3:0]               t_ready;

    wire [4*`TRN_PKT_W-1:0] t_ret_pkt_flat; // tiles → router (return)
    wire [3:0]               t_ret_valid;
    wire [3:0]               t_ret_ready;

    // =========================================================================
    // Router: single-hop round-robin crossbar (reuses existing trinity_router_2x2)
    // =========================================================================
    trinity_router_2x2 u_router (
        .clk             (clk),
        .rst_n           (rst_n),
        .host_in_pkt     (host_in_pkt),
        .host_in_valid   (host_in_valid),
        .host_in_ready   (host_in_ready),
        .host_out_pkt    (host_out_pkt),
        .host_out_valid  (host_out_valid),
        .host_out_ready  (host_out_ready),
        .t_pkt_flat      (t_pkt_flat),
        .t_valid         (t_valid),
        .t_ready         (t_ready),
        .t_ret_pkt_flat  (t_ret_pkt_flat),
        .t_ret_valid     (t_ret_valid),
        .t_ret_ready     (t_ret_ready)
    );

    // =========================================================================
    // 4 × GF16 tiles — DOT_WIDTH=4 (canonical dot4, 0x47C0 vector compliant)
    // =========================================================================
    wire [`TRN_PKT_W-1:0] t_in_pkt  [0:3];
    wire [`TRN_PKT_W-1:0] t_out_pkt [0:3];
    wire [15:0]            tile_dbg  [0:3];

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : g_tile
            assign t_in_pkt[i] = t_pkt_flat[(i+1)*`TRN_PKT_W-1 -: `TRN_PKT_W];
            assign t_ret_pkt_flat[(i+1)*`TRN_PKT_W-1 -: `TRN_PKT_W] = t_out_pkt[i];

            trinity_gf16_tile #(
                .TILE_ID  (i[1:0]),
                .DOT_WIDTH(4)        // canonical dot4; no DSP/`*` (R-SI-1)
            ) u_tile (
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
    assign dbg_tile1_result = tile_dbg[1];
    assign dbg_tile2_result = tile_dbg[2];
    assign dbg_tile3_result = tile_dbg[3];

    // =========================================================================
    // NoC stub — North/South/East/West boundary handshake + round-robin arbitration
    // 4-bit flit, req/ack protocol.
    // Input flits are round-robin collected into a small holding register and
    // looped back (stub: no actual routing to tiles for boundary traffic).
    // Pipeline FFs tagged (* keep *)(* no_retiming *).
    // R-SI-1: only shifts/muxes — no `*` or DSP.
    // =========================================================================

    // RR counter for input arbitration: 2-bit, no `*`
    (* keep *)(* no_retiming *) reg [1:0] noc_rr_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            noc_rr_q <= 2'b00;
        else begin
            // Increment RR pointer when any incoming request is active
            if (noc_north_req_in | noc_south_req_in | noc_east_req_in | noc_west_req_in)
                noc_rr_q <= noc_rr_q + 2'b01;
        end
    end

    // Holding register for selected inbound flit
    (* keep *)(* no_retiming *) reg [3:0] noc_flit_hold_q;
    (* keep *)(* no_retiming *) reg       noc_hold_valid_q;

    // Round-robin select: combinational, no `*`
    wire [1:0] rr_sel = noc_rr_q;
    wire       sel_north = (rr_sel == 2'b00) && noc_north_req_in;
    wire       sel_south = (rr_sel == 2'b01) && noc_south_req_in;
    wire       sel_east  = (rr_sel == 2'b10) && noc_east_req_in;
    wire       sel_west  = (rr_sel == 2'b11) && noc_west_req_in;

    wire [3:0] sel_flit =
        sel_north ? noc_north_flit_in :
        sel_south ? noc_south_flit_in :
        sel_east  ? noc_east_flit_in  :
        sel_west  ? noc_west_flit_in  :
                    4'h0;

    wire sel_any = sel_north | sel_south | sel_east | sel_west;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            noc_flit_hold_q  <= 4'h0;
            noc_hold_valid_q <= 1'b0;
        end else begin
            if (sel_any) begin
                noc_flit_hold_q  <= sel_flit;
                noc_hold_valid_q <= 1'b1;
            end else begin
                noc_hold_valid_q <= 1'b0;
            end
        end
    end

    // ACK back to sender (stub: immediately ack when selected)
    assign noc_north_ack_out = sel_north;
    assign noc_south_ack_out = sel_south;
    assign noc_east_ack_out  = sel_east;
    assign noc_west_ack_out  = sel_west;

    // Output: broadcast held flit to all boundary directions (stub passthrough)
    // req_out asserts when hold_valid is high and peer ack is not blocking
    assign noc_north_flit_out = noc_flit_hold_q;
    assign noc_south_flit_out = noc_flit_hold_q;
    assign noc_east_flit_out  = noc_flit_hold_q;
    assign noc_west_flit_out  = noc_flit_hold_q;

    assign noc_north_req_out  = noc_hold_valid_q & ~noc_north_ack_in;
    assign noc_south_req_out  = noc_hold_valid_q & ~noc_south_ack_in;
    assign noc_east_req_out   = noc_hold_valid_q & ~noc_east_ack_in;
    assign noc_west_req_out   = noc_hold_valid_q & ~noc_west_ack_in;

endmodule
