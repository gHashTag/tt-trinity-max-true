// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/spec_exit.v
// Sacred opcode 0xEB — SPEC_EXIT (Speculative Exit Control)

`timescale 1ns / 1ps

module spec_exit (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  opcode,           // 0xEB
    input  wire [15:0] confidence,       // Speculative confidence
    input  wire [15:0] threshold,        // Exit threshold
    output reg         exit_enable,      // Exit enable
    output reg         flush_enable,     // Flush pipeline
    output reg         valid             // Output valid
);

    // Speculative exit logic: exit if confidence >= threshold
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            exit_enable  <= 1'b0;
            flush_enable <= 1'b0;
            valid        <= 1'b0;
        end else if (opcode == 8'hEB) begin
            if (confidence >= threshold) begin
                exit_enable  <= 1'b1;
                flush_enable <= 1'b1;
            end else begin
                exit_enable  <= 1'b0;
                flush_enable <= 1'b0;
            end
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule

// Sacred opcode 0xEB — SPEC_EXIT
// Wave-39: Speculative exit for early termination
// R-SI-1: Zero `*` operators