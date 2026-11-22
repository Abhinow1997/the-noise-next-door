# Change brief: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 7: animation · Draft v1, 21 Nov 2026 · branch `assignment-7`

The plan for this assignment's change, written before the work. As the course asks, this file now holds only Assignment 7. The earlier briefs are in history: Assignment 2 at tag `a2`, Assignment 3 at `a3`, Assignment 5 at `a5`, Assignment 6 at `a6`. Later changes go below as dated revisions, and the original text stays.

**Before this brief** (from tag `a6` to `dc8ff17`, game work, not part of the animation): Raid the bear bag, the campers' confused head-scratch, the music from the speaker, the tutorial's run back, the tasks written out and calmer cones.

**Status (21 Nov 2026).** Draft v1, for me to check before it's committed, and committed before the first agent prompt.

## The two clips

| | What it is | Route | Its job | Loops or commits | Its one authority |
|---|---|---|---|---|---|
| **The jump** | The raccoon crouches, springs up snout first, then lands: two clips, `jump` and `jump_land` | Imported 3D rig: new actions in `raccoon_v2.glb` | "Airborne, to reach things not generally reachable" (my words, in full below) | **Commits** | `scripts/raccoon_model.gd`, `_change_animation()`, reading the jump's phase from `scripts/player.gd` |
| **The balloon's float** | A party balloon bobbing on its string | `Sprite3D` with an `AnimationPlayer` frame track | "One of the tasks that enables user to spoil the party" (my words, in full below) | **Loops** | Each balloon's own script, the only caller of `play()` on its own `AnimationPlayer` |

**Not graded, built after the two above:** the balloon's `pop` (a one-shot on the same sprite, when it's bitten) and the moths round the campfire (a loop).

**My decisions** (21 Nov 2026, from Claude Code's options): the jump, with a crouch added before takeoff; the balloons as the graded sprite clip, from a sheet Claude Code found; the moth kept as an extra. Pop the balloons replaced four other task ideas I turned down ("These are all bad, man").

## Facts from the code

(Claude Code's, 21 Nov 2026, from the files named; the clips' numbers read back headlessly on Godot 4.7.2.)

**The raccoon's rig and clips.**
- `assets/characters/raccoon_v2.glb`, exported from `raccoon_v2.blend` by `assets/characters/export_raccoon_v2.py`. Its actions are built in Blender by `design/character/raccoon_v2/anim.py` at 24 fps.
- Seven clips, all looping in play: `idle` 4.0 s, `walk` 1.0 s, `run` 0.667 s, `sneak` 2.0 s, `bored` 4.0 s, `sleep` 4.0 s, `climb` 1.0 s. Each has 26 tracks.
- **They're imported as `LOOP_NONE`.** The `.import` file has `animation/fps=24` and `_subresources={}`. They loop only because `_build_rigged()` sets `LOOP_LINEAR` on every clip at runtime (`scripts/raccoon_model.gd:385`).
- Their `step` is 1/24 s (0.0417), from the importer's 24 fps.
- The rig's `AnimationPlayer` is found at runtime (`raccoon_model.gd:384`). Its `callback_mode_process` reads back 1, `ANIMATION_CALLBACK_MODE_PROCESS_IDLE`.

**Who plays his clips.**
- `_process_rigged()`, on the process tick, asks `_rigged_state()` for a clip name and calls `_change_animation()`, which calls `_anim.play(name, blend)` (`raccoon_model.gd`).
- The same script also sets `speed_scale` (the gaits' rate), `seek()`s the run clip to hold poses for leaps and hops, and has `forced_animation` for screenshots.
- `_rigged_state()` today, in order:
  - a leap → `run`, sought to a pose;
  - asleep → `sleep`;
  - a hop → `run`;
  - climbing → `climb`;
  - crouched → `sneak`;
  - fast → `run`;
  - moving or turning → `walk`;
  - still → `idle`, then `bored` after 5 s.
- Three more scripts write his bones after the `AnimationPlayer`, as `SkeletonModifier3D`s: `scripts/raccoon_flex.gd` (his give in turns), `scripts/raccoon_eat.gd` and its `TwoBoneIK3D`s (eating).

**The jump today** (`scripts/player.gd`).
- F calls `jump()`, which keeps the press for `JUMP_BUFFER` 0.12 s. He takes off on the physics tick it's seen while he's on the floor, or within `JUMP_COYOTE` 0.1 s of leaving it: `velocity.y = sqrt(2 × 20 × 0.55)`, 4.69 m/s. There's no startup today.
- He rises under `JUMP_GRAVITY` 20, or 2.5 times that (`JUMP_CUT`) once F is let go, and falls under `FALL_GRAVITY` 28. In the air he has `AIR_CONTROL` 0.35 of his steering.
- **Worked out on 60 ticks a second:**
  - held: he lands 26 ticks after takeoff (0.433 s), peaking at 0.511 m;
  - a tap: he lands after 12 ticks (0.2 s), peaking at 0.183 m.
- On landing, `_jump_pose()` emits `landed` and he soaks it up for `LAND_TIME` 0.2 s.
- His pose through it all is the run clip, sought through `JUMP_AIR`, with squash and pitch.
- **Who reads it:**
  - `scripts/cone_driver.gd:96` (`jumping` shows the campers' cones);
  - `_on_landed()` in `scripts/campsite.gd`, a noise heard 6 m round (`HEAR_STEPS`).
- Physics runs at 60 ticks a second at every frame rate, under `--fixed-fps` too (CLAUDE.md).

**The sheets.**
- **Balloons:** "Balloon Pop Sprite" by metalx1000 (Kris Occhipinti), https://opengameart.org/content/balloon-pop-sprite.
  - Licence: CC-BY-SA 4.0; credit: "Balloon Sprite by Kris Occhipinti http://filmsbykris.com". Checked 21 Nov 2026.
  - Five colours, each committed as downloaded in `assets/sprites/balloons/` (`balloon_red_4.png`, `balloon_yellow.png`, `balloon_green_4.png`, `balloon_purple_2.png`, `balloon_blue_4.png`), with `ATTRIBUTION.md`.
- **Moth:** "Ambient Pixel Art Insects" by madameberry, CC0, https://opengameart.org/content/ambient-pixel-art-insects. Checked 21 Nov 2026.
  - `assets/sprites/cutebugs/cutebugs_by_madameberry.zip` as downloaded; `bugs.png` from it, unchanged; `ATTRIBUTION.md`.
- Both sheets' `.import` files have `detect_3d/compress_to=1`. When the editor first sees them used in 3D, it would switch them to compressed, which blurs pixel art.

**The view.** 1280 × 720. The camera has a 15° field of view from 19.2 m (`scripts/main.gd`), about 142 px per metre at the default zoom. The raccoon is about 0.61 m tall. His mouth is about 0.3 m up when standing (`RIGGED_MOUTH` 0.37 m at his scale of 0.8).

---

## The sheet, for each sprite clip

| | Balloon (graded) | Moth (extra) |
|---|---|---|
| Source, author, licence, checked | As above: metalx1000 (Kris Occhipinti), CC-BY-SA 4.0, 21 Nov 2026 | As above: madameberry, CC0, 21 Nov 2026 |
| Original file, as downloaded | `assets/sprites/balloons/balloon_<colour>.png` (one file per colour; there's no zip) | `assets/sprites/cutebugs/cutebugs_by_madameberry.zip` |
| Sheet used | Each colour's PNG, 48 × 64 px | `bugs.png`, 32 × 24 px |
| Cell size | 16 × 32 px | 8 × 8 px |
| Grid | `hframes` 3 × `vframes` 2 (cells 0–5) | `hframes` 4 × `vframes` 3 (cells 0–11) |
| Frame order | Float: cells 0, 1, 2 (only the string sways). Pop: cells 3, 4, 5 (cracks, bursts, shreds) | Moth: cells 4, 5 (wings out, wings up) |
| Registration | The balloon's body sits in the same 14 × 19 px box in cells 0–2, so it doesn't drift. Checked on all five colours | The body stays in the same columns in both cells |

Cells are numbered left to right, then down. The sheets aren't edited; any fix is on the node.

## The cycle spec: the balloon's float

- **Frames:** four keys over three cells, out and back: 0, 1, 2, 1.
- **Frame rate:** 24 fps, each cell held 6 frames (0.25 s).
- **Keys:** frames 0, 6, 12 and 18 (0, 0.25, 0.5, 0.75 s). Length 24 frames, 1.0 s. `Animation.step` 1/24 s.
- **Track:** a value track on the `Sprite3D`'s `frame`, `UPDATE_DISCRETE`.
- **Loop mode:** `Animation.LOOP_LINEAR`.
- **The seam rule, for a frame track:** no duplicate across the wrap: the last key is cell 1 and the first is cell 0. The gap from the last key to the length (0.75 s to 1.0 s) equals the key interval, 0.25 s.
- **The balloons:** three, red, yellow and blue, each 0.3 m across (`pixel_size` 0.3 / 14), tied low at the party by the speaker's table, with the body's middle about 0.7 m up. Each starts its float at its own offset, set by its own script, so they don't sway in step.

(Picked by me on 21 Nov 2026 from Claude Code's options, its recommendation: out and back, 1 s. The plain 0, 1, 2 loop snaps the string back to straight at every wrap.)

## The phase table: the jump

At **24 fps**, `Animation.step` 1/24 s, the importer's rate for this rig. Frame 0 is the physics tick F is seen. Every boundary below falls on a physics tick (2 frames = 5 ticks).

| Phase | Frames | Begins on | Seconds | Physics ticks | What the player may do | What the game reads |
|---|---|---|---|---|---|---|
| **Startup:** the crouch | 2 | frame 0 | 0 – 0.083 | 0 – 4 | It can't be cancelled: the jump will happen. Moving and steering as on the ground today. F again does nothing; letting go of F still takes off, as a small hop | On the floor; `jumping` true from frame 0 |
| **Active:** the bite | 4 | frame 2 (takeoff) | 0.083 – 0.25 | 5 – 14 | Steer at `AIR_CONTROL`; let go of F to cut the rise | **The bite:** a balloon whose middle is within 0.25 m of his mouth pops (one a jump) |
| **Recovery:** the rest of the air | to landing: about 6.4 more frames held, none on a tap that lands early | frame 6 | 0.25 – landing | 15 – landing (31 held, 17 on a tap) | Steer; a press up to 0.12 s before landing is kept | In the air; no bite |
| **Recovery:** the landing | 4 | landing | landing + 0.167 | landing + 0 – 9 | A kept or new F press starts the next crouch at once, cutting the landing; moving as now | `landed`, heard 6 m round as now |

**The keys built from it.**
- **`jump`**, length 12 frames, `LOOP_NONE`. Keys at frames 0 (standing), 2 (deep crouch, the push), 4 (stretched up, snout first), 6 (the bite's end, gathering) and 12 (paws reaching down, held until he lands).
- **`jump_land`**, length 4 frames, `LOOP_NONE`. Keys at frames 0 (paws down, the squash) and 4 (back in his stance).
- Two clips, not one, because the time in the air depends on how long F is held: `jump` holds its last pose until `landed`.
- Claude Code keys both in `anim.py` from this table and lists each key's time beside the frame it comes from.

**What changes in the game.**
- Takeoff now comes 5 ticks (0.083 s) after the press. Today it's on the press.
- The landing is 10 ticks (0.167 s). Today it's 0.2 s.
- During the jump his pose comes from these clips, not from seeking the run clip. Leaps from the hollow and hops keep the run clip as they are.

(Picked by me on 21 Nov 2026 from Claude Code's options, its recommendations: a 2-frame crouch and a 4-frame landing; the bite in the 4 frames from takeoff. Claude Code first recommended a 3-frame crouch and a 5-frame landing, and corrected itself the same day, before I'd written anything: at 24 fps only every second frame lands on a 60 Hz physics tick, so 3 frames would put takeoff between two ticks.)

## The state machine

The raccoon's clips are played by `raccoon_model.gd` from `_rigged_state()`, a code state table over `player.gd`'s state, on one `AnimationPlayer`. There's no `AnimationTree`, so there's no `advance_expression_base_node` or `advance_mode` to name.

| State | Its clip | Into it when | Out of it when |
|---|---|---|---|
| `idle`, `walk`, `run`, `sneak`, `bored`, `sleep`, `climb` | the clip of the same name | as today | as today, or F (to `jump`) |
| `jump` (new) | `jump` | F seen, or kept from up to 0.12 s before landing, while on the floor or within 0.1 s of leaving it | `landed` (to `jump_land`) |
| `jump_land` (new) | `jump_land` | `landed` | 10 ticks later, back to the state for how he's moving; or F (to `jump`) |

The balloon's float runs from its scene's start. When a bite lands in the active frames, the balloon's script plays `pop` once, then hides the balloon. The moths' driver shows them while the fire `burning()`, and hides them while it doesn't.

## The two clocks

| Clip | Its player | `callback_mode_process` | Advances on |
|---|---|---|---|
| `jump`, `jump_land` | the rig's `AnimationPlayer`, inside the imported scene | `ANIMATION_CALLBACK_MODE_PROCESS_IDLE` (read back: 1), left as it is | the process tick |
| `float`, `pop` | each balloon's `AnimationPlayer` | `ANIMATION_CALLBACK_MODE_PROCESS_IDLE`, set in its scene | the process tick |
| the moth's `flutter` | the moths' `AnimationPlayer` | `ANIMATION_CALLBACK_MODE_PROCESS_IDLE`, set in its scene | the process tick |

- No `AnimatedSprite2D` or `AnimatedSprite3D` is used.
- **Gameplay reads the jump on the physics tick.** `player.gd` counts ticks from the press: takeoff at 5, the bite open on ticks 5–14, then the landing's 10. The bite is checked on the physics tick.
- The clips are keyed from the same table, so a boundary is the same instant in both. The pose shows it on the next process tick. The largest disagreement is predicted to be one physics tick, 1/60 s (0.017 s), and is to be measured.
- No method tracks.

## Boundaries

(What this change must not touch.)
- Collision, the campers' states and timings, the tutorial, the existing tests' expectations, my `shaders/`, my Assignment 6 effects, and every other object stay as they are, except where this brief names a change.
- Movement and input stay as they are, except two jump timings: takeoff 5 ticks after the press, and the 10-tick landing. No new keys.
- **Named changes:**
  - the two new raccoon clips;
  - the raccoon's loop modes moved from `raccoon_model.gd:385` into `raccoon_v2.glb.import`'s per-animation settings;
  - the jump's state in `player.gd` and `raccoon_model.gd`;
  - a new task, "Pop the balloons", under Rock the party, with the hint "Jump and bite all three.": three balloons, the bite check, each pop heard as far as his laugh (`HEAR_CHITTER`, 8 m), and the task ticked when all three are popped;
  - the moths and their driver;
  - `detect_3d/compress_to` set to 0 on the two sheets.
- Presentation code may read game state; it never writes it. The bite check, the pops and the task are game code.

## The evidence split

| Rule | Checked by | How |
|---|---|---|
| Every track resolves to a real node and property or bone | Read-back | Branching on track type: a bone track names a bone of the `Skeleton3D` |
| The jump's keys at the phase table's frames, `step` 1/24, `LOOP_NONE`; the seven loops `LOOP_LINEAR` | Read-back, from an empty import cache | Key times within half a frame (1/48 s), never `==` |
| The float's keys (cells 0, 1, 2, 1 at 0, 0.25, 0.5, 0.75 s), length 1 s, `step` 1/24, `LOOP_LINEAR`, `UPDATE_DISCRETE`, every cell below `hframes × vframes` | Read-back | The same, against the balloon's scene |
| The seam: no duplicate across the wrap, and the last gap equals the interval | Read-back, then my eyes | Five wraps at normal speed |
| The state machine plays `jump` and `jump_land` on the right states, and every clip it asks for exists | Structure test and state test | Real input through `Input.parse_input_event`, reading `current_animation` |
| Takeoff on tick 5, the bite on ticks 5–14 only, a 10-tick landing | Pins (re-pinned as this brief predicts) and edge tests | An input, or a balloon at his mouth, one tick before, on and one tick after each boundary |
| An interrupt in each phase does what the table says | Edge tests | F again, F let go, and a move key in each phase |
| One authority over each animated node | Structure test, then my reading of the code | Only the named script calls `play()` or `seek()` on each `AnimationPlayer` |
| How the jump reads, phase by phase | The frame strip, then my eyes in play | At 1280 × 720, many jumps, an interrupt in each phase |
| The balloons and the moths against the camp at night | My eyes | Over the darkest and lightest ground they're seen on |
| The task: three pops tick it, each pop is heard | A state test | Through real input |

## The frame strip

- **The preview's background:** the camp's party area by the speaker's table, with a red balloon at his mouth's height on a held jump. It uses the game camera's angle and distance, at night, as in play.
- **The trigger:** F at frame 10, at 30 fps, held; captured with `--quit-after 60`.
- At 30 fps the boundaries fall between frames, so both sides are read.

| Frame | Time after F | What it should show |
|---|---|---|
| 10 | 0 | F: still standing, the crouch starting |
| 12, 13 | 0.067, 0.1 (takeoff at 0.083) | The deepest crouch, then just off the ground, stretching up |
| 17, 18 | 0.233, 0.267 (the bite closes at 0.25) | Snout up at the balloon, which pops in the window; then gathering |
| 25, 26 | 0.5, 0.533 (landing at about 0.517) | Paws reaching down, then touching down, squashed |
| 30, 31 | 0.667, 0.7 (the landing ends at 0.683) | Rising out of the squash, then back in his stance |
| 40 | 1.0 | In his stance, the balloon gone |

## Predicted failures

| # | What could go wrong | The check that would catch it |
|---|---|---|
| 1 | The loops come from runtime code, so from an empty import cache the seven clips import as `LOOP_NONE` and only the code hides it | The read-back from an empty cache, once the runtime line is gone (mutation 4) |
| 2 | The float's frame track is left on continuous updates, so the cells change halfway between keys | The read-back's update-mode check |
| 3 | A balloon is sliced on the wrong grid (3 × 1, or 6 × 1), showing the wrong cells with no error | The read-back's `hframes`, `vframes` and frame-range checks |
| 4 | The run clip's seek for leaps still runs during the jump: two writers to one `AnimationPlayer` | The state test reads `current_animation` as `jump` on every tick of the jump |
| 5 | The bite is read from the clip's position, on the process tick, so whether a pop lands depends on the frame rate | The edge tests at 30, 60 and 144 fps |
| 6 | `step` is left at its default 1/30 s, so the clips' keys snap off the 24 fps grid | The read-back's `step` check |

## Short answers

1. **Which route does each clip use, and what does that route's read-back see that the other route's does not?**
   The jump is on the imported 3D rig; the balloon's float is a `Sprite3D` with an `AnimationPlayer` frame track.
   - The rig's read-back sees bone tracks, whose subname is a bone of the `Skeleton3D`, not a property. It sees loop modes that only last if they're in the importer's settings, so it has to run from an empty import cache.
   - The frame track's read-back sees a value track on `frame`: its discrete update mode, and whether every key is a cell the sheet has (below `hframes × vframes`). Neither of those exists on a bone track.
2. **If your frame track is left on continuous updates, what does the sprite show between two keys, and why?**
   The cell changes partway between keys instead of on them. Continuous updates interpolate `frame` between the two keys' values, and the integer shows whichever cell that value becomes; how it rounds on 4.7.2 is to be seen. Where two keys are more than one cell apart, it sweeps through every cell in between: on a plain 0, 1, 2 loop, from cell 2 back to cell 0, it would flash cell 1.
3. **Your brief is in frames at your stated frame rate. What will `Animation.step` be, and what happens to your key times if you leave it at its default?**
   1/24 s (0.0417), one frame at 24 fps; the rig's clips already import with it. At the default 1/30 s, keys set in the editor snap to the 30 fps grid. For example, 0.25 s is 7.5 thirtieths, so it lands at 0.233 or 0.267 s, off the table. The read-back checks `step` and every key time to within half a frame.
4. **Which node is the one authority over each animated node, and what else in your project could write to it?**
   - **The rig's `AnimationPlayer`:** `raccoon_model.gd`, `_change_animation()`. In the same script, `seek()` for leaps and hops and `forced_animation` for screenshots could also write to it; the jump's states keep them out. The `SkeletonModifier3D`s (`raccoon_flex.gd`, `raccoon_eat.gd`, the eating IK) write his bones after it, by design, without touching the player.
   - **Each balloon's `AnimationPlayer`:** that balloon's own script. Nothing else.
   - **The moths' `AnimationPlayer`:** their driver.
5. **Which tick does each clip advance on, and which tick does gameplay read the fact your committing action's active window depends on? If they differ, what is the largest disagreement in seconds?**
   Every clip advances on the process tick (`ANIMATION_CALLBACK_MODE_PROCESS_IDLE`). Gameplay reads the bite window on the physics tick, counting ticks from the press. They differ: the pose can show a boundary up to one physics tick after the game has acted on it, 1/60 s (0.017 s). This is predicted, and is to be measured.
6. **For your cycle: what is the seam rule for its track type, and what would a duplicated frame at the wrap look like in play?**
   A frame track has no duplicate across the wrap, and the gap from the last key to the length equals the key interval. Here the last key is cell 1 and the first is cell 0, 0.25 s apart, the same as every other gap. A duplicated frame, say keys 0, 1, 2, 1, 0 with the last 0 at the end, would hold the straight string for twice as long: a hitch in the sway once a second.
7. **If your rig is imported: where does loop mode have to live so that a reimport keeps it, and how will you prove it survived an empty import cache?**
   In `raccoon_v2.glb.import`'s per-animation settings (`_subresources`, under each animation, `settings/loop_mode`), not in the scene and not in code. To prove it: delete `.godot/`, run `--import`, and run the read-back. It must read `LOOP_LINEAR` on the seven loops and `LOOP_NONE` on `jump` and `jump_land`. With `raccoon_model.gd:385` removed, nothing else can set them.

---

**The clips' jobs, in my own words.**
- **The jump:** "The jump tells the player the raccoon is airborne, to reach things not generally reachable." (21 Nov 2026; Claude Code added the capital and a comma.)
- **The balloons:** "Balloon is one of the tasks that enables user to spoil the party, and one of the movable objects within the task, so that helps." (21 Nov 2026, as I wrote it.)
- **The moths (not graded):** "an indicator of the fire being on, and like surveillance being on." (21 Nov 2026, as I wrote it.) While the fire burns, standing in its light he's seen half as far again, as the smoke already shows.

**Provenance.**
- **My decisions** (21 Nov 2026):
  - the jump as the committing action;
  - adding the crouch;
  - the bite window;
  - the balloons as the graded loop;
  - the moth kept as an extra;
  - Pop the balloons as the new task;
  - the jobs, in my own words.
  Each was picked from Claude Code's options, as marked.
- **Claude Code's specifics, kept at my word** (21 Nov 2026, "Keep them"):
  - three balloons, red, yellow and blue, 0.3 m across, their middles about 0.7 m up by the speaker's table;
  - the bite's reach of 0.25 m, and one pop a jump;
  - each pop heard 8 m round;
  - the hint "Jump and bite all three.";
  - the cones seeing a jump from the press, and E and C unchanged in every phase;
  - the crouch moving as on the ground, and not cancellable;
  - the edge tests stepping in physics ticks.
- **Claude Code's contributions:**
  - the options, and the facts from the code;
  - finding and downloading the sheets, and checking their slicing;
  - the numbers in the phase table and cycle spec;
  - the state table, the evidence split, the strip, the predicted failures, and the drafts of the short answers;
  - this draft of the brief.
- **Generative models:** none.

---

### Revised 21 Nov 2026: a held jump lands 25 ticks after takeoff (the pins)

The pins (`tests/jump_pins.gd`, `1232706`) measured the jump as it is today. Four of the brief's worked-out numbers are off, and each is replaced here. The original text stays above, as this file's rule is.
- **A held jump** lands **25 ticks after takeoff (0.417 s)**, not 26 (0.433 s). It still peaks at 0.511 m. The game counts him down on the tick his capsule is back on the floor, a tick before the worked-out height reaches 0.
- **A quick tap** (F let go the tick after it's pressed, as a quick key press is) peaks at **0.228 m** and still lands after 12 ticks. The brief's 0.183 m assumed F let go at the instant of takeoff, which no key press does.
- **A press kept from before landing** takes off **the tick after he lands**, not on it: he's counted down after that tick's takeoff check.
- **The pins' "tick after F"** is this brief's frame 0: the test presses F on one tick, and the game sees it on the next.

**What it changes in the phase table** (frame 0 is the tick F is seen; takeoff on tick 5, as the brief has it):
- **Landing:** a held jump lands on **tick 30, 0.5 s, exactly frame 12** (was tick 31, about 0.517 s). A quick tap lands on tick 17, 0.283 s. The landing then ends on tick 40 (0.667 s, frame 16) for a held jump.
- **`jump`'s length:** its 12 frames now end exactly as a held jump touches down. Its last key, "paws reaching down", is held only through a longer fall (off a ledge, say).
- **A kept press:** from the landing, the next crouch starts on the tick after he lands, as a kept press does today.

**What it changes in the frame strip** (F at frame 10, at 30 fps):
- the landing at 0.5 s falls exactly on **frame 25**: touching down, squashed;
- the landing's end at 0.667 s falls exactly on **frame 30**: back in his stance;
- the frames to read are 10, 12, 13, 17, 18, 25, 30 and 40.

(Drafted by Claude Code on 21 Nov 2026 from the pins' measurements. Kept by me the same day, before any clip was set up: "Keep and commit".)

---

### Revised 21 Nov 2026: F while asleep or climbing, the task's tests, and the extras' timings (Step 5's findings)

The Step 5 plan (`design/a7/session-5.jsonl`) found four things the brief didn't settle. This revision settles three of them; the fourth (a finished one-shot reads `current_animation` as `""`, so the clip check uses `assigned_animation`) is code, not the brief's.

**F while asleep or climbing.** The state table said F starts `jump` "from all seven states". Today F does nothing while he's asleep (input is locked), and up a tree it hops him off, as E does. From now:
- **Asleep, in the hollow:** F wakes him into the leap out, exactly as a move key does today: he wakes, uncurls and leaps out, posed through the run clip as before. This is an input change: F joins the move keys as a way to wake him. It doesn't start `jump`.
- **Climbing, on the trunk or a limb:** F hops him off as today, with the same timing and the same path, as E still does. The hop is now shown with the jump's clips: `jump` from its takeoff pose (frame 2, so no crouch, since he's already leaving the tree) until he's down, then `jump_land`'s 4 frames. This is presentation only: the hop's timing, movement and input are unchanged, and there's no bite in it.
- This replaces "Leaps from the hollow and hops keep the run clip". The leap out of the hollow, the dive into the bush and its hop out, the startle's leaps and the hop to and from the rest spot keep the run clip. Only the hops off a tree change.
- **In the state table:** from `sleep`, F gives the leap out, not `jump`. From `climb`, F gives the hop off, shown as `jump` from frame 2, then `jump_land`.

**The task's tests.** "Pop the balloons", a new sub-task of Rock the party, changes five existing tests. Each change is only the new task, nothing else:
- `scripts/cones_test.gd:107`, `scripts/tasks_test.gd:74` and `scripts/tutorial_test.gd:268`: the expected task-id strings gain `balloons` after `bearbag`.
- `scripts/cones_test.gd:160` ("Rock the party is ticked off"), `scripts/tasks_test.gd:232` ("All six tasks done", now seven) and `scripts/sound_test.gd:168` ("Every task done"): each still expects `true`. Each test now also ticks `balloons` on its way there, as it ticks the other sub-tasks.
- Their checks' names may change to match ("All six" becomes "All seven"); their counts of checks stay the same.

**The extras' timings and places** (not graded; each gets a light read-back like the float's):
- **The balloon's `pop`:**
  - cells 3, 4, 5, each held 2 frames at 24 fps;
  - keys at 0, 2/24 and 4/24 s; length 6/24 s (0.25 s); `step` 1/24; `LOOP_NONE`; discrete;
  - played once by the balloon's own script when it's bitten, then the balloon is hidden. It goes in the balloon scene's library beside `float`, as `animations/balloon_pop.tres`.
- **The moths' `flutter`:**
  - cells 4, 5 of `bugs.png`, each held 2 frames at 24 fps;
  - keys at 0 and 2/24 s; length 4/24 s; `step` 1/24; `LOOP_LINEAR`; discrete;
  - the seam: the last cell (5) differs from the first (4), and the last gap (2/24 s) equals the interval.
  - It's saved as `animations/moth_flutter.tres`.
- **The moths:**
  - four, round the campfire, each circling 0.55–0.9 m out and 0.85–1.5 m up, each 0.1 m across (`pixel_size` 0.1 / 8), billboarded with nearest filtering;
  - each starts its flutter at its own offset, so they don't flap in step;
  - shown while the fire `burning()`, hidden while it isn't, by their driver, which reads the fire and writes nothing in the game;
  - `bugs.png`'s `detect_3d/compress_to` set to 0.
  - This is as the throwaway preview showed them, and that preview is not reused.

(Drafted by Claude Code on 21 Nov 2026 from my answers to Step 5's findings: "Make F jump there too", then "F wakes him into the leap out" and "The hop off uses the jump clips"; "Draft a brief revision"; and "Add them" for the extras' timings, which are Claude Code's. Kept by me the same day: "Keep it".)

---

### Revised 21 Nov 2026: the balloon is a low-poly sheet I generated, and it's out of the camp with the girl

The pixel-art balloons didn't suit the game ("look absolute trash, don't suit the game at all"): flat toy-bright pixels in a matte, low-poly camp at night. They're replaced by a low-poly balloon I generated. Everything else about the balloon stays: the grid, the frame order, the float's and the pop's keys, its scene, its script and the task.

**The sheet.**
- **Generated by me** with Google Gemini (its version wasn't recorded), from a prompt Claude Code wrote: `design/a7/balloon-prompt.txt`. Whether I used it word for word or added follow-ups wasn't recorded. No artist, brand or character is named. SOURCES.md has the model and its terms.
- **The file kept** is the copy I pasted into the session: `assets/sprites/balloon_lowpoly/balloon_lowpoly_gemini.webp`, 765 × 1024, 26,338 bytes, SHA-256 `b11e42f1def7e3d22a6b181b23dcb3b9e4c1202ad01aa54f890cbfe0e4ce2ddf`. It's a re-compressed WebP; Gemini's own file wasn't kept ("Use this copy").
- **Made into the sheet** by `tools/make_balloon_sheet.gd`, a committed script, run headless. It does four things, and nothing is resampled or repainted:
  - keys the green to transparent, with the green spill taken out of the edges and the string;
  - lines up the float's three frames, moving cells 1 and 2 by 1 and 2 px so the body's box is the same in all three;
  - clears a 3-px frame round each cell, where Gemini's faint lines between the cells crossed;
  - writes `assets/sprites/balloon_lowpoly/balloon_lowpoly.png`, 765 × 1024, SHA-256 `cb5ea4a45aa5541c640234a8a0b99326ccb98758c11310c31ccbac75f9967b7b`.

**The slicing, the same as before:**
- cells of 255 × 512 px, `hframes` 3, `vframes` 2;
- float cells 0, 1, 2 (only the string sways);
- pop cells 3, 4, 5 (a tear, the burst, the shreds).

The float's keys (0, 1, 2, 1 at 0, 0.25, 0.5 and 0.75 s) and the pop's (3, 4, 5, 2 frames each) are unchanged. **Registration:** the body sits in the same 163 × 204 px box at (45, 41) in cells 0–2 (measured by the script).

**On the node.**
- **One off-white sheet for all three balloons,** each tinted with the `Sprite3D`'s `modulate`: red, yellow or blue, in the camp's matte palette. So all three share the same frames.
- **Size:** still 0.3 m across, now across a 163 px body, so `pixel_size` is 0.3 / 163. `offset` is (1, −113) px, so the node's origin is the body's middle and the 0.7 m height and the 0.25 m reach are measured from it.
- **Filtering:** smooth filtering with mipmaps, since it's no longer pixel art. Its import is lossless with mipmaps on and `detect_3d/compress_to` 0.
- **Lighting:** shaded, so the night and the fire light it like the camp's props.

**The old sheets.** The five CC-BY-SA pixel-art sheets (`assets/sprites/balloons/`) and their ATTRIBUTION.md come out of the repo; they're in history at `d878213`. With them out of the game and the film, their credit leaves SOURCES.md's Assignment 7 section. The section notes that they were used, then replaced.

**What changes with it:**
- `props/party_balloon.tscn`: the texture, filtering, size, offset and lighting;
- `props/party_balloon.gd`: the colour picks a tint, not a sheet;
- the read-back's and the task test's expected sheet: the low-poly one, tinted, in place of "one of the five balloon sheets". That's a read-back's expected value changing with a kept change, the brief revised to match, as the course allows.

**Where the balloons are, and the girl.** They were tied by the speaker in the middle of the party, for no reason in the game ("why are the balloons randomly kept in the middle of the camp?").
- **The place:** the three balloons are now tied at a clear spot just outside the camp, beyond `CAMP_ZONE` (12.5 m from its middle). The exact spot is picked in the build where the ground is clear and she can walk to it, then named in its commit.
- **The girl minds them:** a new step in her routine. She walks out to the balloons and stays by them about as long as a dance (30–45 s, `GIRL_DANCE_TIME`), then goes back to the party. The rest of her routine (dancing, warming her hands) is as before.
- **Scaring her off:** what she already does when she sees him. She runs to her protector and cowers (`camp_person.gd`), unchanged, and that leaves the balloons free. Her protector and the others react as they already do.
- **Popping:** any time, with no new rule. If he sneaks up unseen and bites, it pops; scaring her off first is the easy way. Each pop is still heard 8 m round, so out there it may not reach the party.
- **These are named changes** to the campers' routines, which were otherwise out of bounds. Only the girl's routine changes, by this one step. If an existing test expects her old routine, the plan stops and says which test and line.

(Drafted by Claude Code on 21 Nov 2026 from my answers: "give me a prompt u need i will create the assest for u", then the image, then "Use this copy"; and, for the place, "have the girl use somewhere in the out side of the camp area we initially scare her make her run away to pop them", then "Minding the balloons" and "Any time". The keying, alignment, tints, size, offset, filtering and lighting, and the routine step's length, are Claude Code's. Kept by me the same day: "Yes, both".)

---

### Revised 21 Nov 2026: the girl's new step comes after warming her hands (the tasks test)

The build stopped, as the last revision told it to. `scripts/tasks_test.gd` expects the girl's old routine: after warming her hands she's back dancing within 15 s (lines 100–103).
- **Where the step goes:** after warming her hands. Her routine becomes dance → warm → mind the balloons → dance. That way the test's line 84 ("roast drink warm") still holds as it is.
- **`scripts/tasks_test.gd:100–103` changes to match**, and only there:
  - after `warm` is cut short, she walks out to the balloons;
  - that step is cut short too, the same way (`_step_left = 0.01`);
  - then she's back dancing, as the check still expects (`true`).
  - The check's name may change to say so. Its count stays the same.

(Drafted by Claude Code on 21 Nov 2026 from the build's report. Kept by me the same day: "Yes, both".)

---

### Revised 21 Nov 2026: the balloons are 3D, and the moth is the graded sprite clip

My generated balloon sheet looks right as a picture, but in the game it's a flat card: a `Sprite3D` facing the camera beside the camp's real 3D props. "it looks weird in the game". So the balloons become real low-poly 3D, and the sprite-sheet clip the course grades moves to the moth, which is already built and checked.

**The two clips now:**

| | What it is | Route | Its job | Loops or commits | Its one authority |
|---|---|---|---|---|---|
| **The jump** | unchanged | Imported 3D rig | unchanged | **Commits** | unchanged |
| **The moth's flutter** | Four moths flapping round the campfire while it burns | `Sprite3D` with an `AnimationPlayer` frame track | "an indicator of the fire being on, and like surveillance being on" (my words, above) | **Loops** | Each moth's own `AnimationPlayer`, played and sought only by the moths' driver, `props/moths.gd` |

- **The moth's sheet** is as "The sheet, for each sprite clip" gives it: madameberry's CC0 "Ambient Pixel Art Insects", the zip as downloaded, `bugs.png` from it, 8 × 8 cells, `hframes` 4 × `vframes` 3, the moth cells 4 and 5.
- **Its cycle spec** is the one the revision of the extras gave:
  - cells 4, 5, each held 2 frames at 24 fps;
  - keys at 0 and 2/24 s; length 4/24 s; `step` 1/24; `LOOP_LINEAR`; discrete.
  - The seam rule for a frame track: the last cell (5) differs from the first (4), and the last gap (2/24 s) equals the interval. So no frame repeats across the wrap.
- **Its read-back** is `tests/test_moth_flutter.gd`: the course's track check, discrete updates, every key inside the sheet (below 12), key times within half a frame, `step` exactly, `LOOP_LINEAR`, the seam. Its state check is `tests/test_moths_state.gd`.
- **The mutations** move with it:
  - the loop flip sets `flutter` to `LOOP_NONE`;
  - the bad cell keys cell 12, which `bugs.png` doesn't have.
- **Registration** is checked on the moth's two cells.
- **Its job** as a gameplay signal overlaps the smoke's (the fire is lit). That's what I chose it to say.

**The balloons, now 3D:**
- **The model:** low-poly balloons built in code like the camp's other props: a faceted egg-shaped body with few sides, a small knot and a thin string, matte and flat-shaded. Each is tinted with the same red, yellow and blue as before, 0.3 m across, its middle about 0.7 m up.
- **Their bob:** a clip saved as a resource on each balloon's own `AnimationPlayer`. It's a gentle rise and fall with a slight sway, `LOOP_LINEAR`, each balloon starting at its own offset.
- **Their pop:** a short clip saved as a resource (a quick swell, about 0.1 s), then the balloon is hidden.
- **Authority:** the balloon's own script plays them, the only caller of `play()` on that player.
- **Not graded:** both clips get a light read-back.
- **Unchanged:** the task, its place outside the camp, the girl minding them, the bite check and the pops' noise.

**What goes:**
- the 2D balloon's `float` and `pop` clips (`animations/balloon_float.tres`, `animations/balloon_pop.tres`), its `Sprite3D` scene setup, and their read-backs (`tests/test_balloon_float.gd`, `tests/test_balloon_pop.gd`);
- the course's track check, which the moth's read-back borrows from the float test: it moves to the moth's test (or a small shared helper), unchanged;
- my generated sheet, its import files and `tools/make_balloon_sheet.gd`: out of the repo, kept in history at `7bd4aea`. SOURCES.md notes it was made and then replaced.
- `tests/test_balloon_task.gd` changes only where the balloon's look does (its sprite and sheet checks become the 3D balloon's).

(Drafted by Claude Code on 21 Nov 2026 from my answer, "3D balloons, moth graded". The balloons' build, the bob's and the pop's clips, and the removals are Claude Code's. Kept by me the same day: "Keep it".)

---

### Revised 21 Nov 2026: the tasks test settles the fire keeper too; what the girl does out there

Part 2 is built: the balloons are beyond `CAMP_ZONE`, and the girl minds them after warming her hands. The build stopped on two things.

**`scripts/tasks_test.gd` fails 3 of its 48 checks:** the marshmallows, "nobody noticed", "a man snatches it back". Nothing it measures changed. The girl's longer walk out and back, about 25 s more game time, moves where the fire keeper's routine has reached. Now he's stoking the fire as the raccoon unzips the backpack, sees him, and raises the alarm. The test's `_settle()` (lines 311–321) puts the camper, the man and the girl at a fixed step before each scene, but never the keeper.
- **The fix:** `_settle()` also puts the fire keeper at a fixed step of his routine, the first (eating at the table, away from the backpack), as it does the other three.
- **Only how it measures changes.** No expected value changes, and the count stays 48. That's what CLAUDE.md allows a test.

**What the girl does when she sees him at the balloons.** The revision said she "runs to her protector and cowers". The unchanged code (`camp_person.gd:929-940`) sends her behind her protector only when he's within 6 m. At the balloons he's about 14 m away, so she backs off from the raccoon a few steps and cowers there. That's what she does anywhere her protector is far. Her reactions stay unchanged, and the brief now says what they are: seen at the balloons, she backs off and cowers; that still leaves the balloons, and him, free. The test checks that.

(Drafted by Claude Code on 21 Nov 2026 from the build's report. Kept by me the same day: "Keep it".)

---

### Revised 21 Nov 2026: the jump plays as it did before, in three phases of its own; the bite comes out

"remodel the jump for the assignment's requirement but it can't be just a jump and bite, it will be like it was previously". The crouch and the bite made the jump into a balloon-popping move. It goes back to the jump the game had, a general move for reaching things (my job line). Its phases now come from that jump itself.

**The movement, back to before** (`scripts/player.gd` as at `dc8ff17`'s jump):
- he takes off on the tick F is seen, with no crouch, and the same lift;
- letting go of F while he rises still cuts the height (`JUMP_CUT`);
- `JUMP_BUFFER`, `JUMP_COYOTE` and `AIR_CONTROL` as before;
- he soaks up the landing for 0.2 s (`LAND_TIME`, 12 ticks).

Step 1's crouch, `TAKEOFF_TICK`, the 10-tick landing, and `bite_open()`, `use_bite()` and `mouth_point()` all go.

**The phase table, replacing the one above and its first revision.** At 24 fps, `Animation.step` 1/24 s, for a held jump. Frame 0 is takeoff, the tick F is seen.

| Phase | Frames | Begins on | Physics ticks | What the player may do | What the game reads |
|---|---|---|---|---|---|
| **Startup:** the push and rise | 6 | frame 0 (takeoff) | 0–14 | Let go of F to cut the height; steer at `AIR_CONTROL` | `jumping` true (the cones see him); rising |
| **Active:** the top and the fall | 4 | frame 6 (the top) | 15–24 | Steer; a press up to 0.12 s before landing is kept | `jumping`; falling |
| **Recovery:** the landing | 12 ticks (4.8 frames) | landing (tick 25 held) | landing + 0–11 | A kept or new press starts the next jump at once | `landed`, heard 6 m round |

- A held jump peaks between ticks 14 and 15. The pins measured that it lands 25 ticks after takeoff, so the top falls exactly on frame 6 and the landing on frame 10.
- A tap (F let go early) peaks lower and sooner, and lands after 12 ticks. The startup is shorter; the clip simply hands over to `jump_land` when he's down.

**The keys built from it:**
- **`jump`**, re-keyed in Blender (`design/character/raccoon_v2/anim.py`, rebuilt with `anim_jump.py`, re-exported), length 10 frames, `LOOP_NONE`. Keys at frames 0 (the push-off, hind legs extending), 3 (stretched up, snout first), 6 (gathered at the top) and 10 (front paws reaching down), each key's time listed beside its frame.
- **`jump_land`** stays as it is (4 frames). The landing's 12 ticks hold its last pose for the 2 ticks after it ends.
- **A hop off a tree** plays `jump` from frame 0, its push-off, in place of frame 2.

**The bite comes out.** There's no bite in the jump. The balloons stay where they are, out by the girl, who still minds them, but they can't be popped until I give the balloon task its design. `scripts/camp_balloons.gd`'s bite check comes out. `tests/test_balloon_task.gd` keeps its checks of the balloons, their place and the girl, and its pop checks come out until that design.

**What the tests show:**
- **`tests/test_jump_states.gd`** changes with this revision: no crouch, no bite, the 12-tick landing, `jump` from frame 0 off a tree.
- **The pins (`tests/jump_pins.gd`)** go back to passing on the jump's timing: takeoff on the tick after F, a held jump landing 25 ticks later at 0.511 m, a tap's 12 ticks and 0.228 m, a 12-tick landing, the buffered press as before. The only pins the brief still says will change are the clips: `jump` and `jump_land` where the run clip was (the two "posed through the run clip", the clips in order, and the clip on the tick after takeoff). That's Step 6's re-pin.
- **`tests/test_raccoon_rig.gd`** reads `jump`'s new length (10/24 s) and its keys at 0, 3, 6 and 10.

(Drafted by Claude Code on 21 Nov 2026 from my answers: "Approve the remodel" and "Take the bite out now". The phases' boundaries and the clip's new keys are Claude Code's. Kept by me the same day: "Yes, all".)

---

### Revised 21 Nov 2026: the balloon task is "Let the balloons go"

"the ballons can be blown up by the girl maybe tie somewhere a bit outside on something near the camp and we can get it off and float them away to annoy the campers". This replaces popping, which the last revision took out. The balloons stay 3D, at the spot outside the camp, and the girl's step stays where it is in her routine.

**The girl blows them up:**
- On her first balloon step she sets out a folding camp chair at the spot, built in code like the camp's props.
- She blows up the three balloons one by one: each grows from a small, limp bud to full size over about 3 s, an `inflate` clip saved as a resource on the balloon's own `AnimationPlayer`.
- She ties each string to the chair as it's done, then goes back to the party.
- On her later balloon steps she minds them, as now.
- Until she's blown them up, there's nothing there to untie.

**He lets them go:**
- The three strings are knotted together low on the chair, in his reach. He walks up and presses E (grab) to tug the knot loose. That's the grab he already has; there's no jump in it.
- The bunch floats away: it rises about 8 m over about 5 s, swaying, then it's gone. That's a `float_away` clip, saved as a resource, on the bunch.
- That ticks the task. As before, he can do it whenever he can reach the knot unseen, or once he's scared her off.

**The girl calls the others:**
- When she sees the balloons float away, or comes back to find the chair empty, she's upset. She takes fright as she does on seeing him, and calls the others.
- Each of them comes to look where the balloons were tied, searching round the chair as they search after a fright (`camp_person.gd`'s search). That's a risk if he's still about.
- Then they go back to their routines.
- This is a named change to the campers' reactions: one new trigger (the balloons gone) for reactions they already have. How they search and what they do on seeing him are unchanged.

**The task:** "Let the balloons go", under Rock the party, with the hint "Untie them, let them fly." (5 words). It replaces "Pop the balloons" in `camp_tasks.gd`. The five tests the last task revision named keep its id, `balloons`.

**What goes and what changes:**
- The `pop` clip goes, and `inflate` and `float_away` come in. `bob` stays while they're tied.
- `scripts/camp_balloons.gd`: the chair, the inflating, the knot and the release, plus the girl's call.
- `scripts/campsite.gd`: her step now blows them up the first time.
- `props/party_balloon.gd` and `.tscn`: the new clips. The balloon's own script stays the only caller of `play()` on its player; the bunch's release is played by `camp_balloons.gd` on the bunch's own player, its only caller.
- `tests/test_balloon_task.gd` and `tests/test_balloon_3d.gd` change to match:
  - she blows them up and ties them;
  - E at the knot frees them, they float away, and the task ticks;
  - seeing it, or finding the chair empty, she calls the others, who search there.
- If an existing test expects the campers not to react to the balloons, the build stops and says which.

(Drafted by Claude Code on 21 Nov 2026 from my words above and my answers: "A camp chair or stake", "E at the knot", "The girl calls the others". The chair, the clips' timings and the hint are Claude Code's. Kept by me the same day: "Yes, all".)

---

### Revised 21 Nov 2026: every raccoon animation meets the assignment's requirements, not only the jump

The jump has its phase table, and the moth's flutter its cycle spec. The raccoon's seven looping clips are already in the rig's read-back (`tests/test_raccoon_rig.gd`: every bone track resolves, `step` is exactly 1/24, `LOOP_LINEAR`, from an empty import cache). They now get written cycle specs, and their seam is checked. Their keys aren't changed: the gaits are timed so his paws don't slide (`raccoon_model.gd`'s `GAITS`).

**The cycle specs.** All are made by `design/character/raccoon_v2/anim.py` at 24 fps, `Animation.step` 1/24 s, imported with `Animation.LOOP_LINEAR` set in `raccoon_v2.glb.import`'s per-animation settings. Each has 26 bone tracks (rotation and position, continuous):

| Clip | Frames | Length | How it's made (`anim.py`) |
|---|---|---|---|
| `idle` | 96 | 4.0 s | standing, glancing about |
| `walk` | 24 | 1.0 s | a trot, timed off its foot contacts |
| `run` | 16 | 0.667 s | a lope, the head steadied afterwards (`steady_head`) |
| `sneak` | 48 | 2.0 s | a stalk, one paw at a time |
| `bored` | 96 | 4.0 s | slumped on his rump |
| `sleep` | 96 | 4.0 s | curled up |
| `climb` | 24 | 1.0 s | belly to the trunk |

**The seam rule, for a continuous track:** each track's value at time 0 matches its value at the clip's length. `anim.py` makes them that way: it samples each loop at u = f / frames for f from 0 to frames, from a pose that repeats every cycle, so the last frame is the first again (for `run`, after its head is steadied too).

**The check:** `tests/test_raccoon_rig.gd` gains, for each of the seven loops, that every track's value at 0 and at the length match. Rotations are compared with `is_equal_approx`, accepting a quaternion or its negative, which are the same turn. Positions and scales are compared within 1 mm. A clip that hitched at the wrap would fail it. The jump's one-shots are left out: their last pose is their own.

**Every requirement the course sets for a looping clip, for each of the seven** ("do requirements for all the animations, not just jump"). A phase table is the course's requirement for a committing action, so the jump keeps its own; a loop's equivalent is its cycle spec and seam.
- **The cycle spec:** each clip's above. For the four gaits, `anim.py`'s own foot timing is written out in frames as their phases:

| Clip (frames) | Its phases at 24 fps, from `anim.py` |
|---|---|
| `walk` (24) | A trot. Front-left and hind-right down on frames 0–14, front-right and hind-left from 12 to about frame 2 of the next cycle (the pairs overlap: all four down at the hand-overs, about frames 1 and 13). The body is highest at the hand-overs and lowest mid-support (about frames 7 and 19). |
| `run` (16) | A lope. The hind feet land together on frame 0 and push off by about frame 7; the front feet land on frame 8 and push off by about frame 15. No foot is down at about frames 7.5 and 15.5, when the body rises. |
| `sneak` (48) | A stalk, three paws always down. The swings: hind-left frames 37–48, front-left 1–12, hind-right 13–24, front-right 25–36. |
| `climb` (24) | Diagonal pairs on the trunk: front-left and hind-right from frame 0, front-right and hind-left from frame 12. |

  `idle`, `bored` and `sleep` have no footfalls: they're slow cycles of the head, the tail and the ears (`anim.py` gives no action any breathing).
- **The read-back,** for all seven:
  - every bone track resolves;
  - the length is the spec's (frames / 24);
  - `step` is exactly 1/24;
  - `LOOP_LINEAR`, from an empty import cache;
  - the seam, as above.
- **The mutations** (Step 6): the loop-flip mutation is run on each of the seven in turn (`LOOP_NONE` in the importer's settings), and the read-back must fail each one. The broken-subname mutation covers their bone tracks too.
- **The state machine:** the structure test already asserts every clip the state machine can ask for exists, all nine. The state test (`tests/test_jump_states.gd`) gains a check, through real input, that each of the seven states plays its clip, read as `current_animation`:
  - idle: standing;
  - walk: W;
  - run: W with Shift;
  - sneak: Ctrl with W;
  - bored: standing still past `BORED_AFTER`;
  - sleep: in the hollow;
  - climb: on a trunk.
- **The two clocks:** all nine are on the rig's one `AnimationPlayer`, on the process tick. The one-tick lag measured for the jump is measured for a gait change too.
- **My eyes:** a preview scene, `previews/raccoon_loops_preview.tscn`, shows the seven loops side by side in the real camp at night, each looping, so I can watch each one's seam over at least five wraps at normal speed and at `--time-scale 0.25`. I write what I see in TEST-REPORT.md for each.
- **The jump's own requirements** (phase table, edge tests, pins, the strip and the tuning) stay the jump's, as the course asks of the committing action.

(Drafted by Claude Code on 21 Nov 2026 at my request: "Yes, add them", then "do requirements for all the animations not just jump". The numbers and the gaits' phases are from `anim.py` and the read-back. Kept by me the same day: "Keep it".)

---

### Revised 21 Nov 2026: what the jump really does at its edges (the edge tests)

The edge tests (`tests/test_jump_edges.gd`, `5c06182`) interrupted the jump one tick before, on and after each boundary, at 30, 60 and 144 fps. The jump is the original game's, unchanged, and in two places the phase table above promised more than it does. The game stays as it is; the table says what it really does ("Revise the brief").

- **Air control starts the tick after takeoff.** On the takeoff tick itself he still steers at full control. The game picks how hard he can steer before it starts the jump on that tick. Startup's "steer at `AIR_CONTROL`" holds from tick 1.
- **A press is kept for landing only within 5 ticks of it (0.083 s), not 0.12 s.** The kept press can only take off on the tick after he lands, and `JUMP_BUFFER`'s 0.12 s has run out by then for a press made earlier.
  - Measured on a held jump that lands on tick 25: a press on tick 20 (5 ticks before) is kept, and the next jump takes off on tick 26.
  - Presses on ticks 18 and 19 (7 and 6 ticks before) are dropped: no second jump, and the full 12-tick landing.
  - The active phase's "a press up to 0.12 s before landing is kept" now reads "within 5 ticks (0.083 s) of landing".
- **The top.** A held jump peaks on tick 13 (0.511 m). It's still rising into tick 14 (+0.024 m/s) and falling from tick 15, so letting go of F changes nothing from tick 15 on. The active phase still begins on tick 15. The table's "peaks between ticks 14 and 15" now reads "rises until tick 14, falls from tick 15". Letting go on tick 14 only lowers the very last of the rise.
- **The two clocks at 30 fps.** At 60 and 144 fps the clip shows each change one tick after the game, as predicted (0.017 s). At 30 fps a frame is two ticks, so the lag is one or two ticks: up to 0.033 s. Short answer 5's "largest disagreement" is 0.017 s at 60 fps or more, and 0.033 s at 30 fps.
- **The frame rate changes a quick tap.** Input arrives once a frame, so at 30 fps a tap's release is seen a tick later than at 60, and it peaks a little higher (0.269 m against 0.228 m). A held jump is the same at every rate.

**The edge test changes to match,** and only its expected values for these:
- air control from tick 1;
- a press within 5 ticks of landing kept, and 6 or 7 ticks before it dropped.

Every other check stays.

(Drafted by Claude Code on 21 Nov 2026 from the edge tests' measurements. Kept by me the same day: "Revise the brief", the choice that said the revision would state what the jump really does.)

---

### Revised 21 Nov 2026: the jump's frame strip

The strip above is the crouch jump's, from before the remodel. This one is the jump as it is now, for the preview `previews/jump_preview.tscn`.

- **The background:** the game's own level at night. He stands at the camp's edge by the fire (the developer menu's "free" point), at the game camera's pitch, yaw, field of view and distance, held where he took off, as the game's camera stays at a jump's take-off height.
- **The setup:** the campers' cones are off for the capture, so being seen doesn't break the jump off.
- **The trigger:** F is seen on **frame 10** at 30 fps, held, and let go once he's down. It's captured with `--fixed-fps 30 --quit-after 60`.
- **The log:** the preview writes `logs/jump_preview_frames.log`, one line a frame (the ticks since takeoff, his height, the game's state, the clip and its position), so frame N of the strip reads against line N.
- **The ticks:** at 30 fps each frame holds two physics ticks, and frame N shows the later one.

| Frame | Ticks since takeoff | What it should show (from the preview's headless log) |
|---|---|---|
| 10 | 0–1 | **Takeoff:** just off the ground (0.14 m), the push-off, hind legs extending (`jump` at 0 s) |
| 13, 14 | 6–9 | Rising (0.43, 0.48 m): stretched up, snout first (`jump` near its key at 0.125 s) |
| 16 | 12–13 | The peak (0.512 m, tick 13): gathering |
| 17 | 14–15 | **The top's boundary:** falling from tick 15, gathered (`jump` near its key at 0.25 s) |
| 21 | 22–23 | Coming down (0.11 m): front paws reaching for the ground |
| 22 | 24–25 | **Landing**, tick 25: touching down, squashed (`jump_land` at 0 s) |
| 27 | 34–35 | The landing's end: rising out of the squash, `jump_land` held at its last pose |
| 28 | 36–37 | **The landing's end**, tick 37: back in his stance (`idle`) |
| 40 | 60–61 | In his stance |

The frames to keep are 10, 13, 14, 16, 17, 21, 22, 27, 28 and 40. The rest of the sequence is deleted, as the course asks.

(Drafted by Claude Code on 21 Nov 2026 from the preview's headless run at 30 fps. What each frame should show is Claude Code's reading of the log, a prediction for me to check against the capture. Kept by me the same day: "Keep and commit".)
