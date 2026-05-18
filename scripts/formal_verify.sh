#!/bin/bash
# formal_verify.sh — Formal verification with SBY (SymbiYosys)
# Usage: ./formal_verify.sh <module_name>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SRC_DIR="${PROJECT_DIR}/src"
FORMAL_DIR="${PROJECT_DIR}/formal"
mkdir -p "${FORMAL_DIR}"

MODULE="${1:-cortical_column}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Formal Verification: ${MODULE} ===${NC}"

# Check for SBY
if ! command -v sby &> /dev/null; then
    echo -e "${RED}Error: sby not found. Install with: pip install sby${NC}"
    exit 1
fi

# Check for Yosys
if ! command -v yosys &> /dev/null; then
    echo -e "${RED}Error: yosys not found. Install Yosys first${NC}"
    exit 1
fi

# Check module exists
if [[ ! -f "${SRC_DIR}/${MODULE}.v" ]]; then
    echo -e "${RED}Error: Module not found: ${SRC_DIR}/${MODULE}.v${NC}"
    exit 1
fi

# Generate SBY config if not exists
SBY_FILE="${FORMAL_DIR}/${MODULE}.sby"

if [[ ! -f "${SBY_FILE}" ]]; then
    cat > "${SBY_FILE}" <<EOF
[options]
mode bmc
depth 20
append 0

[engines]
smtbmc z3

[script]
read -formal ${SRC_DIR}/${MODULE}.v
prep -top ${MODULE}

[files]
${SRC_DIR}/${MODULE}.v
${SRC_DIR}/gf16_add.v
${SRC_DIR}/gf16_mul.v
${SRC_DIR}/k3_alu.v
EOF
    echo -e "${GREEN}Generated SBY config: ${SBY_FILE}${NC}"
fi

# Run formal verification
echo -e "${YELLOW}Running SBY formal verification...${NC}"
cd "${FORMAL_DIR}"
sby -f "${MODULE}.sby"

# Check result
if [[ -f "${MODULE}/PASS" ]]; then
    echo -e "${GREEN}=== FORMAL VERIFICATION PASSED ===${NC}"
    exit 0
elif [[ -f "${MODULE}/FAIL" ]]; then
    echo -e "${RED}=== FORMAL VERIFICATION FAILED ===${NC}"
    cat "${MODULE}/FAIL"
    exit 1
else
    echo -e "${YELLOW}=== FORMAL VERIFICATION INDETERMINATE ===${NC}"
    exit 2
fi