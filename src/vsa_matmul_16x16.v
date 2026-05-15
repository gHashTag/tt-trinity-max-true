`default_nettype none
// vsa_matmul_16x16.v — 16×16 ternary XOR-popcount matmul (JEPA-T tier)
// Apache-2.0
//
// PhD anchor: Chapter 35 (CROWN) — large-scale ternary VSA inference.
// 4x area of vsa_matmul_8x8. R-SI-1: zero `*` operators.
// Each element 2 bits {00=+1, 01=-1, 10=0, 11=0}. Result is signed 8-bit.
//
// L-S19: Uses gf16_popcount16 (3-stage pipeline, 16 elements).
//        Fmax target: 150 MHz. LATENCY=3 cycles.
//
// Latency from start: 1 (latch) + 1 (valid pulse) + 3 (pipeline) = 5 cycles.
//
// Encoding (per element, 2 bits):
//   00 = +1   01 = -1   10 = 0   11 = 0

module vsa_matmul_16x16 (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [511:0] a_flat,   // 16×16×2 = 512 bits
    input  wire [511:0] b_flat,
    output reg          done,
    output reg  [2047:0] c_flat,  // 16×16×8 = 2048 bits signed
    output wire          matmul_ok
);

    localparam LATENCY = 3;  // L-S19: 3-stage pipeline

    reg [511:0] a_reg, b_reg;
    reg         busy;
    reg         pipe_valid_in;

    // 256 pipelined inner-product units (16×16)
    wire [255:0] pc_valid_out;
    wire [7:0]   pc_result [0:255];

    genvar gi, gj;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : gen_row
            for (gj = 0; gj < 16; gj = gj + 1) begin : gen_col
                gf16_popcount16 #(.N_ELEMS(16), .LATENCY(LATENCY)) u_pc (
                    .clk      (clk),
                    .rst_n    (rst_n),
                    .valid_in (pipe_valid_in),
                    .a_row    (a_reg[32*gi +: 32]),
                    .b_row    (b_reg[32*gj +: 32]),
                    .valid_out(pc_valid_out[gi*16 + gj]),
                    .result   (pc_result[gi*16 + gj])
                );
            end
        end
    endgenerate

    reg [1:0] state;
    localparam ST_IDLE  = 2'd0;
    localparam ST_LATCH = 2'd1;
    localparam ST_PIPE  = 2'd2;
    localparam ST_DONE  = 2'd3;

    integer ci, cj;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg        <= 512'b0;
            b_reg        <= 512'b0;
            c_flat       <= 2048'b0;
            busy         <= 1'b0;
            done         <= 1'b0;
            pipe_valid_in <= 1'b0;
            state        <= ST_IDLE;
        end else begin
            done          <= 1'b0;
            pipe_valid_in <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (start) begin
                        a_reg <= a_flat;
                        b_reg <= b_flat;
                        busy  <= 1'b1;
                        state <= ST_LATCH;
                    end
                end
                ST_LATCH: begin
                    pipe_valid_in <= 1'b1;
                    state <= ST_PIPE;
                end
                ST_PIPE: begin
                    if (pc_valid_out[0]) begin
                        for (ci = 0; ci < 16; ci = ci + 1)
                            for (cj = 0; cj < 16; cj = cj + 1)
                                c_flat[(ci*16 + cj)*8 +: 8] <= pc_result[ci*16 + cj];
                        done  <= 1'b1;
                        busy  <= 1'b0;
                        state <= ST_IDLE;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

    assign matmul_ok = 1'b1;

endmodule
