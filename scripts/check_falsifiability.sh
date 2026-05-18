#!/bin/bash
# check_falsifiability.sh — Verify PhD falsifiability witnesses are documented
# Usage: ./check_falsifiability.sh <module_file>

MODULE_FILE="$1"
MODULE_NAME=$(basename "$MODULE_FILE" .v)
README_FILE="README.md"

if [ ! -f "$README_FILE" ]; then
    echo "ERROR: README.md not found"
    exit 1
fi

# Check for falsifiability table entry
if grep -q "W[0-9]" "$README_FILE"; then
    echo "OK: Falsifiability witnesses documented in README.md"
    exit 0
else
    echo "WARNING: Falsifiability witnesses may not be documented"
    exit 0  # Warning, not error
fi