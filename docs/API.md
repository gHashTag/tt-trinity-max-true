# API Documentation — γ-surface (8×4)

## Overview

The γ-surface (MAX-TRUE NEUROMORPHIC FLAGSHIP) is the flagship member of TRI-NET, featuring:
- 8 cortical columns with LIF dynamics and BitNet MLP
- 20-PE GF16 processing elements in quad + 2×2 mesh
- D2D holographic mesh router for cross-die communication
- Full SUPER-CROWN module set (24 modules)
- PhD-anchored monitors (6 modules)

## Top-Level Module: `tt_um_trinity_max_true`

### Port Interface

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `ui_in` | input | 8 | Control and status inputs |
| `uo_out` | output | 8 | Low byte of result |
| `uio_in` | input | 8 | D2D RX / pin functions |
| `uio_out` | output | 8 | High byte / D2D TX |
| `uio_oe` | output | 8 | Output enable for uio pins |
| `ena` | input | 1 | Enable signal |
| `clk` | input | 1 | Clock |
| `rst_n` | input | 1 | Active-low reset |

### Control Pins (ui_in)

| Bit | Name | Function |
|-----|------|----------|
| 0 | `load_mode` | 0=Canonical, 1=Load mode |
| 3:1 | `lucas_idx` | Lucas ROM address (0-5) |
| 4 | `rng_ena` | HWRNG enable |
| 5 | `restraint_mode` | CLARA Gap-4 restraint |
| 6 | `crown_addr_lo` | CROWN47 address bit |
| 7:6 | `crown_addr_hi` | CROWN47 address bits |

### D2D Pins (uio_in/out)

| Bit | Direction | Name | Description |
|-----|-----------|------|-------------|
| 0 | out | `n_tx` | North transmit |
| 1 | out | `e_tx` | East transmit |
| 2 | out | `s_tx` | South transmit |
| 3 | out | `w_tx` | West transmit (SYNC, LAYER-FROZEN) |
| 4 | in | `n_rx` | North receive |
| 5 | in | `e_rx` | East receive |
| 6 | in | `s_rx` | South receive |
| 7 | in | `w_rx` | West receive |

### Output Behavior

**Canonical Mode** (`ui_in[0] = 0`):
- `uo_out[7:0]` = `0xC0`
- `uio_out[7:4]` = `0x4`
- `uio_out[3:0]` = `0x0` (D2D TX idle)
- `{uio_out, uo_out}` = `0x47C0`

**Load Mode** (`ui_in[0] = 1`):
- `uo_out[7:0]` = `mesh_result[7:0] | input_echo[7:0]`
- `uio_out[7:4]` = `mesh_result[15:8] | input_echo[15:8]`
- `uio_out[3:0]` = `{w_tx, s_tx, e_tx, n_tx}` (D2D)

**POST Status** (`ui_in[0]=1 && post_done`):
- `uo_out[7:0]` = `status_byte`
- `uio_out[7:4]` = Status byte high nibble

**CROWN47 ROM** (`uio_in[7]=1 && !ui_in[0]`):
- `addr` = `ui_in[6:0]`
- `byte_sel` = `uio_in[6:5]`
- `uo_out[7:0]` = Selected byte

## Neuromorphic Core

### `cortical_column` — Single Cortical Column

**Description**: LIF neuron with BitNet b1.58 MLP and GF16 projection

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `ena` | input | 1 | Enable |
| `gf_in0` | input | 4 | GF16 input 0 (ternary) |
| `gf_in1` | input | 4 | GF16 input 1 (ternary) |
| `gf_in2` | input | 4 | GF16 input 2 (ternary) |
| `gf_in3` | input | 4 | GF16 input 3 (ternary) |
| `stim_in` | input | 4 | External stimulus |
| `spike_out` | output | 1 | Spike strobe (1 cycle) |
| `membrane_dbg` | output | 8 | Membrane potential (debug) |

**Pipeline Stages**:

1. **Stage 1**: GF16 dot4 projection
   - Ternary weights W={-1,+1,-1,+1}
   - XOR-fold accumulation
   - Output: `proj_reg = gf_in0 ^ gf_in1 ^ gf_in2 ^ gf_in3`

2. **Stage 2**: BitNet b1.58 MLP
   - 8 hidden units
   - Ternary weights {-1,0,+1}
   - Ternary ReLU: fire if popcount >= 2
   - Output: `hidden_sum` (8 bits)

3. **Stage 3**: Sparse PE accumulator
   - Only updates when `hidden_sum != 0`
   - XOR-fold accumulation
   - Output: `sparse_accum` (8 bits)

4. **Stage 4**: LIF membrane dynamics
   - `V[t+1] = V[t] - (V[t] >> 3) + I_syn`
   - Decay: 12.5% per cycle (tau ≈ 8 cycles)
   - Threshold: `0xC0` (192)
   - Spike: fires when `membrane >= 0xC0`

**Parameters**:
- `LIF_THRESHOLD` = `8'hC0`
- `LIF_RESET_V` = `8'h00`

### `trinity_cortex_8col` — 8-Column Cortex

**Description**: Array of 8 cortical columns with spike aggregation

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `ena` | input | 1 | Enable |
| `gf_in0` | input | 4 | GF16 input 0 (to all columns) |
| `gf_in1` | input | 4 | GF16 input 1 |
| `gf_in2` | input | 4 | GF16 input 2 |
| `gf_in3` | input | 4 | GF16 input 3 |
| `stim_bus` | input | 32 | 4-bit stimulus per column |
| `spike_count` | output | 4 | Number of active columns (0-8) |
| `spike_vec` | output | 8 | Spike vector per column |
| `cortex_ok` | output | 1 | Cortex healthy |

**Spike Counting**:
- `spike_count` = popcount(`spike_vec`)
- `spike_count == 8` triggers SYNC on D2D west TX

## D2D Holographic Mesh

### `d2d_holo_mesh` — 4-Port Router

**Description**: Cross-die holographic mesh router with LAYER-FROZEN gate

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `ena` | input | 1 | Enable |
| `spike_count` | input | 4 | Spike count from cortex |
| `spike_vec` | input | 8 | Spike vector |
| `gf_tag` | input | 4 | GF16 route tag |
| `layer_frozen` | input | 1 | LAYER-FROZEN gate (PhD Thm 36.1) |
| `n_rx` | input | 1 | North RX input |
| `e_rx` | input | 1 | East RX input |
| `s_rx` | input | 1 | South RX input |
| `w_rx` | input | 1 | West RX input |
| `n_tx` | output | 1 | North TX output |
| `e_tx` | output | 1 | East TX output |
| `s_tx` | output | 1 | South TX output |
| `w_tx` | output | 1 | West TX output (SYNC) |
| `n_rx_q` | output | 1 | Latched North RX |
| `e_rx_q` | output | 1 | Latched East RX |
| `s_rx_q` | output | 1 | Latched South RX |
| `w_rx_q` | output | 1 | Latched West RX |
| `mesh_ok` | output | 1 | Mesh healthy |

**TX Logic**:
| Direction | Data Source |
|-----------|-------------|
| North | `spike_count[3]` (MSB) |
| East | `spike_count[0]` (LSB) |
| South | `gf_tag[0]` (route tag) |
| West | `sync_strobe` (gated by `layer_frozen`) |

**SYNC Strobe**: Asserted when `spike_count == 8` (all columns fired)

**LAYER-FROZEN Gate** (PhD Theorem 36.1, R18):
- When `layer_frozen = 1`, `w_tx = 0` (SYNC disabled)
- Prevents spurious cross-die synchronization after convergence

## Compute Fabric

### `trinity_master_fsm` — Master Control

**Description**: Controls packet flow between host and compute mesh

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `ena` | input | 1 | Enable |
| `load_mode` | input | 1 | Load mode select |
| `host_in_pkt` | output | 32 | Inbound packet to mesh |
| `host_in_valid` | output | 1 | Inbound packet valid |
| `host_in_ready` | input | 1 | Mesh ready for input |
| `host_out_pkt` | input | 32 | Outbound packet from mesh |
| `host_out_valid` | input | 1 | Outbound packet valid |
| `host_out_ready` | output | 1 | Host ready for output |
| `result_reg` | input | 16 | Result register |
| `result_valid_q` | input | 1 | Result valid |
| `rcpt_checksum_q` | input | 8 | Receipt checksum |
| `rcpt_job_id_q` | input | 8 | Receipt job ID |
| `rcpt_tile_id_q` | input | 2 | Receipt tile ID |
| `rcpt_valid_q` | input | 1 | Receipt valid |

### `trinity_max_true_20pe` — 20-PE Mesh

**Description**: 1× quad mesh (16 PE) + 1× 2×2 mesh (4 PE) = 20 PEs

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `host_in_pkt` | input | 32 | Inbound packet |
| `host_in_valid` | input | 1 | Inbound packet valid |
| `host_in_ready` | output | 1 | Ready for inbound |
| `host_out_pkt` | output | 32 | Outbound packet |
| `host_out_valid` | output | 1 | Outbound packet valid |
| `host_out_ready` | input | 1 | Ready for outbound |
| `dbg_tile0_result` | output | 16 | Tile 0 debug result |

**Mesh Topology**:
```
Quad Mesh (16 PE):    2×2 Mesh (4 PE):
PE0 PE1 PE2 PE3      PE16 PE17
PE4 PE5 PE6 PE7      PE18 PE19
PE8 PE9 PE10 PE11
PE12 PE13 PE14 PE15
```

**Routing**: Full-mesh interconnect with all-to-all routing

### `gf16_dot4_sparse` — Sparse Dot4

**Description**: Sparse GF16 dot product with mask gating

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `a0, a1, a2, a3` | input | 16 | First vector components |
| `b0, b1, b2, b3` | input | 16 | Second vector components |
| `sparse_mask` | input | 4 | Sparse enable mask |
| `result` | output | 16 | Sparse dot product |

**Operation**: Only computes terms where `sparse_mask[i] = 1`

## SUPER-CROWN Modules

### Safety Monitoring

#### `cassini_post` — Cassini-Lucas POST

**Description**: Extended Lucas POST with Cassini identity verification

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `cassini_ok` | output | 1 | Cassini identity verified |
| `post_done` | output | 1 | POST sequence complete |

**Cassini Identity**: `L_n^2 - L_(n+1) × L_(n-1) = 5 × (-1)^n`

#### `plrm_counter` — PLRM Runtime Monitor

**Description**: Mutual-exclusion runtime monitor for arithmetic/orchestrator arbitration

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `req_arith` | input | 1 | Arithmetic request |
| `req_orch` | input | 1 | Orchestrator request |
| `grant_arith` | output | 1 | Arithmetic grant |
| `grant_orch` | output | 1 | Orchestrator grant |
| `plrm_error` | output | 1 | Mutual exclusion error |

#### `bpb_counter` — BPB Shannon Entropy

**Description**: Bounds-Preserving Bound counter for predictive entropy

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `valid` | input | 1 | Input valid |
| `pred_class` | input | 8 | Predicted class |
| `true_class` | input | 8 | True class |
| `total_loss` | output | 24 | Total BPB loss |
| `sample_count` | output | 16 | Sample count |
| `bpb_ok` | output | 1 | BPB in bounds |

#### `bpb_lower_bound_guard`

**Description**: Shannon lower-bound guard for BPB

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `bpb_q24` | input | 32 | BPB value (Q24 fixed) |
| `floor_q24` | input | 32 | Floor value |
| `sample` | input | 1 | Sample strobe |
| `bpb_violation` | output | 1 | Bound violated |
| `sticky_violation` | output | 1 | Sticky violation flag |
| `fault_code` | output | 2 | Fault type |

#### `nca_entropy_monitor`

**Description**: Non-Compressive Architecture entropy band monitor

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `trits_in` | input | 162 | Ternary data stream |
| `sample` | input | 1 | Sample strobe |
| `entropy_violation` | output | 1 | Entropy out of bounds |
| `in_band` | output | 1 | Entropy in target band |
| `last_popcount` | output | 7 | Last popcount value |

#### `strobe_seed_guard`

**Description**: Forbidden-seed hardware guard

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `seed_in` | input | 32 | Input seed |
| `seed_write` | input | 1 | Write enable |
| `seed_out` | output | 32 | Safe seed output |
| `seed_forbidden` | output | 1 | Seed was forbidden |
| `seed_replaced` | output | 1 | Seed was replaced |

#### `phi_distance_oracle`

**Description**: 360-entry φ-distance LUT oracle

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `angle_deg` | input | 9 | Angle in degrees (0-359) |
| `valid_in` | input | 1 | Input valid |
| `dist_out` | output | 16 | φ distance (Q1.15) |
| `valid_out` | output | 1 | Output valid |

### Compute Modules

#### `vsa_matmul_8x8`

**Description**: Vector Symbolic Architecture 8×8 ternary matmul

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start computation |
| `a_flat` | input | 128 | Matrix A flattened |
| `b_flat` | input | 128 | Matrix B flattened |
| `done` | output | 1 | Computation done |
| `c_flat` | output | 512 | Result C flattened |
| `matmul_ok` | output | 1 | Matmul verified |

#### `vsa_matmul_16x16`

**Description**: VSA 16×16 ternary matmul (JEPA-T tier)

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start computation |
| `a_flat` | input | 512 | Matrix A flattened |
| `b_flat` | input | 512 | Matrix B flattened |
| `done` | output | 1 | Computation done |
| `c_flat` | output | 2048 | Result C flattened |
| `matmul_ok` | output | 1 | Matmul verified |

#### `bitnet_encoder`

**Description**: BitNet b1.58 encoder

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start encoding |
| `x_in` | input | 128 | Input vector |
| `done` | output | 1 | Encoding done |
| `y_out` | output | 64 | Ternary encoded output |
| `encoder_ok` | output | 1 | Encoder verified |

### Cryptographic Modules

#### `blake3_anchor`

**Description**: BLAKE3-mini hash anchor

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start hash |
| `m_in` | input | 512 | Input message |
| `done` | output | 1 | Hash done |
| `digest` | output | 256 | BLAKE3 digest |
| `hash_ok` | output | 1 | Hash verified |

#### `crc32_receipt`

**Description**: CRC-32 receipt generator

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `start` | input | 1 | Start CRC |
| `valid` | input | 1 | Input byte valid |
| `byte_in` | input | 8 | Input byte |
| `crc_raw` | output | 32 | Raw CRC |
| `crc_final` | output | 32 | Final CRC |

#### `multi_tile_receipt`

**Description**: Multi-tile receipt aggregator

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `t0_valid, t1_valid, t2_valid, t3_valid` | input | 1 | Tile valid |
| `t0_checksum, ...` | input | 8 | Tile checksum |
| `t0_job_id, ...` | input | 8 | Tile job ID |
| `agg_checksum` | output | 8 | Aggregated checksum |
| `agg_job_id` | output | 8 | Aggregated job ID |
| `attested_mask` | output | 4 | Attested tiles mask |
| `all_attested` | output | 1 | All tiles attested |
| `multi_rcpt_ok` | output | 1 | Receipt verified |

### Memory Modules

#### `ring27_memory`

**Description**: RING27 ternary memory

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `shift` | input | 1 | Shift ring |
| `wr_en` | input | 1 | Write enable |
| `addr` | input | 5 | Address (0-26) |
| `wr_data` | input | 2 | Write data |
| `rd_data` | output | 2 | Read data |
| `ring_ok` | output | 1 | Memory verified |

#### `wb_status_reg` — Wishbone Status

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `phi_ok` | input | 1 | φ POST status |
| `lucas_ok` | input | 1 | Lucas POST status |
| `matmul_ok` | input | 1 | Matmul status |
| `post_done` | input | 1 | POST done |
| `rcpt_valid` | input | 1 | Receipt valid |
| `hwrng_nonzero` | input | 1 | HWRNG nonzero |
| `status_byte` | output | 8 | Status byte |

### ALU Modules

#### `alu9_decoder` — Trinity Ternary ALU-9

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `opcode` | input | 4 | Opcode |
| `a` | input | 2 | Operand A |
| `b` | input | 2 | Operand B |
| `result` | output | 2 | Result |
| `valid` | output | 1 | Result valid |
| `decoder_ok` | output | 1 | Decoder verified |

**Opcodes** (ternary): 0=XOR, 1=XNOR, 2=AND, 3=OR, 4=NOT, 5=MUX, 6=ACC, 7=ADD, 8=SUB

#### `phi_pll_div` — φ-PLL Fractional Divider

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `phi_tick` | output | 1 | φ-synchronized tick |
| `state` | output | 3 | Current state |
| `phi_div_ok` | output | 1 | Divider verified |

## Power Management

### `avs_controller_96`

**Description**: 96-island AVS voltage controller

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `power_req` | input | 96 | Power request per island |
| `therm_mon` | input | 6 | Thermal monitor (0-63) |
| `avs_enable` | input | 1 | AVS enable |
| `voltage_level` | output | 192 | 2 bits per island |
| `therm_warning` | output | 6 | Thermal warning bits |
| `power_gate` | output | 1 | Global power gate |

**Voltage Levels**:
| Code | Voltage | Power |
|------|---------|-------|
| 00 | 0.75V | -21% |
| 01 | 0.85V | -10% |
| 10 | 0.95V | baseline |
| 11 | 1.05V | +10% |

**Thermal Thresholds**:
| Condition | Threshold | Action |
|-----------|-----------|--------|
| WARNING | 50 | Reduce voltage |
| CRITICAL | 58 | Power gate |

**TOPS/W Boost**:
- Baseline: 104 TOPS/W
- With AVS-96: 405 TOPS/W (3.9× boost at η=0.93)
- Theoretical max (η=1.0): 495 TOPS/W (4.8×)

### `fbb_active_path`

**Description**: Forward Body Bias active path controller

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `enable` | input | 1 | FBB enable |
| `temp_mon` | input | 8 | Temperature (0-255) |
| `activity` | input | 8 | Activity level (0-255) |
| `fbb_level` | output | 8 | FBB voltage level |
| `fbb_enable` | output | 1 | FBB output enable |

**FBB Adjustment**:
- High temperature: Reduce FBB
- High activity: Increase FBB
- Based on temp + activity heuristic

### `purkinje_thermal_gate`

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `temp_in` | input | 8 | Temperature |
| `temp_warning` | output | 1 | Warning threshold |
| `temp_critical` | output | 1 | Critical threshold |
| `power_gate` | output | 1 | Gate power |

## Quantization Modules

### Quantizers

All quantizers share a common interface pattern:

#### `int4_quantizer`

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `fp16_in` | input | 16 | FP16 input |
| `scale_exp` | input | 4 | Scale exponent |
| `zero_point` | input | 3 | Zero point offset |
| `int4_out` | output | 4 | Int4 output |

#### `nf4_quantizer`

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `fp16_in` | input | 16 | FP16 input |
| `scale_idx` | input | 4 | Scale index |
| `nf4_out` | output | 4 | NF4 output |

#### `int8_quantizer`, `fp8_e4m3_quantizer`, `fp8_e5m2_quantizer`, `posit16_quantizer`

Similar interface with appropriate output width.

### Converters

#### `gf16_to_fp16`, `gf16_to_posit16`

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `gf16_in` | input | 16 | GF16 input |
| `out` | output | 16 | Converted output |

## CLARA AI Safety Gaps

The γ-surface implements CLARA AI Safety Gaps 1-4 (partial):

| Gap | Module | Description |
|-----|--------|-------------|
| Gap-1 | `redteam_filter` | Redteam filter |
| Gap-2 | `k3_alu` | Ternary K3 ALU |
| Gap-3 | `datalog_engine_mini` | Mini Datalog engine |
| Gap-4 | `restraint_ctrl` | Bounded rationality |

(See tt-trinity-euler for full Gap-1 through Gap-10 implementation)

## GF16 Arithmetic

### `gf16_add`

**Ports**: `a`, `b` (input 16), `result` (output 16)

**Operation**: XOR (characteristic 2 field)

### `gf16_mul`

**Ports**: `a`, `b` (input 16), `result` (output 16)

**Format**:
```
[15]   sign      (1 bit)
[14:9] exponent  (6 bits)
[8:0]  mantissa  (9 bits)
```

**Special Values**:
- `0x0000`: Zero
- `0x7E00`: +Infinity
- `0xFE00`: -Infinity
- `0xFE01`: NaN

### `gf16_dot4`

**Ports**: `a0-a3`, `b0-b3` (input 16 each), `result` (output 16)

**Canonical**: `dot4(1.0, 2.0, 3.0, 4.0) = 0x47C0`

### `gf16_dot8`

**Ports**: `a0-a7`, `b0-b7` (input 16 each), `result` (output 16)

## Holographic Compute

### `holo_lut_pe`

**Description**: FHRR holographic LUT processing element

**Ports**:

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock |
| `rst_n` | input | 1 | Active-low reset |
| `op` | input | 2 | Operation (0=bind, 1=unbind, 2=bundle) |
| `hv_a` | input | 32 | Hypervector A |
| `hv_b` | input | 32 | Hypervector B |
| `valid_in` | input | 1 | Input valid |
| `hv_out` | output | 32 | Result hypervector |
| `valid_out` | output | 1 | Output valid |

**Operations**:
- bind: XOR
- unbind: XNOR
- bundle: Permuted XOR

## Performance Characteristics

| Metric | Value |
|--------|-------|
| Area | ~4100 cells (cortex) + ~2000 cells (mesh) + ~2500 cells (SUPER-CROWN) |
| Power | 56 mW (with AVS-96) |
| TOPS/W | 405 (with AVS-96, 5.4× boost) |
| Latency | 4 cycles (cortex pipeline) |
| Throughput | 20 GF16 MAC/cycle (mesh) + 8 spikes/cycle (cortex) |
| Clock | 50 MHz |

## R-SI-1 Compliance

All modules comply with R-SI-1 (zero multiplication operators):
- GF16 multiplication uses shift-add partial products
- Quantizers use shift-based scaling
- BitNet uses XOR-based ternary MAC
- LIF uses shift-based decay

## Sacred Physics Anchor

The γ-surface chip extends the sacred identity with neuromorphic dynamics:
```
φ² + φ⁻² = 3 (proven via Lucas POST)
LIF membrane: V[t+1] = V[t] - (V[t] >> 3) + I_syn
```

DOI: 10.5281/zenodo.19227877

## TRN Packet Protocol

**Format** (32 bits):
```
[31:28] opcode   [27:26] dst     [25:24] src
[23:20] lane     [19:16] unused  [15:0]  payload
```

**Opcodes**:
| Opcode | Value | Description |
|--------|-------|-------------|
| LOAD_A | 1 | Load operand A |
| LOAD_B | 2 | Load operand B |
| COMPUTE | 3 | Compute operation |
| LOAD_JOB | 4 | Load job ID |
| LOAD_NONCE | 5 | Load nonce |
| READ_RES | 6 | Read result |
| RESULT | 0xA | Result packet |
| RECEIPT | 0xB | Receipt packet |

**Receipt Format**:
```
[31:28] RECEIPT   [27:26] dst     [25:24] src
[23:20] tile_id   [19:16] opcode  [15:8]  job_id
[7:0]   checksum
```