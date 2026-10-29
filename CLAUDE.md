## Project context

- **Engine:** Godot 4.7 (`project.godot:15`, `config/features`); the build the scripts look for is
  4.7.2 stable (`scripts/run-test.sh:13`, `README.md:21`). GDScript throughout.
- **Renderer:** Forward+ (`project.godot:15`, `"Forward Plus"`). MSAA 3D is 2x (`project.godot:28`).
- **Main scene:** `res://main.tscn` (`project.godot:14`), a single `Node3D` running
  `scripts/main.gd` (`main.tscn:3-6`). The project is the repo root, not `godot/`
  (`scripts/run-test.sh:4`).

### The shaded object: each camper's vision cone
- One cone per camper: `camp_person.gd` makes a `VisionCone` as its `eyes` (`scripts/camp_person.gd:177`).
- The mesh is built in code by `_build_cone()` (`scripts/vision_cone.gd:137-164`): a fan of 24
  triangles (`:141`) laid 0.03 m above the ground (`:140`), with vertex colours white, alpha
  0.55 at the camper and 0.12 at the far edge (`:146-151`). No UVs are set.
- Drawn today with a `StandardMaterial3D` made in code, one per cone: unshaded, alpha
  transparency, vertex colour as albedo, no culling, fog disabled (`scripts/vision_cone.gd:152-158`),
  set as the `MeshInstance3D`'s `material_override` (`:161`).
- Its colour is set every physics frame: `SEEING` if `red()` else `WATCHING` (`:73`); the colours
  are `WATCHING` (1.0, 0.93, 0.62, 0.5) and `SEEING` (1.0, 0.33, 0.27, 0.65) (`:31-32`).
- Shown or hidden through `show_on_ground()` (`:117-119`), called from `scripts/camp_person.gd:242`.
- The timing constants are `RED_TIME` 2.0, `FADE_OUT` 0.5 and `BACK_AFTER` 5.0 (`scripts/vision_cone.gd:26-28`).

### The game state that drives the effect
- Owned by `scripts/campsite.gd`: `clock` (`:200`, advanced in `_physics_process`, `:327`),
  `spotted_at` (`:212`), set by `spot()` (`:371-374`), and `cones_shown_until()` = `spotted_at` +
  `RED_TIME` + `FADE_OUT` (`:378-379`). `cones_on` gates the cones until the tutorial is done (`:211`).
- `spot()` is called from `scripts/camp_person.gd:385`, `:527` and `:542`.
- Each cone also keeps its own `spotted_at` and `clock` (`scripts/vision_cone.gd:41-42`, `:61`, `:68`);
  `red()` reads them (`:83-84`).
- Nothing records *which* camper spotted him yet (`CHANGE-BRIEF.md:723-727`).

### The 3D object for the textured shader: the cooler
- `assets/props/cooler.glb` (`CHANGE-BRIEF.md:649`). Copies of it:
  - at the camp, by `campsite.gd`: `COOLER` (`scripts/campsite.gd:53`), placed at `:249` through
    `_prop()` (`:601-609`), which instances the scene with `_model()` (`:630-633`);
  - in the asset room, `asset_room/asset_room.tscn:5` and node `Cooler` at `:71`;
  - in the bubble demo yard (`scripts/bubble_demo.gd:17`);
  - loaded and measured by `tests/a3_asset_check.gd:29`.
- **Where its material comes from:** the materials are embedded in the `.glb` and imported
  with it. `assets/props/cooler.glb.import` has `materials/extract=0` and `_subresources={}`,
  so nothing is external yet. The glb names three materials: `Cooler_Blue`, `Cooler_White`,
  `Cooler_Grey` (read from the glb's JSON chunk); `Cooler_Blue`'s `baseColorFactor` is
  (0.0437, 0.2051, 0.5210, 1). Tangents are built on import (`cooler.glb.import`,
  `meshes/ensure_tangents=true`).
- No game code recolours the cooler: `_recolor()` is called only for the second tent (`scripts/campsite.gd:244`).
- Judging light: the asset room's `Environment` has `ambient_light_energy = 0.8` (`asset_room/asset_room.tscn:25`)
  and `ssao_enabled = true` (`:26`). The level's depth fog starts at 18 m (`scripts/main.gd:894`).

### Tests: always through `scripts/run-test.sh <test> <fps>`, from the repo root
- An argument starting with `--` runs `main.tscn` with that flag; anything else runs
  `res://tests/<file>` with `--script` (`scripts/run-test.sh:18-24`). Every run is headless,
  with `--fixed-fps <fps>` and a 120 s `timeout`.
- The log goes to `logs/<name>_<fps>fps.log`. The exit is 1 if the log has `SHADER ERROR` or
  `SCRIPT ERROR` (`:26`), and 124 if it hung (`:9`).
- Godot is found from `GODOT`, then `godot` on the PATH, then two Windows paths (`:12-16`).

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
The flags are parsed in `scripts/main.gd:338-368` (described at `:11-30`); `--title-test` is parsed
in `scripts/title_screen.gd:82`. `cones_test.gd` quits 0 or 1 (`scripts/cones_test.gd:313`).
The boundaries ask that each earlier check keeps its baseline at 60 fps, and the cones check
its 43 at 30, 60 and 144 (`CHANGE-BRIEF.md:629`).

## Current change
@CHANGE-BRIEF.md

The current change is its "Assignment 5: shaders and materials" section, including every
dated "Revised 28 Oct 2026" part. Where a revision differs from earlier text, the revision wins.

## Ownership

Every file in `shaders/` is hand-written by the human and is never edited by an agent: not
created, rewritten, reformatted or "fixed". If a shader looks wrong, report it and stop.
The two lines in `fragment()` are fixed by the brief (`CHANGE-BRIEF.md:737-742`); any change to
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
  counts (including the cones check's 43) are taken from `CHANGE-BRIEF.md:629`, not measured.
- README runs `camp`, `tasks`, `waves` and `plan` with `--audio-driver Dummy` (`README.md:46-52`).
  `run-test.sh` doesn't pass it. Whether they pass without it is unconfirmed.
- `run-test.sh` forwards only two arguments, so `a3_asset_check.gd -- --mutate` (`README.md:203`)
  and the `--*-shots=` options can't be run through it as it is.
- `shaders/`, `materials/` and `assets/textures/` don't exist yet. The shader and material paths
  are the brief's suggestions (`CHANGE-BRIEF.md:463`, `:692`).
- The exact `.import` keys for the per-material Use External setting on `cooler.glb` are unconfirmed.
- The asset room's sun energy (0.8, `CHANGE-BRIEF.md:651`) wasn't found in `asset_room.tscn`.
  Only the ambient energy was. It may be set in `asset_room/asset_room.gd`.
- The Poly Haven texture set, its licence and its import settings haven't been checked. Nothing
  is downloaded.
- `tests/normal_map_check.gd` and the driver's test, named in the brief, don't exist yet.
- Whether Godot and `timeout` are on this machine's PATH for `run-test.sh` is unconfirmed.
