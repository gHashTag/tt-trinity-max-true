// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/dfs_gate.v
// Sacred opcode 0xE7 — DFS_GATE (Depth-First Skip Gate)

`timescale 1ns / 1ps

module dfs_gate (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  opcode,           // 0xE7
    input  wire [15:0] depth_counter,    // Recursion depth
    input  wire        visited_flag,     // Node visited flag
    output reg  [15:0] skip_counter,     // Nodes skipped
    output reg         skip_enable,      // Skip enable output
    output reg         valid             // Output valid
);

    // DFS skip logic: skip if depth > threshold AND not visited
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            skip_counter <= 16'h0000;
            skip_enable  <= 1'b0;
            valid        <= 1'b0;
        end else if (opcode == 8'hE7) begin
            // Skip if depth > 16 and node not visited
            if (depth_counter > 16'd16 && !visited_flag) begin
                skip_counter <= skip_counter + 1'b1;
                skip_enable  <= 1'b1;
            end else begin
                skip_enable  <= 1'b0;
            end
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule

// Sacred opcode 0xE7 — DFS_GATE
// Wave-40: Depth-First Search pruning for sparsity
// R-SI-1: Zero `*` operators