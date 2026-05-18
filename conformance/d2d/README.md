# conformance/d2d — D2D conformance assets

> Pinned scenario JSONs for the γ-surface D2D path. Each file is a
> SPEC scenario, not a measurement. Together they cover the failure
> modes a conformance probe (in-tree cocotb harness or an external
> Phi-side checker) must exercise before claiming D2D coverage.

| File | Scenario | Claim IDs |
|------|----------|-----------|
| `header_valid.json` | Canonical reset anchor `0x47C0` | TN-D2D-01, TN-D2D-03 |
| `bad_crc.json` | CRC32 mismatch must not advance receipt state | TN-D2D-04 |
| `unsupported_opcode.json` | Opcode outside sacred bank → drop / no-op | TN-D2D-03, TN-D2D-06 |
| `timeout_retry.json` | RX timeout triggers exactly one retry with ordered audit entries | TN-D2D-07 |
| `multi_chip_ordering.json` | Per-direction FIFO ordering across the triad | TN-D2D-05 |

Each file references the witness RTL in `src/` and the testbench in
`sim/` or `test/` that would falsify the claim. None of these files
modify RTL semantics; they are descriptive conformance scenarios.

See [`docs/VERIFICATION_CLAIMS_MATRIX.md`](../../docs/VERIFICATION_CLAIMS_MATRIX.md)
for the full claims list and [`D2D_PROTOCOL.md`](../../D2D_PROTOCOL.md)
for the γ-side D2D index.
