# Blender build scripts

For Assignment 3, every piece of Python that Claude Code runs in Blender through the MCP is copied here, so Git shows how each asset was built.

- **One file per asset:** `build_smore.py`, `build_pizza_slice.py` and `build_cooler.py`; and, beyond the three, `build_camper.py` and `build_beanie_dropped.py`.
- **Inside each file:** the `execute_blender_code` calls, in the order they ran.
  - Each call is headed by a comment giving its number and what it did.
  - Calls that failed or were undone stay in the file, commented out and marked.
- **The export:** the code that writes the `.glb` goes at the end of the same file.
- **Not in these scripts:** my hand edit in Blender's window isn't Python, so it's described in [BLENDER-NOTES.md](../../BLENDER-NOTES.md). Re-running a script rebuilds the asset as it was before that edit.

The `.blend` sources and the exported `.glb` files live in `assets/props/`.

**After Assignment 3:** `prepare_tent.py`, `prepare_table.py` and `prepare_humans.py` aren't records of MCP calls. They're scripts Claude Code wrote and ran in a background Blender, which turn the author's downloads in `design/downloads/` into the game's `assets/props/tent` and `table_with_laptop`, and `assets/characters/human_male` and `human_female` (`.blend` and `.glb`). How to run each is at the top of its file.

`prepare_chubby.py` is another of them: it makes `assets/characters/chubby_boy` (`.blend` and `.glb`) from `design/downloads/chubby/`. Re-running it gives a byte-identical `.glb`. It ends by running `animate_chubby.py`, which keys his animations (`walk`, `run`, `bend`, `take_away`) the way `animate_human_camper.py` does the rigged camper's; run on its own, it re-keys the saved `chubby_boy.blend` and exports the `.glb`. Its header gives each clip's length and natural speed, and where the raccoon and the item go in `take_away`.

`prepare_lowpoly_man.py` does the same for TiZeta's low-poly man: it makes `assets/characters/lowpoly_man` (`.blend` and `.glb`) from `design/downloads/lowpoly_man/`, and re-running it gives a byte-identical `.glb`. He has the chubby man's rig, so `animate_lowpoly_man.py` runs `animate_chubby.py`'s solver unchanged with his own numbers (his steps, his arms, his stoop). It also works on its own, re-keying the saved `lowpoly_man.blend`.

`prepare_simple_girl.py` and `animate_simple_girl.py` do the same for TiZeta's simple girl (`assets/characters/simple_girl`, from `design/downloads/simple_girl/`), on the same rig with her own numbers. Re-running gives a byte-identical `.glb`.

Since 23 Oct 2026 (level 1's campsite) the three figures also have a looping `dance`, four beats in 64 frames, each with his or her own arms, and the chubby man a looping `hammer`, knocking in a tent peg with a mallet the game puts in his hand (`mallet_grip` prints where). `animate_chubby.py` holds both; the other two scripts give their own `DANCE` numbers. Re-running each `prepare_*.py` still gives a byte-identical `.glb`.

The same day they got their reactions to the raccoon: `scared` for all three, `guard` and `shoo` for the men, `cower` for the girl (`react_clips` in `animate_chubby.py`; each figure's `REACT` sets its numbers).

On 10 Nov 2026 all three got a looping `confused` (75 frames, 3 s), for once the raccoon's got away: standing still, the right hand scratching the side of the head while only the head looks left and right (`confused_clip` in `animate_chubby.py`). Where the hand goes is measured on each figure's head; the low-poly man and the girl scratch a little lower (their `REACT`'s `scratch_up`). The elbow comes forward (`scratch_elbow`): out to the side, the upper arm tore the mesh open in the armpit. The game sets it to loop (`camp_person.gd`), since the `.glb`'s import settings don't list it.

On 23 Nov 2026 the girl's edges were smoothed ("make the edges on them smother ... take the girl 1st", then "Smooth twice"). `prepare_simple_girl.py` puts a Subdivision Surface modifier, two levels (`SMOOTH_LEVELS`), ahead of her Armature, and `animate_simple_girl.py` exports her `.glb` with modifiers applied (the exporter leaves the Armature out and exports her skin as before). Her mesh in the `.blend` isn't changed, so her clips, which `animate_chubby.py` measures on it, keep their keys: the new `.glb`'s nine clips are byte for byte the old one's.

The same day the two men were smoothed the same way ("Yes, both men"): `prepare_chubby.py` and `prepare_lowpoly_man.py` put the same modifier on their bodies, and on the chubby man's beanie too, which is now smooth-shaded ("Smooth it too"). `animate_chubby.py`'s `EXPORT` now applies modifiers, for all three figures. **Run their scripts with `-t 1`** (one thread): on several threads Blender's subdivision isn't the same to the last bit from run to run, and the girl's `.glb` came out three ways in four runs (a couple of vertices split or not). With `-t 1` every rebuild is byte-identical, and `export_glb` stops with an error without it.

`build_human_camper.py` is the same kind of script. Claude Code first built the camper on the male human in my Blender through the MCP, then wrote that work up as one background run. It takes `assets/characters/humans.blend` and `camper.blend` and makes `assets/characters/human_camper.blend` and `.glb`. Its rebuild gives a byte-identical `.glb`. His jacket's body, sleeves, hood and hoodie front aren't the camper's: the script's `CLOTHES` stage makes them again for him, and `garment_weights` weights them.

`animate_human_camper.py` gives him his animations (`walk`, `run`, `bend` and `take_away`), keyed on his 62 bones and exported with him. Claude Code wrote it and ran it in a background Blender, and nothing in it came from the MCP. `build_human_camper.py` ends by running it. Run on its own, it re-keys the saved `human_camper.blend`, saves it and exports the `.glb`, a quicker way to change the animations. Both ways give the same byte-identical `.glb`. Its header gives each clip's length and natural speed, and where the raccoon and the item go in `take_away`.

## Running a script without the window

On this machine (Windows, Git Bash):

```bash
"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --python-exit-code 1 --python tools/blender/build_smore.py
```

`--python-exit-code 1` makes Blender exit with an error when the script raises one. Without it, Blender exits 0 even when the script fails. The three figures' scripts (`prepare_chubby.py`, `prepare_lowpoly_man.py`, `prepare_simple_girl.py` and their `animate_*.py`) also need `-t 1`, as their headers show.
