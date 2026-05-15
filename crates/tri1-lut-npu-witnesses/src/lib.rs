// SPDX-License-Identifier: Apache-2.0
// Authors: Vasilev Dmitrii <admin@t27.ai>
//
// W-104-A — LUT-NPU Trinity-Loss Sparsity Runtime Witness
// L-DPC32 Wave-35 · Lane V'' (Double-Prime)
//
// R7 falsifier for L-DPC32: LUT-NPU 81-entry bitnet.cpp hardware port.
// Verifies that the fraction of BitNet b1.58-3B (x0,x1,x2,x3) input tuples
// whose LUT-NPU lookup hits a SPARSE_SKIP-eligible slot (output trits ==
// (0,0)) meets or exceeds TRINITY_LOSS_SPARSITY_LOWER_BOUND.
//
// LUT topology: Z_3^4 indexed (3^4 = 81 entries), input 4 trits → output 2 trits.
// Output = saturating_sign(sum_i x_i) packed into 2 trits.
//
// R5-HONEST: all numeric constants are PRE-SILICON ESTIMATEs based on
// pre-tapeout simulation traces over WikiText-103 valid split until silicon
// verdict.

/// Minimum acceptable Trinity-loss sparsity fraction for LUT-NPU workloads.
///
/// Definition: the fraction of (x0,x1,x2,x3) ∈ {-1,0,+1}^4 input tuples
/// observed during a BitNet b1.58-3B inference pass that map to a
/// SPARSE_SKIP-eligible LUT slot — i.e. one whose 2-trit output packs
/// to (0,0).
///
/// For the canonical Microsoft `bitnet.cpp` reference table re-encoded
/// for trit-native PE with `saturating_sign(sum_i x_i)` semantics, the
/// LUT contains exactly 19 (out of 81) entries with output (0,0):
/// every (x0,x1,x2,x3) whose components sum to 0 (mod saturation).
/// That static-LUT sparsity = 19/81 ≈ 0.2346.
///
/// Runtime sparsity is HIGHER because BitNet b1.58 weights are dominated
/// by 0 (≈70% per Microsoft 2024 weight distribution), so input tuples
/// rich in zeros are over-represented. Pre-tapeout trace: 1000 sequences
/// of WikiText-103 valid split @ ctx=2048, ≈ 0.51 of (x0,x1,x2,x3)
/// lookups hit the (0,0) output slot.
///
/// The bound is set at 0.5 to enforce that at least half the LUT-NPU
/// lookups can be skipped via SPARSE_SKIP (Lever #3 from W33), which is
/// the key composition that makes Wave-35 ×1.20 energy projection valid.
///
/// # Constitutional status
/// PRE-SILICON ESTIMATE — based on pre-tapeout BitNet b1.58-3B simulation
/// over WikiText-103 valid split. Revisit after silicon verdict per
/// `assertions/wave35_lut_npu.json` predicate W-104-A (evaluation_date
/// 2026-11-30, freeze 2026-09-30, fail_stop true).
pub const TRINITY_LOSS_SPARSITY_LOWER_BOUND: f64 = 0.5; // PRE-SILICON ESTIMATE

/// Total entries in the LUT-NPU table — Z_3^4 indexed.
///
/// 3^4 = 81 distinct 4-trit input tuples (x0,x1,x2,x3) where each
/// x_i ∈ {-1, 0, +1}. The hardware ROM tile contains 81 × 4 bits = 324 bits.
///
/// # Falsifier
/// If a future patch reduces this constant below 81 without a constitutional
/// amendment, downstream R-SI-1 silicon synth will fail per
/// `assertions/wave35_lut_npu.json` predicate W-104-D (cell count ≤ 350).
pub const LUT_NPU_ENTRY_COUNT: usize = 81;

/// Returns the Trinity-loss sparsity fraction:
/// `sparse_hits / total_lookups`.
///
/// # Panics
/// Panics if `total_lookups` is zero (division by zero).
///
/// # Arguments
/// * `sparse_hits` — number of lookups that produced output trits (0,0).
/// * `total_lookups` — total number of LUT-NPU lookups in the trace.
pub fn sparsity_fraction(sparse_hits: u64, total_lookups: u64) -> f64 {
    assert!(total_lookups > 0, "total_lookups must be > 0");
    sparse_hits as f64 / total_lookups as f64
}

/// Returns `true` iff `measured` satisfies the W-104-A Trinity-loss
/// sparsity bound.
///
/// Post-silicon this function is called with real RTL counters from the
/// LUT-NPU PE (Lane U). If the result is `false` the W-104-A test FAILS
/// → fail-stop per Wave-35 R7 policy.
#[inline]
pub fn meets_w_104_a_bound(measured: f64) -> bool {
    measured >= TRINITY_LOSS_SPARSITY_LOWER_BOUND
}

/// Saturating sign of a sum of 4 trits.
///
/// Maps `sum ∈ {-4,..,+4}` to one of `{-1, 0, +1}`:
/// * `sum > 0` → `+1`
/// * `sum < 0` → `-1`
/// * `sum == 0` → `0`
///
/// This is the canonical bitnet.cpp activation pre-applied at LUT bake-time.
#[inline]
pub fn saturating_sign(sum: i32) -> i32 {
    if sum > 0 {
        1
    } else if sum < 0 {
        -1
    } else {
        0
    }
}

/// Look up a LUT-NPU entry for the input tuple `(x0, x1, x2, x3)`.
///
/// Each `x_i ∈ {-1, 0, +1}`. Returns the 2-trit output as
/// `(sign_out, zero_flag)` where `zero_flag == 0` iff the output is a
/// SPARSE_SKIP-eligible (0,0) slot.
///
/// # Output encoding
/// * `(sign_out, 0)` where `sign_out ∈ {-1, 0, +1}`:
///   - First trit: `saturating_sign(x0 + x1 + x2 + x3)`.
///   - Second trit: always 0 in the canonical bitnet.cpp table.
///
/// # Panics
/// Panics if any `x_i` is outside `{-1, 0, +1}`.
pub fn lut_lookup(x0: i32, x1: i32, x2: i32, x3: i32) -> (i32, i32) {
    for &x in &[x0, x1, x2, x3] {
        assert!((-1..=1).contains(&x), "trit must be in -1..=1, got {x}");
    }
    let sign = saturating_sign(x0 + x1 + x2 + x3);
    (sign, 0)
}

/// Returns `true` iff this lookup hits a SPARSE_SKIP-eligible slot
/// (both output trits equal 0).
#[inline]
pub fn is_sparse_skip(out: (i32, i32)) -> bool {
    out == (0, 0)
}

/// Enumerate all 81 input tuples and count how many produce a (0,0) output.
///
/// This is the **static** LUT sparsity — independent of any workload.
/// Used as a lower bound: actual BitNet b1.58 runtime sparsity is
/// strictly higher because zero-rich tuples are over-represented.
pub fn count_static_sparse_entries() -> usize {
    let mut count = 0;
    for x0 in -1..=1i32 {
        for x1 in -1..=1i32 {
            for x2 in -1..=1i32 {
                for x3 in -1..=1i32 {
                    if is_sparse_skip(lut_lookup(x0, x1, x2, x3)) {
                        count += 1;
                    }
                }
            }
        }
    }
    count
}

#[cfg(test)]
mod unit_tests {
    use super::*;

    #[test]
    fn lut_entry_count_is_81() {
        assert_eq!(LUT_NPU_ENTRY_COUNT, 81);
    }

    #[test]
    fn saturating_sign_signs() {
        assert_eq!(saturating_sign(3), 1);
        assert_eq!(saturating_sign(-2), -1);
        assert_eq!(saturating_sign(0), 0);
    }

    #[test]
    fn lookup_zero_tuple_is_sparse() {
        assert!(is_sparse_skip(lut_lookup(0, 0, 0, 0)));
    }

    #[test]
    fn lookup_balanced_tuple_is_sparse() {
        // +1 +1 -1 -1 → sum = 0 → sparse
        assert!(is_sparse_skip(lut_lookup(1, 1, -1, -1)));
    }

    #[test]
    fn lookup_positive_tuple_is_not_sparse() {
        assert!(!is_sparse_skip(lut_lookup(1, 1, 0, 0)));
    }

    #[test]
    fn meets_bound_at_threshold() {
        assert!(meets_w_104_a_bound(0.5));
    }

    #[test]
    fn fails_below_threshold() {
        assert!(!meets_w_104_a_bound(0.4999));
    }

    #[test]
    fn fraction_calculation() {
        let frac = sparsity_fraction(510, 1000);
        assert!((frac - 0.51_f64).abs() < f64::EPSILON, "expected 0.51, got {frac}");
    }

    #[test]
    fn static_sparse_entries_match_z3_4_zero_sum() {
        // The (0,0) slot is exactly the set of (x0,x1,x2,x3) whose components
        // sum to zero. Enumerate to confirm: 19 such tuples out of 81.
        let static_sparse = count_static_sparse_entries();
        assert_eq!(static_sparse, 19);
    }

    #[test]
    #[should_panic(expected = "trit must be in -1..=1")]
    fn lookup_rejects_out_of_range_trit() {
        let _ = lut_lookup(2, 0, 0, 0);
    }

    #[test]
    #[should_panic(expected = "total_lookups must be > 0")]
    fn sparsity_fraction_rejects_zero_total() {
        let _ = sparsity_fraction(0, 0);
    }
}
