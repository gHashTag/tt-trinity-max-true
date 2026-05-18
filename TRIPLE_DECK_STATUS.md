# TRIPLE_DECK_STATUS — RBB → FBB → CAP_BOOST on γ-surface

> Conservative status snapshot for the **triple-decker dynamic-power
> envelope** on γ-surface. Three orthogonal levers (idle-well bias,
> active-well bias, supply-rail capacitive burst) are referenced across
> the TRI-NET line; this file lists what is actually present in *this*
> repo, what is plan-only, and what is reused from sibling crates.
>
> **No silicon measurement is claimed.** All energy / TOPS-per-watt
> figures cited in this document are pre-silicon (synthesis-activity-
> factor modelling), as in [`BENCHMARKS.md`](BENCHMARKS.md) and
> [`STATUS.md`](STATUS.md).

Last reviewed: 2026-05-18.

## TL;DR

Three sacred opcodes form the triple-decker envelope:

| Lever | Opcode | Wave | What it does | Status on γ |
|------|--------|-----:|---------------|-------------|
| **RBB** — Reverse Body Bias (idle PEs) | `0xF1` | W47 | `V_BS = -V_DD · γ⁴`; suppress idle-PE leakage | **Witness only** (`crates/rbb-witness/`); no `src/*.v` |
| **FBB-ACTIVE** — Forward Body Bias (active PEs) | `0xF2` | W48 | `V_BS = +V_DD · γ⁴`; speed up active-path PEs | **RTL present**: `src/fbb_active_path.v` + `crates/fbb-active-witness/` |
| **CAP-BOOST** — Capacitive Decoupling Burst (rail) | `0xF3` | W49 | `ΔC = C_dec_base · γ³`; suppress di/dt droop | **Witness only** (`crates/cap-boost-witness/`); no `src/*.v` |

Status by readiness level (per the gates in [`STATUS.md`](STATUS.md)):

| Lever | SPEC | RTL | SIM | SYNTH | GDS | SILICON |
|-------|:----:|:---:|:---:|:-----:|:---:|:-------:|
| RBB        | ✅ (crate doc) | ❌ | ❌ | ❌ | ❌ | ❌ |
| FBB-ACTIVE | ✅ | ✅ (`src/fbb_active_path.v`) | ❌ (`test/tb_fbb_active_path.v` exists but **does not compile** against current RTL — port mismatch on `enable` / `temp_mon` / `activity` / `fbb_level` width) | 🟡 (rolled into top-level Yosys) | 🟡 (rolled into top-level GDS build) | ❌ |
| CAP-BOOST  | ✅ (crate doc) | ❌ | ❌ | ❌ | ❌ | ❌ |

Anything marked ❌ above is **not implemented in silicon RTL on the
γ-surface in this repo**. The Rust witness crates assert the spec /
parameter band; they are not RTL.

## 1. What a "lever" is

The triple-decker is a **dynamic-power envelope** trick:

- RBB pulls the body of idle PE wells negative (`V_BS = -V_DD · γ⁴ ≈
  −2.5 mV` per `crates/rbb-witness/src/lib.rs`). Idle leakage drops
  ≈40 % (band [35 %, 50 %]) at the cost of ≤1.5 % active-path
  overhead (charge pump).
- FBB-ACTIVE pulls the body of currently-active PE wells positive
  (`V_BS = +V_DD · γ⁴`). Threshold voltage drops on the active path,
  which is taken as a small Fmax / activity gain rather than a power
  saving.
- CAP-BOOST adds a small fractional decoupling capacitance burst on
  the supply rail (`ΔC = C_dec_base · γ³ ≈ 0.81 pF` at
  `C_dec_base = 100 pF` per `crates/cap-boost-witness/src/lib.rs`).
  di/dt margin improves ≈6 % (band [4 %, 10 %]); droop suppression
  ≈4 % (band [2 %, 8 %]).

The three are designed to compose at **iso-area** (per crate
documentation: cap area uplift ≤ 0.5 % at R18 LAYER-FROZEN).

## 2. Repo-side evidence — what is concrete

### 2.1 FBB-ACTIVE (0xF2) — RTL present

| Artefact | Path | Notes |
|----------|------|-------|
| RTL | `src/fbb_active_path.v` | 4-state FSM, FBB level localparams 0…400 mV, leakage-monitor input, status register. Coq proof referenced in header (`FBBActive2.v`). |
| Witness crate | `crates/fbb-active-witness/` | OP_FBB opcode constant + tests. |
| Coq proof | (referenced in RTL header — confirm under `coq/` if reused here) | The RTL file cites `FBBActive2.v`; this repo's `coq/` directory should be the place to land it. |

FBB-ACTIVE is **listed in `info.yaml` source bring-up** (verify before
claiming silicon-side activity). The Yosys audit gate in
`.github/workflows/test.yaml` exercises it as part of `src/*.v`
elaboration.

A dedicated testbench file does exist (`test/tb_fbb_active_path.v`),
but it is currently **stale** relative to the RTL — it references
ports `enable`, `temp_mon`, `activity` that are not on the current
`fbb_active_path` module, and connects `fbb_level` as an 8-bit wire
where the RTL expects 32 bits. Running `iverilog` against the current
tree therefore fails elaboration. Repairing this testbench is in scope
for a follow-up PR; **this PR does not change RTL or testbench
sources**, only documentation.

### 2.2 RBB (0xF1) — witness only

| Artefact | Path | Notes |
|----------|------|-------|
| Witness crate | `crates/rbb-witness/` | OP_RBB = 0xF1; parameter bands (V_BS in decimillivolts, leak-save bps, etc.) |
| RTL | _(none in this repo)_ | No `src/rbb_*.v` module exists in the γ-surface RTL tree. |
| Test | `crates/rbb-witness/tests/opcode.rs` | Rust-side bank-distinctness witness only. |

RBB is therefore **planned, not implemented**, on γ-surface. The
opcode is reserved in the sacred bank (0xF1, first slot of the
extended 0xD0..0xFF bank, R18 ceremony) and the parameter envelope is
fixed by the witness crate; the Verilog has not landed.

### 2.3 CAP-BOOST (0xF3) — witness only

| Artefact | Path | Notes |
|----------|------|-------|
| Witness crate | `crates/cap-boost-witness/` | OP_CAP_BOOST = 0xF3; ΔC bps, di/dt margin band, droop band. |
| RTL | _(none in this repo)_ | No `src/cap_boost_*.v` module exists. |
| Test | `crates/cap-boost-witness/tests/opcode.rs` | Rust-side witness only. |

CAP-BOOST is therefore **planned, not implemented**, on γ-surface.

## 3. Adjacent power-mode RTL (not part of the triple-decker, listed for context)

These are separate dynamic-power features that *do* have RTL in this
repo. They should not be conflated with the triple-decker:

| Module | Path | Sacred opcode |
|--------|------|---------------|
| Drowsy retention | `src/drowsy_ret.v` | `0xEC` (W43) |

If/when RBB and CAP-BOOST RTL lands, they should follow the same
header convention as `src/fbb_active_path.v` and `src/drowsy_ret.v`.

## 4. Plan to close the gap (R5-honest)

Concrete steps to move RBB and CAP-BOOST from **witness-only** to
**RTL present**, in order:

1. Land `src/rbb_idle_well.v` matching the parameter band in
   `crates/rbb-witness/`. Include a `test/tb_rbb_idle_well.v`
   covering `V_BS` step, leakage-save band, and clock-tree
   invariance (`|Δf| ≤ 50 bps`).
2. Land `src/cap_boost_rail.v` matching `crates/cap-boost-witness/`.
   Include a `test/tb_cap_boost_rail.v` covering `ΔC` step, droop
   band, and area-uplift assertion (≤ 50 bps, R18 LAYER-FROZEN).
3. Add a top-level integration block `src/triple_deck_ctrl.v` that
   sequences `0xF1 → 0xF2 → 0xF3` with the existing
   `src/fbb_active_path.v`.
4. Cross-reference all three Verilog modules in
   [`CLARA_TRACEABILITY.md`](CLARA_TRACEABILITY.md) under the audit /
   restraint columns where appropriate (RBB / CAP-BOOST are
   power-envelope levers, not CLARA gaps).
5. Once RTL is present, replace each ❌ in §TL;DR with the actual
   evidence path and bump SIM / SYNTH gates accordingly.

Items 1–3 are out of scope for this PR — they would change the GDS
hash and therefore the TTSKY26b submission. They are listed here so
the gap is visible and traceable.

## 5. Cross-chip note

The TRI-NET line discusses the triple-decker as a **line-wide**
property. Whether RBB and CAP-BOOST RTL is implemented on
[`tt-trinity-phi`](https://github.com/gHashTag/tt-trinity-phi) or
[`tt-trinity-euler`](https://github.com/gHashTag/tt-trinity-euler)
is not asserted by this repo; this file describes γ-surface only.
The sacred-bank opcode reservations (0xF1, 0xF2, 0xF3) are
line-wide per the R18 ceremony, so the opcode allocation is stable
even where the RTL is still planned.

## 6. R5 honesty — what this file does **not** claim

- ❌ "Triple-Deck is implemented on γ-surface." Only FBB-ACTIVE has
  RTL here. RBB and CAP-BOOST are witness-only.
- ❌ Measured leakage / di/dt / TOPS-per-watt improvements. The
  numbers in §1 and the crate docs are pre-silicon bands derived
  from φ⁻ⁿ-based modelling, not from a returned die.
- ❌ A Coq proof for each lever **in this tree**. The RTL header
  references `FBBActive2.v` for FBB-ACTIVE; cross-check
  `coq/` / `trios-coq/` for actual landed proofs.

## See also

- [`STATUS.md`](STATUS.md) — overall readiness gates
- [`BENCHMARKS.md`](BENCHMARKS.md) — pre-silicon workload numbers
- [`CLARA_TRACEABILITY.md`](CLARA_TRACEABILITY.md) — CLARA gap RTL mapping (distinct from triple-deck)
- `crates/rbb-witness/`, `crates/fbb-active-witness/`, `crates/cap-boost-witness/` — sacred-opcode witnesses
- `src/fbb_active_path.v` — the one triple-decker module with γ-side RTL today
- [`SCIENTIFIC_IMPROVEMENT_PLAN.md`](SCIENTIFIC_IMPROVEMENT_PLAN.md) — TRI-NET 2026 plan (items EN-01 / EN-02 / EN-03 own these levers)
