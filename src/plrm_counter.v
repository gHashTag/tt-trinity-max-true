`default_nettype none
// plrm_counter.v — L-S22 Period-Locked Runtime Monitor (PLRM)
// Apache-2.0 · TRI-1 v2 · PhD Ch.24/S24 (flos_58.tex)
//
// PhD anchor: SCH-1 Qed (plrm_mutual_exclusion).
//
// Two co-prime Lucas periods L_7=29 (arithmetic agents) and L_8=47
// (orchestration agents). gcd(29,47)=1, LCM=1363 prevents resonance.
//
// Hardware invariant (formally proved in SCH-1):
//     NEVER (arith_active && orch_active && both_request_mac)
//
// Spec from chapter: 47 LUTs, 62 FFs, 0 DSP, 92 MHz on XC7A100T.
//
// Interface:
//   - req_arith / req_orch — request the GF16 MAC unit
//   - grant_arith / grant_orch — at most ONE high simultaneously
//   - plrm_error — sticky FAIL if mutual-exclusion ever violated
//                  (used for runtime certification; tied to gds POST chain)

module plrm_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire req_arith,    // arithmetic agent requests MAC
    input  wire req_orch,     // orchestration agent requests MAC
    output reg  grant_arith,
    output reg  grant_orch,
    output reg  plrm_error    // sticky-high on mutual-exclusion violation
);

    // Two modulo counters: L_7=29 and L_8=47 cycle bounds
    reg [4:0] cnt_arith;   // 5 bits: 0..28
    reg [5:0] cnt_orch;    // 6 bits: 0..46

    // Active flags: agent currently holds MAC
    reg active_arith;
    reg active_orch;

    // phi-weighted priority: when both request, arith wins (higher phi^2 weight)
    // (PhD: w_arith=phi^2 ≈ 2.618, w_orch=phi^-2 ≈ 0.382)
    wire arith_wins = req_arith;
    wire orch_wins  = req_orch & ~req_arith;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_arith    <= 5'd0;
            cnt_orch     <= 6'd0;
            active_arith <= 1'b0;
            active_orch  <= 1'b0;
            grant_arith  <= 1'b0;
            grant_orch   <= 1'b0;
            plrm_error   <= 1'b0;
        end else begin
            // Arith counter mod 29
            if (active_arith) begin
                if (cnt_arith == 5'd28) begin
                    cnt_arith    <= 5'd0;
                    active_arith <= 1'b0;
                    grant_arith  <= 1'b0;
                end else begin
                    cnt_arith <= cnt_arith + 5'd1;
                end
            end else if (arith_wins && !active_orch) begin
                active_arith <= 1'b1;
                grant_arith  <= 1'b1;
                cnt_arith    <= 5'd0;
            end

            // Orch counter mod 47
            if (active_orch) begin
                if (cnt_orch == 6'd46) begin
                    cnt_orch    <= 6'd0;
                    active_orch <= 1'b0;
                    grant_orch  <= 1'b0;
                end else begin
                    cnt_orch <= cnt_orch + 6'd1;
                end
            end else if (orch_wins && !active_arith) begin
                active_orch <= 1'b1;
                grant_orch  <= 1'b1;
                cnt_orch    <= 6'd0;
            end

            // SCH-1 hardware assertion: mutual exclusion sticky check
            // Per Coq: plrm_mutual_exclusion Qed
            if (active_arith & active_orch)
                plrm_error <= 1'b1;
            if (grant_arith & grant_orch)
                plrm_error <= 1'b1;
        end
    end

endmodule

`default_nettype wire
