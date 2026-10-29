## Project context

- **Engine:** Godot 4.7 (`project.godot`, `config/features`); the build the scripts look for is
  4.7.2 stable (`scripts/run-test.sh`; `README.md`, "Run it"). GDScript throughout.
- **Renderer:** Forward+ (`project.godot`, `config/features`: `"Forward Plus"`). MSAA 3D is 4x (`project.godot`, `anti_aliasing/quality/msaa_3d`).
- **Main scene:** `res://main.tscn` (`project.godot`, `run/main_scene`), a single `Node3D` running
  `scripts/main.gd` (`main.tscn`). The project is the repo root, not `godot/`
  (`scripts/run-test.sh`, its header comment).

### The shaded object: each camper's vision cone
- One cone per camper: `camp_person.gd` makes a `VisionCone` as its `eyes` (`scripts/camp_person.gd`).
- The mesh is built in code by `_build_cone()` (`scripts/vision_cone.gd`): a fan of 24
  triangles laid 0.03 m above the ground, with vertex colours white, alpha
  0.55 at the camper and 0.12 at the far edge. No UVs are set.
- Drawn today with a `StandardMaterial3D` made in code, one per cone: unshaded, alpha
  transparency, vertex colour as albedo, no culling, fog disabled (`_build_cone()` in `scripts/vision_cone.gd`),
  set as the `MeshInstance3D`'s `material_override`.
- Its colour is set every physics frame: `SEEING` if `red()` else `WATCHING` (`_physics_process()`); the colours
  are `WATCHING` (1.0, 0.93, 0.62, 0.5) and `SEEING` (1.0, 0.33, 0.27, 0.65) (constants in `scripts/vision_cone.gd`).
- Shown or hidden through `show_on_ground()`, called from `_physics_process()` in `scripts/camp_person.gd`.
- The timing constants are `RED_TIME` 2.0, `FADE_OUT` 0.5 and `BACK_AFTER` 5.0 (`scripts/vision_cone.gd`).

### The game state that drives the effect
- Owned by `scripts/campsite.gd`: `clock` (advanced in `_physics_process()`),
  `spotted_at`, set by `spot()`, and `cones_shown_until()` = `spotted_at` +
  `RED_TIME` + `FADE_OUT`. `cones_on` gates the cones until the tutorial is done.
- `spot()` is called from `scripts/camp_person.gd`, in `_startle()`, `_search()` and `_return()`.
- Each cone also keeps its own `spotted_at` and `clock` (`scripts/vision_cone.gd`, set in `_physics_process()`);
  `red()` reads them.
- Nothing records *which* camper spotted him yet (`CHANGE-BRIEF.md`, "the script and variables that hold the state").

### The 3D object for the textured shader: the cooler
- `assets/props/cooler.glb` (`CHANGE-BRIEF.md`, "the material plan, for the cooler"). Copies of it:
  - at the camp, by `campsite.gd`: `COOLER` (`scripts/campsite.gd`), placed in `_ready()` through
    `_prop()`, which instances the scene with `_model()`;
  - in the asset room, node `Cooler` in `asset_room/asset_room.tscn`;
- **Where its material comes from:** the materials are embedded in the `.glb` and imported
  with it. `assets/props/cooler.glb.import` has `materials/extract=0` and `_subresources={}`,
  so nothing is external yet. The glb names three materials: `Cooler_Blue`, `Cooler_White`,
  `Cooler_Grey` (read from the glb's JSON chunk); `Cooler_Blue`'s `baseColorFactor` is
  (0.0437, 0.2051, 0.5210, 1). Tangents are built on import (`cooler.glb.import`,
  `meshes/ensure_tangents=true`).
- No game code recolours the cooler: `_recolor()` is called only for the second tent (`_ready()` in `scripts/campsite.gd`).
- Judging light: `asset_room/asset_room.tscn` has a Sun with `light_energy = 0.8`, as well as the
  Environment's `ambient_light_energy = 0.8` and `ssao_enabled = true`. The level's depth fog starts
  at 18 m (`fog_depth_begin` in `scripts/main.gd`).

### Tests: always through `scripts/run-test.sh <test> <fps>`, from the repo root
- An argument starting with `--` runs `main.tscn` with that flag; anything else runs
  `res://tests/<file>` with `--script` (`scripts/run-test.sh`). Every run is headless,
  with `--fixed-fps <fps>` and a 120 s `timeout`.
- The log goes to `logs/<name>_<fps>fps.log`. The exit is 1 if the log has `SHADER ERROR` or
  `SCRIPT ERROR`, and 124 if it hung.
- Godot is found from `GODOT`, then `godot` on the PATH, then two Windows paths.

```
bash scripts/run-test.sh a3_asset_check.gd 60   # tests/a3_asset_check.gd (extends SceneTree)
bash scripts/run-test.sh --cones-test 30        # scripts/cones_test.gd; the brief needs 30, 60 and 144
bash scripts/run-test.sh --cones-test 60
bash scripts/run-test.sh --cones-test 144
bash scripts/run-test.sh --sound-test 60        # scripts/sound_test.gd
bash scripts/run-test.sh --bubble-test 60       # scripts/bubble_test.gd
bash scripts/run-test.sh --camp-test 60         # scripts/camp_test.gd
bash scripts/run-test.sh --tasks-test 60        # scripts/tasks_test.gd
bash scripts/run-test.sh --waves-test 60        # scripts/waves_test.gd
bash scripts/run-test.sh --plan-test 60         # scripts/plan_test.gd
bash scripts/run-test.sh --title-test 60        # scripts/title_test.gd
```
The flags are parsed in `scripts/main.gd` (and described in its header comment); `--title-test` is parsed
in `scripts/title_screen.gd`. `cones_test.gd` quits 0 or 1 (`_finish()` in `scripts/cones_test.gd`).
The boundaries ask that each earlier check keeps its baseline at 60 fps, and the cones check
its 43 at 30, 60 and 144 (`CHANGE-BRIEF.md`, the evidence split's "The boundaries hold" row).

## Headless facts
- A headless run (`--headless`, which also picks the dummy audio driver) renders nothing, so no test here can show how anything looks: the look is checked by eye (`CHANGE-BRIEF.md`, the evidence split).
- `get_shader_uniform_list()` gives each uniform's name and type, not its default, so defaults are read from the shader's source. A shader that fails to parse gives an empty list, and `set_shader_parameter()` with a name the shader doesn't declare raises no error (`CHANGE-BRIEF.md`, the evidence split).
- Under `--fixed-fps`, game time follows frames, not the clock, so `--waves-test` (12 of 13) and `--title-test` (51 of 52) fail at 60 fps, as recorded (`TEST-REPORT.md`, the Assignment 5 baseline). Don't "fix" them.
- Physics runs at 60 ticks a second at every frame rate (`project.godot` sets no other), so at 144 fps a value set in `_physics_process()` changes only every 2 or 3 frames.

## Current change
@CHANGE-BRIEF.md

The current change is its "Assignment 5: shaders and materials" section, including every
dated "Revised 28 Oct 2026" part. Where a revision differs from earlier text, the revision wins.

## Ownership

Every file in `shaders/` is hand-written by the human and is never edited by an agent: not
created, rewritten, reformatted or "fixed". If a shader looks wrong, report it and stop.
The two lines in `fragment()` are fixed by the brief (`CHANGE-BRIEF.md`, "my colour line and see-through line"); any change to
them starts as a dated change to the brief, made by the human.

## Out of scope

- How the raccoon moves and collides, and which keys do what.
- The campers' behaviour and its timings: when they see him, guard, chase, shoo, search and walk
  back, and the existing timing constants. The one allowed addition is a record, made in
  `spot()`, of which camper spotted him.
- The direction of data: the driver reads `spotted_at` and that record and writes only the
  cones' uniforms. Presentation code never writes game state.
- `Engine.time_scale`: no game script changes it; only a test may.
- Every other look: trees, fire, icons, sound waves, the other shaders already in `scripts/`
  (`chalk`, `fire`, `see_through`), and the cooler's handle and posts (`Cooler_Grey`). Only the
  cones and the cooler's body (`Cooler_Blue`) and lid (`Cooler_White`) change.
- The expectations of every existing test.
- The renderer, the project settings, and the cooler's mesh, size and placement.

## Unconfirmed

- No test was run while writing this file, so the current pass or fail state and the baseline
  counts (including the cones check's 43) are taken from `CHANGE-BRIEF.md`'s evidence split, not measured.
- `run-test.sh` forwards only two arguments, so `a3_asset_check.gd -- --mutate` (`README.md`, its Assignment 3 section)
  and the `--*-shots=` options can't be run through it as it is.
- `shaders/`, `materials/` and `assets/textures/` don't exist yet. The shader and material paths
  are the brief's suggestions (`CHANGE-BRIEF.md`, "The effect" and the material plan).
- The exact `.import` keys for the per-material Use External setting on `cooler.glb` are unconfirmed.
- The Poly Haven texture set, its licence and its import settings haven't been checked. Nothing
  is downloaded.
- `tests/normal_map_check.gd` and the driver's test, named in the brief, don't exist yet.
