# Sources and asset log

`the-noise-next-door` · CSYE 7270 · Assignment 2

## Generative models

| Model | Version | Where it ran | Licence or terms |
|---|---|---|---|
| Google Gemini (image generation) | *fill in: the model name and version Gemini shows* | *fill in: e.g. through Northeastern's access* | *fill in* |
| *fill in: the music model* | *fill in* | *fill in* | *fill in* |

## Asset log

One row for every generation that was kept or seriously considered. Rejected outputs are kept as small thumbnails or a contact sheet, not full-size files, because they show the design judgement.

| Asset ID | Model and version | Prompt and settings | Outcome | Edits | Where used |
|---|---|---|---|---|---|
| REF-STYLE | Google Gemini, *fill in the version* | *Fill in the prompt if you still have it; if not, say it wasn't recorded.* | Accepted as the raccoon's style target. An early exploration, made before any design doc was committed (the file is dated 4 Oct 2026, 18:46). | None | [design/reference/Gemini_Generated_Image_kfpcx2kfpcx2kfpc.jpg](design/reference/Gemini_Generated_Image_kfpcx2kfpcx2kfpc.jpg): the style reference for [CHARACTER-SHEET.md](CHARACTER-SHEET.md). Not used in the game. |
| MUS-PIANO-LOOP | *fill in: the music model and version* | "Playful, mischievous solo acoustic piano for a cozy cartoon game where a sneaky little animal tiptoes around a forest campsite stealing snacks. Warm upright piano with soft hammers, close and intimate, recorded in a dry small room. 96 BPM, 4/4, F major with a few sly chromatic notes. The left hand plays light staccato tiptoe steps: a low note on beats one and three, short soft chords on two and four. The right hand plays a catchy two-bar staccato motif with grace notes and little chromatic slides, and now and then pauses for a beat as if freezing to look around, then carries on. Quiet and steady all the way through, mezzo-piano, middle register, no climax. Seamless loop: no intro, no ending, no fade; the last bar leads straight back into the first. Instrumental, piano only." *Confirm this is what you typed; fill in the negative prompt if used, the length, the seed and which take this was.* | Kept. A 2:19 solo piano piece at a steady 91.9 BPM (the prompt asked for 96). It came out as a whole song that fades at the end, not as a loop. | Claude Code cut a 16-bar loop with a Python script: 47.014 s to 88.781 s of the original (41.768 s), on the measured beat grid, starting 50 ms before the downbeat of bar 18. The 16-bar section was chosen because its seam matched best (32-bar sections were weaker). The loop's first 40 ms are an equal-power blend with the audio that follows the cut, so the wrap continues seamlessly. No EQ, compression or level change. Godot import: forward loop over the whole file, QOA compression. | [assets/audio/music/forest-loop.wav](assets/audio/music/forest-loop.wav): the level's music, played by `_start_music()` in `scripts/main.gd`. Original: [design/music/start-quest-forest-campsite.wav](design/music/start-quest-forest-campsite.wav). |

## Code and drawings

- **The prototype** (`project.godot`, the scenes and `scripts/`): the author's own Raccoon Mischief prototype. Two changes were made with Claude Code on 4 Oct 2026; see the README.
- **The storyboard thumbnails** in `design/storyboard/`: drawn by Claude Code in code, with `make_thumbnails.py`. They aren't generated assets.
- **The raccoon model** in `assets/characters/`: built by Claude Code in Blender with Python (through the Blender MCP), matched to `design/reference/the-raccon.jpg`. No generative model made it, so it isn't a generated asset. The game uses `raccoon.glb`, made from `raccoon.blend` by `export_raccoon.py` (also Claude Code).
