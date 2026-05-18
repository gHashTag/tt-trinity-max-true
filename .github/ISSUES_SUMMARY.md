# TRI-NET 2026 Improvement Plan — Issues Summary

## Epic Issue

**#0**: [EPIC] TRI-NET 2026 Scientific Improvement Plan

Master epic linking all 16 sub-issues across 5 focus areas.

---

## All Issues (16 total)

### Part 1: DARPA CLARA Program Alignment

| # | Issue | Priority | Timeline | Status |
|---|-------|----------|----------|--------|
| #1 | CL-01: AR-ML Co-Processor Interface | P0 | 3 weeks | 📄 File |
| #2 | CL-02: Adversarial Training Loop (Gap-1) | P0 | 2 weeks | 📄 File |
| #3 | CL-03: Cryptographic Audit Trail (Gap-10) | P0 | 1 week | 📄 File |
| #4 | CL-04: Coq Verification Export Tool | P1 | 4 weeks | 📄 File |

### Part 2: Energy Efficiency Breakthrough (1000× Target)

| # | Issue | Priority | Timeline | Status |
|---|-------|----------|----------|--------|
| #5 | EN-01: Subthreshold Clock Gating (100× Idle) | P0 | 2 weeks | 📄 File |
| #6 | EN-02: Event-Driven Compute (10× Active) | P0 | 2 weeks | 📄 File |
| #7 | EN-03: Analog Neuron Hybrid (1000× Target) | P1 | 6 weeks | 📄 File |

### Part 3: SNN-TRI Fusion (Neuromorphic Enhancement)

| # | Issue | Priority | Timeline | Status |
|---|-------|----------|----------|--------|
| #8 | SN-01: Adaptive LIF Neuron | P1 | 3 weeks | 📄 File |
| #9 | SN-02: Lateral Inhibition Network | P1 | 2 weeks | 📄 File |
| #10 | SN-03: STDP Learning Module | P1 | 3 weeks | 📄 File |

### Part 4: PhD Publication Path

| # | Issue | Priority | Timeline | Status |
|---|-------|----------|----------|--------|
| #11 | PUB-01: Journal Paper (arXiv first) | P2 | 8 weeks | 📄 File |
| #12 | PUB-02: Conference Paper | P2 | 6 weeks | 📄 File |
| #13 | PUB-03: PhD Dissertation | P2 | Ongoing | 📄 File |

### Part 5: Open Source Community

| # | Issue | Priority | Timeline | Status |
|---|-------|----------|----------|--------|
| #14 | OS-01: t27 Toolchain v2.0 | P2 | 6 weeks | 📄 File |
| #15 | OS-02: CI/CD for Community | P2 | 2 weeks | 📄 File |
| #16 | OS-03: Python SDK | P2 | 4 weeks | 📄 File |

---

## Issue Dependencies

```
┌─────────────────────────────────────────────────────────────┐
│ #0 EPIC: TRI-NET 2026 Scientific Improvement Plan          │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
    ┌───▼───┐         ┌───▼───┐         ┌───▼───┐
    │ Part 1 │         │ Part 2 │         │ Part 3 │
    │ CLARA  │         │ Energy │         │  SNN   │
    └───┬───┘         └───┬───┘         └───┬───┘
        │                 │                 │
    ┌───▼─────────────────▼─────────────────▼───┐
    │ #1 CL-01   #5 EN-01        #8 SN-01     │
    │ #2 CL-02   #6 EN-02        #9 SN-02     │
    │ #3 CL-03   #7 EN-03        #10 SN-03    │
    │ #4 CL-04                              │
    └─────────────────────────────────────┘
        │                 │                 │
    ┌───▼─────────────────▼─────────────────▼───┐
    │          Part 4: Publications           │
    │     #11 PUB-01   #12 PUB-02   #13 PUB-03 │
    └─────────────────────────────────────┘
        │
    ┌───▼───────────────────────────────┐
    │      Part 5: Community Tools      │
    │ #14 OS-01   #15 OS-02   #16 OS-03 │
    └───────────────────────────────────┘
```

### Dependency Details

**#1 CL-01** → Blocks: None, but enables CL-02, CL-03 (uses verification token)

**#4 CL-04** → Foundation for CL-01 proof generation

**#5 EN-01** → Enables EN-02 (provides gated clocks)

**#8 SN-01** → Blocks: SN-02 (uses adaptive threshold)

---

## Timeline Overview

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

## Creation Script

After GitHub CLI is re-authenticated (`gh auth login`), run:

```bash
cd tt-trinity-gamma/.github
./create_issues.sh
```

This will create all 16 issues and output their numbers for linking.

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| CLARA gaps functional | 10/10 | 10/10 enhanced |
| Energy efficiency | 405 TOPS/W | 4000 TOPS/W |
| Formal proofs | 0 auto | 10 modules |
| Papers published | 0 | 2-3 |
| t27 downloads | N/A | 1000/month |
| GitHub stars | N/A | 500 |

---

## How to Link Issues

After creation:

1. Open the Epic issue (#0)
2. In the issue body, add:
   ```
   ## Sub-Issues
   - Closes #1
   - Closes #2
   ...
   ```
3. Comment on each sub-issue:
   ```
   Related to #0
   ```

---

*Generated: 2026-05-18*

---

**Files:**
- `.github/issues/00_EPIC_2026.md`
- `.github/issues/01_CL01_AR_ML_Coprocessor.md` → `#1`
- `.github/issues/02_CL02_Adversarial_Training.md` → `#2`
- `.github/issues/03_CL03_Crypto_Audit.md` → `#3`
- `.github/issues/04_CL04_Coq_Export.md` → `#4`
- `.github/issues/05_EN01_Subthreshold_Clock.md` → `#5`
- `.github/issues/06_EN02_Event_Driven_Compute.md` → `#6`
- `.github/issues/07_EN03_Analog_Neuron.md` → `#7`
- `.github/issues/08_SN01_Adaptive_LIF.md` → `#8`
- `.github/issues/09_SN02_Lateral_Inhibition.md` → `#9`
- `.github/issues/10_SN03_STDP_Learning.md` → `#10`
- `.github/issues/11_PUB01_Journal_Paper.md` → `#11`
- `.github/issues/12_PUB02_Conference_Paper.md` → `#12`
- `.github/issues/13_PUB03_PhD_Dissertation.md` → `#13`
- `.github/issues/14_OS01_t27_Toolchain_v2.md` → `#14`
- `.github/issues/15_OS02_CI_CD_Community.md` → `#15`
- `.github/issues/16_OS03_Python_SDK.md` → `#16`