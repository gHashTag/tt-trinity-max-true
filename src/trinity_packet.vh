// Trinity packet format constants (v0, 2x2 mesh fabric)
// Apache-2.0
//
// 32-bit packet layout:
//   [31:28] op     - 4'h0 NOP, 4'h1 LOAD_A, 4'h2 LOAD_B, 4'h3 COMPUTE, 4'h4 RESULT,
//                    4'h5 READ_RES, 4'h6 RECEIPT, 4'h7 LOAD_JOB, 4'h8 LOAD_NONCE
//   [27:26] dst_x  - 2 bits (column 0..1)
//   [27]    dst_y  - 1 bit  (row    0..1)  (we treat [27:26] as flat tile id 0..3)
//   [25:24] src_x  - 2 bits (column)
//   [23:20] lane   - which lane (0..3 for a/b operands; 0 for compute/result)
//   [19:16] reserved
//   [15:0]  payload (GF16 word or result)
//
// Tile id (flat) lives in [27:26] (dst) and [25:24] (src).
// This is a single-hop fabric; "x/y" naming kept for forward-compat with full 2x2 XY routing.

`define TRN_PKT_W            32
`define TRN_NUM_TILES        4
`define TRN_TILE_ID_W        2

`define TRN_OP_NOP           4'h0
`define TRN_OP_LOAD_A        4'h1
`define TRN_OP_LOAD_B        4'h2
`define TRN_OP_COMPUTE       4'h3
`define TRN_OP_RESULT        4'h4
`define TRN_OP_READ_RES      4'h5
`define TRN_OP_RECEIPT       4'h6   // emitted by tile after every RESULT (G4)
`define TRN_OP_LOAD_JOB      4'h7   // host -> tile: set job_id_q (low 8 bits of payload)
`define TRN_OP_LOAD_NONCE    4'h8   // host -> tile: set nonce_q  (low 8 bits of payload)

// Field accessors
`define TRN_PKT_OP(p)        (p[31:28])
`define TRN_PKT_DST(p)       (p[27:26])
`define TRN_PKT_SRC(p)       (p[25:24])
`define TRN_PKT_LANE(p)      (p[23:20])
`define TRN_PKT_PAYLOAD(p)   (p[15:0])

`define TRN_MK_PKT(op,dst,src,lane,pl) {op, dst, src, lane, 4'h0, pl}

// -----------------------------------------------------------------------------
// Compute-receipt format (v0 — SILICON-ANCHORED, EMITTED BY TILES, G4)
// -----------------------------------------------------------------------------
// Every RESULT packet emitted by a tile is now followed by a paired RECEIPT
// packet on the same 32-bit packet bus. The receipt carries enough state for
// an off-chip verifier (`tools/receipt_verifier/tri_receipt_verifier.py`) to
// attribute the work to this node deterministically.
//
// RECEIPT packet layout (32 bits, op = TRN_OP_RECEIPT):
//
//   [31:28] op        = 4'h6 (TRN_OP_RECEIPT)
//   [27:26] dst       = host tile id (echoes RESULT.src convention)
//   [25:24] tile_id   = the producing tile (this is who signed the work)
//   [23:20] op_code   = which op was settled (TRN_OP_COMPUTE for v0)
//   [19:16] reserved  = 4'h0
//   [15:8]  checksum  = (job_id_q ^ result_q[7:0]) & 0xFF
//                       matches tri_receipt_verifier.compute_checksum()
//   [7:0]   job_id_lo = persisted job_id_q (low 8 bits)
//
// nonce_q is persisted on-die for replay-window enforcement at the host
// level, but is NOT echoed in the 32-bit RECEIPT word in v0 (the full
// 16-bit nonce was reserved in the original spec and remains reserved for
// a future widened-receipt revision; the host already has the nonce it sent
// in LOAD_NONCE so it can match against (node, job_id, nonce) in the
// verifier seen-set).
//
// R-SI-1: the checksum is pure XOR-fold (8-bit). Zero new multipliers in
// this layer. Apache-2.0.
//
// TRI token settlement is OFF-CHIP. The FPGA's only contract is determinism:
// the same `(job_id, nonce, operands)` always yields the same
// `(result, tile_id, op_code, checksum)` from this node. That is what a
// future ZK or fraud-proof attestation will sign.

// Reserved field widths (host-side full-width receipt schema; the wire-level
// receipt is the 32-bit packet above, narrower on purpose):
`define TRN_RCPT_JOB_ID_W    16
`define TRN_RCPT_TILE_ID_W   `TRN_TILE_ID_W
`define TRN_RCPT_OP_W        4
`define TRN_RCPT_RESULT_W    16
`define TRN_RCPT_NONCE_W     16
`define TRN_RCPT_CHECKSUM_W  8

// On-die receipt accessors (against the 32-bit RECEIPT packet)
`define TRN_RCPT_PKT_TILE(p)     (p[25:24])
`define TRN_RCPT_PKT_OP(p)       (p[23:20])
`define TRN_RCPT_PKT_CHECKSUM(p) (p[15:8])
`define TRN_RCPT_PKT_JOB_LO(p)   (p[7:0])

// Constructor: pack a 32-bit RECEIPT packet
`define TRN_MK_RCPT(dst, tile_id, op_code, job_lo, checksum) \
    {`TRN_OP_RECEIPT, dst, tile_id, op_code, 4'h0, checksum, job_lo}
