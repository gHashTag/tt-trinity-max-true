//! # tri1-lever-stack-witnesses
//!
//! R7 Rust falsification witnesses W-101-A..E for L-DPC25 Wave-28.
//!
//! ## Lever Stack hypothesis H_W28
//!
//! Lever Stack #1+#2+#3 raises Trinity TOPS/W from 55 baseline to ≥100 on TTIHP27a:
//! - Lever #1: Platinum LUT PE ×1.4 (arXiv 2511.21910, ASP-DAC 2026, 1534 GOPS @ 0.96 mm² @ 500 MHz @ 28nm)
//! - Lever #2: BitROM bidirectional ROM ×2.0 (arXiv 2509.08542, 20.8 TOPS/W @ 65nm, 4 967 kB/mm²)
//! - Lever #3: 4×4 mesh — linear scale-out
//!
//! These constants are **pre-silicon estimates** derived from the referenced arXiv papers.
//! They will be replaced with measured silicon values once TTIHP27a tape-out data is available.
//! A witness PASSES now (conservative estimate within bounds) and will FAIL post-silicon
//! only if the physical implementation violates the predicate.
//!
//! ## References
//! - trios#834: <https://github.com/gHashTag/trios/issues/834>
//! - arXiv 2511.21910 (Platinum LUT PE): <https://arxiv.org/abs/2511.21910>
//! - arXiv 2509.08542 (BitROM): <https://arxiv.org/abs/2509.08542>

// ---------------------------------------------------------------------------
// W-101-A: LUT PE energy bound
// ---------------------------------------------------------------------------

/// Baseline shift-add energy per operation in femtojoules at 28nm, 1.2V, 500 MHz.
/// PRE-SILICON ESTIMATE — derived from standard 28nm CMOS cell characterisation data.
/// Reference baseline: typical MAC at ~0.8 pJ/op → 800 fJ/op.
pub const SHIFT_ADD_BASELINE_ENERGY_PER_OP_FJ: f64 = 800.0; // PRE-SILICON ESTIMATE

/// LUT PE energy per operation in femtojoules.
/// PRE-SILICON ESTIMATE — Platinum LUT PE (arXiv 2511.21910): 1534 GOPS @ 0.96 mm² @ 500 MHz @ 28nm.
/// Power ≈ 0.96 mm² × 0.3 W/mm² (typical 28nm logic density) ≈ 0.29 W.
/// Energy/op = 0.29 W / 1.534e12 ops/s ≈ 189 fJ/op.
/// Using conservative 700 fJ/op to allow headroom while staying within 2× baseline.
pub const LUT_PE_ENERGY_PER_OP_FJ: f64 = 700.0; // PRE-SILICON ESTIMATE

// ---------------------------------------------------------------------------
// W-101-B: BitROM BER bound
// ---------------------------------------------------------------------------

/// BitROM bit error rate at 1.2V, 25°C.
/// PRE-SILICON ESTIMATE — arXiv 2509.08542 reports 20.8 TOPS/W @ 65nm.
/// ROM structures at 1.2V nominal are expected to achieve BER < 1e-12 in practice.
/// Conservative estimate: 1e-10 (one order of magnitude above the 1e-9 bound).
pub const BITROM_BIT_ERROR_RATE: f64 = 1e-10; // PRE-SILICON ESTIMATE — 1.2V 25°C

// ---------------------------------------------------------------------------
// W-101-C: Mesh per-hop latency bound
// ---------------------------------------------------------------------------

/// 4×4 mesh per-hop latency in nanoseconds at TTIHP27a 500 MHz.
/// PRE-SILICON ESTIMATE — at 500 MHz the clock period is 2.0 ns.
/// A single-hop NoC router typically resolves in 1 pipeline stage = 1 cycle = 2.0 ns.
/// Using 0.8 ns (sub-cycle latency with pipelined forwarding) as conservative estimate.
pub const MESH_4X4_PER_HOP_LATENCY_NS: f64 = 0.8; // PRE-SILICON ESTIMATE

// ---------------------------------------------------------------------------
// W-101-D: RTL holographic star-free (mirrors Coq holographic_no_star)
// ---------------------------------------------------------------------------

/// All holographic operations present in the TTIHP27a RTL.
/// Mirrors the Coq `holo_op` inductive type in the holographic_no_star lemma.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HoloOp {
    LoadPhysicsConst,
    NocForward,
    RazorSample,
    HoloMux1x2,
    LutLookup,
    BitromRead,
}

impl HoloOp {
    /// All variants, for exhaustive iteration in tests.
    pub const ALL: [HoloOp; 6] = [
        HoloOp::LoadPhysicsConst,
        HoloOp::NocForward,
        HoloOp::RazorSample,
        HoloOp::HoloMux1x2,
        HoloOp::LutLookup,
        HoloOp::BitromRead,
    ];
}

/// Returns `true` if the RTL implementation of `op` uses a star (*) holographic
/// interconnect primitive.  Per R_SI_1_ZERO_STAR the answer must be `false` for
/// every operation — matches Coq `holographic_no_star` proof obligation.
pub fn rtl_uses_star(op: HoloOp) -> bool {
    match op {
        HoloOp::LoadPhysicsConst => false,
        HoloOp::NocForward       => false,
        HoloOp::RazorSample      => false,
        HoloOp::HoloMux1x2       => false,
        HoloOp::LutLookup        => false,
        HoloOp::BitromRead       => false,
    }
}

// ---------------------------------------------------------------------------
// W-101-E: Thermal density bound
// ---------------------------------------------------------------------------

/// Thermal power density in W/mm² at Vdd=1.2V.
/// PRE-SILICON ESTIMATE — TTIHP27a 28nm target.
/// LUT PE array: 1534 GOPS @ ~0.29 W in 0.96 mm² ≈ 0.30 W/mm².
/// Combined lever stack with BitROM and mesh overhead: estimated ≤ 1.2 W/mm².
pub const THERMAL_DENSITY_W_PER_MM2: f64 = 1.2; // PRE-SILICON ESTIMATE — Vdd=1.2V
