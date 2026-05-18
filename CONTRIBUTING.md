# Contributing to TRI-NET γ-surface

Thank you for your interest in contributing to the Trinity TRI-NET project!

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [R-SI Compliance](#r-si-compliance)
- [Neuromorphic Guidelines](#neuromorphic-guidelines)
- [Number Format Guidelines](#number-format-guidelines)

---

## Code of Conduct

- Be respectful and inclusive
- Focus on technical discussions
- Assume good intent
- Credit others appropriately

---

## Getting Started

### Prerequisites

```bash
# Install Verilog tools
brew install iverilog cocotb  # macOS
sudo apt-get install iverilog cocotb  # Ubuntu

# Install pre-commit hooks
pip install pre-commit

# Install Verible linter (optional)
brew install verible  # macOS

# Install Rust (for witness crates)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### Setup

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/tt-trinity-gamma
cd tt-trinity-gamma
git remote add upstream https://github.com/gHashTag/tt-trinity-gamma

# Install pre-commit hooks
pre-commit install

# Build witness crates (if working on Rust side)
cargo build --release
```

---

## Development Workflow

```bash
# 1. Create a feature branch
git checkout -b feature/amazing-feature

# 2. Make your changes
# ... edit RTL files in src/ ...

# 3. Run tests
cd test
./sim.sh tb_gf16_dot8
./sim.sh tb_k3_alu
./sim.sh tb_cortical_column

# 4. Run Rust witness tests (if applicable)
cargo test

# 5. Run pre-commit hooks
pre-commit run --all-files

# 6. Commit
git add .
git commit -m 'feat(cortex): implement cortical_column with LIF dynamics'

# 7. Push and create PR
git push origin feature/amazing-feature
```

---

## Commit Message Format

```
<type>(<scope>): brief description

Detailed description explaining the change.

References PhD Glava: <chapter_number>

Closes #<issue>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code refactoring |
| `test` | Test additions/changes |
| `perf` | Performance improvement |
| `clara` | CLARA AI Safety Gap work |
| `cortex` | Neuromorphic cortex work |
| `phd` | PhD thesis-related changes |

### Scopes

| Scope | Description |
|-------|-------------|
| `gf16` | GF16 arithmetic modules |
| `k3` | K3 ternary logic |
| `cortex` | Neuromorphic cortical columns |
| `mesh` | D2D and mesh routing |
| `clara` | CLARA AI Safety Gaps |
| `vsa` | VSA and holographic binding |
| `bitnet` | BitNet b1.58 modules |
| `crown` | Crown47 ROM and sacred constants |
| `power` | Power management (AVS, FBB, Purkinje) |

### Examples

```
feat(cortex): implement cortical_column with LIF dynamics

Implements 8-column cortical array with biologically-inspired
LIF neuron dynamics. Each column uses 5 number formats:
GF16, K3, BitNet b1.58, Q1.15, and packed popcount.

References PhD Glava 36: Holographic brain theorem.

Closes #78

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

```
clara(gap2): implement k3_alu with full Kleene semantics

Implements K3 ternary logic over {-1,0,+1} with encoding:
T=01, U=00, F=10. Truth table verified against Kleene axioms.

References PhD Glava 31: Three-valued belief states.

Closes #82

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

---

## Pull Request Process

1. **Before opening PR:**
   - All RTL tests pass locally
   - Rust witness tests pass (if applicable)
   - Pre-commit hooks pass
   - R-SI compliance verified
   - Documentation updated

2. **PR Title:** Follow commit format
   - Good: `feat(cortex): implement cortical_column with LIF dynamics`
   - Bad: `Added cortex`

3. **PR Description:** Include:
   - Summary of changes
   - Motivation/why
   - Testing approach
   - PhD chapter reference (if applicable)
   - Number formats used
   - Falsifiability witnesses (if applicable)
   - Breaking changes (if any)

4. **CI Checks:**
   - ✅ t27 Format
   - ✅ R-SI-1 no-star
   - ✅ RTL & Cocotb
   - ✅ FPGA Synthesis
   - ✅ Rust Tests (if applicable)
   - ✅ GDS (if applicable)

5. **Code Review:**
   - At least one approval required
   - Address all review comments
   - Keep PRs focused and small

---

## Coding Standards

### Verilog-2005 Compliance

```verilog
// Good
module cortical_column (
    input  wire [7:0]  stim_bus,    // 8-bit stimulus
    input  wire [7:0]  recurrent_in,
    output wire [7:0]  spike_out,
    input  wire        layer_frozen,  // LAYER-FROZEN gate
    input  wire clk,
    input  wire rst_n
);
    // LIF dynamics implementation
endmodule

// Bad (SystemVerilog)
module cortical_column (
    input  logic [7:0]  stim_bus,
    input  logic [7:0]  recurrent_in,
    output logic [7:0]  spike_out,
    input  logic        layer_frozen,
    input  logic clk,
    input  logic rst_n
);
    // ...
endmodule
```

### R-SI-1 Compliance (No `*` operators)

```verilog
// Wrong (R-SI-1 violation)
wire [15:0] result = a * b;

// Correct (shift-add)
wire [15:0] pp0 = b[0] ? a : 16'b0;
wire [15:0] pp1 = b[1] ? {a, 1'b0} : 16'b0;
// ... etc
wire [15:0] result = pp0 + pp1 + ...;
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Modules | `lower_snake_case` | `cortical_column`, `k3_alu` |
| Signals | `lower_snake_case` | `mem_potential`, `spike_count` |
| Parameters | `UPPER_SNAKE_CASE` | `NUM_COLUMNS`, `LIF_THRESHOLD` |
| Constants | `lower_snake_case` | `phi_q15`, `gamma_bps` |

---

## Testing Requirements

### Unit Tests

Every module must have a testbench:

```verilog
`default_nettype none
`timescale 1ns / 1ps

module tb_cortical_column;
    // DUT signals
    reg clk;
    reg rst_n;
    reg [7:0] stim_bus;
    reg [7:0] recurrent_in;
    wire [7:0] spike_out;
    reg layer_frozen;

    // Instantiate DUT
    cortical_column u_dut (
        .stim_bus(stim_bus),
        .recurrent_in(recurrent_in),
        .spike_out(spike_out),
        .layer_frozen(layer_frozen),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Test tracking
    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input expected;
        input actual;
        input [100*8:1] msg;
        begin
            if (expected === actual) begin
                $display("PASS: %s", msg);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s (expected=%h, actual=%h)", msg, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Clock
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        $dumpfile("tb_cortical_column.vcd");
        $dumpvars(0, tb_cortical_column);

        rst_n = 0;
        stim_bus = 8'h0;
        recurrent_in = 8'h0;
        layer_frozen = 1'b0;
        #100;
        rst_n = 1;
        #100;

        // Test LIF dynamics
        // ...

        $display("\n=== SUMMARY ===");
        $display("PASS: %d", pass_count);
        $display("FAIL: %d", fail_count);
        $finish;
    end

endmodule
```

### Integration Tests

```bash
test/tb_integration_mesh.v       # Mesh routing through 20-PE fabric
test/tb_integration_cortex.v    # 8-column cortex integration
test/tb_integration_d2d.v       # D2D holographic mesh
test/tb_integration_clara.v     # CLARA gaps + cortex
```

### Rust Witness Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gamma_q15_encoding() {
        // γ = φ⁻³ ≈ 0.23607 → GAMMA_Q15 = 0x1E35
        let expected = 7733;  // ≡ 7733/32768 = 0.23596
        let actual = GAMMA_Q15;
        let error_pct = ((actual - expected) as f64 / expected as f64) * 100.0;
        assert!(error_pct < 0.05, "Error: {}%", error_pct);
    }

    #[test]
    fn test_three_strand_vote() {
        assert_eq!(three_strand_vote(true, true, false), true);
        assert_eq!(three_strand_vote(true, false, false), false);
    }
}
```

---

## R-SI Compliance

### R-SI-1: Zero `*` operators

```bash
# Check for multiplication operators
grep -n '\*' src/*.v

# Should return empty (or only comments)
```

### R-SI-2 through R-SI-6

See [phi/CONTRIBUTING.md](https://github.com/gHashTag/tt-trinity-phi/blob/main/CONTRIBUTING.md) for full details.

---

## Neuromorphic Guidelines

### LIF Neuron Dynamics

```verilog
// LIF membrane potential update
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_potential <= 8'h00;
        refractory_counter <= 4'h0;
    end else begin
        if (layer_frozen == 1'b0) begin
            // Membrane potential = Σ(stim + recurrent) - decay
            wire [7:0] synaptic_input = stim_bus + recurrent_in;
            wire [7:0] decayed = mem_potential >> 3;  // /8 decay

            if (refractory_counter == 4'h0) begin
                mem_potential <= synaptic_input - decayed;
            end else begin
                refractory_counter <= refractory_counter - 1;
            end

            // Spike generation
            if (mem_potential >= LIF_THRESHOLD) begin
                spike_out <= 8'hFF;  // Fire
                mem_potential <= 8'h00;  // Reset
                refractory_counter <= 4'h2;  // Refractory period
            end else begin
                spike_out <= 8'h00;  // No spike
            end
        end
    end
end
```

### Cortical Column Integration

- 8 columns share global D2D mesh
- LAYER-FROZEN gate locks learned patterns
- Spike count triggers D2D SYNC at 8 spikes

---

## Number Format Guidelines

### Supported Formats

| # | Format | Width | Range | Use Case |
|---|--------|-------|-------|----------|
| 1 | GF(2⁴) / GF16 | 4-bit | 15 elements | VSA binding |
| 2 | K3 Balanced Ternary | 2-bit trit | {-1,0,+1} | Kleene logic |
| 3 | Q8.8 Pseudo-Float | 24-bit | 10⁻³⁸..10³⁸ | Crown47 constants |
| 4 | BitNet b1.58 | 2-bit trit | {-1,0,+1} | Weights |
| 5 | Packed Popcount | 8/16-bit | Hamming 0..N | Sparse counting |
| 6 | Q1.15 Fixed-Point | 16-bit | [-1,+1] | φ-drift, γ-power |
| 7 | BPS (×10⁻⁴) | u32 | 0..10000 | Rust witnesses |
| 8 | Z3 Ternary | enum | {Neg1,Zero,Pos1} | Rust runtime |
| 9a | 21-bit Datalog Clause | 21-bit | 16 atoms×16 clauses | CLARA Gap-3 |
| 9b | 24-bit SAT CNF Literal | 24-bit | 8 vars, 3-CNF | CLARA Gap-9 |
| 9c | 20-bit Proof Tuple | 20-bit | 10 steps×4-bit | CLARA Gap-5 |
| 9d | 48-bit Audit Entry | 48-bit | 64-entry ring | CLARA Gap-10 |

### Format Selection

When adding new modules:
1. Choose format from supported list
2. Follow existing module patterns
3. Ensure zero `*` operators (R-SI-1)
4. Add format-specific test vectors
5. Document format in README

---

## Resources

- [Architecture](docs/ARCHITECTURE.md)
- [CLARA Traceability](CLARA_TRACEABILITY.md)
- [API Documentation](docs/API.md)
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- [Hardware Bring-Up](docs/HARDWARE_BRINGUP.md)
- [Test Coverage](docs/TEST_COVERAGE.md)
- [PhD Dissertation](https://doi.org/10.5281/zenodo.19227877)

---

## License

By contributing, you agree that your contributions will be licensed under the **Apache-2.0** license.

---

## Contact

- GitHub Issues: https://github.com/gHashTag/tt-trinity-gamma/issues
- Discussions: https://github.com/gHashTag/tt-trinity-gamma/discussions