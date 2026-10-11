import bpy, numpy as np, os
import tempfile
# Renders and comparison sheets go to a temp folder, not the repo.
SCR = os.path.join(tempfile.gettempdir(), "raccoon_v2")
os.makedirs(SCR, exist_ok=True)
# The reference poses, found from raccoon_v2.blend in assets/characters.
REF = os.path.normpath(bpy.path.abspath("//../../design/reference/raccoon"))


def crop(path, box, out, step=50, scale=1):
    """Crop an image (top-left pixel coords) with a grid: red every 100 px, yellow every 50."""
    img = bpy.data.images.load(path, check_existing=True)
    w, h = img.size
    a = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)[::-1]
    x0, y0, x1, y1 = box
    c = a[y0:y1, x0:x1].copy()
    if scale != 1:
        c = c.repeat(scale, 0).repeat(scale, 1)
    for gx in range((x0 // step + 1) * step, x1, step):
        c[:, (gx - x0) * scale] = [1, 0, 0, 1] if gx % 100 == 0 else [1, 1, 0, 1]
    for gy in range((y0 // step + 1) * step, y1, step):
        c[(gy - y0) * scale, :] = [1, 0, 0, 1] if gy % 100 == 0 else [1, 1, 0, 1]
    o = bpy.data.images.new("crop_tmp", c.shape[1], c.shape[0], alpha=True)
    o.pixels[:] = c[::-1].ravel()
    o.filepath_raw = os.path.join(SCR, out)
    o.file_format = "PNG"
    o.save()
    bpy.data.images.remove(o)
    return w, h
