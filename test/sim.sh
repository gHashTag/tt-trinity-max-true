#!/bin/bash
# sim.sh - Unified simulation script for tt-trinity-gamma
# Usage: ./sim.sh [testbench_name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SIM_DIR="${SCRIPT_DIR}/sim"
mkdir -p "${SIM_DIR}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default testbench
TB="${1:-tb}"

echo -e "${YELLOW}=== TRI-1 Gamma Simulation ===${NC}"
echo "Project: ${PROJECT_DIR}"
echo "Testbench: ${TB}"
echo ""

# Check tools
if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}Error: iverilog not found. Please install iverilog.${NC}"
    exit 1
fi

if ! command -v vvp &> /dev/null; then
    echo -e "${RED}Error: vvp not found. Please install iverilog.${NC}"
    exit 1
fi

# List available testbenches
echo "Available testbenches:"
for f in "${SCRIPT_DIR}"/*.v; do
    if [[ $(basename "$f") =~ ^tb_ ]]; then
        basename "$f" .v
    fi
done
echo ""

# Build testbench
TB_FILE="${SCRIPT_DIR}/${TB}.v"
if [[ ! -f "${TB_FILE}" ]]; then
    echo -e "${RED}Error: Testbench not found: ${TB_FILE}${NC}"
    exit 1
fi

echo -e "${YELLOW}Building ${TB}...${NC}"
iverilog -o "${SIM_DIR}/${TB}.vvp" \
    -g2012 \
    -I"${PROJECT_DIR}/src" \
    "${PROJECT_DIR}/src"/*.v \
    "${TB_FILE}"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Build successful${NC}"
else
    echo -e "${RED}Build failed${NC}"
    exit 1
fi
echo ""

# Run simulation
echo -e "${YELLOW}Running simulation...${NC}"
vvp "${SIM_DIR}/${TB}.vvp"

# Open waveform if GTKWave is available
if command -v gtkwave &> /dev/null && [[ -f "${SIM_DIR}/${TB}.vcd" ]]; then
    echo ""
    echo -e "${YELLOW}Opening waveform in GTKWave...${NC}"
    gtkwave "${SIM_DIR}/${TB}.vcd" &
fi

echo ""
echo -e "${GREEN}Simulation complete${NC}"
echo "VCD file: ${SIM_DIR}/${TB}.vcd"