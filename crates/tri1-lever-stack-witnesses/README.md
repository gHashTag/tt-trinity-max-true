# tri1-lever-stack-witnesses

**R7 Rust falsification witnesses W-101-A..E for L-DPC25 Wave-28 · Lane N**

Tracking: [tt-trinity-max-true tracking issue](https://github.com/gHashTag/tt-trinity-max-true/issues) · Cross-ref: [trios#834](https://github.com/gHashTag/trios/issues/834)

---

## Purpose

This crate implements five **R7 falsification witnesses** for the H_W28 hypothesis:

> Lever Stack #1+#2+#3 raises Trinity TOPS/W from 55 baseline to ≥ 100 on TTIHP27a.

Each witness is a Rust `#[test]` that **PASSES** with conservative pre-silicon estimates and will **FAIL** post-silicon if the physical implementation violates the predicate. This is the standard R7 gate: witnesses are falsifiable by real silicon data.

---

## Lever Stack

| Lever | Description | Reference |
|-------|-------------|-----------|
| #1 | Platinum LUT PE ×1.4 — 1534 GOPS @ 0.96 mm² @ 500 MHz @ 28nm | [arXiv 2511.21910](https://arxiv.org/abs/2511.21910) (ASP-DAC 2026) |
| #2 | BitROM bidirectional ROM ×2.0 — 20.8 TOPS/W @ 65nm, 4 967 kB/mm² | [arXiv 2509.08542](https://arxiv.org/abs/2509.08542) |
| #3 | 4×4 mesh — linear scale-out | TTIHP27a NoC design |

---

## Witnesses

| ID | Test Name | Predicate | Status |
|----|-----------|-----------|--------|
| W-101-A | `w_101_a_lut_pe_energy_bound` | `lut_pe_energy_per_op ≤ 2 × shift_add_baseline_energy_per_op` | PRE-SILICON PASS |
| W-101-B | `w_101_b_bitrom_ber_bound` | `bitrom_bit_error_rate ≤ 1e-9 @ 1.2V, 25°C` | PRE-SILICON PASS |
| W-101-C | `w_101_c_mesh_latency_bound` | `mesh_4x4_per_hop_latency_ns ≤ 1.0 @ TTIHP27a 500 MHz` | PRE-SILICON PASS |
| W-101-D | `w_101_d_r_si_1_breach` | `rtl_uses_star(op) == false ∀ op` (mirrors Coq `holographic_no_star`) | PRE-SILICON PASS |
| W-101-E | `w_101_e_thermal_density_bound` | `thermal_density_w_per_mm2 ≤ 1.5 @ Vdd=1.2V` | PRE-SILICON PASS |

---

## R-gate verification matrix

| Gate | Status | Notes |
|------|--------|-------|
| R5-HONEST | ✅ | All constants marked `// PRE-SILICON ESTIMATE` |
| R7 | ✅ | Witnesses are falsifiable; pass now, fail if silicon violates predicate |
| R8 | ✅ | Author: Vasilev Dmitrii `<admin@t27.ai>` |
| R18 LAYER-FROZEN | ✅ | Purely additive — no existing files modified |
| Apache-2.0 | ✅ | `license = "Apache-2.0"` in Cargo.toml |

---

## Running the witnesses

```bash
cargo test -p tri1-lever-stack-witnesses
```

Expected output: 5 tests, all passing.

---

## Cross-links

- [trios#834](https://github.com/gHashTag/trios/issues/834) — ONE SHOT L-DPC25 Wave-28 orchestration
- [t27#637](https://github.com/t27ai/t27/issues/637) — TTIHP27a tape-out tracking
- [trios#836](https://github.com/gHashTag/trios/issues/836) — Wave-28 post-silicon review gate

---

## License

Apache-2.0 — see [LICENSE](../../LICENSE).

## Author

Vasilev Dmitrii `<admin@t27.ai>`
