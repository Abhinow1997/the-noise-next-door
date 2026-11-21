# Balloon Pop Sprite

The sprite sheets for the party balloons he pops (Assignment 7).

| | |
|---|---|
| **Title** | Balloon Pop Sprite |
| **Author** | metalx1000 (Kris Occhipinti) |
| **Source** | https://opengameart.org/content/balloon-pop-sprite, posted Monday 1 Apr 2019 |
| **Licence** | CC-BY-SA 4.0, as the page lists it (https://creativecommons.org/licenses/by-sa/4.0/) |
| **Credit, as the author asks** | Balloon Sprite by Kris Occhipinti http://filmsbykris.com |
| **Checked** | 21 Nov 2026: the page read in a browser, and the five files downloaded by Claude Code at the author's request |

**What the licence asks of this repository.**
- Give the credit line above wherever the balloons are used: in this file, in SOURCES.md and in the film's credits.
- Keep the sheets under CC-BY-SA 4.0. The sheets are used as they are, unedited. Any fix (registration, colour) is done on the node, not on the image.
- If the images are ever edited, the edited images must be shared under CC-BY-SA 4.0 too.

## As downloaded, committed unchanged

The page lists these as `balloon_<colour>.png`. These are the names the files were served with.

| File | Bytes (page lists) | SHA-256 |
|---|---|---|
| `balloon_red_4.png` | 10,780 (10.8 Kb) | `5f4142580e6cfc88ea39754d81e3d843d6e5e086fd7384a98520edb8a924ec95` |
| `balloon_yellow.png` | 10,232 (10.2 Kb) | `92db0dea39ee48220714ba429949d723f7e531694dc6091e72038ef38f6d3b87` |
| `balloon_green_4.png` | 10,839 (10.8 Kb) | `421c8c11971f7358cb4e593398534e1604d2873774c559f4cccfe94e33a14dcf` |
| `balloon_purple_2.png` | 10,754 (10.8 Kb) | `52f9dea1c5743ee63bffd3f84a9662257210c9f55de332ff7647b5ac25b1d277` |
| `balloon_blue_4.png` | 10,483 (10.5 Kb) | `f803035a2f2fa8c1d849deb5d2f79a2548f427ffa35201fb6fd154fce97d3976` |

## The sheets
- Each is 48 × 64 px: cells of 16 × 32 px, 3 across and 2 down, so `hframes` 3 and `vframes` 2, with cells 0 to 5 numbered left to right, then down.
- **Cells 0–2, the float.** The balloon's body sits in the same 14 × 19 px box at (1, 1) in all three, so it doesn't drift. Only the string sways: straight, a little waved, more waved.
- **Cells 3–5, the pop.** It cracks, bursts, then scatters into shreds.
- The five colours are the same drawing recoloured: every cell has the same opaque pixel count and the same boxes in all five. These were measured on 21 Nov 2026.
- The page doesn't give a frame rate.
