# Change brief: The Noise Next Door

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

## The slice

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

## Asset list

### Revised in v2 (6 Oct 2026): the sounds and the ground

| ID | What | In the slice | Panels | Status |
|---|---|---|---|---|
| SFX-RUN | `assets/audio/sfx/run-loop.wav`, a loop cut from my running sound | While he runs (Shift) | 3, 5, 6, moving between jobs | Done: looped and imported |
| SFX-CLIMB | `assets/audio/sfx/climb-loop.wav`, a loop cut from my climbing sound | While he moves on a trunk | 3 (stands in for SFX-SLIDE) | Done: looped and imported |
| SFX-CHITTER | Laugh take A, `design/music/raccoon-cheeky-laugh.mp3` | The chitter (Space) | None: it's the raccoon's voice from the prototype | Have it; convert to WAV |
| SFX-TASK-LAUGH | Laugh take B, `design/music/raccoon-cheeky-laugh-2.mp3` | A to-do item ticked off | 6 (replaces SFX-FLOURISH) | Have it; convert to WAV |
| ENV-GROUND | `design/reference/ENV-GROUND.jpg` (Gemini), generated at 20:42 | The clearing's ground | 3, 5, 6 | Have it. It may need darkening, because his fur is as bright as it (CHARACTER-SHEET.md v5). |
| SFX-GRAB, SFX-FLOURISH, SFX-ALL-DONE | — | Dropped | — | Not generated |

The v1 table below still holds for the raccoon's images and the music. For the sounds and the ground, the table above replaces it.

### Revised in v3 (6 Oct 2026): the environment asset

| ID | What | In the slice | Panels | Status |
|---|---|---|---|---|
| ENV-STUMP | A low-poly tree stump (Gemini, prompt below), cut out like the raccoon | It stands in the clearing near where he starts, and he walks round it, because it has collision | 3, 5, 6: the clearing | To generate |
| ENV-GROUND | `design/reference/ENV-GROUND.jpg` | Rejected in the game; the texture is switched off with `GROUND_TEXTURE` in `scripts/main.gd` | — | Not used |

*Update, 6 Oct, 22:28:* I generated ENV-STUMP (`design/reference/stump.jpg`), two minutes after v3 was committed.

### Generated (these count for the brief)

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

### Not generated (listed so the slice is complete; they don't count)

- **The forest, its trees, bench, bin, cans and gnome:** Claude's code, in `scripts/forest.gd`.
- **The to-do list and the "all done" banner:** code, in `scripts/main.gd`.
- **The Blender raccoon (`raccoon.glb`):** Claude's model. It stays in the project, but the slice shows the generated images instead.
- **The code-made chitter tone:** replaced by SFX-CHITTER.

## The raccoon's images in the game

- **One image per state.** When more than one state applies, the first in this order wins: asleep, climbing, sneaking, moving, bored, idle. While he carries something, he keeps his current state's image, and the object is drawn at his mouth. The hop up into the hollow uses CHAR-RUN.
- **Facing:** every image faces front-right, and the game mirrors it when he moves left on screen. Moving straight up or down the screen keeps his last facing. There are no back views, so walking away from the camera still shows his front.
- **Cut-outs:** the green is removed with a colour key, and each image is cropped to the raccoon. All five are scaled to the same body size, so swapping states doesn't make him jump in size. Every edit goes in the asset log.
- **Size and collision:** he collides as a capsule lying along his body, 0.64 m long and 0.32 m wide and tall, with its bottom at his feet (`scripts/player.gd`). CHARACTER-SHEET.md still gives 0.8 m by 0.4 m, which was before the size setting of 0.8 was added; the sheet will be corrected.
  - Each image is placed so his paws stand on the capsule's bottom, at the size the camera and level were tuned for.
  - His head, ears and tail reach past the capsule. That's fair, as the sheet says, because nothing in the game needs to hit them.

## Event-to-sound map

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

## Music behaviour

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

## Predicted failures, and how I'll check each

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

## Prompts for what's still to generate

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

## Order of work

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
