# run-03: notes (the input log for a human-input take)

- **The recording:** `run-03.mp4`, SHA-256 `8f0b700c1aaae41a5c060a858c246fba4f95fa828932059d71b8df2b47521660`.
  - It's Snipping Tool's `Screen Recording 2026-11-24 172900.mp4`, unchanged: 115.93 s, 1294 × 778, 30 fps.
  - The game is at 1280 × 720 from (7, 48), under the window's title bar. From 115 s the recording shows the desktop, after the game was closed.
- **What was played:** the game at `263ac50`, by the author, with keyboard and mouse at real speed, on 24 Nov 2026.
  - Every game file in that commit was last changed by 16:41, before the take (17:29).
  - It's from the developer menu's cake point (`-- --dev-start=cake`), with five tasks done. So its clips are labelled STAGED START.
  - It has the 10 s cutscene after the beanie's taken. The brief's revision that takes the cutscene out came after this take (17:34–17:36), and isn't in `263ac50`.
- **How these notes were made:** Claude Code wrote them from frames taken every second, and every half or quarter second from 7 to 39.25 s and from 96 to 115.5 s. So they give what's seen, not each key.

| Time (s) | What's seen | What was pressed, by what follows |
|---|---|---|
| 0–5 | From the bush by the fire, past the green tent | Move keys |
| 6–7 | The camper at his cake on the folding table, the other three round it, leaning in; "Tie his laces" | — |
| 7.5–11 | He sneaks up to the camper's heels | Ctrl and move keys |
| 11.5–13.5 | The ring at the camper's heels fills | E held |
| 14 | "Tie his laces" crossed off | — |
| 15–17 | The camper steps, windmills and falls on his back, the cake on his face, his beanie off | — |
| 17.5 | "Swipe his red beanie" | — |
| 18.5–21 | He circles round to the beanie | Move keys |
| 22–22.5 | Spotted (red) as he takes the beanie; "Swipe his red beanie" crossed off | E |
| 22.5–32 | The cutscene, behind black bars: the camper gets up, the men give chase, he runs off on his own | — (the keys are held) |
| 32.25–33 | "RUN!", the bars gone, "Get away with it"; the men right behind, the moth just ahead of him | Move keys |
| 34–34.25 | A man catches him: he drops the beanie and leaps away | — |
| 35–96 | On through the forest, the river beside the path, the men after him; seen through the trees as he passes behind them | Move keys |
| 96–98 | Out of a bush and over the river's bridge | Move keys |
| 98.5–101.5 | Past a cabin, two men after him | Move keys |
| 102–111 | On through the trees, past the river | Move keys |
| 113–114.5 | A man catches him in the trees | — |
| 115 | The game is closed; the desktop | — |

**What it doesn't show:** the camper fetching the cake (it's on the table by 6 s), or the end: he was caught short of the forest's north-east edge, so "To be continued" doesn't appear. `tests/test_cake_finale.gd` checks both (23 of 23 at 30, 60 and 144 fps on `263ac50`).

**Used in the film** (`clips.json`):
- **B01E:** 7.50–14.10, 15.20–17.60, 21.20–22.50, 32.25–33.95 and 36.40–37.52 s;
- **B09:** 96.00–111.47 s.
