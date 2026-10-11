# Renders orthographic close-ups of a region from several directions into one strip.
import bpy, numpy as np, os
from mathutils import Vector, Matrix
import tempfile
# Renders and comparison sheets go to a temp folder, not the repo.
SCR = os.path.join(tempfile.gettempdir(), "raccoon_v2")
os.makedirs(SCR, exist_ok=True)


def shots(center, dirs, size, out, objects=("Raccoon",), px=500):
    sc = bpy.context.scene
    r = sc.render
    saved = (sc.camera, r.resolution_x, r.resolution_y, r.resolution_percentage, r.film_transparent, r.filepath,
             r.image_settings.file_format)
    hidden = {o: o.hide_render for o in sc.objects}
    cam = bpy.data.objects.new("_shotcam", bpy.data.cameras.new("_shotcam"))
    sc.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = size
    cam.data.clip_start = 0.01
    cam.data.clip_end = 20
    tiles = []
    try:
        sc.camera = cam
        r.resolution_x = r.resolution_y = px
        r.resolution_percentage = 100
        r.film_transparent = False
        r.image_settings.file_format = "PNG"
        for o in sc.objects:
            if o.type == "MESH":
                o.hide_render = o.name not in objects
        for d in dirs:
            d = Vector(d).normalized()
            cam.location = Vector(center) + d * 5
            cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
            tmp = os.path.join(SCR, "_shot.png")
            r.filepath = tmp
            bpy.ops.render.render(write_still=True)
            img = bpy.data.images.load(tmp, check_existing=False)
            a = np.array(img.pixels[:], dtype=np.float32).reshape(px, px, 4)
            bpy.data.images.remove(img)
            tiles.append(a)
    finally:
        (sc.camera, r.resolution_x, r.resolution_y, r.resolution_percentage, r.film_transparent, r.filepath,
         r.image_settings.file_format) = saved
        for o, v in hidden.items():
            o.hide_render = v
        bpy.data.objects.remove(cam)
    strip = np.concatenate(tiles, 1)
    o = bpy.data.images.new("shots_tmp", strip.shape[1], strip.shape[0], alpha=True)
    o.pixels[:] = strip.ravel()
    o.filepath_raw = os.path.join(SCR, out)
    o.file_format = "PNG"
    o.save()
    bpy.data.images.remove(o)
    return os.path.join(SCR, out)


def action_strip(name, frames, d, center, size, out, px=360):
    """Renders action `name` at `frames` from direction `d`, side by side."""
    rig = bpy.data.objects["RaccoonRig"]
    ad = rig.animation_data
    prev = ad.action
    sc = bpy.context.scene
    f0 = sc.frame_current
    act = bpy.data.actions[name]
    ad.action = act
    for t in ad.nla_tracks:
        t.mute = True
    tiles = []
    try:
        for f in frames:
            sc.frame_set(f)
            p = shots(center, [d], size, "_one.png", px=px)
            img = bpy.data.images.load(p, check_existing=False)
            a = np.array(img.pixels[:], dtype=np.float32).reshape(px, px, 4)
            bpy.data.images.remove(img)
            tiles.append(a)
    finally:
        ad.action = prev
        sc.frame_set(f0)
    strip = np.concatenate(tiles, 1)
    o = bpy.data.images.new("strip_tmp", strip.shape[1], strip.shape[0], alpha=True)
    o.pixels[:] = strip.ravel()
    o.filepath_raw = os.path.join(SCR, out)
    o.file_format = "PNG"
    o.save()
    bpy.data.images.remove(o)
    return os.path.join(SCR, out)
