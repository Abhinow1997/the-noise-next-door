"""Builds assets/characters/raccoon_v2.blend from raccoon.blend: a clean modelling file
with the sprites as reference images, the old model as a see-through guide, and a camera
at the game's angle. This made the starting file; build_all.py builds the raccoon in it.
Run from the repo root:
    blender -b assets/characters/raccoon.blend --python design/character/raccoon_v2/setup_file.py"""
import json
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(bpy.data.filepath)
OUT = os.path.join(HERE, "raccoon_v2.blend")
CUTS = json.load(open(os.path.join(HERE, "raccoon", "cutouts.json")))
PX_PER_M = 146.0      # raccoon_sprite.gd: screen pixels per game metre
GAME_SIZE = 0.8       # player.gd: the model is scaled by this in the game

if os.path.exists(OUT) and "--force" not in sys.argv:
    raise SystemExit("raccoon_v2.blend already exists; pass -- --force to replace it")

scene = bpy.context.scene

# --- Keep only the old raccoon (minus the trowel), as a guide ------------------------
keep = set(o for o in bpy.data.collections["Raccoon"].all_objects if not o.name.startswith("Trowel"))
for ob in list(bpy.data.objects):
    if ob not in keep and ob.type != "LIGHT":
        bpy.data.objects.remove(ob)
for name in ("Background", "Collection"):
    if name in bpy.data.collections:
        bpy.data.collections.remove(bpy.data.collections[name])
old = bpy.data.collections["Raccoon"]
old.name = "Old model (guide)"
for ob in keep:
    ob.display_type = "WIRE"
    ob.hide_select = True
for ob in bpy.data.objects:
    if ob.type == "LIGHT" and ob.name not in scene.collection.objects:
        for c in ob.users_collection:
            c.objects.unlink(ob)
        scene.collection.objects.link(ob)
bpy.ops.outliner.orphans_purge(do_recursive=True) if bpy.ops.outliner.orphans_purge.poll() else None

# --- Reference images ------------------------------------------------------------------
# Image local X -> world -Y (his nose), local Y -> world Z, facing -X: read in Left view (Ctrl+Numpad 3).
FACING_LEFT_VIEW = Matrix(((0, 0, -1), (-1, 0, 0), (0, 1, 0))).to_4x4()


def ref_collection(name, hidden):
    col = bpy.data.collections.new(name)
    scene.collection.children.link(col)
    return col


def add_ref(col, pose, y_offset, ortho_only):
    data = CUTS[pose]
    img = bpy.data.images.load("//raccoon/%s.png" % pose, check_existing=True)
    w, h = img.size
    # cutouts.json gives his on-screen size in the game; undo the game's scale.
    width_m = data["on_screen_px"][0] / PX_PER_M / GAME_SIZE
    m_per_px = width_m / w
    ob = bpy.data.objects.new("Ref_" + pose, None)
    ob.empty_display_type = "IMAGE"
    ob.data = img
    ob.empty_display_size = width_m if w >= h else h * m_per_px
    # Put the point between his paws (anchor_x, feet_row) on the object's origin.
    ob.empty_image_offset = (-data["anchor_x"] / w, -(h - data["feet_row"]) / h)
    ob.matrix_world = Matrix.Translation((0.6, y_offset, 0)) @ FACING_LEFT_VIEW
    ob.empty_image_depth = "BACK"
    ob.use_empty_image_alpha = True
    ob.color[3] = 0.6
    ob.show_empty_image_perspective = not ortho_only
    ob.show_empty_image_only_axis_aligned = ortho_only
    ob.hide_select = True
    col.objects.link(ob)
    return ob


side = ref_collection("Reference: side (running)", False)
add_ref(side, "running", 0.0, True)
poses = ref_collection("Reference: poses", True)
for i, pose in enumerate(("idle", "sneak", "bored", "asleep")):
    add_ref(poses, pose, 2.0 + 1.6 * i, False)
bpy.context.view_layer.layer_collection.children[poses.name].hide_viewport = True

# --- Where the new raccoon goes ----------------------------------------------------------
work = bpy.data.collections.new("Raccoon v2")
scene.collection.children.link(work)

# --- Camera at the game's angle (main.gd: pitch 27 deg, vertical FOV 15 deg, 19.2 m) -----
cam_data = bpy.data.cameras.new("GameCam")
cam_data.sensor_fit = "VERTICAL"
cam_data.angle = math.radians(15.0)
cam = bpy.data.objects.new("GameCam", cam_data)
scene.collection.objects.link(cam)
target = Vector((0, 0, 0.3))
pitch = math.radians(27.0)
# Side-on with his face turned a little toward the camera, like the sprites.
heading = math.radians(-160.0)
dist = 19.2 / GAME_SIZE
d = Vector((math.cos(heading) * math.cos(pitch), math.sin(heading) * math.cos(pitch), math.sin(pitch)))
cam.location = target + d * dist
cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
scene.camera = cam
scene.render.resolution_x, scene.render.resolution_y = 1280, 720

scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1.0
bpy.ops.wm.save_as_mainfile(filepath=OUT, relative_remap=True)
print("SAVED", OUT)
for ob in bpy.data.objects:
    print("  ", ob.name, ob.type, [c.name for c in ob.users_collection])
