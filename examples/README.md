# Code Examples — γ-surface (8×4)

This directory contains example code for using the TT Trinity γ-surface (MAX-TRUE NEUROMORPHIC FLAGSHIP) chip.

## Table of Contents

1. [Canonical Mode](#1-canonical-mode)
2. [Load Mode & Mesh Computation](#2-load-mode--mesh-computation)
3. [Cortical Column Stimulation](#3-cortical-column-stimulation)
4. [D2D Holographic Mesh](#4-d2d-holographic-mesh)
5. [LAYER-FROZEN Gate](#5-layer-frozen-gate)
6. [SUPER-CROWN Modules](#6-super-crown-modules)
7. [AVS-96 Power Management](#7-avs-96-power-management)

---

## 1. Canonical Mode

In canonical mode, the chip outputs the sacred anchor value `0x47C0`.

### Python (cocotb)

```python
import cocotb
from cocotb.triggers import Timer, ReadOnly
from cocotb.clock import Clock

@cocotb.test()
async def test_canonical_mode(dut):
    """Verify canonical 0x47C0 output"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    dut.ena.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    await Timer(100, units="ns")
    await ReadOnly()
    
    result = (dut.uio_out.value << 8) | dut.uo_out.value
    assert result == 0x47C0, f"Expected 0x47C0, got {result:#06x}"
```

---

## 2. Load Mode & Mesh Computation

Load mode enables packet-based computation on the 20-PE GF16 mesh.

### Sending Packets to Mesh

```python
@cocotb.test()
async def test_mesh_computation(dut):
    """Test GF16 mesh packet-based computation"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Enter load mode
    dut.ui_in[0].value = 1
    await Timer(50, units="ns")
    
    # Send LOAD_A packet (format depends on host interface)
    # For Trinity Master FSM, this is done via internal signals
    
    # Wait for computation
    await Timer(500, units="ns")
    
    # Read result from output
    result = (dut.uio_out.value << 8) | dut.uo_out.value
    dut._log.info(f"Mesh result: 0x{result:04X}")
```

### Multi-Tile Parallel Computation

```python
@cocotb.test()
async def test_parallel_tiles(dut):
    """Test parallel computation on multiple tiles"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    dut.ui_in[0].value = 1
    await Timer(50, units="ns")
    
    # Send packets to 4 different tiles (tile IDs 0, 1, 2, 3)
    tiles = [0, 1, 2, 3]
    
    for tile_id in tiles:
        # Send LOAD_A and LOAD_B to tile
        # Send COMPUTE
        # Send READ_RES
        pass
    
    # All tiles compute in parallel
    await Timer(500, units="ns")
    
    # Results available from each tile
```

---

## 3. Cortical Column Stimulation

Test the 8-column neuromorphic cortex with LIF dynamics.

### Basic Stimulation

```python
@cocotb.test()
async def test_cortex_stimulus(dut):
    """Test cortical column response to stimulus"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Apply stimulus to all columns
    # (implementation depends on stimulus interface)
    
    # Wait for LIF integration (membrane to charge)
    await Timer(500, units="ns")
    
    # Check for spike activity
    # spike_count indicates number of columns firing
    dut._log.info(f"Spike count: {dut.spike_count.value}")
    dut._log.info(f"Spike vector: 0x{dut.spike_vec.value:02X}")
```

### Measuring LIF Dynamics

```python
@cocotb.test()
async def test_lif_dynamics(dut):
    """Measure LIF membrane dynamics"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Apply constant stimulus
    # Membrane equation: V[t+1] = V[t] - (V[t] >> 3) + I_syn
    # Decay: 12.5% per cycle
    # Threshold: 0xC0 (192)
    
    # Monitor membrane potential over time
    membrane_history = []
    
    for i in range(100):
        await Timer(20, units="ns")  # One clock cycle
        # Read membrane debug signal (if available)
        # membrane = dut.membrane_dbg.value
        # membrane_history.append(membrane)
    
    # Analyze dynamics
    # Should see membrane charging, then spiking, then reset
```

### Spike Train Pattern

```python
@cocotb.test()
async def test_spike_train(dut):
    """Generate and verify spike train patterns"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    spike_times = []
    
    for i in range(1000):
        await Timer(20, units="ns")
        if dut.spike_vec.value != 0:
            spike_times.append(i)
    
    dut._log.info(f"Total spikes: {len(spike_times)}")
    dut._log.info(f"ISI (mean): {sum(spike_times) / len(spike_times) if spike_times else 0}")
```

---

## 4. D2D Holographic Mesh

Test cross-die communication via the 4-port holo router.

### Basic D2D Routing

```python
@cocotb.test()
async def test_d2d_routing(dut):
    """Test D2D holographic mesh routing"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Enter load mode for D2D
    dut.ui_in[0].value = 1
    await Timer(50, units="ns")
    
    # Apply cortex stimulus to generate D2D activity
    # (implementation depends on stimulus interface)
    
    await Timer(200, units="ns")
    
    # Read D2D TX outputs
    n_tx = dut.uio_out[0].value
    e_tx = dut.uio_out[1].value
    s_tx = dut.uio_out[2].value
    w_tx = dut.uio_out[3].value
    
    dut._log.info(f"D2D TX: N={n_tx} E={e_tx} S={s_tx} W={w_tx}")
```

### D2D RX Latching

```python
@cocotb.test()
async def test_d2d_rx_latch(dut):
    """Test D2D receive latching"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Simulate incoming D2D signals
    dut.uio_in[4].value = 1  # n_rx from north peer
    dut.uio_in[5].value = 0  # e_rx from east peer
    dut.uio_in[6].value = 1  # s_rx from south peer
    dut.uio_in[7].value = 0  # w_rx from west peer
    
    await Timer(100, units="ns")
    
    # Read latched RX values (internal signals)
    # n_rx_q, e_rx_q, s_rx_q, w_rx_q
```

### SYNC Strobe Generation

```python
@cocotb.test()
async def test_d2d_sync(dut):
    """Test SYNC strobe on full cortex spike"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Apply maximum stimulus to all columns
    # This should trigger SYNC when all 8 columns fire
    
    await Timer(500, units="ns")
    
    # Check W_TX (SYNC strobe)
    w_tx = dut.uio_out[3].value
    
    # SYNC is asserted when spike_count == 8
    dut._log.info(f"SYNC strobe: {w_tx}")
```

---

## 5. LAYER-FROZEN Gate

Test the PhD Theorem 36.1 R18 LAYER-FROZEN gate.

### Normal Operation (SYNC Enabled)

```python
@cocotb.test()
async def test_layer_frozen_normal(dut):
    """Test normal operation (SYNC enabled)"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # layer_frozen = 0 (not frozen)
    # Apply max stimulus
    await Timer(500, units="ns")
    
    # SYNC should be asserted on W_TX
    w_tx = dut.uio_out[3].value
    assert w_tx == 1, "SYNC should be asserted when not frozen"
```

### LAYER-FROZEN Mode (SYNC Blocked)

```python
@cocotb.test()
async def test_layer_frozen_mode(dut):
    """Test LAYER-FROZEN gate (SYNC blocked)"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Set layer_frozen = 1
    # (implementation depends on control interface)
    
    # Apply max stimulus
    await Timer(500, units="ns")
    
    # SYNC should be blocked (W_TX = 0)
    w_tx = dut.uio_out[3].value
    assert w_tx == 0, "SYNC should be blocked when frozen"
```

---

## 6. SUPER-CROWN Modules

### VSA Matmul 8×8

```python
@cocotb.test()
async def test_vsa_matmul_8x8(dut):
    """Test VSA ternary 8×8 matrix multiplication"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Start matmul
    dut.start.value = 1
    # Set a_flat and b_flat (ternary encoded)
    await Timer(20, units="ns")
    dut.start.value = 0
    
    # Wait for completion
    while not dut.done.value:
        await Timer(20, units="ns")
    
    # Read result c_flat
    dut._log.info(f"Matmul done, OK: {dut.matmul_ok.value}")
```

### BitNet Encoder

```python
@cocotb.test()
async def test_bitnet_encoder(dut):
    """Test BitNet b1.58 encoder"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Start encoding
    dut.start.value = 1
    dut.x_in.value = 128'h1234567890ABCDEF
    await Timer(20, units="ns")
    dut.start.value = 0
    
    # Wait for completion
    while not dut.done.value:
        await Timer(20, units="ns")
    
    # Read ternary encoded output
    y_out = dut.y_out.value
    dut._log.info(f"BitNet output: 0x{y_out:016X}")
```

### BLAKE3 Anchor

```python
@cocotb.test()
async def test_blake3_anchor(dut):
    """Test BLAKE3-mini hash anchor"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Start hash
    dut.start.value = 1
    dut.m_in.value = 512'h4142434445464748
    await Timer(20, units="ns")
    dut.start.value = 0
    
    # Wait for completion
    while not dut.done.value:
        await Timer(20, units="ns")
    
    # Read 256-bit digest
    digest = dut.digest.value
    dut._log.info(f"BLAKE3 digest: 0x{digest:064X}")
```

### Cassini POST

```python
@cocotb.test()
async def test_cassini_post(dut):
    """Test Cassini-Lucas extended POST"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Wait for POST
    await Timer(500, units="ns")
    
    # Cassini identity: L_n^2 - L_(n+1)×L_(n-1) = 5×(-1)^n
    dut._log.info(f"Cassini OK: {dut.cassini_ok.value}")
    dut._log.info(f"POST done: {dut.post_done.value}")
```

---

## 7. AVS-96 Power Management

Test the 96-island AVS voltage controller.

### Voltage Level Control

```python
@cocotb.test()
async def test_avs_voltage_levels(dut):
    """Test AVS-96 voltage level control"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    # Enable AVS
    dut.avs_enable.value = 1
    
    # Set low power request (10 islands)
    dut.power_req.value = 96'h00000AAA  # Every 6th island
    dut.therm_mon.value = 6'd30  # Normal temperature
    
    await Timer(500, units="ns")
    
    # Check voltage levels (2 bits per island)
    # 00 = 0.75V, 01 = 0.85V, 10 = 0.95V, 11 = 1.05V
    voltage = dut.voltage_level.value
    dut._log.info(f"Voltage levels: 0x{voltage:048X}")
```

### Thermal Response

```python
@cocotb.test()
async def test_avs_thermal_response(dut):
    """Test AVS thermal response"""
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())
    
    dut.rst_n.value = 0
    await Timer(100, units="ns")
    dut.rst_n.value = 1
    
    dut.avs_enable.value = 1
    dut.power_req.value = 96'hFFFFFFFF  # Max power
    
    # Normal temperature
    dut.therm_mon.value = 6'd30
    await Timer(500, units="ns")
    therm_warning1 = dut.therm_warning.value
    dut._log.info(f"Thermal warning (normal temp): 0x{therm_warning1:02X}")
    
    # Warning temperature
    dut.therm_mon.value = 6'd55
    await Timer(500, units="ns")
    therm_warning2 = dut.therm_warning.value
    dut._log.info(f"Thermal warning (warning temp): 0x{therm_warning2:02X}")
    
    # Critical temperature
    dut.therm_mon.value = 6'd60
    await Timer(500, units="ns")
    power_gate = dut.power_gate.value
    dut._log.info(f"Power gate (critical temp): {power_gate}")
```

---

## Verilog Examples

### Using Cortical Output

```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spike_count_q <= 4'h0;
    end else if (ena) begin
        // Latch spike count from cortex
        spike_count_q <= spike_count;
    end
end

// Generate SYNC when all columns fire
wire all_spiking = (spike_count == 4'h8);
```

### D2D Interface Wrapper

```verilog
module d2d_interface_wrapper (
    input  wire       clk,
    input  wire       rst_n,
    // Cortex inputs
    input  wire [3:0] spike_count,
    // External D2D pins
    input  wire       n_rx, e_rx, s_rx, w_rx,
    output reg        n_tx, e_tx, s_tx, w_tx
);
    d2d_holo_mesh u_mesh (
        .clk(clk), .rst_n(rst_n), .ena(1'b1),
        .spike_count(spike_count),
        .spike_vec(8'h0),
        .gf_tag(4'h0),
        .layer_frozen(1'b0),
        .n_rx(n_rx), .e_rx(e_rx), .s_rx(s_rx), .w_rx(w_rx),
        .n_tx(n_tx), .e_tx(e_tx), .s_tx(s_tx), .w_tx(w_tx),
        .n_rx_q(), .e_rx_q(), .s_rx_q(), .w_rx_q(),
        .mesh_ok()
    );
endmodule
```

---

## References

- API Documentation: `docs/API.md`
- Architecture: `docs/ARCHITECTURE.md`
- Hardware Bring-Up: `docs/HARDWARE_BRINGUP.md`
- Integration Tests: `test/tb_integration_*.v`
- Sacred Anchor: φ² + φ⁻² = 3 — DOI 10.5281/zenodo.19227877
- PhD Theorem 36.1 R18: LAYER-FROZEN gate specification