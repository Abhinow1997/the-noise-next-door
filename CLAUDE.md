## Project context

- **Engine:** Godot 4.7.2 stable, GDScript; `config/features` `"4.7"`, `"Forward Plus"`; 1280 × 720, physics interpolation
  on (`project.godot`). The wrapper looks for `Godot_v4.7.2-stable_win64_console.exe` (`scripts/run-test.sh:18`). The
  project is the repo root, so the course's `godot/shaders/`, `animations/`, `tests/` are `shaders/`, `animations/`
  (the moth's and balloons' clips; the raccoon's are in his `.glb`), `tests/`.
- **Scene:** `res://main.tscn` (`run/main_scene`), one `Node3D` running `scripts/main.gd`, which adds `Campsite.new()`.

### The jump: imported 3D rig (`CHANGE-BRIEF.md`, "The two clips"; its phases from "the jump plays as it did before")
- **Rig:** `assets/characters/raccoon_v2.glb` (from `raccoon_v2.blend` by `assets/characters/export_raccoon_v2.py`;
  actions in `design/character/raccoon_v2/anim.py`; `anim_jump.py` rebuilds `jump` alone). Import: `animation/fps=24`
  (`raccoon_v2.glb.import:34`); each clip's loop mode in `_subresources` (:42) → `"animations"` → its name →
  `settings/loop_mode`; nothing in code sets one. Loaded by `_build_rigged()` (`scripts/raccoon_model.gd:385`); scene
  `raccoon_model.tscn`; its `AnimationPlayer` found in the instanced rig (:395), held in `_anim`.
- **Nine clips** (`CLIPS`, `ONE_SHOTS`, `raccoon_model.gd:44-47`): the seven loops `LOOP_LINEAR`; `jump` (10 frames, keys
  0, 3, 6, 10) and `jump_land` (4 frames) `LOOP_NONE`, blended in over `JUMP_BLEND` 0.08 s (:40).
- **State machine:** in `scripts/player.gd` (`jump()` :436, `_jump_pose()` :445, `_end_jump()` :476, `jumping` :158,
  `signal landed` :13, `JUMP_*`/`AIR_CONTROL`/`LAND_TIME` :96-103; `_physics_process()` :253 sets `model.jumping` and
  `model.landing` :277-278; each takeoff adds one to `model.jump_id`; a tree hop shows as a jump, `_show_tree_hop()` :847).
  Clips picked in `raccoon_model.gd`: `_process_rigged()` :469 → `_rigged_state()` :558 → `_change_animation()` :543,
  against `assigned_animation` (:485). No `AnimationTree`. Read by `cone_driver.gd:96`, `_on_landed()` (`campsite.gd:581`,
  `HEAR_STEPS` 6 m) and `scripts/tasks_test.gd:268-285`.

### The moth's flutter (the graded sprite clip): `Sprite3D` + `AnimationPlayer` frame track
- **Sheet:** `assets/sprites/moth_lowpoly/moth_lowpoly.png` (the author's generated image beside it, made the sheet by
  `tools/make_moth_sheet.gd`; `ATTRIBUTION.md` there), 512 × 512 cells, `hframes` 2 × `vframes` 2, cells 0–3;
  `animations/moth_flutter.tres` (0, 1, 2, 3, 2, 1); one moth, `props/moths.tscn`, driver `props/moths.gd`.
- **Its job** ("he helps user navigate to the main area"): on a New Game it guides him from his tree to the camp
  (`guide()`, from `main.gd`, until "Investigate the music"), then it's over the fire while it's `burning()`.
- **Balloons (not graded):** 3D, `props/party_balloon.tscn`/`.gd` (`bob`, `inflate`), `props/balloon_bunch.tscn`
  (`float_away`), clips in `animations/`; chair, knot (E) and release in `scripts/camp_balloons.gd`; task `balloons`.

### Tests: always `bash scripts/run-test.sh <test> <fps|realtime> [timeout-s]`, from the repo root
- `--name` runs `main.tscn` with that flag (parsed in `scripts/main.gd:410-483`): `--x-test` runs `scripts/x_test.gd`
  (`--bearbag-test` `bear_bag_test.gd`; `--leaf-burst-test`, `--smoke-test`, `--smoke-load-test` and `--cone-shader-test`
  `tests/leaf_burst_state_test.gd`, `campfire_smoke_state_test.gd`, `cone_shader_test.gd`). Anything else runs
  `res://tests/<file>` with `--script`. Headless; `<fps>` adds `--fixed-fps <fps>`, `realtime` omits it (audio, the
  clock); timeout 120 s; log `logs/<name>_<fps>fps.log` or `_realtime.log`; exit 1 on `SHADER ERROR`, `SCRIPT ERROR`
  or `Failed loading resource`, 124 on timeout. `tests/track_check.gd` is a shared helper, not run on its own.
```
bash scripts/run-test.sh <test> 60  # each: a3_asset_check.gd normal_map_calibration.gd test_materials.gd test_raccoon_rig.gd
  # test_leaf_burst_config.gd test_campfire_smoke_config.gd jump_pins.gd test_jump_states.gd test_moth_flutter.gd
  # test_moths_state.gd test_moth_guide.gd test_balloon_3d.gd test_balloon_task.gd --sound-test --bubble-test --camp-test
  # --tasks-test --plan-test --tutorial-test --fire-test --leaf-burst-test --smoke-test --smoke-load-test
bash scripts/run-test.sh cost_effects.gd 60 300   # also --tent-test and --bearbag-test, with 300
bash scripts/run-test.sh --cones-test 30          # and 60, 144; so too --cone-shader-test and test_jump_edges.gd
bash scripts/run-test.sh --waves-test realtime    # and --title-test; under --fixed-fps each fails one check: expected
```
- **Baseline** (22 Nov, `logs/a7-baseline-final/`, `160c0eb`): earlier tests at 11 Nov counts but waves 15, `cost_effects`
  3/4 (fire out; open). A7: rig 51, pins 26, states 89, edges 239/238/238, moth 22, moths 15, guide 9, balloons 35, 71.
## Headless facts
- Headless is a dummy renderer: no GPU particle process (a GPU effect's CPU price is near zero), and on 4.7.2 a one-shot
  `GPUParticles3D` never emits `finished` (7 Nov 2026): free a burst on a timer.
- A headless run advances clips and reads their structure. It draws nothing, so whether the motion reads is not
  observable here (seen 21 Nov 2026: a clip and the rig's `walk` moved their property and bone).
- Key times are 32-bit floats; compare them with a tolerance (21 Nov: 5/24 s reads back 0.2083333284 after a save).
- `value_track_get_update_mode` applies only to value tracks (21 Nov: on a bone track it prints an `ERROR`, which
  the wrapper doesn't catch, and answers `UPDATE_CONTINUOUS`).
- Frame strips come from a windowed Movie Maker run, which I start.
- Under `--fixed-fps`, game time follows frames, not the clock; physics runs at 60 ticks a second at every rate.
- A one-shot that has run out reads `current_animation` as `""`; `assigned_animation` keeps its name (21 Nov 2026).
- The glb importer keeps each clip's `settings/loop_mode` from `_subresources` after an empty-cache `--import`; without
  it the loops import as `LOOP_NONE` (21 Nov, `logs/a7-mutations/`, M4 and its contrast). It drops a key its neighbours
  already give (a shin within 0.04° of straight lost its frame-3 key), so the rig's read-back allows 0.1° for a hold.
- The two clocks, measured (21 Nov): the rig's clip changes one physics tick (0.017 s) after the game, for the jump at
  60 and 144 fps and a gait change at 60; for the jump at 30 fps, one or two ticks (up to 0.033 s).
- A `frame` track on continuous updates (22 Nov, a scratch copy of the moth's clip): with nearest interpolation it shows
  the same as discrete; with linear, cells change halfway between keys. Only the update-mode check catches it.
## Current change
@CHANGE-BRIEF.md

## Ownership
- Every file in `shaders/` is hand-written by the human and is never edited by an agent: not created, rewritten,
  reformatted or "fixed". If a shader looks wrong, report it and stop.
- Clips live as resources: in `animations/` (`.tres`/`.res`), in the scene that owns them, or, for the rig, as actions
  in `raccoon_v2.glb` with import settings in its `.import`. Never built in code at runtime: no `Animation.new()`,
  `add_track()`, `track_insert_key()` or `loop_mode =` in game scripts.
- Assignment 6's effect settings stay in `effects/` scenes. The brief's tables are the source of every timing; a change
  starts as a dated revision of `CHANGE-BRIEF.md`, made by the human.

## One authority
Exactly one node writes to each animated node. Never add a second writer to one that already has one.
- **The rig's `AnimationPlayer`:** `scripts/raccoon_model.gd` only (`play()` :416, :551; `seek()` :498, :555;
  `speed_scale` :493). `player.gd` writes the model's inputs (`jumping`, `landing`, `jump_id`, `leap`, `squash`,
  `pitch`), never the player. In `jump` and `jump_land` the leap `seek()` (:496-498, `not jumping`) doesn't run.
  `raccoon_flex.gd`, `raccoon_eat.gd` and the `TwoBoneIK3D` write bones after it as `SkeletonModifier3D`s, by design.
- **Each balloon's:** its own script (`props/party_balloon.gd`). **The bunch's:** `scripts/camp_balloons.gd`
  (`float_away`, once). **The moth's:** `props/moths.gd`: plays `flutter`, seeks it half a frame in, writes no game state.
- **Not this change's, already two writers:** the dancers' players, played by `scripts/camp_person.gd` (`_play()`
  :1080) and sought and sped by `scripts/campsite.gd` (:361-362, :665) for the beat. Leave as is; don't copy.

## Godot 4 names
Godot 4 only. Never Godot 3's: `Animation.loop` (a bool), `playback_speed`, `playback_process_mode`, `AnimatedSprite`,
`Spatial`, `Particles`, `SpatialMaterial`, `flags_unshaded`, `params_billboard_mode`, `flags_transparent`.
- **Seen working in this repo:** `AnimationPlayer` `play(name, blend)`, `seek(t, true)`, `speed_scale`,
  `current_animation`, `assigned_animation`, `current_animation_position`, `current_animation_length`,
  `get_animation_list()`, `get_animation()`; `Animation.loop_mode`, `LOOP_LINEAR` (`raccoon_model.gd`); `Sprite3D`
  `pixel_size`, `billboard`, `alpha_cut` (`SpriteBase3D.ALPHA_CUT_*`), `texture_filter` (`main.gd:1297-1306`).
- **Read back on 4.7.2** (ClassDB, scratch checks, 21 Nov 2026): the rig's `callback_mode_process` 1 (`..._PROCESS_IDLE`)
  and `step` 1/24; `LOOP_NONE`/`LOOP_LINEAR`/`LOOP_PINGPONG`, `length`, `TYPE_VALUE`, `TYPE_POSITION_3D`,
  `value_track_set_update_mode()`/`get`, `UPDATE_DISCRETE`, `track_get_path()`, `track_get_key_time()`,
  `AnimationLibrary`; `Sprite3D.hframes`/`vframes`/`frame`; `TEXTURE_FILTER_NEAREST`.

## Out of scope
- Movement, collision, input and keys. The jump moves as the game's own (`dc8ff17`): takeoff on the tick F is seen, a
  12-tick landing (`LAND_TIME` 0.2 s). The one input change: F wakes him in the hollow into the leap out. The other leaps
  and hops keep the run clip; only a hop off a tree shows `jump` and `jump_land`.
- The campers, except the brief's named changes (the girl's balloon step after warming her hands, then her `sit` on the
  chair; the balloons gone as a trigger for reactions they already have). The tutorial, the other tasks, the fire's life;
  `shaders/`, Assignment 6's effects, every other look except the named ones (the moth's guide, the waves' bursts); the
  renderer, `project.godot`; the seven raccoon clips' keys (only their loop mode moved, into the `.import`).
- What any existing test expects, unless a revision of the brief names the change. A test may change how it measures
  only with the same expected value.
- Presentation reads game state and never writes it; the knot, the release, the girl's call and the task are game code.

## Unconfirmed
- Both clips against the darkest and lightest ground, and the new moth's registration by eye: the author's, still to do.
- `--jump-test` (`scripts/main.gd:423,797-800`) only presses jump for a screenshot; it checks nothing.
- `run-test.sh`'s third argument is only the timeout, so `--*-shots=<folder>` options can't go through it.
