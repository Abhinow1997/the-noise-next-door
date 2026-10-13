"""Exports the rigged raccoon in raccoon_v2.blend to raccoon_v2.glb, ready for the game.

Run it from the repo root after changing the .blend:

    blender -b assets/characters/raccoon_v2.blend --python assets/characters/export_raccoon_v2.py

Nothing is saved back to the .blend. What goes in:
- the Raccoon mesh, with its Mirror modifier applied, skinned to the rig's deform bones
  (the paw controls stay behind; the poses they drive are baked into the animations);
- the seven actions (idle, walk, run, sneak, bored, sleep, climb), sampled every frame.

He faces -Y in the .blend, so he faces +Z in the glTF; scripts/raccoon_model.gd turns him
round to face -Z like the rest of the game. His feet are at y = 0.
"""

import os

import bpy

OUT = os.path.join(os.path.dirname(bpy.data.filepath), "raccoon_v2.glb")
ACTIONS = ["idle", "walk", "run", "sneak", "bored", "sleep", "climb"]

if bpy.context.mode != "OBJECT":
    bpy.ops.object.mode_set(mode="OBJECT")

rig = bpy.data.objects["RaccoonRig"]
mesh = bpy.data.objects["Raccoon"]
rig.location = (0, 0, 0)
rig.rotation_euler = (0, 0, 0)
rig.scale = (1, 1, 1)
missing = [a for a in ACTIONS if a not in bpy.data.actions]
if missing:
    raise SystemExit("missing actions: %s (run design/character/raccoon_v2/build_all.py)" % missing)

# One NLA track per action, so the exporter finds every one; nothing active on top.
ad = rig.animation_data or rig.animation_data_create()
ad.action = None
for t in list(ad.nla_tracks):
    ad.nla_tracks.remove(t)
for name in ACTIONS:
    track = ad.nla_tracks.new()
    track.name = name
    track.strips.new(name, 0, bpy.data.actions[name])
    track.mute = True
for b in rig.pose.bones:
    b.location = (0, 0, 0)
    b.rotation_quaternion = (1, 0, 0, 0)
    b.scale = (1, 1, 1)
bpy.context.scene.frame_set(0)

for o in bpy.context.view_layer.objects:
    o.hide_set(False) if o in (rig, mesh) else None
    o.select_set(o in (rig, mesh))
bpy.context.view_layer.objects.active = rig

options = dict(
    filepath=OUT,
    export_format="GLB",
    use_selection=True,
    export_apply=True,
    export_yup=True,
    export_texcoords=False,
    export_normals=True,
    export_tangents=False,
    export_materials="EXPORT",
    export_cameras=False,
    export_lights=False,
    export_extras=False,
    export_skins=True,
    export_def_bones=True,
    export_morph=False,
    export_animations=True,
    export_animation_mode="ACTIONS",
    export_force_sampling=True,
    export_frame_step=1,
    export_optimize_animation_size=False,
    export_anim_single_armature=True,
    export_reset_pose_bones=True,
    export_current_frame=False,
)
known = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
skipped = [k for k in options if k not in known]
bpy.ops.export_scene.gltf(**{k: v for k, v in options.items() if k in known})
print("Exported", OUT, "(options this Blender doesn't have: %s)" % (skipped or "none"))
