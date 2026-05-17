// SPDX-License-Identifier: Apache-2.0
// t27/rtl_gen/drowsy_ret.v
// Sacred opcode 0xEC — DROWSY_RET (Drowsy Retention Mode)

`timescale 1ns / 1ps

module drowsy_ret (
    input  wire        clk,
    input  wire        reset_n,
    input  wire [7:0]  opcode,           // 0xEC
    input  wire        enter_drowsy,     // Enter drowsy mode
    input  wire        wake_signal,      // Wake from drowsy
    output reg         retention_en,     // Retention enable
    output reg         drowsy_active,    // Drowsy mode active
    output reg         valid             // Output valid
);

    // Drowsy retention state machine
    reg [1:0] state;
    localparam IDLE  = 2'd0;
    localparam ENTRY = 2'd1;
    localparam SLEEP = 2'd2;
    localparam WAKE  = 2'd3;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state        <= IDLE;
            retention_en <= 1'b0;
            drowsy_active<= 1'b0;
            valid        <= 1'b0;
        end else if (opcode == 8'hEC) begin
            case (state)
                IDLE: begin
                    if (enter_drowsy) begin
                        state        <= ENTRY;
                        retention_en <= 1'b1;
                        drowsy_active<= 1'b0;
                    end
                end

                ENTRY: begin
                    state        <= SLEEP;
                    drowsy_active<= 1'b1;
                end

                SLEEP: begin
                    if (wake_signal) begin
                        state        <= WAKE;
                        drowsy_active<= 1'b0;
                    end
                end

                WAKE: begin
                    state        <= IDLE;
                    retention_en <= 1'b0;
                end

                default: state <= IDLE;
            endcase
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule

// Sacred opcode 0xEC — DROWSY_RET
// Wave-42: Drowsy retention for memory power saving
// R-SI-1: Zero `*` operators