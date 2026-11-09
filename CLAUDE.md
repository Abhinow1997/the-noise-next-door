## Project context

- **Engine:** Godot 4.7.2 stable: `config/features` says `"4.7"` and `"Forward Plus"` (`project.godot`); the wrapper
  looks for `Godot_v4.7.2-stable_win64_console.exe` (`scripts/run-test.sh`). GDScript. The project is the repo root.

### The effects (`CHANGE-BRIEF.md`, "The effects", and its 8 Nov 2026 revisions)
- **Effect A, the leaf burst:** two `GPUParticles3D`, **Leaves** and **Puff**, under one `Node3D` root, each with a
  `ParticleProcessMaterial` and a `StandardMaterial3D`. A fresh copy per event, placed at the bush, freed by a timer
  (see Headless facts); the hop-out copy has `amount_ratio` 0.5. Leaves' gravity is −6.0 since tuning r1.
- **Effect B, the campfire smoke:** one `GPUParticles3D`, **Smoke** (`ParticleProcessMaterial`, `StandardMaterial3D`)
  at the fire pit; a feedback loop: `amount_ratio` follows the fire's `strength` (the brief's 8 Nov B revision).

### What owns Effect A's event
- **The bush:** `bush`, an `Area3D` running `scripts/hide_spot.gd`, `_build_bush()` (`scripts/campsite.gd`); never freed.
- **The event:** `dived(inside: bool)` in `scripts/hide_spot.gd` ends by emitting `hiding_changed(inside: bool)`;
  `scripts/leaf_bursts.gd` listens, added in `scripts/main.gd`. Callers (`scripts/player.gd`): `_hidden_in()` on
  landing a `dive_into()` hop (in); `_stop_hiding()` from `_hide_process()` (a move key), `place()` and `startle()` (out).
### What owns Effect B's condition
- **The value:** `strength` (0 out, 1 burning well) in `scripts/camp_fire.gd`, with `burning()` and the signals
  `lit` and `doused`; the node is `campfire` (`var campfire: CampFire`, `scripts/campsite.gd`), at `FIRE`, built in
  `_ready()`. The flames, light and sparks follow `strength` (`_process()` in `scripts/campsite.gd`).
- **What moves it:** `start_cycle()` when the tutorial's done (`_close_list()`, `scripts/camp_tutorial.gd`), then it
  burns down by `BURN`; `die_out()` at the steal; the keeper's `add_log()` (`TEND`, `scripts/camp_person.gd`);
  `douse()` (the bucket, E). Cycle off (the tutorial, the checks that skip it): `strength` stays 1. Starts:
  `-- --dev-start=fire` (burning) or `free` (cold), `scripts/dev_menu.gd` (F1 in debug runs).
### The scenes the effects appear in
- `res://main.tscn` (`project.godot`, `run/main_scene`), running `scripts/main.gd`, which adds `Campsite.new()`. A:
  `effects/leaf_burst.tscn`, `previews/leaf_burst_preview.tscn`, `scripts/leaf_bursts.gd`. B: `effects/campfire_smoke.tscn`,
  `previews/campfire_smoke_preview.tscn`, `scripts/campfire_smoke.gd` (the driver). Tests below.

### Tests: always through `scripts/run-test.sh <test> <fps|realtime> [timeout-s]`, from the repo root
- An argument starting with `--` runs `main.tscn` with that flag (parsed in `scripts/main.gd`; `--title-test` in
  `scripts/title_screen.gd`); anything else runs `res://tests/<file>` with
  `--script`. Every run is headless. `<fps>` adds `--fixed-fps`; `realtime` leaves it out (audio, the clock). The
  third argument is the timeout, 120 s by default. Log: `logs/<name>_<fps>fps.log` or `_realtime.log`; exit 1 on
  `SHADER ERROR` or `SCRIPT ERROR`, 124 on timeout. Godot: `GODOT`, the PATH, then `../Godot/` (`scripts/run-test.sh`).

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
bash scripts/run-test.sh --fire-test 60                # scripts/fire_test.gd (the campfire, the firelight)
bash scripts/run-test.sh --tent-test 60 300            # scripts/tent_test.gd (Dismantle the tent)
bash scripts/run-test.sh test_leaf_burst_config.gd 60  # tests/test_leaf_burst_config.gd (Effect A's settings)
bash scripts/run-test.sh --leaf-burst-test 60          # tests/leaf_burst_state_test.gd (Effect A's state)
bash scripts/run-test.sh test_campfire_smoke_config.gd 60  # tests/test_campfire_smoke_config.gd (Effect B's settings)
bash scripts/run-test.sh --smoke-test 60               # tests/campfire_smoke_state_test.gd (cold); also --smoke-load-test
bash scripts/run-test.sh cost_effects.gd 60 300        # tests/cost_effects.gd (the headless price)
bash scripts/run-test.sh --waves-test realtime         # scripts/waves_test.gd; fails 12 of 13 at 60 fps
bash scripts/run-test.sh --title-test realtime         # scripts/title_test.gd; fails 51 of 52 at 60 fps
```
- Counts (`TEST-REPORT.md`, 8 Nov 2026, `logs/a6-caught-sync/`): bubbles 87, camp 31, tasks 43, plan 19, tutorial 29;
  cones 43, cone shader 93 at 30, 60, 144; fire 23, tent 16, leaf burst state 37, smoke 20 and 8; waves 13/13 and
  title all in realtime; their `--fixed-fps` failures (12/13, 51/52) are expected: don't "fix" them.
## Headless facts
- A headless run uses a dummy renderer (it reports no video adapter): it draws no particles and runs no GPU
  particle process. Node state (emitting, one_shot, amount_ratio, visibility, instance counts) is observable; the
  look is not. On 4.7.2 a one-shot `GPUParticles3D` turns `emitting` off within a few frames and never emits
  `finished` (read back on 7 Nov 2026), so nothing may wait on `finished`: free a burst on a timer.
- A GPU effect's headless CPU price is near zero by construction.
- Frame strips come from a windowed Movie Maker run, which I start.
- Under `--fixed-fps`, game time follows frames, not the clock; physics runs at 60 ticks a second at every rate.
## Current change
@CHANGE-BRIEF.md

## Ownership
Every file in `shaders/` is hand-written by the human and is never edited by an agent: not
created, rewritten, reformatted or "fixed". If a shader looks wrong, report it and stop.

Effect settings live in scene files in `effects/` (`.tscn`, with their materials, curves and textures as
sub-resources or `.tres` beside them), not in code. Scripts may instance an effect, place it, set `amount_ratio`
(Effect A's hop-out; Effect B's feedback) and free it; they don't set `amount`, lifetimes, velocities, ramps or
materials. The brief's settings tables are the source of each value; a change to one starts as a dated revision
of `CHANGE-BRIEF.md`, made by the human.

## Godot 4 names
Use Godot 4 names only. Never Godot 3's: `Particles`, `ParticlesMaterial`, `CPUParticles` (no `3D`),
`SpatialMaterial`, `Spatial`, `flags_unshaded`, `params_billboard_mode`, `flags_transparent`.
- **Seen working on 4.7.2 in this repo:** `CPUParticles3D`, `StandardMaterial3D`, `BaseMaterial3D.SHADING_MODE_UNSHADED`,
  `.TRANSPARENCY_ALPHA`, `.BLEND_MODE_ADD`, `.BILLBOARD_PARTICLES`, `vertex_color_use_as_albedo`, `QuadMesh.size`
  (`scripts/campsite.gd`, the sparks); and Effect A's scene, `effects/leaf_burst.tscn`.
- **Read back from ClassDB on 4.7.2** (7 and 8 Nov, scratch scripts): `GPUParticles3D` has `amount`, `amount_ratio`,
  `one_shot`, `explosiveness`, `randomness`, `lifetime`, `preprocess`, `local_coords`, `visibility_aabb`,
  `process_material`, `draw_pass_1`, `emitting`, `use_fixed_seed`, `seed`, `restart()`, `finished`.
  `ParticleProcessMaterial` has `emission_shape` (`EMISSION_SHAPE_SPHERE`; `_BOX` = 3), `emission_sphere_radius`,
  `emission_box_extents`, `emission_shape_offset`, `direction`, `spread`, `initial_velocity_min`/`_max`, `gravity`,
  `damping_min`/`_max`, `angle_min`/`_max`, `scale_min`/`_max`, `scale_curve`, `alpha_curve`, `lifetime_randomness`,
  `color_ramp`, `color_initial_ramp` (ramps take a `GradientTexture1D`), `turbulence_enabled`, `turbulence_noise_`
  `strength`/`_scale`/`_speed`. `GradientTexture2D`: `fill` (`FILL_RADIAL` = 1), `gradient`, `width`, `height`.
  `StandardMaterial3D`: `albedo_texture`, `disable_fog`.
- Godot 3's `scale_random`, `flags_unshaded`, `params_billboard_mode` don't exist; `initial_velocity`, `scale` are editor pairs.
- The node's `randomness` (emission timing) is not the process material's `lifetime_randomness` (the brief's).

## Out of scope
- The raccoon's movement, collision, input and key bindings, including the dive, its hop and its timings.
- The campers: what they see, their states, routines and timings. The tutorial's steps and wording.
- Game code: the fire's life (`scripts/camp_fire.gd`), the keeper's tending, the bucket, the firelight, the tent,
  the developer menu. Beyond the 7 Nov wiring, the effects listen and read (`hiding_changed`, `strength`); they
  never write game state, and nothing in the game reads them.
- Every other look: the bush's rustle and peeking eyes, the fire's flames, light and sparks, cones, cooler, trees,
  icons, waves, and everything in `shaders/`.
- What any existing test expects. A test may change how it measures only with the same expected value.
- The renderer, `project.godot`, and the bush's and the fire pit's meshes, sizes and places. `Engine.time_scale`:
  only the tutorial changes it, while it holds the game (`scripts/camp_tutorial.gd`).

## Unconfirmed
- What `amount_ratio` 0.5 does to a one-shot burst's count on this build: headless reads only the value; the frame
  strip shows the count (`CHANGE-BRIEF.md`, short answer 1).
- Whether a hidden `GPUParticles3D` keeps simulating on this build: headless can't show it (Effect B, hidden).
- The counts above were measured on 8 Nov 2026 (`logs/a6-caught-sync/`); rerun before trusting. `run-test.sh`'s third
  argument is only the timeout, so `--*-shots=<folder>` options can't go through it.
