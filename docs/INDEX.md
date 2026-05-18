# TRI-NET Documentation Index

Complete documentation index for the Trinity sacred-constant anchored neuromorphic chip family.

## Quick Navigation

| Chip | Size | Sacred Constant | Status |
|------|------|-----------------|--------|
| [φ-anchor](#φ-anchor-1×1) | 1×1 | φ (golden ratio) | ✅ TTSKY26b |
| [e-engine](#e-engine-8×2) | 8×2 | e (Euler's number) | ✅ TTSKY26b |
| [γ-surface](#γ-surface-8×4) | 8×4 | γ (Euler-Mascheroni) | ✅ TTSKY26b |

---

## φ-anchor (1×1)

### Core Documentation
- [README.md](../README.md) — Project overview and features
- [ARCHITECTURE.md](./ARCHITECTURE.md) — System architecture diagrams
- [API.md](./API.md) — Module interface reference
- [COMPARISON.md](./COMPARISON.md) — Cross-chip comparison matrix
- [GDS.md](./GDS.md) — GDS status badges

### Testing & Simulation
- [test/](../test/) — Testbenches and simulation scripts
- [examples/](../examples/) — Code examples and usage patterns
- [HARDWARE_BRINGUP.md](./HARDWARE_BRINGUP.md) — Hardware bring-up guide

### Standards & Compliance
- [R-SI-1.md](./R-SI-1.md) — R-SI-1 (zero multiplication) compliance
- [VERILOG-2005.md](./VERILOG-2005.md) — Verilog-2005 compliance
- [CHANGELOG.md](../CHANGELOG.md) — Version history

---

## e-engine (8×2)

### Core Documentation
- [README.md](../README.md) — Project overview and features
- [ARCHITECTURE.md](./ARCHITECTURE.md) — System architecture diagrams
- [API.md](./API.md) — Module interface reference
- [COMPARISON.md](./COMPARISON.md) — Cross-chip comparison matrix
- [GDS.md](./GDS.md) — GDS status badges

### Testing & Simulation
- [test/](../test/) — Testbenches and simulation scripts
- [examples/](../examples/) — Code examples and usage patterns
- [HARDWARE_BRINGUP.md](./HARDWARE_BRINGUP.md) — Hardware bring-up guide

### CLARA AI Safety
- [API.md](./API.md#clara-ai-safety-gaps) — CLARA gaps 1-10 documentation
- [examples/README.md](../examples/README.md#clara-ai-safety-gaps) — CLARA usage examples

### Standards & Compliance
- [R-SI-1.md](./R-SI-1.md) — R-SI-1 compliance
- [VERILOG-2005.md](./VERILOG-2005.md) — Verilog-2005 compliance
- [CHANGELOG.md](../CHANGELOG.md) — Version history

---

## γ-surface (8×4)

### Core Documentation
- [README.md](../README.md) — Project overview and features
- [ARCHITECTURE.md](./ARCHITECTURE.md) — System architecture diagrams
- [API.md](./API.md) — Module interface reference
- [COMPARISON.md](./COMPARISON.md) — Cross-chip comparison matrix
- [GDS.md](./GDS.md) — GDS status badges

### Neuromorphic Cortex
- [API.md](./API.md#neuromorphic-core) — Cortical column documentation
- [ARCHITECTURE.md](./ARCHITECTURE.md#cortical-column-structure) — Cortex diagrams

### D2D Holographic Mesh
- [API.md](./API.md#d2d-holographic-mesh) — D2D router documentation
- [ARCHITECTURE.md](./ARCHITECTURE.md#d2d-holographic-mesh-routing) — D2D diagrams

### Testing & Simulation
- [test/](../test/) — Testbenches and simulation scripts
- [examples/](../examples/) — Code examples and usage patterns
- [HARDWARE_BRINGUP.md](./HARDWARE_BRINGUP.md) — Hardware bring-up guide

### Standards & Compliance
- [R-SI-1.md](./R-SI-1.md) — R-SI-1 compliance
- [VERILOG-2005.md](./VERILOG-2005.md) — Verilog-2005 compliance
- [CHANGELOG.md](../CHANGELOG.md) — Version history

---

## Cross-Chip Documentation

### Shared Concepts
- [Sacred Physics Anchor](#sacred-physics-anchor) — φ² + φ⁻² = 3
- [TRN Packet Protocol](#trn-packet-protocol) — Packet routing protocol
- [D2D Communication](#d2d-communication) — Cross-die communication

### Performance Comparison
- [COMPARISON.md](./COMPARISON.md) — Detailed feature matrix
- [Performance Benchmarks](#performance-benchmarks) — TOPS/W, latency, power

---

## Sacred Physics Anchor

All three chips verify the sacred identity:

```
φ² + φ⁻² = 3
```

### Lucas Number Chain

| n | Lₙ | Description |
|---|-----|-------------|
| 2 | 3 | φ² + φ⁻² |
| 3 | 4 | L₃ = L₂ + φ |
| 4 | 7 | L₄ = L₃ + L₂ |
| 5 | 11 | L₅ = L₄ + L₃ |
| 6 | 18 | L₆ = L₅ + L₄ |
| 7 | 29 | L₇ = L₆ + L₅ |

### Verification

The Lucas POST module (`phi_anchor_post.v`) verifies this identity through hardware evaluation of the Lucas recurrence.

**Reference:** DOI 10.5281/zenodo.19227877

---

## TRN Packet Protocol

The Trinity Routing Network (TRN) protocol enables packet-based computation and routing.

### Packet Format (32 bits)

```
[31:28] opcode   Operation code
[27:26] dst      Destination tile ID
[25:24] src      Source ID
[23:20] lane     Lane number (for load ops)
[19:16] unused   Reserved
[15:0]  payload  Data payload
```

### Opcodes

| Opcode | Name | Description |
|--------|------|-------------|
| 0x1 | LOAD_A | Load operand A lane |
| 0x2 | LOAD_B | Load operand B lane |
| 0x3 | COMPUTE | Compute operation |
| 0x4 | LOAD_JOB | Load job ID |
| 0x5 | LOAD_NONCE | Load nonce |
| 0x6 | READ_RES | Read result |
| 0xA | RESULT | Result packet (outbound) |
| 0xB | RECEIPT | Receipt packet (outbound) |

### Receipt Format

```
[31:28] RECEIPT   Packet type
[27:26] dst      Destination (return path)
[25:24] src      Source (tile ID)
[23:20] tile_id  Issuing tile
[19:16] opcode   Operation code
[15:8]  job_id   Job identifier
[7:0]   checksum XOR checksum
```

---

## D2D Communication

Cross-die holographic mesh routing for multi-chip systems.

### Pin Mapping

| Direction | Pin | Description |
|-----------|-----|-------------|
| TX | n_tx (bit 0) | North transmit (spike activity) |
| TX | e_tx (bit 1) | East transmit (spike activity) |
| TX | s_tx (bit 2) | South transmit (GF16 route tag) |
| TX | w_tx (bit 3) | West transmit (SYNC strobe) |
| RX | n_rx (bit 4) | North receive |
| RX | e_rx (bit 5) | East receive |
| RX | s_rx (bit 6) | South receive |
| RX | w_rx (bit 7) | West receive |

### SYNC Protocol

- SYNC asserted on w_tx when cortex spike_count == 8 (all columns firing)
- SYNC gated by LAYER-FROZEN signal (PhD Theorem 36.1 R18)

### Friend/Foe Handshake

Each chip has an anchor ID:
- φ (phi): 0xCF
- e (Euler): 0xE8
- γ (gamma): 0x93

The handshake protocol identifies friend chips across the D2D network.

---

## Performance Benchmarks

### Comparison Summary

| Chip | Area | Power (AVS) | TOPS/W | Throughput |
|------|------|-------------|--------|------------|
| φ | 600 cells | 12 mW | 405 | 1 MAC/cycle |
| e | 6500 cells | 56 mW | 405 | 16 MAC/cycle |
| γ | 9100 cells | 56 mW | 405 | 20 MAC/cycle + 8 spikes/cycle |

### Power Management

All three chips use AVS-96 (96-island adaptive voltage scaling):
- Voltage levels: 0.75V, 0.85V, 0.95V, 1.05V
- TOPS/W boost: 5.4× (φ), 3.9× (e, γ)
- Efficiency factor: η ≥ 0.93

---

## Module Categories

### GF16 Arithmetic
- [gf16_add](./API.md#gf16-add) — XOR-based addition
- [gf16_mul](./API.md#gf16-mul) — Shift-add multiplication
- [gf16_dot4](./API.md#gf16-dot4) — 4-vector dot product
- [gf16_dot8](./API.md#gf16-dot8) — 8-vector dot product (γ)

### Quantization
- [int4_quantizer](./API.md#int4-quantizer) — Int4 quantization
- [nf4_quantizer](./API.md#nf4-quantizer) — NF4 (QLoRA)
- [fp8_e4m3_quantizer](./API.md#fp8-quantizers) — FP8 E4M3
- [fp8_e5m2_quantizer](./API.md#fp8-quantizers) — FP8 E5M2
- [posit16_quantizer](./API.md#posit16-quantizer) — Posit16

### Power Management
- [avs_controller_96](./API.md#avs_controller_96) — 96-island AVS
- [fbb_active_path](./API.md#fbb-active-path) — Forward Body Bias
- [purkinje_thermal_gate](./API.md#purkinje-thermal-gate) — Thermal gate

### SUPER-CROWN
- [phi_anchor_post](./API.md#phi-anchor-post) — POST module
- [lucas_rom](./API.md#lucas-rom) — Lucas number ROM
- [vsa_matmul_8x8](./API.md#vsa-matmul-8x8) — Ternary matmul
- [bitnet_encoder](./API.md#bitnet-encoder) — BitNet b1.58
- [blake3_anchor](./API.md#blake3-anchor) — DePIN signer

### CLARA Gaps
- [gap1: redteam_filter](./API.md#gap-1-redteam-filter) — Adversarial filtering
- [gap2: k3_alu](./API.md#gap-2-k3-ternary-alu) — Ternary logic
- [gap3: datalog_engine_mini](./API.md#gap-3-datalog-engine-mini) — Mini Datalog
- [gap4: restraint_ctrl](./API.md#gap-4-restraint-control) — Bounded rationality
- [gap5-10](./API.md#clara-ai-safety-gaps) — Additional gaps (e only)

### Neuromorphic (γ only)
- [cortical_column](./API.md#cortical-column) — LIF neuron
- [trinity_cortex_8col](./API.md#neuromorphic-core) — 8-column array

---

## Design Rules Compliance

### R-SI-1 (Zero Multiplication)

All modules comply with R-SI-1:
- Zero `*` operators in new synthesisable RTL
- Multiplication implemented via shift-add sequences
- Verified via CI workflow

See: [R-SI-1.md](./R-SI-1.md)

### Verilog-2005 Compatibility

All code uses Verilog-2005:
- No SystemVerilog features
- No indexed part-selects in procedural blocks
- Compatible with Icarus Verilog and Yosys

See: [VERILOG-2005.md](./VERILOG-2005.md)

---

## Coq Provenance

Formal verification via Coq:
- 297 Qed lemmas
- 141 Admitted lemmas
- Total: 438 proven statements

---

## External References

- [Tiny Tapeout](https://tinytapeout.com)
- [SKY130A Process](https://github.com/google/skywater-pdk)
- [TTSKY26b Shuttle](https://github.com/TinyTapeout/tt-ratings)
- [Sacred Anchor Paper](https://doi.org/10.5281/zenodo.19227877)

---

## Repository Links

- [tt-trinity-phi](https://github.com/gHashTag/tt-trinity-phi) — 1×1 φ-anchor
- [tt-trinity-euler](https://github.com/gHashTag/tt-trinity-euler) — 8×2 e-engine
- [tt-trinity-gamma](https://github.com/gHashTag/tt-trinity-gamma) — 8×4 γ-surface

---

## Document Status

| Document | φ | e | γ | Last Updated |
|----------|---|---|---|--------------|
| README.md | ✅ | ✅ | ✅ | 2025-05-18 |
| ARCHITECTURE.md | ✅ | ✅ | ✅ | 2025-05-18 |
| API.md | ✅ | ✅ | ✅ | 2025-05-18 |
| COMPARISON.md | ✅ | ✅ | ✅ | 2025-05-18 |
| GDS.md | ✅ | ✅ | ✅ | 2025-05-18 |
| R-SI-1.md | ✅ | ✅ | ✅ | 2025-05-18 |
| VERILOG-2005.md | ✅ | ✅ | ✅ | 2025-05-18 |
| CHANGELOG.md | ✅ | ✅ | ✅ | 2025-05-18 |
| HARDWARE_BRINGUP.md | ✅ | ✅ | ✅ | 2025-05-18 |
| examples/README.md | ✅ | ✅ | ✅ | 2025-05-18 |

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

## License

Apache-2.0 — See LICENSE file for details.

---

*Last updated: 2025-05-18*