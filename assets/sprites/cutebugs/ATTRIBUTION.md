# Ambient Pixel Art Insects

The sprite sheet behind Assignment 7's looping sprite clip, the moth.

| | |
|---|---|
| **Title** | Ambient Pixel Art Insects |
| **Author** | madameberry |
| **Source** | https://opengameart.org/content/ambient-pixel-art-insects, posted Monday 5 Sep 2016 |
| **Licence** | CC0 (public domain dedication), as the page lists it. No credit is required; it's given here and in the film anyway. |
| **Checked** | 21 Nov 2026: the page read in a browser, and the file downloaded by Claude Code at the author's request |
| **As downloaded** | `cutebugs_by_madameberry.zip`, 46,755 bytes (the page lists 46.8 Kb), SHA-256 `54352e8f1f363d17716328d09c2366b4f2f0b457f9160794110accfe02660811`. Committed unchanged. |
| **As used** | `bugs.png`, extracted from the zip unchanged: 32 × 24 px, SHA-256 `970f537fa7addf1a01d89a2e93b333818bc97d7eb2d419a249ef6fc2ccc5477a`. Nothing else in the zip is used. |

## The sheet
- Cells of 8 × 8 px, 4 across and 3 down: `hframes` 4, `vframes` 3, so 12 cells, numbered 0 to 11 left to right, then down.
- Six bugs, two frames each, side by side: firefly 0–1, gnat 2–3, moth 4–5, beetle 6–7, bee 8–9, dragonfly 10–11. Each was matched pixel by pixel against that bug's own PNG in the zip (21 Nov 2026).
- They match exactly, except for 11 pixels (7 in the moth's cell 5, 4 in the firefly's cell 0) that are fully transparent in both and differ only in their hidden colour, so they look the same.
- The author's own GIF of each bug (in the zip) plays its two frames at 80 ms each and loops forever.

The sheet isn't edited. Any fix for registration is a node offset, not a change to the image.
