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
