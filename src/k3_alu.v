// SPDX-License-Identifier: Apache-2.0
// k3_alu.v — Native Kleene K3 ternary ALU (CLARA Gap-2)
//
// Implements K3 strong ternary logic: AND / OR / NOT over {-1, 0, +1}.
// t27 spec: gHashTag/t27/specs/ar/ternary_logic.t27
//   k3_and = min, k3_or = max, k3_not = sign-negate
//
// 2-bit trit encoding (Kleene K3, balanced):
//   2'b10  = NEG / FALSE   (-1)
//   2'b00  = ZERO / UNKNOWN ( 0)
//   2'b01  = POS  / TRUE   (+1)
//   2'b11  = unused / invalid
//
// ops: 2'b00 = NOT(a), 2'b01 = AND(a,b), 2'b10 = OR(a,b), 2'b11 = reserved
//
// R-SI-1 compliant: zero * operators. Case-statement implementation.
// Pure Verilog-2005. ~30 cells.
//
// DARPA CLARA Gap-2 — TTSKY26b TRI-1-GAMMA
// Anchor: phi^2 + phi^-2 = 3  DOI: 10.5281/zenodo.19227877
`default_nettype none

module k3_alu (
    input  wire [1:0] a,       // trit A: 10=F, 00=U, 01=T
    input  wire [1:0] b,       // trit B: 10=F, 00=U, 01=T
    input  wire [1:0] op,      // 00=NOT(a), 01=AND, 10=OR, 11=reserved
    output reg  [1:0] result,  // result trit
    output reg        valid    // 1 when op is valid (op != 2'b11)
);

    // Trit encoding constants
    localparam T_FALSE   = 2'b10;  // -1
    localparam T_UNKNOWN = 2'b00;  //  0
    localparam T_TRUE    = 2'b01;  // +1

    // Op codes
    localparam OP_NOT = 2'b00;
    localparam OP_AND = 2'b01;
    localparam OP_OR  = 2'b10;
    localparam OP_RSV = 2'b11;

    always @(*) begin
        valid  = 1'b1;
        result = T_UNKNOWN; // default safe

        case (op)
            // -------------------------------------------------------
            // NOT — Kleene negation: T→F, F→T, U→U
            // t27: k3_not(a) = Trit::not(a)
            // -------------------------------------------------------
            OP_NOT: begin
                case (a)
                    T_TRUE:    result = T_FALSE;
                    T_FALSE:   result = T_TRUE;
                    T_UNKNOWN: result = T_UNKNOWN;
                    default:   result = T_UNKNOWN; // 2'b11 input clamped
                endcase
            end

            // -------------------------------------------------------
            // AND — Kleene strong conjunction: min(a,b)
            // t27: k3_and(a,b) = Trit::min(a,b)
            // Ordering: FALSE < UNKNOWN < TRUE
            // Truth table (9 combos):
            //   T∧T=T  T∧U=U  T∧F=F
            //   U∧T=U  U∧U=U  U∧F=F
            //   F∧T=F  F∧U=F  F∧F=F
            // -------------------------------------------------------
            OP_AND: begin
                case ({a, b})
                    {T_TRUE,    T_TRUE   }: result = T_TRUE;
                    {T_TRUE,    T_UNKNOWN}: result = T_UNKNOWN;
                    {T_TRUE,    T_FALSE  }: result = T_FALSE;
                    {T_UNKNOWN, T_TRUE   }: result = T_UNKNOWN;
                    {T_UNKNOWN, T_UNKNOWN}: result = T_UNKNOWN;
                    {T_UNKNOWN, T_FALSE  }: result = T_FALSE;
                    {T_FALSE,   T_TRUE   }: result = T_FALSE;
                    {T_FALSE,   T_UNKNOWN}: result = T_FALSE;
                    {T_FALSE,   T_FALSE  }: result = T_FALSE;
                    default:               result = T_UNKNOWN; // invalid input clamp
                endcase
            end

            // -------------------------------------------------------
            // OR — Kleene strong disjunction: max(a,b)
            // t27: k3_or(a,b) = Trit::max(a,b)
            // Ordering: FALSE < UNKNOWN < TRUE
            // Truth table (9 combos):
            //   T∨T=T  T∨U=T  T∨F=T
            //   U∨T=T  U∨U=U  U∨F=U
            //   F∨T=T  F∨U=U  F∨F=F
            // -------------------------------------------------------
            OP_OR: begin
                case ({a, b})
                    {T_TRUE,    T_TRUE   }: result = T_TRUE;
                    {T_TRUE,    T_UNKNOWN}: result = T_TRUE;
                    {T_TRUE,    T_FALSE  }: result = T_TRUE;
                    {T_UNKNOWN, T_TRUE   }: result = T_TRUE;
                    {T_UNKNOWN, T_UNKNOWN}: result = T_UNKNOWN;
                    {T_UNKNOWN, T_FALSE  }: result = T_UNKNOWN;
                    {T_FALSE,   T_TRUE   }: result = T_TRUE;
                    {T_FALSE,   T_UNKNOWN}: result = T_UNKNOWN;
                    {T_FALSE,   T_FALSE  }: result = T_FALSE;
                    default:               result = T_UNKNOWN; // invalid input clamp
                endcase
            end

            // -------------------------------------------------------
            // RESERVED — op=2'b11 is undefined
            // -------------------------------------------------------
            OP_RSV: begin
                result = T_UNKNOWN;
                valid  = 1'b0;
            end

            default: begin
                result = T_UNKNOWN;
                valid  = 1'b0;
            end
        endcase
    end

endmodule
