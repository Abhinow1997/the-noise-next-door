# Leaf burst — r0 first visual verdict

The light green and orange pieces show up clearly against the dark grass and bush. At a glance, though, they read more like small square confetti than leaves. The first beat is a few small pieces at the bush rather than a strong burst; afterward, they gather just above and around it. I don't get a clear sense of tumbling or fluttering down.

The second burst is visible while the first is still in the air, and the pieces are gone by the last frame. Overall, the color contrast works, but the burst feels small and contained, with a weak leaf identity. The fire's bright white sparks also draw attention nearby.

## Claude's reading of r0 (fixture capture, 7 Nov 2026)

Read after the verdict above was written. The strip is `captures/leaf_burst/r0/`: frames 10, 12, 15, 20, 30 and 50 of the preview (`previews/leaf_burst_preview.tscn`), at 30 fps, 1280 × 720, the dive-in burst at frame 10 and the hop-out burst (`amount_ratio` 0.5) at frame 20. Sizes are judged at the game camera's scale, about 142 px a metre. This is a claim, to check against the running game.

| Frame | The brief's table | What the frame shows |
|---|---|---|
| 10 (0 s) | Flecks and the first leaves at the bush's top, bright | About 6 leaves and 4 flecks, in a clump about 80 px (0.55 m) across, at the top right of the bush. The flecks are 4–6 px dots. Not a strong first beat. |
| 12 (0.07 s) | Flecks spreading all round, leaves shooting up and out fast | About 10 leaves within about 100 px (0.7 m). Most of them are stippled with the bush's see-through dither: they're still inside the bush, behind its surface. The flecks are barely visible. |
| 15 (0.17 s) | Leaves about 0.4 m out, the fast phase ending; flecks thinning | About 18 leaves over about 160 px (1.1 m), with the flecks as small pale dots among them. Roughly as the table says. |
| 20 (0.33 s) | Flecks gone; leaves slowed and starting to fall, at their widest; the second burst starting at the bush | The first burst is about 220 px (1.5 m) across, with one fleck left. The second burst's first pieces are at the bush's top, stippled. |
| 30 (0.67 s) | Leaves drifting down, starting to fade | Both bursts together, about 265 px (1.9 m) across. The leaves are still mostly at the height they reached, with little visible fall; a few look lighter. |
| 50 (1.33 s) | Nothing left | Nothing left. Matches. |

**Where I agree with the verdict:**
- **Leaf identity:** the pieces read as square confetti. Each leaf is a flat-coloured 0.12 × 0.08 m rectangle facing the camera, with no leaf shape.
- **Colours:** they're paler than the brief's hexes. The browns show as peach, and the greens as pastel yellow-green. That fits the draw material leaving `vertex_color_is_srgb` off, as the build noted.
- **First beat:** weak, a few small pieces at the bush.
- **Size:** small and contained, at most about 1.9 m across with both bursts, against the brief's 2.4 m.
- **Motion:** no tumble or flutter. The angle is fixed (the brief's fade only), and the leaves fade out at 0.6–0.9 s before they've fallen much.
- **The rest:** the second burst shows while the first is in the air, and the strip is empty by frame 50.

**Where I differ:** the bright white shapes near the fire are the game's sparkle icons for the loot on the log (outlined four-pointed stars, drawn over the scene), not the fire's sparks. The fire's sparks are the small dots rising over the flames. The icons show in play too, whenever loot is in range.

**About the fixture:**
- The bush in the strip is half see-through: the level's see-through window dithers it. In play, while he's hidden, the window is off (`scripts/main.gd`, `radius` 0 while `hiding_in`), so at the dive-in the bush is solid. The leaves still inside it, stippled in frames 10–20, would be hidden then.
- The burst's emission sphere (0.55 m round a point 0.5 m up) lies inside the bush, which is about 1 m tall and 1.3 m across. So in play the first frames are likely weaker than the strip shows.
- Before the next strip, the preview should turn that window off as play does, and r0 should be recaptured with it off, so that r0 and r1 compare the effect on the same background.

## 8 Nov 2026 — Effect A, revision r1

**What I saw** (the preview, `previews/leaf_burst_preview.tscn`, windowed at 1280 × 720: the real level on the real renderer): my r0 verdict above. The part this revision answers: "afterward, they gather just above and around it. I don't get a clear sense of tumbling or fluttering down."

**Claude's reading of r0** (a read-only `claude -p` session, 7 Nov 2026: `design/a6/prompt-4.txt`, `design/a6/session-4.jsonl`):
- **Frame 10:** 3 leaves and about 5 tiny flecks, about 70 px across. Weak: `explosiveness` 0.9 spreads the leaves over about 0.09 s, and the 0.04 m flecks are about 6 px.
- **Frame 12:** about 10 leaves, about 100 px across. The flecks don't read as a puff.
- **Frame 15:** leaves about 0.5 m out, about 160 px wide. Close to the intent.
- **Frame 20:** the widest so far, about 220 px (1.55 m) against the intended 340 px (2.4 m). The leaves have stopped but aren't falling. The hop-out burst starts at the bush.
- **Frame 30:** the leaves almost exactly where they were at frame 20. Off: they hang in the air instead of drifting down.
- **Frame 50:** empty, as intended.
- **Why they hang:** `damping` is a linear brake on the whole speed, on the way down too. Gravity's 3.5 m/s² against damping's 2–3 m/s² leaves 0.5–1.5 m/s² downward, so a leaf drops only about 0.1 m by the end of its life.

**Change:** Leaves `gravity` (on its `ParticleProcessMaterial`, `effects/leaf_burst.tscn`), `Vector3(0, -3.5, 0)` → `Vector3(0, -6.0, 0)`, approved by me ("Approve r1", 7 Nov 2026). The same session made it, with the configuration test's expected value (`design/a6/prompt-4-approve.txt`, `design/a6/session-4-change.jsonl`). The configuration test passed (`logs/a6-step4/r1_config_60fps.log`).

**Claude's prediction for r1** (before the change): a net 3–4 m/s² down. A leaf thrown straight up peaks at about 0.3 s and 0.4 m, then falls about 0.6 m before it dies.

| Frame | Predicted |
|---|---|
| 10 | No visible change |
| 12 | Almost the same; the upward leaves a few pixels lower |
| 15 | The fast phase ends sooner; the cluster slightly squatter |
| 20 | About the same width (about 220 px); most leaves at or just past their peak, starting down; the hop-out burst starting at the bush |
| 30 | The main difference: the first burst's leaves about 0.2 m (25–30 px) lower than at frame 20, spread out vertically, starting to fade |
| 50 | Nothing left |

It said the change wouldn't fix the width, the weak first beat or the confetti look, and that a low leaf might sink into the grass at frames 36–37.

**Claude's comparison of r1 with its prediction** (8 Nov 2026: `design/a6/prompt-4-compare.txt`, `design/a6/session-4-compare.jsonl`):
- **Matches:** both strips use the preview's fixed seed, so the same leaf can be found in each. Every leaf that shows fell as predicted: lower than in r0 by about 4 px at frame 15, about 15 px at frame 20 and about 42 px at frame 30. So it fell about 27 px (about 0.2 m) further between frames 20 and 30. Frame 50 is empty.
- **Doesn't match:** frames 10 and 12, and the hop-out burst at frame 20, show far less than r0 (frame 10 shows nothing). The bush is solid in r1 and half see-through in r0, and everything still inside it is hidden. The session couldn't tell from the files why the two captures differ.
- **Its conclusion:** r1 is closer to play, where the bush is solid while he's hidden. It makes the weak first beat worse than r0 showed: most of the burst starts inside the bush and is hidden for its first 0.1–0.2 s. It points at the emission shape (its 0.5 m offset and its radius) as the next thing to look at.
- **Unchecked:** a low leaf at frame 36 may be passing through the ground. The session wasn't sure.

**Claude Code's check of that comparison** (8 Nov 2026):
- **The matched leaves:** I measured five. They're 13–15 px lower than in r0 at frame 20 and 41–44 px lower at frame 30. The comparison holds.
- **Why the backgrounds differ:** the bush's see-through window cuts only scenery nearer the camera than the raccoon, less 0.8 m (`scripts/see_through.gdshader`, set by `scripts/main.gd`). Run headless, the preview gives the same window at r0's commit and at today's: 18.8 m deep, which cuts only the bush's front, as in r1. One scroll-wheel step of zoom makes it 21.6 m, which cuts the whole bush, as in r0. The likeliest cause is a stray scroll during the r0 capture, but that isn't proven. Either way, r1 shows the default view.

**My verdict** (running game, 1280 × 720): kept, because <in my own words>

**Strips** (fixture captures): `captures/leaf_burst/r0/`, `captures/leaf_burst/r1/`

**Commits:**

# Campfire smoke — r0 first visual verdict

The smoke is like filament, and it's like glowing. When the fire is up, I can see it; I saw it in the preview window, and in the gameplay as well. And it looks visibly well lit. Also, if we can update a little bit of the surrounding area with light, that will be a good indicator. At this point, it's just glow on the smoke, but if we can maybe increase the light or visibility of it, that can also play an effect in the gameplay: if the surrounding is a bit well lit, the area in which the NPCs can spot should be affected, and higher. So that is one input that I can see.

And to clear up the doubts: there's just a bucket lying around. Maybe we can have some element of playing with the bucket for the raccoon; at this point, it feels like it's pretty easy. It's just sitting beside the raccoon. Maybe the bucket is just there, and we have to think about how the bucket is available. Maybe the bucket can be filled with water by the raccoon dragging it to the nearby river, and then he can douse the fire. Or maybe we can have a different element, in which somebody fills the bucket with something, and then we switch it with water, and then we can use that, and eventually it would be used on the fire to douse it out. Something like that.

(Dictated by me on 8 Nov 2026, after the preview and play, before Claude Code read the strip. Claude Code transcribed it and fixed the spelling and punctuation.)

## Claude's reading of the smoke's r0 (fixture capture, 8 Nov 2026)

Read after the verdict above was written. The strip is `captures/campfire_smoke/r0/`: frames 10, 25, 55, 100, 110 and 160 of the preview (`previews/campfire_smoke_preview.tscn`), at 30 fps and 1280 × 720. The fire is lit from cold at frame 10 (three logs, strength 0.9), and the bucket douses it at frame 100. Sizes are judged at the game camera's scale, about 142 px a metre across. This is a claim, to check against the running game.

| Frame | The brief's table | What the frame shows |
|---|---|---|
| 10 (lit) | The first puffs at the pit | The pit still cold: no flames and no smoke. The lighting lands on the next frame. |
| 25 (0.5 s) | A short column starting to rise | The flare: tall flames, and the first faint haze just over them, tinted warm by the firelight. |
| 55 (1.5 s) | The column building, puffs growing as they rise | A soft cluster of round, see-through, light grey puffs, about 0.6 to 1.2 m over the pit. It reads as a cloud more than a column. |
| 100 (3 s, doused) | The full column, about 2 m; the fire goes out | The widest it gets: about 1.7 m across and 2 m tall, close to the brief's 1.5 × 2 m. The bucket's just over and the flames are still up. |
| 110 (0.33 s after) | No new puffs at the pit; the column rising away | The flames down to small tongues; the smoke still hangs over the pit and rises. |
| 160 (2 s after) | The last puffs high up, faint | Only faint wisps left high up: nearly clear. Matches. |

**Where I agree with the verdict:**
- It shows clearly whenever the fire's up, lighter than the night grass and the trees behind it.
- It looks lit, almost glowing. The puffs are unshaded light grey, so nothing darkens them, and the firelight warms the low ones.

**Where I'd add to it:**
- It reads as a cloud hanging over the pit more than a rising column. The puffs start only 0.35 m up, rise slowly (gravity 0.12, with damping) and spread, so they pool at about head height.
- **About the surrounding light:** that's the fire's own light (`scripts/campsite.gd`), game code outside the effect. Where he's seen further already follows that light's reach: 0.8 of it, about 6.4 m at full. So a bigger, brighter lit area would change the fire's light, not the smoke's settings.
- **About the fixture:** the preview doesn't place the raccoon, so his bored thought shows up in frame 160. The campers react to the douse's hiss in frames 110 and 160. Neither is part of the effect.


## 8 Nov 2026 — Effect B, revision r1

**What I saw** (the preview, `previews/campfire_smoke_preview.tscn`, windowed at 1280 × 720, and in play): my r0 verdict above. The part this revision answers: "The smoke is like filament, and it's like glowing ... it looks visibly well lit." (The rest of that paragraph, lighting the area round the fire, is game code and outside the effect.)

**Claude's reading of r0** (a read-only `claude -p` session, 8 Nov 2026: `design/a6/prompt-7.txt`, `design/a6/session-7.jsonl`):
- **Frame 10:** a cold pit, no smoke: the logs go on that frame, so emission starts after it's drawn.
- **Frame 25:** only a faint pale haze, about right for 0.5 s.
- **Frame 55:** the shape's right, but the wisps are too bright: they read as glowing, not as haze.
- **Frame 100:** the base reads as a solid lit cloud, against the intent's "a soft haze, not a solid column".
- **Frame 110:** the brightest frame, a big white cloud on the pit: partly the douse taking 0.5 s, partly the same brightness.
- **Frame 160:** faint, nothing new at the pit. Matches.
- **Why it glows:** the material is unshaded, so the night doesn't darken it, and where the 0.45-alpha puffs overlap they build up nearly to the full warm grey.

**Change:** `color_ramp`, the 15% stop's alpha, 0.45 → 0.25 (the stops, colours and interpolation unchanged), approved by me ("Approve r1", 8 Nov 2026). The same session made it, with the configuration test's expected value (`design/a6/prompt-7-approve.txt`, `design/a6/session-7-change.jsonl`). The configuration test passed (`logs/a6-smoke-r1/r1_config_60fps.log`).

**Claude's prediction for r1** (before the change):

| Frame | Predicted |
|---|---|
| 10 | Unchanged: a cold pit, no smoke |
| 25 | Only a hint of haze above the flame tip |
| 55 | Thin, see-through grey wisps; no white core over the flame |
| 100 | The same column shape and height, as a soft see-through grey haze |
| 110 | Still a cloud low at the pit, but grey haze, not a bright white mass |
| 160 | The last puffs barely visible; they might disappear |

**Claude's comparison of r1 with its prediction** (8 Nov 2026: `design/a6/prompt-7-compare.txt`, `design/a6/session-7-compare.jsonl`; by eye: a pixel-measuring script it wrote wasn't allowed to run):
- **Matches:** frames 10, 25, 55 and 160. The glowing, near-white core of frames 55–110 is gone, and the smoke reads as grey haze.
- **Frame 100, partly:** the base is the soft haze predicted, but the column reads about half as tall. Its own miss: lowering the peak lowers the whole fade after it, so puffs past the middle of their life (the top of the column) fall below what shows against the dark grass. r0 overshot the intent at the bottom; r1 falls short at the top.
- **Frame 110, partly:** dimmer than r0's white mass, but still a cloud more than a haze. That comes from the 0.5 s douse (the fire's still at about 0.2 and smoking) and the darker ground once the flames shrink, not from the alpha.
- **Next, if wanted:** the shape of the alpha fade, not its peak.

**Claude Code's check of that comparison** (8 Nov 2026): frames 55, 100 and 110 of r0 and r1 side by side. Both strips have the same background and seed, so the puffs match one for one. In r1 they're see-through: the ground and the dancer's shadow show through them at 100 and 110, the near-white mass is gone, and the upper puffs are fainter. The comparison holds.

**My verdict** (running game, 1280 × 720): kept, because <in my own words>

**Strips** (fixture captures): `captures/campfire_smoke/r0/`, `captures/campfire_smoke/r1/`

**Commits:**
