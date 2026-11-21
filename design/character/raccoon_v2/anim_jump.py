"""Rebuilds only the two one-shot actions, jump and jump_land, in raccoon_v2.blend, by
running anim.py with ONLY = {"jump", "jump_land"}. The head, mesh, rig, weights and the
seven looping actions are left as they are.

Run from the repo root (add `-- --save` to write the result back into the .blend):

    blender -b assets/characters/raccoon_v2.blend --python design/character/raccoon_v2/anim_jump.py -- --save

Then export: assets/characters/export_raccoon_v2.py.
"""
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(HERE, "anim.py")
ns = {"__name__": "__main__", "__file__": path, "ONLY": {"jump", "jump_land"}}
if bpy.context.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")
exec(compile(open(path).read(), path, "exec"), ns)

# A report: each one-shot's frame range, cyclic flag, key frames and interpolation, and
# whether any quaternion F-curve flips sign between keys (which would turn the long way).
for name in ("jump", "jump_land"):
    act = bpy.data.actions[name]
    fcs = ns["action_fcurves"](act)
    frames = sorted({round(k.co.x) for fc in fcs for k in fc.keyframe_points})
    interp = sorted({(round(k.co.x), k.interpolation, k.easing) for fc in fcs for k in fc.keyframe_points})
    flips = []
    groups = {}
    for fc in fcs:
        if fc.data_path.endswith("rotation_quaternion"):
            groups.setdefault(fc.data_path, {})[fc.array_index] = fc
    for dp, comps in groups.items():
        keys = [[comps[i].keyframe_points[j].co.y for i in range(4)] for j in range(len(comps[0].keyframe_points))]
        for a, b in zip(keys, keys[1:]):
            if sum(x * y for x, y in zip(a, b)) < 0:
                flips.append(dp)
    print("%s: frames %s-%s, cyclic %s, %d F-curves, key frames %s" % (
        name, act.frame_start, act.frame_end, act.use_cyclic, len(fcs), frames))
    print("  segments:", interp)
    print("  quaternion sign flips:", flips or "none")

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--save" in argv:
    bpy.ops.wm.save_mainfile()
    print("saved", bpy.data.filepath)
