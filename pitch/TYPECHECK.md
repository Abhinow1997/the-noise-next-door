# TYPECHECK.md — GATE T

Reel: `the-noise-next-door-pitch`  |  Checked: 2026-11-24T18:53  |  Overall: PASS  |  Beats checked: 12  |  FAILs: 0

Spec: `skills/make/kerning/reference/type-spec.md` §8.  Floor: 1.9% frame-height.  Contrast: 4.5:1 WCAG.  Kern threshold: 3.5× expected advance.  Wordy budget: 2 elements.

| beat | lane | polarity | worst finding | status | fix |
|------|------|----------|---------------|--------|-----|
| B00 | ? | dark | min-size §8.1: min text-run height 20px >= floor 20px (individual-char fallback at 1×) | PASS | — |
| B01 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B01E | ? | dark | min-size §8.1: min text-run height 20px >= floor 20px (individual-char fallback at 1×) | PASS | — |
| B02 | ? | dark | min-size §8.1: min text-run height 20px >= floor 20px (individual-char fallback at 1×) | PASS | — |
| B03 | ? | dark | min-size §8.1: min text-run height 20px >= floor 20px (individual-char fallback at 1×) | PASS | — |
| B04 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B05 | ? | dark | min-size §8.1: min text-run height 20px >= floor 20px (individual-char fallback at 1×) | PASS | — |
| B06 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B07 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B08 | ? | light | no-wordy-card §8.5: no prose payload found | PASS | — |
| B09 | ? | dark | min-size §8.1: min text-run height 20px >= floor 20px (individual-char fallback at 1×) | PASS | — |
| B10 | ? | — | no video | SKIP | — |

---

## Failures requiring action before cut

*None — GATE T PASS.*
---

## Check summary

| Check | Beats checked | FAILs |
|-------|---------------|-------|
| no-wordy-card §8.5 | 5 | 0 |
| min-size §8.1 | 11 | 0 |
| overflow §8.2 | 11 | 0 |
| contrast §8.3 | 11 | 0 |
| contrast-local §8.3b | 11 | 0 |
| bbox-overlap §8.6b | 11 | 0 |
| card-clip §8.13 | 11 | 0 |
| kerning §8.4 | 0 | 0 |
| redundancy §8.10 (advisory) | 0 | 0 (advisory — no exit effect) |

---

*GATE T: any FAIL blocks `./art run` and `./art final`. Fix the flagged beats and re-run `scripts/type_check.py` until green.*
