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
| [CHARACTER-SHEET.md](CHARACTER-SHEET.md) | The cast: the raccoon and the camper (the two main characters) and the town's dogs, with looks, palettes, poses and the Gemini prompts |
| [CHANGE-BRIEF.md](CHANGE-BRIEF.md) | The plan for the asset slice: its assets, which sound plays on which event, the music's behaviour, and predicted failures |
| [SOURCES.md](SOURCES.md) | The generative models used, and the asset log |
| [FRICTIONAL.md](FRICTIONAL.md) | The dated design log: what was asked for, what came back and what was decided, starting with the storyboard |
| [design/storyboard/](design/storyboard/) | The storyboard thumbnails, and `make_thumbnails.py`, which draws them |
| [design/character/](design/character/) | The character sheet's images: the silhouette test, the labelled pose sheet, the collision overlay and the cut-out poses, made from the generated poses by `make_character_sheet.gd` |
| [design/reference/](design/reference/) | The generated reference images: the raccoon's style target and poses, the camper, the dogs, the forest, the den, the rejected ground texture and the stump |
| [assets/characters/](assets/characters/) | The raccoon model: `raccoon.blend`, the `raccoon.glb` the game loads, and `export_raccoon.py`, which makes the .glb from the .blend |
| `project.godot`, `main.tscn`, `raccoon_model.tscn`, `scripts/` | The Godot project |

## Run it

You need Godot 4.7.2. The project uses the Forward+ renderer.

- **Windows:** double-click `Play The Noise Next Door.bat`, or `Edit in Godot.bat` to open the editor. They look for Godot in the `GODOT` environment variable, then in `%LOCALAPPDATA%\Programs\Godot`, then in your Downloads folder. The first run takes a few seconds longer while Godot imports the raccoon model.
- **Anywhere:** run `godot --path .` from this folder. On a fresh clone, first run `godot --headless --path . --import` once (or open the project in the editor), so the raccoon model is imported.

**Controls:** WASD or the arrow keys to move, Shift to run, Ctrl or C to sneak, E or a click to grab or drop, Space to chitter, and the mouse wheel to zoom. Walk into a tree to climb it. Then W and S climb up and down, A and D go round the trunk, and E lets go. Climb to the top of the home pine to get into the hollow. Esc pauses. M turns the music on and off, and N does the same for the sound effects. Tab opens a panel for trying out camera views live; its "Copy numbers" button copies the settings.

**The automated sound check:** run `godot --headless --path . -- --sound-test`. It plays a scripted input sequence, counts how often each sound effect starts, and checks the music's pause, mute, loop and end behaviour. It prints a table, and its exit code is 0 only if every check passes (`scripts/sound_test.gd`).

To redraw the storyboard after editing it, run `python design/storyboard/make_thumbnails.py`. To remake the character-sheet images and the raccoon's cut-outs, run `godot --path . --script res://design/character/make_character_sheet.gd`, then copy the five cut-outs the slice uses into `assets/characters/raccoon/`. For the stump, run `godot --headless --path . --script res://design/environment/make_props.gd`. For the sound loops, run `python design/sfx/make_sfx_loops.py`. To update the game's raccoon after editing `raccoon.blend`, run `blender -b assets/characters/raccoon.blend --python assets/characters/export_raccoon.py`.

## Started from

This project started from **Raccoon Mischief**, the first prototype of this game, and it keeps building on it.

The prototype is a raccoon in a fenced garden with a five-task to-do list. Everything in it is built in GDScript when the game runs: the raccoon is a procedural low-poly model, and there are no image or sound files. It doesn't play the storyboard's story yet.

Two changes were made with Claude Code on 4 Oct 2026, before this repo existed:
- The launchers find Godot on any machine.
- The raccoon can be smoothed, using `smooth_loft()` in `scripts/lowpoly.gd` and the `smooth` setting in `scripts/raccoon_model.gd`. Turning `smooth` off brings back the original faceted look.

## Who made what

- **The author:** the prototype, the story, and the design decisions. The provenance notes at the end of CONCEPT.md and STORYBOARD.md list them.
- **Claude Code:** drafts and wording for the docs, the storyboard thumbnails (drawn in code), the two prototype changes above, the raccoon model in `assets/characters/` (built in Blender with Python) and the code that puts it in the game, tree climbing, the camera code and its Tab panel (the camera view itself is the author's pick), the character-sheet images and pose cut-outs (`design/character/make_character_sheet.gd`), the music and sound-effect loop cuts (`design/sfx/make_sfx_loops.py`), drawing the raccoon with the generated images (`scripts/raccoon_sprite.gd`), placing the stump, wiring up the sounds, mute and pause, the automated sound check (`scripts/sound_test.gd`), and this README.
- **Generative models, run by the author:**
  - Google Gemini for every image: the raccoon's style target (made before any design doc was committed), his pose images, the other character and scene references, and the ground texture;
  - a music and sound model, still to be named in SOURCES.md, for the five music tracks and all the sound effects.

  [SOURCES.md](SOURCES.md) logs every generation. Claude Code generated none of them: it cut out the poses and cut the loops.
