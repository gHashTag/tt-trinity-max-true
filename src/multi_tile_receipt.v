`default_nettype none
// multi_tile_receipt.v — fan-in tree for RECEIPTs from all 4 mesh tiles
// Apache-2.0
//
// PhD anchor: Chapter 12 / DePIN — multi-tile attestability.
// Combines per-tile RECEIPT inputs (job_id, tile_id, checksum) into a single
// XOR-summed aggregate. Asserts all_attested when every tile has produced
// at least one valid receipt since reset.

module multi_tile_receipt (
    input  wire        clk,
    input  wire        rst_n,
    // Per-tile inputs (4 tiles)
    input  wire        t0_valid,
    input  wire [7:0]  t0_checksum,
    input  wire [7:0]  t0_job_id,
    input  wire        t1_valid,
    input  wire [7:0]  t1_checksum,
    input  wire [7:0]  t1_job_id,
    input  wire        t2_valid,
    input  wire [7:0]  t2_checksum,
    input  wire [7:0]  t2_job_id,
    input  wire        t3_valid,
    input  wire [7:0]  t3_checksum,
    input  wire [7:0]  t3_job_id,
    // Aggregated outputs
    output reg  [7:0]  agg_checksum,
    output reg  [7:0]  agg_job_id,
    output reg  [3:0]  attested_mask,    // bit-per-tile latch
    output wire        all_attested,
    output wire        multi_rcpt_ok
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            agg_checksum  <= 8'b0;
            agg_job_id    <= 8'b0;
            attested_mask <= 4'b0;
        end else begin
            if (t0_valid) begin
                agg_checksum <= agg_checksum ^ t0_checksum;
                agg_job_id   <= agg_job_id   ^ t0_job_id;
                attested_mask[0] <= 1'b1;
            end
            if (t1_valid) begin
                agg_checksum <= agg_checksum ^ t1_checksum;
                agg_job_id   <= agg_job_id   ^ t1_job_id;
                attested_mask[1] <= 1'b1;
            end
            if (t2_valid) begin
                agg_checksum <= agg_checksum ^ t2_checksum;
                agg_job_id   <= agg_job_id   ^ t2_job_id;
                attested_mask[2] <= 1'b1;
            end
            if (t3_valid) begin
                agg_checksum <= agg_checksum ^ t3_checksum;
                agg_job_id   <= agg_job_id   ^ t3_job_id;
                attested_mask[3] <= 1'b1;
            end
        end
    end

    assign all_attested  = &attested_mask;
    assign multi_rcpt_ok = 1'b1;

endmodule
