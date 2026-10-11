# Renders `objects` through camera `cam_name` at the reference's resolution and writes
# <out>: reference crop | render crop | 50/50 overlay. Restores the scene afterwards.
import bpy, numpy as np, os
import tempfile
# Renders and comparison sheets go to a temp folder, not the repo.
SCR = os.path.join(tempfile.gettempdir(), "raccoon_v2")
os.makedirs(SCR, exist_ok=True)


def load_px(path):
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(img)
    return a


def compare(cam_name, ref_path, objects, box, out, scale=0.5):
    sc = bpy.context.scene
    r = sc.render
    saved = (sc.camera, r.resolution_x, r.resolution_y, r.resolution_percentage, r.film_transparent,
             r.filepath, r.image_settings.file_format)
    hidden = {o: o.hide_render for o in sc.objects}
    try:
        ref = load_px(ref_path)
        h, w = ref.shape[:2]
        sc.camera = bpy.data.objects[cam_name]
        r.resolution_x, r.resolution_y, r.resolution_percentage = w, h, int(scale * 100)
        r.film_transparent = True
        r.image_settings.file_format = "PNG"
        for o in sc.objects:
            if o.type in ("MESH", "CURVE"):
                o.hide_render = o.name not in objects
        tmp = os.path.join(SCR, "_render.png")
        r.filepath = tmp
        bpy.ops.render.render(write_still=True)
        ren = load_px(tmp)
    finally:
        (sc.camera, r.resolution_x, r.resolution_y, r.resolution_percentage, r.film_transparent,
         r.filepath, r.image_settings.file_format) = saved
        for o, v in hidden.items():
            o.hide_render = v
    # Bring the render to the reference's size (nearest neighbour).
    yi = (np.arange(h) * ren.shape[0] / h).astype(int)
    xi = (np.arange(w) * ren.shape[1] / w).astype(int)
    ren = ren[yi][:, xi]
    x0, y0, x1, y1 = box
    refc, renc = ref[y0:y1, x0:x1, :3], ren[y0:y1, x0:x1]
    alpha = renc[:, :, 3:4]
    bg = np.full_like(refc, 0.25)
    shown = renc[:, :, :3] * alpha + bg * (1 - alpha)
    over = refc * 0.5 + (renc[:, :, :3] * alpha + refc * (1 - alpha)) * 0.5
    panel = np.concatenate([refc, shown, over], 1)
    panel = np.concatenate([panel, np.ones(panel.shape[:2] + (1,), np.float32)], 2)
    o = bpy.data.images.new("cmp_tmp", panel.shape[1], panel.shape[0], alpha=True)
    o.pixels[:] = panel[::-1].ravel()
    o.filepath_raw = os.path.join(SCR, out)
    o.file_format = "PNG"
    o.save()
    bpy.data.images.remove(o)
    return os.path.join(SCR, out)
