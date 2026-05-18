# TRIPLE_DECKER_FSM — state machine spec

> Specification (not yet implementation) for the γ-side triple-decker
> dynamic-power envelope controller. Sequences the three sacred-bank
> levers `0xF1` (RBB) → `0xF2` (FBB-ACTIVE) → `0xF3` (CAP-BOOST) → IDLE
> with explicit guards, cooldown, and brownout / overcurrent fallback.
>
> **Status today.** This file is the SPEC for a future
> `src/triple_deck_ctrl.v`. The integration block does **not yet
> exist** in this repo; FBB-ACTIVE (`0xF2`) is the only triple-decker
> lever with RTL (`src/fbb_active_path.v`). RBB and CAP-BOOST are
> witness-only crates. See [`TRIPLE_DECK_STATUS.md`](../../TRIPLE_DECK_STATUS.md).
> No silicon measurement is claimed here.

Last reviewed: 2026-05-18.

## Claim IDs

- TN-TD-01 — RBB parameter band
- TN-TD-02 — FBB-ACTIVE RTL band
- TN-TD-03 — CAP-BOOST parameter band
- TN-TD-04 — Sequencing RBB → FBB → CAP_BOOST → IDLE with cooldown
- TN-TD-05 — Iso-area composition (≤ 0.5 % uplift, R18 LAYER-FROZEN)

See [`docs/VERIFICATION_CLAIMS_MATRIX.md`](../VERIFICATION_CLAIMS_MATRIX.md)
for the canonical row text and anti-claims.

## 1. States

| State | Encoding | Entry condition | What is asserted |
|-------|:--------:|-----------------|------------------|
| `IDLE` | `3'd0` | reset, or cooldown elapsed from `CAP_BOOST` | All three levers OFF. Charge-pump quiescent. |
| `RBB` | `3'd1` | host opcode `0xF1` AND `safe_guards_ok` | `V_BS = -V_DD · γ⁴` applied to idle PE wells. |
| `FBB_ACTIVE` | `3'd2` | host opcode `0xF2` AND came-from `RBB` OR cooldown elapsed from `IDLE` | `V_BS = +V_DD · γ⁴` applied to active PE wells; FBB level in `[0, 400]` mV. |
| `CAP_BOOST` | `3'd3` | host opcode `0xF3` AND came-from `FBB_ACTIVE` AND no brownout | `ΔC = C_dec_base · γ³` added on supply rail. |
| `COOLDOWN` | `3'd4` | exit from `CAP_BOOST` OR any FALLBACK | All levers OFF; counter `cooldown_cnt` decrementing. |
| `FALLBACK` | `3'd5` | `brownout` OR `overcurrent` from any active state | All levers driven OFF in ≤2 cycles; latch `fault_reason`. |

`COOLDOWN` exists only to ensure the rail/well bias has settled
before re-entering `RBB`. It is intentionally not a host-visible
state — host sees `IDLE` once `cooldown_cnt == 0`.

## 2. Transition diagram (ASCII)

```
      ┌──────────────────────────────────────────────┐
      │                                              │
      ▼                                              │
   ┌──────┐  opcode=0xF1   ┌────────┐  opcode=0xF2  │
   │ IDLE │ ─────────────► │  RBB   │ ────────────► │
   └──────┘                └────────┘                │
      ▲     ◄── cooldown_done                       ▼
      │                                          ┌─────────────┐
      │                                          │ FBB_ACTIVE  │
      │                                          └─────────────┘
      │                                              │
      │                                  opcode=0xF3 ▼
      │                                          ┌────────────┐
      │              cooldown_done ◄────────────│ CAP_BOOST  │
      │                                          └────────────┘
      │                                              │
      │                                  exit        ▼
      │                                         ┌──────────┐
      └─────────────────────────────────────────│ COOLDOWN │
                                                └──────────┘

   Any active state ─── brownout|overcurrent ──► FALLBACK ──► COOLDOWN
```

Legend: arrows are one-cycle transitions guarded by the conditions
listed in §3. `COOLDOWN → IDLE` is automatic when `cooldown_cnt`
reaches 0.

## 3. Guards

| Guard | Definition | Source |
|-------|------------|--------|
| `safe_guards_ok` | `temp_ok && rail_ok && !layer_frozen_violation` | composed below |
| `temp_ok` | thermal sensor reading below `T_MAX_C` (host-provided) | `src/purkinje_thermal_gate.v` |
| `rail_ok` | rail droop sensor below `DROOP_MAX_BPS` | future `src/cap_boost_rail.v` |
| `layer_frozen_violation` | attempt to assert `w_tx` while `layer_frozen=1` | `src/d2d_holo_mesh.v` |
| `brownout` | rail voltage below `V_BROWNOUT` (host-provided) | host input |
| `overcurrent` | rail current above `I_MAX` (host-provided) | host input |
| `cooldown_done` | `cooldown_cnt == 0` | local |

Forbidden transitions (must NOT exist in any implementation):

- `CAP_BOOST → RBB` directly. Must traverse `COOLDOWN → IDLE`.
- `CAP_BOOST → FBB_ACTIVE` directly. Same rationale.
- `IDLE → CAP_BOOST` directly. CAP-BOOST is only valid after FBB-ACTIVE.
- `FALLBACK → IDLE` in zero cycles. Must traverse `COOLDOWN`.

## 4. Parameters (R5-honest, pre-silicon)

| Parameter | Value | Source |
|-----------|-------|--------|
| `V_BS_RBB` | `-V_DD · γ⁴` (≈ -2.5 mV per `crates/rbb-witness/src/lib.rs`) | TN-TD-01 |
| `V_BS_FBB_max` | `+400` mV (RTL localparam) | TN-TD-02 |
| `ΔC_CAP_BOOST` | `C_dec_base · γ³` (≈ 0.81 pF at `C_dec_base = 100 pF`) | TN-TD-03 |
| `COOLDOWN_CYCLES` | `≥ 4`, host-tunable, default `8` | spec |
| `FALLBACK_CYCLES` | `≤ 2` from any active state to `FALLBACK` | spec |
| Iso-area uplift | `≤ 0.5 %` of LAYER-FROZEN top-level area | TN-TD-05 |

Numbers above are SPEC bands. No silicon measurement is claimed.

## 5. Brownout / overcurrent fallback

When either `brownout` or `overcurrent` asserts in any state in
`{RBB, FBB_ACTIVE, CAP_BOOST}`:

1. Within `≤ FALLBACK_CYCLES` cycles, drive all three levers OFF.
2. Latch `fault_reason ∈ {BROWNOUT, OVERCURRENT}` in the status
   register.
3. Transition to `FALLBACK`, then unconditionally to `COOLDOWN`.
4. `COOLDOWN` enforces at least `COOLDOWN_CYCLES` quiescent cycles
   regardless of host opcode.
5. Host must read and clear `fault_reason` before the next `0xF1`
   is accepted; otherwise the FSM stays in `IDLE` and ignores
   triple-deck opcodes.

This rule guarantees that a hostile or buggy host cannot keep
driving the rail into brownout by hammering `0xF3`.

## 6. R18 / LAYER-FROZEN interaction

The triple-decker MUST NOT alter `w_tx` (SYNC strobe). The FSM has
no direct path to `w_tx`; only `src/d2d_holo_mesh.v` drives it, and
only when `layer_frozen == 0`. Attempting any FSM transition that
would side-channel through `layer_frozen` is a violation of
TN-D2D-02 and TN-TD-05.

## 7. Verification plan (PLAN, not in-tree)

Once `src/triple_deck_ctrl.v` lands, a cocotb harness
`test/tb_triple_deck_ctrl.v` MUST cover:

- Cold start: `IDLE → RBB → FBB_ACTIVE → CAP_BOOST → COOLDOWN → IDLE`.
- Brownout from `CAP_BOOST` → `FALLBACK` → `COOLDOWN`.
- Overcurrent from `FBB_ACTIVE` → `FALLBACK` → `COOLDOWN`.
- Forbidden transition attempts (see §3) MUST be ignored (FSM stays).
- Cooldown count enforcement (host opcode during cooldown is a no-op).
- Iso-area Yosys area report cross-check (TN-TD-05).

Until the harness is committed, claims about triple-deck
*sequencing* in release notes must cite this spec, not a measured
result.

## See also

- [`TRIPLE_DECK_STATUS.md`](../../TRIPLE_DECK_STATUS.md) — what is RTL vs witness-only today
- [`docs/VERIFICATION_CLAIMS_MATRIX.md`](../VERIFICATION_CLAIMS_MATRIX.md) — claim rows TN-TD-01…TN-TD-05
- `crates/rbb-witness/`, `crates/fbb-active-witness/`, `crates/cap-boost-witness/`
- [`SCIENTIFIC_IMPROVEMENT_PLAN.md`](../../SCIENTIFIC_IMPROVEMENT_PLAN.md) — items EN-01 / EN-02 / EN-03
