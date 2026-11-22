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
