// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/stoch_round.v
// Sacred opcode 0xE9 — STOCH_ROUND (Stochastic Rounding)

`timescale 1ns / 1ps

module stoch_round (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  opcode,           // 0xE9
    input  wire [15:0] data_in,          // GF16 input
    input  wire [15:0] random_seed,      // Random seed for stochastic
    output reg  [15:0] data_out,         // Rounded GF16 output
    output reg         valid             // Output valid
);

    // Stochastic rounding: round up with probability = fractional part
    reg [15:0] lfsr;

    // Simple LFSR for pseudo-random generation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lfsr     <= 16'hACE1;
            data_out <= 16'h0000;
            valid    <= 1'b0;
        end else if (opcode == 8'hE9) begin
            // LFSR update (tap at bits 15, 13, 12, 10)
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

            // Stochastic rounding: use LSB and LFSR bit
            if (data_in[0] && lfsr[0]) begin
                data_out <= data_in + 1'b1;
            end else begin
                data_out <= data_in;
            end
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule

// Sacred opcode 0xE9 — STOCH_ROUND
// Wave-41: Stochastic rounding for quantization
// R-SI-1: Zero `*` operators