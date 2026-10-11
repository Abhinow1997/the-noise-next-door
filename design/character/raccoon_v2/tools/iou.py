# Silhouette overlap between the rendered raccoon (through a camera) and the reference,
# whose green background is keyed out. Uses Workbench for speed.
import bpy, numpy as np, os
import tempfile
# Renders and comparison sheets go to a temp folder, not the repo.
SCR = os.path.join(tempfile.gettempdir(), "raccoon_v2")
os.makedirs(SCR, exist_ok=True)
_REF_MASKS = {}


def _px(path):
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    bpy.data.images.remove(img)
    return a


def ref_mask(path, n):
    key = (path, n)
    if key not in _REF_MASKS:
        a = _px(path)
        g = (a[:, :, 1] > a[:, :, 0] + 0.12) & (a[:, :, 1] > a[:, :, 2] + 0.08)
        m = ~g
        h, w = m.shape
        yi = (np.arange(n) * h / n).astype(int)
        xi = (np.arange(n) * w / n).astype(int)
        _REF_MASKS[key] = m[yi][:, xi]
    return _REF_MASKS[key]


def render_mask(cam_name, objects, n):
    sc = bpy.context.scene
    r = sc.render
    saved = (sc.camera, r.engine, r.resolution_x, r.resolution_y, r.resolution_percentage, r.film_transparent, r.filepath)
    hidden = {o: o.hide_render for o in sc.objects}
    try:
        sc.camera = bpy.data.objects[cam_name]
        r.engine = "BLENDER_WORKBENCH"
        r.resolution_x = r.resolution_y = n
        r.resolution_percentage = 100
        r.film_transparent = True
        for o in sc.objects:
            if o.type == "MESH":
                o.hide_render = o.name not in objects
        tmp = os.path.join(SCR, "_mask.png")
        r.filepath = tmp
        bpy.ops.render.render(write_still=True)
        a = _px(tmp)
    finally:
        sc.camera, r.engine, r.resolution_x, r.resolution_y, r.resolution_percentage, r.film_transparent, r.filepath = saved
        for o, v in hidden.items():
            o.hide_render = v
    return a[:, :, 3] > 0.5


def iou(cam_name, ref_path, objects, n=256, region=None):
    m = render_mask(cam_name, objects, n)
    rm = ref_mask(ref_path, n)
    if region is not None:
        x0, y0, x1, y1 = [int(v * n) for v in region]
        m, rm = m[y0:y1, x0:x1], rm[y0:y1, x0:x1]
    return (m & rm).sum() / max((m | rm).sum(), 1)
