`default_nettype none
// bpb_lower_bound_guard.v — L-S33 BPB Shannon Lower Bound Guard
// Apache-2.0 · TRI-1 v2 · PhD BPB_LowerBound.v (THM-25-3 Qed, THM-25-1 Adm)
//
// PhD anchor: kl_divergence_non_negative -> bpb_non_negative (Qed)
//
// Two-tier guard:
//   (1) THM-25-3 Qed: bpb ≥ 0 always. Hardware: sign bit must be 0.
//   (2) THM-25-1 Adm (Coq.Interval pending): bpb ≥ H(source) configurable floor.
//
// Catches "BPB collapse" (model memorisation -> BPB < H) silently in software.
// Hardware-enforced floor in silicon; no software polling required.
//
// Input: bpb_q24 — current BPB in Q8.24 fixed-point (24 fractional bits).
//        Floor in same Q8.24 format.
//
// Interface:
//   - bpb_q24[31:0]      — current BPB (Q8.24 signed)
//   - floor_q24[31:0]    — configurable Shannon-entropy floor
//   - sample             — pulse to check
//   - bpb_violation      — 1-cycle pulse if bpb < 0 (THM-25-3) or bpb < floor (THM-25-1)
//   - sticky_violation   — sticky any past violation
//
// Budget: 32-bit signed compare ~10 LUT, FF state ~6 LUT. Total ~16 LUT.

module bpb_lower_bound_guard (
    input  wire        clk,
    input  wire        rst_n,
    input  wire signed [31:0] bpb_q24,
    input  wire signed [31:0] floor_q24,
    input  wire        sample,
    output reg         bpb_violation,
    output reg         sticky_violation,
    output reg  [1:0]  fault_code   // 00=ok, 01=below_floor, 10=negative, 11=both
);

    // THM-25-3: bpb_non_negative Qed
    wire is_negative = bpb_q24[31];   // sign bit

    // THM-25-1 (pending Coq.Interval): bpb >= floor
    wire below_floor = (bpb_q24 < floor_q24) & ~is_negative;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bpb_violation    <= 1'b0;
            sticky_violation <= 1'b0;
            fault_code       <= 2'b00;
        end else begin
            bpb_violation <= 1'b0;
            if (sample) begin
                case ({is_negative, below_floor})
                    2'b10: begin
                        bpb_violation    <= 1'b1;
                        sticky_violation <= 1'b1;
                        fault_code       <= 2'b10;
                    end
                    2'b01: begin
                        bpb_violation    <= 1'b1;
                        sticky_violation <= 1'b1;
                        fault_code       <= 2'b01;
                    end
                    2'b11: begin
                        bpb_violation    <= 1'b1;
                        sticky_violation <= 1'b1;
                        fault_code       <= 2'b11;
                    end
                    default: fault_code <= 2'b00;
                endcase
            end
        end
    end

endmodule

`default_nettype wire
