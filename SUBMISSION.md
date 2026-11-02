# SUBMISSION: Assignment 5

> **Draft by Claude Code (1 Nov 2026), from the repo at fab87d0 and the work after it.** Fill in everything marked **[to fill]**, check that every line says it the way you would, then delete this note. The tagged commit's own SHA can't go into that commit: put it in the copy that goes to Canvas with `submission.zip`. The Assignment 3 version of this file is at the `a3` tag.

**Assignment:** Assignment 5 - Shaders, Materials, and the Godot Shading Language

**Student:** Abhinav Gangurde (GitHub: Abhinow1997)

**Project name:** The Noise Next Door

**GitHub repository URL:** https://github.com/Abhinow1997/the-noise-next-door (branch `assignment-5`)

**Git tag and submitted commit SHA:** `a5` → **[to fill: the SHA `a5` points at]**

**Game-source revision shown in the film:** **[to fill: no film yet]**

**Godot version, renderer, and operating system:** Godot 4.7.2 stable (official build `ed1daf0bf`), Forward+ (`project.godot`, `config/features`), Windows 11 Home (build 26300). The checks run in Git Bash through `scripts/run-test.sh`.

**Game state the shader from code communicates:** a camper has just spotted the raccoon.
- The campers' vision cones, drawn by my `shaders/vision_cone.gdshader` (53b0087), one `ShaderMaterial` per cone. A cone is pale yellow while its camper watches.
- The moment a camper spots him, that camper's cone snaps red (`alarm` 1) for 2 s of game time, starting over if he's spotted again. Then every cone fades out over 0.5 s (`shown`), and each comes back, yellow, after its camper calms down.
- The state is `spotted_at` and `spotters` in `scripts/campsite.gd`, set by `spot()`. `scripts/cone_driver.gd` reads them and writes only the cones' `alarm` and `shown`.

**3D object and scene given the textured shader:** the cooler (`assets/props/cooler.glb`, my Assignment 3 asset), in the asset room (`asset_room/asset_room.tscn`, key 2) and at the camp by the fire (`scripts/campsite.gd`). My `shaders/cooler_paint.gdshader` (c45c97b) draws its body and lid through two materials, `materials/cooler_body.tres` (red, since 1 Nov) and `materials/cooler_lid.tres` (white), behind the glb's per-material Use External.

**Texture sources and licences:**
- **Blue Metal Plate,** by Rob Tuytel (all roles), from Poly Haven: https://polyhaven.com/a/blue_metal_plate. CC0, checked by me on 29 Oct 2026. The 1k PNGs: the diffuse (with `source_color`), the roughness map and the OpenGL normal map `_nor_gl` (both as data). The `_nor_dx` map is only for calibrating the normal-map check, and its import is Skip. Credits, sizes and MD5s: `assets/textures/blue_metal_plate/ATTRIBUTION.md`.
- **The hint experiment's 3×1 PNG** of greys 64, 128 and 192 is written by code: `hint_experiment/make_greys_png.gd`.
- No generated textures.

**Final film URL and filename:** **[to fill: no film yet]**

**Final film SHA-256:** **[to fill]**

**Summary of my work:**
- **My specification** (CHANGE-BRIEF.md, "Assignment 5: shaders and materials"), committed before either shader, with dated revisions.
  - Mine: the state, the rules and my choices, and my colour line and see-through line.
  - My predicted pixels and hint-experiment numbers were worked out with Gemini's and ChatGPT's help and checked by hand. The wording of my short answers and of the hint experiment's "why" is theirs, validated by me.
  - Many choices were picked from Claude Code's options, and each revision says which.
- **CLAUDE.md:** the `claude -p` agent's draft (6451725), then my review (b97ac59). Claude Code made the edits I decided on.
- **My three shaders, written by hand:** the cone's (53b0087), the cooler's (c45c97b) and the hint experiment's (9d782c3). No agent session changed `shaders/`; I made the editor's conversion and my annotations of it myself (e58ccb4, 92e12b8).
- **The cone's driver and its test:** written by the `claude -p` agent (29fd5da) and fixed by Claude Code after its review (2024a76).
- **My checks:**
  - the parse and rename mutations of my cone shader, and the `source_color` mutation of my cooler shader;
  - my controlled-value captures of the cone, against my predicted pixels, with `alarm` at 2.0 for the `hint_range` question;
  - my hint-experiment capture;
  - five spottings in play;
  - the cooler in the editor with SSAO off, with the shader-edit and material-edit check;
  - my interface sweep (fab87d0).
- **My language notes,** LANGUAGE-NOTES.md (b6a8185, revised on 1 Nov after Claude Code's checks), with line references to my shaders.
- **Claude Code's other work:**
  - the test wrapper's adaptation;
  - the materials and their import settings;
  - the hint experiment's scene;
  - the capture tools;
  - the material audit's review (ec2742d), after the agent's audit (406133e);
  - the fix to the material test after a fresh import (a0e7049);
  - the `hint_normal` probe;
  - the write-ups.

  SOURCES.md and FRICTIONAL.md say who did what.

**Checks run (command and result):** from the repo root in Git Bash, after `godot --headless --path . --import` from an empty cache, all through `bash scripts/run-test.sh`. Claude Code's fresh-clone run of 1 Nov, with the fix in a0e7049:
- the cone's shader test (`--cone-shader-test`): 93 of 93 at 30, 60 and 144 fps;
- the material test (`test_materials.gd 60`): 137 of 137;
- the cones check (`--cones-test`): 43 of 43 at 30, 60 and 144 fps;
- the earlier checks at 60 fps: A3 assets 20, sounds 30, bubbles 87, camp 31, tasks 43 and plan 19, all passing. Waves (12 of 13) and title (51 of 52) fail the one check each that they failed before this assignment began;
- the normal-map calibration: GL 0.427 and DX 1.573 with `directx = false`. The material test passes a map below 0.7;
- the mutations: the semicolon (85 of 93) and the rename (87 of 93) of my cone shader each exit 1. My `source_color` mutation of my cooler shader fails the material test, 136 of 137; its exit status wasn't recorded, and the test quits 1 on any failure;
- no `SHADER ERROR` or `SCRIPT ERROR` in any log.

**[to fill]** Clone the `a5` tag into an empty folder, run the import and every check above, and confirm the counts match.

**Known limitations:**
- **No film yet.**
- **The interface sweep is partly recorded.** My notes on `tint` and `uv_scale` are in TEST-REPORT.md, but not yet what changed for `detail`, `roughness_scale` and `normal_strength`. **[remove this if you add them]**
- **The hint experiment** is one quad split in two, not the course's bool uniform with two materials on two quads. That was my decision (CHANGE-BRIEF.md, "Revised 29 Oct 2026: the hint experiment, on one quad split in two").
- **My predictions have a known arithmetic slip:** most channels come out 1 to 3 steps low. My capture of Base at Camper's R is 3 steps above my prediction, past my 2-step match.
- **In play,** the rest of my list (the cones fading back in, the tutorial's end, the boundaries and the bubble demo) is recorded only as "looks fine", with no detail for each. A red cone over a yellow one (my predicted failure 7) hasn't been seen.
- **The cooler:**
  - its colour line can take `ALBEDO` above 1 at the diffuse's brightest texels (MATERIALS.md, findings);
  - its red body goes against CHARACTER-SHEET.md and STORYBOARD.md, which keep red for the beanie. I kept it.
- **The cone's shader has no `fog_disabled`.** My captures show no fog at my two spots.
- **No headless run shows the look:** the colours, the fades and the cooler's surface are checked only by my eyes.
- **Two earlier checks fail under `--fixed-fps`:** waves (12 of 13) and title (51 of 52), as recorded before this assignment.
- **An editor session rewrites three campers' `.import` files** by Godot's 3D detection. They were restored each time, and the rewrite is explained in TEST-REPORT.md.

**Changed games since Assignment 2:** No. It's still The Noise Next Door.

---

**Source ZIP:** `submission.zip`
- Made with `git archive --format=zip --prefix=the-noise-next-door/ -o submission.zip a5`.
- **[to fill: its size in bytes, its number of files, and its SHA-256]**
- If you move `a5` again, remake the ZIP and update this.
