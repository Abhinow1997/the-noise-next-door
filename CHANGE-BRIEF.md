# Change brief: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 2 · Draft v1, 6 Oct 2026

The plan for the asset slice: what goes into it, which sound plays on which event, how the music behaves, and what I expect to go wrong.

**When this was written.** :
- the style target is from 1 Oct;
- the first raccoon pose images are from 2 Oct, 17:09;
- the forest music loop is already in the game.

Everything below was still decided before any generated art went into the game. It also comes before the ground texture and three of the four sound effects are generated.

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

## Asset list

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

## Order of work

1. Cut out the five poses, scale them, and put them in the game in place of the model, with the state swaps and mirroring.
2. Generate ENV-GROUND, make it tile, put it on the ground, and check the contrast.
3. Generate SFX-GRAB, SFX-FLOURISH and SFX-ALL-DONE, pick the chitter take, then trim and convert all four.
4. Wire up the sounds, the two buses, mute, pause and the end of the slice.
5. Add the automated sound-count test.
6. Playtest it myself with sound on and then muted, and write TEST-REPORT.md.

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
- **Generative models:** none were used to write this.
