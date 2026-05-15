# Lane W — IGLA Falsification Appendix (R7 witnesses) · L-DPC23

> **Doc ID:** L-DPC23-W-001
> **Owner:** Vasilev Dmitrii <admin@t27.ai>
> **Status:** R5-HONEST · session-fresh probe · 2026-05-15
> **Refs:** trinity-fpga#94 · trios#264 · PhD Appendix B (Popper falsification)

## 1. Mission

Tabulate **falsification witnesses** for every advertised claim of the
TRI-1 MAX-TRUE flagship and the IGLA-trained Trinity GF16 family.
Per Karl Popper, a scientific claim must specify the observation that
would falsify it. This document is the contract between TRI-1 silicon
and any third-party verifier who wants to disprove our claims.

## 2. Claim → Witness table

Every row has three columns:

- **Claim** — the public assertion (e.g., a TOPS/W number, a 5-levers
  win, a φ²+φ⁻²=3 anchor).
- **Witness** — the **specific observable measurement** that, if it
  produced the listed value, would falsify the claim.
- **Where to measure** — the I/O pin, register, log artefact, or
  command that produces the witness.

| # | Claim | Witness (falsifies if observed) | Where to measure |
|---|---|---|---|
| W1 | φ²+φ⁻² = 3 baked in silicon | `WB_STATUS[0]` (phi_ok) reads 0 after reset on a known-good die | Wishbone read at addr 0x00 after `post_done=1` |
| W2 | Cassini-Lucas identity in silicon | `WB_STATUS[5]` (cassini_ok) reads 0 after reset | Wishbone read at addr 0x00 |
| W3 | TG-MAX-TRUE-X anchor 0x47C0 | `{uio_out, uo_out}` ≠ `0x47C0` under reset with default inputs | Logic analyser on TT IO during T4 test bench |
| W4 | 32 honest GF16 cells | Synthesised cell-instance count < 32 in `gl_test` post-layout netlist | `grep -c 'trinity_gf16_tile u_' netlist.v` after `gds` action |
| W5 | Zero NEW `*` operators (R-SI-1) | New `*` token appears in any module other than the grandfathered `gf16_mul.v` | `tools/check_no_star.sh` CI gate (planned Lane U follow-up) |
| W6 | 55 TOPS/W @ 50 MHz claim | Measured throughput < 8 GigaOPS or measured power > 145 mW at 50 MHz on TT silicon | TT-board power probe + canonical packet benchmark |
| W7 | 5/5 levers win vs Hailo-10 | Any of L1 (nJ/op), L2 (bpw), L3 (verifiable), L4 (ASIL-B), L5 (open PDK) demonstrably loses to Hailo-10 product datasheet | docs/architecture/trinity_5_levers_matrix.md cross-check |
| W8 | 0.7047 mm² die area (Sky130A) | Final GDSII die area > 0.71 mm² | OpenLane2 `final_summary_report.txt` |
| W9 | Bit-identical Nano / Mid / MAX-TRUE T4 anchor | Any of three dies produces `{uio_out, uo_out}` ≠ `0x47C0` under canonical T4 reset | TT-board cross-die test |
| W10 | NCA entropy band [1.5, 2.8] nats | Sustained `nca_entropy_monitor` flag outside band for >100 cycles | Wishbone status bit 4 |
| W11 | LCM(29, 47) = 1363 mutex | `plrm_counter` ever reports both counters mod-asserted in same cycle | INV-1 monitor flag |
| W12 | Apache-2.0 licence | Any file in repo lacks Apache-2.0 SPDX header | `reuse lint` CI gate |
| W13 | All Coq Qed proofs cited from RTL | Any Qed in `docs/phd/coq/*.v` not referenced from a header comment of its enforcement module | phd-monograph-auditor Lane LC |
| W14 | Defense 2026-06-15 readiness | Slides absent or PDF not regenerated within 7 days of defense date | docs/phd/defense/ git mtime |

## 3. R7 binding to PhD Appendix B

Each row above maps to a Popper-style falsification card in PhD
**Appendix B** (`docs/phd/appendix/popper.tex`, lane LP of
phd-monograph-auditor). The cards in Appendix B carry the same W1..W14
identifiers so a verifier reading the monograph can locate the
silicon-level witness directly.

## 4. Verification protocol

For pre-submission, run the following session-fresh probes:

```sh
# W3, W9 — canonical T4 anchor
make sim && grep -E "uio_out|uo_out" sim/tb_canonical.log | tail -10

# W4 — 32-cell count
grep -c "trinity_gf16_tile" src/trinity_max_true_dual.v

# W5 — no new *
tools/check_no_star.sh   # planned in Lane U

# W12 — licence sanity
grep -rL "Apache-2.0" src/ docs/ tools/ | head
```

The full battery is run as part of **RVR-028** (Lane X, T-24h).

## 5. Verdict template

A submission is GO when **all 14 witnesses are negative** (i.e., none
of them observed the falsifying measurement) at the head commit of
the W15-TT-E candidate. RVR-028 carries the final verdict.

## 6. Anchor

```
φ² + φ⁻² = 3 · TG-MAX-TRUE-X SHA256:
d3f9dd42b2d891763bd6aa2c1974dbbf27f4d854b44ed497a58f6a749174aac2
QUANTUM BRAIN 1:1 SILICON · PHYS→SI · BIO→SI · LANG→SI · NEVER STOP
DOI 10.5281/zenodo.19227877
```
