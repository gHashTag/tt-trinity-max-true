#!/bin/bash
# check_clara_traceability.sh — Verify CLARA gap modules have traceability
# Usage: ./check_clara_traceability.sh <module_file>

MODULE_FILE="$1"
MODULE_NAME=$(basename "$MODULE_FILE" .v)
TRACEABILITY_FILE="CLARA_TRACEABILITY.md"

if [ ! -f "$TRACEABILITY_FILE" ]; then
    echo "ERROR: CLARA_TRACEABILITY.md not found"
    exit 1
fi

# Extract gap number from module name
case "$MODULE_NAME" in
    redteam_filter)
        GAP="Gap-1"
        ;;
    k3_alu)
        GAP="Gap-2"
        ;;
    datalog_engine*)
        GAP="Gap-3"
        ;;
    constraint_ctrl|restraint_ctrl)
        GAP="Gap-4"
        ;;
    explainability_unit)
        GAP="Gap-5"
        ;;
    asp_solver*)
        GAP="Gap-6"
        ;;
    composition_kernel)
        GAP="Gap-7"
        ;;
    proof_trace_writer)
        GAP="Gap-8"
        ;;
    sat_solver*)
        GAP="Gap-9"
        ;;
    audit_log_ring_buffer)
        GAP="Gap-10"
        ;;
    *)
        echo "Not a CLARA gap module: $MODULE_NAME"
        exit 0
        ;;
esac

# Check if gap is documented
if grep -q "$GAP" "$TRACEABILITY_FILE"; then
    echo "OK: $MODULE_NAME ($GAP) has traceability in CLARA_TRACEABILITY.md"
    exit 0
else
    echo "ERROR: $MODULE_NAME ($GAP) missing from CLARA_TRACEABILITY.md"
    exit 1
fi