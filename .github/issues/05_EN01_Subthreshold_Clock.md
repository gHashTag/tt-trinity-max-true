---
title: "[EN-01] Subthreshold Clock Gating - 100× Idle"
labels: "power-efficiency, priority:P0, size:medium"
assignees: "gHashTag"
---

## EN-01: Subthreshold Clock Gating (100× Idle)

### 📚 Research Context

> *"Subthreshold clock gating achieves 100× idle power reduction"* — Energy-aware SNN FPGA work, arXiv:2411.01628

2025 research shows neuromorphic chips can achieve **100-1000× energy efficiency gains** through event-driven operation and power gating.

### 🎯 Objective

Implement per-cortex-column clock gating based on membrane potential, achieving 100× idle power reduction.

### 📋 Implementation

**New module**: `src/subth_clock_gate.v` (~300 cells)

```
module subth_clock_gate (
    // Clock control
    input  wire clk,
    input  wire rst_n,

    // Membrane potential monitors (8 columns)
    input  wire [7:0] mem_pot_0,
    input  wire [7:0] mem_pot_1,
    input  wire [7:0] mem_pot_2,
    input  wire [7:0] mem_pot_3,
    input  wire [7:0] mem_pot_4,
    input  wire [7:0] mem_pot_5,
    input  wire [7:0] mem_pot_6,
    input  wire [7:0] mem_pot_7,

    // Threshold configuration (Q8.8)
    input  wire [15:0] wake_threshold,

    // Gated clock outputs
    output wire clk_gate_0,
    output wire clk_gate_1,
    output wire clk_gate_2,
    output wire clk_gate_3,
    output wire clk_gate_4,
    output wire clk_gate_5,
    output wire clk_gate_6,
    output wire clk_gate_7,

    // Status
    output wire [7:0]  active_columns,
    output wire        all_idle
);
```

### Features

1. **Membrane potential monitor** — Per column V_mem tracking
2. **Dynamic voltage/frequency scaling (DVFS)** — Clock division based on activity
3. **Clock gating** — Gating when V_mem < 0.25 × V_threshold
4. **Wake-on-spike** — Immediate clock restore on spike detection
5. **R-SI-1 compliant** — Zero `*` operators

### ✅ Acceptance Criteria

- [ ] Module compiles with R-SI-1 compliance
- [ ] Clock gating activates when V_mem < threshold
- [ ] Clock restores within 2 cycles on spike detection
- [ ] Idle power reduced to <1.2 mW (vs 120 mW baseline)
- [ ] Testbench: `test/tb_subth_clock_gate.v`
- [ ] Power analysis: `scripts/power_analysis.py`

### 📊 Timeline

**2 weeks** (Phase 2, Weeks 3-4)

### 🔗 Dependencies

- Depends on: `cortical_column.v` (membrane_potential outputs)
- Blocks: EN-02 (uses gated clocks)

### 📖 References

- [Energy-aware FPGA implementation of SNN](https://arxiv.org/abs/2411.01628)
- [FPGA-Based Adaptive LIF Neuron](https://www.researchgate.net/publication/391587111)

### 🎯 Success Metric

Idle power reduced from 120 mW to **1.2 mW** (100× improvement).

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan