# The Noise Next Door

A raccoon just wants a quiet night in his tree. Then a party starts right underneath it.

He sneaks down to prank the partiers, gets chased into town wearing a camper's red beanie, becomes the neighbourhood's masked bandit, and is finally driven home by that same camper, just in time for the next party. It's slapstick with no dialogue: the story is told through what the player does and how people react.

Made for CSYE 7270 (Fall 2026), Assignment 2: Generate Art, Sound, and Music for Your Game.

![The storyboard](design/storyboard/storyboard-sheet.svg)

## What's here

| Path | What it is |
|---|---|
| [CONCEPT.md](CONCEPT.md) | The one-page concept: story, core loop, pillars, art and audio direction |
| [STORYBOARD.md](STORYBOARD.md) | The whole story in 15 panels, with each panel's shot, sounds and assets |
| [CHARACTER-SHEET.md](CHARACTER-SHEET.md) | The two main characters, the raccoon and the camper: looks, palettes, poses, and the Gemini prompts |
| [SOURCES.md](SOURCES.md) | The generative models used, and the asset log |
| [design/storyboard/](design/storyboard/) | The storyboard thumbnails, and `make_thumbnails.py`, which draws them |
| [design/reference/](design/reference/) | The raccoon's style target |
| `project.godot`, `main.tscn`, `raccoon_model.tscn`, `scripts/` | The Godot project |

## Run it

You need Godot 4.7.2. The project uses the Forward+ renderer.

- **Windows:** double-click `Play The Noise Next Door.bat`, or `Edit in Godot.bat` to open the editor. They look for Godot in the `GODOT` environment variable, then in `%LOCALAPPDATA%\Programs\Godot`, then in your Downloads folder.
- **Anywhere:** run `godot --path .` from this folder.

**Controls:** WASD or the arrow keys to move, Shift to run, Ctrl or C to sneak, E or a click to grab or drop, Space to chitter, and the mouse wheel to zoom.

To redraw the storyboard after editing it, run `python design/storyboard/make_thumbnails.py`.

## Started from

This project started from **Raccoon Mischief**, the first prototype of this game, and it keeps building on it.

The prototype is a raccoon in a fenced garden with a five-task to-do list. Everything in it is built in GDScript when the game runs: the raccoon is a procedural low-poly model, and there are no image or sound files. It doesn't play the storyboard's story yet.

Two changes were made with Claude Code on 4 Oct 2026, before this repo existed:
- The launchers find Godot on any machine.
- The raccoon can be smoothed, using `smooth_loft()` in `scripts/lowpoly.gd` and the `smooth` setting in `scripts/raccoon_model.gd`. Turning `smooth` off brings back the original faceted look.

## Who made what

- **The author:** the prototype, the story, and the design decisions. The provenance notes at the end of CONCEPT.md and STORYBOARD.md list them.
- **Claude Code:** drafts and wording for the docs, the storyboard thumbnails (drawn in code), the two prototype changes above, and this README.
- **Generative models:** only one image so far: the raccoon's style target, generated with Google Gemini before any design doc was committed. It's in `design/reference/`, and [SOURCES.md](SOURCES.md) logs it.
