//! AVS-96 Dopamine witness for Wave 45 (S-199).
//!
//! Anchor: phi^2 + phi^-2 = 3
//! DOI: 10.5281/zenodo.19227877

/// Number of AVS-96 steps.
pub const AVS96_STEPS: u32 = 96;

/// AVS-96 bin width in microvolts.
pub const AVS96_BIN_WIDTH_UV: u32 = 6250;

/// AVS-48 bin width in microvolts (W36 reference).
pub const AVS48_BIN_WIDTH_UV: u32 = 12500;

/// Maximum allowed accuracy drop in PP'' lane (percent-points).
pub const ACCURACY_DROP_MAX_PP: f64 = 1.5;

/// Reused opcodes for AVS-96 reconfiguration.
pub const REUSES_OPCODES: [&str; 3] = ["0xE4 AVS_RECONF", "0xE5 SUBTH_CLK", "0xEE FBB"];

/// Returns true if `step` is within the valid AVS-96 range [0, 95].
pub fn step_in_range(step: u32) -> bool {
    step < AVS96_STEPS
}

/// Returns true if two AVS-96 bins equal one AVS-48 bin.
pub fn half_of_avs48() -> bool {
    2 * AVS96_BIN_WIDTH_UV == AVS48_BIN_WIDTH_UV
}

/// Returns the analytic Pareto energy-gain ratio for W-108-G.
pub fn energy_gain_ratio() -> f64 {
    1.30
}

/// Returns true if the measured accuracy drop satisfies the W-108-G constraint.
pub fn is_w108g_satisfied(drop_pp: f64) -> bool {
    drop_pp <= ACCURACY_DROP_MAX_PP
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_steps_count_96() {
        assert_eq!(AVS96_STEPS, 96);
    }

    #[test]
    fn test_bin_width_6250() {
        assert_eq!(AVS96_BIN_WIDTH_UV, 6250);
    }

    #[test]
    fn test_half_of_avs48() {
        assert!(half_of_avs48());
    }

    #[test]
    fn test_step_in_range_zero() {
        assert!(step_in_range(0));
    }

    #[test]
    fn test_step_in_range_95() {
        assert!(step_in_range(95));
    }

    #[test]
    fn test_step_out_of_range_96() {
        assert!(!step_in_range(96));
    }

    #[test]
    fn test_step_out_of_range_high() {
        assert!(!step_in_range(1000));
    }

    #[test]
    fn test_energy_gain_130() {
        let ratio = energy_gain_ratio();
        assert!((ratio - 1.30_f64).abs() < 1e-9);
    }

    #[test]
    fn test_w108g_satisfied_at_15pp() {
        assert!(is_w108g_satisfied(1.5));
    }

    #[test]
    fn test_w108g_violated_above_15pp() {
        assert!(!is_w108g_satisfied(1.6));
    }

    #[test]
    fn test_reuses_three_opcodes() {
        assert_eq!(REUSES_OPCODES.len(), 3);
        assert_eq!(REUSES_OPCODES[0], "0xE4 AVS_RECONF");
        assert_eq!(REUSES_OPCODES[1], "0xE5 SUBTH_CLK");
        assert_eq!(REUSES_OPCODES[2], "0xEE FBB");
    }

    #[test]
    fn test_avs48_bin_width_12500() {
        assert_eq!(AVS48_BIN_WIDTH_UV, 12500);
    }
}
