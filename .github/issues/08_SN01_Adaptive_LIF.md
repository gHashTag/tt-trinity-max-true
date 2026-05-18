---
title: "[SN-01] Adaptive LIF Neuron"
labels: "neuromorphic, SNN, priority:P1, size:medium"
assignees: "gHashTag"
---

## SN-01: Adaptive LIF Neuron

### 📚 Research Context

> *"FPGA-Based Adaptive LIF Neuron for High-Speed Energy-Efficient SNN"* — IEEE Transactions 2025

Current LIF implementation in `cortical_column.v` is basic (decay >>= 3, fixed threshold). Biologically, neurons adapt:

- **Adaptive threshold** — θ increases on fire, decays otherwise
- **STDP** — Spike-Timing-Dependent Plasticity for learning
- **Homeostatic plasticity** — Target firing rate regulation
- **Separate channels** — Excitatory/inhibitory

### 🎯 Objective

Enhance LIF neuron with biological fidelity enabling on-chip learning.

### 📋 Implementation

**Enhance**: `src/cortical_column.v` (+200 cells)

```
// New features to add:
reg [7:0]  threshold_adaptive;  // θ(t) adapts on spikes
reg [7:0]  stdp_trace_pre;       // Pre-synaptic trace
reg [7:0]  stdp_trace_post;      // Post-synaptic trace
reg [15:0] weight_stdp;        // Plasticity-enabled weight
reg [7:0]  firing_rate_target;   // Homeostatic target
reg        excitatory_only;     // E/I channel selection
```

### Features

1. **Adaptive threshold** — θ(t+1) = θ(t) + Δθ when fire, decay otherwise
2. **STDP trace** — Capture pre/post spike timing
3. **Homeostatic plasticity** — Regulate to target firing rate
4. **Separate E/I channels** — Biological fidelity
5. **R-SI-1 compliant** — Zero `*` operators (shift-add only)

### ✅ Acceptance Criteria

- [ ] Adaptive threshold increases on spike, decays otherwise
- [ ] STDP traces capture spike timing
- [ ] Homeostatic plasticity regulates firing rate
- [ ] Testbench: `test/tb_adaptive_lif.v`
- [ ] Integration test: `test/tb_cortical_adaptive.v`

### 📊 Timeline

**3 weeks** (Phase 3, Weeks 7-9)

### 🔗 Dependencies

- Depends on: Base `cortical_column.v`
- Blocks: SN-02 (uses adaptive threshold)

### 📖 References

- [FPGA-Based Adaptive LIF Neuron](https://www.researchgate.net/publication/391587111) — IEEE 2025
- [STDP in neuromorphic hardware](https://arxiv.org/abs/2006.01010)

### 🎯 Success Metric

Adaptive LIF neuron demonstrates learning behavior (firing rate adaptation to stimulus patterns).

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan