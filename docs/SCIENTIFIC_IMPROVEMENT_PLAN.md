# TRI-NET 2026 Scientific Improvement Plan

Based on analysis of 2025-2026 research papers in neuromorphic computing, AI safety, and formal verification.

---

## Executive Summary

| Priority | Focus Area | Impact | Effort |
|----------|-----------|--------|--------|
| P0 | DARPA CLARA Compliance | High (funding) | Medium |
| P0 | Energy Efficiency 1000× | High (differentiation) | High |
| P1 | SNN-TRI Fusion | Medium | Medium |
| P1 | Coq Formal Verification | High (safety) | High |
| P2 | PhD Publication | High | Medium |
| P2 | Open Source Community | Medium | Low |

---

## Part 1: DARPA CLARA Program Alignment

### Research Context

**DARPA CLARA** (AI Safety) extends to **June 22, 2026** with up to **$2M per contract** for integrating Automated Reasoning (AR) + ML components. The program emphasizes:

1. **Behavioral proof primitives** for AI systems
2. **High-assurance AI** with formal guarantees
3. **AR-ML tight integration** not just post-hoc monitoring

### Current State

| CLARA Gap | Status | Gap Analysis |
|-----------|--------|--------------|
| Gap-1: Redteam detection | ✅ Implemented | No adversarial training loop |
| Gap-2: K3 ternary logic | ✅ Implemented | Limited to 2-bit trits |
| Gap-3: Datalog reasoning | ✅ Implemented | 16 clauses only |
| Gap-4: Bounded rationality | ✅ Implemented | Q1.15 φ-drift only |
| Gap-5: Explainability | ✅ Implemented | 20-bit tuple only |
| Gap-6: ASP solver | ✅ Implemented | 8 vars only |
| Gap-7: Composition | ✅ Implemented | No orchestrator policies |
| Gap-8: Proof trace | ✅ Implemented | 64 entries only |
| Gap-9: SAT solver | ✅ Implemented | DPLL-basic only |
| Gap-10: Audit log | ✅ Implemented | No cryptographic signing |

### Improvement Plan

#### CL-01: AR-ML Co-Processor Interface

**Research**: *"CLARA advances high-risk AI research through AR-ML integration"*

**Implementation**:
```
New module: ar_ml_co_processor.v (~800 cells)

Features:
  - Bidirectional AR ↔ ML communication bus
  - Proof request channel (AR → ML)
  - Decision justification channel (ML → AR)
  - Verification token exchange
  - R-SI-1 compliant (zero *)
```

**Rationale**: Enables true AR-ML integration per CLARA spec, not just monitoring.

**Timeline**: 3 weeks

---

#### CL-02: Adversarial Training Loop (Gap-1 Enhancement)

**Research**: Neuromorphic chips achieve **100-1000× energy efficiency** for adversarial detection (2025 patent surge).

**Implementation**:
```
New module: adversarial_trainer.v (~500 cells)

Features:
  - PGD (Projected Gradient Descent) in GF16
  - On-chip ε-ball computation (Q8.8)
  - L∞, L2 norm constraints
  - Sparse adversarial pattern generation
  - Zero * operators (shift-add)
```

**Rationale**: Current redteam_filter is static. Real adversaries adapt.

**Timeline**: 2 weeks

---

#### CL-03: Cryptographic Audit Trail (Gap-10 Enhancement)

**Research**: CLARA FAQ emphasizes **"behavioral proof primitives"** requiring cryptographic integrity.

**Implementation**:
```
Enhance: audit_log_ring_buffer.v (+200 cells)

Features:
  - BLAKE3 hash chaining (already have blake3_anchor.v)
  - Merkle tree root in Crown47 ROM
  - Nonce from hwrng_lfsr
  - Tamper-evident overwrite detection
  - Timestamp via free-running counter
```

**Rationale**: Prevents audit log tampering per CLARA requirements.

**Timeline**: 1 week

---

#### CL-04: Coq Verification Export

**Research**: LLM-generated ACSL annotations for formal verification (arXiv:2602.13851, Nov 2025).

**Implementation**:
```
New tool: coq_export.py (Python script)

Features:
  - Parse Verilog → Coq extraction specification
  - Generate functional model in Coq
  - Auto-prove key invariants:
    * φ² + φ⁻² = 3
    * K3 truth table completeness
    * GF16 field axioms
  - Export proof certificates
```

**Rationale**: Enables formal verification without manual Coq work.

**Timeline**: 4 weeks

---

## Part 2: Energy Efficiency Breakthrough (1000× Target)

### Research Context

2025-2026 research shows:

1. **"Brain-like chips could slash AI energy use by 70%"** — ScienceDaily 2026
2. **"Neuromorphic chips achieve 100-1000× energy efficiency"** — PatSnap 2025 patent surge
3. **"Energy-aware FPGA implementation of SNN with LIF neurons"** — arXiv:2411.01628
4. **"FPGA-based adaptive LIF neuron"** — IEEE Transactions 2025

### Current State

| Mode | Power (SKY130A) | TOPS/W |
|------|-----------------|--------|
| Idle | 60-120 mW | — |
| Normal | 120-240 mW | 208-405 |
| AVS-96 adaptive | 28-240 mW | **405** |

### Improvement Plan

#### EN-01: Subthreshold Clock Gating (100× Idle)

**Research**: *"Subthreshold clock gating achieves 100× idle power reduction"* — Energy-aware SNN FPGA work.

**Implementation**:
```
New module: subth_clock_gate.v (~300 cells)

Features:
  - Membrane potential monitor per column
  - Dynamic voltage/frequency scaling (DVFS)
  - Clock gating when V_mem < 0.25 * V_threshold
  - Wake-on-spike threshold
  - R-SI-1: zero * operators
```

**Projected Impact**: Idle power 120 mW → **1.2 mW**

**Timeline**: 2 weeks

---

#### EN-02: Event-Driven Compute (10× Active)

**Research**: *"SNNs are 3rd generation NN with event-driven sparsity"* — arXiv:2502.20415

**Implementation**:
```
Enhance: cortical_column.v (+150 cells)

Features:
  - Spike-triggered compute (not clock-driven)
  - Null PE bypass on zero stimulus
  - Sparse activation routing
  - Stochastic computing for probabilistic neurons
```

**Projected Impact**: Active power 240 mW → **24 mW** at 50% sparsity

**Timeline**: 2 weeks

---

#### EN-03: Analog Neuron Hybrid (1000× Target)

**Research**: €15M LED-based neuromorphic computer project (2025) explores **analog+digital hybrid**.

**Implementation**:
```
Research module: analog_neuron_digital_ctrl.v (TBD)

Features:
  - Subthreshold CMOS neuron (analog domain)
  - Digital SPIKE_OUT / membrane read
  - Configurable τ, threshold via digital registers
  - Self-timed operation (no global clock)
```

**Note**: Requires advanced node (22FDX). For SKY130A, implement **stochastic digital approximation**.

**Projected Impact**: Active power 240 mW → **0.24 mW** (advanced node)

**Timeline**: 6 weeks (research phase)

---

## Part 3: SNN-TRI Fusion (Neuromorphic Enhancement)

### Research Context

Recent 2025 SNN hardware papers:

1. **[PDF] arXiv:2502.20415** — SNNs as 3rd generation NN
2. **[IEEE 2025]** — FPGA-Based Adaptive LIF Neuron
3. **[SETSCI 2025]** — FPGA-based SNN with membrane thresholding
4. **[Washington U 2025]** — Spiking Neural Networks on PYNQ-Z2

### Current State

| Component | Implementation | Gap |
|-----------|----------------|-----|
| LIF neuron | ✅ Basic (decay=>>3) | No adaptation, no STDP |
| Spiking | ✅ 1-bit spike_out | No burst, no refractory dynamics |
| Cortical | ✅ 8 columns | No lateral inhibition |

### Improvement Plan

#### SN-01: Adaptive LIF Neuron

**Research**: *"FPGA-Based Adaptive LIF Neuron for High-Speed Energy-Efficient SNN"* — IEEE 2025

**Implementation**:
```
Enhance: cortical_column.v (+200 cells)

Features:
  - Adaptive threshold (θ increases on fire, decays otherwise)
  - STDP (Spike-Timing-Dependent Plasticity) trace
  - Homeostatic plasticity (target firing rate)
  - Separate excitatory/inhibitory channels
```

**Rationale**: Enables learning and adaptation on-chip.

**Timeline**: 3 weeks

---

#### SN-02: Lateral Inhibition Network

**Research**: *"Cortical columns exhibit lateral inhibition"* — Neuroscience consensus.

**Implementation**:
```
New module: lateral_inhib_net.v (~400 cells)

Features:
  - 8×8 inhibition matrix (one-hot suppression)
  - Distance-based inhibition strength
  - K3 ternary inhibitory weights {-1,0,+1}
  - Real-time winner-take-all dynamics
```

**Rationale**: Mimics biological cortex, improves pattern separation.

**Timeline**: 2 weeks

---

#### SN-03: STDP Learning Module

**Research**: *"STDP enables unsupervised feature extraction"* — SNN literature.

**Implementation**:
```
New module: stdp_learning.v (~600 cells)

Features:
  - Pre-post spike timing capture
  - Δw calculation (exponential decay)
  - Weight normalization (L2 constraint)
  - Plasticity gate (learning enable/disable)
```

**Rationale**: On-chip unsupervised learning.

**Timeline**: 3 weeks

---

## Part 4: PhD Publication Path

### Research Alignment

The project anchors on **DOI: 10.5281/zenodo.19227877** with PhD chapters:

| Glava | Topic | Current Status | Publication Ready |
|-------|-------|----------------|------------------|
| Glava 28 | φ²+φ⁻²=3, GF16, VSA | ✅ Implemented | ✅ |
| Glava 29 | Cassini POST | ✅ Implemented | ✅ |
| Glava 30 | BitNet b1.58 | ✅ Implemented | ⚠️ Needs benchmarks |
| Glava 31 | K3 logic, t27 ISA | ✅ Implemented | ⚠️ Needs proofs |
| Glava 32 | FHRR hypervectors | ✅ Implemented | ⚠️ Needs experiments |
| Glava 33 | BPB lower bound | ✅ Implemented | ⚠️ Needs Coq |
| Glava 34 | BLAKE3, audit | ✅ Implemented | ⚠️ Needs security analysis |
| Glava 35 | Crown47, sacred constants | ✅ Implemented | ✅ |
| Glava 36 | TG-TRIAD-X D2D | ✅ Implemented | ⚠️ Needs cross-chip test |

### Publication Plan

#### PUB-01: Journal Paper (arXiv first)

**Target Venue**: IEEE Transactions on Neural Networks and Learning Systems

**Title**: *"TRI-NET: Ternary Neuromorphic AI with Sacred-Constant Anchoring and Formal Verification"*

**Contributions**:
1. Novel φ²+φ⁻²=3 silicon identity proof
2. Ternary {−1,0,+1} compute substrate (R-SI-1 compliant)
3. CLARA-aligned AI safety gaps (10/10)
4. 1000× energy efficiency path (projected)

**Experiments Needed**:
- [ ] Cross-chip φ= e= γ anchor test
- [ ] Energy measurement on FPGA
- [ ] CLARA gap effectiveness metrics
- [ ] Coq proof extraction results

**Timeline**: 8 weeks

---

#### PUB-02: Conference Paper

**Target Venue**: NeurIPS 2026 (deadline ~May 2026) or IJCNN 2026

**Title**: *"Formally Verified Neuromorphic AI: From Ternary Logic to Silicon Proofs"*

**Contributions**:
1. Coq verification of φ²+φ⁻²=3 in silicon
2. R-SI-1: zero DSP constraint → formal guarantees
3. AR-ML co-processor for CLARA compliance
4. Energy-aware neuromorphic design

**Timeline**: 6 weeks

---

#### PUB-03: PhD Dissertation

**Defense Date**: 2026-06-15

**Required Deliverables**:
- [ ] All 36 Glava chapters with Coq proofs
- [ ] Silicon return from TTSKY26b (measured, not projected)
- [ ] 3 peer-reviewed papers
- [ ] Open source t27 toolchain v2.0
- [ ] Falsifiability witnesses (R7, Appendix B)

**Critical Path**:
1. Silicon return (Jan 2026)
2. Measurement campaigns (Feb-Mar 2026)
3. Paper submissions (Apr 2026)
4. Dissertation writing (May 2026)

---

## Part 5: Open Source Community

### Research Context

GitHub show strong interest in:
- **Neuromorphic computing** (openSpike, Norse, Lava)
- **Ternary networks** (BitNet, TernaryBERT)
- **Formal verification** (Coq, SymbiYosys)

### Improvement Plan

#### OS-01: t27 Toolchain v2.0

**Features**:
- CLI: `t27 generate --target=verilog --chip=gamma`
- Plugins: CLARA gap generator, ROM generator
- LSP: VS Code extension for .t27 files
- Verification: `t27 verify --sby --coq`

**Timeline**: 6 weeks

---

#### OS-02: CI/CD for Community

**Features**:
- GitHub Actions matrix (phi/euler/gamma × all tests)
- Automated coverage reporting
- Badge updates (GDS, test, lint)
- Documentation preview (Netlify)

**Timeline**: 2 weeks

---

#### OS-03: Python SDK

**Features**:
- `pip install trinity` → Python bindings
- Jupyter notebook tutorials
- D2D mesh simulation in Python
- CLARA gap testing harness

**Timeline**: 4 weeks

---

## Timeline Summary

```
Week 1-4:  CL-01 (AR-ML Co-Processor)
Week 1-2:  CL-02 (Adversarial Training Loop)
Week 1:     CL-03 (Crypto Audit Trail)
Week 1-4:  CL-04 (Coq Export Tool)
Week 3-4:  EN-01 (Subthreshold Clock Gating)
Week 5-6:  EN-02 (Event-Driven Compute)
Week 7-12: EN-03 (Analog Hybrid Research)
Week 7-9:  SN-01 (Adaptive LIF Neuron)
Week 9-10: SN-02 (Lateral Inhibition)
Week 11-13: SN-03 (STDP Learning)
Week 1-8:  PUB-01 (Journal Paper)
Week 1-6:  PUB-02 (Conference Paper)
Week 1-6:  OS-01 (t27 v2.0)
Week 1-2:  OS-02 (CI/CD)
Week 1-4:  OS-03 (Python SDK)
```

---

## Priority Execution Order

### Phase 1 (Weeks 1-4): DARPA CLARA Compliance
1. CL-03: Crypto Audit Trail (1 week) → Quick win
2. CL-04: Coq Export Tool (4 weeks) → Foundation
3. CL-02: Adversarial Training (2 weeks) → Gap-1 enhancement
4. PUB-02: Conference paper (6 weeks, parallel)

### Phase 2 (Weeks 5-8): Energy Efficiency
1. EN-01: Subthreshold Clock Gating (2 weeks) → 100× idle
2. EN-02: Event-Driven Compute (2 weeks) → 10× active
3. OS-01: t27 v2.0 (6 weeks, parallel)
4. PUB-01: Journal paper (8 weeks, parallel)

### Phase 3 (Weeks 9-12): Neuromorphic Enhancement
1. SN-01: Adaptive LIF (3 weeks) → Learning
2. SN-02: Lateral Inhibition (2 weeks) → Cortex
3. SN-03: STDP Learning (3 weeks) → Plasticity
4. OS-02/OS-03: Community tools (6 weeks, parallel)

---

## Success Metrics

| Metric | Current | Target | How to Measure |
|--------|---------|--------|----------------|
| CLARA gaps functional | 10/10 | 10/10 enhanced | Integration tests |
| Energy efficiency | 405 TOPS/W | 4000 TOPS/W | Power meter on FPGA |
| Formal proofs | 0 auto | 10 modules | Coq export tool |
| Papers published | 0 | 2-3 | arXiv/IEEE |
| t27 downloads | N/A | 1000/month | PyPI stats |
| GitHub stars | N/A | 500 | GitHub API |

---

## References

### Neuromorphic & SNN
- [Spiking Neural Networks on FPGAs](https://ese.washu.edu/documents/Spiking-Neural-Networks-on-FPGAs.pdf) — Washington U 2025
- [FPGA-Based Adaptive LIF Neuron](https://www.researchgate.net/publication/391587111) — IEEE 2025
- [arXiv:2502.20415](https://arxiv.org/pdf/2502.20415) — SNNs as 3rd generation NN
- [arXiv:2411.01628](https://arxiv.org/abs/2411.01628) — Energy-aware SNN FPGA

### DARPA CLARA
- [CLARA - DARPA](https://www.darpa.mil/research/programs/clara) — Program overview
- [CLARA FAQ](https://www.darpa.mil/sites/default/files/attachment/2026-04/clara-program-darpa-faqs.pdf) — Behavioral proofs
- [International AI Safety Report 2025](https://internationalaisafetyreport.org/) — Context

### Formal Verification
- [LLM-Generated ACSL Annotations](https://arxiv.org/html/2602.13851v2) — arXiv 2025
- [SymbiYosys](https://symbiyosys.readthedocs.io/) — Formal verification flow

### Energy Efficiency
- [Neuromorphic computing patents surge 401%](https://www.patsnap.com/) — 100-1000× efficiency
- [Brain-like chips slash energy 70%](https://www.sciencedaily.com/) — 2026 breakthrough

---

*Generated: 2026-05-18*

---

**Sources:**
- [Spiking Neural Networks on FPGAs](https://ese.washu.edu/documents/Spiking-Neural-Networks-on-FPGAs.pdf)
- [FPGA-Based Adaptive LIF Neuron](https://www.researchgate.net/publication/391587111)
- [arXiv:2502.20415](https://arxiv.org/pdf/2502.20415)
- [arXiv:2411.01628](https://arxiv.org/abs/2411.01628)
- [LLM-Generated ACSL Annotations](https://arxiv.org/html/2602.13851v2)
- [CLARA - DARPA](https://www.darpa.mil/research/programs/clara)
- [CLARA FAQ](https://www.darpa.mil/sites/default/files/attachment/2026-04/clara-program-darpa-faqs.pdf)
- [International AI Safety Report 2025](https://internationalaisafetyreport.org/)