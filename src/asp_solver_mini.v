// SPDX-License-Identifier: Apache-2.0
// asp_solver_mini.v — CLARA Gap-6 Answer Set Programming solver
// Mini variant: MAX_RULES=16, MAX_ATOMS=16
// Spec: gHashTag/t27/specs/ar/asp_solver.t27
// Target: gHashTag/tt-trinity-gamma  (~600 cells, 1.2% GAMMA)
// R-SI-1: zero * operator — pure XOR/AND/OR logic
// Verilog-2005 only — no SystemVerilog syntax
//
// ASP Rule encoding (24 bits per rule):
//   [23]     valid bit
//   [22:19]  head atom index (4-bit → selects atom 0..15)
//   [18:11]  pos_body[7:0]  — positive body bitmask (8-bit, covers atoms 0..7)
//   [10:3]   neg_body[7:0]  — negation-as-failure bitmask (atoms 0..7)
//   [2:0]    _unused
//
// Rule fires iff:
//   valid=1 AND (model & pos_body) == pos_body AND (model[7:0] & neg_body) == 0
//
// Algorithm (iterative stable-model computation via TP operator):
//   new_model = OR over fired rule heads (start from empty model each iteration)
//   The TP operator is applied once per clock cycle.
//   Convergence: model == prev_model (stable model found)
//   Cap: 8 iterations maximum (oscillation → capped output)
//
// Ports:
//   clk, rst_n
//   load_rule    — when high, latch rule data into rule_mem[rule_idx]
//   rule_idx     — [3:0] which slot to write
//   rule_data    — [23:0] packed rule: {valid,head[3:0],pos_body[7:0],neg_body[7:0],_unused[2:0]}
//   start        — rising edge begins stable-model computation
//   model_out    — [15:0] computed stable model (atom bits)
//   stable       — high when stable model found (convergence or cap)
//   iter_count   — [3:0] number of TP iterations completed
//   capped       — high when iteration cap (8) was hit without convergence

`default_nettype none

module asp_solver_mini (
    input  wire        clk,
    input  wire        rst_n,

    // Rule loading interface
    input  wire        load_rule,
    input  wire [3:0]  rule_idx,
    input  wire [23:0] rule_data,

    // Control
    input  wire        start,

    // Outputs
    output reg  [15:0] model_out,
    output reg         stable,
    output reg  [3:0]  iter_count,
    output reg         capped
);

    // -------------------------------------------------------------------
    // Rule memory: 16 slots × 24 bits
    // Encoding: {valid[1], head[4], pos_body[8], neg_body[8], _unused[3]}
    // -------------------------------------------------------------------
    reg [23:0] rule_mem [0:15];

    // -------------------------------------------------------------------
    // State machine: IDLE → RUNNING → DONE
    // -------------------------------------------------------------------
    localparam ST_IDLE    = 2'b00;
    localparam ST_RUNNING = 2'b01;
    localparam ST_DONE    = 2'b10;

    reg [1:0] state;
    reg [3:0] pass_count;

    // -------------------------------------------------------------------
    // Previous model for convergence detection
    // -------------------------------------------------------------------
    reg [15:0] prev_model;

    // -------------------------------------------------------------------
    // Unpack rule fields from rule_mem (combinational)
    // -------------------------------------------------------------------
    wire        rv  [0:15]; // rule valid
    wire [3:0]  rh  [0:15]; // rule head atom index
    wire [7:0]  rp  [0:15]; // rule pos_body bitmask
    wire [7:0]  rn  [0:15]; // rule neg_body bitmask

    assign rv[0]  = rule_mem[0][23];  assign rh[0]  = rule_mem[0][22:19];
    assign rp[0]  = rule_mem[0][18:11]; assign rn[0]  = rule_mem[0][10:3];

    assign rv[1]  = rule_mem[1][23];  assign rh[1]  = rule_mem[1][22:19];
    assign rp[1]  = rule_mem[1][18:11]; assign rn[1]  = rule_mem[1][10:3];

    assign rv[2]  = rule_mem[2][23];  assign rh[2]  = rule_mem[2][22:19];
    assign rp[2]  = rule_mem[2][18:11]; assign rn[2]  = rule_mem[2][10:3];

    assign rv[3]  = rule_mem[3][23];  assign rh[3]  = rule_mem[3][22:19];
    assign rp[3]  = rule_mem[3][18:11]; assign rn[3]  = rule_mem[3][10:3];

    assign rv[4]  = rule_mem[4][23];  assign rh[4]  = rule_mem[4][22:19];
    assign rp[4]  = rule_mem[4][18:11]; assign rn[4]  = rule_mem[4][10:3];

    assign rv[5]  = rule_mem[5][23];  assign rh[5]  = rule_mem[5][22:19];
    assign rp[5]  = rule_mem[5][18:11]; assign rn[5]  = rule_mem[5][10:3];

    assign rv[6]  = rule_mem[6][23];  assign rh[6]  = rule_mem[6][22:19];
    assign rp[6]  = rule_mem[6][18:11]; assign rn[6]  = rule_mem[6][10:3];

    assign rv[7]  = rule_mem[7][23];  assign rh[7]  = rule_mem[7][22:19];
    assign rp[7]  = rule_mem[7][18:11]; assign rn[7]  = rule_mem[7][10:3];

    assign rv[8]  = rule_mem[8][23];  assign rh[8]  = rule_mem[8][22:19];
    assign rp[8]  = rule_mem[8][18:11]; assign rn[8]  = rule_mem[8][10:3];

    assign rv[9]  = rule_mem[9][23];  assign rh[9]  = rule_mem[9][22:19];
    assign rp[9]  = rule_mem[9][18:11]; assign rn[9]  = rule_mem[9][10:3];

    assign rv[10] = rule_mem[10][23]; assign rh[10] = rule_mem[10][22:19];
    assign rp[10] = rule_mem[10][18:11]; assign rn[10] = rule_mem[10][10:3];

    assign rv[11] = rule_mem[11][23]; assign rh[11] = rule_mem[11][22:19];
    assign rp[11] = rule_mem[11][18:11]; assign rn[11] = rule_mem[11][10:3];

    assign rv[12] = rule_mem[12][23]; assign rh[12] = rule_mem[12][22:19];
    assign rp[12] = rule_mem[12][18:11]; assign rn[12] = rule_mem[12][10:3];

    assign rv[13] = rule_mem[13][23]; assign rh[13] = rule_mem[13][22:19];
    assign rp[13] = rule_mem[13][18:11]; assign rn[13] = rule_mem[13][10:3];

    assign rv[14] = rule_mem[14][23]; assign rh[14] = rule_mem[14][22:19];
    assign rp[14] = rule_mem[14][18:11]; assign rn[14] = rule_mem[14][10:3];

    assign rv[15] = rule_mem[15][23]; assign rh[15] = rule_mem[15][22:19];
    assign rp[15] = rule_mem[15][18:11]; assign rn[15] = rule_mem[15][10:3];

    // -------------------------------------------------------------------
    // TP operator: combinational new_model from current model_out
    //
    // Rule r fires iff:
    //   rv[r] == 1
    //   AND (model_out[7:0] & rp[r]) == rp[r]   [all pos_body atoms in model]
    //   AND (model_out[7:0] & rn[r]) == 8'h00   [no neg_body atom in model]
    //
    // Note: pos_body and neg_body only cover atoms 0..7 (lower 8 bits).
    // Atoms 8..15 are derivable heads only.
    //
    // R-SI-1: no * operator. Use AND + reduction to check equality.
    //   (model_out[7:0] & rp[r]) == rp[r]
    //   is equivalent to: ~|(rp[r] & ~model_out[7:0]) i.e. no pos_body bit missing
    //
    // new_model = OR over {fires[r] ? (1 << rh[r]) : 0}
    // Implemented via 16-bit one-hot expand and OR-reduction.
    // -------------------------------------------------------------------

    wire        fires [0:15]; // rule fires signal

    // pos_body check: all bits of rp[r] present in model_out[7:0]
    // = no bit in rp[r] is absent from model_out[7:0]
    // = ~|(rp[r] & ~model_out[7:0])
    wire [7:0] m8;
    assign m8 = model_out[7:0];

    wire pos_ok [0:15];
    wire neg_ok [0:15];

    assign pos_ok[0]  = ~|(rp[0]  & ~m8);
    assign neg_ok[0]  = ~|(rn[0]  &  m8);
    assign pos_ok[1]  = ~|(rp[1]  & ~m8);
    assign neg_ok[1]  = ~|(rn[1]  &  m8);
    assign pos_ok[2]  = ~|(rp[2]  & ~m8);
    assign neg_ok[2]  = ~|(rn[2]  &  m8);
    assign pos_ok[3]  = ~|(rp[3]  & ~m8);
    assign neg_ok[3]  = ~|(rn[3]  &  m8);
    assign pos_ok[4]  = ~|(rp[4]  & ~m8);
    assign neg_ok[4]  = ~|(rn[4]  &  m8);
    assign pos_ok[5]  = ~|(rp[5]  & ~m8);
    assign neg_ok[5]  = ~|(rn[5]  &  m8);
    assign pos_ok[6]  = ~|(rp[6]  & ~m8);
    assign neg_ok[6]  = ~|(rn[6]  &  m8);
    assign pos_ok[7]  = ~|(rp[7]  & ~m8);
    assign neg_ok[7]  = ~|(rn[7]  &  m8);
    assign pos_ok[8]  = ~|(rp[8]  & ~m8);
    assign neg_ok[8]  = ~|(rn[8]  &  m8);
    assign pos_ok[9]  = ~|(rp[9]  & ~m8);
    assign neg_ok[9]  = ~|(rn[9]  &  m8);
    assign pos_ok[10] = ~|(rp[10] & ~m8);
    assign neg_ok[10] = ~|(rn[10] &  m8);
    assign pos_ok[11] = ~|(rp[11] & ~m8);
    assign neg_ok[11] = ~|(rn[11] &  m8);
    assign pos_ok[12] = ~|(rp[12] & ~m8);
    assign neg_ok[12] = ~|(rn[12] &  m8);
    assign pos_ok[13] = ~|(rp[13] & ~m8);
    assign neg_ok[13] = ~|(rn[13] &  m8);
    assign pos_ok[14] = ~|(rp[14] & ~m8);
    assign neg_ok[14] = ~|(rn[14] &  m8);
    assign pos_ok[15] = ~|(rp[15] & ~m8);
    assign neg_ok[15] = ~|(rn[15] &  m8);

    assign fires[0]  = rv[0]  & pos_ok[0]  & neg_ok[0];
    assign fires[1]  = rv[1]  & pos_ok[1]  & neg_ok[1];
    assign fires[2]  = rv[2]  & pos_ok[2]  & neg_ok[2];
    assign fires[3]  = rv[3]  & pos_ok[3]  & neg_ok[3];
    assign fires[4]  = rv[4]  & pos_ok[4]  & neg_ok[4];
    assign fires[5]  = rv[5]  & pos_ok[5]  & neg_ok[5];
    assign fires[6]  = rv[6]  & pos_ok[6]  & neg_ok[6];
    assign fires[7]  = rv[7]  & pos_ok[7]  & neg_ok[7];
    assign fires[8]  = rv[8]  & pos_ok[8]  & neg_ok[8];
    assign fires[9]  = rv[9]  & pos_ok[9]  & neg_ok[9];
    assign fires[10] = rv[10] & pos_ok[10] & neg_ok[10];
    assign fires[11] = rv[11] & pos_ok[11] & neg_ok[11];
    assign fires[12] = rv[12] & pos_ok[12] & neg_ok[12];
    assign fires[13] = rv[13] & pos_ok[13] & neg_ok[13];
    assign fires[14] = rv[14] & pos_ok[14] & neg_ok[14];
    assign fires[15] = rv[15] & pos_ok[15] & neg_ok[15];

    // -------------------------------------------------------------------
    // new_model computation: OR of all fired head one-hot expansions
    // For each atom bit h (0..15): set if any fired rule has rh[r]==h
    // Combinational always block (no * operator used).
    // -------------------------------------------------------------------
    reg [15:0] new_model;
    integer i;
    always @(*) begin
        new_model = 16'h0000;
        for (i = 0; i < 16; i = i + 1) begin
            if (fires[i]) begin
                new_model[rh[i]] = 1'b1;
            end
        end
    end

    // -------------------------------------------------------------------
    // Sequential: state machine
    // -------------------------------------------------------------------
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= ST_IDLE;
            model_out  <= 16'h0000;
            prev_model <= 16'h0000;
            stable     <= 1'b0;
            capped     <= 1'b0;
            iter_count <= 4'h0;
            pass_count <= 4'h0;
            for (j = 0; j < 16; j = j + 1)
                rule_mem[j] <= 24'h0;
        end else begin
            // Rule loading (any time including idle)
            if (load_rule) begin
                rule_mem[rule_idx] <= rule_data;
            end

            case (state)
                ST_IDLE: begin
                    stable     <= 1'b0;
                    capped     <= 1'b0;
                    iter_count <= 4'h0;
                    pass_count <= 4'h0;
                    if (start) begin
                        // TP starts from empty model (semantics of stable model)
                        model_out  <= 16'h0000;
                        prev_model <= 16'hFFFF; // force first iteration to run
                        state      <= ST_RUNNING;
                    end
                end

                ST_RUNNING: begin
                    // Apply TP operator: advance one iteration
                    model_out  <= new_model;
                    pass_count <= pass_count + 4'h1;
                    iter_count <= pass_count + 4'h1;

                    if (new_model == model_out) begin
                        // Stable model found — fixed point of TP
                        stable <= 1'b1;
                        capped <= 1'b0;
                        state  <= ST_DONE;
                    end else if (pass_count == 4'h7) begin
                        // Hit 8-iteration cap (oscillation/non-convergence)
                        stable <= 1'b1;
                        capped <= 1'b1;
                        state  <= ST_DONE;
                    end else begin
                        prev_model <= new_model;
                    end
                end

                ST_DONE: begin
                    stable <= 1'b1;
                    // Stay done until reset or new start
                    if (start) begin
                        stable     <= 1'b0;
                        capped     <= 1'b0;
                        model_out  <= 16'h0000;
                        prev_model <= 16'hFFFF;
                        pass_count <= 4'h0;
                        iter_count <= 4'h0;
                        state      <= ST_RUNNING;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    // Suppress lint warnings for unused signals
    wire _unused_ok = &{1'b0, prev_model, 1'b0};

endmodule
`default_nettype wire
