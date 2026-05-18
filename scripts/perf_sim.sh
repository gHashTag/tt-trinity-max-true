#!/bin/bash
# perf_sim.sh — Performance simulation with cycle counting
# Usage: ./perf_sim.sh <testbench_name>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SIM_DIR="${PROJECT_DIR}/test/sim"
mkdir -p "${SIM_DIR}"

TB="${1:-tb_canonical_anchor}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Performance Simulation: ${TB} ===${NC}"

# Check for iverilog
if ! command -v iverilog &> /dev/null; then
    echo -e "${RED}Error: iverilog not found. Install with: brew install iverilog${NC}"
    exit 1
fi

# Check testbench exists
TB_FILE="${PROJECT_DIR}/test/${TB}.v"
if [[ ! -f "${TB_FILE}" ]]; then
    echo -e "${RED}Error: Testbench not found: ${TB_FILE}${NC}"
    exit 1
fi

# Build with cycle counting
echo -e "${YELLOW}Building simulation...${NC}"
iverilog -o "${SIM_DIR}/${TB}.vvp" \
    -g2012 \
    -I"${PROJECT_DIR}/src" \
    "${PROJECT_DIR}/src"/*.v \
    "${TB_FILE}" \
    -DENABLE_CYCLE_COUNT

# Run simulation
echo -e "${YELLOW}Running simulation...${NC}"
vvp "${SIM_DIR}/${TB}.vvp" | tee "${SIM_DIR}/${TB}.log"

# Extract cycle count from log
CYCLE_COUNT=$(grep -o "Cycle count: [0-9]*" "${SIM_DIR}/${TB}.log" | grep -o "[0-9]*" || echo "N/A")

if [[ "$CYCLE_COUNT" != "N/A" ]]; then
    echo -e "${GREEN}=== Performance Summary ===${NC}"
    echo "Clock frequency: 50 MHz"
    echo "Cycle count: $CYCLE_COUNT"
    echo "Latency: $(echo "scale=2; $CYCLE_COUNT / 50" | bc) µs"
    echo "Throughput: $(echo "scale=2; 50 / $CYCLE_COUNT" | bc) MHz"
else
    echo -e "${YELLOW}Cycle count not available in output${NC}"
fi

echo -e "${GREEN}=== Simulation complete ===${NC}"
echo "Log: ${SIM_DIR}/${TB}.log"
echo "VCD: ${SIM_DIR}/${TB}.vcd"