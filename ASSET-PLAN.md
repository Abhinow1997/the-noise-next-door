# Asset plan: the three Blender assets

`the-noise-next-door` · CSYE 7270 · Assignment 3 · branch `assignment-3` · written 14 Oct 2026

How Claude Code will build each asset in my open Blender through the Blender MCP, step by step, and where I stop to check and take screenshots. It follows [CHANGE-BRIEF.md](CHANGE-BRIEF.md) v1, committed in `289aa76` before any building. If the build has to differ from the brief, the brief gets a dated revision; this plan doesn't overrule it.

**Who does what.**
- **Claude Code:** wrote this plan and runs every step through the MCP. After each part it reports the numbers from `get_scene_info`, and it saves every code body to `tools/blender/build_<asset>.py`.
- **Me:** I approve the plan for each asset before it's built, look at each part in Blender's window, make the hand edit, and take the screenshots marked **📷 Me**.

**Screenshots.**
- **📷 Me:** my own screenshots of my real session. The film needs these: my prompt to Claude, what it built, and my hand edit. I save them in the repo, and Claude files them in `design/a3/build/<asset>/` with captions.
- **🖼 Claude:** viewport pictures Claude takes with the MCP's `look` tool. They're saved in `design/a3/build/<asset>/`, and every one is labelled as Claude's. They aren't my screenshots, so the film labels them as Claude's.

**Status key:** ⬜ not started · 🔨 in progress · ✅ done (with date)

---

## For every asset

| Step | What happens | Check |
|---|---|---|
| 0a | Save the file that's open, the same as Ctrl+S | The save time on disk |
| 0b | Open a new **empty** file: no cube, camera or light. Units metric, unit scale 1.0, lengths in metres. | `get_scene_info` shows no objects |
| 0c | Save it as `assets/props/<asset>.blend`, and add `<asset>.blend.import` with `importer="skip"` so Godot ignores the `.blend` (the game uses the `.glb`) | The file is on disk |
| 1…n | **One code call per part:** add the basic shape at the brief's size and position, with its flat-colour material | Its location, size, rotation and scale from `get_scene_info`, beside the brief. 🖼 Claude after each part. |
| last | Apply rotation and scale on every part, count the triangles, save, and show it from the front, side, top and three-quarter view | Scale 1, 1, 1, rotation 0. Triangles at or under the budget. The bottom at Z = 0. |
| 📷 Me | My Blender window with the finished asset: the N sidebar open on a part, and Scene Statistics turned on | — |

**The rules for every part:**
- The asset is centred on the world origin, with its base at Z = 0, so its origin is the centre of its underside. The front faces −Y.
- Each part is its own object, named `<Asset>_<Part>`, so I can move or recolour one by hand.
- Colours go on the Principled BSDF's Base Color and on the material's Viewport Display colour, so Solid view and Material Preview match.
- **Never used:** Poly Haven, Sketchfab, Poly Pizza, Hyper3D, Hunyuan3D, Tripo, `generate_3d`, `search_assets` or `import_asset`.
- **Not done during building:** the export. It comes after all three are built and checked (see "Later" below).

---

## 1. The s'more ✅ built 14 Oct (waiting for my look and screenshot)

`assets/props/smore.blend` · 0.065 × 0.065 × 0.04 m · budget 100 triangles · build code in `tools/blender/build_smore.py`

| Step | Part | Shape | Size (m) | Z range (m) | Colour | Triangles | Status |
|---|---|---|---|---|---|---|---|
| 1 | `Smore_CrackerBottom` | Cube | 0.065 × 0.065 × 0.008 | 0 – 0.008 | tan `#C8955A` | 12 | ✅ 14 Oct |
| 2 | `Smore_Chocolate` | Cube | 0.045 × 0.03 × 0.004 | 0.008 – 0.012 | dark brown `#4A2C1D` | 12 | ✅ 14 Oct |
| 3 | `Smore_Marshmallow` | Cylinder, 12 sides | Ø 0.045 × 0.02 | 0.012 – 0.032 | off-white `#F4EEE0` | 44 | ✅ 14 Oct |
| 4 | `Smore_CrackerTop` | Cube | 0.065 × 0.065 × 0.008 | 0.032 – 0.04 | tan (same material as step 1) | 12 | ✅ 14 Oct |
| | **Total** | 4 shapes | 0.065 × 0.065 × 0.04 | 0 – 0.04 | | **80** of 100 | ✅ measured: 0.065 × 0.065 × 0.04, bottom Z 0, 80 triangles |

**Stops:**
- 📷 **Me (before step 0):** this chat, with my message approving the s'more plan.
- 🖼 **Claude:** after each step.
- 📷 **Me (after the last step):** my Blender window with the finished s'more. ✅ 14 Oct, 14:45.

**Pictures of the s'more build** (in [design/a3/build/smore/](design/a3/build/smore/)):

| Picture | Whose | What it shows |
|---|---|---|
| [01_cracker-bottom_by-claude.png](design/a3/build/smore/01_cracker-bottom_by-claude.png) | 🖼 Claude, `look` tool, 14:40 | After step 1: the bottom cracker alone, three-quarter view, Material Preview |
| [02_chocolate_by-claude.png](design/a3/build/smore/02_chocolate_by-claude.png) | 🖼 Claude, 14:40 | After step 2: the chocolate on the cracker |
| [03_marshmallow_by-claude.png](design/a3/build/smore/03_marshmallow_by-claude.png) | 🖼 Claude, 14:40 | After step 3: the 12-sided marshmallow, which covers most of the chocolate |
| [04_finished_front-right-top-3q_by-claude.png](design/a3/build/smore/04_finished_front-right-top-3q_by-claude.png) | 🖼 Claude, 14:41 | The finished s'more after rotation and scale were applied: front, right, top and three-quarter views. From the top it's only a tan square. |
| [05_finished-in-my-blender_by-me.png](design/a3/build/smore/05_finished-in-my-blender_by-me.png) | 📷 **Me**, 14:45 | My own Blender window with the finished s'more, described below |

What my 14:45 screenshot shows:
- The file is `assets/props/smore.blend`, with no `*` in the title. The parts were unchanged from the last save; Claude checked afterwards.
- Object Mode, in Material Preview.
- `Smore_CrackerBottom` is selected. The N sidebar's Item tab shows Location 0, 0, 0.004 m, Rotation 0°, 0°, 0°, Scale 1.000, 1.000, 1.000, and **Dimensions 0.065 × 0.065 × 0.008 m**, which match the plan.
- The Outliner lists the four parts.
- The sidebar has an **MCP for Blender** tab.
- From this angle the chocolate shows as only a thin dark line between the bottom cracker and the marshmallow.
- Scene Statistics isn't turned on in the status bar, so the 80 triangles still need checking there.

### The s'more, v2 ✅ rebuilt 14 Oct, 15:01–15:05 (waiting for my look and screenshot)

**Why:** after my first look I said (14:56) "the smores doesn't feel like more does it". At 14:59 I asked Claude to fix it and to add plain marshmallows (CHANGE-BRIEF.md "Revised in v2"). The v1 file is kept as [smore_v1.blend](design/a3/build/smore/smore_v1.blend).

| Part | Shape | Size (m) | Placed | Colour | Triangles | Status |
|---|---|---|---|---|---|---|
| `Smore_CrackerBottom` | Cube | 0.065 × 0.065 × 0.006 | Z 0 – 0.006 | tan `#C8955A` | 12 | ✅ |
| `Smore_Chocolate` | Cube, turned 8° | 0.055 × 0.05 × 0.005 | Z 0.006 – 0.011 | dark brown `#4A2C1D` | 12 | ✅ |
| `Smore_Marshmallow` | UV sphere 12 × 6, squashed, smooth | 0.072 × 0.068 × 0.018 | Z 0.0085 – 0.0265, bulging past the crackers | toasted cream `#F3E6CC` | 120 | ✅ |
| `Smore_CrackerTop` | Cube, twisted 12°, tilted about 2° | 0.065 × 0.065 × 0.006 | Z 0.0235 – 0.0335 | tan | 12 | ✅ |
| `Marshmallow_Standing` | Cylinder, 12 sides | Ø 0.033 × 0.03 | beside the s'more, standing | white `#F7F3EA` | 44 | ✅ |
| `Marshmallow_Lying` | Cylinder, 12 sides | Ø 0.033 × 0.03 | on its side, turned 35°, resting on Z 0 | white | 44 | ✅ |
| **Whole asset** | **6 shapes** | **0.130 × 0.082 × 0.034** | centred on the origin, base at Z 0 | | **244** of 250 | ✅ measured |

| Picture | Whose | What it shows |
|---|---|---|
| [v2_01](design/a3/build/smore/v2_01_cracker-bottom_by-claude.png) … [v2_05](design/a3/build/smore/v2_05_marshmallow-standing_by-claude.png) | 🖼 Claude | After each part: the thinner cracker, the turned chocolate, the squished marshmallow bulging past the cracker, the twisted top cracker (three-quarter view and top view), the standing marshmallow |
| [v2_06_finished-six-views_by-claude.png](design/a3/build/smore/v2_06_finished-six-views_by-claude.png) | 🖼 Claude | The finished v2 from the front, right, top, three-quarter, about 27° down from the front (close to the game camera's angle) and from behind. From the side the bulge and the chocolate show. From straight above the marshmallow only peeks out a little at the cracker's edge. |
| [v2_07_v2-in-my-blender-material-tab_by-me.png](design/a3/build/smore/v2_07_v2-in-my-blender-material-tab_by-me.png) | 📷 **Me**, 15:39 | My own Blender window with **v2** (before the dots), in Material Preview. I was on the Material tab of `Smore_Cracker` (Base Color tan, Roughness 0.700), with the Cursor tool active and "scale" typed in the Properties search. The 3D cursor sits on the s'more, not at the origin. |

### The s'more, v3 ✅ 14 Oct, about 15:53–15:55: the crackers' groove and dots (waiting for my look and screenshot)

**Why:** at 15:49 I asked: "add some indentations and textures to the biscuits". Textures aren't allowed (flat colours only), so these are geometry plus a second flat colour (CHANGE-BRIEF.md "Revised in v3"). v2 is kept as [smore_v2.blend](design/a3/build/smore/smore_v2.blend).

| Part | Change | Triangles | Status |
|---|---|---|---|
| `Smore_CrackerTop` | A 6 × 6 grid on its top face, the middle line pressed 0.8 mm down (the snap groove), and 8 dots inset 3.5 mm and pressed 0.7 mm in, in darker flat tan `#9C6A36` | 12 → **166** | ✅ |
| `Smore_CrackerBottom` | Its underside split in two, with the middle line pressed 0.8 mm up | 12 → **16** | ✅ |
| **Whole asset** | 6 shapes. Size unchanged at 0.130 × 0.082 × 0.034, base at Z 0, centred. | **402** of 420 | ✅ measured, as predicted |

| Picture | Whose | What it shows |
|---|---|---|
| [v3_01_top-cracker-groove-and-dots_by-claude.png](design/a3/build/smore/v3_01_top-cracker-groove-and-dots_by-claude.png) | 🖼 Claude | The top cracker from above and at an angle: the groove down the middle and the 8 dots. The dots read as **square pits**, because a single inset slopes in from the whole grid square. Real graham crackers have small round pricks. |
| [v3_02_finished-3q-game-angle-top-below_by-claude.png](design/a3/build/smore/v3_02_finished-3q-game-angle-top-below_by-claude.png) | 🖼 Claude | The finished v3: three-quarter view, about 27° down (the game camera's angle), from the top, and from below. From below the bottom cracker is in shadow, so its groove barely shows. |

**Both sides?** At 15:54 I asked for the dots "on both sides of the biscuits". On all four faces it would be about 860 triangles, over the course's 500. Even the two outer faces only would be about 552, unless the marshmallows got simpler. At 16:07, after my laptop crashed and Claude reopened the file intact, I chose "Keep it as it is".

**Stops:** 📷 **Me:** my own look at the s'more and a screenshot of it in my Blender window, with Scene Statistics showing 402 triangles.

---

## 2. The pizza slice ✅ built 14 Oct, 16:09–16:12 (waiting for my look and screenshot)

`assets/props/pizza_slice.blend` · 0.15 × 0.20 × 0.02 m · budget 200 triangles · build code in `tools/blender/build_pizza_slice.py`

The tip points to the front (−Y). The crust runs along the back edge (+Y).

| Step | Part | Shape | Size (m) | Where | Colour | Triangles | Status |
|---|---|---|---|---|---|---|---|
| 1 | `Pizza_Base` | Cylinder, 3 sides (a triangular prism), one corner turned to −Y, then scaled into the wedge | 0.15 wide at the back × 0.19 long × 0.008 thick | Z 0 – 0.008; from the tip at Y −0.10 to Y +0.09 | cheese yellow `#F2C14E` | 8 | ✅ |
| 2 | `Pizza_Crust` | Cylinder, 8 sides, lying along X | 0.15 long × Ø 0.02 | Z 0 – 0.02; centre at Y +0.09, so its back is at Y +0.10 | crust `#D9A55B` | 28 | ✅ |
| 3 | `Pizza_Pepperoni1` | Cylinder, 10 sides | Ø 0.03 × 0.002 | Z 0.008 – 0.010; at X 0, Y −0.02 | pepperoni `#B23A2E` | 36 | ✅ |
| 4 | `Pizza_Pepperoni2` | Cylinder, 10 sides | Ø 0.03 × 0.002 | at X −0.025, Y +0.04 | (same) | 36 | ✅ |
| 5 | `Pizza_Pepperoni3` | Cylinder, 10 sides | Ø 0.03 × 0.002 | at X +0.025, Y +0.045 | (same) | 36 | ✅ |
| | **Total** | 5 shapes | 0.15 × 0.20 × 0.02 | | | **144** of 200 | ✅ measured: 0.15 × 0.20 × 0.02, bottom Z 0, centred, tip at Y −0.10, 144 triangles |

All three pepperoni lie fully inside the wedge. At Y −0.02 the wedge is 0.063 wide, and at Y +0.04 it's 0.11 wide.

**Stops:**
- 📷 **Me:** my message approving the plan: "ok lets do it" (16:09).
- 🖼 **Claude:** after each step.
- 📷 **Me:** the finished slice in my Blender window. Not taken yet.

**Pictures of the pizza slice build** (in [design/a3/build/pizza_slice/](design/a3/build/pizza_slice/)):

| Picture | Whose | What it shows |
|---|---|---|
| [01_base-wedge-3q-and-top_by-claude.png](design/a3/build/pizza_slice/01_base-wedge-3q-and-top_by-claude.png) | 🖼 Claude | After step 1: the wedge from a three-quarter view and from above, its tip to the front |
| [02_crust_by-claude.png](design/a3/build/pizza_slice/02_crust_by-claude.png) | 🖼 Claude | After step 2: the crust along the back edge |
| [03_pepperoni_by-claude.png](design/a3/build/pizza_slice/03_pepperoni_by-claude.png) | 🖼 Claude | After step 5: all three pepperoni |
| [04_finished-six-views_by-claude.png](design/a3/build/pizza_slice/04_finished-six-views_by-claude.png) | 🖼 Claude | The finished slice: front, right, top, three-quarter, about 27° down (the game camera's angle), and from below |

**Claude's own look:**
- It reads as a pizza slice from above and at the game's angle.
- The cheese comes out a pale yellow-tan, close to the crust, so they don't stand apart much.
- From below, the underside is the cheese colour (in shadow, brown), where a real slice is bread-coloured underneath.
- Either could be my hand edit. In Edit Mode, select the bottom face and assign the crust material, or change the cheese's Base Color.


---

## 3. The cooler ✅ built 14 Oct, 17:29–17:33

`assets/props/cooler.blend` · 0.58 × 0.36 × 0.36 m · budget 150 triangles · build code in `tools/blender/build_cooler.py`

**Body colour:** blue `#3B7DBF`, my choice on 14 Oct, about 17:25 (CHANGE-BRIEF.md "Revised in v4").

| Step | Part | Shape | Size (m) | Z range (m) | Colour | Triangles | Status |
|---|---|---|---|---|---|---|---|
| 1 | `Cooler_Body` | Cube | 0.54 × 0.34 × 0.28 | 0 – 0.28 | blue `#3B7DBF` | 12 | ✅ |
| 2 | `Cooler_Lid` | Cube, overhanging the body by 0.02 on each side | 0.58 × 0.36 × 0.05 | 0.28 – 0.33 | white `#F2F2EE` | 12 | ✅ |
| 3 | `Cooler_PostL` | Cube | 0.025 × 0.025 × 0.02 | 0.33 – 0.35, at X −0.14 | grey `#8A8F94` | 12 | ✅ |
| 4 | `Cooler_PostR` | Cube | 0.025 × 0.025 × 0.02 | 0.33 – 0.35, at X +0.14 | (same) | 12 | ✅ |
| 5 | `Cooler_Handle` | Cylinder, 8 sides, lying along X | 0.30 long × Ø 0.02 | 0.34 – 0.36 | (same) | 28 | ✅ |
| | **Total** | 5 shapes | 0.58 × 0.36 × 0.36 | 0 – 0.36 | | **76** of 150 | ✅ measured: 0.58 × 0.36 × 0.36, bottom Z 0, centred, 76 triangles |

**Stops:**
- 📷 **Me:** my message approving the plan: "fixed the pepperoni heights, now lets do the cooler".
- 🖼 **Claude:** after each step.
- 📷 **Me:** the finished cooler in my Blender window. ✅ 17:42.

**Pictures of the cooler build** (in [design/a3/build/cooler/](design/a3/build/cooler/)):

| Picture | Whose | What it shows |
|---|---|---|
| [01_body_by-claude.png](design/a3/build/cooler/01_body_by-claude.png) | 🖼 Claude | After step 1: the blue body |
| [02_lid_by-claude.png](design/a3/build/cooler/02_lid_by-claude.png) | 🖼 Claude | After step 2: the white lid, overhanging by 2 cm |
| [03_posts_by-claude.png](design/a3/build/cooler/03_posts_by-claude.png) | 🖼 Claude | After step 4: the two grey handle posts |
| [04_finished-six-views_by-claude.png](design/a3/build/cooler/04_finished-six-views_by-claude.png) | 🖼 Claude | The finished cooler: front, right, top, three-quarter, about 27° down (the game camera's angle), and from below |
| [05_finished-in-my-blender-scene-stats-76_by-me.png](design/a3/build/cooler/05_finished-in-my-blender-scene-stats-76_by-me.png) | 📷 **Me**, 17:42 | My own Blender window with the finished cooler in Material Preview. The viewport's Statistics show Objects 5, Vertices 48, Edges 72, Faces 34 and **Triangles 76**, and the status bar shows `Verts:48 | Faces:34 | Tris:76 | Objects:0/5`. The area below the Outliner, normally the Properties editor, is showing a second 3D viewport. |

**Claude's own look:**
- It reads as a classic camping cooler: a blue box, a white overhanging lid and a grey handle.
- It's very boxy, with sharp corners and flat sides. Real coolers have rounded corners and often side handles and a drain plug.
- One more shape is allowed (6 at most), and 74 triangles are left in the budget, if I want one of those.


---

## My hand edit ✅ the pizza slice, 14 Oct

**What I changed, as measured by Claude in my saved files (16:33, then 16:34):**
- **The cheese:** I changed `Pizza_Cheese`'s Base Color from `#F2C14E` to `#F2CF0A` (16:33), then to **`#F2B908`** (saved 16:34), a rich golden yellow that stands apart from the crust.
  - Its Viewport Display colour is still `#F2C14E`, so Solid view still shows the old colour. The export uses Base Color.
- **Two pepperoni:** I moved `Pizza_Pepperoni1` (to 0.0063, −0.0096) and `Pizza_Pepperoni3` (to 0.0208, 0.058) with **G**.
  - Moving in a tilted view also changed their heights: Pepperoni1 is **sunk 1.7 mm** into the cheese, and Pepperoni3 is **floating 3.1 mm** above it.
  - That's my predicted failure 3 (floats or sinks), on a single part. **Shift+Z** while moving keeps the height fixed.
  - **Fixed by me:** I set Location Z to 0.009 on Pepperoni1 (saved 17:25) and then on Pepperoni3 (saved 17:27). Claude checked that all three now sit exactly on the cheese, and the slice is still 0.15 × 0.20 × 0.02 m with 144 triangles.
- **Before that, a first try** (16:25) went wrong. It's in FRICTIONAL.md: Solid view hid the colour changes, the cheese material got replaced instead of a slot being added, and a shared material changed two objects. Claude reset the one remaining colour at my request (16:29).

| Picture | Whose | What it shows |
|---|---|---|
| [05_before-hand-edit-from-below_by-me.png](design/a3/build/pizza_slice/05_before-hand-edit-from-below_by-me.png) | 📷 Me, 16:17 | The slice as built, from below, in Solid view, with `Pizza_Base` selected (Location 0, 0.026667, 0.004; Rotation 0; Scale 1) |
| [06_before-hand-edit-from-above_by-me.png](design/a3/build/pizza_slice/06_before-hand-edit-from-above_by-me.png) | 📷 Me, 16:17 | The slice as built, from above, in Solid view, with the pepperoni where Claude put them |
| [07_during-hand-edit-pepperoni-material_by-me.png](design/a3/build/pizza_slice/07_during-hand-edit-pepperoni-material_by-me.png) | 📷 Me, 16:34:30 | Material Preview, with `Pizza_Pepperoni2` selected, on the Material tab for `Pizza_Pepperoni` (3 users, red Base Color, Roughness 0.450) |
| [08_after-hand-edit-cheese-saved_by-me.png](design/a3/build/pizza_slice/08_after-hand-edit-cheese-saved_by-me.png) | 📷 Me, 16:34:55 | **After:** Material Preview, with `Pizza_Base` selected and `Pizza_Cheese`'s golden Base Color showing. The status bar says "Saved pizza_slice.blend". From this angle you can't see that one pepperoni floats and one is sunk; it only shows from the side. |

**In my own words** (what I changed and what it taught me): still to write, in BLENDER-NOTES.md.

**Original plan for this section:** ⬜

At least one change I make myself in Blender's window, on one of the three assets: moving a part, scaling it, or changing a colour.
- 📷 **Me:** before and after.
- I write what I changed and what it taught me, in my own words, in [BLENDER-NOTES.md](BLENDER-NOTES.md).
- The build scripts don't include it, so re-running a script rebuilds the asset as it was before my edit.

---

## Later: export and Godot ✅ 14 Oct, 17:45–18:05, except my look (step 5)

These come after all three assets are built, checked and hand-edited. What happened is in TEST-REPORT.md, "Godot: import, the headless check, and the asset room".
- 1 ✅ exported (17:45);
- 2 ✅ imported with no errors, with LOD generation turned off for the props;
- 3 ✅ `asset_room/asset_room.tscn`, opened by `Look at the A3 assets.bat`;
- 4 ✅ `tests/a3_asset_check.gd`: passes, and its mutation proof catches 7 of 7 breaks;
- 5 ⬜ my look.

1. **Export** each asset as binary glTF, `assets/props/<asset>.glb`.
   - Settings: +Y Up (the default), modifiers applied, no cameras or lights.
   - Claude runs Blender's own glTF exporter through `execute_blender_code`, and that code goes at the end of each build script.
2. **Import:** `godot --headless --path . --import`. Here the repo root is the Godot project, not a `godot/` folder.
3. **A small 3D scene:** a floor, one light, a camera, the three assets side by side at game size, and the raccoon beside them for scale.
4. **A headless check** (`tests/`). For each asset it prints the bounding-box size along X, Y and Z, the bottom's height, and the node scale, and fails if they're off the brief.
   - The comparison is W against X, H against Y, D against Z. It isn't "the tallest side is up", because the pizza slice is flat.
5. **📷 Me:** the three assets in the running Godot scene, and my look round each one: from behind, from below, beside the raccoon.
