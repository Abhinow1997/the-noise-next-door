# SUBMISSION: Assignment 3

> **Draft by Claude Code (15 Oct 2026), from the repo at the `a3` tag.** Fill in everything marked **[to fill]**, and check that the hand-edit text says it the way you would. Then delete this note. This file goes to Canvas with `submission.zip` and isn't committed: it names the tagged commit's own SHA.

**Assignment:** Assignment 3 - Your First 3D Game Assets with Claude, the Blender MCP, and Blender

**Student:** **Abhinav Gangurde** (GitHub: Abhinow1997)

**Project name:** The Noise Next Door

**GitHub repository URL:** https://github.com/Abhinow1997/the-noise-next-door (branch `assignment-3`)

**Git tag and submitted commit SHA:** `a3` → `c729e539c0b07f771da495921ea3eacd575c4c0f`

**Game-source revision shown in the film:** **[to fill: the commit you recorded the film from]**
- The game source hasn't changed since `209bf8d` (14 Oct 2026, 20:34). That means `assets/`, `asset_room/`, `tests/`, `scripts/`, `tools/`, `project.godot`, the scenes and the launchers.
- `git diff 209bf8d a3` on those paths is empty. The later commits change only the docs and the film link, and take the large media out of the repo.
- So a film recorded from `209bf8d` or later shows the same game source as `a3`.

**Godot version, Blender version, and operating system:**
- Godot 4.7.2 stable (official build `ed1daf0bf`), Blender 5.2.2 LTS, Windows 11 Home (build 26300).
- The brief's commands are written for macOS. I ran their Windows equivalents in Git Bash, which has `timeout`.

**The three assets and what each is for:**

| Asset | For | Size, W × D × H | Parts | Triangles (budget) |
|---|---|---|---|---|
| S'more | A snack the raccoon tries to steal, by the campfire | 0.130 × 0.082 × 0.033 m | 6 | 402 (420) |
| Pizza slice | Another snack to steal, on the picnic bench | 0.150 × 0.200 × 0.020 m | 5 | 144 (200) |
| Cooler | A campsite cooler to raid, beside a tent | 0.580 × 0.360 × 0.360 m | 5 | 76 (150) |

**MCP project and version, or "script route":**
- MCP for Blender: the `mcp-for-blender` server 2.1.9 with its Blender add-on 1.8. It's registered in Claude Code with `DISABLE_TELEMETRY=true`.
- All three assets used the MCP route (`execute_blender_code`). There was no script route.
- The add-on's asset libraries and 3D generators were off and never called.
- Every code body Claude ran is in `tools/blender/build_<asset>.py`.

**My hand edit in Blender:** **[check the wording is yours]**
- On the pizza slice, by hand in Blender's window on 14 Oct, I changed the cheese's Base Color from `#F2C14E` to `#F2B908` and moved two pepperoni with G.
- Moving them also changed their heights: one sank 1.7 mm into the cheese and one floated 3.1 mm above it, which Claude found by measuring. I set both back to Location Z 0.009 (saved at 17:25 and 17:27).
- What it taught me is in BLENDER-NOTES.md, under "My hand edit".

**Checks run (command and result):**
- **The commands:** run from the repo root in Git Bash, where `godot` is `Godot_v4.7.2-stable_win64_console.exe`.
  - `godot --headless --path . --import`: all 8 models imported with no errors.
  - `timeout 120 godot --headless --path . --script res://tests/a3_asset_check.gd --fixed-fps 60`: `PASS: 0 check(s) failed`.
  - The same with `-- --mutate`: `PASS: 7 of 7 breaks caught`. It also prints its known limit: a part sunk into another part still passes.
- **What the check measured** (X × Y × Z, against the brief's W × H × D):
  - s'more: 0.1297 × 0.0335 × 0.0823 m, against 0.130 × 0.035 × 0.085;
  - pizza slice: 0.1500 × 0.0200 × 0.2000 m, against 0.150 × 0.020 × 0.200;
  - cooler: 0.5800 × 0.3600 × 0.3600 m, against 0.580 × 0.360 × 0.360;
  - for all three: the bottom at Y = 0, the scale 1, 1, 1, and the height along Y.
- **The fresh clone (15 Oct):**
  - I cloned the repo into an empty folder: `git clone https://github.com/Abhinow1997/the-noise-next-door.git a3-check`, then `git -C a3-check checkout a3`.
  - In the clone, the import, the check (0 failed) and the mutation proof (7 of 7) all ran, and the asset room opened with `godot --path . res://asset_room/asset_room.tscn`.
  - The unzipped `submission.zip` gave the same results, and its files are exactly the ones in `a3`.
- **My human check** (14 Oct, 18:16, in the asset room): "this looks good to me the smores are fine size wise it'll work". **[to fill, if you've done it: what you saw from behind and below, and whether there were any missing faces or wrong colours]**

**Final film URL and filename:**
- URL: https://northeastern-my.sharepoint.com/:v:/g/personal/gangurde_a_northeastern_edu/IQC3xt_YqEIIRKm1kHmIXIVgAUVl3dB4lVUKLrHAG-6cByo?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=uhHctc
- Filename: **Assignment-3-Video-Submission**


**Summary of my changes:**
- **Three props for the campsite:** the s'more, pizza slice and cooler, built through the Blender MCP, with the code kept in `tools/blender/`. Each is exported to `.glb` with its `.blend` source and `.import` files.
- **An asset room in Godot** (`asset_room/asset_room.tscn`): the props at game size beside the raccoon, with size labels and the game camera's view. Launchers for Windows and for macOS or Linux.
- **A headless check** (`tests/a3_asset_check.gd`), with a mutation proof that it can fail.
- **Extras I asked for:** a round pizza made of 5 copies of the slice, my practice donut at life size, the camper and his dropped beanie.
- **The docs:** Assignment 3 sections in CHANGE-BRIEF.md (the brief, committed before building, with dated revisions), TEST-REPORT.md, FRICTIONAL.md, SOURCES.md and the README, plus the new ASSET-PLAN.md and BLENDER-NOTES.md.
- **Large media out of the repo:** Assignment 2's music masters over 25 MB and its MP3s (`c729e53`).

**Known limitations:**
- **Not in the game yet:** the props are only in the asset room, not the game level.
- **The s'more is tiny:** about 15 px from the game's camera.
- **What the check can't see:** a part sunk into another part, or whether an asset looks right. It covers only the three props.
- **Evidence still incomplete,** as the README says:
  - the interface notes in BLENDER-NOTES.md are partly Claude's text;
  - my human check doesn't cover behind and below;
  - Blender's Scene Statistics is in my screenshots for the cooler only.
- **The camper** is an extra, far over the props' triangle limit, with no rig or animation.
- **The large media:** Git's older commits still hold it, and the README's media-storage link is still "link to add". **[remove this line if you fix that]**
- **The film's records:** its beat sheet, script and evidence records aren't in the repo. **[remove this line if you add them]**
- The full list is in the README, under "Known limitations (Assignment 3)".

**Changed games since Assignment 2:** No. It's still The Noise Next Door.

---

**Source ZIP:** `submission.zip`
- Made with `git archive --format=zip --prefix=the-noise-next-door/ -o submission.zip a3`.
- 77,436,036 bytes, 259 files.
- SHA-256: `c545a3525f8caedf8f258c64093288e2065d931933056d20b17a5e346ffb822d`.
- If you move `a3` again, remake the ZIP and update this checksum.
