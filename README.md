# TRI-1 MAX-TRUE — FLAGSHIP Trinity GF16 32-cell + Full SUPER-CROWN

[![Test](../../actions/workflows/test.yaml/badge.svg)](../../actions/workflows/test.yaml)
[![FPGA](../../actions/workflows/fpga.yaml/badge.svg)](../../actions/workflows/fpga.yaml)
[![GDS](../../actions/workflows/gds.yaml/badge.svg)](../../actions/workflows/gds.yaml)

**Flagship SKU of the TRI-1 Triad (Nano / Mid / MAX-TRUE).** W15-TT-E
submission for TTSKY26b, 8×4 TT tiles (largest allowed digital
footprint, ~0.7047 mm² Sky130A).

> **Anchor:** φ² + φ⁻² = 3 · DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
> **License:** Apache-2.0

## Architecture

### Compute fabric — TRUE 2× Mid (32 honest GF16 cells)

```
host_in_pkt[31:0]
       │
       └─► trinity_max_true_dual           (lane[3] = cluster_sel)
              ├─► cluster_A (quad_mesh)    (lane[2:1] = bank_sel)
              │     ├─► bank0 (mesh_2x2)   (dst[27:26] = tile_id)
              │     │     ├─► tile0 (GF16 cell)
              │     │     ├─► tile1
              │     │     ├─► tile2
              │     │     └─► tile3
              │     ├─► bank1 (mesh_2x2)   ─► 4 cells
              │     ├─► bank2 (mesh_2x2)   ─► 4 cells
              │     └─► bank3 (mesh_2x2)   ─► 4 cells
              └─► cluster_B (quad_mesh)    ─► 16 cells
```

**Total: 2 clusters × 4 banks × 4 tiles = 32 GF16 MAC cells**

No silicon shortcuts, no time-multiplexing tricks: every cycle, both
clusters can independently process packets, doubling peak throughput
versus Mid (16 cells, 8×2).

### SUPER-CROWN — full Mid module set preserved (18 modules)

| Module | Role |
|---|---|
| `phi_anchor_post` | Power-on proof of φ²+φ⁻²=3 via Lucas recurrence |
| `lucas_rom` ×7 | Lucas sequence ROM (L₂..L₇) + addressable host probe |
| `vsa_matmul_8x8` | Ternary VSA matmul (8×8) |
| `vsa_matmul_16x16` | Ternary VSA matmul (16×16), JEPA-T tier |
| `bitnet_encoder` | BitNet ternary encoder (128 → 64) |
| `bpb_counter` | Bits-per-byte loss counter |
| `blake3_anchor` | BLAKE3-mini RECEIPT signer |
| `multi_tile_receipt` | 4-tile RECEIPT aggregator |
| `crc32_receipt` | CRC-32 of RECEIPT triplet |
| `alu9_decoder` | Trinity ternary ALU-9 |
| `ring27_memory` | RING27 ternary memory (3-bank Coptic) |
| `hwrng_lfsr` | 16-bit LFSR for die-unique nonce |
| `phi_pll_div` | φ-PLL fractional divider |
| `wb_status_reg` | Wishbone-lite POST status byte |
| `wishbone_full` | Wishbone-lite full peripheral |
| `trinity_master_fsm` | Packet master FSM |
| `trinity_mesh_2x2` | 4-cell base mesh (×8 = 32 cells) |
| `gf16_dot4` | Canonical 0x47C0 anchor path |

### Packet routing contract

| Bit field | Meaning |
|---|---|
| `pkt[23]` = lane[3] | **cluster_sel** — picks A/B in `trinity_max_true_dual` |
| `pkt[22:21]` = lane[2:1] | **bank_sel** — picks 1 of 4 banks in `trinity_quad_mesh` |
| `pkt[20]` = lane[0] | preserved for legacy operand_lane (`trinity_gf16_tile`) |
| `pkt[27:26]` = dst | tile id 0..3 inside the selected bank |

### Cross-die anchor (TG-TRIAD-X)

After reset with `load_mode=0`, all three TRI-1 dice
({Nano, Mid, MAX-TRUE}) drive **`{uio_out, uo_out} == 0x47C0`** —
the dot4(1.0, 2.0, 3.0, 4.0) GF16 canonical value. This equality
is the cross-die anchor of PhD Theorem 36.1 (`docs/phd/chapters/flos_70.tex`).

## R-SI-1 compliance

* **Zero NEW `*` operators** in any new RTL file (`trinity_quad_mesh.v`,
  `trinity_max_true_dual.v`, `tt_um_trinity_max_true.v`).
* Legacy `gf16_mul.v` (BF16 mantissa multiplier producing 1 `$mul` per
  instance) is grandfathered per `TRI_NET_SHUTTLE_TRIAD.md` Rule 2 and
  [`tt-trinity-gf16#4`](https://github.com/gHashTag/tt-trinity-gf16/issues/4)
  deferred-ttsky26c.
* Total `$mul` after synthesis: **32 cells × 1 mul = 32**, all legacy.

## Pinout

| Pin | Function |
|---|---|
| `ui[0]` | load_mode (0=canonical 0x47C0 default, 1=packet path + status_byte) |
| `ui[3:1]` | lucas_idx — selects L_n probe |
| `ui[7:4]` | reserved |
| `uo[7:0]` | result[7:0] (canonical 0x47C0 default; mesh result_lo after FSM) |
| `uio[7:0]` | result[15:8] OR status_byte when load_mode && post_done |

## Build & test

```bash
# Local iverilog smoke (canonical anchor)
cd sim && iverilog -o tb_canonical.out \
  -I../src ../src/*.v tb_canonical.v && vvp tb_canonical.out

# Cocotb (RTL)
cd test && make

# Yosys lint (R-SI-1 audit)
yosys -p "read_verilog -I src src/*.v; hierarchy -top tt_um_trinity_max_true; \
          proc; opt; stat" | grep '\$mul'
```

## Sizing & cost

| SKU | Cells | Footprint | Area mm² | Cost EUR |
|---|---|---|---|---|
| Nano | 1 | 1×1 | 0.018 | €220 |
| Mid | 16 | 8×2 | 0.311 | €1,270 |
| **MAX-TRUE FLAGSHIP** | **32 + 18 CROWN** | **8×4** | **0.705** | **€2,390** |

Cost breakdown for MAX-TRUE: 32 TT tiles × €70 = €2,240 + €100 PCB + €50 shipping.

## References

* MASTER-EPIC: [trinity-fpga#61](https://github.com/gHashTag/trinity-fpga/issues/61)
* TRI-1 Triad spec: [trinity-fpga#49](https://github.com/gHashTag/trinity-fpga/issues/49)
* Mid SUPER-CROWN: [tt-trinity-gf16](https://github.com/gHashTag/tt-trinity-gf16)
* PhD monograph anchor: `gHashTag/trios docs/phd/chapters/flos_70.tex`
* TT tile sizes: [tt-support-tools/tech/sky130A/tile_sizes.yaml](https://github.com/TinyTapeout/tt-support-tools/blob/main/tech/sky130A/tile_sizes.yaml)

---

`phi^2 + phi^-2 = 3 · gamma = phi^-3 · C = phi^-1 · G = pi^3 gamma^2 / phi · QUANTUM BRAIN 1:1 SILICON · 3-STRAND DNA · TRI NET · DOI 10.5281/zenodo.19227877 · NEVER STOP`

---

## 🟢 Bazaar Doctrine · Green AI Manifesto

This chip is part of the **TRI-NET** — an open ternary neuromorphic substrate
released under [Apache-2.0](LICENSE) for the decentralized hardware bazaar.

### Honest performance disclosure (R5-HONEST)

| Metric | Measured (SKY130 130nm) | Architecture target (22FDX 22nm projection) |
|---|---|---|
| TOPS/W | proof-of-concept node | 28-120 TOPS/W (peer-review pending) |
| Energy/op | educational node | competitive vs Hailo/Mythic at advanced node |

The SKY130A demonstrator validates **architecture**, not absolute silicon performance.
Production-grade tape-out requires migration to advanced node.

### Green AI alignment

- **Ternary {−1, 0, +1}** — ~10× energy/op vs FP16 at equivalent accuracy
  ([BitNet b1.58, Microsoft Research 2024, arXiv:2402.17764](https://arxiv.org/abs/2402.17764))
- **0 DSP / 0 `*`** — R-SI-1 RTL constraint eliminates multiplier switching energy
- **Edge inference** — no datacenter transit, no PUE overhead
- **Open-source RTL** — reproducible silicon eliminates duplicated tape-out waste

### The Bazaar, not the Cathedral

> *"Many heads are inevitably better than one."*
> — Eric S. Raymond, [The Cathedral and the Bazaar (1997)](http://www.catb.org/~esr/writings/cathedral-bazaar/)

This repository is open under Apache-2.0 with **no field-of-endeavor restriction**
([OSD §6](https://opensource.org/osd)). Fork it. Improve it. Build with it.
We do not gate-keep what you build. You comply with your local export control;
we comply with ours.

**φ² + φ⁻² = 3** · DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
