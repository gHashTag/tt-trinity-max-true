---
title: "[SN-03] STDP Learning Module"
labels: "neuromorphic, learning, STDP, priority:P1, size:medium"
assignees: "gHashTag"
---

## SN-03: STDP Learning Module

### 📚 Research Context

> *"STDP enables unsupervised feature extraction"* — SNN literature

Spike-Timing-Dependent Plasticity (STDP) is a biologically-plausible learning rule:
- **Δw = A₊ * exp(-Δt/τ₊)** for pre before post (LTP)
- **Δw = -A₋ * exp(Δt/τ₋)** for post before pre (LTD)
- **Weight normalization** — L2 constraint to prevent runaway growth

### 🎯 Objective

Implement on-chip STDP learning for unsupervised feature extraction.

### 📋 Implementation

**New module**: `src/stdp_learning.v` (~600 cells)

```
module stdp_learning (
    // Clock and reset
    input  wire clk,
    input  wire rst_n,

    // Spike timing capture
    input  wire        pre_spike,      // Pre-synaptic spike
    input  wire        post_spike,     // Post-synaptic spike
    input  wire [15:0] pre_trace,     // Pre-synaptic trace register
    input  wire [15:0] post_trace,    // Post-synaptic trace register

    // STDP parameters (Q8.8)
    input  wire [7:0]  tau_plus,      // τ₊ time constant
    input  wire [7:0]  tau_minus,     // τ₋ time constant
    input  wire [7:0]  A_plus,        // A₊ LTP amplitude
    input  wire [7:0]  A_minus,       // A₋ LTD amplitude

    // Plasticity control
    input  wire        learning_enable,

    // Weight update
    output reg  [7:0]  delta_w,        // Weight change
    output reg         delta_w_valid,
    output wire [15:0] weight_normalized  // L2-normalized weight
);
```

### Features

1. **Pre-post spike timing capture** — Δt calculation
2. **Δw calculation** — Exponential decay (look-up table)
3. **Weight normalization** — L2 constraint
4. **Plasticity gate** — Learning enable/disable
5. **R-SI-1 compliant** — Zero `*` operators (LUT-based exp)

### ✅ Acceptance Criteria

- [ ] Pre-post timing captured correctly
- [ ] Δw follows STDP rule (LTP/LTD)
- [ ] Weight normalization prevents runaway
- [ ] Learning gate enables/disables updates
- [ ] Testbench: `test/tb_stdp_learning.v`
- [ ] Integration test: `test/tb_cortex_stdp.v`

### 📊 Timeline

**3 weeks** (Phase 3, Weeks 11-13)

### 🔗 Dependencies

- Depends on: `cortical_column.v` spike timing
- Blocks: None (standalone module)

### 📖 References

- [STDP in neuromorphic hardware](https://arxiv.org/abs/2006.01010)
- [Unsupervised learning with STDP](https://arxiv.org/abs/1805.08354)

### 🎯 Success Metric

STDP module demonstrates unsupervised feature extraction on spike patterns.

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan