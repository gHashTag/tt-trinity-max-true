`default_nettype none
// trinity_router_2x2.v - minimal single-hop packet crossbar (v0 of 2x2 mesh fabric).
// Apache-2.0
//
// This is NOT a full multi-hop XY router yet. It is an honest packet crossbar with:
//   - one host injection port + 4 tile ports
//   - destination decoded from packet DST field (2-bit flat tile id 0..3)
//   - round-robin arbitration on returning packets back to host
//
// Forward path (host -> tile): packet is offered to all 4 tile ports, but only one tile
// sees in_valid asserted (the addressed one). host_in_ready follows that tile's ready.
// Return path (tile -> host): single-slot output buffer, round-robin priority.

`include "trinity_packet.vh"

module trinity_router_2x2 (
    input  wire                       clk,
    input  wire                       rst_n,

    // Host injection port
    input  wire [`TRN_PKT_W-1:0]      host_in_pkt,
    input  wire                       host_in_valid,
    output wire                       host_in_ready,

    // Host ejection port (RESULT packets from tiles)
    output reg  [`TRN_PKT_W-1:0]      host_out_pkt,
    output reg                        host_out_valid,
    input  wire                       host_out_ready,

    // 4 tile fan-out (forward) - flat buses, tile i occupies bits [(i+1)*W-1 : i*W]
    output wire [4*`TRN_PKT_W-1:0]    t_pkt_flat,
    output wire [3:0]                 t_valid,
    input  wire [3:0]                 t_ready,

    // 4 tile fan-in (return)
    input  wire [4*`TRN_PKT_W-1:0]    t_ret_pkt_flat,
    input  wire [3:0]                 t_ret_valid,
    output wire [3:0]                 t_ret_ready
);

    // ---- Forward broadcast ----
    wire [1:0] dst = `TRN_PKT_DST(host_in_pkt);

    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_fwd
            assign t_pkt_flat[(gi+1)*`TRN_PKT_W-1 -: `TRN_PKT_W] = host_in_pkt;
            assign t_valid[gi] = host_in_valid && (dst == gi[1:0]);
        end
    endgenerate

    assign host_in_ready = (dst == 2'd0) ? t_ready[0] :
                           (dst == 2'd1) ? t_ready[1] :
                           (dst == 2'd2) ? t_ready[2] :
                                           t_ready[3];

    // ---- Return round-robin ----
    reg  [1:0] rr;
    reg  [1:0] sel;
    reg        sel_valid;

    wire [1:0] try0 = rr;
    wire [1:0] try1 = rr + 2'd1;
    wire [1:0] try2 = rr + 2'd2;
    wire [1:0] try3 = rr + 2'd3;

    always @(*) begin
        sel = 2'd0;
        sel_valid = 1'b0;
        if      (t_ret_valid[try0]) begin sel = try0; sel_valid = 1'b1; end
        else if (t_ret_valid[try1]) begin sel = try1; sel_valid = 1'b1; end
        else if (t_ret_valid[try2]) begin sel = try2; sel_valid = 1'b1; end
        else if (t_ret_valid[try3]) begin sel = try3; sel_valid = 1'b1; end
    end

    // Slice return packet bus
    wire [`TRN_PKT_W-1:0] ret_pkt0 = t_ret_pkt_flat[1*`TRN_PKT_W-1 -: `TRN_PKT_W];
    wire [`TRN_PKT_W-1:0] ret_pkt1 = t_ret_pkt_flat[2*`TRN_PKT_W-1 -: `TRN_PKT_W];
    wire [`TRN_PKT_W-1:0] ret_pkt2 = t_ret_pkt_flat[3*`TRN_PKT_W-1 -: `TRN_PKT_W];
    wire [`TRN_PKT_W-1:0] ret_pkt3 = t_ret_pkt_flat[4*`TRN_PKT_W-1 -: `TRN_PKT_W];

    wire [`TRN_PKT_W-1:0] sel_pkt = (sel == 2'd0) ? ret_pkt0 :
                                    (sel == 2'd1) ? ret_pkt1 :
                                    (sel == 2'd2) ? ret_pkt2 :
                                                    ret_pkt3;

    // Issue ready to selected tile only when buffer can accept this cycle
    wire buffer_can_accept = (!host_out_valid) || host_out_ready;

    assign t_ret_ready[0] = (sel == 2'd0) && sel_valid && buffer_can_accept;
    assign t_ret_ready[1] = (sel == 2'd1) && sel_valid && buffer_can_accept;
    assign t_ret_ready[2] = (sel == 2'd2) && sel_valid && buffer_can_accept;
    assign t_ret_ready[3] = (sel == 2'd3) && sel_valid && buffer_can_accept;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr <= 2'd0;
            host_out_pkt <= {`TRN_PKT_W{1'b0}};
            host_out_valid <= 1'b0;
        end else begin
            if (host_out_valid && host_out_ready)
                host_out_valid <= 1'b0;

            if (buffer_can_accept && sel_valid) begin
                host_out_pkt   <= sel_pkt;
                host_out_valid <= 1'b1;
                rr             <= sel + 2'd1;
            end
        end
    end

endmodule
