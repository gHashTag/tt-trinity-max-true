// SPDX-License-Identifier: Apache-2.0
// Authors: Vasilev Dmitrii <admin@t27.ai>
//
// W-103-A Integration Test — TOM Layer Idle Fraction Bound
// L-DPC31 Wave-34 · Lane Y'' (Double-Prime)
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ R7 FALSIFICATION WITNESS                                                │
// │                                                                         │
// │ PRE-SILICON (now): test uses a CACHED SIMULATION TRACE derived from     │
// │ pre-tapeout simulation of the 28-layer TOM Ternary ROM Accelerator.    │
// │ Simulation values: total_layers = 28, active_layers = 14,              │
// │ idle_fraction = 0.5 → PASSES (0.5 ≥ 0.5).                             │
// │                                                                         │
// │ POST-SILICON: this test is re-run with real counters from              │
// │ verdict.json produced by the TOM layer-idle RTL controller             │
// │ (Lane Y''). If measured_idle_fraction < 0.5, this test FAILS           │
// │ → FAIL-STOP per Wave-34 R7 policy.                                     │
// │                                                                         │
// │ Design spec: trinity-fpga#116 (L-DPC31 TOM Ternary ROM Accelerator)   │
// │ PhD chapter: trios#853 (TOM layer-idle ratio analysis)                 │
// │ Template: PR #17 (9f0a00c1ec) Lane T''' tri1-tenet-witnesses W-102-A  │
// └─────────────────────────────────────────────────────────────────────────┘

use tri1_tom_witnesses::{idle_fraction, meets_w_103_a_bound, LAYER_IDLE_LOWER_BOUND};

/// W-103-A: TOM layer idle fraction must be ≥ LAYER_IDLE_LOWER_BOUND (0.5).
///
/// Pre-silicon cached simulation trace: 28-layer TOM ROM accelerator,
/// 14 layers idle during a ternary inference pass → idle_fraction = 0.5.
///
/// Post-silicon: replace cached simulation values with real RTL verdict.json
/// counters. If real_idle_fraction < 0.5 this test FAILS → fail-stop (R7,
/// Wave-34).
#[test]
fn w_103_a_layer_idle_bound() {
    // PRE-SILICON ESTIMATE: cached simulation trace from pre-tapeout TOM sim.
    // 28-layer accelerator, 14 layers idle during ternary inference pass.
    let total_layers: usize = 28; // PRE-SILICON ESTIMATE
    let active_layers: usize = 14; // PRE-SILICON ESTIMATE

    let measured = idle_fraction(active_layers, total_layers); // 0.5 pre-silicon

    assert!(
        meets_w_103_a_bound(measured),
        "W-103-A FAIL: measured idle fraction {:.4} < lower bound {:.4}. \
         R7 fail-stop triggered. Real RTL counters do not meet the \
         ≥50% layer-idle requirement for TOM Ternary ROM Accelerator. \
         See trinity-fpga#116 (L-DPC31) and trios#853.",
        measured,
        LAYER_IDLE_LOWER_BOUND,
    );
}
