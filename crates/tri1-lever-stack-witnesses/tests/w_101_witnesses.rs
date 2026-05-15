//! R7 Falsification Witnesses W-101-A..E
//!
//! Lane N · L-DPC25 Wave-28 · LEVER STACK
//! Tracking issue: <https://github.com/gHashTag/tt-trinity-max-true/issues/TBD>
//! Cross-ref: trios#834 <https://github.com/gHashTag/trios/issues/834>
//!
//! Each test PASSES with pre-silicon conservative estimates and will FAIL
//! post-silicon if the physical implementation violates the predicate.

use tri1_lever_stack_witnesses::{
    BITROM_BIT_ERROR_RATE,
    LUT_PE_ENERGY_PER_OP_FJ,
    MESH_4X4_PER_HOP_LATENCY_NS,
    SHIFT_ADD_BASELINE_ENERGY_PER_OP_FJ,
    THERMAL_DENSITY_W_PER_MM2,
    HoloOp,
    rtl_uses_star,
};

/// W-101-A: LUT PE energy per operation must be ≤ 2× shift-add baseline.
///
/// Predicate: `lut_pe_energy_per_op <= 2 * shift_add_baseline_energy_per_op`
/// Lever: #1 Platinum LUT PE (arXiv 2511.21910)
/// Gate: R7 — falsifiable witness; fails if silicon shows super-linear energy overhead.
#[test]
fn w_101_a_lut_pe_energy_bound() {
    let bound = 2.0 * SHIFT_ADD_BASELINE_ENERGY_PER_OP_FJ;
    assert!(
        LUT_PE_ENERGY_PER_OP_FJ <= bound,
        "W-101-A BREACHED: lut_pe_energy_per_op={:.1} fJ/op > 2×shift_add_baseline={:.1} fJ/op. \
         Lever #1 Platinum LUT PE energy efficiency violated. \
         Ref: arXiv 2511.21910 (ASP-DAC 2026). \
         trios#834 Lane N L-DPC25 Wave-28.",
        LUT_PE_ENERGY_PER_OP_FJ,
        bound,
    );
}

/// W-101-B: BitROM bit error rate must be ≤ 1e-9 at 1.2V, 25°C.
///
/// Predicate: `bitrom_bit_error_rate <= 1e-9 @ 1.2V, 25C`
/// Lever: #2 BitROM bidirectional ROM (arXiv 2509.08542)
/// Gate: R7 — falsifiable witness; fails if silicon shows unacceptable read errors.
#[test]
fn w_101_b_bitrom_ber_bound() {
    let ber_limit: f64 = 1e-9;
    assert!(
        BITROM_BIT_ERROR_RATE <= ber_limit,
        "W-101-B BREACHED: bitrom_ber={:.2e} > limit={:.2e} @ 1.2V 25°C. \
         Lever #2 BitROM reliability violated. \
         Ref: arXiv 2509.08542 (20.8 TOPS/W @ 65nm). \
         trios#834 Lane N L-DPC25 Wave-28.",
        BITROM_BIT_ERROR_RATE,
        ber_limit,
    );
}

/// W-101-C: 4×4 mesh per-hop latency must be ≤ 1.0 ns at TTIHP27a 500 MHz.
///
/// Predicate: `mesh_4x4_per_hop_latency_ns <= 1.0 @ TTIHP27a 500MHz`
/// Lever: #3 4×4 mesh linear scale-out
/// Gate: R7 — falsifiable witness; fails if NoC routing cannot meet timing.
#[test]
fn w_101_c_mesh_latency_bound() {
    let latency_limit_ns: f64 = 1.0;
    assert!(
        MESH_4X4_PER_HOP_LATENCY_NS <= latency_limit_ns,
        "W-101-C BREACHED: mesh_per_hop_latency={:.2} ns > limit={:.2} ns @ 500 MHz. \
         Lever #3 4×4 mesh timing violated. \
         Clock period at 500 MHz = 2.0 ns; single-hop must resolve sub-cycle. \
         trios#834 Lane N L-DPC25 Wave-28.",
        MESH_4X4_PER_HOP_LATENCY_NS,
        latency_limit_ns,
    );
}

/// W-101-D: R_SI_1_ZERO_STAR — no holographic operation uses a star (*) primitive.
///
/// Predicate: `rtl_uses_star(op) == false for all op`
/// Mirrors Coq `holographic_no_star` proof obligation.
/// Gate: R7 — falsifiable witness; fails if any op introduces a star interconnect.
#[test]
fn w_101_d_r_si_1_breach() {
    for op in HoloOp::ALL {
        assert!(
            !rtl_uses_star(op),
            "W-101-D BREACHED: R_SI_1_ZERO_STAR violated for op={:?}. \
             rtl_uses_star returned true — holographic star (*) primitive detected in RTL. \
             Mirrors Coq holographic_no_star lemma. \
             trios#834 Lane N L-DPC25 Wave-28.",
            op,
        );
    }
}

/// W-101-E: Thermal power density must be ≤ 1.5 W/mm² at Vdd=1.2V.
///
/// Predicate: `thermal_density_w_per_mm2 <= 1.5 @ Vdd=1.2V`
/// Combined lever stack (LUT PE + BitROM + 4×4 mesh).
/// Gate: R7 — falsifiable witness; fails if stacked levers exceed thermal budget.
#[test]
fn w_101_e_thermal_density_bound() {
    let thermal_limit: f64 = 1.5;
    assert!(
        THERMAL_DENSITY_W_PER_MM2 <= thermal_limit,
        "W-101-E BREACHED: thermal_density={:.3} W/mm² > limit={:.3} W/mm² @ Vdd=1.2V. \
         Lever stack combined thermal budget violated. \
         Ref: LUT PE arXiv 2511.21910 + BitROM arXiv 2509.08542 + 4×4 mesh. \
         trios#834 Lane N L-DPC25 Wave-28.",
        THERMAL_DENSITY_W_PER_MM2,
        thermal_limit,
    );
}
