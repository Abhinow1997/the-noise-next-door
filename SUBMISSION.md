# SUBMISSION: Assignment 6

> The SHA that `a6` points at and the source ZIP's checksum are in the note sent to Canvas with `submission.zip`: a commit can't contain its own SHA, and the ZIP is made from the tagged commit. The Assignment 5 version of this file is at the `a5` tag.

**Assignment:** Assignment 6 - Creating Particle Effects with Godot and Claude

**Student:** Abhinav Gangurde (GitHub: Abhinow1997)

**Project name:** The Noise Next Door

**GitHub repository URL:** https://github.com/Abhinow1997/the-noise-next-door (branch `assignment-6`)

**Git tag and submitted commit SHA:** `a6`. Its SHA is in the Canvas note.

**Game-source revision shown in the films:** the game source as at `502dc4e`, for both videos. No later commit changes it: the later commits add only docs, logs, Godot's `.uid` files, `captures/.gdignore` and the generated process shader, which nothing in the game uses.

**Godot version, renderer, and operating system:** Godot 4.7.2 stable (official build `ed1daf0bf`), Forward+ (`project.godot`, `config/features`), Windows 11 Home (build 26300). The checks run in Git Bash through `scripts/run-test.sh`. The GPU price was taken on an NVIDIA GeForce RTX 4050 Laptop GPU at 1280 × 720.

**The two effects:**
- **Effect A, the leaf burst** (`effects/leaf_burst.tscn`): a one-shot on a repeating gameplay event. Leaves and a puff of flecks burst out of the camp's bush when the raccoon dives in to hide, and a half-size burst (`amount_ratio` 0.5) when he hops out. It tells the player they're hidden, out of sight of whoever's chasing them, and then that they can be seen again.
  - Two `GPUParticles3D`, Leaves and Puff, under one `Node3D`.
  - **Its event:** the bush's `hiding_changed(inside)` signal, emitted at the end of `dived()` (`scripts/hide_spot.gd`). `scripts/leaf_bursts.gd` puts a fresh copy at the bush per event and frees it on a timer.
  - **Its retrigger rule is overlap:** in and straight out gives two bursts alive at once.
- **Effect B, the campfire smoke** (`effects/campfire_smoke.tscn`): a feedback loop. Every frame, `scripts/campfire_smoke.gd` sets the smoke's `amount_ratio` to the fire's `strength` (0 out, 1 burning well; `scripts/camp_fire.gd`), and `emitting` to whether it burns. `amount` never changes. Its job, in my words: the smoke is the signal that the fire is up, so near the camp the raccoon has to crouch or be detected more quickly.
  - **What Effect A doesn't use:** the value-driven `amount_ratio`, turbulence, a scale curve, a box emission shape, `preprocess` and a soft round texture.
  - **Start, stop, pause and hidden:** it starts when the fire's lit and stops when it's out, letting the air clear. Paused, it freezes. Hidden, `amount_ratio` keeps following the fire.

**Texture sources and licences:** none sourced and none generated. The leaves and flecks are untextured quads. The smoke's soft disc is a `GradientTexture2D` written in its scene file.

**Final film URL and filename:**
- **My film:** https://northeastern-my.sharepoint.com/:v:/g/personal/gangurde_a_northeastern_edu/IQCrT_wDa6QiSq6EOe5F_I_PAVkvaVZz3eDnikzc0rKSncM?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=8I0K9d
  - Filename: `VideoRecording - Assignement -6.mp4`
- **An AI explainer,** a NotebookLM Video Overview made from this repo's Assignment 6 docs (SOURCES.md): https://northeastern-my.sharepoint.com/:v:/g/personal/gangurde_a_northeastern_edu/IQAPL5_3NROUQp7Ey6fqwVn9AUuZi7FF5uODsgNRKoH9g7g?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=4aeAqc
  - Filename: `AI_Explainer_Assignment_6_Godot_Particles.mp4`

**Final film SHA-256:**
- My film: `1a0a98ca86b2e313624359217b4399927eaf2d963d70372cf7e01f03ce0355b0`
- The AI explainer: `a39f2b765137ca57953be0062e1673dbdecd648e01b6584b4836910ec8af823c`

**Summary of my work:**
- **My specification** (CHANGE-BRIEF.md), committed before the first prompt (`f24df97`), with dated revisions: the preview's retrigger frame, the signal and wiring, Effect B, its wiring, and each tuning change.
  - **Mine:** both effects' jobs, in my own words; Effect A's fade-only look; my picks for every choice.
  - **Claude Code's options, used at my word:** the settings' numbers, the frame readings, the price predictions, and the drafts of the short answers, which I checked. Each revision says which.
- **CLAUDE.md:** the `claude -p` agent's draft (`da111e2`), then the review (`f9c94ca`), kept under 120 lines.
- **The effects, built by `claude -p` sessions** and committed unedited before each review:
  - Effect A's scene, configuration test and preview (`b0ca8d0`);
  - its wiring and state test (`271687d`);
  - Effect B's scene, configuration test and preview (`9e81f79`);
  - its driver and state tests (`0286ea2`);
  - the cost script (`fb47194`).

  The prompts and transcripts are in `design/a6/`.
- **Tuning:** one revision each, with Claude's prediction, my strips before and after, Claude's comparison and my verdict in the running game (TUNING.md):
  - Effect A, the leaves' gravity −3.5 → −6.0 (`872ed53`);
  - Effect B, the smoke's peak alpha 0.45 → 0.25 (`9cd79df`).

  I captured every strip and kept both changes.
- **The process shader:** I converted a copy of the smoke's `ParticleProcessMaterial` in the editor (`shaders/particles_generated.gdshader`, `7bde16d`). My line references and my answer on process versus draw are in TEST-REPORT.md, "The process shader" (`49be553`). Copilot helped me verify them, as that section says. No agent session changed `shaders/`.
- **My checks in play:** effects, backgrounds, screen edge and the overall feel (TEST-REPORT.md, "Assignment 6: Use It"). Also the Visual Profiler on the RTX 4050 (`74dde66`).
- **The films:** my film, and an AI explainer that NotebookLM made from this repo's Assignment 6 docs.
- **Claude Code's other work:**
  - the reviews;
  - the GPU-timer script (`tools/gpu_time_effects.gd`);
  - the game work at my requests (the campfire's life, the developer menu, the tent, the firelight and the fire's circle of sight, the tutorial's changes);
  - the write-ups.

  SOURCES.md and FRICTIONAL.md say who did what.

**Checks run (command and result):** from the repo root in Git Bash, all through `bash scripts/run-test.sh`, with the mode stated ([logs/a6-caught-sync/](logs/a6-caught-sync/), the game source as at `502dc4e`):
- **Effect A:**
  - configuration (`test_leaf_burst_config.gd 60`): 110 of 110;
  - state (`--leaf-burst-test 60`): 37 of 37, including two events inside one lifetime.
- **Effect B:**
  - configuration (`test_campfire_smoke_config.gd 60`): 73 of 73;
  - state from cold (`--smoke-test 60`): 20 of 20;
  - burning at load (`--smoke-load-test 60`): 8 of 8.
- **The mutations:**
  - **Effect A's configuration test:** a Godot 3 name (`initial_velocity` for `initial_velocity_min`) and `amount` 18 → 24 each exit 1. With the Godot 3 name, the state test still passes 37 of 37.
  - **Effect A's state test:** four listener mutations each fail it (a reused node, a burst at load, no half burst, never freed).
  - **Effect B's state test:** the driver writing `amount` instead of `amount_ratio` fails 13 of 20.
- **The price:**
  - **Headless CPU** (`cost_effects.gd 60 300`), per frame: the empty-scene control 0.005 ms, the game with both effects off 1.016, Effect A at its peak 1.018, Effect B at its heaviest 1.008.
  - **GPU on the RTX 4050:** Effect A +0.05 ms (budget 0.2) and Effect B +0.03 ms (budget 0.3), by the GPU-timer script.
  - **In the Visual Profiler:** one frame at 2.96 ms, of which "Update GPUParticles" took 0.01 ms.
- **The earlier checks**, at their baseline counts: A3 assets 20, sound 30, bubbles 87, camp 31, tasks 43, plan 19, tutorial 29, materials 137; cones 43 and cone shader 93 at 30, 60 and 144 fps; fire 23, tent 16. Waves (13 of 13) and title pass in realtime. Under `--fixed-fps` they fail the one check each that they failed before this assignment began.
- No `SHADER ERROR` or `SCRIPT ERROR` in any log.

**My fresh-clone check of the `a6` tag:** in the Canvas note, since it can only be run once the tag exists.

**Known limitations:**
- **Effect B needs more work, in my view:** "I don't think the second effects has been created or designed well. I will need to rework on the same for some time." Since its tuning, the column's top half is too faint to see, so it reads about half as tall as the brief's 2 m.
- **The GPU price, effect by effect, came from a script** that reads the Visual Profiler's GPU timer, not from per-state Visual Profiler readings. From the Visual Profiler I read one frame, and its effect state wasn't recorded. FPS with vsync off and the AMD Radeon 740M weren't measured.
- **My notes on the smoke at scene load, paused and hidden** say I checked them, but not what I saw.
- **The course's Brutalist godot-gamedev skill** wasn't installed in this checkout (Claude Code checked the plugin catalog on 8 Nov 2026).
- **The AI explainer is NotebookLM's summary of my docs.** It may simplify or misstate details; the repo is the record.
- **No headless run shows the look.** How each effect reads is checked only by the strips and my eyes. These remain unconfirmed on this build:
  - how many particles `amount_ratio` 0.5 gives a one-shot burst;
  - whether a hidden `GPUParticles3D` keeps simulating.
- **Two earlier checks fail under `--fixed-fps`:** waves (12 of 13) and title (51 of 52), as recorded before this assignment.

**Changed games since Assignment 2:** No. It's still The Noise Next Door.

---

**Source ZIP:** `submission.zip`
- Made with `git archive --format=zip --prefix=the-noise-next-door/ -o submission.zip a6`.
- Its size, number of files and SHA-256 are in the Canvas note.
- If `a6` moves, the ZIP is made again and the Canvas note updated.
