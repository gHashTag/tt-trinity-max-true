// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/holo_mux_x4.v
// Sacred opcode 0xE6 — HOLO_MUX_X4 (Holographic 4:1 Multiplexer)

`timescale 1ns / 1ps

module holo_mux_x4 (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  opcode,           // 0xE6
    input  wire [1:0]  select,           // 2-bit select for 4:1 mux
    input  wire [15:0] data_in0,         // GF16 input 0
    input  wire [15:0] data_in1,         // GF16 input 1
    input  wire [15:0] data_in2,         // GF16 input 2
    input  wire [15:0] data_in3,         // GF16 input 3
    output reg  [15:0] data_out,         // GF16 output
    output reg         valid             // Output valid
);

    // 4:1 MUX logic
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 16'h0000;
            valid    <= 1'b0;
        end else if (opcode == 8'hE6) begin
            case (select)
                2'b00: data_out <= data_in0;
                2'b01: data_out <= data_in1;
                2'b10: data_out <= data_in2;
                2'b11: data_out <= data_in3;
                default: data_out <= 16'h0000;
            endcase
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule

// Sacred opcode 0xE6 — HOLO_MUX_X4
// Wave-40/41 integration: holographic multiplexer for LEVER STACK
// R-SI-1: Zero `*` operators (multiplexer only)