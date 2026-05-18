# tests/vectors — golden vectors for TRI-NET verification

> Format-pinning vector sets that bind a protocol spec to a concrete
> set of seeds, distributions, baselines, and tolerances. Vectors here
> are **specifications**, not measurements; no row claims a returned
> silicon number.

| File | Claim IDs (`docs/VERIFICATION_CLAIMS_MATRIX.md`) | Protocol |
|------|-------------------------------------------------|----------|
| `nmse_gf16_bf16.golden.json` | TN-NF-01, TN-NF-02, TN-NF-03 | [`GF16_BFLOAT16_NMSE.md`](../../GF16_BFLOAT16_NMSE.md) |

When a candidate harness lands (`tools/nmse_gf16_bf16.py`), it MUST:

1. Load the matching vector file and honour every `samples_min`,
   `seeds`, `input_distribution`, and `tolerance_*` field.
2. Pin its output JSON to the same vector by name + SHA-256.
3. Emit one of the allowed `verdict_enum` values; `INVALID` if any
   invariant is violated.
4. Refuse to publish a `Δ_dB` summary unless `verdict != INVALID`.

See [`docs/VERIFICATION_CLAIMS_MATRIX.md`](../../docs/VERIFICATION_CLAIMS_MATRIX.md)
for the full claims list and CI gate behaviour.
