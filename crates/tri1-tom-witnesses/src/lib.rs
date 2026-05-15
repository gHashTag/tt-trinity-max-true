// SPDX-License-Identifier: Apache-2.0
// Authors: Vasilev Dmitrii <admin@t27.ai>
//
// W-103-A — TOM Layer Idle Fraction Runtime Witness
// L-DPC31 Wave-34 · Lane Y'' (Double-Prime)
//
// R7 falsifier for L-DPC31: TOM Ternary ROM Accelerator layer idle bound.
// Verifies that the fraction of idle (non-active) layers during a TOM
// inference pass meets or exceeds LAYER_IDLE_LOWER_BOUND.
//
// R5-HONEST: all numeric constants are PRE-SILICON ESTIMATEs based on
// pre-tapeout simulation traces until silicon verdict.

/// Minimum acceptable idle-layer fraction for TOM Ternary ROM workloads.
///
/// Based on pre-tapeout simulation of a 28-layer TOM ROM accelerator:
/// 14 of 28 layers are idle (not active) during a ternary inference pass,
/// giving an idle fraction of 0.5.
///
/// The bound is set at 0.5 to enforce that at least half the layers are
/// quiescent at any given cycle — a key power-saving property of TOM.
///
/// # Constitutional status
/// PRE-SILICON ESTIMATE — based on pre-tapeout simulation. Revisit after
/// silicon verdict.
pub const LAYER_IDLE_LOWER_BOUND: f64 = 0.5; // PRE-SILICON ESTIMATE

/// Returns the idle fraction: `(total_layers - active_layers) / total_layers`.
///
/// # Panics
/// Panics if `total_layers` is zero (division by zero).
///
/// # Arguments
/// * `active_layers` — number of layers active during the measurement window.
/// * `total_layers` — total number of layers in the TOM ROM accelerator.
pub fn idle_fraction(active_layers: usize, total_layers: usize) -> f64 {
    assert!(total_layers > 0, "total_layers must be > 0");
    let idle = total_layers - active_layers;
    idle as f64 / total_layers as f64
}

/// Returns `true` iff `measured` satisfies the W-103-A layer idle bound.
///
/// Post-silicon this function is called with real RTL counters from the
/// TOM layer-idle controller (Lane Y''). If the result is `false` the
/// W-103-A test FAILS → fail-stop per Wave-34 R7 policy.
#[inline]
pub fn meets_w_103_a_bound(measured: f64) -> bool {
    measured >= LAYER_IDLE_LOWER_BOUND
}

#[cfg(test)]
mod unit_tests {
    use super::*;

    #[test]
    fn meets_bound_at_threshold() {
        assert!(meets_w_103_a_bound(0.5));
    }

    #[test]
    fn fails_below_threshold() {
        assert!(!meets_w_103_a_bound(0.4));
    }

    #[test]
    fn fraction_calculation() {
        // 14 idle out of 28 total → 0.5
        let active = 14_usize; // PRE-SILICON ESTIMATE
        let total = 28_usize;  // PRE-SILICON ESTIMATE
        let frac = idle_fraction(active, total);
        assert!(
            (frac - 0.5_f64).abs() < f64::EPSILON,
            "expected 0.5, got {frac}"
        );
    }
}
