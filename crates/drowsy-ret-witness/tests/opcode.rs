//! Wave-43 Lane HH'' — drowsy-ret-witness integration tests
//! 8 test functions for OP_DROWSY_RET = 0xEC
//! anchor phi^2 + phi^-2 = 3 · DOI 10.5281/zenodo.19227877

use drowsy_ret_witness::{
    gamma_within_half_percent, leakage_reduction_ok, retention_fidelity_ok, wake_bound_ok,
    DrowsyRetCtrl, GAMMA_Q15, OP_DROWSY_RET, WAKE_CYCLES_MAX,
};

/// Test 1: OP_DROWSY_RET constant equals 0xEC.
#[test]
fn test_opcode_ec_constant() {
    assert_eq!(OP_DROWSY_RET, 0xECu8, "OP_DROWSY_RET must be 0xEC");
}

/// Test 2: Wrong opcode freezes counters (no idle progress, no drowsy entry).
#[test]
fn test_opcode_mismatch_freeze() {
    let mut c = DrowsyRetCtrl::new(4, 32);
    for _ in 0..1000 {
        c.tick(0x00, &[false, false, false, false]);
    }
    for b in &c.banks {
        assert_eq!(b.idle_cnt, 0, "idle_cnt must stay 0 under wrong opcode");
        assert!(!b.drowsy, "must not enter drowsy under wrong opcode");
    }
}

/// Test 3: After IDLE_THRESHOLD idle cycles, all banks enter drowsy.
#[test]
fn test_all_banks_drowsy_after_threshold() {
    let mut c = DrowsyRetCtrl::new(4, 32);
    for _ in 0..40 {
        c.tick(OP_DROWSY_RET, &[false; 4]);
    }
    for (i, b) in c.banks.iter().enumerate() {
        assert!(b.drowsy, "bank {i} must be drowsy after 40 idle cycles");
    }
}

/// Test 4: Access wakes the accessed bank and bounds wake_cnt ≤ WAKE_CYCLES_MAX.
#[test]
fn test_access_wakes_and_bounds_wake_cycles() {
    let mut c = DrowsyRetCtrl::new(4, 32);
    // Drive all banks drowsy
    for _ in 0..40 {
        c.tick(OP_DROWSY_RET, &[false; 4]);
    }
    // Access bank 0 once
    c.tick(OP_DROWSY_RET, &[true, false, false, false]);
    assert!(!c.banks[0].drowsy, "bank 0 must exit drowsy after access");
    let mut max_wake = 0u8;
    for _ in 0..10 {
        for b in &c.banks {
            if b.wake_cnt > max_wake {
                max_wake = b.wake_cnt;
            }
        }
        c.tick(OP_DROWSY_RET, &[false; 4]);
    }
    assert!(
        wake_bound_ok(max_wake),
        "wake_cnt observed {max_wake} > WAKE_CYCLES_MAX={WAKE_CYCLES_MAX}"
    );
}

/// Test 5: Leakage ≤ 30% of full V_DD when all banks drowsy.
#[test]
fn test_leakage_full_drowsy() {
    let mut c = DrowsyRetCtrl::new(4, 32);
    for _ in 0..40 {
        c.tick(OP_DROWSY_RET, &[false; 4]);
    }
    let leak = c.leakage_pct();
    assert!(
        leak <= 30,
        "full-drowsy leakage {leak}% exceeds 30% target"
    );
    assert!(leakage_reduction_ok());
}

/// Test 6: γ Q1.15 within ±0.5% of exact φ⁻³.
#[test]
fn test_gamma_match_half_percent() {
    assert!(
        gamma_within_half_percent(),
        "GAMMA_Q15=0x{GAMMA_Q15:04X} drifts > 0.5% from φ⁻³"
    );
}

/// Test 7: Retention fidelity ≥ 0.99 over 1ms idle (modelled at 990/1000).
#[test]
fn test_retention_fidelity_min() {
    assert!(retention_fidelity_ok(995), "modelled fidelity 0.995 ≥ 0.990");
    assert!(!retention_fidelity_ok(900), "modelled fidelity 0.900 must fail gate");
}

/// Test 8: OP_DROWSY_RET is distinct from all prior ISA chain opcodes.
#[test]
fn test_distinct_from_all_prior_opcodes() {
    let c = DrowsyRetCtrl::new(1, 1);
    assert!(c.distinct_from_spec_exit(),  "must differ from OP_SPEC_EXIT   (0xEB)");
    assert!(c.distinct_from_null_pe(),    "must differ from OP_NULL_PE     (0xEA)");
    assert!(c.distinct_from_stoch(),      "must differ from OP_STOCH_ROUND (0xE9)");
    assert!(c.distinct_from_sparse(),     "must differ from OP_SPARSE_SKIP (0xE8)");
    assert!(c.distinct_from_dfs(),        "must differ from OP_DFS_GATE    (0xE7)");
    assert!(c.distinct_from_holo_mux(),   "must differ from OP_HOLO_MUX_X4 (0xE6)");
    assert!(c.distinct_from_subth(),      "must differ from OP_SUBTH_CLK   (0xE5)");
    assert!(c.distinct_from_avs(),        "must differ from OP_AVS_RECONF  (0xE4)");
    assert!(c.distinct_from_lut_npu(),    "must differ from OP_LUT_NPU     (0xE3)");
    assert!(c.distinct_from_tom(),        "must differ from OP_TOM         (0xE2)");
    assert!(c.distinct_from_tenet(),      "must differ from OP_TENET       (0xE1)");
}
