# Change brief: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 6: particle effects · Draft v1, 7 Nov 2026 · branch `assignment-6`

The plan for this assignment's change, written before the work. As the course asks, this file now holds only Assignment 6. The earlier briefs are in history: Assignment 2 at tag `a2`, Assignment 3 at `a3`, Assignment 5 at `a5`. Later changes go below as dated revisions, and the original text stays.

**Before this brief** (6–7 Nov 2026, committed on this branch, not part of the effects): the camp grew and got a fourth camper, the tutorial at the camp was remade, the bush he dives into was added, and hiding was made safe. FRICTIONAL.md and TEST-REPORT.md have them.

**Status (7 Nov 2026).** Effect A, the leaves bursting out of the bush when he dives in or out, is written in full below. Effect B comes later, in a dated revision ("just do the effect A first we will work on effect B"). This brief is committed before the first prompt.

## The effects

| | What it is | Its job | Its event or condition |
|---|---|---|---|
| **Effect A: leaf burst** | A burst of leaves out of the bush he hides in | A one-shot on a gameplay event that repeats | He dives into the bush, or hops out of it |
| **Effect B** | To come (a dated revision) | Ambience, a feedback loop or a trail | — |

**My decision** (7 Nov 2026, from Claude Code's suggestion): Effect A is the leaf burst.

## Facts from the code

(Claude Code's, 7 Nov 2026, from the files named.)

**Effect A's event.**
- The camp's bush is a hiding spot with `dive` on (`scripts/hide_spot.gd`, built by `_build_bush()` in `scripts/campsite.gd` at `FIRE + BUSH`, 3.5 m west and 3 m south of the fire, by the trail's end).
- He dives in when he walks into it: a hop of `DIVE_TIME` 0.32 s to its middle (`dive_into()` in `scripts/player.gd`). Landed, `_hidden_in()` calls the bush's `dived(true)`.
- He hops out with a move key, 1.5 m clear (`DIVE_OUT`): `_stop_hiding()` calls `dived(false)`. Placing him somewhere (`place()`, the tests) and a startle also call it.
- `dived()` is where the bush's rustle starts today. Nothing signals it: the burst needs a signal there, or a call from it. That would be the one addition to the game's code.
- **How often:** he can hop out as soon as he's in, so an in and an out can come a fraction of a second apart. After coming out he can't dive in again for `DIVE_AGAIN` 0.6 s. The tutorial makes him dive in once (camp_tutorial.gd, "Hide!"), and the bush stays for free play.
- The bush is never freed.

**The view and the background, for scale and contrast.**
- **The window:** 1280 × 720 (`project.godot`). The camera: a 15° field of view from 19.2 m (`scripts/main.gd`), about **142 px per metre** at the default zoom, zoomable from 0.5 to 1.6 times that distance.
- **The raccoon:** about 0.61 m tall and 1.35 m long with his tail, so **about 87 px tall** on screen.
- **The bush:** one of the forest's bush meshes (`_bush_mesh(401)` in `scripts/forest.gd`), scaled 1.2: about 1.3 m across and 1 m tall, **about 185 px across**. Its colour is `BUSH` `#507548`, darkened for the night (`night_mesh`).
- **The ground round it:** the camp's night grass. Measured in Assignment 5 near the camp: about (34, 45, 49) and (58, 76, 82) in screen pixels. The forest's day colours: grass `#6e8a69`, fallen leaves `#c96a32`, `#d27f38`, `#b85a2e`, `#a8763a`, `#7d8a45` (`LEAVES`).
- **Light:** the fire's light (`FIRE_RANGE` 8 m, `scripts/campsite.gd`) reaches the bush, which is about 4.6 m from the fire.
- **Fog:** the level's depth fog starts at 18 m (`scripts/main.gd`), and the camera is 19.2 m away. A particle material that takes fog drifts toward the haze.
- **Already in the game:** the fire's sparks, a `CPUParticles3D` built in code (`scripts/campsite.gd`). Godot 4.7.2, Forward+ (`project.godot`).

---

## Effect A: leaf burst

### The job
- What the effect tells the player, and why the player needs it: the effect just tells that you've been hidden, or you jumped into the bushes to get hidden, and you're out of sight, basically, giving you an option to hide away from the chasing NPC, and deactivate the status of being caught, to reset the scenario for you. That helps in that particular case.

  (My answer to Claude Code's question, 7 Nov 2026, in my own words. Claude Code fixed the spelling and added commas.)
- The script and signal that hold its event: `dived()` in `scripts/hide_spot.gd` (see the facts above).

### The intent block
- Timing phases, with rough durations: strong on the first frame; out fast for about 0.15 s; then the leaves flutter down and fade, gone by about 0.9 s.
- Contrast against the background (the darkest and lightest ground round the bush): yellow-greens a little lighter than the bush, with a few of the forest's fallen-leaf oranges and browns, so they stand out against both the bush and the night grass.
- Scale against the raccoon: the leaves fly about 0.6 m past the bush's edge, a burst about 2.4 m across (roughly 340 px), a little wider than he is long.
- Change over life: fade only. Each leaf keeps its size and colour, and just fades out.
- Variation: the leaves' colours (the greens and browns above) and their speeds; nothing changes over a leaf's life but its fade.
- Each emitter and what it does: two under one root. The leaves tumble out and flutter down; a quick puff of small flecks (bits of leaf and dust) makes the first frame strong.
- Diving in and hopping out: a full burst as he dives in (hidden), a smaller one as he hops out (out of cover, seen again).

(Picked by me on 7 Nov 2026 from Claude Code's options. The two emitters, the size and timing, the colours, the node type below, the burst both ways and the overlap rule were its recommendations. Fade only was my own pick: Claude Code had recommended spin, drift, browning and a fade, and noted that the course warns a fade alone usually reads flat.)

### The settings
- The node type (CPU or GPU, 3D), and why: `GPUParticles3D`, the course's main path: its `ParticleProcessMaterial` is the one Step 6 turns into its shader, and it's priced on GPU time.
- Two `GPUParticles3D` under one root (`Node3D`), **Leaves** and **Puff**:

| Setting | Leaves | Puff |
|---|---|---|
| `amount` | 18 | 12 |
| `one_shot` | on | on |
| `explosiveness` | 0.9 | 1.0 |
| `lifetime` | 0.9 s | 0.35 s |
| `lifetime_randomness` (on the process material) | 0.2 | 0.0 |
| Emission shape | sphere, radius 0.55 m, 0.5 m up the bush | sphere, radius 0.4 m, 0.5 m up the bush |
| `direction`, `spread` | up (0, 1, 0), 70° | up (0, 1, 0), 180° |
| `initial_velocity_min` / `_max` | 2.0 / 3.2 m/s | 1.0 / 2.0 m/s |
| `gravity` | (0, −3.5, 0), light, so they float | (0, 0, 0) |
| `damping_min` / `_max` | 2.0 / 3.0 | 4.0 / 4.0 |
| `angle_min` / `_max` | 0° / 360° (a random start, no spin) | 0° / 0° |
| `scale_min` / `_max` | 1.0 / 1.0 (all one size) | 1.0 / 1.0 |
| `color_initial_ramp` | yellow-greens and browns, one picked at random per leaf | pale tan flecks |
| `color_ramp` (fade only) | alpha 1 until 66% of its life, then down to 0 | alpha down from 1 to 0 over its life |
| Mesh | a leaf quad 0.12 × 0.08 m, built in code | a quad 0.04 m |

- Draw (both): a `StandardMaterial3D`, unshaded, with `vertex_color_use_as_albedo` on (so the colour ramps show), alpha transparency (so the fade shows), and particle billboarding (`BILLBOARD_PARTICLES`, so the quads face the camera and take their angle). Blend: mix, not additive (leaves don't glow).
- `local_coords`: off. Once out, the leaves stay where they flew, in the world; the bush doesn't move anyway.
- `visibility_aabb` (both): set, 3.2 × 2.2 × 3.2 m round the bush (the 2.4 m burst and room to fall), and checked against the frame strip and in play near the screen's edge.
- `preprocess`: 0 (a one-shot has nothing to be running at load).
- Hopping out: the same burst with `amount_ratio` 0.5 (half the leaves and flecks).
- One burst per event (overlap): a fresh copy of the effect's scene at the bush each time, freed once both emitters are done.

(Claude Code's numbers to match my intent, used as my settings at my word, 7 Nov 2026: "Use these". Corrected by Claude Code the same day, before any build: its table first named the leaves' 0.2 as the node's `randomness`, which randomises when particles are emitted; the lifetime's randomness is the process material's `lifetime_randomness`.)

### Observable rules
- It fires on every dive in and every hop out, never otherwise (including on scene load), at the bush.
- The retrigger rule: overlap. Each event gets its own burst, and one still alive finishes. At most 2 alive at once: in, then straight out.
- If the node it would follow is freed on the same event: the bush is never freed, and each burst stands on its own at the bush, so nothing is cut off.

### The frame strip
- **The preview scene's background:** the real bush on the camp's night grass, at the game camera's angle and distance, with the fire's light, as in play.
- **The trigger** at frame 10, at 30 fps; the strip is frames 10, 12, 15, 20, 30 and 50 (the course's). What each should show:

| Frame | Time after the trigger | What it should show |
|---|---|---|
| 10 | 0 s | The trigger: flecks and the first leaves at the bush's top, bright |
| 12 | 0.07 s | Flecks spreading all round, leaves shooting up and out fast |
| 15 | 0.17 s | Leaves about 0.4 m out, the fast phase ending; flecks thinning |
| 20 | 0.33 s | Flecks gone; leaves slowed and starting to fall, the burst at its widest |
| 30 | 0.67 s | Leaves drifting down, starting to fade (66% of 0.9 s is 0.6 s) |
| 50 | 1.33 s | Nothing left |

(Claude Code's reading of my settings, used at my word, 7 Nov 2026.)

---

## Boundaries

(What this change must not touch.)
- Collision, movement, input, the campers' states and timings, the tutorial, the existing tests' expectations, my `shaders/`, and every other look stay as they are.
- The one addition to the game's code: a signal from the bush's `dived()`, for the burst to follow.
- Presentation code may read game state; it never writes it.

## The evidence split

| Rule | Checked by | How |
|---|---|---|
| Fires on every dive in and every hop out, never otherwise (including at scene load), at the bush | A headless state test | Through real input: walk into the bush, hop out with a move key; count the bursts and where they are |
| Overlap: in and straight out gives two bursts alive at once | A headless state test | The same test, in and out inside one lifetime |
| Every setting as this brief says | A headless configuration test | Loads the effect's scene and reads each setting back, with these values as the expected ones |
| How it reads: its timing, contrast and size | The frame strip, then my eyes | The strip against the frame table above; then in the running game at 1280 × 720 |
| Near the screen's edge (the visibility box) | My eyes | In play, with the bush at the edge of the screen |
| The price | The cost script and the Visual Profiler | A headless CPU price against an empty-scene control; GPU time with the effect off and on at its peak |

(Used at my word, 7 Nov 2026, as Claude Code proposed them: the boundaries and the evidence split.)

## Predicted failures

| # | What could go wrong | The check that would catch it |
|---|---|---|
| 1 | The colours don't show: `vertex_color_use_as_albedo` is off, so every leaf is white whatever the ramps say | The configuration test reads the flag; the frame strip |
| 2 | The fade doesn't show: the material isn't transparent, so the alpha fade does nothing and the leaves vanish all at once | The configuration test reads the transparency; the frame strip, frames 30 and 50 |
| 3 | The second burst is dropped: one one-shot node is reused, and setting `emitting` while it's still going does nothing, so hopping straight out shows no leaves | The state test: in and out inside one lifetime, two bursts alive |

(Picked by me on 7 Nov 2026 from Claude Code's options.)

## Price predictions and budget

| Effect | Peak particle count | Predicted headless CPU price | Predicted GPU time | Budget | Compared on |
|---|---|---|---|---|---|
| A: leaf burst | 45 (in, then straight out: 18 + 12, then half of each) | The same as the empty-scene control, within its spread: a headless run doesn't run the GPU's particle process | Under 0.05 ms at peak (45 small unshaded quads) | 0.2 ms of GPU time at peak | GPU time, from the Visual Profiler |

(Claude Code's reasoning, used as my predictions at my word, 7 Nov 2026.)

## Short answers

(Drafted by Claude Code on 7 Nov 2026 at my request, "Draft, I'll check"; checked by me before this brief was committed. My check, with notes I pasted in, changed two: answer 6 moves the emission shape to the process step, where Godot keeps it; and answer 1 now gives what the class reference says `amount_ratio` does. Claude Code kept answer 1 from calling it confirmed, since it hasn't been seen on this build, and corrected its own draft's claim that the state test checks the count: a headless run can only read the ratio. "Everything else looks good.")

1. **Which node type does each effect use, and which features in my brief does it lack (from the class reference for 4.7)?**
   Effect A uses two `GPUParticles3D`, each with a `ParticleProcessMaterial`. Every feature my brief uses is one this node has: one-shot bursts, explosiveness, a sphere emission shape, direction and spread, initial velocity, gravity, damping, a random start angle, the initial-colour and colour-over-life ramps, `amount_ratio`, `local_coords`, `visibility_aabb`, and a mesh drawn with particle billboarding. It lacks none of them. (The CPU node would lack the GPU-only features: turbulence, attractors, collision, sub-emitters and trails; Effect A uses none of those.) On `amount_ratio`: the class reference says the node then emits `amount × amount_ratio` of its particles, and that changing it doesn't restart the system, so at 0.5, set on the hop-out's copy before it emits, the burst should be 9 leaves and 6 flecks. The state test can only read that the ratio is 0.5 (a headless run emits nothing); the frame strip shows the count.
2. **With `local_coords` as I set it, what does Effect A do if its parent moves after the event?**
   It's off, so the particles live in world space. Leaves already emitted stay where they flew, in the world; only particles emitted after the move would start from the new place. A burst emits almost all of its particles on its first frame, so in practice nothing follows. Each burst is its own copy at the bush, and the bush never moves.
3. **Under my retrigger rule, how many Effect A bursts can be alive at once? What peak particle count does that give?**
   Two: a dive in, then a hop straight out, before the first burst's leaves are gone. A third can't come in time: after hopping out he can't dive in for 0.6 s, plus the 0.32 s hop, about 0.9 s or more, by which time the first burst's leaves (0.9 s at most) are gone. The peak is 45 particles: 18 leaves and 12 flecks for the dive in, and half of each (9 and 6) for the hop out. (Each copy still allocates its full 30, so 60 are allocated at that moment.)
4. **What will a headless run report as the cost of a GPU effect, and why? With vsync on, what would FPS read with the effect off and with it on?**
   Close to nothing: about the same as the empty-scene control. A headless run uses a dummy renderer, which doesn't run the GPU's particle process or draw anything, so only the nodes' small CPU-side work is measured. With vsync on, FPS reads the display's refresh rate both with the effect off and with it on, as long as each frame still fits in the refresh interval, so FPS hides the cost. GPU time from the Visual Profiler measures it.
5. *(For Effect B, with its revision.)*
6. **Which settings in my brief belong to emission, which to process, and which to draw?**
   - **Emission** (when particles appear, and how many, on the `GPUParticles3D` node): `amount`, `one_shot`, `explosiveness`, `lifetime`, `amount_ratio` (the smaller burst going out), and `preprocess`.
   - **Process** (where each starts, how it moves and how it changes over its life, in the `ParticleProcessMaterial`): the sphere emission shape and its radius (they decide where particles appear, but in Godot they're the process material's, and its shader places each particle in `start()`), `direction`, `spread`, `initial_velocity_min` and `_max`, `gravity`, `damping_min` and `_max`, `angle_min` and `_max`, `scale_min` and `_max`, `lifetime_randomness`, `color_initial_ramp` and `color_ramp`; and `local_coords`, which sets whether it all happens in world space or the node's.
   - **Draw** (what each looks like): the meshes (the leaf quad and the fleck quad) and their `StandardMaterial3D`: unshaded, `vertex_color_use_as_albedo`, alpha transparency, mix blending and `BILLBOARD_PARTICLES`; and `visibility_aabb`, which decides when it's culled from drawing. The colour ramps are worked out in the process step, but only show if the draw material uses vertex colour as albedo (my failure 1).

---

**Provenance.**
- **My decisions** (7 Nov 2026): the leaf burst as Effect A, from Claude Code's suggestion; its job, in my own words; its intent, rules, frame strip, boundaries, evidence split, predicted failures and price, picked from or taken as Claude Code proposed them, as marked under each; Effect B later.
- **Claude Code's contributions:** the suggestion and options, the facts from the code, the settings' numbers, the frame reading, the price reasoning, the drafts of the short answers, and this outline of the course's brief.
- **Generative models:** none.

---

### Revised 7 Nov 2026: the preview's retrigger frame

The course's preview scene triggers Effect A at frame 10 and, with its retrigger option on, again at a frame the brief gives; the brief above didn't give one.

- **The retrigger:** the hop-out burst (`amount_ratio` 0.5) at **frame 20**, 0.33 s after the dive-in burst at frame 10: a quick in and out.
- **What the strip should show then:** the first burst's leaves at their widest and still alive, and the smaller second burst starting at the bush, both at once (the overlap rule, two alive).

(Picked by me on 7 Nov 2026 from Claude Code's options, its recommendation, before the build.)

---

### Revised 7 Nov 2026: the signal's name, and the wiring Step 3 needs

Step 3's plan (a `claude -p` session, `design/a6/session-3.jsonl`) needs things the boundaries above don't allow, beyond the one signal.

- **The signal:** `hiding_changed(inside: bool)`, emitted at the end of the bush's `dived()` in `scripts/hide_spot.gd`: `inside` is true for a dive in, false for a hop out.
- **The wiring:** a few lines in `scripts/main.gd`'s `_ready()` that add the burst listener (presentation code, a new script) to the level beside the camp's bush; and a `--leaf-burst-test` flag in `scripts/main.gd`, in the pattern of `--cone-shader-test`, that starts the new state test in the real level with the tutorial skipped. Neither writes game state, and nothing in the game reads the listener.
- **Freeing a burst:** after its emitters' own lifetimes, read from the copy, plus a little, so the code holds no lifetime of its own.

(Picked by me on 7 Nov 2026 from Claude Code's options: the name; the wiring, with this revision on record; and the lifetimes read from the scene. The rest of the plan is the session's.)

---

### Revised 8 Nov 2026: Effect A's leaves fall faster (tuning r1)

- **Leaves `gravity`:** (0, −6.0, 0); it was (0, −3.5, 0). With the leaves' damping (2.0–3.0), −3.5 left them hanging where they stopped. At −6.0 they drift down after the burst, as the intent asks: "the leaves flutter down and fade".
- The settings table above keeps the first value, as the original text stays; this revision replaces it. The scene (`effects/leaf_burst.tscn`) and the configuration test have the new value.

(Kept by me on 8 Nov 2026 after play at 1280 × 720, from Claude Code's proposal in Step 4: TUNING.md, revision r1.)

---

### Revised 8 Nov 2026: Effect B, the campfire smoke

**Before this revision** (8 Nov 2026, game work, not part of the effects; TEST-REPORT.md has each):
- the campfire's life in the open world: its strength from 0 to 1, the keeper feeding it from a woodpile, and the bucket to douse it with E (`scripts/camp_fire.gd`);
- the firelight: while it burns, standing in its light, he's seen half as far again, and crouching cancels it (`in_firelight` in `scripts/campsite.gd`, FIRELIT_SIGHT in `scripts/camp_person.gd`);
- Dismantle the tent (`scripts/camp_tent.gd`);
- no laugh or food thought on reaching the camp, and no z's or boredom while hidden;
- the developer menu (F1, `scripts/dev_menu.gd`).

#### The job
- **What the effect tells the player, and why the player needs it:** The fire's smoke is the signal for an alert system, like the vision cones: if the fire is up, the smoke starts. When the fire is lit and the raccoon comes into the camp or near the fireplace, he has to crouch the whole time, or else he'll be detected more quickly.

  (My answer, 8 Nov 2026, in my own words. Claude Code fixed the spelling and commas and tightened the wording a little.)
- **Its condition:** the fire's `strength`, 0 (out) to 1, in `scripts/camp_fire.gd`; its signals `lit` and `doused`. The keeper raises it a log at a time, it burns down by itself, and the bucket puts it out.
- **Which job:** a feedback loop that follows a game value: `amount_ratio` follows `strength`.
- **The feature Effect A doesn't use:** the value-driven `amount_ratio`. It also uses turbulence, a scale curve (the puffs grow), a box emission shape, `preprocess` and a soft round texture, none of which Effect A has.

#### The intent block
- **Timing:** continuous while the fire burns. Each puff rises about 1.6 m over 3.5 s, slowing and spreading. Lit from cold, the column builds up over about 3 s. Doused, no new puffs come, and what's in the air rises away and is gone within 3.5 s.
- **Contrast against the background** (the night grass and the dark trees behind the fire): pale warm grey near the flames, cooling to blue-grey as it rises, at low alpha (at most 0.45). It's lighter than both, so it reads as a soft haze, not a solid column.
- **Scale against the character:** about 0.5 m wide at the pit, about 1.5 m wide at the top and about 2 m tall: taller than a camper, about three times the raccoon's height.
- **Change over life:** it grows (scale 0.4 → 1.6), fades in, then out (alpha 0 → 0.45 at 15% → 0), and goes from warm grey to blue-grey.
- **Variation:** a random start angle, size and speed; turbulence makes each puff drift differently.
- **Emitters:** one, **Smoke**.

#### The settings
- **The node type:** `GPUParticles3D`, because turbulence exists only on GPU particles, and its `ParticleProcessMaterial` is priced on GPU time like Effect A's.

| Setting | Smoke |
|---|---|
| `amount` | 40 |
| `one_shot` | off |
| `explosiveness` | 0 |
| `lifetime` | 3.5 s |
| `preprocess` | 3.5 s (a burning fire has its column on the first frame) |
| `lifetime_randomness` (on the process material) | 0.2 |
| Emission shape | box, extents 0.25 × 0.05 × 0.25 m, 0.35 m up the pit |
| `direction`, `spread` | up (0, 1, 0), 12° |
| `initial_velocity_min` / `_max` | 0.35 / 0.6 m/s |
| `gravity` | (0, 0.12, 0): it rises on its own heat |
| `damping_min` / `_max` | 0.1 / 0.2 |
| `turbulence_enabled`, `turbulence_noise_strength`, `turbulence_noise_scale` | on, 0.6, 2.0 |
| `angle_min` / `_max` | 0° / 360° |
| `scale_min` / `_max` | 0.8 / 1.2 |
| `scale_curve` | 0.4 → 1.6 over its life |
| `color_ramp` | alpha 0 → 0.45 at 15% → 0; warm grey `#9b938a` → blue-grey `#6f7a85` |
| Mesh | a 0.5 m quad |

- **Draw:** a `StandardMaterial3D`, unshaded, with `vertex_color_use_as_albedo` on, alpha transparency, mix blending and `BILLBOARD_PARTICLES`. Its `albedo_texture` is a soft disc, a radial `GradientTexture2D` written in the scene file (no image file).
- **`local_coords`:** off. The pit doesn't move, and smoke already in the air stays where it rose.
- **`visibility_aabb`:** 3 × 4 × 3 m round the pit: set, and checked in the strip and in play near the screen's edge.
- **The feedback:** every frame, `amount_ratio` = the fire's `strength`. `amount` never changes after load.
- **Where:** at the fire pit, placed by presentation code that reads `strength` and writes nothing but the effect.

#### Observable rules
- It follows the fire: `amount_ratio` equals `strength`, so it's 0 out (no new smoke), 0.3 on one log, and 1 at full.
- It starts when the fire's lit and stops when it's out (doused, or burnt down). A stop lets the air clear; it doesn't cut the smoke off.
- At scene load: a burning fire has its column (`preprocess`); a cold fire has none.
- While the tree is paused: frozen in the air, and it carries on afterwards.
- While it's hidden: not drawn, and its settings and `amount_ratio` don't change. Whether the GPU keeps simulating it while hidden can't be seen headless; that's for my eyes in play.

#### The evidence split
| Rule | Checked by | How |
|---|---|---|
| `amount_ratio` follows `strength`, at two values at least, and `amount` never changes | A headless state test | Through the game: the keeper lighting and building the fire, and the bucket tipped with E |
| It starts when the fire's lit and stops when it's out | A headless state test | Reads `amount_ratio` and `emitting` across the same events |
| Paused and hidden | A headless state test, then my eyes | Reads the node's state; the look in play |
| Every setting as this brief says, the feature included | A headless configuration test | Loads the scene and reads each setting back |
| How it reads: timing, contrast and size; at scene load | The frame strip, then my eyes | The strip against the table below; then in the running game at 1280 × 720 |
| The price | The cost script and the Visual Profiler | As for Effect A |

#### The frame strip
- **The preview's background:** the real fire pit at the game camera's angle and distance, as in play.
- **The condition:** the fire lit from cold at frame 10 (three logs: strength 0.9), and doused at frame 100. The frames to read are 10, 25, 55, 100, 110 and 160, at 30 fps, captured with `--quit-after 180`.

| Frame | Time | What it should show |
|---|---|---|
| 10 | lit | The first puffs at the pit |
| 25 | 0.5 s | A short column starting to rise |
| 55 | 1.5 s | The column building, puffs growing as they rise |
| 100 | 3 s, doused | The full column, about 2 m; the fire goes out |
| 110 | 0.33 s after | No new puffs at the pit; the column rising away |
| 160 | 2 s after | The last puffs high up, faint |

#### Predicted failures (Effect B)
| # | What could go wrong | The check that would catch it |
|---|---|---|
| 4 | The popping loop: the code changes `amount`, not `amount_ratio`, so the smoke vanishes and re-emits at every change | The state test asserts `amount` never changes |
| 5 | Turbulence isn't on (left off, or a name the class doesn't have), so the puffs rise in straight lines | The configuration test reads `turbulence_enabled`; the strip |
| 6 | The texture's null, so each puff is a hard grey square | The configuration test reads the texture; the strip |
| 7 | `preprocess` is 0, so a burning fire at scene load has no column for 3.5 s | The configuration test; my eyes at scene load |

#### Price
| Effect | Peak particle count | Predicted headless CPU price | Predicted GPU time | Budget | Compared on |
|---|---|---|---|---|---|
| B: campfire smoke | 40 | The same as the empty-scene control, within its spread | Under 0.1 ms (40 soft, see-through quads that overlap) | 0.3 ms of GPU time | GPU time, from the Visual Profiler |

#### Short answers, for Effect B
1. **Node type, and features it lacks:** `GPUParticles3D`, as for Effect A. Every feature this brief uses (turbulence, the scale curve, the box shape, `preprocess`, `amount_ratio`, `visibility_aabb`) is one it has.
4. **The headless cost:** close to nothing, for the same reason as Effect A: the dummy renderer runs no GPU particle process. With vsync on, FPS reads the refresh rate with it off and on.
5. **What it shows on the first frame after its scene loads, with `preprocess` and without; while paused; while hidden:** with `preprocess`, over a burning fire, the full column; without it, nothing, filling in over 3.5 s. Paused: frozen. Hidden: not drawn.
6. **Emission, process and draw:** emission is `amount`, `one_shot`, `explosiveness`, `lifetime`, `preprocess` and the `amount_ratio` it's driven by. Process is the box shape and offset, `direction`, `spread`, the velocities, `gravity`, damping, turbulence, the angles, the scales and `scale_curve`, `lifetime_randomness`, `color_ramp` and `local_coords`. Draw is the quad, its `StandardMaterial3D` and texture, and `visibility_aabb`.

(The job is my own words. The rest is Claude Code's options from 8 Nov 2026, used at my word.)

---

### Revised 8 Nov 2026: Effect B's wiring, for Step 3

Step 3's plan for Effect B (a `claude -p` session, `design/a6/session-6.jsonl`) needs the following, which the revision above allows only in general terms.

- **The driver:** a new presentation script, `scripts/campfire_smoke.gd`, that makes one copy of the smoke at the fire pit. Every frame it sets the copy's `amount_ratio` to the fire's `strength`, and `emitting` to whether the fire is burning. It sets the copy's state before adding it, so a cold fire doesn't preprocess a column. It reads `strength` and `burning()` and writes nothing outside its copy; `amount` and the scene's settings are never touched.
- **The wiring:** a few lines in `scripts/main.gd`'s `_ready()` that add the driver after the developer start points have set the fire. Two flags in the `--leaf-burst-test` pattern start the new state test in the real level: `--smoke-test` with the fire cold, and `--smoke-load-test` with it burning.
- **The preview:** one line in `previews/campfire_smoke_preview.gd`, so that it removes the game's copy and its strip shows only its own.
- **Hidden:** while the smoke is hidden, `amount_ratio` keeps following `strength`, so there's no jump when it's shown again. This replaces the rule above that hidden means `amount_ratio` doesn't change; its settings still don't.

(Picked by me on 8 Nov 2026 from Claude Code's recommendations, "Approve all three": the hidden rule, this revision on record for the wiring, and the preview's line. The rest of the plan is the session's.)
