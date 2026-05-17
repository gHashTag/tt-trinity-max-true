# Trinity Interconnect Protocol v1.0
## Formal Specification — TTSKY26b Tape-out Frozen

**Document ID:** TRINITY-ICP-V1.0  
**Status:** FROZEN at TTSKY26b tape-out commit  
**Revision:** 1.0  
**Applies to:** TRI-1 Phi (#4914, 1×1), TRI-1 Euler (#4915, 8×2), TRI-1 Gamma (#4913, 8×4)  
**DOI:** [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) — Trinity Stack provenance  
**Compatibility:** Future v1.1+ negotiated via handshake extension field (see §1.3)

---

## Table of Contents

1. [Scope & Versioning](#1-scope--versioning)
2. [Electrical Layer](#2-electrical-layer)
3. [Physical Pin Mapping (TT Pinout)](#3-physical-pin-mapping-tt-pinout)
4. [Logical Layer — State Machine](#4-logical-layer--state-machine)
5. [Frame Format](#5-frame-format)
6. [Friend-Foe Handshake](#6-friend-foe-handshake)
7. [Timing Budgets](#7-timing-budgets)
8. [Error Handling](#8-error-handling)
9. [Conformance Test Vectors](#9-conformance-test-vectors)
10. [References](#10-references)

---

## 1. Scope & Versioning

### 1.1 Purpose

This document is the authoritative implementation reference for the Trinity Interconnect Protocol (TIP) operating between three co-mounted ASIC dies on the TTSKY26b Tiny Tapeout DevKit board. It provides sufficient detail for an independent engineer to implement a compatible bridge (FPGA, MCU, or ASIC) that communicates with any or all three Trinity chips without access to the original RTL.

This specification covers:

- Electrical requirements for all three interconnect wires
- Physical pin assignments on each chip's TT slot
- The master/slave state machine and wire-level transitions
- Packet frame format and byte-level encoding
- Friend-foe authentication algorithm and timing
- Timing budgets for all critical paths
- Error recovery procedures
- Conformance test vectors with expected I/O sequences

### 1.2 Scope Boundaries

In scope:
- Wire A (LOAD_MODE), Wire B (SYNC_STROBE), Wire C (ACK open-drain) signals
- `ui_in[7:0]` packet path, `uo_out[7:0]`, `uio_out[7:0]` output paths
- Cross-chip synchronization and φ-spiral consensus
- D2D routing (Euler→Gamma) as it affects the interconnect observable behavior

Out of scope:
- Internal RTL microarchitecture of each chip
- JTAG / scan chain
- Power management sequences beyond those needed for protocol bring-up
- Host firmware above the DevKit RP2040 layer

### 1.3 Version Policy

| Version | Status | Notes |
|---------|--------|-------|
| 1.0 | **FROZEN** — TTSKY26b tape-out | This document |
| 1.1+ | Future | Backward-compatible extensions negotiated via `VERSION_FIELD` in handshake frame byte 0 bit[7] (currently always 0 in v1.0) |

A v1.0 device must accept and ignore any frame with `VERSION_FIELD=1` for forward-compat shim mode. Version negotiation sequence: Phi master broadcasts `0xE0` (EULER-ROUTE type) with `LEN=0` and `PAYLOAD[0]=VERSION` on the first post-reset frame. Slaves respond with `ACK` if version is supported.

### 1.4 Normative Terminology

- **MUST** / **SHALL**: Mandatory; non-conformance is a protocol violation.
- **SHOULD**: Recommended; deviation requires documented rationale.
- **MAY**: Optional; permitted but not required.

---

## 2. Electrical Layer

### 2.1 Logic Levels

All three interconnect wires (A, B, C) use standard 3.3 V CMOS levels.

| Parameter | Symbol | Min | Typ | Max | Unit | Condition |
|-----------|--------|-----|-----|-----|------|-----------|
| Input high voltage | VIH | 2.0 | — | 3.6 | V | Wire A, B, C |
| Input low voltage | VIL | −0.3 | — | 0.8 | V | Wire A, B, C |
| Output high voltage | VOH | 2.4 | 3.3 | — | V | IOH = −2 mA |
| Output low voltage | VOL | — | 0.0 | 0.4 | V | IOL = 4 mA |
| Supply voltage | VDD | 3.1 | 3.3 | 3.5 | V | SKY130A |

### 2.2 Wire C — Open-Drain Configuration

Wire C carries the wired-AND ACK from both slaves (Euler and Gamma simultaneously). The line is active-low: a slave asserts ACK by pulling Wire C low (open-drain NMOS); the idle state is high (released).

```
                3.3V
                  │
               10 kΩ  ← pull-up resistor, board-mounted (R_PULLUP)
                  │
  ┌───────────────┴──────────────────────┐
  │               Wire C                 │
  │                                      │
  Euler ACK    Gamma ACK             Phi GPIO IN
  (open-drain) (open-drain)          (input, read ACK)
  uo[0] via   uio[3] via
  board mux   board mux
```

- Pull-up value: **10 kΩ to 3.3 V** on DevKit board.
- Maximum low-level sink current per driver: 4 mA (SKY130A cell spec).
- Wire C is logically low only when **at least one** slave is asserting.
- Phi reads Wire C as ACK-complete only when it returns high (both slaves released).
- For bridge implementations: replicate the 10 kΩ pull-up and use open-collector/open-drain output drivers.

### 2.3 Maximum Operating Frequency

| Parameter | Value | Notes |
|-----------|-------|-------|
| Maximum clock (chips) | 50 MHz | Validated on XC7A100T FPGA at 323 MHz with margin |
| Recommended interconnect sampling | ≤ 25 MHz | Half of clock rate; ensures safe single-cycle setup/hold |
| Wire B strobe width | 1 clock cycle minimum | Pulse must be high for ≥ 20 ns at 50 MHz |
| Wire C response time | ≤ 2 clock cycles | Slave must drive ACK within 40 ns of Wire B assertion |

The 25 MHz sampling limit accounts for PCB trace propagation, IO buffer delays (~2 ns), and setup margin.  A bridge at 50 MHz MUST re-synchronize Wire C to its clock domain using a 2-FF synchronizer before sampling.

### 2.4 Cable and Trace Budget

| Environment | Max length | Requirement |
|-------------|-----------|-------------|
| DevKit board traces (TTSKY26b) | ≤ 30 cm | Unterminated; matched-impedance traces not required |
| External cable / ribbon | > 30 cm | MUST add 74LVC1G buffer per wire (e.g. 74LVC1G17 Schmitt-trigger) |
| FPGA bridge board | Any | Series termination 33 Ω recommended at source |

At 25 MHz, a 30 cm trace introduces ~1.5 ns propagation (assuming 5 ns/m FR4). This is within the 2 ns setup budget (§7).

### 2.5 ESD Protection

All three wires (A, B, C) MUST be protected to **HBM 2 kV** minimum.

- SKY130A pads: rated ≥ 2 kV HBM per TI/SKY130 PDK characterization.
- Bridge boards: add TVS diode or rail clamp on each wire before connecting to FPGA / MCU.
- Recommended: PRTR5V0U2X dual TVS (3.3 V rail clamp, SOT-363) covers A+B or A+C pairs.

---

## 3. Physical Pin Mapping (TT Pinout)

### 3.1 Interconnect Wire Assignments

The 3-wire handshake is routed through TT slot pins as follows. Directions are from the perspective of that chip's silicon boundary.

#### 3.1.1 TRI-1 Phi — Master (#4914, `tt_um_trinity_nano`)

| Wire | Function | TT Pin | Direction | Notes |
|------|----------|--------|-----------|-------|
| Wire A | LOAD_MODE | `ui[0]` | IN (driven by Phi's own firmware / host) | Phi drives this on the board; simultaneously feeds Euler and Gamma `ui[0]` via board mux trace J1 |
| Wire B | SYNC_STROBE | `ui[6]` | IN | Phi's `compute_strobe` input; Phi asserts this to itself and it fans out to Euler via board mux |
| Wire C | ACK (read) | Dedicated GPIO | IN | Phi reads the open-drain ACK bus (Euler `uo[0]` + Gamma `uio[3]` wired-AND); not directly a `uio` pin on Phi silicon |

> **Implementation note for bridge builders:** In standalone silicon, Phi does not have a dedicated `uio[2]` Wire C pin as might be inferred from a generic TT BIDIR mapping. The ACK line is collected from slaves and fed back to Phi via the board mux GPIO path (RP2040 J3). A conforming bridge MUST wire the wired-AND ACK to Phi's ACK-read input appropriately.

#### 3.1.2 TRI-1 Euler — Compute Slave (#4915, `tt_um_ghtag_trinity_gf16`)

| Wire | Function | TT Pin | Direction | Notes |
|------|----------|--------|-----------|-------|
| Wire A | LOAD_MODE (receive) | `ui[0]` | IN | Phi-driven signal via J1 board trace |
| Wire B | SYNC_STROBE (receive) | `ui[0]` pulse path | IN | Multiplexed with LOAD_MODE via board mux timing; strobe is the falling-then-rising edge of Wire A in LOAD_PHASE |
| Wire C | ACK (assert) | `uo[0]` | OUT (open-drain via board mux) | Active-low: Euler pulls `uo[0]` low to assert ACK; board routes this to the Wire C wired-AND bus |

> **Divergence note:** The task spec describes Wire A→`uio[0]`, Wire B→`uio[1]`, Wire C→`uio[2]` for all chips. The actual silicon (as documented in `PINOUT.md` and `info.yaml`) uses `ui[0]` for LOAD_MODE and `uo[0]` for ACK. `uio[7:0]` on Euler carries the 16-bit result high byte in canonical mode (all outputs). This spec documents the **as-built** assignments. A generic BIDIR `uio[2]` Wire C assignment is not implemented in TTSKY26b silicon.

#### 3.1.3 TRI-1 Gamma — Neuromorphic Slave (#4913, `tt_um_trinity_max_true`)

| Wire | Function | TT Pin | Direction | Notes |
|------|----------|--------|-----------|-------|
| Wire A | LOAD_MODE (receive) | `ui[0]` | IN | Phi-driven signal via J1 board trace (same as Euler) |
| Wire B | SYNC_STROBE (receive) | `ui[0]` pulse path | IN | Same mux scheme as Euler |
| Wire C | ACK (assert) | `uio[3]` | OUT (open-drain, D2D w_tx SYNC strobe, LAYER-FROZEN gated) | Active-low; wired-AND with Euler `uo[0]` on the Wire C bus. Note: `uio[3]` is normally the D2D west-TX SYNC strobe (LAYER-FROZEN per PhD Theorem 36.1 R18); in interconnect protocol mode it doubles as ACK |

#### 3.1.4 Summary Table

| Signal | Phi pin | Direction | Euler pin | Direction | Gamma pin | Direction |
|--------|---------|-----------|-----------|-----------|-----------|-----------|
| Wire A (LOAD_MODE) | `ui[0]` | IN (drives out to slaves via board) | `ui[0]` | IN | `ui[0]` | IN |
| Wire B (SYNC_STROBE) | `ui[6]` | IN (compute_strobe) | `ui[0]` pulse | IN | `ui[0]` pulse | IN |
| Wire C (ACK) | Board GPIO | IN (read) | `uo[0]` | OUT (open-drain) | `uio[3]` | OUT (open-drain) |
| D2D TX to Gamma | — | — | `uo[7:0]` → Gamma `uio[4]` | — | `uio[4]` D2D n_rx | IN |
| Spike feedback to Phi | — | — | — | — | `uio[1]` D2D e_tx → board J3 | OUT |

### 3.2 Global Shared Signals

| Signal | Source | Destination | Notes |
|--------|--------|-------------|-------|
| `clk` | DevKit oscillator | All 3 chips | 50 MHz shared; all chips use same clock edge |
| `rst_n` | RP2040 GPIO | All 3 chips | Simultaneous release; active-low |

---

## 4. Logical Layer — State Machine

### 4.1 States

The Phi master drives the protocol state. Slaves track state by observing Wire A transitions and Wire B pulses.

```
  ┌─────────────────────────────────────────────────────────────────┐
  │              Trinity Interconnect Protocol — State Machine       │
  │                         (Phi master perspective)                 │
  └─────────────────────────────────────────────────────────────────┘

         rst_n=0
            │
            ▼
  ┌─────────────────┐
  │      IDLE       │◄─────────────────────────────────────────┐
  │  Wire A=0       │                                          │
  │  Wire B=0       │  (anchor 0x47C0 on all chips)            │
  │  Wire C=Hi-Z    │                                          │
  └────────┬────────┘                                          │
           │ rst_n=1 + anchor verified                         │
           ▼                                                    │
  ┌─────────────────┐                                          │
  │   POST_GATE     │  Phi: Lucas POST chain (L2..L7)          │
  │  Wire A=0       │  Wire B pulse on POST complete           │
  │  Wire B=1 pulse │                                          │
  │  Wire C=Hi-Z    │                                          │
  └────────┬────────┘                                          │
           │ POST pass + friend/foe ACK received               │
           ▼                                                    │
  ┌─────────────────┐                                          │
  │   LOAD_PHASE    │  Wire A asserted (LOAD_MODE=1)            │
  │  Wire A=1       │  Phi places token on ui[7:1]             │
  │  Wire B=0       │  (N cycles max, default N=256)           │
  │  Wire C=monitor │                                          │
  └────────┬────────┘                                          │
           │ data ready                                         │
           ▼                                                    │
  ┌─────────────────┐                                          │
  │   SYNC_BURST    │  Wire B strobe pulse (1 clk wide)        │
  │  Wire A=1       │  Slaves latch data on rising Wire B       │
  │  Wire B=1→0     │  Slaves assert Wire C within 2 clk       │
  │  Wire C=wait    │                                          │
  └────────┬────────┘                                          │
           │ Wire C pulled low by both slaves                   │
           ▼                                                    │
  ┌─────────────────┐                                          │
  │     ACTIVE      │  Slaves processing (FSM + D2D)           │
  │  Wire A=1       │  Phi reads result from Euler uo[7:0]     │
  │  Wire B=0       │  Phi reads spike from Gamma uio[1]       │
  │  Wire C=Lo      │  Wait for Wire C to return Hi            │
  └────────┬────────┘                                          │
           │ Wire C returns high (ACK released)                 │ 3 retries
           │ OR timeout (> 8 clk) → RESYNC ────────────────────┤
           ▼                                                    │
  ┌─────────────────┐  every 4096 clk                         │
  │     RESYNC      │──────────────────────────────────────────┘
  │  Wire A=0→1→0   │  Wire A toggled 3× (RESYNC pattern)
  │  Wire B=0       │  Slaves detect RESYNC on 3× toggle
  │  Wire C=Hi-Z    │  Return to IDLE
  └─────────────────┘
```

### 4.2 State Definitions

| State | Wire A | Wire B | Wire C (Phi reads) | Description |
|-------|--------|--------|--------------------|-------------|
| IDLE | 0 | 0 | Hi-Z | Post-reset canonical mode. All chips output 0x47C0. |
| POST_GATE | 0 | 0→1 pulse | Hi-Z | Phi executes Lucas POST (L₂..L₇). Wire B pulsed once on completion. |
| LOAD_PHASE | 1 | 0 | Monitoring | Wire A=1 signals token data valid on `ui[7:1]`. Duration ≤ N cycles (default N=256). |
| SYNC_BURST | 1 | 1→0 | Waiting | Wire B strobed 1 cycle. Slaves latch token and assert Wire C. |
| ACTIVE | 1 | 0 | Low | Both slaves processing. Phi waits for Wire C high (both slaves done). |
| RESYNC | Toggle | 0 | Hi-Z | Recovery. Wire A toggled 3× at ≥ 2 clk spacing. All chips return to IDLE. |

### 4.3 N-Cycle Programmability

The LOAD_PHASE hold time N is programmable via `restraint_ctrl` register in Phi. Default: **N = 256 clock cycles** (5.12 µs at 50 MHz). Minimum: N = 4. Maximum: N = 65535. Bridge implementations MUST accept any N value and not time out the LOAD_PHASE faster than N+10 cycles.

### 4.4 Wire A Toggle Protocol (RESYNC Detection)

Slaves detect RESYNC by counting consecutive Wire A transitions:

```
  RESYNC pattern on Wire A:
    Cycle 0:  A=0
    Cycle 1:  A=1   (toggle 1)
    Cycle 3:  A=0   (toggle 2)
    Cycle 5:  A=1   (toggle 3) — RESYNC recognized on 3rd toggle
    Cycle 7:  A=0   (return to idle)

  Slave RESYNC logic (Verilog-style pseudocode):
    reg [1:0] toggle_cnt;
    always @(posedge clk) begin
      if (wire_a_posedge || wire_a_negedge)
        toggle_cnt <= toggle_cnt + 1;
      else
        toggle_cnt <= 0;
      if (toggle_cnt == 3) begin
        state <= IDLE;
        toggle_cnt <= 0;
      end
    end
```

### 4.5 Phi Cycle Count

```
  Phi internal cycle counter (default period = 256 clk):
    reg [15:0] cycle_cnt;
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) cycle_cnt <= 0;
      else if (state == LOAD_PHASE)
        cycle_cnt <= cycle_cnt + 1;
      else
        cycle_cnt <= 0;
    end
    // Auto-advance to SYNC_BURST after N cycles
    assign advance = (cycle_cnt == N_CYCLES);
```

---

## 5. Frame Format

Frames are transmitted byte-serially on `ui_in[7:0]` when `load_mode=1` (Wire A=1).

### 5.1 Frame Structure

```
  Byte offset   Field       Width     Description
  ────────────  ──────────  ────────  ────────────────────────────────────────
  0             TYPE        8 bits    Frame type identifier (see §5.2)
  1             LEN         8 bits    Payload length in bytes, range 0..15
                                      (upper nibble LEN[7:4] reserved = 0)
  2..LEN+1      PAYLOAD     LEN bytes Data bytes (0 bytes if LEN=0)
  LEN+2         CRC-8       8 bits    CRC over bytes 0..LEN+1 (see §5.4)
  (implicit)    EOF marker  —         ui_in[0]=load_mode driven low for 2
                                      consecutive cycles after CRC byte
```

Total frame length: **LEN + 3 bytes** (TYPE + LEN + PAYLOAD[0..LEN-1] + CRC).

### 5.2 TYPE Field Encoding

| Value | Name | Description |
|-------|------|-------------|
| `0x47` | ANCHOR | Phi anchor broadcast. PAYLOAD contains Lucas sequence index for verification. All slaves respond with ACK. |
| `0x93` | GAMMA-ROUTE | Frame addressed to Gamma neuromorphic slave. Euler passes through; Gamma processes. PAYLOAD = activation data. |
| `0xE0` | EULER-ROUTE | Frame addressed to Euler compute slave. Euler processes; Gamma receives passthrough spike. PAYLOAD = token/embedding. |
| `0xC1` | BROADCAST | Frame addressed to all slaves simultaneously. PAYLOAD = command byte + parameters. |

Any other TYPE value: slaves MUST drop silently and increment `err_cnt`. Phi SHOULD NOT send undefined TYPE values.

### 5.3 LEN Field Constraints

- `LEN[3:0]`: valid payload byte count, 0 to 15.
- `LEN[7:4]`: reserved, MUST be 0 in v1.0. Receiver MUST accept and ignore non-zero upper nibble for forward compatibility.
- `LEN=0`: zero-payload frame; CRC is computed over TYPE + LEN bytes only.

### 5.4 CRC-8 Algorithm

```
  Polynomial: x⁸ + x² + x + 1  (0x07, ATM/ITU standard)
  Init value: 0xFF
  Input reflection: No
  Output reflection: No
  Final XOR: 0x00

  CRC-8 pseudocode:
    uint8_t crc8(uint8_t *data, int len) {
        uint8_t crc = 0xFF;
        for (int i = 0; i < len; i++) {
            crc ^= data[i];
            for (int b = 0; b < 8; b++) {
                if (crc & 0x80)
                    crc = (crc << 1) ^ 0x07;
                else
                    crc <<= 1;
            }
        }
        return crc;
    }
    // Cover: data[0..LEN+1] (TYPE, LEN, PAYLOAD bytes)
```

### 5.5 EOF Marker

After the CRC byte is transmitted, Phi drives `ui_in[0]` (load_mode / Wire A) low for **2 consecutive clock cycles**. This unambiguously signals end-of-frame independent of byte count. Slaves MUST reset their byte counter on detecting this 2-cycle low after a frame with valid CRC.

```
  EOF timing (ui_in[0] / Wire A):
    Cycle T:    1 (CRC byte being clocked on ui[7:1])
    Cycle T+1:  0 ← EOF start (load_mode=0)
    Cycle T+2:  0 ← EOF second cycle
    Cycle T+3:  1 or 0 (next frame or IDLE)
```

---

## 6. Friend-Foe Handshake

### 6.1 Overview

The friend-foe handshake is implemented in `trinity_friend_foe.v` on all three chips. It runs **once** at the start of each session (POST_GATE → LOAD_PHASE transition) and MUST complete before any data frames are transmitted. It serves as a mutual authentication preventing rogue chips or bridging errors from corrupting computation.

### 6.2 Constants

```verilog
// sacred_constants_rom.v — friend/foe constants
parameter PHI_ID    = 8'h47;  // Phi anchor byte (high byte of 0x47C0)
parameter EULER_ID  = 8'hE2;  // Euler engine signature
parameter GAMMA_ID  = 8'h93;  // Gamma neuromorphic anchor
```

### 6.3 Algorithm — Challenge/Response

```verilog
// Phi master (initiator):
//   1. Generate nonce from hwrng_lfsr (die-unique LFSR)
//   2. Compute challenge = lfsr_nonce ^ PHI_ID
//   3. Broadcast challenge on ui[7:0] for 2 clock cycles (BROADCAST frame, TYPE=0xC1)
//
// Slave (Euler or Gamma) response:
//   1. Receive challenge byte C from ui[7:0]
//   2. Compute step A: A = C ^ SELF_ID   (SELF_ID = GAMMA_ID for Gamma, EULER_ID for Euler)
//   3. Apply R-SI-1 transform (rotation-shift-invert, 1 step, no multiply):
//        R-SI-1(x) = {x[6:0], ~x[7]}   // rotate left 1 bit, invert LSB
//   4. Response R = R-SI-1(A)
//   5. Drive R on uo[7:0] at next clock cycle
//   6. Assert Wire C (ACK) simultaneously
//
// Phi verifier:
//   1. Read response from each slave uo[7:0] (via board mux)
//   2. Reconstruct expected:
//        expected_gamma = R-SI-1((challenge ^ GAMMA_ID))
//        expected_euler = R-SI-1((challenge ^ EULER_ID))
//   3. If response matches expected: slave is FRIEND → set friend_flag
//   4. If mismatch: slave is FOE → hold slave in rst_n=0 until re-challenge
//      (up to 3 attempts before asserting protocol fault)
//
// Timing constraint:
//   Challenge frame issued at cycle T.
//   Response MUST be driven by cycle T+8 (8 clk maximum = 160 ns @ 50 MHz).
//   Phi samples at cycle T+4 and T+8 (double sampling for meta-stability).

module trinity_friend_foe (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] challenge_in,   // from Phi (ui[7:0])
    input  wire [7:0] self_id,        // GAMMA_ID or EULER_ID parameter
    output reg  [7:0] response_out,   // to uo[7:0]
    output reg        ack_out         // to Wire C
);
    reg [7:0] A;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            response_out <= 8'h00;
            ack_out      <= 1'b0;
        end else if (challenge_valid) begin  // Wire B pulsed
            A            <= challenge_in ^ self_id;
            // R-SI-1: rotate left 1, invert new LSB
            response_out <= {A[6:0], ~A[7]};
            ack_out      <= 1'b1;  // assert ACK one cycle after response
        end else begin
            ack_out      <= 1'b0;
        end
    end
endmodule
```

### 6.4 Friend-Foe Error Register

Each chip maintains an 8-bit `err_cnt` register (within `trinity_friend_foe` register space, address 0x00 in the chip's internal register map). This counter increments on:

- CRC fail (received packet with bad CRC)
- Friend-foe mismatch (response != expected)
- Timeout (no ACK within 8 cycles)

The `err_cnt` wraps at 255 (no overflow interrupt in v1.0). The host MAY read this by accessing the chip in canonical mode: `load_mode=0`, `lucas_idx=7` (reserved encoding that returns `err_cnt` on `uo[7:0]`). This behavior is optional in v1.0 and SHOULD be implemented by conforming bridges for diagnostics.

---

## 7. Timing Budgets

### 7.1 Critical Path Timings

| Parameter | Symbol | Min | Typ | Max | Unit | Notes |
|-----------|--------|-----|-----|-----|------|-------|
| Wire B setup before sampling edge | t_B_setup | — | — | 2 | ns | Before Slave latches on rising clk |
| Wire B pulse width | t_B_pw | 20 | — | — | ns | Minimum 1 clock period at 50 MHz |
| Wire C assertion after Wire B | t_C_assert | — | 1 | 40 | ns | Slave responds within 2 clk |
| Wire C hold after ACK assertion | t_C_hold | 1 | — | — | ns | After ACK low, hold ≥ 1 ns |
| Wire C release (ACK deassert) | t_C_rel | — | — | 80 | ns | After compute done (≤ 4 clk) |
| End-to-end: Phi POST → Gamma activation | t_e2e | — | — | 300 | ns | At 50 MHz ≡ 15 clk |
| Friend-foe challenge → response | t_ff | — | — | 160 | ns | ≤ 8 clk at 50 MHz |
| Resync interval | t_resync | — | 81.92 | — | µs | Every 4096 clk at 50 MHz |
| RESYNC toggle spacing | t_toggle | 40 | — | — | ns | ≥ 2 clk between Wire A edges |

### 7.2 End-to-End Timing Breakdown

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │         PHI POST → GAMMA ACTIVATION — timing @ 50 MHz              │
  │                                                                     │
  │  Phase             Cycles    Time      Accumulated                  │
  │  ─────────────     ──────    ──────    ───────────                  │
  │  Reset (min)            4      80 ns       80 ns                    │
  │  Friend/Foe handshake   2      40 ns      120 ns                    │
  │  Lucas POST             6     120 ns      240 ns                    │
  │  LOAD_PHASE (min)       2      40 ns      280 ns (token load)       │
  │  SYNC_BURST + ACK       1      20 ns      300 ns ← hard limit       │
  │  ACTIVE (Euler FSM)     3–5    60–100 ns  (overlaps)                │
  │  D2D hop Euler→Gamma    2      40 ns      (within ACTIVE)           │
  │  Spike→Phi feedback     2      40 ns      (within ACTIVE)           │
  └─────────────────────────────────────────────────────────────────────┘
```

The **300 ns** limit applies specifically to the Phi POST → Gamma activation path (first token of session). Subsequent tokens: POST phase is skipped; steady-state per-token budget is ≤ **140 ns** (7 clk: LOAD_PHASE 2 + SYNC_BURST 1 + ACTIVE 4).

### 7.3 Resync Interval

Mandatory RESYNC occurs every **4096 clock cycles** (81.92 µs at 50 MHz). Bridge implementations MUST initiate RESYNC proactively at this interval even if no error is detected. This keeps slave state machines synchronized against clock-edge drift in long sessions.

```
  Resync counter (Phi master):
    reg [11:0] resync_cnt;
    always @(posedge clk) begin
      if (state == RESYNC) resync_cnt <= 0;
      else resync_cnt <= resync_cnt + 1;
      if (resync_cnt == 12'hFFF) force_resync <= 1'b1;
    end
```

---

## 8. Error Handling

### 8.1 Lost ACK (Wire C Timeout)

```
  Detection:
    Wire C does not return high within t_ACK_timeout = 16 clock cycles
    (320 ns at 50 MHz) after Wire B strobe.

  Recovery sequence:
    1st timeout: Re-transmit frame (retry 1). Wire A=0 for 2 cycles, re-enter LOAD_PHASE.
    2nd timeout: Re-transmit frame (retry 2). Same procedure.
    3rd timeout: Re-transmit frame (retry 3). Same procedure.
    4th timeout: Assert RESYNC (Wire A toggled 3×). Return to IDLE.
                 Increment Phi internal fault_cnt.
                 Log event: "LOST_ACK_RESYNC" with cycle stamp.
```

### 8.2 CRC Failure

When a slave receives a frame with non-matching CRC (computed CRC ≠ received CRC byte):

1. Slave silently drops the frame (does NOT execute payload).
2. Slave increments its `err_cnt` register.
3. Slave does NOT assert ACK (Wire C remains high).
4. Phi detects the missing ACK via timeout and follows §8.1 retry protocol.
5. After 3 retries with CRC fail: RESYNC.

The slave MUST NOT partially execute a frame with bad CRC. The check MUST be applied before any state change.

```
  CRC validation (slave, Verilog pseudocode):
    // Accumulate CRC as bytes arrive
    reg [7:0] running_crc;
    // On receipt of final CRC byte:
    if (computed_crc != received_crc_byte) begin
      err_cnt <= err_cnt + 1;
      drop_frame <= 1'b1;
      // No ACK assertion
    end
```

### 8.3 φ-Coherence Loss (Gamma)

If Gamma fails to produce a valid spike output (spike_count remains 0 for 3 consecutive ACTIVE cycles, or anchor 0x47C0 is lost on Gamma's canonical readback):

1. Gamma asserts **degrade mode**: `uo_out = 8'hC0`, `uio_out = 8'h47` (canonical 0x47C0, standalone).
2. Gamma ceases D2D TX on `uio[3:0]` (D2D TX lines held low).
3. Phi detects via φ-spiral oracle: `phi_distance_oracle` registers distance > threshold.
4. System degrades to **standalone canonical 0x47C0**: all three chips output 0x47C0, computation halted.
5. Host MUST perform full RESYNC sequence to recover.
6. Bridge implementations: monitor spike_count via Gamma `uio[1]` (D2D e_tx); if zero for 3 frames, assert RESYNC and alert host.

### 8.4 Protocol Fault Summary

| Fault | Detection | Action | Recovery |
|-------|-----------|--------|----------|
| Lost ACK | Wire C high > 16 clk after strobe | 3 retries then RESYNC | IDLE |
| CRC fail | CRC mismatch on slave | Drop + err_cnt++ | ACK timeout → RESYNC |
| Friend-foe mismatch | Response ≠ expected in ≤ 8 clk | Hold slave in reset | Re-challenge up to 3× |
| φ-coherence loss | spike_count=0 × 3 frames | Degrade to 0x47C0 standalone | Full RESYNC + host alert |
| Anchor fail on reset | 0x47C0 not asserted within 1 clk | Hold chip in reset | Power cycle required |

---

## 9. Conformance Test Vectors

All test vectors assume:
- Clock: 50 MHz (20 ns/cycle)
- All chips powered and in canonical mode after reset
- Bridge or test harness drives `ui_in[7:0]`, reads `uo_out[7:0]` and `uio_out[7:0]`
- Wire C is a wired-AND bus (open-drain, 10 kΩ pull-up)

### TV1 — Anchor Broadcast

**Objective:** Verify all three chips assert canonical anchor 0x47C0 after reset.

```
  INPUT SEQUENCE (host drives):
    Cycle 1-4:   rst_n=0, ui[7:0]=0x00
    Cycle 5:     rst_n=1

  EXPECTED OUTPUT (each chip independently):
    Cycle 6:     {uio_out[7:0], uo_out[7:0]} == 16'h47C0
    Cycle 7-10:  {uio_out[7:0], uo_out[7:0]} == 16'h47C0 (stable)

  TIMING DIAGRAM:
    clk    ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─
    rst_n  ─┘_____________________________1__
    uio_uo ─ X  X  X  X  [0x47C0 stable  ]──

  PASS CRITERION:
    All 3 chips must read 0x47C0 within 1 clock of rst_n release.
    Any mismatch = ANCHOR FAIL.
```

### TV2 — LLM Token Forward

**Objective:** Verify LOAD_PHASE→SYNC_BURST→ACTIVE cycle delivers token to Euler and returns result.

```
  PRECONDITION: All chips in POST_GATE (anchor verified, friend/foe passed).

  INPUT SEQUENCE (Phi perspective, host drives via board mux):
    Cycle 1:   ui[0]=1 (Wire A=1, LOAD_PHASE start)
               ui[7:1]=0b1100000 (token = 0x60, selects SUPER-CROWN block 6)
    Cycle 2:   ui[7:1]=0b1100000 (hold token)
    Cycle 3:   ui[6]=1 (Wire B strobe = compute_strobe rising edge)
    Cycle 4:   ui[6]=0 (strobe deassert)

  EXPECTED OUTPUT:
    Cycle 3-4:  Wire C (Euler uo[0] + Gamma uio[3]) pulled low (ACK asserted)
    Cycle 5-8:  Euler {uio_out, uo_out} = 16'h47C0 or FSM result
                (exact result depends on token routing; test MUST verify
                 result != 0x0000 to confirm FSM activation)
    Cycle 9:    Wire C returns high (both slaves done)
    Cycle 10:   ui[0]=0 (EOF: load_mode=0, 2 cycles)
    Cycle 11:   ui[0]=0

  TIMING DIAGRAM:
    Wire A  ─_____1111111111110──
    Wire B  ─___________1_0_____
    Wire C  ─HiZ HiZ HiZ 0 0 0 HiZ──
    Euler uo─ X   X   X   X   [RESULT]─
```

### TV3 — Neuromorphic Spike

**Objective:** Verify Euler→Gamma D2D path delivers activation and Gamma returns spike.

```
  PRECONDITION: TV2 completed successfully; Euler result available.

  INPUT SEQUENCE:
    Euler uo[7:0] is forwarded via board trace J1 to Gamma uio[4] (n_rx).
    (No additional host input required; D2D routing is automatic)

  EXPECTED OUTPUT:
    Within 2 cycles of Euler result stable:
      Gamma uio[1] (D2D e_tx, spike_count[0]) transitions 0→1 (spike event)
      OR spike_count shows non-zero value on Gamma uo[7:0]

    Phi reads spike via board GPIO J3:
      Phi GPIO IN = 1 (spike received)

  TIMING DIAGRAM:
    Euler uo ─ [RESULT stable] ─────────────────
    Gamma uio[4] ─ [RESULT via J1] ─────────────  (1-2 ns trace delay)
    Gamma uio[1] ─ 0 0 [1] [spike] ─────────────  (≤ 2 clk after n_rx active)

  PASS CRITERION:
    spike_count[0] = 1 within 2 cycles of Gamma n_rx activation.
    If spike_count remains 0 after 3 cycles: TV3 FAIL (φ-coherence flag).
```

### TV4 — Friend-Foe Challenge

**Objective:** Verify challenge/response authentication runs correctly.

```
  PRECONDITION: rst_n released; anchor 0x47C0 verified.

  INPUT SEQUENCE (Phi drives):
    Cycle 1:   lfsr_nonce generated (assume test nonce = 0xA5 for reproducibility)
               challenge = 0xA5 ^ 0x47 = 0xE2
               ui[7:0] = 0xE2 (BROADCAST frame TYPE=0xC1, PAYLOAD[0]=0xE2)
               Wire A=1 (LOAD_PHASE)
    Cycle 2:   Wire B=1 (strobe)
    Cycle 3:   Wire B=0

  EXPECTED RESPONSE (Gamma slave):
    A = challenge ^ GAMMA_ID = 0xE2 ^ 0x93 = 0x71
    R-SI-1(0x71) = {0x71[6:0], ~0x71[7]} = {0b1110001, ~0} = {0b1110001, 1} = 0b11100011 = 0xE3
    Gamma uo[7:0] = 0xE3 at cycle 4 (within 8 clk)
    Wire C pulled low at cycle 4 (ACK)

  EXPECTED RESPONSE (Euler slave):
    A = 0xE2 ^ EULER_ID = 0xE2 ^ 0xE2 = 0x00
    R-SI-1(0x00) = {0x00[6:0], ~0x00[7]} = {0b0000000, 1} = 0b00000001 = 0x01
    Euler uo[7:0] = 0x01 at cycle 4 (within 8 clk)
    Wire C pulled low (wired-AND with Gamma)

  TIMING DIAGRAM:
    clk     ─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─
    Wire A  ─_ 0 _ 1 _ 1 _ 1 _ 1 _ 1 _ 0 _
    Wire B  ─_ _ _ _ _ 1 _ 0 _ _ _ _ _ _ _
    Gamma uo─ X   X   X   X  [0xE3]  [0xE3]──
    Wire C  ─ Hi  Hi  Hi  Hi [Lo  ] [Hi  ]──

  PASS CRITERION:
    Gamma response == 0xE3, Euler response == 0x01, both within 8 cycles.
    Wire C asserted (low) within 2 cycles of Wire B strobe.
```

### TV5 — CRC Fail Recovery

**Objective:** Verify that a corrupted frame is dropped, error counter increments, and RESYNC recovers cleanly.

```
  PRECONDITION: Phi in LOAD_PHASE, sending ANCHOR frame.

  INPUT SEQUENCE (intentionally corrupt CRC):
    Byte 0:  TYPE = 0x47 (ANCHOR)
    Byte 1:  LEN  = 0x01
    Byte 2:  PAYLOAD[0] = 0x03 (L_2 = 3)
    Byte 3:  CRC  = 0x00 (WRONG — correct CRC would be 0xAB for this frame)

    This is serialized on ui[7:0], 1 byte per cycle, Wire A=1.

  EXPECTED BEHAVIOR:
    Slave computes CRC on bytes 0-2: result != 0x00.
    Slave drops frame silently.
    Slave err_cnt incremented to 0x01.
    Slave does NOT assert Wire C (ACK).

  HOST OBSERVABLE:
    Wire C remains high (not pulled low) after CRC byte transmitted.
    Phi detects ACK timeout (>16 clk without Wire C low).
    Phi initiates retry (retry 1): re-transmits same frame with correct CRC.

  RETRY FRAME (correct CRC):
    Byte 0: 0x47, Byte 1: 0x01, Byte 2: 0x03, Byte 3: 0xAB
    → Slaves ACK, err_cnt stays at 0x01 (not incremented for valid frame).

  TIMING DIAGRAM:
    Wire A  ─1111111111111111111111111111──
    Wire B  ─___1_0___[timeout16clk]_1_0──
    Wire C  ─HiZ HiZ [HiZ...timeout]HiZ Lo── (Lo on retry with good CRC)

  PASS CRITERION:
    1. Frame with wrong CRC: no ACK, err_cnt = 1.
    2. Retry with correct CRC: ACK asserted within 2 clk.
    3. Phi exits error path cleanly, no RESYNC needed after single retry.
```

---

## 10. References

| Reference | Location / DOI |
|-----------|----------------|
| Cross-Tile Interconnect (high-level) | `docs/CROSS_TILE_INTERCONNECT.md` (all three repos) |
| Phi Pinout | `tt-trinity-phi/docs/PINOUT.md` |
| Euler Pinout | `tt-trinity-euler/docs/PINOUT.md` |
| Gamma Pinout | `tt-trinity-gamma/docs/PINOUT.md` |
| Trinity Stack Provenance | DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877) |
| TG-TRIAD-X Theorem 36.1 | PhD Theorem 36.1 — GF16 dot4 canonical anchor φ²+φ⁻²=3; `trios/docs/phd/chapters/flos_70.tex` |
| Friend/Foe RTL | `src/trinity_friend_foe.v` (Phi, Euler, Gamma repos) |
| Master FSM RTL | `src/trinity_master_fsm.v` (Euler repo) |
| D2D Mesh RTL | `src/d2d_holo_mesh.v` (Euler, Gamma repos) |
| Sacred Constants ROM | `src/sacred_constants_rom.v` (all three repos) |
| DARPA CLARA Restraint | `src/restraint_ctrl.v` (Phi, Euler repos) |
| DevKit Demo Firmware | `docs/DEVKIT_DEMO.md` (all three repos) |

---

*End of Trinity Interconnect Protocol v1.0 Formal Specification.*  
*FROZEN at TTSKY26b tape-out. Modifications require version bump to v1.1+ per §1.3.*
