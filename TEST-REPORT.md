# Test report: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 7: animation

What Assignment 7's work is tested for, how, and what actually happened. Each run gives its source revision, the Godot version (4.7.2 stable) and the renderer (Forward+ in a window; headless runs use the dummy renderer, which draws nothing). As with CHANGE-BRIEF.md, this file holds only the current assignment. The earlier reports are in history.

## The earlier assignments

| Assignment | What was tested | Where it is |
|---|---|---|
| 2: the asset slice | Startup and controls, the character against its sheet, the storyboard, sound, music, muted play, the playtest and the automated check | `TEST-REPORT.md` at tag `a2` (`2da6991`) |
| 3: the three Blender assets | The s'more, the pizza slice and the cooler in Godot: the asset check and the look in the asset room | `TEST-REPORT.md` at tag `a3` (`c729e53`) |
| 5: shaders and materials | The vision cone's shader, the cooler's materials and the normal-map check, with their mutations | `TEST-REPORT.md` at tag `a5` (`62ee5fb`) |
| 6: particle effects, and the bigger camp | The leaf burst and the campfire smoke (settings, state, price, GPU time, mutations, strips and play), and the camp's game checks | `TEST-REPORT.md` at tag `a6` (`1578035`). The game work after it (Raid the bear bag, the music from the speaker, the run back, calmer cones) is at `dc8ff17`, the last commit before Assignment 7 |

Their logs stay in `logs/` where those reports cite them: Assignment 6's are in the `logs/a6-*/` folders.

**The last counts before Assignment 7** (11 Nov 2026, `logs/a6-run-scribe-cones/`), through Assignment 6's wrapper: bubbles 87, camp 31, tasks 48, plan 22, tutorial 34; cones 43 at 30, 60 and 144; cone shader 93 at 60 (and at 30 and 144 on 10 Nov, `logs/a6-bearbag/`); fire 25, tent 16, bear bag 41, leaf burst state 37, smoke 20 and 8; sound 30; waves 14/14 and title 53/53 in realtime. Their `--fixed-fps` runs fail one check each (13/14, 52/53), which is expected. Assignment 7's baseline reruns every test through its own wrapper.

---

## Assignment 7: animation

Every run here is Godot 4.7.2 stable. Headless runs use the dummy renderer, which draws nothing. The captures are windowed Forward+ at 1280 × 720, made by me with Movie Maker. Each entry names its source revision. The clips are the jump (`jump` and `jump_land`, the imported rig, committing) and the moth's flutter (a `Sprite3D` frame track, looping), as CHANGE-BRIEF.md's revisions have them. The moth's job: "he helps user navigate to the main area". On a New Game it guides him from his tree to the camp, then it's over the fire.

| Check | Evidence | Status |
|---|---|---|
| Baseline | Every earlier test through Assignment 7's wrapper, before and after the change, in its pinned mode, with counts | **Done** (22 Nov). Every earlier test gives the same count before and after. `cost_effects.gd` fails 1 of 4 on both sides, so it isn't this change's. Rerun at the branch tip, `160c0eb`: the same, but waves 15, as its brief revision says |
| Pins | The behaviour pins before the change and after, with what changed and why the brief predicted it | **Done.** 26/26 before (`1232706`); four pins re-pinned as the brief predicted (`1c858ed`); 26/26 after |
| Read-back | Both clips' read-back tests: track, key-time, step, loop-mode, update-mode and frame-range assertions, named | **Done.** The rig 51/51; the moth 22/22 on its new sheet (22 Nov) |
| Mutations | The four mutations exiting 1, each from its own worktree | **Done.** Each fails its test, a bone track's broken subname too (22 Nov) |
| Fresh cache | The rig's read-back after deleting `.godot/` and reimporting; for an imported rig, that its loop mode survived | **Done** (22 Nov, at `c14faf9`, and again at `160c0eb`). The rig 51/51: the seven loops `LOOP_LINEAR`, the jump's two `LOOP_NONE` |
| State machine | The structure test against the resource, and the state test driving real input through `Input.parse_input_event` | **Done.** The jump's states 89/89; the moths 15/15 |
| Edges | Every phase boundary, with an interrupt one frame before, on and one frame after each | **Done.** 239 checks at 30 fps, 238 at 60 and 144; three findings, settled by a brief revision |
| Frame strips (fixture) | The strips behind every revision in TUNING.md, labelled as fixture captures | **Done.** The jump r0 and r1; the raccoon's loops r0 |
| The cycle seam (HUMAN CHECK) | The looping clip through at least five wraps at normal speed: no stutter, no duplicated frame, no jump | **To look at again on the new moth.** On the four pixel-art moths (22 Nov), in play: "the moths are fine" |
| The action in play (HUMAN CHECK) | The committing action in normal play many times, with an interrupt in each phase; the three phases read as distinct | **Done** (22 Nov), in play: "Feels fine, even for different distinct workflows". I noted the distance |
| Registration (HUMAN CHECK) | The cycle's strip: the character doesn't drift within its cells | **Measured on the new sheet; my look not done.** The body sits within 1.5 px of 512 in all four cells |
| Against the background (HUMAN CHECK) | Both clips over the darkest and lightest level art they can appear on | **Not done** |
| Two clocks | The tick each clip advances on and the tick gameplay reads, measured, with the largest disagreement in seconds | **Done.** One physics tick, 0.017 s, at 60 and 144 fps; up to 0.033 s at 30 fps |
| Claude against me | Each of Claude's strip readings beside my verdict, with at least one point where I disagreed, or "none" | **Done for every strip so far.** The disagreements are named below |

### Baseline (22 Nov 2026)

Each side ran in its own git worktree with no `.godot/`, imported first (`--import` exit 0). Every test went through that revision's `scripts/run-test.sh`, which is Assignment 7's wrapper on both sides:
- **Before:** `3e0266c`, the game at `dc8ff17` with Assignment 7's wrapper and nothing else.
- **After:** `c14faf9`; and again at the end, at `160c0eb`, the game source as at `8bf28c9` (22 Nov 2026 19:05), in a fresh git clone with no `.godot/`, imported first.

The logs are in `logs/a7-baseline-before/`, `logs/a7-baseline-after/` and `logs/a7-baseline-final/`, each with a `SUMMARY.txt`.

| Test | Mode | Before (`3e0266c`) | After (`c14faf9`) | After, final (`160c0eb`) |
|---|---|---|---|---|
| `a3_asset_check.gd` | 60 | 20 ok, 0 failed | 20 ok, 0 failed | 20 ok, 0 failed |
| `normal_map_calibration.gd` | 60 | exit 0 (a measurement: the GL map reads 0.427 with `directx` off, against 1.573 on) | the same | the same |
| `test_materials.gd` | 60 | 137/137 | 137/137 | 137/137 |
| `test_leaf_burst_config.gd` | 60 | 110/110 | 110/110 | 110/110 |
| `test_campfire_smoke_config.gd` | 60 | 73/73 | 73/73 | 73/73 |
| `cost_effects.gd` | 60 | **3/4, exit 1** | **3/4, exit 1** | **3/4, exit 1** |
| sound, bubbles, camp, tasks, plan, tutorial | 60 | 30, 87, 31, 48, 22, 34 | 30, 87, 31, 48, 22, 34 | 30, 87, 31, 48, 22, 34 |
| cones; cone shader | 30, 60, 144 | 43 each; 93 each | 43 each; 93 each | 43 each; 93 each |
| fire, tent, bear bag, leaf burst state, smoke, smoke at load | 60 | 25, 16, 41, 37, 20, 8 | 25, 16, 41, 37, 20, 8 | 25, 16, 41, 37, 20, 8 |
| waves; title | realtime | 14/14; 53/53 | 14/14; 53/53 | **15/15**; 53/53 |

- **The final rerun:** every count is the same as at `c14faf9`, but waves. Its 15th check, each set on one of the burst's first three beats, came with the brief's revision "the moth guides him to the camp; the waves come in bursts" (`scripts/waves_test.gd`). No log has `SHADER ERROR`, `SCRIPT ERROR` or `Failed loading resource`.

- **The counts match:** every count is the same before and after. For the tests it lists, each is also the same as the last counts before Assignment 7 (above).
- **`cost_effects.gd` fails** its smoke case on both sides: "effect_b: 1500 sampled frames in the wrong state (… smoke emitting false …)". The fire is out by the time it samples. It fails before any of this change, so it isn't this change's; it's still open.
- **Assignment 7's own tests at `c14faf9`:**
  - the rig's read-back 51;
  - pins 26;
  - the jump's states 89;
  - edges 239, 238 and 238;
  - the moth's read-back 40 and the moths' state 15, on the pixel-art moths. On the new sheet (22 Nov), 22 and 15.
  - the balloons 35 and 69. With the chair moved by the table and the girl sitting on it (22 Nov, the brief's revision), the task's test has 71, all passing, and every other camp test keeps its count.
- **Assignment 7's own tests at `160c0eb`** (the final rerun): the rig's read-back 51; pins 26; the jump's states 89; edges 239, 238 and 238; the moth's read-back 22; the moths' state 15; the guide 9; the balloons 35 and 71.

### Pins

- **Before:** `tests/jump_pins.gd`, committed at `1232706` before any clip was wired, passed 26/26 at 60 fps (`logs/a7-pins/jump_pins_60fps.log`).
- **Four of the brief's worked-out numbers were wrong,** and the pins measured them: a held jump lands 25 ticks after takeoff (not 26), a tap peaks at 0.228 m (not 0.183 m), a kept press takes off the tick after landing, and the pins' "tick after F" is the brief's frame 0. The brief was revised to the pins (`0f0de36`).
- **The re-pin, in its own commit** (`1c858ed`), changed only the four pins about which clip plays:
  - the two "posed through the run clip";
  - "the clips in order";
  - "the clip on the tick after takeoff".
  They now read `jump` and `jump_land`, as the brief's revision `c0190b0` predicted: the jump is posed by its own clips, not the run clip sought. Every other pin kept its value.
- **After:** 26/26 at `c14faf9`, and again at `160c0eb`.

### Read-back

**The rig,** `tests/test_raccoon_rig.gd`, 51/51:
- **Track:** every track in every clip resolves to a real node, and to a property, bone or blend shape (`tests/track_check.gd`, by track type). All nine clips exist.
- **Step:** exactly 1/24 s on each of the nine (`is_equal_approx`, not within half a frame).
- **Loop mode:** `Animation.LOOP_LINEAR` on the seven loops; `Animation.LOOP_NONE` on `jump` and `jump_land`.
- **Update mode:** asked only of value tracks, and the rig has none.
- **Key times:**
  - `jump`: 10/24 s long, with keys at frames 0, 3, 6 and 10, within 1/48 s;
  - `jump_land`: 4/24 s long, with keys at 0 and 4;
  - each one-shot's last pose is its own.
- **The seven loops:** each length is its cycle spec's, and each seam holds: every track's value at 0 matches its value at the length.
- **Frame range:** this check is for frame tracks, and the rig has none.

**The moth,** `tests/test_moth_flutter.gd`, 22/22 on its new sheet (22 Nov 2026):
- **Track:** every track resolves. There's one track, a value track on the `Sprite3D`'s `frame`, in the saved resource `animations/moth_flutter.tres`.
- **Update mode:** `UPDATE_DISCRETE`.
- **Frame range:** every key is a cell inside the sheet (0–3), and the keys are 0, 1, 2, 3, 2, 1, out and back.
- **Key times:** 0 to 5/24 s, a frame apart, within 1/48 s; length 6/24 s.
- **Step and loop mode:** step exactly 1/24 s; `LOOP_LINEAR`.
- **The seam:** the last key's cell differs from the first's, and the last gap equals the key interval.
- **The sheet on the node:** one moth, on `moth_lowpoly.png` sliced 2 × 2; 0.15 m across its spread wings; billboarded, smooth filtering with mipmaps, cut out against a depth pre-pass; its `.import` lossless with mipmaps on and `detect_3d/compress_to` 0; its own `AnimationPlayer`, on `callback_mode_process` IDLE.
- **Before the new sheet** (the four pixel-art moths, cells 4 and 5 of `bugs.png`): 40/40.

**Not graded:** the 3D balloons' clips, `tests/test_balloon_3d.gd`, 35/35.

### Mutations (21 Nov 2026)

Each mutation was made in its own git worktree from `d2a306b`, then thrown away (`logs/a7-mutations/`, with `summary.txt`).

| Mutation | What changed | Its test | Result |
|---|---|---|---|
| 1. Break a track's subname | The moth's track names `.:fram`, not `.:frame` | `test_moth_flutter.gd` | **Exit 1**: 5 failed on the pixel-art moths; 2 failed on the new moth (22 Nov) |
| | (not graded) The balloon's bob names `Float:positon` | `test_balloon_3d.gd` | Exit 1, 1 failed |
| | The rig's `jump`: its first bone track names `pelvis_x`, not `pelvis`, in the clip only (22 Nov, below) | `test_raccoon_rig.gd` | **Exit 1**, 1 failed: "no bone pelvis_x on Skeleton3D" |
| 2. Flip the cycle's loop mode | The moth's `flutter` set to `LOOP_NONE` | `test_moth_flutter.gd` | **Exit 1**, 1 failed, on both moths |
| | Each raccoon loop set to `LOOP_NONE` in the importer's settings, one at a time (7 runs) | `test_raccoon_rig.gd` | Exit 1 each time, 1 failed |
| 3. Key a cell the sheet doesn't have | The moth's second key set to the first cell past the sheet: 12 (4 × 3) on the pixel-art moth, 4 (2 × 2) on the new one | `test_moth_flutter.gd` | **Exit 1**, 2 failed, on both moths |
| 4. Reimport from an empty cache | No `.godot/`, then `--import` (exit 0) | The read-backs | Rig 51/51, moth 40/40 (the pixel-art moth), balloons 35/35: the loop modes survived |
| | The contrast: the same import with the seven loops' modes taken out of the importer, the old runtime-code way | `test_raccoon_rig.gd` | **Exit 1**, 7 failed, one for each loop |

The new moth's mutations (22 Nov 2026, `logs/a7-mutations-moth/`) ran the same way. Each worktree was HEAD plus the uncommitted new moth, imported from an empty cache, and a control with no change passed 22/22.

The bone-track mutation (22 Nov 2026, `logs/a7-mutations-bone/`) ran in a git worktree at `160c0eb`, removed afterwards. Step 6's subname mutations had broken property tracks only, the moth's and a balloon's, so the read-back's branch for bone tracks hadn't been shown to catch anything.
- **The change:** an import script, `zz_mutate_bone.gd` (kept in the folder as `zz_mutate_bone.gd.txt`), set as `raccoon_v2.glb.import`'s `import_script/path`. On an import from no `.godot/`, it renamed the bone that `jump`'s first track names, `pelvis` to `pelvis_x`, in that clip only. The skeleton's bone kept its name.
- **The result:** the rig's read-back exited 1, 50 passed and 1 failed: "jump track 0: no bone pelvis_x on Skeleton3D".
- **The control:** the same worktree, imported from no `.godot/` before the change, passed 51/51.

Every mutation failed its test. Mutation 4 passes as it should, since the loop modes are in the importer's settings. Its contrast shows the read-back catches it when they aren't.

### Fresh cache

- **22 Nov 2026, at `c14faf9`:** the "after" baseline's worktree had no `.godot/`, and `--import` exited 0 (`logs/a7-baseline-after/00_import.log`). The rig's read-back then passed 51/51, with the seven loops reading `LOOP_LINEAR` and `jump` and `jump_land` reading `LOOP_NONE`. The moth's passed 40/40 on the pixel-art moths. The new moth's passed 22/22 from an empty cache, as the control of its mutations (`logs/a7-mutations-moth/`).
- **22 Nov 2026, at `160c0eb`:** the final baseline's fresh clone had no `.godot/`, and `--import` exited 0 (`logs/a7-baseline-final/00_import.log`). The rig's read-back passed 51/51 and the moth's 22/22.
- **Earlier:** at `d2a306b` (mutation 4 above), and first at `16ee0fe` (`logs/a7-fresh-cache/`).

### State machine

**`tests/test_jump_states.gd`, 89/89 at 60 fps.**
- **Structure, against the resource:**
  - every clip the model can ask for (`RM.CLIPS`, all nine) is in the rig's `AnimationPlayer`, and every clip it asked for in the run is one of them;
  - the nine loop modes are as the game has them;
  - one authority:
    - all 5 of `raccoon_model.gd`'s `play()`, `seek()` and `speed_scale` calls are on `_anim`;
    - no other script reaches `_anim`;
    - `player.gd` has no `AnimationPlayer`;
  - no `loop_mode =`, `Animation.new()`, `add_track()` or `track_insert_key()` in either script.
- **State,** in the real level, through `Input.parse_input_event`:
  - **Where F was pressed:** from walking, running, sneaking and standing, in the landing, and up a tree.
  - **What plays:**
    - `current_animation` is `jump` on every tick from the one after takeoff to the landing;
    - then `jump_land` through the landing, a tick late. Its last 2 ticks read `""` once it has run out, and `assigned_animation` still names it;
    - then the clip for how he's moving.
  - **The jump's start:** `jump` starts from frame 0, and the leap seek never runs during a jump.
  - **The seven loops:** each of the seven states plays its own clip.

**`tests/test_moths_state.gd`, 15/15** (on the new moth, 22 Nov 2026):
- one moth, over the fire, 0.4 m out and 1.15–1.25 m up, its flutter started half a frame in;
- it shows while the fire burns and hides while it doesn't;
- it shows every one of cells 0–3;
- `moths.gd` plays and seeks only the moths' players, and asks the fire only `burning()`.

### Edges

- **`tests/test_jump_edges.gd`, at `c14faf9`, and again at `160c0eb`:** 239 checks at 30 fps, and 238 at 60 and 144, all passing.
- **The boundaries:**
  - takeoff (tick 0);
  - the top (tick 15);
  - the landing (tick 25, held);
  - the landing's end (tick 37);
  - the edge of the kept-press buffer.
- **The interrupts:** at each boundary, F let go, F again and W (a move key), each seen one tick before the boundary, on it and one tick after. A tick is a physics tick, 1/60 s. At 30 fps a frame holds two ticks, and the test's table shows that each input lands on the first tick of a frame.
- **Three findings:** the first run (`5c06182`, the agent's, unedited) found three places where the brief promised more than the jump does:
  - air control starts the tick after takeoff;
  - a press is kept only within 5 ticks of landing, not 0.12 s;
  - the jump peaks on tick 13 and is still rising into tick 14.

  The game stayed as it was. The brief was revised to say what the jump does (`9e214ec`), and the test asserts that.

### Two clocks

- **Every clip advances on the process tick:**
  - the rig's player has `callback_mode_process` 1 (IDLE), read back;
  - the moth's player is set to 1 in `props/moths.tscn`.
- **Gameplay reads the jump on the physics tick,** 60 a second at every frame rate. Nothing in the game reads a clip's position.
- **Measured:**
  - **At 60 fps:** `jump` is asked for one tick after the game starts the jump, and `jump_land` one tick after the landing. Walk to run took one tick, 0.0167 s (`test_jump_states.gd`).
  - **At 144 fps:** also one tick.
  - **At 30 fps:** one or two ticks (`test_jump_edges.gd`).
- **The largest disagreement is 0.033 s, at 30 fps** (0.017 s at 60 and 144).

### Frame strips (fixture captures)

All of these are labelled fixture captures in TUNING.md.
- **The jump r0:** `captures/jump/r0/`, the ten frames the brief names (10, 13, 14, 16, 17, 21, 22, 27, 28, 40). They're from `previews/jump_preview.tscn` with Movie Maker at 30 fps (`--quit-after 60`), and its log is `logs/jump_preview_frames.log`.
- **The jump r1:** `captures/jump/r1/`, the same ten frames after the push-off key was re-keyed.
- **The raccoon's loops r0:** `captures/loops/r0/<clip>/`, 49 frames. They're cut by `tools/crop_loop_strips.gd` from `previews/raccoon_loops_preview.tscn` at 24 fps (`--quit-after 240`), and its log is `logs/raccoon_loops_preview_frames.log`.

### Claude against me

- **The jump r0: I disagreed with Claude.** My verdict on the strip was "I can see the push from its hind legs, which feels natural". Claude's reading said the push-off barely shows on frame 10, mixed into the 0.08 s blend from his standing pose. In play I then saw it Claude's way ("The hind legs don't particularly move"), and that observation drove r1.
- **The jump r1:** Claude's own prediction was wrong in two places. Frame 10 and frames 13–14 barely changed in the kept frames, because the new drive happens on frames 11 and 12. I kept r1 after play: "Yes, keep r1".
- **The loops r0: I disagreed once.** On `idle`'s blink, I saw it, and Claude couldn't make it out in the 168 × 126 px crops. My eyes stand. On the rest, Claude's reading agreed with mine (TUNING.md, "Loops r0").

### The human checks

My words are as I dictated them; Claude Code fixed only the punctuation.

**The cycle seam (22 Nov 2026, in play, on the four pixel-art moths before the new sheet).** I ran the game with the fire burning (`-- --dev-start=fire`) and watched the moths:

> "Did this, ran the game. We need a dev flag to disable the human NPCs, 'cause they scare away for us to test the element we need to. Along with the same, them moths are fine: they move in the same loop irrespective of the players, and they fade away after the bucket is downed."

- **The engine finding at the wrap** (Claude Code's, measured on 22 Nov 2026 in `previews/moth_preview.tscn`, `logs/moth_preview_frames.log`):
  - **What happens:** at a steady frame rate where the cycle is a whole number of frames, the moth's player reads its position as the length (4/24 s) on the wrap's frame, not 0. The discrete track then shows the last key's cell, 5, not 4.
  - **At 24 fps** a cycle reads 4, 5, 5, 5 instead of 4, 4, 5, 5.
  - **At 60 fps** it's 4 frames of cell 4 and 6 of cell 5, instead of 5 and 5.
  - **In play,** two of the four pixel-art moths started on whole 60 Hz frames. The new moth starts half a frame in (1/48 s), so its wrap doesn't land on the length at 24, 30 or 60 fps. Measured in the preview over 2 s: at 60 fps every cell shows in every cycle, and at 144 fps one frame in 48 of cell 0 is lost.
  - **What catches it:** the keys follow the seam rule, and the read-back passes, so it's the engine's behaviour at an exact wrap. No read-back of the clip can see it.
  - **My check:** it named no stutter.
- **What I asked for:** a developer flag that stops the campers getting in the way of a check.

**The action in play (22 Nov 2026).** I jumped many times in normal play, with an interrupt in each phase:

> "Yeah, I've tested the jumping. Feels fine, even for different distinct workflows. It feels fine. Maybe we can increase the distance for the jump, like, a little bit. It seems a little less at this time. A little bit of a, maybe, couple of pixels. I don't know. It feels a little less compared to what we have. Or maybe keep it. I will let you know. But something to note."

The jump's distance is its movement, which this change doesn't touch (CLAUDE.md, "Out of scope"). It's noted here, and it would need a revision of the brief if I want it.

**Still to do:**
- **Registration, on the new sheet:** measured by `tools/make_moth_sheet.gd`. The moth's left eye sits within 1.5 px in all four cells, and the abdomen's tip is on row 377 in each. My look is still to do: the four frames, or the preview's strip (`previews/moth_preview.tscn` into `captures/moth/r0/`, keeping frames 0–5).
- **The cycle seam, on the new moth:** a look in play, with `-- --dev-start=fire --dev-unseen`.
- **Against the background:** the jump and the moth over the darkest and lightest ground they appear on.
- **The raccoon's loops over five wraps** in their preview: optional, the brief's "my eyes" check. Their strips' seams read clean (TUNING.md, "Loops r0").
