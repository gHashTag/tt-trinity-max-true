---
title: "[EN-02] Event-Driven Compute - 10× Active"
labels: "power-efficiency, neuromorphic, priority:P0, size:medium"
assignees: "gHashTag"
---

## EN-02: Event-Driven Compute (10× Active)

### 📚 Research Context

> *"SNNs are 3rd generation NN with event-driven sparsity"* — arXiv:2502.20415

Current implementation uses clock-driven compute even when no spikes are present. Event-driven compute enables power proportional to activity.

### 🎯 Objective

Enhance `cortical_column.v` with spike-triggered compute, achieving 10× active power reduction at 50% sparsity.

### 📋 Implementation

**Enhance**: `src/cortical_column.v` (+150 cells)

```
// New features to add:
reg        compute_enable;      // Spike-triggered enable
wire [7:0] stim_sparse_mask;   // Zero-skip detection
reg        sparse_active;      // Sparse mode flag
```

### Features

1. **Spike-triggered compute** — Only compute when stimulus is non-zero
2. **Null PE bypass** — Skip zero-weight multiplication
3. **Sparse activation routing** — Only active columns receive clock
4. **Stochastic computing** — Probabilistic neuron activation for energy/accuracy trade-off
5. **R-SI-1 compliant** — Zero `*` operators

### ✅ Acceptance Criteria

- [ ] Compute only when stimulus non-zero
- [ ] Null PE bypass verified in simulation
- [ ] Sparse mode reduces power at 50% sparsity
- [ ] Active power reduced to <24 mW (vs 240 mW baseline)
- [ ] Testbench: `test/tb_cortical_column_sparse.v`
- [ ] Integration test: `test/tb_integration_sparse.v`

### 📊 Timeline

**2 weeks** (Phase 2, Weeks 5-6)

### 🔗 Dependencies

- Depends on: EN-01 (subth_clock_gate.v for clock control)
- Blocks: EN-03 (research phase)

### 📖 References

- [arXiv:2502.20415](https://arxiv.org/pdf/2502.20415) — SNNs as 3rd generation NN
- [Spiking Neural Networks on FPGAs](https://ese.washu.edu/documents/Spiking-Neural-Networks-on-FPGAs.pdf)

### 🎯 Success Metric

Active power reduced from 240 mW to **24 mW** at 50% sparsity (10× improvement).

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan