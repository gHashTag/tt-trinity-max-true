---
title: "[SN-02] Lateral Inhibition Network"
labels: "neuromorphic, cortex, priority:P1, size:medium"
assignees: "gHashTag"
---

## SN-02: Lateral Inhibition Network

### 📚 Research Context

> *"Cortical columns exhibit lateral inhibition"* — Neuroscience consensus

Biological cortex has lateral inhibition: when one column fires, it suppresses neighboring columns. This enables:
- **Winner-take-all** dynamics
- **Pattern separation**
- **Contrast enhancement**

### 🎯 Objective

Implement 8×8 lateral inhibition network for 8 cortical columns.

### 📋 Implementation

**New module**: `src/lateral_inhib_net.v` (~400 cells)

```
module lateral_inhib_net (
    // Clock and reset
    input  wire clk,
    input  wire rst_n,

    // Column spike inputs
    input  wire [7:0]  column_spikes_in,

    // Inhibition parameters (K3 ternary: -1,0,+1)
    input  wire [1:0]  inhib_w_00,  inhib_w_01, ..., inhib_w_77,  // 8×8 = 64 weights

    // Distance-based scaling (Q8.8)
    input  wire [7:0]  distance_scale,

    // Lateral inhibition outputs
    output reg  [7:0]  inhibition_out,
    output wire       wta_winner,      // Winner-take-all flag
    output wire [2:0]  wta_winner_idx  // Which column won
);
```

### Features

1. **8×8 inhibition matrix** — One-hot suppression pattern
2. **Distance-based inhibition** — Further = weaker inhibition
3. **K3 ternary inhibitory weights** — {-1,0,+1} encoding
4. **Real-time WTA** — Winner-take-all dynamics
5. **R-SI-1 compliant** — Zero `*` operators

### ✅ Acceptance Criteria

- [ ] 8×8 inhibition matrix implemented
- [ ] K3 ternary weights used correctly
- [ ] WTA dynamics verified (single winner)
- [ ] Distance-based scaling works
- [ ] Testbench: `test/tb_lateral_inhib_net.v`
- [ ] Integration test: `test/tb_cortex_lateral.v`

### 📊 Timeline

**2 weeks** (Phase 3, Weeks 9-10)

### 🔗 Dependencies

- Depends on: `cortical_column.v` spike outputs
- Blocks: SN-03 (uses inhibition)

### 📖 References

- [Lateral inhibition in cortex](https://www.ncbi.nlm.nih.gov/pmc/)
- [Winner-take-all networks](https://arxiv.org/abs/2004.08773)

### 🎯 Success Metric

Lateral inhibition network demonstrates WTA dynamics with clear pattern separation.

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan