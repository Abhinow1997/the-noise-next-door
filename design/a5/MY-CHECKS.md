# My checks for Assignment 5

The checks only I can do, in order. Each says what to record. I tell Claude Code the results, and it writes them up as mine. (Written by Claude Code on 29 Oct 2026, from the course's Step 3, Step 4 and "Use It", and my brief.)

In Git Bash, from the repo root, first:

```bash
GODOT="/c/Users/dotbix/AppData/Local/Programs/Godot/Godot_v4.7.2-stable_win64_console.exe"
```

## 1. Now

- [x] **Commit my hint shader** (unless I've asked Claude Code to): `git add shaders/hint_experiment.gdshader shaders/hint_experiment.gdshader.uid && git commit -m "Add hint experiment shader"`
- [x] **Hint experiment (HUMAN CHECK):** `"$GODOT" --path . --script "$(pwd)/design/a5/captures/read_bands.gd"`. It saves `design/a5/captures/hint/bands.png` and `bands.txt`, with each band's pixel beside my prediction. Record: does each band match, within 2 steps? If not, check my known power slip first (the brief's hint predictions).

## 2. Any time, even while Claude Code's runs go (nothing to save)

- [ ] **In play (HUMAN CHECK):** from a normal start, 3 more spottings (my brief asks for at least five, and two are recorded). For each: which cones turned red, how the fade looked, when the cones came back, and any re-spotting.
- [ ] **Also in play:**
  - a cone coming back about 5 s after its camper walks back, fading in over 0.5 s;
  - two cones overlapping during a red: does it flicker?
  - all three cones appearing at the tutorial's end, with no fade-in;
  - the boundaries: he moves and the campers behave as before, and only the cones and the cooler look different;
  - the bubble demo's cone still turns red.

## 3. In the editor, while no run of Claude Code's is going (save nothing)

Look in the editor's 3D view, not a run: running from the editor saves the scene first.

- [ ] **The cooler under its light:** open `asset_room/asset_room.tscn` and turn the Environment's SSAO off. The body should read as scuffed painted metal, and the lid as smoother white plastic. Then one look at the camp at night, in play.
- [ ] **Interface sweep (HUMAN CHECK):** on `materials/cooler_body.tres`, each uniform at its minimum, the shader's default and its maximum: `detail` 0 / 0.5 / 1, `uv_scale` 0.25 / 1 / 4, `roughness_scale` 0 / 1 / 1, `normal_strength` 0 / 1 / 2, and `tint` black and white. Record what changed, and any setting that breaks the look.
- [ ] **One shader, two materials (HUMAN CHECK):** a capture of the body and the lid side by side. Edit one line of `shaders/cooler_paint.gdshader`: both should change. Edit one value in `materials/cooler_lid.tres`: only the lid should change. Undo both.
- [ ] **After closing the editor:** `git status`. If any `.import`, `.tres` or `.tscn` changed, tell Claude Code: the course wants any rewritten `.import` explained. `git diff -- shaders/ materials/` must be empty.

## 4. After Claude Code says the audit's test is in

- [ ] **The `source_color` mutation:** delete `source_color` from `albedo_texture` in `shaders/cooler_paint.gdshader` and save. Run `bash scripts/run-test.sh test_materials.gd 60; echo "exit $?"`: it must exit 1. Copy `logs/test_materials_60fps.log` to `logs/mutation-source-color_60fps.log`, then `git checkout -- shaders/cooler_paint.gdshader logs/test_materials_60fps.log`. `git diff -- shaders/` must be empty.

## 5. Step 4: reading the language (mine to write; the spec's Step 4 has the exact wording)

- [ ] In a scratch scene, not saved in the repo, make a StandardMaterial3D with the Blue Metal Plate albedo, normal map and roughness textures enabled. Make it unique, then convert it to a ShaderMaterial from the Inspector's resource menu. Save the code as `shaders/standard_generated.gdshader`, and annotate it.
- [ ] `LANGUAGE-NOTES.md`, part 1: the line numbers in that file of `shader_type` and `render_mode`; the uniforms for the albedo colour and the normal-map strength; the albedo and normal-map samplers, with their hints; and the lines that write `ALBEDO`, `ROUGHNESS` and `NORMAL_MAP`.
- [ ] Part 2: the eight questions, in my own words, each with a line reference to one of my three shaders:
  - what `shader_type` decides;
  - which processor functions I wrote and when each runs, and what moving my colour line into `vertex()` would change;
  - three built-ins I read and two I wrote, and which are read-only;
  - what each hint changes (cite my hint experiment);
  - whether `hint_range` clamps (cite my 2.0 capture);
  - the generated line that samples the albedo as colour and the normal map as data, and mine;
  - why `fragment()` can't read a neighbour, and how game state reaches it;
  - two things the language gives that GLSL doesn't.

## 6. The film, last

- [ ] One landscape film, made with the course's Brutalist godot-gamedev skill and its walker modifier. The skill isn't installed on this machine, so I request it from the course. Its shader shots must be real engine output on my display. Its link, filename and SHA-256 go in the README and SUBMISSION.md.
