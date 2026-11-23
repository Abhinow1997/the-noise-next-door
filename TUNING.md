# Tuning: The Noise Next Door

`the-noise-next-door` · CSYE 7270 · Assignment 7: animation

The feel of Assignment 7's committing action, tuned from real frame strips and from play. Each revision records:
- what I saw in the running game, at normal speed and at `--time-scale 0.25`: my verdict, in visual terms, written before Claude reads anything;
- Claude's reading of the strip at each phase boundary, against the phase table in CHANGE-BRIEF.md;
- the one change, to the phase table or to one key's transition, made only after I approve it;
- Claude's prediction of what the next strip will show;
- its comparison of the new strip with that prediction;
- my verdict in the running game, and whether the change is kept.

Strips are fixture captures, and they're labelled that way. At least one revision has to come from something I saw in play, not from Claude's first reading.

Assignment 6's tuning (one revision for each effect, both kept) is in `TUNING.md` at tag `a6`.

---

## Assignment 7: the committing action

### r0: my first verdict (21 Nov 2026)

**The strip:** `captures/jump/r0/` (fixture capture). It's `previews/jump_preview.tscn` run with Movie Maker at 30 fps (`--quit-after 60`), F seen on frame 10, a held jump. I kept frames 10, 13, 14, 16, 17, 21, 22, 27, 28 and 40 (CHANGE-BRIEF.md, "the jump's frame strip"). The per-frame log of the same run headless is `logs/jump_preview_frames.log`.

**What I saw,** from the captured frames, before Claude read them (dictated; Claude Code fixed only the punctuation):

> I can see the raccoon jumping in the captured frames. I can see the push from its hind legs, which feels natural and appropriate in this particular action. And it feels better as compared to the version one which we created. So we will move ahead with this.

"The version one which we created" is the first jump: the crouch before takeoff and the bite window, before the remodel (CHANGE-BRIEF.md, "the jump plays as it did before").

### r0: Claude's reading of the strip (fixture capture, 21 Nov 2026)

These are Claude Code's claims, read from the ten frames after my verdict above, against the phase table and `logs/jump_preview_frames.log`. They aren't checks.

| Frame | Ticks | The table says | The strip shows |
|---|---|---|---|
| 10 | 0–1, takeoff | the push-off, hind legs extending | Nearly his standing pose, leaning a little forward, 0.14 m up. The clip is at 0 s and still blending in from idle (`JUMP_BLEND` 0.08 s), so the push-off barely shows on the first frame. |
| 13, 14 | 6–9, rising | stretched up, snout first | Reared almost upright: snout high, front paws up by his chest, hind legs reaching down. A strong, clear stretch. |
| 16 | 12–13, the peak | gathering | Flat out, level, tail straight back, paws tucked. In two frames he's turned from upright to level. |
| 17 | 14–15, the top | gathered | Much as frame 16, starting to fall. |
| 21 | 22–23, coming down | front paws reaching for the ground | Nose down, front paws reaching, tail up. It reads. |
| 22 | 24–25, landing | touching down, squashed | Front paws down, body tipped nose-down. A landing, if a small one. |
| 27, 28 | 34–37, the landing's end | back in his stance | His stance at frame 27 already (`jump_land` held), idle at 28. |
| 40 | after | his stance | His stance. |

**Where the motion and the table disagree:**
- **Takeoff (frame 10)** doesn't show the push-off strongly: the 0.08 s blend into `jump` mixes it with his standing pose on the very frame the jump begins. The push mostly reads between frames 10 and 13.
- **The turn from upright to level** (frames 14 → 16, the clip's keys at 0.125 s and 0.25 s) is fast.
- Everything else matches the table: the stretch, the top on tick 15, the reach, the touchdown on tick 25, the stance by tick 37.

### r1: what I saw in play, and the change (21 Nov 2026)

**What I saw** (dictated after playing; Claude Code fixed only the punctuation):

> The takeoff seems a little off, not quite there. The hind legs don't particularly move, so we can update the frames on those if possible.

(I also asked for a firmer F press to send him farther. A keyboard reads how long F is held, not how hard, and that would be a change to the jump's movement, not this animation, so it's decided separately.)

**The one change** (Claude Code's proposal, "Yes, make r1"): the push-off key, frame 0 of `jump`, is re-posed in `design/character/raccoon_v2/anim.py` with the hind legs bunched under his hips, thighs folded and hind paws forward under his belly. They drive straight out by the stretch at frame 3, eased fast out of the bunch.
- **What doesn't change:** the other keys (3, 6, 10), the clip's length and timing, `jump_land`, the seven loops and the phase table. So the pins and the edge tests don't change either.

**Claude's prediction for strip r1** (same capture, F seen on frame 10):
- **frame 10:** his hindquarters lower than in r0, hind paws forward under his belly. It's still partly blended with his standing pose, since the clip blends in over 0.08 s.
- **frames 13 and 14:** the hind legs fully straightened back and down, visibly longer than in r0, the push now readable from 10 to 13.
- **frames 16 to 40:** the same as r0.

**Made** (the agent's session, `design/a7/prompt-9.txt`; checked by Claude Code):
- **The pose:** in `anim.py`'s push-off, the hind paws are pulled forward under his belly (0.13 m forward, 0.03 m up), the toes are flatter (pitch 0.75 → 0.3), and the hips are lowered 2 cm. Rebuilt alone, re-exported, reimported.
- **What moved:** the seven loops and `jump_land` hash identically; `jump` keeps its 10 frames and its keys at 0, 3, 6 and 10.
- **The hind legs, frame 0 to frame 3:** the thigh now swings 72.6° (22.7° in r0), and the shin goes from folded 83° to straight.
- **The read-back changed with it:** the stronger push straightens the shins by frame 2, and they stay within 0.04° of straight through frame 4, so the importer drops their frame-3 key. The check now counts a track as held through a frame when its keys either side are within 0.1° (it was about 0.00001), as I chose: "Yes, 0.1° tolerance". No expected value changed.
- **Tests:** rig read-back 51/51, jump states 89/89, pins 26/26, edges 238/238.

### r1: Claude's comparison of strip r1 with its prediction (fixture capture, 21 Nov 2026)

`captures/jump/r1/` is the author's capture of the same preview, trimmed to the same ten frames. These are Claude Code's claims, read side by side with r0.
- **Frames 16 to 40:** the same as r0, as predicted.
- **Frame 10:** hardly different from r0. The prediction said his hindquarters would sit lower with the hind paws forward. On the takeoff frame the clip has only just started and is still blending in from his standing pose (`JUMP_BLEND` 0.08 s, about 2.4 frames at 30 fps), so the new bunched pose barely shows.
- **Frames 13 and 14:** the same as r0. The prediction said the hind legs would look longer. They don't, because the stretch key (frame 3) didn't change, so the legs end in the same straight pose. That part of the prediction was wrong.
- **So the strip can't show r1's change well.** The new drive from the bunch happens between frames 10 and 13: the thigh swings 72.6° instead of 22.7°. That's on frames 11 and 12, which the strip doesn't keep, and it's partly hidden under the blend from standing.
- **Whether the push reads now** is for the author's eyes in play, at normal speed and at `--time-scale 0.25`. If it still doesn't, the blend into `jump` is what's left hiding it.

### r1: my verdict in play (21 Nov 2026)

Asked "Does the push off the hind legs read now when you play it?": **"Yes, keep r1"**. Kept.

---

## Assignment 7: the raccoon's seven loops

From CHANGE-BRIEF.md's revision of 22 Nov 2026, "a frame strip for each of the seven loops": each loop gets a strip as the jump did, read against its cycle spec, and my verdict. A loop changes only where I ask for one.

### Loops r0: my verdict (22 Nov 2026)

**The strips:** `captures/loops/r0/<clip>/` (fixture capture).
- They're cut by `tools/crop_loop_strips.gd` from my Movie Maker capture of `previews/raccoon_loops_preview.tscn`, at 24 fps, the clips' own rate (`--quit-after 240`).
- Each strip comes from its clip's second wrap and ends on the seam into the third. The frames kept are the brief's.
- Each frame is named `frame<captured frame>_f<clip frame>.png`. The log of the same run is `logs/raccoon_loops_preview_frames.log`.

**What I saw,** going through each strip's frames, before Claude's reading. Dictated; Claude Code fixed the punctuation, wrote "bored" for the dictation's "Board", and left out the asides while I moved between frames (marked …).

> **idle:** "So I'm looking through and going through the idle frame. So, feels good, like he is just standing and glancing about. He does a small blink, which is fine. I mean, it's an indicator to, like, just standing around: maybe the player needs to do something, so it's fine. It works for me for this particular one."

> **walk:** "… Yeah, feels natural, good enough. Like, I can see the leg movement is also well. Like, we have folds in our legs, which feels a little bit more natural than it was originally. Um, we work and we'll work with this particular one."

> **run:** "For run as well, we've gone through. Feels good, like, the bends and all for the body and the legs that we are doing feels natural."

> **sneak:** "For sneak, he changes his stance, bends down, and has, like, a radius, like, has a, like, a curious eye. I don't know that, like, shape of it, but it feels natural in terms of what he's doing. Like, he's more focused and, like, he's trying to sneak around, so it gives a good indicator for that as well."

> **bored:** "Bored as well, just sitting on his hind legs and just sort of sleeping. Feels like a little bit like eyes closed and sleep sort of motion, but I feel okay with that particular element. It also has an indicator of it being a ZZZ on its head, so it's okay."

> **sleep:** "For sleep, yeah, I mean, there's no movement in that particular sleep, which is fine. We don't have a natural sleep animation apart from, like, when we'll be cutting into cutscenes, so that's fine for me."

> **climb:** "For climb as well, it's fine. Maybe we'll need to work on climb in the future, but for now, I'm just gonna go ahead and we'll move ahead with climb."

> **All seven:** "So we will go ahead with that and make the notes for these particular things for the animations, and let's proceed ahead."

### Loops r0: Claude's reading of the strips (fixture capture, 22 Nov 2026)

These are Claude Code's claims, against the brief's table of what each frame should show. They were read from the 168 × 126 px crops, with pixel differences between frames, and held back until my verdict above was in. They aren't checks.

| Clip | The brief says | The strip shows | Beside my verdict |
|---|---|---|---|
| `idle` | Glancing one way (24) and the other (72), the blink (29), the ear flick (60) | The head turns read: a little away at 24, toward the camera by 60 and most at 72, back ahead by 95. At this size the blink and the ear flick are a few pixels: the change from 24 to 29 (1,194 px) is mostly the head still turning. | I saw the blink; Claude couldn't make it out in the crops. My eyes stand. |
| `walk` | A trot: all four feet down at 1 and 13, the body highest there and lowest at 7 and 19 | The diagonal stepping reads, and the biggest change is from 1 to 7 (4,433 px). The body's rise and fall isn't visible at this size. | Agree: the legs read, with the joints folding. |
| `run` | Hind feet land at 0 and push off at 7; front feet land at 8 and push off at 15 | It reads as a lope: stretched out at 7 and 8 (hind legs back after the push-off, front legs reaching to land), gathered at 12, 15 and 0. | Agree. |
| `sneak` | Three paws down; a paw lifted at 6, 18, 30 and 42 | Low and crouched all through. The front paw lifting at 6, and curled under at 30, reads. The hind steps (18, 42) are hidden under his body at this angle and size. | Agree: a focused creep. |
| `bored` | The sigh (in at 0, out by 24), the tail's flick (36), a slow blink (53) | It reads as one held, slumped pose with half-shut eyes. Only the sigh shows as a change (0 to 24, 2,379 px). From 24 to 36 and 36 to 53, about 150 px change each: the tail lies behind him out of view, and the blink is too small to see. | Agree: it reads sleepy, eyes half shut (the clip's lids are at 0.45). The bored face over his head says the rest. |
| `sleep` | The same in every frame | Identical: 0 px change from 0 to 48, as the read-back said. | Agree. |
| `climb` | Diagonal pairs reaching up and gripping | In the preview he's on flat ground, not a trunk. His head, looking up the trunk, runs into the bush beside him and is half hidden. The legs alternate, spread widest at 12. Which pair is which can't be told at this size. | Agree it's fine for now. It's best judged up a tree in play, where the game turns him onto the trunk. |

**The seams:**
- Every loop's last frame runs into frame 0 with no visible jump.
- Frame 0 one wrap later is the same pose:
  - `walk`, checked pixel by pixel: none of his own pixels changed. What changed is the run copy beside him, its shadow, the idle copy's head and the label's digit.
  - `idle`, `bored`, `sleep` and `climb`: only the label's digit changed.
  - `run` and `sneak`: 56 and 69 px changed in their own columns, where their neighbours' tails and shadows reach. Claude didn't separate those.
- The rig's read-back checks each loop's seam in its tracks; this is the same seen in the pictures.

**What the strips can't show:**
- which side's paw is which;
- the walk's bob;
- small moves of the eyes, ears and tail.

Each crop also takes in a neighbour's tail at its edge and the label's bottom line, since the copies stand 1.15 m apart. A later capture with the copies about 1.6 m apart would give clean crops.

### Loops r0: kept (22 Nov 2026)

All seven loops are kept as they are, with no tuning revision: "So we will go ahead with that … and let's proceed ahead".
- **`climb`:** "Maybe we'll need to work on climb in the future". That's for later, not this change.
- **`sleep`** stays still: "there's no movement in that particular sleep, which is fine".
