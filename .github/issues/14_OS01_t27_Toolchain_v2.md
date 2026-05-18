---
title: "[OS-01] t27 Toolchain v2.0"
labels: "toolchain, t27, priority:P2, size:large"
assignees: "gHashTag"
---

## OS-01: t27 Toolchain v2.0

### 🎯 Objective

Upgrade the t27 specification-to-RTL toolchain with CLI, plugins, LSP, and verification integration.

### 📋 Features

### 1. CLI (Command Line Interface)

```bash
# Generate Verilog from .t27 spec
t27 generate --target=verilog --chip=gamma specs/numerical/gf16.t27

# Generate with options
t27 generate --target=verilog --output=src/ --no-asserts
t27 generate --target=coq --output=proofs/
t27 generate --target=c --output=csrc/
```

### 2. Plugins

- **CLARA gap generator** — `t27 plugin clara --gap=3`
- **ROM generator** — `t27 plugin rom --type=crown47 --size=47`
- **Quantizer generator** — `t27 plugin quant --type=nf4`

### 3. LSP (VS Code Extension)

- Syntax highlighting for .t27 files
- Auto-completion of t27 keywords
- Go-to-definition for types and constants
- Diagnostics for semantic errors

### 4. Verification Integration

```bash
# Run formal verification
t27 verify --sby src/gf16_dot4.v
t27 verify --coq proofs/gf16_dot4.v
t27 verify --r-si-1 src/  # Check for * operators
```

### 📁 New File Structure

```
t27/
├── cli/
│   └── t27_cli.py          # Main CLI entry point
├── plugins/
│   ├── clara_gen.py        # CLARA gap generator
│   ├── rom_gen.py          # ROM generator
│   └── quant_gen.py        # Quantizer generator
├── lsp/
│   ├── t27_language_server.py
│   └── syntax.json
├── parsers/
│   ├── t27_parser.py
│   └── type_checker.py
├── generators/
│   ├── verilog_gen.py
│   ├── coq_gen.py
│   └── c_gen.py
└── verify/
    ├── sby_wrapper.py
    └── coq_wrapper.py
```

### ✅ Acceptance Criteria

- [ ] CLI generates valid Verilog from .t27 specs
- [ ] CLARA gap plugin creates testable code
- [ ] ROM plugin generates Crown47 with 47 entries
- [ ] LSP provides syntax highlighting in VS Code
- [ ] Verification integrates with SBY and Coq
- [ ] PyPI package `pip install t27` works
- [ ] Documentation: `t27/README.md`

### 📊 Timeline

**6 weeks** (Phase 2, parallel with energy work)

### 🔗 Dependencies

- None — standalone toolchain project

### 📖 References

- [t27 spec repo](https://github.com/gHashTag/t27)
- [VS Code LSP docs](https://code.visualstudio.com/api/language-protocol/)
- [SymbiYosys](https://symbiyosys.readthedocs.io/)

### 🎯 Success Metric

t27 CLI successfully generates Verilog, Coq, and C code from .t27 specifications; LSP works in VS Code.

---

**Related**: #0 [EPIC] TRI-NET 2026 Scientific Improvement Plan