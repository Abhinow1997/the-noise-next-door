# Builds the armature "RaccoonRig" for the Raccoon mesh in raccoon_v2.blend and skins it.
# Deform bones carry the mesh; *_ik bones are animation controls (not exported).
import bpy
from mathutils import Vector

scene = bpy.context.scene
mesh_ob = bpy.data.objects["Raccoon"]
col = mesh_ob.users_collection[0]

if bpy.context.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")
old = bpy.data.objects.get("RaccoonRig")
if old:
    bpy.data.armatures.remove(old.data)
mesh_ob.parent = None
for m in [m for m in mesh_ob.modifiers if m.type == "ARMATURE"]:
    mesh_ob.modifiers.remove(m)
mesh_ob.vertex_groups.clear()

arm = bpy.data.armatures.new("RaccoonRig")
rig = bpy.data.objects.new("RaccoonRig", arm)
col.objects.link(rig)
arm.display_type = "OCTAHEDRAL"
rig.show_in_front = True

# name: (head, tail, parent, deform)
CENTRE = {
    "root":   ((0, 0.25, 0), (0, -0.05, 0), None, False),
    "pelvis": ((0, 0.40, 0.47), (0, 0.18, 0.48), "root", True),
    "spine":  ((0, 0.18, 0.48), (0, -0.04, 0.45), "pelvis", True),
    "chest":  ((0, -0.04, 0.45), (0, -0.17, 0.43), "spine", True),
    "neck":   ((0, -0.17, 0.43), (0, -0.22, 0.50), "chest", True),
    "head":   ((0, -0.22, 0.50), (0, -0.59, 0.47), "neck", True),
    "tail1":  ((0, 0.46, 0.54), (0, 0.61, 0.54), "pelvis", True),
    "tail2":  ((0, 0.61, 0.54), (0, 0.76, 0.52), "tail1", True),
    "tail3":  ((0, 0.76, 0.52), (0, 0.91, 0.47), "tail2", True),
    "tail4":  ((0, 0.91, 0.47), (0, 1.09, 0.40), "tail3", True),
}
FX, BX = 0.15, 0.19
LEFT = {
    "upperarm": ((FX, -0.17, 0.37), (FX, -0.18, 0.20), "chest", True),
    "forearm":  ((FX, -0.18, 0.20), (FX, -0.205, 0.05), "upperarm", True),
    "hand":     ((FX, -0.205, 0.05), (FX, -0.29, 0.02), "forearm", True),
    "thigh":    ((BX, 0.25, 0.40), (BX, 0.27, 0.18), "pelvis", True),
    "shin":     ((BX, 0.27, 0.18), (BX, 0.33, 0.055), "thigh", True),
    "foot":     ((BX, 0.33, 0.055), (BX, 0.175, 0.02), "shin", True),
    "ear":      ((0.183, -0.361, 0.60), (0.178, -0.37, 0.72), "head", True),
    # Points up through the eye, so scaling it along its length closes the eye.
    "eye":      ((0.081, -0.474, 0.517), (0.081, -0.474, 0.547), "head", True),
    # Controls: drag these to place a paw; the leg bends to reach it.
    # Lined up with the paw bones, so copying their rotation keeps the paws flat.
    "hand_ik":  ((FX, -0.205, 0.05), (FX, -0.29, 0.02), "root", False),
    "foot_ik":  ((BX, 0.33, 0.055), (BX, 0.175, 0.02), "root", False),
}

bpy.context.view_layer.objects.active = rig
for o in scene.objects:
    o.select_set(o is rig)
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.edit_bones


def add(name, head, tail, parent, deform):
    b = eb.new(name)
    b.head, b.tail = Vector(head), Vector(tail)
    b.roll = 0.0
    b.use_deform = deform
    if parent:
        b.parent = eb[parent]
        b.use_connect = (b.head - eb[parent].tail).length < 1e-4
    return b


for name, spec in CENTRE.items():
    add(name, *spec)
for side, sx in (("L", 1), ("R", -1)):
    for name, (h, t, parent, deform) in LEFT.items():
        mirror = lambda p: (p[0] * sx, p[1], p[2])
        par = parent if parent in CENTRE else (parent + "." + side if parent else None)
        add(name + "." + side, mirror(h), mirror(t), par, deform)
bpy.ops.object.mode_set(mode="POSE")

for side in ("L", "R"):
    for chain, target in (("forearm", "hand_ik"), ("shin", "foot_ik")):
        c = rig.pose.bones[chain + "." + side].constraints.new("IK")
        c.target, c.subtarget, c.chain_count = rig, target + "." + side, 2
    for paw, target in (("hand", "hand_ik"), ("foot", "foot_ik")):
        c = rig.pose.bones[paw + "." + side].constraints.new("COPY_ROTATION")
        c.target, c.subtarget = rig, target + "." + side
        c.mix_mode, c.target_space, c.owner_space = "REPLACE", "WORLD", "WORLD"
        # Paws stay flat (they turn with their control) however the leg bends.
bpy.ops.object.mode_set(mode="OBJECT")

# --- Skin: automatic weights, then the parts heat weighting can't see -------------------
for o in scene.objects:
    o.select_set(o in (rig, mesh_ob))
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
# Keep the mirror before the armature so .L weights are copied to the .R side.
mods = mesh_ob.modifiers
arm_mod = next(m for m in mods if m.type == "ARMATURE")
mods.move(mods.find(arm_mod.name), len(mods) - 1)
print("modifiers", [m.type for m in mods])
empty = [vg.name for vg in mesh_ob.vertex_groups if not any(vg.index in [g.group for g in v.groups] for v in mesh_ob.data.vertices)]
print("bones with no weights:", empty)
