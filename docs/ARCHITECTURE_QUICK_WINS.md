# ARCHITECTURE_QUICK_WINS — γ-surface, competitor-grounded

> Concrete, low-cost, R5-honest improvements for `tt-trinity-gamma` that
> are grounded in the **actual RTL in this repo today** and informed
> by the TRI-NET competitive architecture report.
>
> No item below promises a measured TOPS/W, NMSE, or silicon return.
> Every item lists what would change, what evidence/witness path it
> hooks into, and the anti-claim a reviewer should hold us to.

Last reviewed: 2026-05-18.

## How to read this doc

- **Scope.** γ-surface only. Phi and Euler quick wins are owned by
  the sibling repos. Items here cite RTL files in `src/` and the
  verification assets added in PR #72.
- **Status legend.** Same as `README.md` § "R5-honest claim-status
  legend":
  `RTL` (in-tree Verilog),
  `SIM` (sim pass exists),
  `SPEC` / `PROTOCOL` (spec only),
  `WITNESS` (Rust witness crate),
  `MODEL` (analytical / activity-factor estimate),
  `SILICON` (never used — no returned die).
- **Effort buckets.** `S` = doc/JSON change only; `M` = small Rust /
  Python harness; `L` = new RTL block (out of scope for any
  doc-only PR).

## Inventory — what γ-surface actually has today

Grounding for the quick wins, drawn from the live tree (not aspirational):

| RTL surface | File | What it does on γ today |
|------------|------|-------------------------|
| D2D router stub | `src/d2d_holo_mesh.v` | 4-port N/E/S/W, 1-bit TX/RX, `w_tx` LAYER-FROZEN per R18 |
| Spike packet inputs | `src/d2d_holo_mesh.v` ports | `spike_count[3:0]`, `spike_vec[7:0]`, `gf_tag[3:0]` from cortex into router |
| Cortex | `src/cortical_column.v`, `src/trinity_cortex_8col.v` | 8 LIF cortical columns + BitNet b1.58 MLP per column |
| Mesh | `src/trinity_quad_mesh.v`, `src/trinity_mesh_2x2.v` | 20-PE GF16 mesh that holds cortical activations |
| Audit | `src/multi_tile_receipt.v`, `src/crc32_receipt.v`, `src/blake3_anchor.v`, `src/audit_log_ring_buffer.v`, `src/proof_trace_writer.v` | Per-decision CRC + long-horizon Blake3 anchor + tamper-evident log |
| Power lever (RTL) | `src/fbb_active_path.v` | FBB-ACTIVE only; RBB / CAP-BOOST are witness crates, no RTL on γ |
| Anchor | `sim/tb_canonical.v` | `{uio_out,uo_out} == 16'h47C0` at reset; gated CI job `iverilog-canonical` |

Anything outside that table is **not present on γ today** and any
quick win that requires it lands as `SPEC` / `PROTOCOL`, never as
`RTL`.

## Quick wins

### QW-G-01 — Document the γ-side spike packet format (parallel to Loihi-2-style framing)

- **Status target.** `PROTOCOL` (doc + JSON). No RTL change.
- **Effort.** S.
- **What changes.** Add `docs/specs/SPIKE_PACKET_FORMAT_V0.md` that
  describes the **existing** D2D wire surface as a wire format:
  - field 0: `spike_count[3:0]` — number of cortical columns firing
    this tick (γ has 8 columns, so value range `[0, 8]`)
  - field 1: `spike_vec[7:0]` — per-column firing bitmask (1 bit per
    column, MSB-first)
  - field 2: `gf_tag[3:0]` — GF16 route tag (upper nibble of the
    matmul result selected for cross-die routing)
  - per-direction TX/RX: 1-bit serial extraction of `spike_count[3]`
    (N), `spike_count[0]` (E), `gf_tag[0]` (S), `sync_strobe` (W,
    LAYER-FROZEN).
  - explicit note: γ's current D2D is a **registered TX / latched RX
    stub**, not a graded-spike payload bus. Loihi 2's 32-bit graded
    spike payload is *not* what γ has today; this doc clarifies the
    actual surface so external integrators stop reading "neuromorphic
    spike fabric" as a richer protocol than the stub.
- **Hooks into.** `TN-D2D-05` (multi-chip ordering), `TN-D2D-02`
  (`w_tx` LAYER-FROZEN). Adds a new `TN-D2D-09` row to the matrix:
  *"γ-side spike packet wire format is {spike_count[3:0],
  spike_vec[7:0], gf_tag[3:0]} as routed by `src/d2d_holo_mesh.v`."*
- **Anti-claim.** "γ implements Loihi-2-style graded spike payloads."
  It does not — payload width is 1 bit per direction, the doc must
  say so.

### QW-G-02 — GALS / mode-switch power-delta evidence path (no RTL change)

- **Status target.** `MODEL`-tagged evidence path; `SPEC` doc.
- **Effort.** S (doc), M (Rust witness extension).
- **What changes.** Extend the existing `crates/cap-boost-witness/`
  parameter band table with an explicit "mode-switch power delta"
  appendix:
  - Identify on-chip mode switches present today: reset-vs-running
    (canonical anchor stable across 20 cycles per
    `sim/tb_canonical.v`), `layer_frozen=0 → 1` transition (gates
    `w_tx`), drowsy retention (`src/drowsy_ret.v`, opcode `0xEC`),
    FBB-ACTIVE FSM (`src/fbb_active_path.v`, opcode `0xF2`).
  - Document each transition with: switching cycle bound,
    SAIF / activity-factor proxy, expected leakage delta band (from
    the existing witness crates' `[lo, hi]` bps bands), and the
    failure mode that would invalidate the band.
  - Make explicit that GALS (Globally Asynchronous Locally
    Synchronous) is a **design pattern reference**, not a γ
    implementation claim. γ is synchronous today; the canonical
    `sim/tb_canonical.v` confirms single-clock anchor stability.
- **Hooks into.** `TN-TD-01..03` (RBB / FBB / CAP-BOOST parameter
  bands), `TN-WL-01` (TOPS/W is `MODEL`, not measured).
- **Anti-claim.** "γ uses TrueNorth-style GALS NoC at 1 ms global
  tick." It does not. The mode-switch evidence path is the
  honest substitute: documented switching events with their
  modelling, not a fabricated GALS claim.

### QW-G-03 — Lava / MetaTF adapter stub plan (specification only)

- **Status target.** `PROTOCOL` only. No Python / no Rust shipped in
  this round.
- **Effort.** S (doc), L (full adapter — out of scope here).
- **What changes.** Add a `docs/specs/LAVA_METATF_ADAPTER_V0.md`
  (planned; this doc is the placeholder, the spec lands in a
  follow-up PR) covering:
  - **Inbound translation.** Lava `OutPort` / MetaTF spike emitters
    → γ's `{spike_count, spike_vec, gf_tag}` triple (see QW-G-01).
  - **Mapping table.** Lava graded spike (variable-width integer)
    → γ's 8-column popcount summary; lossy for >1 bit per column;
    document the lossiness, do not hide it.
  - **No claim of bit-exact equivalence** with Lava / MetaTF
    reference models. The adapter is a host-side shim, not silicon.
  - Plain Python skeleton (~30 lines) referenced as future
    `tools/lava_metatf_adapter.py` — explicitly **not committed**
    here. The presence of a placeholder doc is intentional: it
    pins the *contract* (input/output formats) without inflating
    the surface area until the harness lands.
- **Hooks into.** `TN-NF-04` (BitNet b1.58 encoder), `TN-D2D-09`
  (new spike-format row from QW-G-01).
- **Anti-claim.** "γ runs Lava SNN models natively." It does not.
  The adapter is a host-side translation with documented information
  loss.

### QW-G-04 — Cross-link claims matrix from per-feature docs

- **Status target.** Doc cross-link only.
- **Effort.** S.
- **What changes.** Each existing TRI-NET feature doc (`GF16_BFLOAT16_NMSE.md`,
  `D2D_PROTOCOL.md`, `TRIPLE_DECK_STATUS.md`) gets a "Claim IDs:" line
  near the top pointing at the matching rows in
  `docs/VERIFICATION_CLAIMS_MATRIX.md`. The matrix is the spine; per-feature
  docs are the limbs. This makes the CI gate trip on stale references
  if a doc cites a number not represented in the matrix.
- **Hooks into.** Every existing claim row.
- **Anti-claim.** "Cross-linking IS the implementation." It isn't —
  this is a navigation / coverage win, not a verification win.

### QW-G-05 — Pin the disclaimer legend in the README header

- **Status target.** README structure.
- **Effort.** S. **Already landed** in the same PR — see
  README §"R5-honest claim-status legend".
- **Why it counts.** Every numerical claim in `README.md` and
  `BENCHMARKS.md` gets read against the same six-tag legend, which
  prevents pre-silicon `MODEL` rows being silently compared to
  competitor silicon-measured data sheets. This is the cheapest
  durable honesty mechanism in the bundle.

### QW-G-06 — Repo-side mode-switch metrics test scaffolding

- **Status target.** `SPEC` (test scaffolding plan).
- **Effort.** M.
- **What changes.** Add a tracked TODO in
  `docs/VERIFICATION_CLAIMS_MATRIX.md` referencing a future
  `test/tb_mode_switch_metrics.v` that asserts:
  - `w_tx` does not toggle while `layer_frozen=1` (already
    asserted in spirit by `sim/tb_canonical.v` — formalise it as
    an `$display`-checked sequence).
  - Drowsy retention entry / exit completes within a bounded cycle
    count.
  - FBB-ACTIVE FSM does not advance through forbidden states (the
    Triple-Decker FSM spec covers the integration block; this
    item covers FBB-ACTIVE alone in isolation).
- **Hooks into.** `TN-D2D-02`, `TN-TD-02`. Adds matrix row
  `TN-TD-06` ("FBB-ACTIVE in-isolation testbench coverage exists";
  Status `SPEC` until the testbench lands).
- **Anti-claim.** "FBB-ACTIVE testbench exists today." It does not
  on γ — `test/tb_fbb_active_path.v` is stale per
  `TRIPLE_DECK_STATUS.md` §2.1. This item plans the replacement,
  doesn't claim it.

### QW-G-07 — Public anchor of "what γ is NOT"

- **Status target.** README + COMPETITORS cross-link.
- **Effort.** S.
- **What changes.** A short section in `README.md` (or a dedicated
  doc) listing what `tt-trinity-gamma` is **not**, in plain
  language, with citations to the matrix's anti-claim column:
  - Not a Loihi-2-style fully asynchronous SNN. γ is a synchronous
    20-PE GF16 mesh with a 4-port D2D router stub.
  - Not a NorthPole-style on-chip-only inference engine. γ's
    weight residency story is column-local; this is a property of
    `src/cortical_column.v` + the GF16 mesh, not a "no off-chip
    DRAM" guarantee.
  - Not Lava-compatible at the framework level. See QW-G-03.
  - No measured TOPS/W. The `75 → 405` figure is `MODEL` per the
    matrix row `TN-WL-01`.
- **Anti-claim.** The doc is itself the anti-claim surface; if a
  reader cannot find a clear "γ is NOT X" sentence for a claim they
  thought γ made, that's the bug — file an issue against this doc.

## Out of scope for this PR

The following are referenced by the competitive report but require RTL
work or external infrastructure beyond a doc-only PR:

- New RTL for RBB (`0xF1`) or CAP-BOOST (`0xF3`). Both remain
  witness-only on γ per `TRIPLE_DECK_STATUS.md`. The Triple-Decker
  FSM spec lands the contract; the RTL is a separate PR that will
  change the GDS hash.
- A real `tools/nmse_gf16_bf16.py` harness. The golden vector
  contract lives in `tests/vectors/nmse_gf16_bf16.golden.json`; the
  implementation is still planned per `GF16_BFLOAT16_NMSE.md` §6.
- A real Lava / MetaTF adapter (`tools/lava_metatf_adapter.py`).
  QW-G-03 documents the contract; the script is a future PR.
- Any measured silicon claim. None will be added until a die returns
  and `docs/silicon/<date>.json` is committed.

## See also

- [`README.md`](../README.md) §"R5-honest claim-status legend" — the legend itself
- [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md) — every claim and anti-claim
- [`docs/specs/TRIPLE_DECKER_FSM.md`](specs/TRIPLE_DECKER_FSM.md) — power-lever sequencing
- [`D2D_PROTOCOL.md`](../D2D_PROTOCOL.md), [`conformance/d2d/`](../conformance/d2d/) — D2D index + scenarios
- [`GF16_BFLOAT16_NMSE.md`](../GF16_BFLOAT16_NMSE.md), [`tests/vectors/nmse_gf16_bf16.golden.json`](../tests/vectors/nmse_gf16_bf16.golden.json) — NMSE protocol + golden vectors
- [`TRIPLE_DECK_STATUS.md`](../TRIPLE_DECK_STATUS.md) — what is RTL today vs witness-only
- [`COMPETITORS.md`](../COMPETITORS.md) — restrained, source-backed positioning
