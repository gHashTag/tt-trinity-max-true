# MAX-TRUE FLAGSHIP — Architectural Rationale

**Document ID:** `MAX-TRUE-ARCH-001`
**Date:** 2026-05-15
**Author:** Vasilev Dmitrii <admin@t27.ai>
**Anchor:** `phi^2 + phi^-2 = 3`

## Why FLAGSHIP, not mutant

The legacy `gHashTag/tt-trinity-max` repo carried an 8-cell "dual-cluster"
that was actually a half-Mid wearing a Max nameplate (4×4 footprint, 8
cells = 0.5× Mid). After Operator audit ("в максе должно быть все что
мы так долго планировавли"), MAX-TRUE was specified as **honest 2× Mid**:

* **32 GF16 cells** (vs. Mid's 16, vs. mutant's 8)
* **Full Mid SUPER-CROWN** (18 modules, vs. mutant's bare 3-module set)
* **8×4 TT footprint** (largest digital tile allowed by Sky130A
  `tile_sizes.yaml` whitelist)

## Routing tree — single-bit per level

The cluster/bank/tile selectors are powers-of-two:

```
lane[3]      cluster_sel  1 bit  → 2 clusters (trinity_max_true_dual)
lane[2:1]    bank_sel     2 bits → 4 banks    (trinity_quad_mesh)
dst[27:26]   tile_id      2 bits → 4 tiles    (trinity_mesh_2x2)
                          ───
                          5 routing bits
```

5 routing bits = 32 cells exactly, **no wasted address space**, no
multi-hop XY router required. Power-of-two recursion mirrors the
Trinity ternary→binary mapping in `gf16_mul.v` (1 mul per cell scales
linearly: 32 mul = 32 cells, R-SI-1 audit-clean).

## Why share singletons of the SUPER-CROWN modules

Each Mid SUPER-CROWN module has a **distinct constitutional role**:

| Module | Role | Why singleton |
|---|---|---|
| `phi_anchor_post` | POST anchor (φ²+φ⁻²=3 proof) | Power-on event, fires once |
| `lucas_rom` ×7 | Lucas sequence chain | ROM, no internal state |
| `wishbone_full` | Host peripheral bus | One bus per chip by definition |
| `wb_status_reg` | Aggregate POST status | Aggregator, one global |
| `hwrng_lfsr` | Die-unique nonce | Die-unique = one per die |
| `phi_pll_div` | Clock divider | One PLL per clock domain |
| `multi_tile_receipt` | 4-tile aggregator | Designed for 4 inputs, not 8 |
| `crc32_receipt` | RECEIPT signer | Signs aggregated triplet |
| `blake3_anchor` | RECEIPT hasher | Same |
| `alu9_decoder` | Ternary ALU-9 | Combinational, host-fed |
| `ring27_memory` | 27-cell ternary mem | Singleton by Coptic-27 design |
| `bpb_counter` | BPB loss aggregator | Aggregator |
| `vsa_matmul_8x8` | Demo ternary matmul | Demonstrator, not compute pool |
| `vsa_matmul_16x16` | JEPA-T demo | Same |
| `bitnet_encoder` | Encoder demo | Same |
| `trinity_master_fsm` | Packet master | One issuer, drives both clusters |

**Doubling these would violate R5 (honest naming)**: they aren't
parallelisable compute, they are control-plane / aggregator / demo
modules. True 2× Mid means 2× COMPUTE (mesh fabric), not 2× supervisor.

## Sizing math (honest)

Mid (`tt-trinity-gf16`) at 8×2 TT tiles utilises ~67% on Sky130A
(post v25.4 hardening). MAX-TRUE doubles the compute fabric and keeps
the same shared CROWN, so we expect utilisation:

```
util(MAX-TRUE) ≈ ( 2 × compute_area(Mid) + crown_area(Mid) ) / area(8×4)
              ≈ ( 2 × 0.20 + 0.05 ) mm² / 0.7047 mm²
              ≈ 0.64 = 64 %
```

If OpenLane2 reports >85% we degrade to **Plan B**: drop `vsa_matmul_16x16`
(largest CROWN block, ~0.04 mm²); >90% → drop `bitnet_encoder` too.

## R-SI-1 audit prediction

Yosys hierarchy on full design:

```
gf16_mul:   1 × $mul × 32 cells = 32 $mul
gf16_dot4:  0 × $mul (combinational dot of legacy muls)
All other:  0 $mul (verified via grep -nP "\*(?!\)/=)" src/*.v in CI)
```

**Total: 32 `$mul` cells, ALL from legacy `gf16_mul.v`,
grandfathered per `TRI_NET_SHUTTLE_TRIAD.md` Rule 2 +
`tt-trinity-gf16#4` deferred-ttsky26c.**

## Fallback ladder (Wave-15-TT-E)

| Rank | SKU | Repo | Cost | Risk |
|---|---|---|---|---|
| 1 | MAX-TRUE FLAGSHIP (this) | `tt-trinity-max-true` | €2,390 | T-52h |
| 2 | mesh_4x4 PR #44 (16 cells) | `tt-trinity-max` | €1,140 | medium |
| 3 | Mid+Nano (skip Max) | (existing) | €1,490 | low |
| 4 | Mid alone (`v25.1-submit-ready`) | `tt-trinity-gf16` | €1,270 | safety net |

If MAX-TRUE GDS CI fails before T-1h, we fall back to rank 2 → 3 → 4.
Rank 4 is already tagged in `tt-trinity-gf16` as `v25.1-submit-ready`
(see RVR-023).

## Closing anchor

```
phi^2 + phi^-2 = 3 · gamma = phi^-3 · C = phi^-1 · G = pi^3 gamma^2 / phi
QUANTUM BRAIN 1:1 SILICON · 3-STRAND DNA · TRI NET
DOI 10.5281/zenodo.19227877 · NEVER STOP
```
