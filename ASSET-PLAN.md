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

---

## 2. The pizza slice ⬜

`assets/props/pizza_slice.blend` · 0.15 × 0.20 × 0.02 m · budget 200 triangles · build code in `tools/blender/build_pizza_slice.py`

The tip points to the front (−Y). The crust runs along the back edge (+Y).

| Step | Part | Shape | Size (m) | Where | Colour | Triangles | Status |
|---|---|---|---|---|---|---|---|
| 1 | `Pizza_Base` | Cylinder, 3 sides (a triangular prism), one corner turned to −Y, then scaled into the wedge | 0.15 wide at the back × 0.19 long × 0.008 thick | Z 0 – 0.008; from the tip at Y −0.10 to Y +0.09 | cheese yellow `#F2C14E` | 8 | ⬜ |
| 2 | `Pizza_Crust` | Cylinder, 8 sides, lying along X | 0.15 long × Ø 0.02 | Z 0 – 0.02; centre at Y +0.09, so its back is at Y +0.10 | crust `#D9A55B` | 28 | ⬜ |
| 3 | `Pizza_Pepperoni1` | Cylinder, 10 sides | Ø 0.03 × 0.002 | Z 0.008 – 0.010; at X 0, Y −0.02 | pepperoni `#B23A2E` | 36 | ⬜ |
| 4 | `Pizza_Pepperoni2` | Cylinder, 10 sides | Ø 0.03 × 0.002 | at X −0.025, Y +0.04 | (same) | 36 | ⬜ |
| 5 | `Pizza_Pepperoni3` | Cylinder, 10 sides | Ø 0.03 × 0.002 | at X +0.025, Y +0.045 | (same) | 36 | ⬜ |
| | **Total** | 5 shapes | 0.15 × 0.20 × 0.02 | | | **144** of 200 | |

All three pepperoni lie fully inside the wedge. At Y −0.02 the wedge is 0.063 wide, and at Y +0.04 it's 0.11 wide.

**Stops:**
- 📷 **Me:** my message approving the plan.
- 🖼 **Claude:** after each step.
- 📷 **Me:** the finished slice in my Blender window.

---

## 3. The cooler ⬜

`assets/props/cooler.blend` · 0.58 × 0.36 × 0.36 m · budget 150 triangles · build code in `tools/blender/build_cooler.py`

**Waiting on me:** the body colour. Claude suggested blue `#3B7DBF` in the brief.

| Step | Part | Shape | Size (m) | Z range (m) | Colour | Triangles | Status |
|---|---|---|---|---|---|---|---|
| 1 | `Cooler_Body` | Cube | 0.54 × 0.34 × 0.28 | 0 – 0.28 | body colour (my choice) | 12 | ⬜ |
| 2 | `Cooler_Lid` | Cube, overhanging the body by 0.02 on each side | 0.58 × 0.36 × 0.05 | 0.28 – 0.33 | white `#F2F2EE` | 12 | ⬜ |
| 3 | `Cooler_PostL` | Cube | 0.025 × 0.025 × 0.02 | 0.33 – 0.35, at X −0.14 | grey `#8A8F94` | 12 | ⬜ |
| 4 | `Cooler_PostR` | Cube | 0.025 × 0.025 × 0.02 | 0.33 – 0.35, at X +0.14 | (same) | 12 | ⬜ |
| 5 | `Cooler_Handle` | Cylinder, 8 sides, lying along X | 0.30 long × Ø 0.02 | 0.34 – 0.36 | (same) | 28 | ⬜ |
| | **Total** | 5 shapes | 0.58 × 0.36 × 0.36 | 0 – 0.36 | | **76** of 150 | |

**Stops:**
- 📷 **Me:** my message approving the plan.
- 🖼 **Claude:** after each step.
- 📷 **Me:** the finished cooler in my Blender window.

---

## My hand edit ⬜

At least one change I make myself in Blender's window, on one of the three assets: moving a part, scaling it, or changing a colour.
- 📷 **Me:** before and after.
- I write what I changed and what it taught me, in my own words, in [BLENDER-NOTES.md](BLENDER-NOTES.md).
- The build scripts don't include it, so re-running a script rebuilds the asset as it was before my edit.

---

## Later: export and Godot ⬜

These come after all three assets are built, checked and hand-edited.

1. **Export** each asset as binary glTF, `assets/props/<asset>.glb`.
   - Settings: +Y Up (the default), modifiers applied, no cameras or lights.
   - Claude runs Blender's own glTF exporter through `execute_blender_code`, and that code goes at the end of each build script.
2. **Import:** `godot --headless --path . --import`. Here the repo root is the Godot project, not a `godot/` folder.
3. **A small 3D scene:** a floor, one light, a camera, the three assets side by side at game size, and the raccoon beside them for scale.
4. **A headless check** (`tests/`). For each asset it prints the bounding-box size along X, Y and Z, the bottom's height, and the node scale, and fails if they're off the brief.
   - The comparison is W against X, H against Y, D against Z. It isn't "the tallest side is up", because the pizza slice is flat.
5. **📷 Me:** the three assets in the running Godot scene, and my look round each one: from behind, from below, beside the raccoon.
