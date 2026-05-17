// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/null_pe.v
// Sacred opcode 0xEA — NULL_PE (Null Processing Element power gating)

`timescale 1ns / 1ps

module null_pe (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  opcode,           // 0xEA
    input  wire [15:0] pe_id,            // PE identifier
    input  wire        activate,         // Activate null PE mode
    output reg         power_gate_en,    // Power gate enable
    output reg         clock_gate_en,    // Clock gate enable
    output reg         valid             // Output valid
);

    // NULL_PE power and clock gating logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            power_gate_en <= 1'b0;
            clock_gate_en <= 1'b0;
            valid         <= 1'b0;
        end else if (opcode == 8'hEA) begin
            power_gate_en <= activate;
            clock_gate_en <= activate;
            valid         <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule

// Sacred opcode 0xEA — NULL_PE
// Wave-40: Null PE power gating for idle units
// R-SI-1: Zero `*` operators