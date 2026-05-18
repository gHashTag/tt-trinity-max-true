---
title: "[EN-03] Analog Neuron Hybrid - 1000× Target"
labels: "power-efficiency, analog, research, priority:P1, size:large"
assignees: "gHashTag"
---

## EN-03: Analog Neuron Hybrid (1000× Target)

### 📚 Research Context

> *€15M LED-based neuromorphic computer project (2025) explores analog+digital hybrid*

Analog neuron implementations in advanced nodes (22FDX, FinFET) can achieve **1000× energy efficiency** over digital-only designs. SKY130A is 130nm — suboptimal for analog but suitable for **stochastic digital approximation**.

### 🎯 Objective

Research and design analog neuron hybrid architecture with digital control interface.

### 📋 Implementation

**Research module**: `src/analog_neuron_digital_ctrl.v` (TBD cells)

```
module analog_neuron_digital_ctrl (
    // Digital interface
    input  wire clk_dig,
    input  wire rst_n_dig,
    input  wire ena,

    // Neuron configuration (digital registers)
    input  wire [7:0] tau_decay,        // Membrane time constant
    input  wire [7:0] threshold,       // Spike threshold
    input  wire [7:0] reset_potential,  // V_reset

    // Analog monitor outputs
    input  wire [15:0] membrane_analog, // 16-bit ADC read
    output wire        spike_analog,      // Comparator output

    // Digital outputs
    output reg         spike_out_dig,     // Synchronized spike
    output wire [7:0]  membrane_dig,     // ADC sample

    // Self-timed operation flag
    output wire        self_timed,
    output wire        clk_en            // Clock enable (self-timed)
);
```

### Features

1. **Subthreshold CMOS neuron** (analog domain) — Native physics-based membrane dynamics
2. **Digital SPIKE_OUT** — Synchronized to digital domain
3. **Membrane read** — 16-bit ADC sample for digital processing
4. **Configurable parameters** — τ, threshold, V_reset via digital registers
5. **Self-timed operation** — No global clock (event-driven)

### ⚠️ Note

**SKY130A limitation**: For 130nm process, implement **stochastic digital approximation**:
- Probabilistic neuron firing
- Temperature-dependent noise modeling
- Variability-aware operation

### ✅ Acceptance Criteria

- [ ] Digital control interface designed
- [ ] Stochastic approximation model implemented for SKY130A
- [ ] Self-timed operation verified
- [ ] Power analysis shows path to 1000× (advanced node)
- [ ] Research document: `docs/ANALOG_NEURON_RESEARCH.md`
- [ ] Testbench: `test/tb_analog_neuron_digital_ctrl.v`

### 📊 Timeline

**6 weeks** (Phase 2, Weeks 7-12, research phase)

### 🔗 Dependencies

- None — research project, can run in parallel

### 📖 References

- [Subthreshold CMOS design](https://ieeexplore.ieee.org/)
- [LED-based neuromorphic computer](https://www.eurekalert.org/)
- [Self-timed circuits](https://dl.acm.org/)

### 🎯 Success Metric

Research report documenting path to **1000× energy efficiency** on advanced node, with stochastic approximation for SKY130A achieving at least 10×.

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan