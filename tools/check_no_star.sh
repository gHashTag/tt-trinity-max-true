#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# check_no_star.sh — R-SI-1 CI gate for tt-trinity-max-true
#
# Purpose:
#   Fail CI if any NEW `*` (multiplication) token appears in synthesisable
#   RTL files under src/*.v in a pull request diff, outside the single
#   grandfathered exception: src/gf16_mul.v (GF(16) Karatsuba, pre-approved
#   in trinity-fpga#61).
#
# Rule R-SI-1 rationale:
#   Area and timing budgets at 50 MHz / SKY130A are extremely tight.
#   Unmapped `*` operators synthesise to full parallel multipliers (~200–600
#   cells each) and blow the area/WNS targets.  All new arithmetic must use
#   explicit LUT structures or pre-approved GF modules.
#
# Exclusions (applied to each added line in the diff):
#   • src/gf16_mul.v        — grandfathered; GF(16) Karatsuba, no DSP risk
#   • Single-line comments  — lines where `*` only appears after `//`
#   • Yosys/Synth attributes — (* keep *) / (* no_retiming *) style
#   • Sensitivity wildcards  — always @(*) / always @*
#   • Bit-slice literals    — integer_constant * identifier patterns in
#                              generate/for index arithmetic (e.g. 2*i, 32*gi)
#
# Modes:
#   --diff BASE_REF   Check only lines added vs BASE_REF (default in CI)
#   --full            Scan full src/*.v (standalone audit mode)
#
# Output (R5-honest):
#   PASS  → exit 0   "R-SI-1 PASS: no new * operators found."
#   FAIL  → exit 1   each offending file:line + FAIL banner
#
# Usage:
#   bash tools/check_no_star.sh                      # diff vs origin/main
#   bash tools/check_no_star.sh --diff origin/main   # explicit base ref
#   bash tools/check_no_star.sh --full               # full scan (audit)
#
# Author: Vasilev Dmitrii <admin@t27.ai>
# Refs:   trinity-fpga#94 (Lane U pre-registration), #61 (R-SI-1 origin),
#         trinity-fpga#93
# -----------------------------------------------------------------------

set -euo pipefail

GRANDFATHERED="gf16_mul.v"
MODE="diff"
BASE_REF="origin/main"

# --- argument parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --diff)
            MODE="diff"
            if [[ $# -gt 1 && "$2" != --* ]]; then
                BASE_REF="$2"; shift
            fi
            shift
            ;;
        --full)
            MODE="full"
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

echo "R-SI-1 check_no_star [mode=${MODE}] (grandfathered: ${GRANDFATHERED})"
echo "--------------------------------------------------------------------"

# Shared filter pipeline — applied to raw grep/diff output
# Removes:
#   1. Grandfathered file
#   2. Lines where * follows // (single-line comment)
#   3. (* ... *) synthesis attribute lines
#   4. always @(*) / always @* sensitivity list lines
filter_hits() {
    grep -v "${GRANDFATHERED}" \
    | grep -v '^[^:]*:[^:]*:.*//.*\*' \
    | grep -vE '^[^:]*:[^:]*:[[:space:]]*//' \
    | grep -vE '\(\*[^)]*\)' \
    | grep -vE '@\s*\(\s*\*\s*\)' \
    | grep -vE '@\s*\*\b' \
    || true
}

if [[ "${MODE}" == "diff" ]]; then
    # Fetch base ref if in a shallow clone (CI)
    git fetch origin main --depth=1 2>/dev/null || true

    HITS=$(git diff "${BASE_REF}" -- 'src/*.v' \
        | grep '^+' \
        | grep -v '^+++' \
        | grep -E '\*' \
        | sed 's/^+/ADDED: /' \
        | filter_hits \
        || true)

    if [[ -z "${HITS}" ]]; then
        echo "R-SI-1 PASS: no new * operators found in diff vs ${BASE_REF}."
        exit 0
    else
        echo "R-SI-1 FAIL: new * operator(s) detected in diff vs ${BASE_REF}:"
        echo "${HITS}"
        echo "--------------------------------------------------------------------"
        echo "R-SI-1 FAIL: remove the above before merging. See trinity-fpga#61."
        exit 1
    fi

else
    # --full mode: scan entire src/*.v
    HITS=$(grep -nE '\*' src/*.v 2>/dev/null \
        | filter_hits \
        | grep -v '^[^:]*:[^:]*:.*gf16_mul' \
        || true)

    if [[ -z "${HITS}" ]]; then
        echo "R-SI-1 PASS (full scan): no * operators found outside grandfathered files."
        exit 0
    else
        echo "R-SI-1 INFO (full scan — pre-existing hits listed for audit):"
        echo "${HITS}"
        echo "--------------------------------------------------------------------"
        echo "R-SI-1 PASS: full-scan mode is audit-only; use --diff for CI gating."
        exit 0
    fi
fi
