# RELEASE_MANIFEST_TRINET_V1 — γ-surface verification hardening bundle

> Manifest for the **intended** Zenodo deposition of the TRI-NET
> γ-surface verification hardening bundle (v1). This file documents
> what would be deposited, with content hashes pinned at the
> verification-hardening commit, intended metadata, creators inferable
> from the repo, and explicit anti-claims.
>
> **Anti-claim, top of file.**
>
> ⛔ **No DOI is minted by this commit, this manifest, or the sibling
> [`.zenodo.json`](../.zenodo.json).** A DOI exists only after a
> Zenodo deposition is **published** and Zenodo assigns one. Until
> that point, the only DOI that may be cited from this repo is the
> pre-existing TIP v1.0 / φ²+φ⁻²=3 anchor record
> [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877),
> which is **not** minted by this bundle.

Last reviewed: 2026-05-18.

## 1. Bundle identity (intended)

| Field | Value | Notes |
|-------|-------|-------|
| Title | `TRI-NET γ-surface — Verification hardening bundle v1` | Pin at deposit time. |
| Version | `v1` | First verification-hardening bundle. Bump on substantive matrix changes. |
| Upload type | `software` | Same upload type as the legacy TIP v1.0 record. |
| License | `Apache-2.0` | Matches `LICENSE`. |
| Access | `open` | No embargo, no restricted access. |
| Communities | (none) | Intentionally empty until a community is decided. |
| DOI | **not minted by this commit** | See top-of-file anti-claim. |

## 2. Creators (inferable from repo)

| Name | Affiliation | Source | ORCID |
|------|-------------|--------|-------|
| Vasilev, Dmitrii | t27.ai | `src/d2d_holo_mesh.v` SPDX header (`Author: Dmitrii Vasilev <admin@t27.ai>`); `tools/check_no_star.sh` (`Author: Vasilev Dmitrii <admin@t27.ai>`) | **NOT ASSERTED** by this PR — must be filled in by the depositor before Zenodo submission |

This list intentionally contains only authorship attribution that can
be traced to in-repo files. Any additional contributor must be added
by the depositor with their own verifiable record.

## 3. Files included (with content hashes at this commit)

The bundle would deposit the seven verification-hardening artefacts
introduced in PR #72, plus the README refresh and Zenodo metadata:

| Path | SHA-256 (verification-hardening commit) | Status tag |
|------|-----------------------------------------|------------|
| `docs/VERIFICATION_CLAIMS_MATRIX.md` | `7db8ef00097df797f3dc3d0e4a6de76b7afcc4dff8d5581e2d590a8bb94b681d` | SPEC |
| `docs/specs/TRIPLE_DECKER_FSM.md` | `c88471b21bcafc77a7b968e50068a422172233529adcefb51218ba827b3f7e02` | SPEC |
| `tests/vectors/nmse_gf16_bf16.golden.json` | `96a19b655dbb2263bc4966a81e3370079388141172402b26020fa20bc56f9636` | SPEC |
| `conformance/d2d/header_valid.json` | `65353a92a8a7e32ab9daf8fffbace534d51cd7e8baa60e321984b7c602d7c45d` | SIM (gated by `iverilog-canonical`) |
| `conformance/d2d/bad_crc.json` | `4a2fdd779fae54f3d1b39621ddf82f0b79f17dabc5ce32468bca8529dc21a09e` | SPEC |
| `conformance/d2d/unsupported_opcode.json` | `2c55367dbb28bd2522e1b0f8c4c91522eb7044f1e8451b33073d92a0e97a7d9e` | SPEC |
| `conformance/d2d/timeout_retry.json` | `a1ff939f4a75a9b603ff84f2ae16dc3c456121eda0c3a5893f509071d352190e` | SPEC |
| `conformance/d2d/multi_chip_ordering.json` | `775dcbb026ad4457116f2c24ad682bb1abd8df6eceb39bf36fb7893e58559aba` | SPEC |
| `scripts/check_trinet_specs.sh` | `b43e60b1c54f692b2d15c0717d25a14f66d5317bf16ba66bef574afd64fb1343` | RTL gate (CI) |
| `.zenodo.json` | recompute at deposit time | SPEC |
| `docs/ARCHITECTURE_QUICK_WINS.md` | recompute at deposit time | SPEC |
| `docs/RELEASE_MANIFEST_TRINET_V1.md` | this file — recompute at deposit time | SPEC |

Reproduce the hash list:

```bash
sha256sum \
  docs/VERIFICATION_CLAIMS_MATRIX.md \
  docs/specs/TRIPLE_DECKER_FSM.md \
  tests/vectors/nmse_gf16_bf16.golden.json \
  conformance/d2d/*.json \
  scripts/check_trinet_specs.sh
```

If any row above no longer matches the live `sha256sum` output, the
manifest is **out of date** and must be regenerated before any
Zenodo submission. The hash mismatch is a feature: it forces the
depositor to confirm the bundle contents have not silently drifted.

## 4. Related identifiers (intended)

| Identifier | Relation | Notes |
|-----------|----------|-------|
| `10.5281/zenodo.19227877` | `isDocumentedBy` | Pre-existing TIP v1.0 / φ²+φ⁻²=3 anchor. **Not minted by this PR.** |
| `https://github.com/gHashTag/tt-trinity-gamma` | `isSupplementTo` | Source repo. |
| `https://github.com/gHashTag/tt-trinity-phi` | `isPartOf` | Sibling chip φ-anchor. |
| `https://github.com/gHashTag/tt-trinity-euler` | `isPartOf` | Sibling chip e-engine. |
| `https://github.com/gHashTag/t27` | `references` | Spec toolchain / format registry. |
| arXiv id | `isDocumentedBy` | **TBD — not asserted.** Placeholder only. |

## 5. Keywords

`TRI-NET`, `TT-Trinity`, `gamma-surface`, `neuromorphic`, `GF16`,
`BitNet b1.58`, `ternary logic`, `K3 Kleene`, `open-PDK silicon`,
`SkyWater SKY130A`, `Tiny Tapeout`, `verification`, `conformance`.

## 6. Pre-deposit checklist (depositor MUST complete)

Before invoking the Zenodo API or pressing "Publish" in the UI:

- [ ] Recompute every SHA-256 in §3 against the actual commit being
      deposited.
- [ ] Fill in creator ORCID and any additional contributors (see §2).
- [ ] Replace `TBD-arxiv-id` in `.zenodo.json` with a real arXiv id,
      or remove the placeholder entry entirely.
- [ ] Confirm the legacy DOI `10.5281/zenodo.19227877` is the **only**
      pre-existing DOI cited and that the new deposition's DOI is left
      blank (Zenodo will mint it on publish).
- [ ] Decide whether to attach the bundle to an existing Zenodo
      community; leave `communities: []` if not.
- [ ] Confirm `LICENSE` (Apache-2.0) is bundled with the deposition.

Until every box is checked, the deposition is not authorised.

## 7. Anti-claims (R5 honesty)

- ⛔ Committing this file or `.zenodo.json` does **not** mint a DOI.
- ⛔ No silicon measurement is asserted by this bundle.
- ⛔ No funding source, program acceptance, or paper acceptance is
  claimed.
- ⛔ No DOI other than the pre-existing TIP v1.0 anchor
  `10.5281/zenodo.19227877` may be cited from this repo until a real
  Zenodo deposition is published.
- ⛔ Creator ORCIDs and arXiv IDs in `.zenodo.json` are placeholders;
  do not present them as verified attribution.

## See also

- [`.zenodo.json`](../.zenodo.json) — machine-readable intended metadata
- [`docs/VERIFICATION_CLAIMS_MATRIX.md`](VERIFICATION_CLAIMS_MATRIX.md) — falsifiable claims
- [`docs/ARCHITECTURE_QUICK_WINS.md`](ARCHITECTURE_QUICK_WINS.md) — competitor-grounded fast wins
- [`scripts/check_trinet_specs.sh`](../scripts/check_trinet_specs.sh) — CI gate
