// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/sparse_mask.v
// Sacred opcode 0xED — SPARSE_MASK (Sparsity Mask Application)

`timescale 1ns / 1ps

module sparse_mask (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  opcode,           // 0xED
    input  wire [15:0] data_in,          // GF16 input
    input  wire [26:0] mask_bits,        // 27-bit sparsity mask
    input  wire [4:0]  channel_id,       // Channel ID (0-26)
    output reg  [15:0] data_out,         // Masked GF16 output
    output reg         masked,           // Output was masked (set to zero)
    output reg         valid             // Output valid
);

    // Sparsity mask application: zero out if mask bit is 0
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 16'h0000;
            masked   <= 1'b0;
            valid    <= 1'b0;
        end else if (opcode == 8'hED) begin
            if (mask_bits[channel_id]) begin
                data_out <= data_in;
                masked   <= 1'b0;
            end else begin
                data_out <= 16'h0000;
                masked   <= 1'b1;
            end
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule

// Sacred opcode 0xED — SPARSE_MASK
// Wave-40: Channel-wise sparsity masking (27 Coptic channel groups)
// R-SI-1: Zero `*` operators