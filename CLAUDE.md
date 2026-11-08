## Project context

- **Engine:** Godot 4.7.2 stable: `config/features` says `"4.7"` (`project.godot`), and the wrapper looks for
  `Godot_v4.7.2-stable_win64_console.exe` (`scripts/run-test.sh`; `README.md`, "Run it"). GDScript throughout.
- **Renderer:** Forward+ (`project.godot`, `"Forward Plus"`). The project is the repo root, not `godot/`
  (`scripts/run-test.sh`, header comment).

### The effects (`CHANGE-BRIEF.md`, "The effects")
- **Effect A, the leaf burst:** two `GPUParticles3D`, **Leaves** and **Puff**, under one `Node3D` root, each with a
  `ParticleProcessMaterial` and a `StandardMaterial3D` draw material (`CHANGE-BRIEF.md`, "The settings").
  A fresh copy of the effect's scene per event, placed at the bush, freed when both emitters are done; the hop-out
  copy has `amount_ratio` 0.5 (same section).
- **Effect B:** not defined yet; it comes in a dated revision (`CHANGE-BRIEF.md`, "Status"). No node type.

### What owns Effect A's event
- **The bush:** `bush`, an `Area3D` running `scripts/hide_spot.gd` (`var bush: Area3D`, `scripts/campsite.gd`),
  built by `_build_bush()` at `FIRE + BUSH`, `BUSH := Vector2(-3.5, 3.0)`, with `dive = true` (`scripts/campsite.gd`).
  It is never freed (`CHANGE-BRIEF.md`, "Facts from the code").
- **The event:** `dived(inside: bool)` in `scripts/hide_spot.gd`, which starts the rustle today. **No signal exists
  yet**: `hide_spot.gd` declares none. Adding one there is the brief's one allowed change to game code
  (`CHANGE-BRIEF.md`, "Boundaries"). Its name and signature aren't decided.
- **Its callers** (`scripts/player.gd`):
  - in: walking into the bush, `_on_body_entered()` (`hide_spot.gd`) defers `dive_into()`, a `DIVE_TIME` 0.32 s hop;
    on landing `_hidden_in()` calls `spot.call("dived", true)`;
  - out: `_stop_hiding()` calls `spot.call("dived", false)`. It is called from `_hide_process()` (a move key, hop of
    `DIVE_OUT` 1.5 m, then `DIVE_AGAIN` 0.6 s before he can dive again), `place()` (tests) and `startle()`.

### The scenes the effects appear in
- `res://main.tscn` (`project.godot`, `run/main_scene`): one `Node3D` running `scripts/main.gd` (`main.tscn`).
  `main.gd` builds the camp with `Campsite.new()` unless `--bubble-demo` is on (`scripts/main.gd`, `_ready()`).
- The tutorial's "Hide!" step makes him dive in once (`scripts/camp_tutorial.gd`, header, step 3).
- The effect's own scene(s) go in `effects/` (see Ownership). That folder doesn't exist yet.

### Tests: always through `scripts/run-test.sh <test> <fps|realtime> [timeout-s]`, from the repo root
- An argument starting with `--` runs `main.tscn` with that flag (`-- <flag>`); anything else runs
  `res://tests/<file>` with `--script`. Every run is headless (`scripts/run-test.sh`).
- `<fps>` adds `--fixed-fps <fps>`; **`realtime`** leaves it out, for checks that wait on audio or the clock.
  The optional third argument is the `timeout` in seconds, 120 by default (`scripts/run-test.sh`, header).
- Log: `logs/<name>_<fps>fps.log` or `logs/<name>_realtime.log`. Exit 1 on `SHADER ERROR` or `SCRIPT ERROR`
  in the log, 124 on timeout. Godot: `GODOT`, then `godot` on the PATH, then `../Godot/` (`scripts/run-test.sh`).

```
bash scripts/run-test.sh a3_asset_check.gd 60          # tests/a3_asset_check.gd
bash scripts/run-test.sh normal_map_calibration.gd 60  # tests/normal_map_calibration.gd
bash scripts/run-test.sh test_materials.gd 60          # tests/test_materials.gd
bash scripts/run-test.sh --sound-test 60               # scripts/sound_test.gd
bash scripts/run-test.sh --bubble-test 60              # scripts/bubble_test.gd
bash scripts/run-test.sh --camp-test 60                # scripts/camp_test.gd
bash scripts/run-test.sh --tasks-test 60               # scripts/tasks_test.gd
bash scripts/run-test.sh --plan-test 60                # scripts/plan_test.gd
bash scripts/run-test.sh --tutorial-test 60            # scripts/tutorial_test.gd (dives into the bush)
bash scripts/run-test.sh --cones-test 30               # scripts/cones_test.gd; also 60 and 144
bash scripts/run-test.sh --cone-shader-test 30         # tests/cone_shader_test.gd; also 60 and 144
bash scripts/run-test.sh --waves-test realtime         # scripts/waves_test.gd; fails 12 of 13 at 60 fps
bash scripts/run-test.sh --title-test realtime         # scripts/title_test.gd; fails 51 of 52 at 60 fps
```
- Flags are parsed in `scripts/main.gd` (header comment); `--title-test` in `scripts/title_screen.gd`.
- The baseline before any effect (`TEST-REPORT.md`, "Step 0", at `ed05ada`, logs in `logs/a6-step0/`): 87, 31, 43,
  19 and 21 of each; cones 43 and cone shader 93 at 30, 60 and 144; waves 13 of 13 and title all in realtime.
  The two `--fixed-fps` failures are recorded and expected: don't "fix" them.
- Headless runs use a dummy renderer and draw nothing, so no test can show the look; the GPU particle process
  doesn't run either (`CHANGE-BRIEF.md`, short answer 4). Look and GPU cost are checked by the frame strip, the
  author's eyes and the Visual Profiler (`CHANGE-BRIEF.md`, "The evidence split").

## Current change
@CHANGE-BRIEF.md

## Ownership

Every file in `shaders/` is hand-written by the human and is never edited by an agent: not
created, rewritten, reformatted or "fixed". If a shader looks wrong, report it and stop.

Effect settings live in scene files in `effects/` (`.tscn`, with their materials as sub-resources or `.tres`
beside them), not in code. Scripts may instance an effect, place it, set `amount_ratio` for the hop-out and
free it; they don't set `amount`, lifetimes, velocities, ramps or materials. The brief's settings table is the
source of each value; a change to one starts as a dated revision of `CHANGE-BRIEF.md`, made by the human.

## Godot 4 names

Use Godot 4 names only. Never Godot 3's: `Particles`, `ParticlesMaterial`, `CPUParticles` (no `3D`),
`SpatialMaterial`, `Spatial`, `flags_unshaded`, `params_billboard_mode`, `flags_transparent`.
- **Seen working on 4.7.2 in this repo** (`scripts/campsite.gd`, the fire's sparks): `CPUParticles3D`,
  `StandardMaterial3D`, `BaseMaterial3D.SHADING_MODE_UNSHADED`, `.TRANSPARENCY_ALPHA`, `.BLEND_MODE_ADD`,
  `.BILLBOARD_PARTICLES`, `vertex_color_use_as_albedo`, `billboard_mode`, `blend_mode`, `QuadMesh.size`, `Gradient`.
- **From the Godot 4 class reference, not yet seen on this build** (no file in the repo uses them):
  - `GPUParticles3D`: `amount`, `amount_ratio`, `one_shot`, `explosiveness`, `randomness`, `lifetime`,
    `preprocess`, `local_coords`, `visibility_aabb`, `process_material`, `draw_pass_1`, `emitting`,
    `restart()`, signal `finished`.
  - `ParticleProcessMaterial`: `emission_shape` (`EMISSION_SHAPE_SPHERE`), `emission_sphere_radius`, `direction`,
    `spread`, `initial_velocity_min`/`_max`, `gravity`, `damping_min`/`_max`, `angle_min`/`_max`,
    `scale_min`/`_max`, `lifetime_randomness`, `color_ramp`, `color_initial_ramp`.
  - Unsure: `emission_shape_offset` (one way to put the sphere "0.5 m up the bush"; the node's position is the other).
  - Its `color_ramp` and `color_initial_ramp` take a `Texture2D` (`GradientTexture1D`), not a `Gradient`. Confirm.
- The node's `randomness` (emission timing) is not the process material's `lifetime_randomness` (the brief's).

## Out of scope

- The raccoon's movement, collision, input and key bindings, including the dive, its hop and its timings.
- The campers: what they see, their states, routines and timings. The tutorial's steps and wording.
- Game code beyond one signal emitted from `dived()` in `hide_spot.gd`. The effect listens; it never writes
  game state, and nothing in the game reads the effect.
- Every other look: the bush's rustle and peeking eyes, the fire and its sparks, cones, cooler, trees, icons,
  waves, and everything in `shaders/`.
- What any existing test expects. A test may change how it measures only with the same expected value.
- The renderer, `project.godot`, `Engine.time_scale` in game code, and the bush's mesh, size and place.
- Effect B, until the brief's dated revision defines it.

## Unconfirmed

- The `GPUParticles3D` and `ParticleProcessMaterial` names above haven't been read back from 4.7.2 here; a
  ClassDB query needed approval this session couldn't give. The configuration test should read each one.
- Whether `GPUParticles3D.finished` fires, or `emitting` turns off, in a headless run with the dummy renderer;
  the "freed once both are done" rule and the state test depend on it.
- What `amount_ratio` 0.5 does to a one-shot burst on this build (`CHANGE-BRIEF.md`, short answer 1, says unseen).
- The signal's name and arguments, the effect scene's file name in `effects/`, and the new tests' names and
  commands: none exist yet.
- The test counts were last measured on 7 Nov 2026 at `ed05ada` (`TEST-REPORT.md`, "Step 0"); rerun before trusting.
- `run-test.sh` takes a third argument only as the timeout, so `a3_asset_check.gd -- --mutate` and the
  `--*-shots=<folder>` options still can't go through it.
