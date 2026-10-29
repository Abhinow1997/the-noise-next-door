# Change brief: The Noise Next Door

`the-noise-next-door` · CSYE 7270

The plan for each assignment's change, written before the work. Each assignment's brief is its own section; later changes are dated revisions inside it, and the original text stays.

| Section | Written | Submitted as |
|---|---|---|
| [Assignment 2: the asset slice](#assignment-2-the-asset-slice) | 6 Oct 2026, drafts v1 to v3 | tag `a2` |
| [Assignment 3: three 3D assets from Blender](#assignment-3-three-3d-assets-from-blender) | 13 Oct 2026, revised to v4 on 14 Oct | tag `a3` |
| [Assignment 5: shaders and materials](#assignment-5-shaders-and-materials) | 25 Oct 2026, revised 28 and 29 Oct | branch `assignment-5`, not tagged yet |

---

## Assignment 2: the asset slice

`the-noise-next-door` · CSYE 7270 · Assignment 2 · Draft v3, 6 Oct 2026

The plan for the asset slice: what goes into it, which sound plays on which event, how the music behaves, and what I expect to go wrong.

**When this was written.** :
- the style target is from 1 Oct;
- the first raccoon pose images are from 2 Oct, 17:09;
- the forest music loop is already in the game.

Everything below was still decided before any generated art went into the game. It also comes before the ground texture and three of the four sound effects are generated.

**Revised in v2 (6 Oct 2026): the four sounds.** After v1, I generated running and climbing sounds instead of the three v1 planned (grab, flourish and "ta-da"). I chose to build the slice from the sounds I'd made:
- running and climbing, as loops;
- my two laugh takes: one for the chitter, one for a ticked-off task.

Each changed section keeps its v1 text, marked as the earlier plan.

**Revised in v3 (6 Oct 2026): a stump instead of the ground.** I tried my ground texture on the forest floor in the game and didn't like it ("i dont like the ground", 22:20), so the slice keeps the plain grass. Its environment asset is now a generated tree stump (22:24), cut out like the raccoon and placed in the clearing with collision.

### The slice

The forest clearing already in the game, around the raccoon's home pine, with its five to-do tasks: knock over the trash bin, steal the bin lid, stash 3 cans in the den, kidnap the garden gnome, and sneak into the den for a nap. The player moves the raccoon with the keyboard. His look swaps between generated images as his state changes, the four sounds fire on real events, and the music loops.

This is smaller than the slice in CONCEPT.md, which has the campsite, a camper with a routine, and the marshmallow and cocoa jobs. There are no humans in this slice, so there's no failure (busted) state yet.

| Storyboard panel | Covered? |
|---|---|
| 1 Good vibrations | Partly: he sleeps in the hollow (CHAR-SLEEP), but there's no party bass waking him |
| 3 Dropping in | Partly: play starts by his tree with the to-do list, but there's no party |
| 5 Paws on the zipper | The interaction, as grabbing the bin lid, cans or gnome |
| 6 Music off | The payoff: a to-do line struck through with the piano flourish |
| 2, 4, 7–15 | No. They need the party, humans, the beanie or the town. Panel 4's to-do list exists in the game, but as a text card, not a close-up. |

*Revised in v2:* in panel 6's payoff, my laugh (SFX-TASK-LAUGH) replaces the piano flourish.

### Asset list

#### Revised in v2 (6 Oct 2026): the sounds and the ground

| ID | What | In the slice | Panels | Status |
|---|---|---|---|---|
| SFX-RUN | `assets/audio/sfx/run-loop.wav`, a loop cut from my running sound | While he runs (Shift) | 3, 5, 6, moving between jobs | Done: looped and imported |
| SFX-CLIMB | `assets/audio/sfx/climb-loop.wav`, a loop cut from my climbing sound | While he moves on a trunk | 3 (stands in for SFX-SLIDE) | Done: looped and imported |
| SFX-CHITTER | Laugh take A, `design/music/raccoon-cheeky-laugh.mp3` | The chitter (Space) | None: it's the raccoon's voice from the prototype | Have it; convert to WAV |
| SFX-TASK-LAUGH | Laugh take B, `design/music/raccoon-cheeky-laugh-2.mp3` | A to-do item ticked off | 6 (replaces SFX-FLOURISH) | Have it; convert to WAV |
| ENV-GROUND | `design/reference/ENV-GROUND.jpg` (Gemini), generated at 20:42 | The clearing's ground | 3, 5, 6 | Have it. It may need darkening, because his fur is as bright as it (CHARACTER-SHEET.md v5). |
| SFX-GRAB, SFX-FLOURISH, SFX-ALL-DONE | — | Dropped | — | Not generated |

The v1 table below still holds for the raccoon's images and the music. For the sounds and the ground, the table above replaces it.

#### Revised in v3 (6 Oct 2026): the environment asset

| ID | What | In the slice | Panels | Status |
|---|---|---|---|---|
| ENV-STUMP | A low-poly tree stump (Gemini, prompt below), cut out like the raccoon | It stands in the clearing near where he starts, and he walks round it, because it has collision | 3, 5, 6: the clearing | To generate |
| ENV-GROUND | `design/reference/ENV-GROUND.jpg` | Rejected in the game; the texture is switched off with `GROUND_TEXTURE` in `scripts/main.gd` | — | Not used |

*Update, 6 Oct, 22:28:* I generated ENV-STUMP (`design/reference/stump.jpg`), two minutes after v3 was committed.

#### Generated (these count for the brief)

| ID | What | In the slice | Panels | Status |
|---|---|---|---|---|
| CHAR-IDLE | Pose 3, `design/reference/raccoon/idle.jpg` (Gemini) | Standing still | 3, 5, 6 | Have it; green background |
| CHAR-RUN | Pose 7 without the beanie, `running.jpg` (Gemini) | Walking and running | 3, 5, 6 | Have it, but on a scene background, so it needs a careful cut-out. If the edge is poor, regenerate it on green with prompt P. The storyboard's CHAR-RUN in panels 11–12 is the same pose with the beanie. |
| CHAR-SNEAK | Pose 6, `sneak.jpg` (Gemini) | Sneaking (Ctrl), moving or still | 5 | Have it; green background |
| CHAR-BORED | Pose 4, `bored.jpg` (Gemini) | No input for 5 seconds | 3, 5, 6 | Have it; green background |
| CHAR-SLEEP | Pose 12, `asleep.jpg` (Gemini) | Asleep in the hollow (the nap task) | 1 | Have it; green background |
| CHAR-CLIMB | Climbing a trunk (prompt below) | Climbing | 3 | Optional. Without it, climbing shows CHAR-SNEAK turned upright, and that edit gets logged. |
| ENV-GROUND | A tiling grass texture (Gemini, prompt below) | The clearing's ground | 3, 5, 6 | To generate |
| SFX-GRAB | A short grab sound | Picking something up | 5 (stands in for SFX-ZIP) | To generate |
| SFX-FLOURISH | A short piano flourish | A to-do item ticked off | 6 | To generate |
| SFX-CHITTER | `raccoon-cheeky-laugh.mp3` or `-2.mp3` (two different takes) | The chitter (Space) | None: it's the raccoon's voice from the prototype | Have it. Pick a take, and convert it to WAV, because MP3s stay out of the repo. |
| SFX-ALL-DONE | A short piano "ta-da" | The last task done | Stands in for panel 8's sting, since the slice has no getaway | To generate |
| MUS-PIANO-LOOP | `assets/audio/music/forest-loop.wav` | The level's music | 3–6 | Done, and playing in the game |

#### Not generated (listed so the slice is complete; they don't count)

- **The forest, its trees, bench, bin, cans and gnome:** Claude's code, in `scripts/forest.gd`.
- **The to-do list and the "all done" banner:** code, in `scripts/main.gd`.
- **The Blender raccoon (`raccoon.glb`):** Claude's model. It stays in the project, but the slice shows the generated images instead.
- **The code-made chitter tone:** replaced by SFX-CHITTER.

### The raccoon's images in the game

- **One image per state.** When more than one state applies, the first in this order wins: asleep, climbing, sneaking, moving, bored, idle. While he carries something, he keeps his current state's image, and the object is drawn at his mouth. The hop up into the hollow uses CHAR-RUN.
- **Facing:** every image faces front-right, and the game mirrors it when he moves left on screen. Moving straight up or down the screen keeps his last facing. There are no back views, so walking away from the camera still shows his front.
- **Cut-outs:** the green is removed with a colour key, and each image is cropped to the raccoon. All five are scaled to the same body size, so swapping states doesn't make him jump in size. Every edit goes in the asset log.
- **Size and collision:** he collides as a capsule lying along his body, 0.64 m long and 0.32 m wide and tall, with its bottom at his feet (`scripts/player.gd`). CHARACTER-SHEET.md still gives 0.8 m by 0.4 m, which was before the size setting of 0.8 was added; the sheet will be corrected.
  - Each image is placed so his paws stand on the capsule's bottom, at the size the camera and level were tuned for.
  - His head, ears and tail reach past the capsule. That's fair, as the sheet says, because nothing in the game needs to hit them.

### Event-to-sound map

**Revised in v2 (6 Oct 2026):**

| Sound | The exact event in the code | What shows it with sound muted | How it plays only once |
|---|---|---|---|
| SFX-RUN | `_walk_process()` in `player.gd`. It starts when he goes faster than walking speed with Shift held and isn't sneaking. It stops when he slows to a walk, stops, sneaks, starts climbing or hops into the hollow. | His image is CHAR-RUN | One looping player, started only on the change into running. A held Shift keeps one loop going, and quick on-off presses stop and restart it rather than stacking copies. |
| SFX-CLIMB | `_climb_process()` in `player.gd`. It starts when he moves on the trunk, whether up, down or round. It stops when he clings still, hops off or climbs into the hollow. | His climbing image, moving on the trunk | As for SFX-RUN |
| SFX-CHITTER | `chitter()` in `player.gd` (Space), through its `chittered` signal | The image gives a quick squash and hop | Key repeats are ignored. Pressing again while it plays restarts the one player, rather than stacking a second copy. |
| SFX-TASK-LAUGH | `_check_tasks()` in `main.gd`, when a task's `done` flips from false to true, including the last task | The to-do line is struck through | `done` never flips back, so each task plays it once, and at most once per frame |

*As planned in v1:*

| Sound | The exact event in the code | What shows it with sound muted | How it plays only once |
|---|---|---|---|
| SFX-GRAB | `_grab()` in `player.gd`, at the moment it takes hold of an object. Pressing E with nothing in reach plays nothing. | The object appears in his mouth | Key repeats are ignored (`is_action_pressed` skips echoes), so holding E grabs once. Dropping is a different event and has no sound. |
| SFX-FLOURISH | `_check_tasks()` in `main.gd`, when a task's `done` flips from false to true | The to-do line is struck through | `done` never flips back, so each task plays it once. At most one flourish per frame. On the last task, SFX-ALL-DONE plays instead. |
| SFX-CHITTER | `chitter()` in `player.gd` (Space), through its `chittered` signal | The image gives a quick squash and hop | Key repeats are ignored. Pressing again while it plays restarts the one player, rather than stacking a second copy. |
| SFX-ALL-DONE | `_check_tasks()` in `main.gd`, on the first frame when every task is done, where the banner turns on | The "all done" banner | A flag makes it fire once. It replaces SFX-FLOURISH on that frame. |

**Sound never decides what happens.** Each sound plays after the code has already changed the game's state, and nothing reads a sound back. Music and effects play on separate audio buses, so muting one doesn't touch the game.

### Music behaviour

| Moment | What the music does |
|---|---|
| Start | The forest loop fades in over 2 seconds, as now. |
| Pause (Esc) | The game pauses. The loop keeps playing, muffled (a low-pass filter) and about 8 dB quieter, and the effects pause. Unpausing restores both. This follows CONCEPT.md: "Pausing muffles it". |
| Success: a task ticked off | The flourish plays over the loop, and the loop dips about 4 dB under it. |
| Failure | Doesn't happen in this slice, because there are no humans. In the full game, the loop cuts out for a beat when he's caught (CONCEPT.md, storyboard panel 7). |
| End: all five tasks done | SFX-ALL-DONE plays, and the loop fades out over 3 seconds, leaving the clearing quiet (pillar 3, Home should be quiet). |
| Mute | M turns the music on and off, and N does the same for the effects. The on-screen controls line shows both. |

*Revised in v2:*
- When a task is ticked off, my laugh plays over the loop instead of the flourish, and the loop still dips about 4 dB under it.
- At the end there's no "ta-da": the last task's laugh plays, and the loop fades out over 3 seconds.

### Predicted failures, and how I'll check each

1. **The poses don't match.** The five images may differ in size, proportions or colour, so he visibly pops when his state changes.
   - *Check:* scale the cut-outs to the same body length and compare them side by side against the sheet's consistency rules. Then screenshot every state at the same spot in the game.
2. **He disappears into the ground.** The character sheet already measured his grey fur at almost the same brightness as the daytime grass (1.1:1).
   - *Check:* the silhouette test at 64 and 128 px; the contrast between his fur and ENV-GROUND, measured from a game screenshot; and a muted playtest at the default zoom and both zoom limits.
   - *If it fails:* change the ground texture, not the raccoon.
3. **The cut-outs keep a green fringe,** or lose the tail tip.
   - *Check:* zoomed-in crops of every state against the ground.
4. **The art doesn't line up with the collision.** His paws float above the ground, or his body sits off the capsule.
   - *Check:* screenshots with Godot's collision shapes shown, for every state and both facings.
5. **A sound plays twice.** For example, the flourish and the "ta-da" together on the last task, a held E repeating the grab, or a task sound every frame.
   - *Check:* an automated test plays a scripted input sequence and counts the plays of each sound against the expected numbers. The sequence covers rapid E presses, a held E, rapid Space presses and finishing all five tasks.
6. **The loop clicks, or pause breaks it.** It might click at the wrap, or stay muffled after unpausing.
   - *Check:* I listen to at least three repetitions. The automated test also checks the WAV's loop points, and that the muffling is off again after unpausing.
7. **His facing flickers.** Mirroring by screen direction makes him flip back and forth when he moves straight up or down.
   - *Check:* walk in all eight directions and screenshot each.
8. **It's unreadable muted.** Every sound has a visual partner, listed in the event map.
   - *Check:* my own muted playtest.
9. *(Added in v2)* **A loop misbehaves.** The running or climbing loop restarts every frame, keeps playing after he stops, or stacks a second copy. This replaces failure 5's flourish and "ta-da" case.
   - *Check:* the automated test starts and stops running, toggles Shift quickly and holds it, and climbs and clings still. It checks that each loop starts once per stretch and is silent whenever he isn't moving that way.
10. *(Added in v2)* **The two laughs blur together.** The chitter and the task laugh are takes of the same laugh, so with sound on a player might not tell them apart.
    - *Check:* my playtest. Muted play isn't affected, because each has its own visual: the squash and hop, and the struck-through line.
11. *(Added in v3)* **The stump looks pasted on.** A flat image standing in a 3D clearing may float without a shadow, sit at the wrong size next to him, or let him walk through it.
    - *Check:* a screenshot from the game camera with him beside it, and walking into it from several sides.

### Prompts for what's still to generate

Every prompt avoids brands, named artists, copyrighted characters and existing recordings. Each prompt, setting and take goes in the asset log.

**ENV-GROUND** (Gemini, square image):
> A seamless, tileable texture of a forest clearing floor seen from directly above: short mossy grass in muted sage and olive greens, with a few scattered fallen leaves and tiny pebbles. Low-poly style: large faceted patches of flat colour, at most one shadow tone per colour, no fine noise, no strong highlights, soft shadowless light. A mid-dark green, darker than a bright lawn. No objects, no tall plants, no border, no vignette, no text, no watermark.

**SFX-GRAB** (sound-effect model):
> A short, soft cartoon grab: a quick rustle and a little pop as a small animal snatches something in its teeth. Light, playful, dry and close. Under half a second. No voice, no music.

**SFX-FLOURISH** (sound-effect or music model). It matches the loop's warm upright piano and key of F major:
> A short, playful solo piano flourish: a quick rising run ending on a bright, light F major chord, played softly on a warm upright piano with soft hammers in a dry small room. About one second. No other instruments.

**SFX-ALL-DONE** (sound-effect or music model):
> A short, cheeky solo piano "ta-da": a playful two-note pickup into a bright F major chord with a little grace-note slide, on a warm upright piano with soft hammers in a dry small room. About two seconds, ending cleanly with a short natural decay. No other instruments, no voice.

**CHAR-CLIMB** (Gemini, optional). Attach `idle.jpg` as the reference:
> Use the attached raccoon as the exact reference: keep his proportions, face pattern, colours, five tail rings, low-poly faceted finish and camera angle exactly the same. Change only his pose: clinging to a vertical tree trunk with all four paws, body upright, climbing upward, head turned toward the camera. Show only a short section of plain brown trunk. Full body in frame and centred. No cast shadow. Plain, flat, solid bright green background (#22C55E), no floor, no gradient. Square image. No text, no watermark.

For each sound: trim the silence at the front so it starts at once, and save it as WAV or OGG.

*Revised in v2:* the SFX-GRAB, SFX-FLOURISH and SFX-ALL-DONE prompts aren't needed, because the slice uses the sounds I generated.

**ENV-STUMP** (Gemini, added in v3). Attach `design/reference/raccoon/idle.jpg` as the style reference:
> Use the attached raccoon only as the style reference, and don't include him. Make a single low-poly tree stump for a cozy cartoon forest game, in exactly his style: chunky faceted shapes with flat-shaded facets and crisp edges, no outlines, no fine texture. A short, wide stump about knee height, with a flat cut top showing pale wood rings, warm brown bark in a few large facets, and two or three thick roots flaring out at the base. No moss, no leaves and nothing green on it. Seen from the same high three-quarter angle as the raccoon, as if the camera is above and in front, looking down. Soft light from the upper left. The whole stump in frame and centred, with space around it. No cast shadow. Plain, flat, solid bright green background (#22C55E), no floor, no grass, no gradient. Square image. No text, no watermark.

### Order of work

1. Cut out the five poses, scale them, and put them in the game in place of the model, with the state swaps and mirroring.
2. Generate ENV-GROUND, make it tile, put it on the ground, and check the contrast.
3. Generate SFX-GRAB, SFX-FLOURISH and SFX-ALL-DONE, pick the chitter take, then trim and convert all four.
4. Wire up the sounds, the two buses, mute, pause and the end of the slice.
5. Add the automated sound-count test.
6. Playtest it myself with sound on and then muted, and write TEST-REPORT.md.

*Revised in v2:* step 3 is now: convert and trim the two laugh takes. The running and climbing loops are done.

*Revised in v3:* step 2 is now: generate the stump, cut it out, and place it in the clearing with collision and a shadow.

---

**Provenance.**
- **My decisions,** answered in chat on 6 Oct 2026:
  - the slice is the forest clearing already in the game, with its five tasks;
  - my generated poses appear as flat cut-outs, swapped per state;
  - the four sound events are grab, a task ticked off, the chitter, and all tasks done;
  - the environment asset is a generated ground texture;
  - CHARACTER-SHEET.md switches to the low-poly look of my poses, in a dated revision still to be written.
- **Claude's contributions:**
  - the draft and its wording;
  - the order in which state images win, and the double-trigger rules;
  - the music numbers (8 dB, 4 dB, 3 s);
  - the failure predictions and their checks;
  - the prompts above;
  - noticing that the collision capsule is now 0.64 m, not the sheet's 0.8 m.
- **My decision for v2** (6 Oct 2026, 22:02): use only the sounds I've generated, which are running, climbing and my two laugh takes. Take B plays on a ticked-off task, in place of the piano flourish. All the sounds are mine.
- **My decision for v3** (6 Oct 2026): at 22:20, after seeing my ground texture on the forest floor: "No the forest resort the previous verison i dont like the ground". At 22:24 I chose a generated tree stump as the environment asset instead.
- **Claude's v3 contributions:**
  - the four replacement options;
  - the stump prompt;
  - how the stump goes into the game;
  - failure 11.
- **Claude's v2 contributions:**
  - the running and climbing loop cuts;
  - when each loop starts and stops;
  - the new IDs SFX-RUN, SFX-CLIMB and SFX-TASK-LAUGH;
  - failures 9 and 10;
  - the v2 wording.
- **Generative models:** none were used to write this.

---

## Assignment 3: three 3D assets from Blender

`the-noise-next-door` · CSYE 7270 · Assignment 3 · Draft v0, 13 Oct 2026 · branch `assignment-3`

Three simple props for the campsite. Each is built in Blender through the Blender MCP, exported as a `.glb`, and shown with the others in a Godot 3D scene. This section is the plan, written before anything is built. Later changes go below it as dated revisions; the original text stays.

**Status (13 Oct 2026).** The three assets are chosen, and nothing has been built yet. Next I'll write each asset's size, origin, colours and triangle budget, plus my predicted failures. They come after my first session looking round Blender's window (the assignment's "Learn the window" step) and are committed before the first build.

### The three assets

| Asset | What it is in the game | Where it appears | Who chose it |
|---|---|---|---|
| S'more | A snack the raccoon tries to steal | The campers' campfire site | Me, 13 Oct 18:18: "maybe smores ? like from the campfire site where the raaccoon will try and steal them ?" |
| Pizza slice | Another snack to steal | Not decided yet | Me, in the same message: "we can try those and then pizzas slices" |
| Cooler | A campsite cooler to raid | Not decided yet | Me, 13 Oct 18:21, from three options Claude offered (a campfire, a pizza box, a cooler). I didn't give a reason. |

The level has no campfire site yet; in the story it belongs to level 1, the campers' party. For this assignment the three assets are shown in a small Godot scene of their own, beside the raccoon for scale. Putting them into the level comes later.

### Limits for every asset (the course's, for this assignment)

- Built mainly from Blender's basic shapes (cube, cylinder, cone, sphere, plane): at most 6 shapes and at most 500 triangles each.
- Flat-colour materials. No sculpting, painted textures, rigging or animation.
- Each asset in its own `.blend`, built around Blender's world origin with its base on the floor there.
- 1 Blender unit is 1 metre, and so is 1 Godot unit, so nothing is converted.
  - Blender is Z-up. The glTF exporter's +Y Up option, its default, turns that into Godot's Y-up.
- Nothing downloaded or generated:
  - the add-on's Poly Haven, Sketchfab, Poly Pizza, Hyper3D, Hunyuan3D and Tripo options stay off;
  - `generate_3d`, `search_assets` and `import_asset` are never called.

### Measured from the game, for sizing (Claude Code, 13 Oct)

| What | Value | Where it comes from |
|---|---|---|
| The raccoon | About 0.61 m tall and 0.52 m wide. He's 1.35 m long, tail included. | `raccoon_v2.blend`'s mesh (0.767 × 0.649 × 1.688), times the game's `size` of 0.8 (`scripts/player.gd`) |
| His collision capsule | 0.64 m long and 0.32 m across. It lies along his body. | `scripts/player.gd` |
| How big things look | About 214 pixels per metre at 1080p, at the default zoom. That makes the raccoon about 130 px tall. | The camera is 19.2 m away with a 15° field of view (`scripts/main.gd`): 1080 ÷ (2 × 19.2 × tan 7.5°) |
| Today's props, for comparison | Bin Ø 0.60 × 0.76 m; can Ø 0.12 × 0.16 m, about 1.3 times a real drink can; gnome about 0.46 m tall | `_build_props()` in `scripts/main.gd` |

**Provenance (Assignment 3).**
- **My decisions:** the s'more and the pizza slice (my idea) and the cooler (my pick from Claude's options).
- **Claude's contributions:** the options for the third asset, this draft and its wording, and the measurements above.
- **Generative models:** none.

### Revised in v1 (14 Oct 2026): sizes, origins, looks, budgets and predicted failures

Written after my first session in Blender (13 Oct; see [BLENDER-NOTES.md](BLENDER-NOTES.md)) and **before any asset is built**. The table of assets above keeps its 13 Oct text; where it says "Not decided yet", the decision is here.

**My choices** (14 Oct, 00:15, picked from options Claude offered):
- the s'more and the pizza slice are **life size**;
- the cooler is a **medium, life-size** one;
- they're **spread around the camp**: the s'mores by the campfire, the pizza slice on the picnic bench, the cooler beside a tent;
- the three failures I predict are below.

#### For every asset

- **Axes.** Blender is Z-up, and the asset's front faces −Y (what Blender's front view, Numpad 1, shows). The glTF exporter's +Y Up option turns that into Godot's +Y up, with the front facing +Z.
- **Origin.** The centre of the underside, on Blender's world origin, with the base on the floor at Z = 0. Why: in Godot, placing the asset at a point on the floor stands it on that point, and turning it round its vertical axis keeps it in place.
- **Transforms.** Rotation and scale are applied before export, so the Godot node's scale is 1, 1, 1.
- **Materials.** One flat colour per part, set on the Principled BSDF's Base Color. The colours below are sRGB hex.

#### The s'more

| | |
|---|---|
| Size (W × D × H) | **0.065 × 0.065 × 0.04 m** |
| Why that size | Life size: a graham cracker square is about 6.5 cm. It's smaller than the game's drink can (Ø 0.12 × 0.16 m), which the raccoon already carries in his mouth. At the default zoom it's only about 14 px across on a 1080p screen, so whether it reads at all is part of my look check. |
| Parts (4 shapes) | Bottom cracker: a cube, 0.065 × 0.065 × 0.008. Chocolate: a thin cube, 0.045 × 0.03 × 0.004. Marshmallow: a 12-sided cylinder, Ø 0.045 × 0.02. Top cracker: a cube, 0.065 × 0.065 × 0.008. Stacked from Z = 0 to 0.04. |
| Colours | Cracker tan `#C8955A`, chocolate `#4A2C1D`, marshmallow off-white `#F4EEE0` |
| What makes it recognisable | Two pale square crackers with a white layer squeezed between them, and a dark edge of chocolate |
| Triangle budget | **100**. About 80 by count: 12 per cube, and 44 for a 12-sided cylinder. It's tiny on screen, so detail there would be wasted. |

#### The pizza slices

| | |
|---|---|
| Size (W × D × H) | **0.15 × 0.20 × 0.02 m**: 0.15 wide at the crust, 0.20 from the crust to the tip, 0.02 tall at the crust |
| Why that size | Life size: one slice of a 16-inch pizza cut in eight. That's about a seventh of the raccoon's length with his tail (1.35 m), and about 43 px long on screen. |
| Parts (5 shapes) | Base and cheese: a 3-sided cylinder (a triangular prism) stretched into the wedge, 0.008 thick. Crust: an 8-sided cylinder lying along the back edge. Pepperoni: three flat 10-sided cylinders on the cheese. The tip points to the front (−Y). |
| Colours | Crust `#D9A55B`, cheese `#F2C14E`, pepperoni `#B23A2E` |
| What makes it recognisable | The triangle shape with a rolled crust along the wide end, yellow cheese, and red circles |
| Triangle budget | **200**. About 144 by count: 8 for the wedge, 28 for the crust, 36 for each pepperoni. That leaves room if the crust needs more sides to look round. |

#### The cooler

| | |
|---|---|
| Size (W × D × H) | **0.58 × 0.36 × 0.36 m**, handle included |
| Why that size | Life size: a medium cooler for a weekend camp. It's just over half the raccoon's height (0.61 m), so he can climb on it or knock the lid open. On screen it's about 124 × 77 px. |
| Parts (5 shapes) | Body: a cube, 0.54 × 0.34 × 0.28. Lid: a cube, 0.58 × 0.36 × 0.05, slightly larger so it overhangs. Handle: an 8-sided cylinder bar, 0.30 long, on two small cube posts, lying across the top of the lid. The long side faces the front. |
| Colours | **Body: to be confirmed by me.** Claude's suggestion is blue `#3B7DBF`. Lid white `#F2F2EE`, handle grey `#8A8F94`. |
| What makes it recognisable | A box with a lighter, overhanging lid and a carry handle on top |
| Triangle budget | **150**. About 76 by count: 12 for each cube, and 28 for the 8-sided bar. It's the biggest of the three on screen, so it can afford a rounder handle. |

#### Predicted failures, and how I'll check each

1. **An asset arrives lying on its side or upside down.** This is the wrong up axis, or a rotation that wasn't applied. I nearly did this to my practice donut by looking at it from below the floor (BLENDER-NOTES.md, 14 Oct).
   - **Check:** the headless script prints each asset's bounding box size along Godot's X, Y and Z. They must match the brief's W, H and D in that order, so its height lies along Y.
   - It **must not** just test which side is longest. The pizza slice is flat, so its height is its *smallest* size, and a "tallest side is up" test would call a correctly placed slice wrong.
   - Then I look at each asset in the scene from the front and the side.
2. **An asset arrives the wrong size, say 10 times too big or too small.** This could be built in centimetres, or a scale that wasn't applied.
   - **Check:** Blender's sidebar Dimensions beside the brief before export. Then the headless script's bounding box size within 5% of the brief on every axis, with node scale 1, 1, 1.
3. **An asset floats above the floor or sinks into it.** This means the origin isn't at the base.
   - **Check:** the headless script places each asset at Y = 0, and the bottom of its bounding box must be within 1 mm of 0.
   - This uses the mesh's own box, not a physics collider. Module 3's floor check stopped on the object's own collider, which proved nothing about the floor.
   - Then I look along the floor from the side to see it sitting on it.

**Provenance (v1).**
- **My decisions:** life-size food, the medium cooler, where each asset goes, and the three failures, picked from Claude's options on 14 Oct at 00:15. I didn't ask for a different origin when Claude suggested the centre of the underside.
- **Claude's contributions:**
  - the options;
  - the part breakdowns and part sizes;
  - the colours;
  - the triangle counts and budgets;
  - the axis convention;
  - the wording of the checks, including the pizza-slice caveat in failure 1;
  - the on-screen pixel sizes, from the 214 px per metre measured above.
- **Generative models:** none.

### Revised in v2 (14 Oct 2026): the s'more, after my first look

The v1 s'more above was built exactly to plan (0.065 × 0.065 × 0.04 m, 80 triangles; see ASSET-PLAN.md). Its v1 text stays as it was.

**What I saw** (14:56): "the smores doesn't feel like more does it". Claude agreed and gave four reasons:
- the marshmallow was a neat white puck that didn't bulge;
- the chocolate was hidden under it;
- the two crackers lined up too perfectly;
- from above it was a plain tan square.

**What I decided** (14:59): "You do it for me along with smores u can have just marshmallows also but make them well designed and they should look the the real deal".

**The v2 s'more** (Claude's design, from that decision). Still basic shapes and flat colours, now 6 shapes, the course's limit:

| Part | Shape | Size (m) | What it's for |
|---|---|---|---|
| Bottom cracker | Cube | 0.065 × 0.065 × 0.006 | Thinner than v1's 0.008, closer to a real graham cracker |
| Chocolate | Cube, turned 8° | 0.055 × 0.05 × 0.005 | Bigger than v1, so its edge peeks out under the marshmallow |
| Toasted marshmallow | UV sphere, 12 segments × 6 rings, squashed | about 0.072 × 0.068 × 0.018 | **Bulges out past the crackers' edges**, the main cue that it's been squished in a s'more. Lightly toasted cream `#F3E6CC`. |
| Top cracker | Cube, twisted 12° and tilted about 2°, pressed slightly into the marshmallow | 0.065 × 0.065 × 0.006 | Looks made by hand. From above, the marshmallow and chocolate show at its edges. |
| Two plain marshmallows | Cylinders, 12 sides, one standing and one on its side | Ø 0.033 × 0.03 each (real size) | My "just marshmallows also", beside the s'more. White `#F7F3EA`. |

- **Size of the whole asset:** about **0.13 × 0.085 × 0.035 m**, the s'more plus its two marshmallows. It's measured after the build and centred on the origin, with its base on the floor.
- **Triangle budget:** revised from 100 to **250**. By count: 12 for each cube, 120 for the sphere and 44 for each cylinder, which is **244**. The puffy marshmallow is what makes it read as a s'more, and it needs the sphere's triangles.
- **Colours** otherwise as in v1: cracker tan `#C8955A`, chocolate `#4A2C1D`.
- **Origin, axes and the predicted failures** are unchanged from v1.
- **Before and after:** the v1 file is kept as `design/a3/build/smore/smore_v1.blend`.

**Provenance (v2):** my look, my words and my decision to have Claude make the change. The diagnosis, the design, the sizes and the new budget are Claude's.
ss
### Revised in v3 (14 Oct 2026): the crackers' groove and dots

**What I asked for** (15:49): "add some indentations and textures to the biscuits".

**What's possible under the course's rules.**
- **Textures aren't.** The assignment allows no painted textures and asks for flat-colour materials.
- **Indentations are,** as geometry. So the crackers get the shape of a real graham cracker instead.

Claude's design:

| Part | Change | Triangles |
|---|---|---|
| Top cracker | Its top face is cut into a 6 × 6 grid. The middle line is pressed 0.8 mm down into a V-groove, the snap line. Eight dots (2 columns × 4 rows) are inset 3.5 mm and pressed 0.7 mm in, in a second flat colour, darker tan `#9C6A36`. | 12 → about 166 |
| Bottom cracker | A groove pressed 0.8 mm up into its underside, so it shows when it's seen from below | 12 → about 16 |

- **Triangle budget:** revised from 250 to **420**, under the course's limit of 500. The predicted total is about **402**.
- **Still unchanged:** 6 shapes, the sizes, the origin, and every other part. The dots are a flat colour, not a texture.
- **What it can't do:** at the game camera the s'more is about 14 px across, so the groove and dots won't show in play. They're for close-ups, my look in Blender, and the film.

**Provenance (v3):** my request. The rules check, the design and the numbers are Claude's.

### Revised in v4 (14 Oct 2026): the cooler's body colour

v1 left the cooler's body colour for me to confirm, with Claude's suggestion of blue `#3B7DBF`. On 14 Oct (about 17:25), picking from Claude's four options (blue, red, green, orange), **I chose blue `#3B7DBF`**. Claude's reason for it: it stands out best against the green forest ground. Everything else about the cooler is as in v1.

---

## Assignment 5: shaders and materials

Written 25 Oct 2026, before either shader. Revisions go below, dated 25th Oct 2026.

### The NPC's vision cones 
- what the effect tells the player:
It tells the player what the NPC can see or observe while the player is trying to sneek around the game or avoid being seen by the NPCs.
The game in its mechanics has multiple sneek requirements, to avoid detections from the NPCs. 


- Why the player needs to see it:
The vision cone is indicator as well it serves as the perception of what the NPC is able to detect the presence of the raccoon in his surrounding. The game has a lots of tasks that are expected to be done while sneaking around and avoid detection, so it's important that the players understand what the spotting vision is limited to or the detection feedback is working to play the game.

- What the cone does:
  - The state: The detection system will follows the color pattern of being tinge of yellow for indicating the general sight of vision, which will also increase and reduce depending upon the raccoon's/player's movements, and when detected we go a alerted state for the NPC and the raccoon.
  - The two colours: The pale yellow and red are the two main vision colors.
  - The change: When spotted the color should snap to red for a 2 seconds indicating the actions to the player along with state of alerted. If the player wants to fade the status away he needs to run away from the vicinity of the alerted NPC or hide away to become undetected again.

  (My answers to Claude Code's questions, 26 Oct 2026, in my own words. Claude Code fixed the spelling and typos and added full stops and commas. This "why" replaces my first answer, which was about the moods in general.)

- What the cone does, round 2 (26 Oct 2026):
  - How long it stays red: 2 seconds. (I first wrote "Vanishing after 3 frames so the player understands he has been spotted"; Claude Code pointed out that 3 frames is 0.1 s at 30 fps and 0.02 s at 144 fps, and I picked 2 seconds from its options.)
  - What starts the red: the moment he's spotted. (Picked from Claude Code's options.)
  - Back to yellow: There should be no fade to yellow.
  - After the red: Completely fade all the vision cones, make the NPC confused with the "??" around his head looking around and then walk back, and after like 5 seconds bring the vision cone back.
  - When the confused part happens: This confused action happens after he has shooed him away and after the raccoon has evaded the sight.
  - When the cones start: no cones until he reaches the camp. Yes, let's show him the tasks as some sort of tutorial workflow prompting him to open Tab. Before this there should be no tasks other than "identify the music", and then the "rock the party" main task should have sub tasks like steal marshmallows and all others which we have. It's a interactive tutorial style.

  (My answers, in my own words, with spelling fixed by Claude Code.)

- The gaps, filled by Claude Code because I asked it to ("take liberties with the gaps that feel approriate", 26 Oct 2026). These are Claude Code's choices, not mine:
  - The fade-out: when the 2 s of red are up, all the cones fade out together over 0.5 s. During the 2 s only the cone of the camper who spotted him is red; the others stay yellow until they fade with it.
  - Coming back: 5 s after a camper starts walking back from the confused looking-around, that camper's cone fades back in, yellow, over 0.5 s.
  - The length: while the cones show after a spotting, each stays as long as it was while its camper watched (7 m standing, shorter while he sneaks), not the 14 m an alarmed camper sees.
  - The names: "identify the music" is the task already in the game, "Investigate the music". The main task is "Rock the party", with the camp's tasks as its sub-tasks.
  - The tutorial: he reaches the camp and "Investigate the music" is ticked off. The game pauses and a note says to press Tab. THE PLAN opens, showing "Rock the party" and its sub-tasks, and the note tells him to sneak so they don't see him. He closes it with Tab, the game carries on, and the cones fade in.
  - The split: when the cones show, the campers' "??" search and the timers are the game's behaviour, written by Claude Code in GDScript. The yellow, the 2 s of red and the fades are my shader's job, driven from that behaviour.

- The script and variable that hold it:

- The other moods in the game, and why I picked this one:


### The effect
- Shader file: `shaders/vision_cone.gdshader` (picked from Claude Code's options, 27 Oct 2026)
- shader_type and render_mode (my words, 28 Oct 2026):
  - `shader_type spatial;`: In Godot, 3D materials require the spatial shader type to interact with the 3D rendering pipeline.
  - `render_mode blend_mix, unshaded, depth_draw_opaque;`: `blend_mix` enables standard alpha transparency, `unshaded` prevents the environment's lights and shadows from altering the cone's flat colors, and `depth_draw_opaque` ensures the transparent cone correctly depth-sorts against other transparent elements.
- The object it colours, and how that object is drawn: each camper's vision cone, a fan of 24 triangles on the ground under their eyes, built in code (`scripts/vision_cone.gd`, `_build_cone`). Its corners carry vertex colours, white, with alpha 0.55 at the camper fading to 0.12 at the far edge. Until my shader is in, it's drawn with a StandardMaterial3D made in code: unshaded, see-through, vertex colours as its colour, both sides drawn, no fog. (These facts are from the code, written in by Claude Code.)

| Uniform | Type | Hint | Default | Set by |
|---|---|---|---|---|
| `alarm` | float | `hint_range(0.0, 1.0)` | 0.0 | The game, every frame: 0 = the yellow, 1 = the red |
| `shown` | float | `hint_range(0.0, 1.0)` | 1.0 | The game, every frame: 0 = gone, 1 = fully shown (the fades) |
| `watch_color` | vec4: a colour and its see-through amount | `source_color` | the game's yellow, `WATCHING`: (1.0, 0.93, 0.62, 0.5) | Its default, which a material can change in the Inspector |
| `alarm_color` | vec4: a colour and its see-through amount | `source_color` | the game's red, `SEEING`: (1.0, 0.33, 0.27, 0.65) | Its default, which a material can change in the Inspector |

(Picked from Claude Code's options on 26 and 27 Oct 2026: the names, what 0 and 1 mean for `alarm` and `shown`, their defaults, the hints, and the two colours as knobs keeping the game's colours and see-through amounts.)

### The colour line
(the one line inside fragment() that changes the colour)

My choices for it (picked from Claude Code's options, 27 Oct 2026):
- As `alarm` goes from 0 to 1, the colour blends smoothly from `watch_color` to `alarm_color`, halfway at 0.5.
- How see-through the cone is at a pixel: its tip-to-edge fade × the colour's own amount × `shown`.

### Rules
- The uniform's value when the mood starts, and when it ends:
  `alarm` jumps from 0 to 1 the moment he's spotted, and stays at 1 through the 2 s of red and the fade-out after it. It's back at 0 when the cone comes back. `shown` is 1 while the cone shows; it goes to 0 after the red, and back to 1 when the cone comes back.
- How long the change takes (seconds, give or take one frame), the same at 30, 60 and 144 fps:
  `alarm` takes no time: it snaps. `shown` goes from 1 to 0 over 0.5 s, starting 2 s after the spotting, and from 0 to 1 over 0.5 s when the cone comes back, 5 s after its camper starts walking back. Each takes the same time at 30, 60 and 144 fps, give or take one frame.

  (These two are from my design above, as Claude Code put it together; I confirmed it on 27 Oct 2026.)
- If the mood starts again mid-change: restart, extend or ignore?
  Restart: the red lasts 2 s from the latest spotting, whether another camper spots him or the same one sees him again.
- Scaled or unscaled time under Engine.time_scale, and what it does while paused:
  Unscaled: always 2 real seconds, whatever speed the game runs at. While the game is paused, the red and the fades freeze where they are and carry on afterwards.
- The value if the mood ends before the change finishes:
  The red still runs its full 2 s and then fades, even if he's already hidden.

  (The three answers above are mine, picked from Claude Code's options on 26 Oct 2026.)
- With several copies of the object, how each gets its own value:
  One material per cone: each cone makes its own ShaderMaterial from my one shader, and the game sets each one's values. (Picked from Claude Code's options on 27 Oct 2026.)

### Boundaries
(what this change must not touch)

When my shader and its driver go in, these stay exactly as they are (ticked by me from Claude Code's list, 27 Oct 2026):
- how he moves and collides, and which keys do what;
- the campers' behaviour (when they see him, guard, chase, shoo and search) and all its timings, as built on 26 Oct;
- everything else's look: only the cones change, and the trees, the fire, the icons and the other shaders stay the same;
- no earlier test's expectations change (added at my request on 27 Oct 2026, after Claude Code pointed out that the assignment lists it).

### Evidence split
| Rule | Checked by (test or my eyes) | How |
|---|---|---|
| Spotted: `alarm` snaps to 1 and the red lasts 2 s; it starts over when he's re-spotted, and still runs its 2 s if he's lost early | A headless test | Claude's driver test reads `alarm` every frame at 30, 60 and 144 fps while he's spotted in play at the camp, and measures the times |
| The fades: `shown` 1 to 0 over 0.5 s after the red, 0 to 1 over 0.5 s when the cone comes back | A headless test | The same test measures them on the game's clock |
| Paused: the red and the fades freeze. Slowed down: always 2 real seconds | A headless test | The test pauses the game and sets `Engine.time_scale`, then checks `alarm` and `shown` |
| Each cone has its own value: only the spotter's goes red | Both | The test checks each cone's `alarm` and `shown`; I check in play that only one cone turns red |

(Picked by me from Claude Code's options, 27 Oct 2026. "Lost early" is in the first row because I chose a test for every timing rule.)

### Predicted pixels
| Pixel | Its colour now | At 0.0 (Yellow: 255, 237, 158) | At 0.5 (Blend: 255, 160, 113) | At 1.0 (Red: 255, 84, 69) |
|---|---|---|---|---|
| **Base at Camper** (Vertex Alpha 0.55 over Grass 80, 120, 80) | 80, 120, 80 | 176, 184, 123 | 176, 142, 98 | 176, 100, 74 |
| **Far Edge** (Vertex Alpha 0.12 over Grass 80, 120, 80) | 80, 120, 80 | 100, 133, 89 | 100, 124, 83 | 100, 115, 78 |

### Hint experiment predictions
| Grey in the file | Quad with source_color | Quad without |
|---|---|---|
| 64 (0.25) | ~0.05 (Darkened via sRGB curve) | 0.25 |
| 128 (0.50) | ~0.21 (Darkened via sRGB curve) | 0.50 |
| 192 (0.75) | ~0.53 (Darkened via sRGB curve) | 0.75 |

**Which quad shows the file's values unchanged, and why:**
The quad **without** `source_color`. Godot’s 3D rendering pipeline operates in Linear color space. When a texture is imported or sampled with `source_color`, Godot assumes it was authored in sRGB (how monitors display color) and automatically applies an inverse gamma correction curve (~power of 2.2) to convert it to Linear space, mathematically altering the raw pixel values. Sampling without `source_color` reads the exact raw data bytes from the file.

### Material plan (the textured shader)
**The object, and the lighting I'll judge it under:** The 24-triangle vision cone fan on the ground, viewed under the game's flat-shaded, unlit night environment where only ALBEDO and ALPHA determine the final pixel output.

| Texture | Role | Source | What its numbers mean | Colour or data | compress/mode | compress/normal_map | mipmaps/generate |
|---|---|---|---|---|---|---|---|
| `cone_edge_mask.png` | Softens the harsh side edges of the geometric triangles to look more like a projected light | 2D image | 1.0 (white) in the center fading to 0.0 (black) at the left and right borders | Data | Lossless / VRAM uncompressed | False | False (prevents edge bleeding at distances) |

| Uniform | Type | Hint | Range | Default | Group | What changes on screen |
|---|---|---|---|---|---|---|
| `edge_softness` | float | `hint_range` | 0.0 to 1.0 | 0.1 | Edge Mask | How wide the blurred transition is at the side borders of the cone |
| `mask_texture` | sampler2D | `filter_linear` | N/A | empty | Edge Mask | Applies the horizontal gradient falloff to the cone |

**How the two materials differ, and why:**
The untextured version relies solely on the CPU-generated vertex colors (alpha 0.55 to 0.12) to fade the cone outward, leaving sharp geometric edges on the sides. The textured material multiplies this vertex alpha by the `mask_texture`, resulting in a cone that smoothly fades out both over distance (via vertices) and at its peripheral vision edges (via the texture).

### Predicted failures
| What could go wrong | The check that would catch it |
|---|---|
| The 0.5s fade-out continues to animate while the game is paused because the `Tween` driving the `shown` uniform is not set to `TWEEN_PROCESS_PHYSICS` or is ignoring the node's pause mode. | A headless test or manual playtest that pauses the game the exact frame the cone starts fading after an alert; the alpha should freeze immediately. |
| The cone flashes solid white or black when first spawned because the material's `watch_color` and `alarm_color` uniforms weren't properly initialized in the exported Godot resource. | A headless test verifying the ShaderMaterial's parameters immediately after instantiation before the first `_process` frame executes. |
| Depth-sorting issues cause the transparent raccoon to render *in front* of the vision cone instead of inside it when the camera angle lowers. | Visual check in playtest ensuring `depth_draw_opaque` and the Render Priority settings on the cone material sort correctly behind the raccoon's material. |

### Short answers
1. The renderer project.godot names, and what it rules out:
2. The colour that arrives in fragment() before I change it, and what the tempting alternative would give:
3. canvas_item: what texture(TEXTURE, UV) would give instead of COLOR. Or spatial: what ALBEDO holds if I never write it, and what COLOR holds:
4. How long a frame-counting version would last at 30, 60 and 144 fps:
5. Which resource holds the uniform's default, which holds its current value, and what happens if two objects share the material:
6. Does hint_range clamp a value set from code? My prediction:

### Revised 28 Oct 2026: the timings, the tolerance and the restarts, made exact

Written after a grading review with Claude Code on 28 Oct 2026. The rules above stay as they were. Where this section differs from them, it replaces them.

**What "spotted" means** (facts from the code, written in by Claude Code). My boundaries keep the campers' behaviour as it is, so the rules below fit it.
- He's spotted the moment `spot()` in `scripts/campsite.gd` runs. It sets the camp's `spotted_at` to the camp's `clock`, and the game then shows every cone until 2.5 s after it (`cones_shown_until()`).
- `spot()` runs when a camper who isn't alarmed sees him: at work, wondering about a noise, fixing the plug, confused, or walking back (`scripts/camp_person.gd`: `_work`, `_investigate` and `_fix` through `_startle`, line 385; `_search`, line 527; `_return`, line 542).
- A camper who's already alarmed (startled, guarding, chasing, shooing, fleeing, cowering, or taking something back) can see him without it counting. So "the same one sees him again", in my restart rule above, can only restart the red once that camper is calm again.

**How long each change takes, and the tolerance** (replaces "give or take one frame"):
- `alarm` goes from 0 to 1 within one frame of the spotting, with nothing in between.
- `shown` goes from 1 to 0 over 0.5 s, starting 2.0 s after the latest spotting, so it's 0 at 2.5 s. It goes from 0 to 1 over 0.5 s from the moment the game shows a cone again after its 5 s.
- The tolerance is one frame period at the rate it runs at: 33.3 ms at 30 fps, 16.7 ms at 60 fps and 6.9 ms at 144 fps.
- Every time is measured in game time, by a node that reads the uniforms once a frame after every other `_process()` (a high `process_priority`). Each must come out the same at all three rates, within that tolerance.

**Time scale and pause** (replaces "Unscaled: always 2 real seconds"; picked by me from Claude Code's options, 28 Oct 2026):
- Game time, which `Engine.time_scale` scales: the clock the campers run on (`clock += delta` in `scripts/vision_cone.gd` and `scripts/campsite.gd`).
  - At `time_scale` 0.5, the red lasts 4 real seconds and its fade 1 s. At 2.0, they last 1 s and 0.25 s.
  - Why I changed it: the game hides the cones on that scaled clock, and my boundaries keep it. A real-time clock of the shader's own would drift out of step: at `time_scale` 2 the game hides the cones after 1.25 real seconds, before the fade has started.
  - No script in the game changes `time_scale`; only the test does.
- Paused: the red and the fades freeze where they are and carry on afterwards, as before.

**When he's spotted again** (replaces my restart rule above; picked by me from Claude Code's options, 28 Oct 2026):

| When the new spotting comes | What the game does (unchanged) | `alarm` | `shown` |
|---|---|---|---|
| During the 2 s of red | Shows every cone until 2.5 s after the new spotting | The new spotter's cone snaps to 1. A cone that's red already stays at 1. | Stays at 1. The fade starts 2 s after the new spotting. |
| During the 0.5 s fade | The same | As above | Snaps back to 1. The fade starts again 2 s after the new spotting. |
| While the cones are hidden, by a camper who isn't alarmed (confused, walking back, or back at work before their cone's come back) | Shows every cone again, until 2.5 s after the spotting | The spotter's cone snaps to 1. Every other cone is at 0. | Snaps from 0 to 1 at once. Then the usual 2 s of red and the 0.5 s fade. |
| Seen by a camper who's alarmed, at any time | Nothing: it doesn't count as a spotting | No change | No change: hidden cones stay hidden |

- **Which cones are red:** every camper whose spotting starts or restarts the red has a red cone, until the cones fade. The rest stay yellow. So if a second camper spots him while the first one's cone is red, both cones are red.
- **Back to yellow:** a cone that shows again, after its 5 s or because someone has spotted him, starts at `alarm` 0, unless its own camper has just spotted him. This is Claude Code's reading of my rule "It's back at 0 when the cone comes back", as it put it in the question I answered.

**The tests for these** (added to the evidence split). Each is a headless assertion at 30, 60 and 144 fps, on the uniforms read once a frame:
- the snap: `alarm` goes from 0 to 1 within one frame of the spotting, on the spotter's cone only;
- the fade: `shown` starts falling 2.0 s after the latest spotting and is 0 at 2.5 s. When the cone comes back, it goes from 0 to 1 over 0.5 s;
- spotted again during the red, and again during the fade: the fade starts over from the new spotting, and both spotters' cones are red;
- spotted while the cones are hidden: `shown` goes from 0 to 1 in one frame, with the spotter's cone red and the others yellow;
- seen by a camper who's alarmed: no change;
- time scale: the red lasts 2 s of game time at any `time_scale`. At 60 fps that's 120 frames at 1.0, 240 at 0.5 and 60 at 2.0;
- paused mid-fade: `shown` keeps its value through the pause, and the fade finishes after it.

(Picked by me from Claude Code's options on 28 Oct 2026: game time, snapping back during the fade, snapping in while hidden, and both spotters' cones red. All four were its recommendations. The facts from the code, the table, the tests and the wording are Claude Code's. The tolerance is one frame at each rate.)

### Revised 28 Oct 2026: the evidence split, made complete

Written after the same grading review. This table replaces the evidence split above, which covered only the timing rules. The assertions under "The tests for these", in the revision before this one, still apply. Every rule in my brief now has a check.

| Rule | Checked by | How |
|---|---|---|
| The uniforms: `alarm`, `shown`, `watch_color` and `alarm_color`, with the types in my table | A headless test | `get_shader_uniform_list()` gives each uniform's name and type. Their hints and defaults are read from the shader's source text, because a headless run doesn't report them. |
| The shader parses | A headless test | A shader that fails to parse has an empty uniform list, so the check above fails, and `scripts/run-test.sh` fails on any `SHADER ERROR` line too. Proved by deleting one semicolon from the shader: the run must exit 1. |
| The driver sets the names the shader declares | A headless test | Proved by renaming `alarm` in the shader only: the uniform-list check must fail, and the run exit 1. Setting a name the shader doesn't declare raises no error, so nothing else would catch it. |
| Spotted: `alarm` snaps to 1 and the red lasts 2 s, even if he's lost early; and each restart in the revision before this one | A headless test | Through the real game at the camp, reading the uniforms once a frame at 30, 60 and 144 fps |
| The fades: `shown` 1 to 0 over 0.5 s after the red, and 0 to 1 over 0.5 s when a cone comes back | A headless test | The same test, in game time |
| Paused: the red and the fades freeze. Slowed down or sped up: 2 s of game time | A headless test | The test pauses the game and sets `Engine.time_scale`. It counts frames, not real seconds: a run with `--fixed-fps` doesn't keep to the wall clock. At N fps and `time_scale` s, 2 s of game time is 2N ÷ s frames: 120 at 60 fps and 1.0, 240 at 0.5, 60 at 2.0. |
| Each cone has its own value: only the spotters' cones go red | Both | The test checks each cone's `alarm` and `shown`. In play, I check that only the spotters' cones turn red. |
| The colour at `alarm` 0, 0.5 and 1, with `shown` at 1 | My eyes | A capture at each value, read from the game's own frame, not an OS screenshot, against my predicted pixels. How, below. |
| Whether `hint_range` clamps a value set from code | My eyes | A capture with `alarm` set to 2.0 from code, compared with the capture at 1.0. How, below. |
| In play | My eyes | At least five spottings in normal play. How, below. |
| The boundaries hold | Both | The earlier checks keep their baseline counts at 60 fps, and the cones check its 43 at 30, 60 and 144. In play, I check that he moves and the campers behave as before, and that nothing but the cones looks different. |

**How I take the captures:**
- In a windowed run, with a debug key, from the game's rendered frame. The game is paused and the driver held off, so nothing overwrites the value I set.
- The same framing and the same two pixels as my grass captures: Base at Camper (974, 258) and Far Edge (249, 480).
- The pause also stops the fire's flicker (`scripts/campsite.gd:425`), which lights Far Edge. With each capture goes one of the same paused frame with the cones hidden, so the grass under both pixels is measured every time, not assumed.
- A match is within 2 of my prediction on each of R, G and B. A bigger difference is a finding: I record it with the capture, then find out why.
- Once, I compare a capture with an OS screenshot of the same frame, and record which I trust and why.

**The `hint_range` check:** with the driver held off, I set `alarm` to 2.0 and take a capture as above. If both pixels match the capture at 1.0 within 2 steps, `hint_range` clamped the value. If not, it didn't. My prediction is in the short answers.

**In play:** at least five spottings at the camp from a normal start, with nothing scripted. For each, I write down which cones turned red, how the fade looked and when the cones came back, and any re-spotting along the way. The rarer restarts are the headless test's to check.

(Picked by me from Claude Code's options on 28 Oct 2026: a match within 2 steps, each capture paused with a bare frame beside it, and five spottings in normal play. All three were its recommendations. The table, the frame counts and the wording are Claude Code's, and so is using `alarm` for the 2.0 capture, since it's the uniform that moves the colour from yellow to red. The checks in the table follow the assignment.)

### Revised 28 Oct 2026: the material plan, for the cooler

Written after the same grading review. It replaces the material plan above, which put one texture on the vision cone. The cone has no UVs, and my shader from code may have no samplers of its own, so the textured shader goes on another object.

**The object and the light:**
- **The object:** the cooler, my Assignment 3 asset (`assets/props/cooler.glb`). It's at the camp by the fire, and in the asset room under key 2. It has UVs, and Godot builds its tangents on import (`meshes/ensure_tangents=true`), which the normal map needs. No game code recolours it.
- **Where the materials go:** behind the importer's per-material Use External setting in `cooler.glb`'s import, so a reimport keeps them and every copy of the cooler gets them, at the camp and in the asset room. The body (`Cooler_Blue`) gets one material and the lid (`Cooler_White`) the other. The handle and its posts (`Cooler_Grey`) stay as they are.
- **The light I judge under:** the asset room's sun (energy 0.8) and ambient light (energy 0.8). Its SSAO (`asset_room/asset_room.tscn`, line 26) is switched off while I judge, so SSAO's shading isn't mistaken for the roughness or normal map. Then one look at the camp at night, in play.

**The textures:** Blue Metal Plate, by Rob Tuytel (all roles), from Poly Haven (https://polyhaven.com/a/blue_metal_plate), published 26 Sep 2024. Poly Haven's textures are CC0; I check its licence on the day I download them, and the source, authors, licence and that date go in an `ATTRIBUTION.md` beside the files. All three at 1k, since the cooler is only about 124 × 77 px on screen, and as PNG, so nothing lossy sits under the import.

| Texture | Role | What its numbers mean | Sampled as | compress/mode | compress/normal_map | mipmaps/generate |
|---|---|---|---|---|---|---|
| `blue_metal_plate_diff_1k.png` | The colour: the plate's paint, its scratches and scuffs | Colour, stored in sRGB as a photo is | Colour, with `source_color`, so it's decoded to linear before any arithmetic | VRAM Compressed | Disabled | On |
| `blue_metal_plate_rough_1k.png` | How rough each point of the surface is | 0 (black) is smooth and shiny, 1 (white) rough and matte. Data, not a colour | Data, without `source_color` | VRAM Compressed | Disabled | On |
| `blue_metal_plate_nor_gl_1k.png` | Which way each point of the surface faces: the slopes of the scratches | Each texel is a direction. R and G are its X and Y, stored as 0 to 1 for −1 to 1, with green pointing up (OpenGL), as Godot expects. Godot works out Z from them | Data, with `hint_normal` | VRAM Compressed | Enable | On |

- All three also get `roughness/mode` Disabled, so the editor's detection has nothing left to change. The audit looks up each setting's integer in the `.import` files.
- It's the OpenGL normal map, `_nor_gl`, not `_nor_dx`. Because it's a normal map, `tests/normal_map_check.gd` is committed before the audit. It's calibrated on this set's own `_nor_gl` and `_nor_dx` pair: the GL file should come out low, and near 2 under the other convention. A scratched plate is nearly flat, so if the pair doesn't separate (both drift toward 1), a bumpier Poly Haven pair calibrates the check instead, and TEST-REPORT.md says so.

**The uniforms:**

| Uniform | Type | Hint | Range | Default | Group | What I expect across its range |
|---|---|---|---|---|---|---|
| `tint` | vec4 | `source_color` | a colour | white | colour | The part's colour, with the texture's scratches showing in it |
| `detail` | float | `hint_range(0.0, 1.0)` | 0 to 1 | 0.5 | colour | 0: the flat colour the cooler has today. 1: the plate's full scratches and scuffs. Near 1 the photo's detail may clash with the game's flat low-poly look. |
| `uv_scale` | float | `hint_range(0.25, 4.0)` | 0.25 to 4 | 1.0 | colour | How many times the texture repeats on each face. At 0.25 the scratches are 4 times bigger; at 4 they're 4 times smaller, and may turn into a fine pattern. |
| `roughness_scale` | float | `hint_range(0.0, 1.0)` | 0 to 1 | 1.0 | surface | 0: shiny as a mirror everywhere, catching the sun. 1: the map's own roughness, shiny paint with matte scratches. |
| `normal_strength` | float | `hint_range(0.0, 2.0)` | 0 to 2 | 1.0 | surface | 0: flat, lit as it is today. 1: the scratches catch the light as the map says. 2: twice as deep, which may look wrong on a cooler. |

| Sampler | Hints | Group | Bound to |
|---|---|---|---|
| `albedo_texture` | `source_color, filter_linear_mipmap, repeat_enable` | colour | the diffuse |
| `roughness_texture` | `hint_default_white, filter_linear_mipmap, repeat_enable` | surface | the roughness map |
| `normal_texture` | `hint_normal, filter_linear_mipmap, repeat_enable` | surface | the `_nor_gl` normal map |

**How the colour texture meets the tint:** the diffuse, decoded with `source_color`, darkens and lightens the tint by its brightness around its own average, as far as `detail` says. So one blue texture gives a scuffed blue body and a scuffed white lid: a tint multiplying a blue texture could only make it darker. The line that does it is mine to write in the shader.

**The two materials:**

| Material | `tint` | `detail` | `roughness_scale` | `normal_strength` | `uv_scale` |
|---|---|---|---|---|---|
| The body (`Cooler_Blue`) | `#3B7DBF` | 0.6 | 1.0 | 1.0 | 1.0 |
| The lid (`Cooler_White`) | `#F2F2EE` | 0.25 | 0.6 | 0.5 | 1.0 |

- **Why:** the lid should read as smoother, shinier white plastic, and the body as scuffed painted metal.
- Both bind the same three textures, so they differ in four values, not in a texture.

**Suggested paths** (Claude Code's, mine to change): the shader `shaders/cooler_paint.gdshader`; the materials `materials/cooler_body.tres` and `materials/cooler_lid.tres`; the textures in `assets/textures/blue_metal_plate/`, with its `ATTRIBUTION.md`.

**A change to my boundaries:** "only the cones change" now has a second exception: the cooler's body and lid, which this shader is for. Everything else stays as in my boundaries above.

(Picked by me from Claude Code's options on 28 Oct 2026: the cooler; the diffuse, roughness and normal maps; the body and the lid; the asset room with SSAO off; the texture shading the tint; the five uniforms; VRAM compression with mipmaps; and the two materials' values. All eight were its recommendations. The facts from the code and from Poly Haven, the tables, the paths and the wording are Claude Code's.)

### Revised 28 Oct 2026: the predicted failures, tied to my rules

Written after the same grading review. It replaces my predicted failures above: two are corrected here, and one is dropped. Each failure has the check that would catch it.

| # | What could go wrong | Why it would happen | The check that would catch it |
|---|---|---|---|
| 1 | Every cone turns red at once | The cones share one ShaderMaterial, so setting `alarm` on the spotter's cone sets it on every cone | The headless test reads each cone's `alarm`, and checks that each cone has a material of its own. In play, only the spotters' cones turn red. |
| 2 | The red doesn't restart | A second spotting during the red or the fade leaves the fade on the first spotting's clock, so the cones go too early | The test's re-spottings during the red and during the fade: the fade must start 2 s after the latest spotting |
| 3 | The red lasts the wrong time under time scale | The driver times the red on the wall clock, or with a Tween that ignores time scale. At `time_scale` 2 the game hides the cones before the fade starts. | The test's frame counts at `time_scale` 0.5 and 2.0: 240 and 60 frames at 60 fps |
| 4 | The fade carries on through a pause (my first prediction, corrected) | The driver runs while the game is paused, through its `process_mode`, or through a Tween's pause mode, which is set with `set_pause_mode`, not a process mode | The test pauses the game mid-fade: `shown` must hold its value |
| 5 | Fog on the cone | My render_mode has no `fog_disabled`. The level's depth fog starts at 18 m (`scripts/main.gd:894`) and the camera is 19.2 m away (`scripts/main.gd:116`), so the cone's colour drifts toward the haze. | The controlled captures: off by more than 2 steps, toward the haze. One capture with the fog off confirms it. |
| 6 | The tip-to-edge fade is lost | The shader ignores the cone's vertex alpha (0.55 at the camper, 0.12 at the edge), so the whole cone is equally see-through | The controlled captures: Base at Camper and Far Edge must differ as my predictions say |
| 7 | Overlapping cones flicker (my third prediction, corrected) | Where two cones overlap, which is drawn on top depends on their order, sorted by distance, and with `depth_draw_opaque` neither hides the other. As the campers move the order flips, so a red cone over a yellow one flickers. | My eyes in play, watching an overlap during a red. The raccoon is opaque, so the depth buffer, not sorting, already puts him in front or behind. |
| 8 | A data texture read as colour | The roughness or normal map sampled with `source_color`, so its numbers are decoded as if they were sRGB: the plate shines in the wrong places, and the scratches light wrongly | The material test reads each sampler's hints from the shader's source |
| 9 | The editor rewrites an import setting | A setting left on Detect, so the editor rewrites the `.import` file the first time it draws the texture | `git status` after my first editor session, and the material test's import checks |

**Dropped:** my second prediction, the cone flashing white or black when it first appears because its colours weren't set. A uniform that no material sets takes the shader's default, so the cone starts in my default yellow and can't flash.

(Picked by me from Claude Code's options on 28 Oct 2026: three failures in the cone's timing, two in its look and two in the cooler, and correcting my first and third predictions. Seven of the nine came from its recommendations. The lost tip-to-edge fade and the rewritten import were my own picks, and I left out its recommended DirectX normal map. The causes, the checks and the wording are Claude Code's.)

### Revised 28 Oct 2026: the script and variables that hold the state

This fills in "The script and variable that hold it", which the 25 Oct text left empty. The facts are from Claude Code's code of 26 Oct, written in by Claude Code. The choice of how to record the spotter is mine.

- **When he was spotted:** `spotted_at` in `scripts/campsite.gd` (line 212). It's the camp's `clock` (line 200) at the latest spotting, set by `spot()` (line 371), and `cones_shown_until()` (line 378) is 2.5 s after it. The red and the fade are timed from it.
- **Who spotted him:** nothing records this yet.
  - `spot()` stores only when.
  - Each cone's own `spotted_at` (`scripts/vision_cone.gd`, line 41) changes whenever its camper starts seeing him, even a camper who's already guarding. So today a guard who turns to face him goes red as well (`red()`, line 83), against my rule that the other cones stay yellow.
  - The cones check passes only because, in its setup, the other campers don't see him (`scripts/cones_test.gd`, line 176).
  - Claude Code found this in its own code on 28 Oct 2026, when I asked why the state wasn't named.
- **The fix** (picked by me from Claude Code's options, 28 Oct 2026; its recommendation): when the driver is built, `spot()` also records which camper spotted him. Nothing anyone does, or when, changes.
- **So the state is** `spotted_at` for when, and that record for who.

**Two additions to my boundaries:**
- The campers' behaviour and its timings still stay exactly as they are. The one addition to the game's code is that record of who spotted him.
- Presentation code may read game state, but it never writes it: the driver reads `spotted_at` and the record, and writes only the cones' uniforms. (This is the assignment's rule, added at Claude Code's suggestion.)

### Revised 28 Oct 2026: my colour line and see-through line

Written by me on 28 Oct 2026, and put in word for word by Claude Code. My shader uses these two lines exactly, inside `fragment()`. If either has to change, this brief changes first, with a date.

```glsl
ALBEDO = mix(watch_color.rgb, alarm_color.rgb, alarm);
ALPHA = COLOR.a * mix(watch_color.a, alarm_color.a, alarm) * shown;
```

- **The colour line** is the first. As `alarm` goes from 0 to 1, the colour blends from `watch_color` to `alarm_color`, halfway at 0.5.
- **The see-through line** is the second: the cone's tip-to-edge fade (`COLOR.a`) × the colour's own amount × `shown`. The colour's own amount blends with `alarm` too, from 0.5 to 0.65.
- **Checked by Claude Code against my rules** (28 Oct 2026): the names match my uniform table, the types fit, and both lines do what my rules say. It suggested no change.

### Revised 28 Oct 2026: my predicted pixels and contrast ratios

These replace the predicted pixels above. The table and the working are mine, worked out with the help of Gemini and ChatGPT and cross-checked by me by hand. In my words: "Cross checked and validated the calculation along with the AI tools like gemeni and chatgpt for calculations but eventually i cross validated the calculations on my end as well manually". Claude Code put them in, with the layout tidied; the numbers are as I sent them in my third table of 28 Oct (FRICTIONAL.md has all three).

**What they assume:**
- my two lines, from the revision above, with `shown` at 1;
- the colours decoded from sRGB (`source_color`), with their `.a` used as written: 0.5 and 0.65;
- the cone's vertex alpha as measured at each pixel, and my measured grass;
- a Linear tonemap at exposure 1, and no fog on the cone.

| Pixel | `alarm` 0.0 | `alarm` 0.5 | `alarm` 1.0 |
|---|---|---|---|
| Base at Camper, (974, 258): vertex alpha 0.519, grass (34, 45, 49) | (139, 132, 93) | (148, 109, 79) | (156, 61, 56) |
| Far Edge, (249, 480): vertex alpha 0.151, grass (58, 76, 82) | (94, 100, 89) | (98, 91, 85) | (102, 76, 80) |

**Contrast, Base at Camper against its grass:**
- the grass's luminance: 0.0242;
- at `alarm` 0: luminance 0.2366, a contrast ratio of 3.86:1;
- at `alarm` 1: luminance 0.1105, a contrast ratio of 2.16:1.

**My working for Far Edge at `alarm` 0:**
1. **Decode to linear.**
   - `watch_color` (255, 237, 158): R 1.0. G 237 ÷ 255 = 0.92941, and ((0.92941 + 0.055) ÷ 1.055)^2.4 = 0.84687. B 158 ÷ 255 = 0.61961, and ((0.61961 + 0.055) ÷ 1.055)^2.4 = 0.34047.
   - Far Edge grass (58, 76, 82): R 58 ÷ 255 = 0.22745 → 0.04192. G 76 ÷ 255 = 0.29804 → 0.07324. B 82 ÷ 255 = 0.32157 → 0.08438.
2. **The colour line:** at `alarm` 0 the mix is just `watch_color`.
3. **The see-through line:** 0.151 × 0.5 × 1.0 = 0.0755.
4. **Blend over the grass,** whose weight is 1 − 0.0755 = 0.9245: R 0.0755 + 0.03876 = 0.11426. G 0.06394 + 0.06771 = 0.13165. B 0.02571 + 0.07801 = 0.10372.
5. **Encode,** 1.055 × linear^(1/2.4) − 0.055, then × 255: R 0.3674 × 255 = 93.69 → 94. G 0.3926 × 255 = 100.11 → 100. B 0.3509 × 255 = 89.48 → 89.

**My working for Base at Camper at `alarm` 1:**
1. **Decode to linear.**
   - `alarm_color` (255, 84, 69): R 1.0. G 84 ÷ 255 = 0.32941, and ((0.32941 + 0.055) ÷ 1.055)^2.4 = 0.08865. B 69 ÷ 255 = 0.27059, and ((0.27059 + 0.055) ÷ 1.055)^2.4 = 0.05780.
   - Base at Camper grass (34, 45, 49): R 34 ÷ 255 = 0.13333 → 0.01500. G 45 ÷ 255 = 0.17647 → 0.02620. B 49 ÷ 255 = 0.19216 → 0.03150.
2. **The colour line:** at `alarm` 1 the mix is just `alarm_color`.
3. **The see-through line:** 0.519 × 0.65 × 1.0 = 0.33735.
4. **Blend over the grass,** whose weight is 1 − 0.33735 = 0.66265: R 0.33735 + 0.00994 = 0.34729. G 0.02990 + 0.01736 = 0.04726. B 0.01950 + 0.02087 = 0.04037.
5. **Encode:** R 1.055 × 0.63259 − 0.055 = 0.61238, × 255 = 156.16 → 156. G 1.055 × 0.27958 − 0.055 = 0.23996, × 255 = 61.19 → 61. B 1.055 × 0.26182 − 0.055 = 0.22122, × 255 = 56.41 → 56.

**A known slip** (found by Claude Code's checks, 28 Oct 2026):
- In step 5 the powers come out 1 to 2% low. Raised back to 2.4, 0.4004 gives 0.1112, not 0.11426, and 0.63259 gives 0.3332, not 0.34729.
- Two decodes don't come back to where they started: 0.01500 for 34 comes back as about 32.7, and 0.05780 for 69 as about 68.0. A few others are a fraction off.
- So most channels come out 1 to 3 steps lower than my two lines give, and none higher. Base at Camper's R is 3 low in every cell, past my 2-step match.
- I chose to write the table in as it is (28 Oct 2026). When I compare the captures with it, I check this slip first.

### Revised 28 Oct 2026: my hint experiment predictions

These replace my hint experiment predictions above. Those gave the value each quad's shader receives, not the displayed 8-bit value, and they named the other quad. The numbers here are as I sent them on 28 Oct, worked out with Gemini and ChatGPT and validated by me. In my words: "Its a combination of the AI tools and me validating them". The "why" was written or polished by Gemini or ChatGPT, and checked by me. Claude Code put them in.

**What they assume:** the course's 3×1 PNG of greys 64, 128 and 192, on two unshaded quads, one sampling it with `source_color` and one without, under a Linear tonemap at exposure 1, in Forward+.

| Grey in the file | Quad with `source_color` | Quad without |
|---|---|---|
| 64 | 64 | 135 |
| 128 | 128 | 184 |
| 192 | 192 | 225 |

**Which quad shows the file's values unchanged:** the quad with `source_color`.

**Why** (a tool's wording, checked by me): "Godot’s 3D rendering pipeline always encodes the final spatial shader output to sRGB before displaying it on the screen. When you use `source_color`, Godot decodes the texture from sRGB to linear space when reading it. That decode on read and the encode on display perfectly cancel each other out, returning the original numbers. On the quad without `source_color`, the shader passes the raw data directly to the pipeline, which means the final screen encode applies gamma correction to values that were never decoded, brightening them heavily."

- **On the wording** (Claude Code's note): "always" holds for Forward+, the renderer this project uses, and for Mobile. The assignment says Compatibility may differ.
- **A known slip** (Claude Code's check, 28 Oct 2026): 135 and 184 come out a few steps low, from the same power slip as my pixels. The `source_color` column and 225 are right. When I measure the bands, I check this first.

### Revised 28 Oct 2026: my short answers

These answer the six short questions above, which the 25 Oct text left empty. The wording is Gemini's or ChatGPT's, validated by me. I revised answers 1, 2 and 5 after Claude Code's review, using its notes. Claude Code put them in, with the layout tidied.

1. **The renderer project.godot names, and what it rules out:** Line 15 names the Forward Plus (Forward+) renderer. Regarding the features listed in the assignment's note, Forward+ rules out none of them; decals, compute shaders, VoxelGI, SDFGI, and SSIL are all available in Forward+. Furthermore, Forward+ does not rely on Vulkan alone; it runs on Vulkan, Direct3D 12, or Metal. Choosing this renderer does rule out exporting to the Web.
2. **The colour that arrives in fragment() before I change it, and what the tempting alternative would give:** The color arrives in the `COLOR` built-in, which holds the vertex colors built by Claude Code in `vision_cone.gd`'s `_build_cone`. The tempting alternative is trying to read from `ALBEDO`. However, reading `ALBEDO` before you assign anything to it will simply give you its starting value of solid white, meaning you would completely lose the tip-to-edge fade data stored in the vertices.
3. **Spatial: what ALBEDO holds if I never write it, and what COLOR holds:**
   - `ALBEDO`: If you never write to it, it defaults to solid white (`vec3(1.0, 1.0, 1.0)`).
   - `COLOR`: It holds the `vec4` vertex color passed from the mesh's vertex data or the `vertex()` function, containing both the RGB color and the alpha channel.
4. **How long a frame-counting version would last at 30, 60 and 144 fps:** To find the duration in seconds, divide the total number of frames (120) by the frame rate:
   - at 30 fps: 120 / 30 = 4 seconds;
   - at 60 fps: 120 / 60 = 2 seconds;
   - at 144 fps: 120 / 144 ≈ 0.83 seconds (or 5/6 of a second).
5. **Which resource holds the uniform's default, which holds its current value, and what happens if two objects share the material:** The default value is stored in the `Shader` resource itself, and the current value is stored in the `ShaderMaterial` resource. A material holds uniform values. If two cones share the exact same `ShaderMaterial`, changing a uniform for one will change it for both. This requires the "one material per cone" rule so each cone has its own material to hold its specific uniform values, while the actual alert states and fade timers live in the driver and the game's code.
6. **Does hint_range clamp a value set from code? My prediction:** No, it does not clamp values set from code. In Godot, `hint_range` is an Editor UI directive that tells the Inspector to display a slider with specific bounds for artists and designers. When you change the uniform's value via a script using `set_shader_parameter()`, the engine bypasses the Inspector interface and passes the raw number directly to the GPU shader. The hint is for the interface, not a strict runtime constraint on the variable itself. (My 2.0 capture checks this; see the evidence split.)

### Revised 29 Oct 2026: three gaps found by Claude Code's plan

Written after Claude Code's plan-only run of 28 Oct 2026 (`prompt-2.txt`), which changed nothing. Claude Code checked the plan against the code, and these are the three changes to my brief that came out of it. Where this section differs from the revisions above, it replaces them.

**A second addition to the game's code: a read-only getter.**
- The driver times each cone's fade-in from the moment that camper's cone comes back. The game keeps that moment in `_cone_back_at`, in `scripts/camp_person.gd`.
- So `camp_person.gd` gets a getter, `cone_back_at()`, which returns it and changes nothing.
- The record of who spotted him needs each of the three calls to `spot()` (in `_startle()`, `_search()` and `_return()`) to say who's calling. That's part of the record: nobody calls it at a different time.
- So the game's code gets two additions: that record, and this getter. The campers' behaviour and its timings stay exactly as they are, and presentation code still never writes game state.

**The tolerance at 144 fps.**
- Physics runs at 60 ticks a second at every frame rate, and the camp's clock moves only on a tick. So the uniforms can change only on a frame after a tick: every frame at 60 fps, but only every 2 or 3 frames at 144.
- So the first frame where a value has changed can come up to one tick (16.7 ms) after the time it should change, or one frame at 30 fps, where a frame is two ticks. At 144 fps, one tick is more than one frame (6.9 ms).
- The test reads each fade's start and end off its slope, in game time. Those must still come out within one frame at every rate.
- It also prints the first frame where each value changed, at every rate. Those must come within one frame or one tick, whichever is longer: 33.3 ms at 30 fps, and 16.7 ms at 60 and at 144.
- The frame counts under time scale (2N ÷ s) hold to the same tick: within 1 frame at 30 and 60 fps, and within 3 frames at 144.
- The snap is as before: `alarm` goes from 0 to 1 within one frame of the spotting, at every rate.

**No fade-in when the tutorial ends.**
- "The cones fade in", in the tutorial above, was Claude Code's gap-filling, and no rule times it. Today the cones just appear.
- They still do: when the tutorial ends, each cone appears with `shown` at 1. The only fade-in in my rules is the one when a cone comes back after its 5 s.

(Picked by me on 29 Oct 2026 from Claude Code's recommendations, in my words "Yes, all eight": the getter, a tolerance of one tick at 144 fps for the first changed frame, and no fade-in when the tutorial ends. The other five of the eight approve the plan's steps, and are in `prompt-3.txt`. The facts from the code and the wording are Claude Code's.)

### Revised 29 Oct 2026: no getter, and the 5 s as the game counts them

Written after Claude Code's review of the driver and its test, the `claude -p` agent's work from `prompt-3.txt` (commit 29fd5da). Where this section differs from the revisions above, it replaces them.

**No getter after all.**
- The revision above, "three gaps found by Claude Code's plan", says the game keeps the moment a cone comes back in `_cone_back_at`. That was wrong. The game can draw the cone again a tick after `_cone_back_at`, because the clock, a sum of ticks, can come out a hair under it. A fade-in timed from `_cone_back_at` was then already above 0 on the first frame the cone was drawn. The agent found this in its first run of the test.
- So the driver times each fade-in from the first frame the game draws the cone again, as my 28 Oct rule says: "from the moment the game shows a cone again".
- That left the getter one job: telling a cone that comes back after a spotting from the cones that appear when the tutorial ends. `spotted_at` already tells them apart, because only `spot()` hides the cones.
- So the getter is gone, and the game's code keeps the one addition of my 28 Oct revision: the record of who spotted him.

**The 5 s, as the game counts them.**
- My rules say a cone comes back "5 s after its camper starts walking back". The game, which my boundaries keep as it is, starts a camper's 5 s once they're calm again (at work, walking back, fixing or wondering about a noise) and the cones have gone, whichever comes later. Then it shows their cone again, if they're still calm.
- So a camper who starts walking back while the cones still show gets their cone back later than that. In the driver's test, the girl's came back about 1.6 s later.
- The driver's test prints when each cone comes back, and doesn't assert it, because when is the game's timing. It asserts the fade-in from that moment.

(Picked by me on 29 Oct 2026 from Claude Code's recommendations after its review, in my words "All four": dropping the getter, and writing down how the game counts the 5 s. The other two of the four change the test, not the brief. The facts from the code and the test, and the wording, are Claude Code's.)

### Revised 29 Oct 2026: the normal-map check, calibrated, and its threshold

Written after the check was calibrated on this texture set's own pair (TEST-REPORT.md, "The textures, their import settings, and the normal-map check"). It adds to the material plan above.

- **As given, the check came out reversed:** the GL map, the right one for Godot, scored 1.57 with `directx = false`. As the course says to, `s` is flipped in `tests/normal_map_check.gd`. Now the GL map scores 0.43 with `directx = false` and 1.57 with `directx = true`, and the DX map the other way round.
- **The threshold:** the material test passes a normal map only if it scores below 0.7 with `directx = false`. That's about halfway between this known-good map's 0.43 and the score of about 1 that a map with no surface behind it gets. So it fails a map in the other green convention (1.57 here), and one with no surface behind it.
- **What it can't tell:** a map that passes has a real surface behind it, in Godot's convention, but not necessarily the right surface (the course's note on the check).

(Picked by me on 29 Oct 2026 from Claude Code's recommendation, in my words "Below 0.7". The numbers are from `tests/normal_map_calibration.gd`; the reasoning and the wording are Claude Code's.)

### Revised 29 Oct 2026: the hint experiment, on one quad split in two

Written after Claude Code checked my hint shader against the course's design. It adds to my hint experiment predictions above.

- **The course's design:** a bool uniform picks which sampler writes `ALBEDO`, and two materials from the shader, one per bool value, go on two quads.
- **Mine** (`shaders/hint_experiment.gdshader`): one quad, split down the middle by `UV.x`. The left half samples `with_source_color` (`source_color, filter_nearest`) and the right half `without_source_color` (`filter_nearest` only), and each half shows all three greys. There's no bool, so it's one material on one quad.
- **Why my predictions still hold:** each half reads the same PNG through one sampler, as each of the course's quads would. The "two unshaded quads" they assume are the two halves.
- **Unchanged:** the 3×1 PNG of greys 64, 128 and 192, imported lossless with no mipmaps; the Linear tonemap at exposure 1; Forward+.
- **The scene:** `hint_experiment/hint_experiment.tscn`, with its material `hint_experiment/split_quad.tres`, both Claude Code's.

(My decision on 29 Oct 2026, in my words "Keep the split", from Claude Code's two options: adding the bool, or keeping the split. The facts and the wording are Claude Code's.)
