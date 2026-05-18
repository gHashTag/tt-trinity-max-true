# Troubleshooting Guide — TRI-NET

Common issues and solutions for the TT Trinity chip family.

## Table of Contents

1. [Build Issues](#build-issues)
2. [Simulation Issues](#simulation-issues)
3. [Synthesis Issues](#synthesis-issues)
4. [Hardware Issues](#hardware-issues)
5. [Test Failures](#test-failures)
6. [Power Issues](#power-issues)
7. [D2D Issues](#d2d-issues)

---

## Build Issues

### Error: "module not found"

**Symptom:**
```
Error: Module 'gf16_dot4' not found
```

**Cause:** Missing file or incorrect include path.

**Solution:**
```bash
# Check file exists
ls -la src/gf16_dot4.v

# Verify include path
grep -r "gf16_dot4" src/
```

**Prevention:** Use correct include paths:
```verilog
// Correct
gf16_dot4 u_dot (...);

// Wrong (may fail)
gf16_dot4 u_dot(.a(a0), ...);  // Needs instantiation
```

---

### Error: "port mismatch"

**Symptom:**
```
Error: Port mismatch in module instantiation
```

**Cause:** Port width or direction mismatch.

**Solution:**
1. Check module definition:
```verilog
module gf16_dot4 (
    input  wire [15:0] a0,
    // ...
);
```

2. Check instantiation:
```verilog
gf16_dot4 u_dot (
    .a0(a0),  // Must match
    // ...
);
```

---

### Error: "duplicate identifier"

**Symptom:**
```
Error: Duplicate identifier 'result'
```

**Cause:** Multiple variables with same name in same scope.

**Solution:**
```verilog
// Wrong
reg [15:0] result;
wire [15:0] result;  // Duplicate!

// Correct
reg [15:0] result_reg;
wire [15:0] result_wire;
```

---

## Simulation Issues

### Issue: No output / stuck at 0x0000

**Symptom:** Output remains 0x0000 after reset.

**Possible Causes:**
1. Reset stuck low
2. Clock not running
3. Enable not asserted

**Solutions:**

1. Check reset:
```python
dut.rst_n.value = 0
await Timer(100, units="ns")
dut.rst_n.value = 1  # Must go HIGH
```

2. Check clock:
```python
clock = Clock(dut.clk, 20, units="ns")  # 50 MHz
cocotb.fork(clock.start())
```

3. Check enable:
```python
dut.ena.value = 1  # Enable the chip
```

---

### Issue: Wrong canonical output

**Symptom:** Output not 0x47C0 in canonical mode.

**Possible Causes:**
1. Different chip variant
2. Pin reassignment
3. Module version mismatch

**Solution:**
```python
# Verify expected value
result = (dut.uio_out.value << 8) | dut.uo_out.value
print(f"Got: {result:#06X}, Expected: 0x47C0")

# If different, check top-level module
# gf16_dot4 values: 1.0, 2.0, 3.0, 4.0 = 0x47C0
```

---

### Issue: GTKWave won't open VCD

**Symptom:** GTKWave says file not found or corrupted.

**Solution:**
```bash
# Check VCD file exists
ls -la test/sim/tb_canonical_anchor.vcd

# Regenerate VCD
./sim.sh tb_canonical_anchor

# Check for VCD in current directory
ls -la *.vcd
```

---

### Issue: Test timeout

**Symptom:** Test hangs or times out.

**Possible Causes:**
1. Infinite loop in DUT
2. Waiting for condition that never occurs
3. Clock stopped

**Solutions:**

1. Add timeout to test:
```python
async with Timeout(100, units="us"):
    while not dut.done.value:
        await Timer(10, units="ns")
```

2. Check FSM stuck state:
```verilog
// Add debug output
always @(posedge clk) begin
    if ($time > 1_000_000) begin
        $display("TIMEOUT: state=%d", state);
        $finish;
    end
end
```

---

## Synthesis Issues

### Error: "R-SI-1 violation found"

**Symptom:** CI reports multiplication operator found.

**Cause:** Using `*` operator in new RTL.

**Solution:** Replace with shift-add:
```verilog
// Wrong (R-SI-1 violation)
result = a * b;

// Correct (shift-add)
wire [19:0] pp0 = b[0] ? a : 20'b0;
wire [19:0] pp1 = b[1] ? {a, 1'b0} : 20'b0;
// ... etc
result = pp0 + pp1 + ...;
```

---

### Error: "Verilog-2005 violation"

**Symptom:** CI reports indexed part-select in procedural block.

**Cause:** Using SystemVerilog features.

**Solution:** Replace with case statement:
```verilog
// Wrong (Verilog-2005 violation)
always @(posedge clk) begin
    result = data[idx+1:idx];
end

// Correct (case statement)
always @(posedge clk) begin
    case (idx)
        4'd0: result = data[4:1];
        4'd1: result = data[5:2];
        // ...
    endcase
end
```

---

### Error: "Area exceeded"

**Symptom:** Synthesis reports area > available tiles.

**Cause:** Too much logic for allocated tiles.

**Solutions:**
1. Remove unused modules
2. Optimize critical path
3. Use parameterization to disable features:
```verilog
module tt_um_trinity_nano #(
    parameter ENABLE_CLARA = 0  // Disable CLARA if not needed
) (
    // ...
);
```

---

## Hardware Issues

### Issue: Output pins stuck at 0

**Symptom:** All outputs read as 0 on hardware.

**Possible Causes:**
1. Power not applied
2. Clock not connected
3. Output enable not set

**Solutions:**

1. Verify power supply:
```
VDD = 3.3V
GND = 0V
```

2. Check clock with oscilloscope (50 MHz expected)

3. Verify output enable:
```verilog
assign uio_oe = 8'hFF;  // All outputs enabled
```

---

### Issue: High current draw

**Symptom:** Current > 150 mA (should be < 100 mW).

**Possible Causes:**
1. Clock glitching
2. Power gate not working
3. Short circuit

**Solutions:**

1. Check clock waveform (should be clean)
2. Verify AVS-96 operation:
```verilog
// Check if avs_enable is asserted
// Check therm_mon is not stuck at CRITICAL
```

3. Check for shorts in test setup

---

### Issue: D2D signals not updating

**Symptom:** D2D TX pins stuck at 0.

**Possible Causes:**
1. Not in load mode
2. LAYER-FROZEN gate blocking
3. No cortex activity

**Solutions:**

1. Enter load mode:
```
ui_in[0] = 1  // Load mode
```

2. Check layer_frozen:
```verilog
// layer_frozen should be 0 for normal operation
// w_tx will be 0 if layer_frozen = 1
```

3. Provide stimulus to cortex:
```
stim_bus = 32'hFFFFFFFF  // Max stimulus to all columns
```

---

## Test Failures

### Issue: POST timeout

**Symptom:** POST never completes.

**Possible Causes:**
1. Clock too slow/fast
2. Power instability
3. Counter stuck

**Solutions:**

1. Verify clock frequency (target: 50 MHz)

2. Check power stability

3. Debug counter:
```verilog
// Add debug output
always @(posedge clk) begin
    if (post_count > 100) begin
        $display("POST TIMEOUT: count=%d", post_count);
        $finish;
    end
end
```

---

### Issue: Lucas values incorrect

**Symptom:** Lucas ROM returns wrong values.

**Cause:** Incorrect address mapping.

**Solution:**
```verilog
// Verify address mapping
// idx 0 → L₂ = 3
// idx 1 → L₃ = 4
// ...

always @(*) begin
    case (idx)
        3'd0: value = 8'd3;   // L₂
        3'd1: value = 8'd4;   // L₃
        // ...
    endcase
end
```

---

### Issue: Quantization output out of range

**Symptom:** Quantizer returns invalid value.

**Cause:** Input out of range or scaling issue.

**Solution:**
```verilog
// Check input range
if (fp16_in > 16'd4000) begin
    int4_out = 4'd5;  // Clamp to max
end else if (fp16_in < -16'd4000) begin
    int4_out = 4'd0;  // Clamp to min
end
```

---

## Power Issues

### Issue: AVS-96 not reducing power

**Symptom:** Power remains high with AVS enabled.

**Possible Causes:**
1. avs_enable not asserted
2. Power requests too high
3. Thermal monitor stuck

**Solutions:**

1. Verify avs_enable:
```verilog
avs_enable = 1'b1;  // Enable AVS
```

2. Check power_req:
```verilog
// Lower power requests enable lower voltage
power_req = 96'h00005555;  // Every 4th island
```

3. Check therm_mon:
```verilog
// Should be < CRITICAL (58)
therm_mon = 6'd30;  // Normal temperature
```

---

### Issue: FBB causing overheating

**Symptom:** Temperature rising with FBB enabled.

**Cause:** FBB increases leakage current too much.

**Solution:**
```verilog
// Reduce FBB level based on temperature
if (temp_mon > 8'd100) begin
    fbb_level = 8'd80;  // Lower FBB
end
```

---

## D2D Issues

### Issue: SYNC never asserted

**Symptom:** w_tx never goes high.

**Possible Causes:**
1. Cortex never reaches 8 spikes
2. LAYER-FROZEN gate blocking
3. Spike count not propagating

**Solutions:**

1. Apply maximum stimulus:
```verilog
stim_bus = 32'hFFFFFFFF;  // All columns max stimulus
```

2. Check layer_frozen:
```verilog
layer_frozen = 1'b0;  // Allow SYNC
```

3. Verify spike_count propagation:
```verilog
// Check that spike_count reaches d2d_holo_mesh
d2d_holo_mesh u_d2d (
    .spike_count(cortex_spike_count),  // Direct connection
    // ...
);
```

---

### Issue: Friend/Foe handshake fails

**Symptom:** friend_detected never goes high.

**Possible Causes:**
1. Wrong anchor ID
2. Not in load mode
3. Timing issue

**Solutions:**

1. Check anchor IDs:
```
φ (phi): 0xCF
e (Euler): 0xE8
γ (gamma): 0x93
```

2. Enter load mode:
```
ui_in[0] = 1  // Load mode required
```

3. Add delay for handshake:
```python
await Timer(1000, units="ns")  # Wait for handshake
```

---

## Getting Help

If issues persist:

1. Check [CI workflows](https://github.com/gHashTag/tt-trinity-phi/actions)
2. Review [API documentation](./API.md)
3. Check [Hardware Bring-Up Guide](./HARDWARE_BRINGUP.md)
4. Run simulation to isolate problem
5. Check [Test Coverage Report](./TEST_COVERAGE.md)

## Additional Resources

- [Tiny Tapeout Troubleshooting](https://tinytapeout.com/guides/)
- [Cocotb Documentation](https://docs.cocotb.org/)
- [Icarus Verilog Manual](https://iverilog.fandomlogic.it/)
- [GTKWave Manual](https://gtkwave.sourceforge.net/manual/)

---

*Last updated: 2025-05-18*