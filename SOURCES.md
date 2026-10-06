# Sources and asset log

`the-noise-next-door` · CSYE 7270 · Assignment 2

## Generative models

| Model | Version | Where it ran | Licence or terms |
|---|---|---|---|
| Google Gemini (image generation) | *fill in: the model name and version Gemini shows* | *fill in: e.g. through Northeastern's access* | *fill in* |

## Asset log

One row for every generation that was kept or seriously considered. Rejected outputs are kept as small thumbnails or a contact sheet, not full-size files, because they show the design judgement.

| Asset ID | Model and version | Prompt and settings | Outcome | Edits | Where used |
|---|---|---|---|---|---|
| REF-STYLE | Google Gemini, *fill in the version* | *Fill in the prompt if you still have it; if not, say it wasn't recorded.* | Accepted as the raccoon's style target. An early exploration, made before any design doc was committed (the file is dated 4 Oct 2026, 18:46). | None | [design/reference/Gemini_Generated_Image_kfpcx2kfpcx2kfpc.jpg](design/reference/Gemini_Generated_Image_kfpcx2kfpcx2kfpc.jpg): the style reference for [CHARACTER-SHEET.md](CHARACTER-SHEET.md). Not used in the game. |

## Code and drawings

- **The prototype** (`project.godot`, the scenes and `scripts/`): the author's own Raccoon Mischief prototype. Two changes were made with Claude Code on 4 Oct 2026; see the README.
- **The storyboard thumbnails** in `design/storyboard/`: drawn by Claude Code in code, with `make_thumbnails.py`. They aren't generated assets.
- **The raccoon model** in `assets/characters/`: built by Claude Code in Blender with Python (through the Blender MCP), matched to `design/reference/the-raccon.jpg`. No generative model made it, so it isn't a generated asset. The game uses `raccoon.glb`, made from `raccoon.blend` by `export_raccoon.py` (also Claude Code).
