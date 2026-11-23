# Contact sheets of the raccoon's frame strips

**Fixture captures** (Movie Maker runs of the previews, 1280 × 720), laid out by [tools/make_strip_sheets.gd](../../tools/make_strip_sheets.gd). Pixels are copied, not resampled. Each sheet's frames run left to right, then down, in the order captured. The strips themselves are in `captures/jump/r0/`, `captures/jump/r1/` and `captures/loops/r0/<clip>/`. What each frame should show is in CHANGE-BRIEF.md, and the readings and verdicts are in TUNING.md.

## The jump

**The sheets:** `jump-r0.png` (before tuning) and `jump-r1.png` (after r1, the push-off with the hind legs bunched).
- Both use the same box round the raccoon and his shadow, (382, 226), 364 × 244 px, 5 frames to a row.
- They come from `previews/jump_preview.tscn` at 30 fps, with F seen on frame 10, a held jump.
- Ticks are physics ticks (60 a second) since takeoff.

| Place | Frame | Ticks | What it is (CHANGE-BRIEF.md, "the jump's frame strip") |
|---|---|---|---|
| 1 | 10 | 0–1 | Takeoff: the push-off |
| 2, 3 | 13, 14 | 6–9 | Rising: stretched up, snout first |
| 4 | 16 | 12–13 | The peak: gathering |
| 5 | 17 | 14–15 | The top's boundary: falling from tick 15, gathered |
| 6 | 21 | 22–23 | Coming down: front paws reaching |
| 7 | 22 | 24–25 | Landing, tick 25: touching down |
| 8 | 27 | 34–35 | The landing's end: `jump_land` held at its last pose |
| 9 | 28 | 36–37 | Back in his stance, tick 37 |
| 10 | 40 | 60–61 | In his stance |

## The seven loops

**The sheets:** `loops-r0-<clip>.png`.
- Each is that loop's crops in one row.
- They come from `previews/raccoon_loops_preview.tscn` at 24 fps, the clips' own rate.
- Each frame is from the clip's second wrap. The last frame of each row is the seam: frame 0 of the next wrap.
- The numbers are clip frames.

| Sheet | Frames |
|---|---|
| `loops-r0-idle.png` | 0, 24, 29, 48, 60, 72, 95 → 0 |
| `loops-r0-walk.png` | 0, 1, 7, 13, 19, 23 → 0 |
| `loops-r0-run.png` | 0, 4, 7, 8, 12, 15 → 0 |
| `loops-r0-sneak.png` | 0, 6, 12, 18, 24, 30, 36, 42, 47 → 0 |
| `loops-r0-bored.png` | 0, 24, 36, 53, 77, 95 → 0 |
| `loops-r0-sleep.png` | 0, 48, 95 → 0 |
| `loops-r0-climb.png` | 0, 6, 12, 18, 23 → 0 |

The crops take in a neighbour's tail at their edges, and the bottom line of the label above each copy.
