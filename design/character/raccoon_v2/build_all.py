"""Rebuilds the raccoon in assets/characters/raccoon_v2.blend: head, mesh, rig, weights and
the seven animations, with the settings the current model was made with.

Run from the repo root (add `-- --save` to write the result back into the .blend):

    blender -b assets/characters/raccoon_v2.blend --python design/character/raccoon_v2/build_all.py

or, with the file open in Blender, from the Text Editor or the Python console:

    exec(open(r"<repo>/design/character/raccoon_v2/build_all.py").read())

Each step is its own script in this folder, so one step can be re-run alone after a
change, as long as the steps after it are re-run too (e.g. mesh -> rig -> weights -> anim).
"""
import os
import sys

import bpy
from mathutils import Matrix, Quaternion

try:
    HERE = os.path.dirname(os.path.abspath(__file__))
except NameError:   # exec'd without __file__: find the folder from the .blend
    HERE = os.path.normpath(bpy.path.abspath("//../../design/character/raccoon_v2"))

# The head (face.py). Ear outline traced from idle.jpg (tools/ear_measure.py); smile corners
# and edges picked on idle.jpg and ray-cast onto the muzzle.
FACE = dict(
    ear_pts=[(-0.159, -0.375, 0.549), (-0.175, -0.382, 0.585), (-0.179, -0.388, 0.618),
             (-0.177, -0.392, 0.647), (-0.146, -0.391, 0.658), (-0.106, -0.383, 0.641),
             (-0.059, -0.372, 0.603)],
    rim=0.019,
    smile=dict(corner=(0.055, -0.497, 0.389), top=(0.0, -0.535, 0.383), bottom=(0.0, -0.531, 0.367)),
)
# The body (mesh.py): the head at 1.287x on the neck (solved against idle.jpg), the body
# from the design's proportions, body and legs fused into about 340 big facets.
PARAMS = dict(face_head=(1.287, (0, -0.201, 0.537)), body_v3=True, fuse=True, facets=340)
# A leaner rear (19 Oct 2026: the author said his bum looked big and made him look a bit
# fat). Behind the belly the body now narrows to the tail instead of swelling at the hips
# (top-view width at the hips 0.65 -> 0.56 m, at the rump 0.59 -> 0.43 m), the rump is
# tucked up behind the thighs instead of hanging low, the thigh tops sit in from the
# flanks, and the tail is slimmer where it leaves the body. Head, neck, chest, legs'
# length, back line and tail length are as before. (y, top z, bottom z, half width)
PARAMS.update(
    body3=[(0.54, 0.58, 0.47, 0.06), (0.495, 0.66, 0.37, 0.14), (0.43, 0.72, 0.27, 0.20),
           (0.31, 0.770, 0.19, 0.245), (0.17, 0.765, 0.17, 0.275), (0.03, 0.74, 0.18, 0.272),
           (-0.08, 0.72, 0.19, 0.26), (-0.17, 0.70, 0.21, 0.245), (-0.225, 0.70, 0.27, 0.25),
           (-0.285, 0.675, 0.345, 0.225)],
    thigh=((-0.02, 0.085), (0.0, 0.08)),
    tail_radii=[0.07, 0.082, 0.098, 0.112, 0.12, 0.118, 0.112, 0.10, 0.085, 0.06])


def run(script, **params):
    path = os.path.join(HERE, script)
    ns = {"__name__": "__main__", "__file__": path}
    ns.update(params)
    print("--", script)
    exec(compile(open(path).read(), path, "exec"), ns)


if bpy.context.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")

# The objects the steps write into.
col = bpy.data.collections.get("Raccoon v2")
if col is None:
    col = bpy.data.collections.new("Raccoon v2")
    bpy.context.scene.collection.children.link(col)
if "Raccoon" not in bpy.data.objects or bpy.data.objects["Raccoon"].type != "MESH":
    col.objects.link(bpy.data.objects.new("Raccoon", bpy.data.meshes.new("Raccoon")))
if "FaceWork" not in bpy.data.objects:
    fw = bpy.data.objects.new("FaceWork", bpy.data.meshes.new("FaceWork"))
    bpy.context.scene.collection.objects.link(fw)
    fw.hide_set(True)
rig = bpy.data.objects.get("RaccoonRig")
if rig and rig.animation_data:
    rig.animation_data.action = None
    for t in list(rig.animation_data.nla_tracks):
        rig.animation_data.nla_tracks.remove(t)

run("face.py", FACE=FACE)
bpy.data.objects["FaceWork"].hide_render = True
run("mesh.py", PARAMS=PARAMS)
run("rig.py")
ob = bpy.data.objects["Raccoon"]
ob.matrix_parent_inverse = Matrix()
ob.matrix_basis = Matrix()
run("weights.py")

# Bone collections and colours: red controls to grab, blue ears/tail/eyes.
rig = bpy.data.objects["RaccoonRig"]
arm = rig.data
for c in list(arm.collections_all):
    arm.collections.remove(c)
controls, deform = arm.collections.new("Controls"), arm.collections.new("Deform")
for b in arm.bones:
    (deform if b.use_deform else controls).assign(b)
for b in rig.pose.bones:
    b.rotation_mode = "QUATERNION"
    b.rotation_quaternion = Quaternion()
    if not arm.bones[b.name].use_deform:
        b.color.palette = "THEME01"
    elif b.name.startswith(("ear", "tail", "eye")):
        b.color.palette = "THEME04"

run("anim.py", ONLY=None, P_SLEEP={})

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if "--save" in argv:
    bpy.ops.wm.save_mainfile()
    print("saved", bpy.data.filepath)
print("raccoon_v2 rebuilt")
