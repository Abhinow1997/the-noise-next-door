## Project context

- **Engine:** Godot 4.7.2 stable, GDScript; `config/features` is `"4.7"`, `"Forward Plus"` (`project.godot`); the
  wrapper looks for `Godot_v4.7.2-stable_win64_console.exe` (`scripts/run-test.sh:18`). The project is the repo root, so
  the course's `godot/shaders/`, `godot/animations/`, `godot/tests/` are `shaders/`, `animations/`, `tests/` here.
  Renderer Forward+, 1280 × 720, physics interpolation on (`project.godot`). No `animations/` folder exists yet.
- **Scene:** `res://main.tscn` (`run/main_scene`), one `Node3D` running `scripts/main.gd`, which adds `Campsite.new()`.

### The jump: imported 3D rig (`CHANGE-BRIEF.md`, "The two clips")
- **Rig:** `assets/characters/raccoon_v2.glb` (from `raccoon_v2.blend` by `assets/characters/export_raccoon_v2.py`; its
  actions keyed in `design/character/raccoon_v2/anim.py`). Import: `animation/fps=24`, `_subresources={}`
  (`raccoon_v2.glb.import:34,42`). Loaded by `_build_rigged()` (`scripts/raccoon_model.gd:375`); the model's scene is
  `raccoon_model.tscn`. The `AnimationPlayer` is found in the instanced rig (`raccoon_model.gd:384`) and held in `_anim`.
- **New clips** `jump` and `jump_land` go in the `.glb` as Blender actions (keyed in `anim.py`); loop modes go in the
  `.import`'s `_subresources`, replacing the runtime loop at `raccoon_model.gd:385-386`.
- **State machine:** the state lives in `scripts/player.gd` (`jump()` :431, `_jump_pose()` :440, `_end_jump()` :465,
  `jumping` :159, `signal landed` :13, the `JUMP_*`, `AIR_CONTROL`, `LAND_TIME` constants :93-100; `_physics_process()`
  :251 sets `model.jumping`). The clips are picked in `scripts/raccoon_model.gd`: `_process_rigged()` :460 →
  `_rigged_state()` :553 → `_change_animation()` :540. No `AnimationTree`.
- **His mouth:** `mouth`, a `Marker3D` on the `head` bone (`raccoon_model.gd:392-400`). **Readers of the jump:**
  `cone_driver.gd:96`; `_on_landed()` (`campsite.gd:539`, `HEAR_STEPS` 6 m); `tasks_test.gd:260-274`.

### The balloon's float: `Sprite3D` + `AnimationPlayer` frame track
- **Sheets:** `assets/sprites/balloons/balloon_{red_4,yellow,blue_4}.png` (also green, purple), 48 × 64 px, `hframes` 3,
  `vframes` 2; float cells 0–2, pop 3–5 (`assets/sprites/balloons/ATTRIBUTION.md`; CC-BY-SA 4.0, credit line there).
- **Placement:** by the party's `TABLE` and `SPEAKER` (`scripts/campsite.gd:81,83`); a pop heard `HEAR_CHITTER` 8 m (:105).
- **Moth (extra):** `assets/sprites/cutebugs/bugs.png` (`ATTRIBUTION.md` there, CC0), shown while `burning()`
  (`scripts/camp_fire.gd`). Both sheets have `detect_3d/compress_to=1` today (their `.png.import`, line 40).

### Tests: always `bash scripts/run-test.sh <test> <fps|realtime> [timeout-s]`, from the repo root
- `--name` runs `main.tscn` with that flag (parsed in `scripts/main.gd:399-470`); anything else runs `res://tests/<file>`
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
```
- The waves and title failures under `--fixed-fps` are expected: don't "fix" them. No Assignment 7 test exists yet.
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
- Every file in `shaders/` is hand-written by the human and is never edited by an agent: not created, rewritten,
  reformatted or "fixed". If a shader looks wrong, report it and stop.
- Clips live as resources: in `animations/` (`.tres`/`.res`), in the scene that owns them (the balloon's `.tscn`), or,
  for the rig, as actions in `raccoon_v2.glb` with import settings in its `.import`. Never built in code at runtime: no
  `Animation.new()`, `add_track()`, `track_insert_key()` or `loop_mode =` in game scripts.
- Assignment 6's effect settings stay in `effects/` scenes. The brief's tables are the source of every timing; a
  change starts as a dated revision of `CHANGE-BRIEF.md`, made by the human.

## One authority
Exactly one node writes to each animated node. Never add a second writer to one that already has one.
- **The rig's `AnimationPlayer`:** `scripts/raccoon_model.gd` only (`play()` :407, :548; `seek()` :493, :550; `speed_scale`
  :478). `player.gd` writes the model's inputs (`jumping`, `leap`, `squash`, `pitch`), never the player. During `jump`
  and `jump_land` the leap `seek()` (:479-493) must not run. `raccoon_flex.gd`, `raccoon_eat.gd` and the `TwoBoneIK3D`
  write bones after it, as `SkeletonModifier3D`s, by design; they never touch the `AnimationPlayer`.
- **Each balloon's `AnimationPlayer`:** that balloon's own script, its only caller of `play()`; the bite check asks it to pop.
- **The moths' `AnimationPlayer`:** their driver script; it reads `burning()`, writes nothing in the game.
- **Not this change's, already two writers:** the dancers' `AnimationPlayer`s are played by `scripts/camp_person.gd`
  (`_play()` :1008) and sought and sped by `scripts/campsite.gd` (:354-355, :617-623) for the beat. Leave as is; don't copy.

## Godot 4 names
Godot 4 only. Never Godot 3's: `Animation.loop` (a bool), `playback_speed`, `playback_process_mode`, `AnimatedSprite`,
`Spatial`, `Particles`, `SpatialMaterial`, `flags_unshaded`, `params_billboard_mode`, `flags_transparent`.
- **Seen working in this repo:** `AnimationPlayer` `play(name, blend)`, `seek(t, true)`, `speed_scale`,
  `current_animation`, `current_animation_position`, `current_animation_length`, `get_animation_list()`,
  `get_animation()`; `Animation.loop_mode`, `Animation.LOOP_LINEAR` (`raccoon_model.gd`). `Sprite3D` `pixel_size`,
  `billboard`, `alpha_cut` (`SpriteBase3D.ALPHA_CUT_*`), `texture_filter` (`BaseMaterial3D.TEXTURE_FILTER_*`) (`main.gd:1264-1275`).
- **Read back on 4.7.2 (the brief):** rig's `callback_mode_process` 1 (`ANIMATION_CALLBACK_MODE_PROCESS_IDLE`), `step` 1/24.
- **Not yet seen in this repo, believed Godot 4; read back from ClassDB before relying on them:** `Animation.LOOP_NONE`,
  `Animation.step`, `length`, `TYPE_VALUE`, `value_track_set_update_mode()`, `UPDATE_DISCRETE`, `track_get_path()`,
  `track_get_key_time()`, `Sprite3D.hframes`/`vframes`/`frame`, `TEXTURE_FILTER_NEAREST`, `AnimationLibrary`, and the
  glb importer's per-animation `settings/loop_mode` key in `_subresources`.

## Out of scope
- Movement, collision, input and key bindings, except the brief's two jump timings (takeoff 5 ticks after the press,
  a 10-tick landing). No new keys. The leap from the hollow and hops keep the run clip.
- The campers (sight, states, routines, timings, clips), the tutorial, the other tasks, the fire's life; `shaders/`,
  Assignment 6's effects, every other look; the renderer, `project.godot`; the seven raccoon clips' keys (only
  their loop mode moves, into the `.import`).
- What any existing test expects. A test may change how it measures only with the same expected value.
- Presentation reads game state and never writes it; the bite, the pops and the task are game code.

## Unconfirmed
- Whether the glb importer on 4.7.2 keeps `settings/loop_mode` per animation from `_subresources` after an empty-cache
  `--import`: the brief's prediction, not yet read back.
- How a continuous `frame` track rounds between keys (short answer 2); the one-tick (1/60 s) clock gap: unmeasured.
- Paths for the balloon and moth scenes and scripts and the Assignment 7 tests: in no file yet. `--jump-test`
  (`scripts/main.gd:412,766`) only presses jump for a screenshot; it checks nothing.
- Earlier counts were measured 11 Nov 2026 (`logs/a6-run-scribe-cones/`); rerun before trusting. `run-test.sh`'s
  third argument is only the timeout, so `--*-shots=<folder>` options can't go through it.
