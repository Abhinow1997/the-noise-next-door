# Renders every frame of an action from given views (side by side) into frames/ for a GIF.
import bpy, os, numpy as np
import tempfile
# Renders and comparison sheets go to a temp folder, not the repo.
SCR = os.path.join(tempfile.gettempdir(), "raccoon_v2")
os.makedirs(SCR, exist_ok=True)


def action_frames(name, views, center, size, folder, px=360):
    out = os.path.join(SCR, folder)
    os.makedirs(out, exist_ok=True)
    for f in os.listdir(out):
        os.remove(os.path.join(out, f))
    act = bpy.data.actions[name]
    n = int(act.frame_end - act.frame_start)
    for f in range(n):
        p = action_strip(name, [f], views[0], center, size, "_v0.png", px=px)
        tiles = []
        for i, d in enumerate(views):
            p = action_strip(name, [f], d, center, size, "_v%d.png" % i, px=px)
            img = bpy.data.images.load(p, check_existing=False)
            tiles.append(np.array(img.pixels[:], dtype=np.float32).reshape(px, px, 4))
            bpy.data.images.remove(img)
        strip = np.concatenate(tiles, 1)
        o = bpy.data.images.new("gif_tmp", strip.shape[1], strip.shape[0], alpha=True)
        o.pixels[:] = strip.ravel()
        o.filepath_raw = os.path.join(out, "f%03d.png" % f)
        o.file_format = "PNG"
        o.save()
        bpy.data.images.remove(o)
    return out, n
