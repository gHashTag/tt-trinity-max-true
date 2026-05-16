//! Wave-47 Lane QQ'' — RBB witness tests
//! Mirrors Wave-46 adiab-rc-witness pattern; 13 tests covering R18 bank extension,
//! V_BS sign/band, γ⁴ identity, leakage band [35%,50%], active overhead ≤1.5%,
//! net idle save ≥30%, f_clk invariance, TOPS/W lift ≥1.5%, full distinctness.

use rbb_witness::*;

/// Test 1: OP_RBB encoded as 0xF1.
#[test]
fn test_op_rbb_is_0xf1() {
    assert_eq!(OP_RBB, 0xF1, "OP_RBB must be 0xF1");
    assert!(op_rbb_constant_f1());
}

/// Test 2: OP_RBB sits inside EXTENDED sacred bank [0xE0, 0xFF].
#[test]
fn test_rbb_in_extended_bank() {
    assert!(rbb_in_extended_bank(),
        "OP_RBB={:#x} must lie in [{:#x}, {:#x}]",
        OP_RBB, SACRED_BANK_LOW, SACRED_BANK_HIGH);
    // Boundaries
    assert!(OP_RBB >= 0xE0);
    assert!(OP_RBB <= 0xFF);
}

/// Test 3: R18 bank extension — 32 > 16 (strict).
#[test]
fn test_bank_extension_strict() {
    assert!(bank_extension_strict(),
        "Extended bank ({}) must be strictly larger than legacy ({})",
        SACRED_BANK_EXTENDED_SIZE, SACRED_BANK_LEGACY_SIZE);
    assert_eq!(SACRED_BANK_LEGACY_SIZE, 16);
    assert_eq!(SACRED_BANK_EXTENDED_SIZE, 32);
}

/// Test 4: V_BS is negative (reverse bias direction).
#[test]
fn test_v_bs_is_negative() {
    assert!(v_bs_is_negative(), "V_BS must be negative for REVERSE body bias");
    assert_eq!(V_BS_DECIMV, -25, "V_BS = -2.5 mV ⇒ -25 decimV");
}

/// Test 5: V_BS magnitude in safety band [2.2 mV, 2.8 mV].
#[test]
fn test_v_bs_magnitude_in_band() {
    assert!(v_bs_magnitude_in_band(),
        "|V_BS|={} decimV not in [{}, {}]",
        V_BS_MAG_DECIMV, V_BS_MAG_MIN_DECIMV, V_BS_MAG_MAX_DECIMV);
    assert_eq!(V_BS_MAG_DECIMV, 25);
}

/// Test 6: γ⁴ Q-encoding within ±2 bps of exact (~31).
#[test]
fn test_gamma4_encoding() {
    assert!(gamma4_within_2_bps(),
        "GAMMA4_BPS={} drifts >2 bps from exact 31", GAMMA4_BPS);
    assert_eq!(GAMMA4_BPS, 31);
}

/// Test 7: γ⁴ = (γ²)² — derived from B007 squared then squared again, no new ROM.
#[test]
fn test_gamma4_equals_gamma2_squared() {
    assert!(gamma4_equals_gamma2_squared(),
        "γ⁴ ({}) must equal γ² · γ² within 1 bps", GAMMA4_BPS);
}

/// Test 8: Leakage save lands in canonical [35%, 50%] band.
#[test]
fn test_leakage_save_band() {
    let mut c = RbbCtrl::new();
    c.step(OP_RBB);
    assert!(leakage_save_in_band(c.leak_save_bps),
        "leakage save {} bps outside [{}, {}]",
        c.leak_save_bps, LEAK_SAVE_LO_BPS, LEAK_SAVE_HI_BPS);
    // Boundaries
    assert!(leakage_save_in_band(3500));   // 35% — floor
    assert!(leakage_save_in_band(4000));   // 40% — center
    assert!(leakage_save_in_band(5000));   // 50% — ceiling
    assert!(!leakage_save_in_band(3499));  // 34.99% — falsified
    assert!(!leakage_save_in_band(5001));  // 50.01% — too good to be true
}

/// Test 9: Active path overhead never exceeds 1.5%.
#[test]
fn test_active_overhead_within_1_5pct() {
    let mut c = RbbCtrl::new();
    c.step(OP_RBB);
    assert!(active_overhead_within_1_5pct(c.active_overhead_bps),
        "active overhead {} bps exceeds {} bps",
        c.active_overhead_bps, ACTIVE_OVERHEAD_MAX_BPS);
    // 151 bps (1.51%) must fail
    assert!(!active_overhead_within_1_5pct(151));
    // 150 bps (1.50%) must pass
    assert!(active_overhead_within_1_5pct(150));
}

/// Test 10: Net idle save ≥ 30% — R7 falsification floor.
#[test]
fn test_net_idle_save_at_least_30pct() {
    let mut c = RbbCtrl::new();
    c.step(OP_RBB);
    let net = c.net_idle_save_bps();
    assert!(net_idle_save_at_least_30pct(net),
        "net idle save {} bps below {} bps floor",
        net, NET_IDLE_SAVE_MIN_BPS);
    // 2999 bps (29.99%) must fail
    assert!(!net_idle_save_at_least_30pct(2999));
    // 3000 bps (30.00%) must pass
    assert!(net_idle_save_at_least_30pct(3000));
}

/// Test 11: Frequency invariance — RBB does not move clock tree.
#[test]
fn test_freq_invariant() {
    let mut c = RbbCtrl::new();
    c.step(OP_RBB);
    assert!(freq_invariant(c.f_ratio_bps),
        "F_RATIO_BPS {} not within ±50 bps of 10000", c.f_ratio_bps);
    assert!(freq_invariant(9950));
    assert!(freq_invariant(10050));
    assert!(!freq_invariant(9949));
    assert!(!freq_invariant(10051));
}

/// Test 12: TOPS/W lift W46 → W47 ≥ 1.5%.
#[test]
fn test_tops_w_lift() {
    assert!(tops_w_lift_ok(15), "+1.5% (15 tenths) must pass the floor");
    assert!(tops_w_lift_ok(19), "+1.9% (W47 projection) must pass");
    assert!(!tops_w_lift_ok(14), "+1.4% must fail the floor");
    assert_eq!(TOPS_W_LIFT_MIN_TENTHS, 15);
    assert!(w46_to_w47_lift_at_least_1_5pct(),
        "W47 TOPS/W ({}) - W46 TOPS/W ({}) lift below 1.5%",
        TOPS_W_W47_POST, TOPS_W_W46_POST);
    assert_eq!(TOPS_W_W47_POST, 1063);
    assert_eq!(TOPS_W_W46_POST, 1043);
}

/// Test 13: Distinctness from all 16 prior sacred opcodes (0xE1..0xF0).
#[test]
fn test_distinctness() {
    let c = RbbCtrl::new();
    assert!(c.distinct_from_adiab_rc(),    "must differ from OP_ADIAB_RC    (0xF0)");
    assert!(c.distinct_from_wl_boost(),    "must differ from OP_WL_BOOST    (0xEF)");
    assert!(c.distinct_from_fbb(),         "must differ from OP_FBB         (0xEE)");
    assert!(c.distinct_from_sparse_mask(), "must differ from OP_SPARSE_MASK (0xED)");
    assert!(c.distinct_from_drowsy_ret(),  "must differ from OP_DROWSY_RET  (0xEC)");
    assert!(c.distinct_from_spec_exit(),   "must differ from OP_SPEC_EXIT   (0xEB)");
    assert!(c.distinct_from_null_pe(),     "must differ from OP_NULL_PE     (0xEA)");
    assert!(c.distinct_from_stoch(),       "must differ from OP_STOCH_ROUND (0xE9)");
    assert!(c.distinct_from_sparse(),      "must differ from OP_SPARSE_SKIP (0xE8)");
    assert!(c.distinct_from_dfs(),         "must differ from OP_DFS_GATE    (0xE7)");
    assert!(c.distinct_from_holo_mux(),    "must differ from OP_HOLO_MUX_X4 (0xE6)");
    assert!(c.distinct_from_subth(),       "must differ from OP_SUBTH_CLK   (0xE5)");
    assert!(c.distinct_from_avs(),         "must differ from OP_AVS_RECONF  (0xE4)");
    assert!(c.distinct_from_lut_npu(),     "must differ from OP_LUT_NPU     (0xE3)");
    assert!(c.distinct_from_tom(),         "must differ from OP_TOM         (0xE2)");
    assert!(c.distinct_from_tenet(),       "must differ from OP_TENET       (0xE1)");
}

/// Test 14: Wave-47 silicon truth — opcode + R18 extension + leak band together.
#[test]
fn test_wave47_silicon_truth() {
    // 1. Opcode is exactly 0xF1
    assert_eq!(OP_RBB, 0xF1);
    // 2. R18 bank extension active (16 → 32 slots)
    assert!(bank_extension_strict());
    // 3. V_BS negative ⇒ REVERSE bias
    assert!(v_bs_is_negative());
    // 4. V_BS magnitude in band
    assert!(v_bs_magnitude_in_band());
    // 5. γ⁴ = (γ²)² (no new ROM)
    assert!(gamma4_equals_gamma2_squared());
    // 6. TOPS/W lift ≥ 1.5%
    assert!(w46_to_w47_lift_at_least_1_5pct());
    // 7. TOPS/W constants
    assert!(TOPS_W_W47_POST > TOPS_W_W46_POST);
    assert_eq!(TOPS_W_W47_POST, 1063);
    assert_eq!(TOPS_W_W46_POST, 1043);
}
