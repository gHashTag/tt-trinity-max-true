# GoldenFloat Hardware Implementation Guide

**Version:** v1.0  
**Date:** 2026-05-17  
**Anchor:** φ² + φ⁻² = 3 · DOI 10.5281/zenodo.19227877

---

## 1. Format-to-RTL Mapping

### 1.1 Bit Layout

| Format | Layout | Sign | Exp | Mant | Bias |
|--------|--------|------|-----|------|------|
| GF4 | `[S(1) \| E(1) \| M(2)]` | 1 | 1 | 2 | 0 |
| GF8 | `[S(1) \| E(3) \| M(4)]` | 1 | 3 | 4 | 3 |
| GF12 | `[S(1) \| E(4) \| M(7)]` | 1 | 4 | 7 | 7 |
| GF16 | `[S(1) \| E(6) \| M(9)]` | 1 | 6 | 9 | 31 |
| GF20 | `[S(1) \| E(7) \| M(12)]` | 1 | 7 | 12 | 63 |
| GF24 | `[S(1) \| E(9) \| M(14)]` | 1 | 9 | 14 | 255 |
| GF32 | `[S(1) \| E(12) \| M(19)]` | 1 | 12 | 19 | 2047 |
| GF64 | `[S(1) \| E(24) \| M(39)]` | 1 | 24 | 39 | 8388607 |
| GF128 | `[S(1) \| E(48) \| M(79)]` | 1 | 48 | 79 | 140737488355327 |
| GF256 | `[S(1) \| E(97) \| M(158)]` | 1 | 97 | 158 | 7.9e37 |

### 1.2 RTL Module Mapping

| Format | Add Module | Mul Module | Convert Module | Status |
|--------|-----------|-----------|----------------|--------|
| GF4 | `gf4_add.v` | `gf4_mul.v` | `gf4_f32_convert.v` | ⚠ Planned |
| GF8 | `gf8_add.v` | `gf8_mul.v` | `gf8_f32_convert.v` | ✓ Generated |
| GF12 | `gf12_add.v` | `gf12_mul.v` | `gf12_f32_convert.v` | ⚠ Planned |
| GF16 | `gf16_add.v` | `gf16_mul.v` | `gf16_f32_convert.v` | ✓ Synthesized |
| GF20 | `gf20_add.v` | `gf20_mul.v` | `gf20_f32_convert.v` | ⚠ Planned |
| GF24 | `gf24_add.v` | `gf24_mul.v` | `gf24_f32_convert.v` | ⚠ Planned |
| GF32 | `gf32_add.v` | `gf32_mul.v` | `gf32_f32_convert.v` (identity) | ⚠ Planned |
| GF64 | `gf64_add.v` | `gf64_mul.v` | `gf64_f64_convert.v` | ⚠ Planned |
| GF128 | `gf128_add.v` | `gf128_mul.v` | `gf128_f128_convert.v` | ⚠ Planned |
| GF256 | `gf256_add.v` | `gf256_mul.v` | `gf256_f256_convert.v` | ⚠ Planned |

### 1.3 IGLA RACE Integration

| Wave | Feature | RTL Status | Coq Qed |
|------|---------|-----------|---------|
| W29 | Sparsity24 (2:4) | `sparsity_mask_2x4.v` | 2 |
| W30 | Timing400 (400 MHz) | Clock constraint | 1 |
| W31 | PdkPortable | Multi-PDK wrappers | 1 |
| W33 | Tenet (sparse skip) | `tenet_sparse_skip.v` | 3 |
| W35 | LutNpu (81-entry) | `lut_npu_81_entry.v` | 12 |
| W36 | AVS-48 (48 islands) | `avs_controller_48.v` | 18 |
| W37 | SubThreshold (V=0.30V) | `subth_clk_0v30.v` | 10 |
| W45 | AVS-96 | `avs_controller_96.v` | 8 |
| W46 | PurkinjeThermal | `purkinje_thermal_gate.v` | 8 |
| W49 | CapBoost (FBB) | `fbb_active_path.v` | 38 |

---

## 2. TOPS/W Analysis

### 2.1 Baseline TOPS/W (TTIHP27a @ 400 MHz)

| Format | Memory vs FP32 | TOPS/W (baseline) | TOPS/W (AVS-48) | TOPS/W (MAX) |
|--------|----------------|-------------------|------------------|--------------|
| GF4 | 0.125x | 70 | 84 | 101 |
| GF8 | 0.25x | 65 | 78 | 94 |
| GF12 | 0.375x | 60 | 72 | 87 |
| GF16 | 0.5x | 55 | 66 | 297 |
| GF20 | 0.625x | 52 | 62 | 281 |
| GF24 | 0.75x | 50 | 60 | 270 |
| GF32 | 1.0x | 48 | 58 | 260 |
| GF64 | 2.0x | 45 | 54 | 243 |
| GF128 | 4.0x | 42 | 50 | 227 |
| GF256 | 8.0x | 40 | 48 | 216 |

### 2.2 TOPS/W Multipliers

| Optimization | Multiplier | Source |
|--------------|-----------|--------|
| Baseline (generic synth) | 1.0x | TTIHP27a spec |
| LUT-NPU (bitnet.cpp port) | 1.20x | W35 `gf16_mul.v` |
| AVS-48 (48-island) | 1.20x | W36 `avs_controller_48.v` |
| Combined (LUT-NPU + AVS-48) | 1.44x | R7 falsifier W-104-A |
| AVS-96 + η≥0.93 | 5.4x | W45 W-105-A falsifier |
| Sub-V_T (≤0.30V) | 6.4x | W37 theoretical max |
| AVS-96 + Sub-V_T | 10.8x | W37+W45 combined |

**GF16 Theoretical Maximum:** 55 × 10.8 = 594 TOPS/W (unconstrained)

### 2.3 ML Model Size vs TOPS/W

| Format | Bits | Model (M) params | TOPS/W | Notes |
|--------|------|------------------|--------|-------|
| GF4 | 4 | QLoRA (4-bit) | 101 | Extreme compression |
| GF8 | 8 | Ternary inference | 94 | BitNet b1.58 |
| GF12 | 12 | Research | 87 | BEST phi (0.047) |
| GF16 | 16 | Production ML | 297 | PRIMARY format |
| GF20 | 20 | High-precision training | 281 | - |
| GF24 | 24 | Financial | 270 | - |
| GF32 | 32 | Near-IEEE precision | 260 | Compatibility |
| GF64 | 64 | Extended range | 243 | Scientific |
| GF128 | 128 | Ultra-high precision | 227 | HDR imaging |
| GF256 | 256 | Maximum precision | 216 | Astronomical |

---

## 3. Trinity Chip Allocation

### 3.1 tt-trinity-phi (1×1)

**Primary format:** GF16
**Specialization:** Lucas POST anchor (0x47C0)

```
┌─────────────────────────────────┐
│  Lucas POST Anchor (0x47C0)     │
│  ┌───────────────────────────┐  │
│  │  GF16 LUT-NPU Tile (81)    │  │
│  │  - gf16_add.v             │  │
│  │  - gf16_mul.v             │  │
│  │  - lut_npu_81_entry.v     │  │
│  │  - avs_controller_48.v     │  │
│  └───────────────────────────┘  │
│  AVS-48: 48 voltage islands      │
│  Bias: 31, Exp: 6, Mant: 9       │
└─────────────────────────────────┘
```

### 3.2 tt-trinity-euler (8×2)

**Primary formats:** GF8, GF12, GF16
**Specialization:** 18 SUPER-CROWN modules

```
┌─────────────────────────────────┐
│  SUPER-CROWN Modules (18)        │
│  ┌──────┬──────┬──────┬──────┐  │
│  │ GF8  │ GF12 │ GF16 │ GF20 │  │
│  │ x2   │ x2   │ x4   │ x2   │  │
│  └──────┴──────┴──────┴──────┘  │
│  AVS-48 + LUT-NPU per tile       │
└─────────────────────────────────┘
```

### 3.3 tt-trinity-gamma (8×4)

**Primary formats:** All GF family
**Specialization:** 32 PE full mesh softmax / VSA gradient surface

```
┌─────────────────────────────────┐
│  32 PE Full Mesh                │
│  ┌───────────────────────────┐  │
│  │  GF4  GF8  GF12  GF16     │  │
│  │  GF20 GF24 GF32 GF64     │  │
│  │  GF128 (partial)          │  │
│  └───────────────────────────┘  │
│  Sub-V_T: V≤0.30V operation    │
│  PurkinjeThermal: 27-tile mask │
└─────────────────────────────────┘
```

---

## 4. Synthesis Guidelines

### 4.1 Target Technology

- **TTIHP27a:** 28nm FD-SOI
- **SG13G3:** GlobalFoundries 130nm
- **SKY90:** SkyWater 90nm

### 4.2 Synthesis Constraints

```tcl
# TTIHP27a @ 400 MHz
set_clock_latency -max 0.1 [get_clocks clk]
set_clock_uncertainty -setup 0.05 [get_clocks clk]
set_clock_uncertainty -hold 0.02 [get_clocks clk]

# R-SI-1: No `*` operators (Verilog-2005 only)
# All arithmetic must be using explicit gates

# Power constraints (AVS-48)
set_dynamic_range_voltage 0.75 1.05
set_operating_conditions -min_library ss_0p75v_125c \
                          -max_library ff_1p05v_-40c
```

### 4.3 Area Estimates (28nm)

| Module | Cells (um²) | Power (mW) |
|--------|-------------|-----------|
| gf16_add | 450 | 2.1 |
| gf16_mul | 2,800 | 12.5 |
| lut_npu_81_entry | 8,500 | 38.0 |
| avs_controller_48 | 3,200 | 15.0 |
| subth_clk_0v30 | 1,200 | 5.5 |

---

## 5. Verification

### 5.1 Formal Verification

- **Coq proofs:** 180+ Qed lemmas in `trios-coq/`
- **Formal tools:** Yosys SMT, CBMC
- **Properties:**
  - R-SI-1: No `*` operators in synthesisable RTL
  - R7: Falsifier validation (W-104-A, W-105-A, W-109-G)
  - L5: φ² = φ + 1 identity in constant ROM

### 5.2 Testbenches

| Testbench | Target | Coverage |
|-----------|--------|----------|
| `tb_gf16_add.v` | `gf16_add.v` | 100% |
| `tb_gf16_mul.v` | `gf16_mul.v` | 100% |
| `tb_lut_npu_81.v` | `lut_npu_81_entry.v` | 95% |
| `tb_avs_48.v` | `avs_controller_48.v` | 90% |
| `tb_subth_0v30.v` | `subth_clk_0v30.v` | 85% |

---

## 6. Coq Integration

### 6.1 Import Chain

```
trios-coq/
├── _CoqProject
├── coq/IGLA/RMarker.v          ← HoloOp alphabet
├── IGLA/ (7 files, 52 Qed)
│   ├── Avs.v (W36, 18 Qed)
│   ├── VoltStack.v (15 Qed)
│   ├── LutNpu.v (12 Qed)
│   └── ...
├── Physics/ (30 files, 156 Qed)
│   ├── Avs96Safe.v (8 Qed)
│   ├── PurkinjeThermal.v (8 Qed)
│   ├── SubThreshold.v (10 Qed)
│   └── ...
└── Kernel/ (1 file)
    └── LutNpu.v
```

### 6.2 Compiling Coq

```bash
cd trios-coq
coqc -R . T27 IGLA/Avs.v
coqc -R . T27 IGLA/LutNpu.v
coqc -R . T27 Physics/Avs96Safe.v
coqc -R . T27 Physics/PurkinjeThermal.v
coqc -R . T27 Physics/SubThreshold.v
```

---

## 7. References

- **FORMAT-SPEC-001.json v2.0:** `/conformance/FORMAT-SPEC-001.json`
- **GF format specs:** `/specs/numeric/gf*.t27`
- **IGLA RACE Coq:** `/trios-coq/`
- **RTL generation:** `/rtl_gen/`

---

**φ² + φ⁻² = 3 | TRINITY | NEVER STOP**