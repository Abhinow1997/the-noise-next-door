# Raccoon v2

The scripts that build `assets/characters/raccoon_v2.blend`: a single-mesh, rigged, animated raccoon made to put the 3D raccoon back in the game in place of the sprite cut-outs. It isn't in the game yet; there is no export or Godot hookup so far.

Claude Code wrote these scripts and built the model with them, in Blender 5.2 through the Blender MCP, matched to the author's reference poses in `design/reference/raccoon/`. No generative model made it (see `SOURCES.md`).

## Rebuilding

From the repo root:

```
blender -b assets/characters/raccoon_v2.blend --python design/character/raccoon_v2/build_all.py -- --save
```

Without `-- --save` it rebuilds in memory only. `build_all.py` holds the settings the current model was made with. Rebuilding with them gives the same mesh, weights, rig and animations as the saved file (checked on 10 Oct 2026).

## The steps

| Script | What it does |
|---|---|
| `setup_file.py` | Made the starting `raccoon_v2.blend` from `raccoon.blend`: the reference images, the old model as a guide, the game's camera. Refuses to overwrite the file without `-- --force`. |
| `face.py` | The head, in object `FaceWork`: the first model's head, straightened and reshaped to `idle.jpg` and `standing.jpg`. |
| `mesh.py` | The `Raccoon` mesh: body and legs as one piece, tail, paws, and the head from `FaceWork`. Left half only, plus a Mirror modifier. |
| `rig.py` | `RaccoonRig`: spine, neck, head, ears, eyes, four tail bones and three per leg (deform), plus root and paw controls (`hand_ik`, `foot_ik`) that bend the legs. |
| `weights.py` | Skins the mesh to the rig, part by part. |
| `anim.py` | Seven looping actions at 24 fps, in place: `idle`, `walk`, `run`, `sneak`, `bored`, `sleep`, `climb`. Walk, run and sneak are timed off their foot contacts. Climb is built belly-to-trunk, as the game turns him. |

`tools/` has the helpers used to match the reference images and check the work. They solve a camera from landmarks in a reference, render the model through it, compare overlays and silhouette overlap, trace the ear, and render frame strips and GIFs. Their output goes to the system temp folder.

## Watching the animations

Select `RaccoonRig`, open a Dope Sheet in **Action Editor** mode, pick an action and press Space. The actions are also stored as muted NLA tracks, so an exporter can find them all.
