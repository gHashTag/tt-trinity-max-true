---
title: "[OS-03] Python SDK"
labels: "tooling, Python, SDK, priority:P2, size:medium"
assignees: "gHashTag"
---

## OS-03: Python SDK

### 🎯 Objective

Create a Python SDK for TRI-NET simulation and testing with `pip install trinity`.

### 📋 Features

### 1. Installation

```bash
pip install trinity
```

### 2. Core API

```python
from trinity import TrinitySimulator, NeuralColumn, CLARAGap

# Instantiate simulator
sim = TrinitySimulator(chip='gamma', config='default')

# Simulate cortical column
col = NeuralColumn(sim, column_id=0)
col.set_stimulus(0xFF)  # Max stimulus
result = col.step(n_cycles=10)

# Test CLARA gap
gap = CLARAGap(sim, gap_id=3)  # Datalog engine
gap.assert_reasoning(facts=[1,2,3], expected=True)
```

### 3. D2D Mesh Simulation

```python
from trinity.mesh import D2DMesh, MeshConfig

# Create 4-die mesh (phi, e, e, γ)
mesh = D2DMesh(config=MeshConfig.FOUR_DIE)
mesh.set_position(phi, 0, 0)
mesh.set_position(euler_n, 0, 1)
mesh.set_position(euler_s, 1, 0)
mesh.set_position(gamma, 1, 1)

# Test SYNC protocol
gamma.send_sync(direction='west')
euler_s.receive_sync(direction='north')
assert euler_s.sync_received == True
```

### 4. Jupyter Notebook Tutorials

- `notebooks/01_canonical_anchor.ipynb`
- `notebooks/02_clara_gaps.ipynb`
- `notebooks/03_d2d_mesh.ipynb`
- `notebooks/04_cortical_dynamics.ipynb`
- `notebooks/05_energy_efficiency.ipynb`

### 5. CLARA Gap Testing Harness

```python
from trinity.test import CLARATestSuite

suite = CLARATestSuite(sim)
suite.run_gap(gap_id=1, test_vectors=adversarial_patterns)
suite.run_gap(gap_id=3, test_vectors=datalog_queries)
suite.assert_all_pass()
```

### 📁 New File Structure

```
trinity-python-sdk/
├── trinity/
│   ├── __init__.py
│   ├── core.py              # Core simulator
│   ├── neural.py            # Neural column/cortex
│   ├── mesh.py              # D2D mesh
│   ├── clara.py             # CLARA gaps
│   ├── quant.py             # Quantization
│   └── energy.py            # Power estimation
├── notebooks/
│   ├── 01_canonical_anchor.ipynb
│   ├── 02_clara_gaps.ipynb
│   ├── 03_d2d_mesh.ipynb
│   ├── 04_cortical_dynamics.ipynb
│   └── 05_energy_efficiency.ipynb
├── tests/
│   └── test_*.py
├── setup.py
├── requirements.txt
└── README.md
```

### ✅ Acceptance Criteria

- [ ] `pip install trinity` works
- [ ] Core API provides all simulator functions
- [ ] D2D mesh simulation matches RTL behavior
- [ ] CLARA gap testing harness works
- [ ] All 5 Jupyter notebooks run successfully
- [ ] Test coverage >80%
- [ ] Documentation: PyPI + README

### 📊 Timeline

**4 weeks** (Phase 1, parallel with CL work)

### 🔗 Dependencies

- None — standalone Python package

### 📖 References

- [Python package structure](https://packaging.python.org/)
- [Jupyter notebooks](https://jupyter.org/)

### 🎯 Success Metric

Python SDK successfully published to PyPI with 100+ downloads/month after launch.

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan