# VERIFICATION_CLAIMS_MATRIX — TRI-NET (γ-surface) numerical claims

> Single, falsifiable index of every numerical / behavioural claim made
> in TRI-NET γ-surface docs and specs. Each row pins **where** the
> claim is stated, **what evidence / witness** backs it, **which
> harness** would falsify it, **status today**, and the **anti-claim**
> a reviewer should hold us to.
>
> **R5 honesty.** No row in this table cites a measured silicon
> number. Anything labelled `pre-silicon` is synthesis-activity-factor
> modelling or a witness-crate parameter band, not a returned die.
> Anything labelled `protocol-only` is a spec without a checked-in
> harness or measured result.

Last reviewed: 2026-05-18.

## How to read this table

- **Claim ID** — stable identifier (`TN-<area>-<n>`) referenced by
  `scripts/check_trinet_specs.sh`. The CI gate fails if a claim ID
  appears in the canonical doc list (see [§Gate](#spec-ci-gate)) but
  is not represented in this matrix.
- **Claim** — the assertion, in one line. Numbers reproduced verbatim
  from the source document.
- **Location** — `<file>:<anchor>` of the assertion. Multiple
  locations are listed comma-separated.
- **Evidence / Witness** — what artefact in this repo (RTL, witness
  crate, Coq, JSON vector, testbench, conformance asset) backs it.
- **Harness** — the harness that would refute the claim (script,
  testbench, conformance asset path).
- **Status** — one of `SPEC`, `WITNESS`, `RTL`, `SIM`, `PROTOCOL`,
  `PLAN`. No row may be marked `SILICON` until a returned die has
  been measured.
- **Anti-claim** — the negation a reviewer should test against, so
  the claim is genuinely falsifiable rather than rhetorical.

## Numeric format claims (NF)

| Claim ID | Claim | Location | Evidence / Witness | Harness | Status | Anti-claim |
|----------|-------|----------|---------------------|---------|--------|------------|
| TN-NF-01 | GF16 is the γ-surface primary 16-bit numeric format (1 sign / 6 exp / 9 mantissa, bias 31). | `GF16_BFLOAT16_NMSE.md` §2, `specs/numeric/gf16.t27`, `conformance/FORMAT-SPEC-001.json` (`formats.GF16`) | `specs/numeric/gf16.t27`, `src/gf16_*.v`, `conformance/FORMAT-SPEC-001.json` | `scripts/check_trinet_specs.sh` (matrix coverage) | SPEC | GF16 field widths differ from (1,6,9) bias 31 in any of the three locations. |
| TN-NF-02 | bfloat16 reference is (1 sign / 8 exp / 7 mantissa, bias 127), computed off-chip in fp64 host harness. | `GF16_BFLOAT16_NMSE.md` §2, `conformance/FORMAT-SPEC-001.json` (`tri_net_extended_formats.BF16`) | `conformance/FORMAT-SPEC-001.json`, host harness | host fp64 reference (planned `tools/nmse_gf16_bf16.py`) | PROTOCOL | A row in `tests/vectors/nmse_gf16_bf16.golden.json` uses a non-fp64 reference. |
| TN-NF-03 | "GF16 competitive with bfloat16 at workload W" requires `Δ_dB ≤ +0` at fixed seed, distribution, and ≥10000 samples. | `GF16_BFLOAT16_NMSE.md` §3, §5 | Threshold/tolerance encoded in `tests/vectors/nmse_gf16_bf16.golden.json` | `tools/nmse_gf16_bf16.py` (planned), seed/sample assertions | PROTOCOL | A run with <10000 samples or undeclared distribution is published as `Δ_dB`. |
| TN-NF-04 | BitNet b1.58 ternary weights cost 1.58 bits per weight (`log₂ 3`); compression vs INT8 = 5.04×, vs FP16 = 10.1×. | `README.md` §4, `BENCHMARKS.md` Demo 1 | `src/bitnet_encoder.v` (2-bit trit), README §4 derivation | manual derivation; no harness needed (purely combinatorial encoding) | RTL | Encoder uses >2 bits per weight or omits the `0` symbol. |
| TN-NF-05 | `gf16_dot4_sparse` achieves 3.83 effective ops/cycle at 74.3 % sparsity vs 1.0 dense. | `README.md` §5, line 168 (sparse cycle count ≈22) | `src/gf16_dot4_sparse.v`, README cycle-count table | cocotb test under `test/` for `gf16_dot4_sparse` | SIM | Cycle count >22 at 74.3 % sparsity, or effective ops/cycle <3.83. |

## D2D / interconnect claims (D2D)

| Claim ID | Claim | Location | Evidence / Witness | Harness | Status | Anti-claim |
|----------|-------|----------|---------------------|---------|--------|------------|
| TN-D2D-01 | At reset (`ui_in[0]=0`, canonical mode), `{uio_out, uo_out} == 16'h47C0` on γ-surface. | `D2D_PROTOCOL.md` §2, `BENCHMARKS.md` "Ground rules" | `sim/tb_canonical.v`, `src/tt_um_trinity_max_true.v` | `.github/workflows/test.yaml` job `iverilog-canonical`; `conformance/d2d/header_valid.json` | SIM | Reset emits a value other than `0x47C0` on the concatenated bus. |
| TN-D2D-02 | `w_tx` (SYNC strobe, `uio[3]`) is LAYER-FROZEN: gated to 0 when `layer_frozen=1` (PhD Theorem 36.1 R18). | `D2D_PROTOCOL.md` §1, `src/d2d_holo_mesh.v` header | `src/d2d_holo_mesh.v` assignment `w_tx <= sync_strobe_raw & ~layer_frozen;` | `sim/tb_canonical.v` LAYER-FROZEN check | RTL | `w_tx` toggles while `layer_frozen=1`. |
| TN-D2D-03 | TIP v1.0 wire spec is FROZEN at TTSKY26b; γ is the slave compute/mesh endpoint accepting LOAD_MODE / SYNC_STROBE. | `D2D_PROTOCOL.md` §1, §4, `docs/INTERCONNECT_PROTOCOL_V1.md` | `docs/INTERCONNECT_PROTOCOL_V1.md` §3–§5, `src/tt_um_trinity_max_true.v` | `conformance/d2d/header_valid.json`, `conformance/d2d/unsupported_opcode.json` | PROTOCOL | A header bit assignment in §3 differs between docs and `tt_um_trinity_max_true.v`. |
| TN-D2D-04 | Cross-die packets are bound to a per-decision CRC32 receipt and a long-horizon Blake3 anchor. | `D2D_PROTOCOL.md` §3 | `src/crc32_receipt.v`, `src/blake3_anchor.v`, `src/multi_tile_receipt.v` | `test/tb_proof_trace_writer.v`, `conformance/d2d/bad_crc.json` | RTL | A CRC mismatch in `bad_crc.json` is not flagged by the receipt path. |
| TN-D2D-05 | Multi-chip packet ordering is preserved per-direction (N/E/S/W) on the γ-side router stub. | `src/d2d_holo_mesh.v` TX comment block | `src/d2d_holo_mesh.v` registered TX path | `conformance/d2d/multi_chip_ordering.json` | RTL | A pair of packets sent in order on a given direction is observed out-of-order on RX latches. |
| TN-D2D-06 | Unsupported opcodes on the D2D path do not corrupt receipt state (drop/no-op semantics). | `D2D_PROTOCOL.md` §5 ("not claims") | `src/audit_log_ring_buffer.v` (tamper-evident log) | `conformance/d2d/unsupported_opcode.json` | PROTOCOL | An unsupported opcode advances the receipt counter or mutates anchor state. |
| TN-D2D-07 | A D2D timeout triggers retry without losing receipt ordering. | `D2D_PROTOCOL.md` §5 (implicit — FEC not implemented) | host harness (planned) | `conformance/d2d/timeout_retry.json` | PROTOCOL | A simulated timeout causes a gap in the audit log ring buffer. |
| TN-D2D-08 | DOI `10.5281/zenodo.19227877` pins TIP v1.0; no in-repo measured cross-die signal integrity is claimed. | `D2D_PROTOCOL.md` §5, `docs/INTERCONNECT_PROTOCOL_V1.md` | external Zenodo record (out-of-repo) | n/a — claim is explicitly **plan-only / external citation** | SPEC | The repo cites an additional DOI as if it were measured silicon. |

## Triple-Decker power claims (TD)

| Claim ID | Claim | Location | Evidence / Witness | Harness | Status | Anti-claim |
|----------|-------|----------|---------------------|---------|--------|------------|
| TN-TD-01 | RBB (`0xF1`): `V_BS = -V_DD · γ⁴`, idle leakage drop ≈40 % (band [35 %, 50 %]), active overhead ≤1.5 %. | `TRIPLE_DECK_STATUS.md` §1 | `crates/rbb-witness/src/lib.rs` parameter constants | `cargo test -p rbb-witness` | WITNESS | A witness test asserts a `V_BS` or leakage band outside the published range. |
| TN-TD-02 | FBB-ACTIVE (`0xF2`): `V_BS = +V_DD · γ⁴`; FBB level localparams 0…400 mV; RTL has 4-state FSM. | `TRIPLE_DECK_STATUS.md` §2.1, `src/fbb_active_path.v` header | `src/fbb_active_path.v`, `crates/fbb-active-witness/` | `cargo test -p fbb-active-witness`; future repaired `test/tb_fbb_active_path.v` | RTL | The RTL exposes an FBB level outside `[0, 400]` mV without a witness update. |
| TN-TD-03 | CAP-BOOST (`0xF3`): `ΔC = C_dec_base · γ³ ≈ 0.81 pF` at `C_dec_base = 100 pF`; di/dt margin ≈6 % (band [4 %, 10 %]); droop suppression ≈4 % (band [2 %, 8 %]). | `TRIPLE_DECK_STATUS.md` §1, §2.3 | `crates/cap-boost-witness/src/lib.rs` parameter constants | `cargo test -p cap-boost-witness` | WITNESS | A witness test asserts a ΔC or droop band outside the published range. |
| TN-TD-04 | Triple-deck sequencing is RBB → FBB → CAP_BOOST → IDLE with explicit guards, cooldown, and brownout fallback. | `docs/specs/TRIPLE_DECKER_FSM.md`, `TRIPLE_DECK_STATUS.md` §4 | FSM doc; integration block `src/triple_deck_ctrl.v` is **PLAN** | future `test/tb_triple_deck_ctrl.v` | PLAN | A future implementation transitions out of `CAP_BOOST` to `RBB` directly without IDLE/cooldown. |
| TN-TD-05 | Triple-deck composes at iso-area: cap area uplift ≤ 0.5 % at R18 LAYER-FROZEN. | `TRIPLE_DECK_STATUS.md` §1 | witness crates' area-uplift constants | future synthesis area report cross-check | WITNESS | Synthesis returns a top-level area uplift > 0.5 % attributable to triple-deck blocks. |

## Workload / TOPS-per-watt claims (WL)

| Claim ID | Claim | Location | Evidence / Witness | Harness | Status | Anti-claim |
|----------|-------|----------|---------------------|---------|--------|------------|
| TN-WL-01 | Pre-silicon TOPS/W estimates `75 → 405` (AVS-48/96 + FBB + Purkinje thermal) are **modelling**, not measured. | `README.md` line ~622, `BENCHMARKS.md` Demo 1 "What this is not" | `crates/avs-witness/`, `src/fbb_active_path.v`, `src/purkinje_thermal_gate.v` | none (modelling only) — see `docs/silicon/` placeholder | PLAN | Any release note publishes `405 TOPS/W` without the `pre-silicon estimate` qualifier. |
| TN-WL-02 | `gf16_dot4_sparse` MAC primitive uses no `*` operator (R-SI-1). | `BENCHMARKS.md` Demo 1, `tools/check_no_star.sh` | `src/gf16_dot4_sparse.v`, Yosys `$mul` audit gate in `test.yaml` | `tools/check_no_star.sh --diff origin/main` | RTL | A new `*` operator appears in `src/*.v` outside `gf16_mul.v`. |

## Spec CI gate

The gate script is [`scripts/check_trinet_specs.sh`](../scripts/check_trinet_specs.sh).
It performs two passes:

1. **t27c parse (optional).** If a `t27c` binary is on `PATH`, the
   script runs `t27c parse` against every `specs/numeric/*.t27` and
   `specs/fpga/*.t27` file. If `t27c` is not available, the script
   prints `t27c not found - skipping parse` and continues.
2. **Claims coverage (mandatory).** The script scans the canonical
   doc list (see the script body) for tokens matching
   `TN-(NF|D2D|TD|WL)-\d+` and verifies that every such token also
   appears as a row in this file. A missing row fails the gate.

To extend the matrix, add a row above with a fresh `Claim ID`, then
update or annotate the source doc with that ID so the gate finds it.

## See also

- [`GF16_BFLOAT16_NMSE.md`](../GF16_BFLOAT16_NMSE.md) — NMSE protocol
- [`D2D_PROTOCOL.md`](../D2D_PROTOCOL.md) — D2D index
- [`TRIPLE_DECK_STATUS.md`](../TRIPLE_DECK_STATUS.md) — triple-deck status
- [`docs/specs/TRIPLE_DECKER_FSM.md`](specs/TRIPLE_DECKER_FSM.md) — triple-decker FSM spec
- [`tests/vectors/nmse_gf16_bf16.golden.json`](../tests/vectors/nmse_gf16_bf16.golden.json) — NMSE golden vectors
- [`conformance/d2d/`](../conformance/d2d/) — D2D conformance assets
- [`scripts/check_trinet_specs.sh`](../scripts/check_trinet_specs.sh) — gate script
