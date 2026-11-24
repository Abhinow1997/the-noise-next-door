# Sources: The Noise Next Door, final project pitch

`pitch/` · Assignment 8 · Draft v0, 23 Nov 2026

What the pitch film used, what I made, what Claude Code contributed, and every third-party asset with its licence. The game's own assets are logged in full in the repo's [SOURCES.md](../SOURCES.md); this file covers the film.

## What I made

- **The game and its design:** The Noise Next Door, its story (CONCEPT.md, STORYBOARD.md) and GDD.md, quoted exactly on the boards.
- **The footage:** every gameplay clip is real play: the game run normally and its window screen-recorded by me (SHOTLIST.md), at the commit named in FACTCHECK.md.
- **The decisions:**
  - the pitch covers the whole game;
  - gameplay programmer as the role;
  - the games I compare it with;
  - why I picked it;
  - Brutalist's godot-gdd route;
  - a desktop game for Windows and macOS;
  - waiting for level 1's ending before recording.

  They're quoted in PROMPTS.md.

## What Claude Code contributed (Claude Opus 5.5, in Claude Code, 23 Nov 2026)

- **The drafts:** PROJECT-BRIEF.md, the narration and board props in `beat_sheet.json`, SHOTLIST.md, FACTCHECK.md, PROMPTS.md and this file.
- **The tools:**
  - `tools/build_ledger.py`, the GDD evidence ledger;
  - `tools/set_timing.py`, the boards' timing;
  - `tools/stage.sh`, the board images;
  - `tools/cut_clips.py`, the gameplay clips and their labels;
  - `tools/make_end_card.py`, the end card.
- **Getting Brutalist to run on Windows:**
  - the install, in its own Python environment;
  - five small patches, in `tools/brutalist-local.patch` (FRICTIONAL.md has why).
- **The checks** in FACTCHECK.md, and the gate runs.

## Generated material

- **The narration:** an AI voice, Kokoro-82M's `am_onyx`, reading my script as me. It isn't my voice, and the end card says so.
- **In the footage:**
  - **the moth**, a sprite sheet I generated with Google Gemini (Assignment 7, `assets/sprites/moth_lowpoly/`). It's labelled as generated in B05, where it leads him down the trail, and on the end card; it's also on screen, smaller, in B01E and B09.
  - The game's music (Suno) and effects (ElevenLabs, Pixabay) are muted under the narration.
- **No images, video or music were generated for the film itself.**

## Tools

| Tool | Version | Used for | Licence |
|---|---|---|---|
| Brutalist (github.com/nikbearbrown/brutalist.art) | commit `3a6d397`, with `tools/brutalist-local.patch` | The godot-gdd skill and its check, `GodotDesignBoard`, the narration, compile and gates | No licence file in the repo; used as the course's required toolkit |
| Kokoro-82M, through kokoro-onnx | model files v1.0 (`kokoro-v1.0.onnx` SHA-256 `7d5df8ec…3636a6c5`, `voices-v1.0.bin` `bca610b8…1fbf7d`); kokoro-onnx 0.6.1 | The narration, locally | Model: Apache 2.0. kokoro-onnx: MIT |
| Remotion | 4.0.535 | Rendering the boards | Remotion Free License (individuals) |
| FFmpeg | 9.1, gyan.dev full build, from winget | Cutting, labelling and compiling | GPL (the full build) |
| PyAV | 18.0.0 (not 18.1.1, which Windows' Smart App Control blocked) | Brutalist's dependency | BSD-3-Clause |
| Godot | 4.7.2 stable | The game, run for the takes | MIT |
| Snipping Tool (Windows 11) | built in | Recording the game's window for the takes | Part of Windows |
| EB Garamond, Inter | bundled with Brutalist (`runtime/fonts/`) | The boards' and the end card's type, the clip labels | SIL Open Font License 1.1 |

## Third-party assets on screen

All are in the game, logged in the repo's SOURCES.md, and seen in the footage:

| Asset | Creator | Licence | Credit |
|---|---|---|---|
| Simple girl, Lowpoly man, chubby boy (the campers and the fire keeper) | TiZeta, Blend Swap 66413, 66412, 66415 | CC BY 3.0 | Required: on the end card |
| Tent | SSimpossible, Blend Swap 5010 | CC0 | Given anyway |
| Table with laptop, radio and documents | Not named on its licence page, Blend Swap 92671 | CC0, marked fan art: no commercial use | Given anyway; to be replaced before any commercial release |
| Patrick Hand (the game's handwriting font) | Patrick Wagesreiter | SIL OFL 1.1 | Given anyway |
| The fire keeper's cardboard box | Viktor Sano ("[CC0] Free Cardboard Boxes") | CC0 | Given anyway |
