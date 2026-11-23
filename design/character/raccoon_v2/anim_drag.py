"""Builds only the looping action drag in raccoon_v2.blend (23 Nov 2026), by running anim.py with
ONLY = {"drag"}. The head, mesh, rig, weights and the other nine actions are left as they are,
as anim_jump.py leaves them for the jump. Its report gives drag's frame range and whether every
F-curve's first and last keys match (the seam).

Run from the repo root (add `-- --save` to write the result back into the .blend):

    blender -b assets/characters/raccoon_v2.blend --python design/character/raccoon_v2/anim_drag.py -- --save

Then export: assets/characters/export_raccoon_v2.py.
"""
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
path = os.path.join(HERE, "anim.py")
ns = {"__name__": "__main__", "__file__": path, "ONLY": {"drag"}}
if bpy.context.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")
exec(compile(open(path).read(), path, "exec"), ns)

act = bpy.data.actions["drag"]
fcs = ns["action_fcurves"](act)
frames = sorted({round(k.co.x) for fc in fcs for k in fc.keyframe_points})
seam = [fc.data_path + "[%d]" % fc.array_index for fc in fcs
        if abs(fc.keyframe_points[0].co.y - fc.keyframe_points[-1].co.y) > 1e-5]
print("drag: frames %s-%s, cyclic %s, %d F-curves, %d keyed frames (%s-%s)" % (
    act.frame_start, act.frame_end, act.use_cyclic, len(fcs), len(frames), frames[0], frames[-1]))
print("  seam (first key != last key):", seam or "none")
print("  actions now:", sorted(a.name for a in bpy.data.actions))

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--save" in argv:
    bpy.ops.wm.save_mainfile()
    print("saved", bpy.data.filepath)
