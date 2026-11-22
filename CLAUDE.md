## Project context

- **Engine:** Godot 4.7.2 stable, GDScript; `config/features` is `"4.7"`, `"Forward Plus"` (`project.godot`); the
  wrapper looks for `Godot_v4.7.2-stable_win64_console.exe` (`scripts/run-test.sh:18`). The project is the repo root, so
  the course's `godot/shaders/`, `godot/animations/`, `godot/tests/` are `shaders/`, `animations/`, `tests/` here.
  Renderer Forward+, 1280 × 720, physics interpolation on (`project.godot`). `animations/` holds the moth's and the
  balloons' clips; the raccoon's are in his `.glb`.
- **Scene:** `res://main.tscn` (`run/main_scene`), one `Node3D` running `scripts/main.gd`, which adds `Campsite.new()`.

### The jump: imported 3D rig (`CHANGE-BRIEF.md`, "The two clips"; its phases from "the jump plays as it did before")
- **Rig:** `assets/characters/raccoon_v2.glb` (from `raccoon_v2.blend` by `assets/characters/export_raccoon_v2.py`; its
  actions keyed in `design/character/raccoon_v2/anim.py`; `anim_jump.py` rebuilds `jump` alone). Import:
  `animation/fps=24` (`raccoon_v2.glb.import:34`); every clip's loop mode is in `_subresources` (:42), under
  `"animations"`, the clip's name, `settings/loop_mode`. Nothing in code sets a loop mode. Loaded by `_build_rigged()`
  (`scripts/raccoon_model.gd:385`); the model's scene is `raccoon_model.tscn`. The `AnimationPlayer` is found in the
  instanced rig (:395) and held in `_anim`.
- **Nine clips** (`CLIPS`, `ONE_SHOTS`, `raccoon_model.gd:44-47`): the seven loops, `LOOP_LINEAR`; `jump` (10 frames,
  keys at 0, 3, 6, 10) and `jump_land` (4 frames), `LOOP_NONE`. Blended in over `JUMP_BLEND` 0.08 s (:40).
- **State machine:** the state lives in `scripts/player.gd` (`jump()` :436, `_jump_pose()` :445, `_end_jump()` :476,
  `jumping` :158, `signal landed` :13, the `JUMP_*`, `AIR_CONTROL`, `LAND_TIME` constants :96-103; `_physics_process()`
  :253 sets `model.jumping` and `model.landing` at :277-278; each takeoff adds one to `model.jump_id`; a hop off a tree
  is shown as a jump, `_show_tree_hop()` :847). The clips are picked in `scripts/raccoon_model.gd`: `_process_rigged()`
  :469 → `_rigged_state()` :558 → `_change_animation()` :543, against `assigned_animation` (:485). No `AnimationTree`.
- **Readers of the jump:** `cone_driver.gd:96`; `_on_landed()` (`campsite.gd:559`, `HEAR_STEPS` 6 m); `tasks_test.gd:267-281`.

### The moth's flutter (the graded sprite clip): `Sprite3D` + `AnimationPlayer` frame track
- **Sheet:** `assets/sprites/moth_lowpoly/moth_lowpoly.png` (the author's generated image beside it, made into the sheet
  by `tools/make_moth_sheet.gd`; `ATTRIBUTION.md` there), 512 × 512 cells, `hframes` 2, `vframes` 2, cells 0–3;
  `animations/moth_flutter.tres` (0, 1, 2, 3, 2, 1); one moth, `props/moths.tscn`, driver `props/moths.gd`.
- **Its job** ("he helps user navigate to the main area"): on a New Game it guides him from his tree to the camp
  (`guide()`, from `main.gd`, until "Investigate the music"), then it's over the fire while it's `burning()`.
- **Balloons (not graded):** 3D. `props/party_balloon.tscn`/`.gd` (`bob`, `inflate`), `props/balloon_bunch.tscn`
  (`float_away`), clips in `animations/`. The chair, the knot (E) and the release are in `scripts/camp_balloons.gd`.
  The task is "Let the balloons go", id `balloons`.

### Tests: always `bash scripts/run-test.sh <test> <fps|realtime> [timeout-s]`, from the repo root
- `--name` runs `main.tscn` with that flag (parsed in `scripts/main.gd:407-480`); anything else runs `res://tests/<file>`
  with `--script`. Headless. `<fps>` adds `--fixed-fps <fps>`; `realtime` omits it (audio, the clock). Timeout 120 s.
  Log `logs/<name>_<fps>fps.log` or `_realtime.log`; exit 1 on `SHADER ERROR`, `SCRIPT ERROR` or `Failed loading resource`, 124 on timeout.
```
bash scripts/run-test.sh a3_asset_check.gd 60          # tests/a3_asset_check.gd
bash scripts/run-test.sh normal_map_calibration.gd 60  # tests/normal_map_calibration.gd
bash scripts/run-test.sh test_materials.gd 60          # tests/test_materials.gd
bash scripts/run-test.sh test_leaf_burst_config.gd 60  # tests/test_leaf_burst_config.gd
bash scripts/run-test.sh test_campfire_smoke_config.gd 60  # tests/test_campfire_smoke_config.gd
bash scripts/run-test.sh cost_effects.gd 60 300        # tests/cost_effects.gd
bash scripts/run-test.sh --sound-test 60               # scripts/sound_test.gd
bash scripts/run-test.sh --bubble-test 60              # scripts/bubble_test.gd
bash scripts/run-test.sh --camp-test 60                # scripts/camp_test.gd (reads campers' current_animation)
bash scripts/run-test.sh --tasks-test 60               # scripts/tasks_test.gd (a jump's landing heard)
bash scripts/run-test.sh --plan-test 60                # scripts/plan_test.gd
bash scripts/run-test.sh --tutorial-test 60            # scripts/tutorial_test.gd
bash scripts/run-test.sh --cones-test 30               # scripts/cones_test.gd; also 60 and 144
bash scripts/run-test.sh --cone-shader-test 30         # tests/cone_shader_test.gd; also 60 and 144
bash scripts/run-test.sh --fire-test 60                # scripts/fire_test.gd
bash scripts/run-test.sh --tent-test 60 300            # scripts/tent_test.gd
bash scripts/run-test.sh --bearbag-test 60 300         # scripts/bear_bag_test.gd
bash scripts/run-test.sh --leaf-burst-test 60          # tests/leaf_burst_state_test.gd
bash scripts/run-test.sh --smoke-test 60               # tests/campfire_smoke_state_test.gd; also --smoke-load-test
bash scripts/run-test.sh --waves-test realtime         # scripts/waves_test.gd; under --fixed-fps one check fails
bash scripts/run-test.sh --title-test realtime         # scripts/title_test.gd; under --fixed-fps one check fails
bash scripts/run-test.sh test_raccoon_rig.gd 60        # tests/test_raccoon_rig.gd: the rig's read-back, nine clips
bash scripts/run-test.sh jump_pins.gd 60               # tests/jump_pins.gd: the jump's timing, pinned
bash scripts/run-test.sh test_jump_states.gd 60        # tests/test_jump_states.gd: the state machine, real input
bash scripts/run-test.sh test_jump_edges.gd 30         # tests/test_jump_edges.gd; also 60 and 144
bash scripts/run-test.sh test_moth_flutter.gd 60       # tests/test_moth_flutter.gd: the moth's read-back
bash scripts/run-test.sh test_moths_state.gd 60        # tests/test_moths_state.gd
bash scripts/run-test.sh test_moth_guide.gd 60         # tests/test_moth_guide.gd: the moth guiding him to the camp
bash scripts/run-test.sh test_balloon_3d.gd 60         # tests/test_balloon_3d.gd: the balloons' clips (not graded)
bash scripts/run-test.sh test_balloon_task.gd 60       # tests/test_balloon_task.gd: Let the balloons go
```
`tests/track_check.gd` is the course's track check, shared by the read-backs; it isn't run on its own.
- Baseline (21 Nov 2026, this wrapper): every test above passes at its 11 Nov count except `cost_effects.gd`, 3/4 (its
  smoke case finds the fire out; open). The waves and title `--fixed-fps` failures are expected: don't "fix" them.
  The Assignment 7 tests, all passing at `ab5de2b`: rig 51, pins 26, jump states 89, edges 239 at 30 fps and 238 at
  60 and 144, balloon 3D 35, balloon task 69 (about 30 s; the rest under 15 s). The moth's, on its new sheet (22 Nov):
  flutter 22, state 15.
## Headless facts
- A headless run uses a dummy renderer (no video adapter): no GPU particle process, so a GPU effect's CPU price is
  near zero. On 4.7.2 a one-shot `GPUParticles3D` never emits `finished` (7 Nov 2026): free a burst on a timer.
- A headless run advances clips and reads their structure. It draws nothing, so whether the motion reads is not
  observable here (seen 21 Nov 2026: a clip and the rig's `walk` moved their property and bone).
- Key times are 32-bit floats; compare them with a tolerance (21 Nov: 5/24 s reads back 0.2083333284 after a save).
- `value_track_get_update_mode` applies only to value tracks (21 Nov: on a bone track it prints an `ERROR`, which
  the wrapper doesn't catch, and answers `UPDATE_CONTINUOUS`).
- Frame strips come from a windowed Movie Maker run, which I start.
- Under `--fixed-fps`, game time follows frames, not the clock; physics runs at 60 ticks a second at every rate.
- A one-shot that has run out reads `current_animation` as `""`; `assigned_animation` keeps its name (21 Nov 2026).
- The glb importer keeps each clip's `settings/loop_mode` from `_subresources` after an empty-cache `--import`, and
  without it the loops import as `LOOP_NONE` (21 Nov 2026, `logs/a7-mutations/`, M4 and its contrast).
- The glb importer drops a key whose value its neighbours already give (21 Nov 2026: a shin within 0.04° of straight
  lost its frame-3 key), so the rig's read-back counts a track as held through a frame within 0.1°.
- The two clocks, measured (21 Nov 2026): the rig's clip changes one physics tick after the game, 0.017 s, for the
  jump at 60 and 144 fps and for a gait change at 60; for the jump at 30 fps, one or two ticks (up to 0.033 s).
- A `frame` track on continuous updates (22 Nov 2026, a scratch copy of the moth's clip): with nearest interpolation
  it shows the same as discrete; with linear, `frame` takes the nearest cell, so cells change halfway between keys and
  keys two cells apart show the cell between. So only the update-mode check catches it, not the picture.
## Current change
@CHANGE-BRIEF.md

## Ownership
- Every file in `shaders/` is hand-written by the human and is never edited by an agent: not created, rewritten,
  reformatted or "fixed". If a shader looks wrong, report it and stop.
- Clips live as resources: in `animations/` (`.tres`/`.res`), in the scene that owns them (the balloon's `.tscn`), or,
  for the rig, as actions in `raccoon_v2.glb` with import settings in its `.import`. Never built in code at runtime: no
  `Animation.new()`, `add_track()`, `track_insert_key()` or `loop_mode =` in game scripts.
- Assignment 6's effect settings stay in `effects/` scenes. The brief's tables are the source of every timing; a
  change starts as a dated revision of `CHANGE-BRIEF.md`, made by the human.

## One authority
Exactly one node writes to each animated node. Never add a second writer to one that already has one.
- **The rig's `AnimationPlayer`:** `scripts/raccoon_model.gd` only (`play()` :416, :551; `seek()` :498, :555; `speed_scale`
  :493). `player.gd` writes the model's inputs (`jumping`, `landing`, `jump_id`, `leap`, `squash`, `pitch`), never the
  player. During `jump` and `jump_land` the leap `seek()` (:496-498, `not jumping`) doesn't run. `raccoon_flex.gd`,
  `raccoon_eat.gd` and the `TwoBoneIK3D` write bones after it, as `SkeletonModifier3D`s, by design; they never touch
  the `AnimationPlayer`.
- **Each balloon's `AnimationPlayer`:** that balloon's own script (`props/party_balloon.gd`), its only caller of
  `play()` and `seek()`. **The bunch's:** `scripts/camp_balloons.gd`, which plays `float_away` once on release.
- **The moth's `AnimationPlayer`:** its driver, `props/moths.gd`, which plays `flutter` and seeks it half a frame in;
  it reads `burning()`, writes nothing in the game.
- **Not this change's, already two writers:** the dancers' `AnimationPlayer`s are played by `scripts/camp_person.gd`
  (`_play()` :1080) and sought and sped by `scripts/campsite.gd` (:358-359, :643) for the beat. Leave as is; don't copy.

## Godot 4 names
Godot 4 only. Never Godot 3's: `Animation.loop` (a bool), `playback_speed`, `playback_process_mode`, `AnimatedSprite`,
`Spatial`, `Particles`, `SpatialMaterial`, `flags_unshaded`, `params_billboard_mode`, `flags_transparent`.
- **Seen working in this repo:** `AnimationPlayer` `play(name, blend)`, `seek(t, true)`, `speed_scale`,
  `current_animation`, `assigned_animation`, `current_animation_position`, `current_animation_length`, `get_animation_list()`,
  `get_animation()`; `Animation.loop_mode`, `Animation.LOOP_LINEAR` (`raccoon_model.gd`). `Sprite3D` `pixel_size`,
  `billboard`, `alpha_cut` (`SpriteBase3D.ALPHA_CUT_*`), `texture_filter` (`BaseMaterial3D.TEXTURE_FILTER_*`) (`main.gd:1289-1298`).
- **Read back on 4.7.2** (the brief; ClassDB and scratch checks, 21 Nov 2026): the rig's `callback_mode_process` 1
  (`ANIMATION_CALLBACK_MODE_PROCESS_IDLE`) and `step` 1/24; `Animation.LOOP_NONE`/`LOOP_LINEAR`/`LOOP_PINGPONG`, `step`,
  `length`, `TYPE_VALUE`, `TYPE_POSITION_3D`, `value_track_set_update_mode()`/`get`, `UPDATE_DISCRETE`, `track_get_path()`,
  `track_get_key_time()`, `AnimationLibrary`; `Sprite3D.hframes`/`vframes`/`frame`; `TEXTURE_FILTER_NEAREST`.

## Out of scope
- Movement, collision, input and key bindings. The jump's movement is the game's own (`dc8ff17`): takeoff on the tick
  F is seen, a 12-tick landing (`LAND_TIME` 0.2 s). No new keys; the one input change is F waking him in the hollow
  into the leap out, as a move key does. The leap out of the hollow, the bush's dive and hop, the startle's leaps and
  the rest spot's hops keep the run clip; only a hop off a tree is shown with `jump` and `jump_land`.
- The campers (sight, states, routines, timings, clips), except the brief's two named changes: the girl's balloon step
  after warming her hands, and the balloons gone as one new trigger for reactions they already have. The tutorial,
  the other tasks, the fire's life; `shaders/`, Assignment 6's effects, every other look; the renderer,
  `project.godot`; the seven raccoon clips' keys (only their loop mode moved, into the `.import`).
- What any existing test expects, unless a revision of the brief names the change. A test may change how it measures
  only with the same expected value.
- Presentation reads game state and never writes it; the knot, the release, the girl's call and the task are game code.

## Unconfirmed
- How each clip reads in motion, and every seam over five wraps: the author's eyes, in play and in the previews
  (`previews/raccoon_loops_preview.tscn`, `previews/jump_preview.tscn`), not yet written in TEST-REPORT.md.
- `--jump-test` (`scripts/main.gd:420,789-793`) only presses jump for a screenshot; it checks nothing.
- `run-test.sh`'s third argument is only the timeout, so `--*-shots=<folder>` options can't go through it.
