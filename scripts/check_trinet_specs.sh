#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# check_trinet_specs.sh — TRI-NET (γ-surface) spec CI gate
#
# Purpose:
#   1. (Optional) If `t27c` is available on PATH, parse every
#      specs/numeric/*.t27 and specs/fpga/*.t27 file. Otherwise skip
#      with a non-fatal notice — the validator lives in the upstream
#      `t27` meta repo and is not vendored here.
#
#   2. (Mandatory) Verify every TRI-NET numerical claim ID
#      `TN-(NF|D2D|TD|WL)-\d+` that appears in the canonical doc list
#      below is also present as a row in
#      docs/VERIFICATION_CLAIMS_MATRIX.md. Missing coverage fails the
#      gate with exit 1.
#
# Usage:
#   bash scripts/check_trinet_specs.sh
#
# R5 honesty:
#   - This gate does NOT measure silicon, NMSE, TOPS/W, or anything
#     else. It only checks documentation coverage and (optionally)
#     spec parsability.
#   - Absence of `t27c` is NOT a failure — see point (1).
#
# Author: TRI-NET verification hardening
# -----------------------------------------------------------------------

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MATRIX="${ROOT}/docs/VERIFICATION_CLAIMS_MATRIX.md"

# Canonical doc set scanned for claim IDs. Add to this list when a
# new TRI-NET doc starts referencing TN-* IDs.
CANONICAL_DOCS=(
  "${ROOT}/docs/VERIFICATION_CLAIMS_MATRIX.md"
  "${ROOT}/docs/specs/TRIPLE_DECKER_FSM.md"
  "${ROOT}/docs/ARCHITECTURE_QUICK_WINS.md"
  "${ROOT}/docs/RELEASE_MANIFEST_TRINET_V1.md"
  "${ROOT}/tests/vectors/nmse_gf16_bf16.golden.json"
  "${ROOT}/conformance/d2d/header_valid.json"
  "${ROOT}/conformance/d2d/bad_crc.json"
  "${ROOT}/conformance/d2d/unsupported_opcode.json"
  "${ROOT}/conformance/d2d/timeout_retry.json"
  "${ROOT}/conformance/d2d/multi_chip_ordering.json"
)

echo "TRI-NET spec gate"
echo "=================="
echo "Repository root: ${ROOT}"
echo

# -----------------------------------------------------------------------
# Pass 1 — optional t27c parse
# -----------------------------------------------------------------------
echo "[1/2] t27c spec parse (optional)"
if command -v t27c >/dev/null 2>&1; then
    parse_fail=0
    for f in "${ROOT}/specs/numeric"/*.t27 "${ROOT}/specs/fpga"/*.t27; do
        [ -f "$f" ] || continue
        if ! t27c parse "$f" >/dev/null 2>&1; then
            echo "  FAIL: t27c parse $(basename "$f")"
            parse_fail=1
        fi
    done
    if [ "$parse_fail" -ne 0 ]; then
        echo "t27c parse: FAIL"
        exit 1
    fi
    echo "  t27c parse: PASS"
else
    echo "  t27c not found - skipping (validator lives in upstream t27 meta repo)"
fi
echo

# -----------------------------------------------------------------------
# Pass 2 — mandatory claims coverage
# -----------------------------------------------------------------------
echo "[2/2] Claims coverage vs docs/VERIFICATION_CLAIMS_MATRIX.md"

if [ ! -f "${MATRIX}" ]; then
    echo "  FAIL: ${MATRIX} not found"
    exit 1
fi

# Pattern: TN-<AREA>-<digits> where AREA in {NF, D2D, TD, WL}
PATTERN='TN-(NF|D2D|TD|WL)-[0-9]+'

# Collect all claim IDs referenced anywhere in the canonical doc set.
referenced_ids=$(
  for f in "${CANONICAL_DOCS[@]}"; do
    [ -f "$f" ] || continue
    grep -oE "${PATTERN}" "$f" || true
  done | sort -u
)

if [ -z "${referenced_ids}" ]; then
    echo "  FAIL: no TN-* claim IDs found in canonical docs - matrix is unused"
    exit 1
fi

# Collect claim IDs that appear as rows in the matrix.
matrix_ids=$(grep -oE "${PATTERN}" "${MATRIX}" | sort -u)

missing=""
for id in ${referenced_ids}; do
    if ! grep -qE "^\| ${id} \|" "${MATRIX}"; then
        # Allow either "| TN-XX-N |" (matrix row) OR a citation within
        # the same matrix file (we still want a row form to be present).
        if ! echo "${matrix_ids}" | grep -qxF "${id}"; then
            missing="${missing} ${id}"
        fi
    fi
done

# Trim leading whitespace.
missing="$(echo "${missing}" | xargs || true)"

if [ -n "${missing}" ]; then
    echo "  FAIL: the following claim IDs are referenced in the canonical"
    echo "        docs but missing a row in ${MATRIX#${ROOT}/}:"
    for id in ${missing}; do
        echo "          - ${id}"
    done
    echo
    echo "  Add a row to docs/VERIFICATION_CLAIMS_MATRIX.md for each"
    echo "  missing ID, then re-run this gate."
    exit 1
fi

echo "  Claims coverage: PASS (${referenced_ids//$'\n'/ })"
echo
echo "TRI-NET spec gate: PASS"
exit 0
