---
title: "[CL-02] Adversarial Training Loop - Gap-1 Enhancement"
labels: "CLARA, Gap-1, priority:P0, size:small"
assignees: "gHashTag"
---

## CL-02: Adversarial Training Loop (Gap-1 Enhancement)

### 📚 Research Context

> *"Neuromorphic chips achieve 100-1000× energy efficiency for adversarial detection"* — PatSnap 2025 patent surge

Current `redteam_filter.v` is static — it checks against known adversarial patterns but cannot adapt to new attacks. Real adversaries continuously evolve their techniques.

### 🎯 Objective

Implement an on-chip adversarial training loop using PGD (Projected Gradient Descent) in GF16 arithmetic.

### 📋 Implementation

**New module**: `src/adversarial_trainer.v` (~500 cells)

```
module adversarial_trainer (
    // Clock and reset
    input  wire clk,
    input  wire rst_n,
    input  wire ena,

    // Input data stream
    input  wire [15:0] data_in,
    input  wire        data_valid,

    // Training control
    input  wire        train_start,
    input  wire        train_step,

    // Parameters (Q8.8 format)
    input  wire [15:0] epsilon,      // ε-ball radius
    input  wire [7:0]  alpha,        // Step size
    input  wire        norm_type,    // 0=L∞, 1=L2

    // Adversarial output
    output reg  [15:0] adv_data_out,
    output reg         adv_valid_out,
    output reg         adversarial_detected
);
```

### Features

1. **PGD in GF16** — Projected Gradient Descent using GF16 arithmetic
2. **On-chip ε-ball** — Computation in Q8.8 format
3. **L∞, L2 norm constraints** — Selectable via `norm_type`
4. **Sparse adversarial patterns** — Zero-skip optimization
5. **R-SI-1 compliant** — Zero `*` operators (shift-add only)

### ✅ Acceptance Criteria

- [ ] Module compiles with R-SI-1 compliance
- [ ] PGD converges within 10 steps on test vectors
- [ ] ε-ball constraint verified (adversarial perturbation ≤ ε)
- [ ] Testbench: `test/tb_adversarial_trainer.v`
- [ ] Integration test: `test/tb_integration_redteam.v`

### 📊 Timeline

**2 weeks** (Phase 1, Weeks 1-2)

### 🔗 Dependencies

- Depends on: `gf16_dot4.v`, `gf16_add.v` (already implemented)
- Blocks: None (standalone enhancement)

### 📖 References

- [Neuromorphic computing patents surge 401%](https://www.patsnap.com/)
- [BitNet: Scaling 1-bit Transformers](https://arxiv.org/abs/2310.11453)

### 🎯 Success Metric

Adversarial trainer detects >90% of PGD-generated attacks while maintaining <5% false positive rate.

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan