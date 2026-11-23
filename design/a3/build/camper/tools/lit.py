# A lit EEVEE render through RefCam beside the reference crop; exec() in Blender with OUT and BOX defined.
# A temporary sun and grey world are added and removed again.
import bpy, os, numpy as np, math
from mathutils import Euler
REF = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\reference\red-beanie-man.jpg"
OUTD = os.path.join(os.environ["TEMP"], "raccoon_v2")
sc = bpy.context.scene; r = sc.render
saved = dict(engine=r.engine, rx=r.resolution_x, ry=r.resolution_y, pct=r.resolution_percentage, ft=r.film_transparent,
             fp=r.filepath, vt=sc.view_settings.view_transform, world=sc.world, cam=sc.camera)
for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
    try:
        r.engine = eng; break
    except TypeError:
        pass
w = bpy.data.worlds.new("_cmp_world"); w.use_nodes = True
bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs[0].default_value = (0.34, 0.34, 0.34, 1); bg.inputs[1].default_value = 1.0
sc.world = w
sun = bpy.data.objects.new("_cmp_sun", bpy.data.lights.new("_cmp_sun", "SUN")); sc.collection.objects.link(sun)
sun.data.energy = 3.2; sun.data.angle = math.radians(8)
sun.rotation_euler = Euler((math.radians(45), 0, math.radians(-20)), "XYZ")
try:
    sc.view_settings.view_transform = "Standard"
except TypeError as e:
    print(e)
sc.camera = bpy.data.objects[globals().get("CAM", "RefCam")]
img = bpy.data.images.load(REF, check_existing=True); W, H = img.size
SCALE = globals().get("SCALE", 0.5)
r.resolution_x, r.resolution_y, r.resolution_percentage = W, H, int(SCALE * 100)
r.film_transparent = False
r.filepath = os.path.join(OUTD, "_lit.png"); r.image_settings.file_format = "PNG"
try:
    bpy.ops.render.render(write_still=True)
    ren = bpy.data.images.load(r.filepath, check_existing=False)
    a = np.array(ren.pixels[:], np.float32).reshape(ren.size[1], ren.size[0], 4)[::-1]; bpy.data.images.remove(ren)
finally:
    bpy.data.objects.remove(sun); bpy.data.lights.remove(bpy.data.lights["_cmp_sun"])
    sc.world = saved["world"]; bpy.data.worlds.remove(w)
    r.resolution_x, r.resolution_y, r.resolution_percentage, r.film_transparent, r.filepath = saved["rx"], saved["ry"], saved["pct"], saved["ft"], saved["fp"]
    sc.view_settings.view_transform = saved["vt"]; sc.camera = saved["cam"]
ref = np.array(img.pixels[:], np.float32).reshape(H, W, 4)[::-1]
yi = (np.arange(H) * a.shape[0] / H).astype(int); xi = (np.arange(W) * a.shape[1] / W).astype(int); a = a[yi][:, xi]
x0, y0, x1, y1 = BOX
panel = np.concatenate([ref[y0:y1, x0:x1], a[y0:y1, x0:x1]], 1); panel[:, :, 3] = 1
o = bpy.data.images.new("_sbs", panel.shape[1], panel.shape[0], alpha=True); o.pixels[:] = panel[::-1].ravel()
o.filepath_raw = os.path.join(OUTD, OUT); o.file_format = "PNG"; o.save(); bpy.data.images.remove(o)
print(os.path.join(OUTD, OUT))
