# The camper, v2: every execute_blender_code body Claude Code ran in my Blender through the MCP, in order, on 14 Oct 2026
# (about 18:47-19:43), after I rejected v1: "I dont like the human model at all doesnt look anything like the refernece
# img it looks bocky and like a minecraft tree take the efernece of the raaccoon and recreate it to simialr style".
# v2 is built the way raccoon_v2 is (design/character/raccoon_v2/mesh.py): each part is lofted from rings, fused with a
# voxel remesh, relaxed, then decimated to big flat facets with X symmetry; flat-shaded, one flat colour per part.
# It's matched to design/reference/red-beanie-man.jpg by solving the reference's camera from landmarks
# (design/character/raccoon_v2/tools/solve.py) and overlaying the model on it, five times: the fit went from 25.4 px
# rms to 13.4 px (calls 1-26). Then, at my request at 19:25 ("yes turn the head like the reference"), calls 27-31 turn
# his head as the reference's is: 9 deg to his right, nodded 1.5 deg, tilted 2.7 deg, solved from the head's landmarks
# with the camera fitted to his body alone (head 6.9 px rms, body 12.0 px). They also bring the nose forward and set the
# pompom lower. After my look at that ("no chin no neck like in therefernece", 19:37), calls 32-39 give him the
# reference's jaw edge and chin, a neck of its own showing under it, the jacket closing lower round the neck, and the
# hood as one collar open in a V at the front. 22 parts, 4,472 triangles, 0.631 x 0.342 x 1.824 m (to the top of the
# pompom), facing -Y like the other assets. No rig or animation.
#
# v1 (the blocky one) is kept as design/a3/build/camper/camper_v1.blend with its record, build_camper_v1.py.
#
# Don't run this file directly: call 1 opens assets/characters/camper.blend and later calls save over it (call 2 also
# writes design/a3/build/camper/camper_v1.blend). To test that it rebuilds him, run a copy that opens and saves a copy.
# Changes from what ran: the scratchpad helpers it exec'd (persp.py, camper_fit.py, camper_lit.py) are now
# design/a3/build/camper/tools/ (persp.py, fit.py, lit.py), and the paths below point there. Call 9 failed at its last
# step (a colour missing from the palette); that step is commented out, and call 10 did it. A first call 27 was lost
# when the connection to Blender dropped; Blender came back with camper_v1.blend open and none of it applied, so it
# isn't here, and call 27 reopens camper.blend. (Call 27 asserts the open file is unchanged: true in my Blender after
# it came back, but not in a run of this file straight through, where the measuring calls before it change the camera.)
# A first try at call 32 stopped on its own file check (the beanie's file was open) before changing anything, so it
# isn't here either; call 32 reopens camper.blend, and call 33 is that try as it then ran.
# The "measuring only" calls change nothing in the model; their renders go to %TEMP%\raccoon_v2.

# --- Call 1 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 1: open camper.blend (the beanie file is saved), keep the blocky v1 as design/a3/build/camper/camper_v1.blend,
# then clear the objects so v2 starts clean in the same file.
import bpy, os
assert not bpy.data.is_dirty, bpy.data.filepath
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\characters\camper.blend")

# --- Call 2 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 2: the v1 copy, then an empty scene in camper.blend.
import bpy, os
assert bpy.data.filepath.endswith(r"assets\characters\camper.blend")
os.makedirs(r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper", exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\camper_v1.blend", copy=True)
n = len(bpy.data.objects)
for o in list(bpy.data.objects):
    me = o.data; bpy.data.objects.remove(o)
    if me and me.users == 0: bpy.data.meshes.remove(me)
print("v1 kept with", n, "parts; objects left:", len(bpy.data.objects), "| materials kept:", len(bpy.data.materials))

# --- Call 3 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 3: the toolkit, kept in the file as the text block "camper2_lib" (every later call runs it first).
import bpy
LIB = r'''
import bpy, bmesh, math
from mathutils import Vector, Matrix

def lin(h):
    c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)

def mat(name, hexc, rough=0.85):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    if m.node_tree is None:
        try: m.use_nodes = True
        except Exception: pass
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    s = {x.identifier: x for x in bsdf.inputs}
    s["Base Color"].default_value = (*lin(hexc), 1.0); s["Roughness"].default_value = rough
    m.diffuse_color = (*lin(hexc), 1.0); m.roughness = rough
    return m

# colours clustered from design/reference/red-beanie-man.jpg
COL = {"skin": ("C99C85", 0.6), "hair": ("3A2E26", 0.9), "beanie": ("AC453B", 0.9), "jacket": ("5A4A3B", 0.85),
       "jacket_dark": ("463A2F", 0.85), "pocket": ("62513F", 0.85), "hoodie": ("67696D", 0.9), "tshirt": ("D8D8D8", 0.9),
       "string": ("A9A9AD", 0.8), "jeans": ("33363B", 0.85), "boot": ("AF8758", 0.7), "sole": ("7A5C3C", 0.8)}
def M(key):
    h, r = COL[key]
    return mat("C2_" + key, h, r)

def hring(cx, cy, z, rx, ry, n=12, off=0.0):
    """A horizontal ring (an ellipse round a vertical axis)."""
    return [Vector((cx + rx * math.cos(off + 2 * math.pi * i / n), cy + ry * math.sin(off + 2 * math.pi * i / n), z)) for i in range(n)]

def loft(bm, rings, caps=True):
    vs = [[bm.verts.new(p) for p in r] for r in rings]
    n = len(vs[0])
    for a, b in zip(vs, vs[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((a[i], a[j], b[j], b[i]))
    if caps:
        bm.faces.new(vs[0]); bm.faces.new(list(reversed(vs[-1])))
    return vs

def path_tube(bm, pts, radii, n=10, ref=Vector((0, 0, 1))):
    """A tube along a polyline; radii = (rx, ry) per point; rings perpendicular to the path."""
    pts = [Vector(p) for p in pts]
    rings = []
    for k, p in enumerate(pts):
        t = (pts[min(k + 1, len(pts) - 1)] - pts[max(k - 1, 0)]).normalized()
        u = ref.cross(t)
        if u.length < 1e-6: u = Vector((1, 0, 0)).cross(t)
        u.normalize(); v = t.cross(u).normalized()
        rx, ry = radii[k]
        rings.append([p + u * (rx * math.cos(2 * math.pi * i / n)) + v * (ry * math.sin(2 * math.pi * i / n)) for i in range(n)])
    return loft(bm, rings)

def shell(name, build, mkey, faces, voxel=0.012, relax=4, sym=True, extra_mats=()):
    """Fuse the tubes from build(bm) into one surface (voxel remesh), relax it, then decimate to `faces` big flat facets,
    like raccoon_v2's body. Replaces any object of the same name."""
    old = bpy.data.objects.get(name)
    if old:
        me0 = old.data; bpy.data.objects.remove(old); bpy.data.meshes.remove(me0)
    bm = bmesh.new(); build(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name + "_src"); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    rem = ob.modifiers.new("Remesh", "REMESH"); rem.mode = "VOXEL"; rem.voxel_size = voxel; rem.adaptivity = 0.0
    if relax:
        sm = ob.modifiers.new("Relax", "LAPLACIANSMOOTH"); sm.iterations = relax; sm.lambda_factor = 1.0; sm.use_volume_preserve = True
    dg = bpy.context.evaluated_depsgraph_get()
    n_hi = len(ob.evaluated_get(dg).data.polygons)
    dec = ob.modifiers.new("Facets", "DECIMATE"); dec.decimate_type = "COLLAPSE"; dec.ratio = min(1.0, faces / max(n_hi, 1))
    dec.use_symmetry = sym; dec.symmetry_axis = "X"; dec.use_collapse_triangulate = True
    dg = bpy.context.evaluated_depsgraph_get()
    lo = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
    ob.modifiers.clear(); ob.data = lo; lo.name = name
    bpy.data.meshes.remove(me)
    lo.materials.append(M(mkey))
    for p in lo.polygons: p.use_smooth = False
    return ob

def plain(name, build, mkey):
    """A small detail kept as built (no remesh): pockets, lapels, strings."""
    old = bpy.data.objects.get(name)
    if old:
        me0 = old.data; bpy.data.objects.remove(old); bpy.data.meshes.remove(me0)
    bm = bmesh.new(); build(bm); bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(ob)
    me.materials.append(M(mkey))
    for p in me.polygons: p.use_smooth = False
    return ob

def slab(bm, centre, size, rot_z=0.0, rot_x=0.0):
    """A box (for pockets and flaps), turned about Z then X."""
    R = Matrix.Rotation(rot_z, 4, "Z") @ Matrix.Rotation(rot_x, 4, "X")
    bmesh.ops.create_cube(bm, size=1.0, matrix=Matrix.Translation(centre) @ R @ Matrix.Diagonal((*size, 1.0)))

def report(names):
    bpy.context.view_layer.update()
    for n in names:
        o = bpy.data.objects[n]
        ws = [o.matrix_world @ v.co for v in o.data.vertices]
        print(n, "| X %.3f..%.3f | Y %.3f..%.3f | Z %.3f..%.3f | faces %d | tris %d" % (
            min(p.x for p in ws), max(p.x for p in ws), min(p.y for p in ws), max(p.y for p in ws),
            min(p.z for p in ws), max(p.z for p in ws), len(o.data.polygons), sum(len(f.vertices) - 2 for f in o.data.polygons)))
'''
t = bpy.data.texts.get("camper2_lib") or bpy.data.texts.new("camper2_lib")
t.clear(); t.write(LIB)
old = bpy.data.texts.get("camper_helpers")
if old: bpy.data.texts.remove(old)
exec(LIB)
print("toolkit ready |", len(LIB), "chars | objects:", len(bpy.data.objects))

# --- Call 4 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 4: the jeans (hips and both legs fused, with rolled cuffs) and the boots, in the raccoon_v2 style.
import bpy
exec(bpy.data.texts["camper2_lib"].as_string())

def build_jeans(bm):
    loft(bm, [hring(0, 0.005, z, rx, ry, 16) for z, rx, ry in
              [(0.76, 0.15, 0.10), (0.82, 0.172, 0.112), (0.90, 0.178, 0.118), (0.97, 0.172, 0.114)]])
    for s in (1, -1):
        pts = [(s * 0.093, 0.0, 0.88), (s * 0.096, 0.0, 0.72), (s * 0.100, -0.008, 0.50), (s * 0.104, 0.0, 0.32),
               (s * 0.107, 0.008, 0.232), (s * 0.108, 0.008, 0.224), (s * 0.108, 0.008, 0.214), (s * 0.108, 0.008, 0.152),
               (s * 0.108, 0.008, 0.143), (s * 0.108, 0.008, 0.13)]
        radii = [(0.088, 0.095), (0.082, 0.088), (0.070, 0.075), (0.066, 0.070), (0.066, 0.068), (0.080, 0.082),
                 (0.084, 0.086), (0.084, 0.086), (0.077, 0.079), (0.050, 0.052)]
        path_tube(bm, pts, radii, n=12)

BOOT = [(0.012, -0.050, 0.055, 0.128), (0.03, -0.051, 0.060, 0.132), (0.058, -0.048, 0.061, 0.129),
        (0.085, -0.030, 0.060, 0.110), (0.110, -0.008, 0.058, 0.086), (0.135, 0.004, 0.057, 0.068), (0.165, 0.008, 0.056, 0.064)]
def build_boots(bm):
    for s in (1, -1):
        loft(bm, [hring(s * 0.108, 0.008 + cy, z, rx, ry, 14) for z, cy, rx, ry in BOOT])
def build_soles(bm):
    for s in (1, -1):
        loft(bm, [hring(s * 0.108, 0.008 - 0.050, z, 0.063, 0.136, 14) for z in (0.0, 0.024)])

shell("Camper_Jeans", build_jeans, "jeans", faces=320)
shell("Camper_Boots", build_boots, "boot", faces=170, voxel=0.009)
plain("Camper_Soles", build_soles, "sole")
report(["Camper_Jeans", "Camper_Boots", "Camper_Soles"])

# --- Call 5 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 5: the jacket (a boxy body, open down the front where the hoodie shows), the sleeves with folded
# cuffs (their own shell, so the arms keep a crease against the body, like the raccoon's legs), and the hands.
import bpy, math
from mathutils import Vector
exec(bpy.data.texts["camper2_lib"].as_string())

def sring(cx, cy, z, rx, ry, n=64, p=3.4, notch=None):
    """A boxy ring (superellipse), sampled evenly along its length starting at the front centre (-Y).
    notch = (half_width, depth) recesses the front between the jacket's two open edges."""
    raw = []
    for i in range(721):
        a = 1.5 * math.pi + 2 * math.pi * i / 720
        c, s = math.cos(a), math.sin(a)
        raw.append((rx * math.copysign(abs(c) ** (2 / p), c), ry * math.copysign(abs(s) ** (2 / p), s)))
    L = [0.0]
    for k in range(1, 721):
        L.append(L[-1] + math.hypot(raw[k][0] - raw[k - 1][0], raw[k][1] - raw[k - 1][1]))
    pts, k = [], 0
    for i in range(n):
        t = L[-1] * i / n
        while L[k + 1] < t: k += 1
        f = (t - L[k]) / max(L[k + 1] - L[k], 1e-9)
        x = raw[k][0] + f * (raw[k + 1][0] - raw[k][0]); y = raw[k][1] + f * (raw[k + 1][1] - raw[k][1])
        if notch and y < 0:
            w, d = notch
            y += d * max(0.0, min(1.0, (w - abs(x)) / 0.012))
        pts.append(Vector((cx + x, cy + y, z)))
    return pts

JACKET = [(0.755, 0.200, 0.138, (0.068, 0.030)), (0.80, 0.200, 0.138, (0.068, 0.030)), (1.00, 0.198, 0.137, (0.066, 0.030)),
          (1.20, 0.198, 0.137, (0.068, 0.030)), (1.30, 0.195, 0.132, (0.074, 0.028)), (1.35, 0.180, 0.122, (0.078, 0.024)),
          (1.39, 0.140, 0.105, (0.070, 0.018)), (1.415, 0.100, 0.085, None)]
def build_jacket(bm):
    loft(bm, [sring(0, 0.0, z, rx, ry, notch=nt) for z, rx, ry, nt in JACKET])

def arm_path(s):
    pts = [(s * 0.150, 0.0, 1.300), (s * 0.215, 0.0, 1.290), (s * 0.245, 0.005, 1.200), (s * 0.258, 0.010, 1.070),
           (s * 0.262, 0.000, 0.950), (s * 0.263, -0.005, 0.925), (s * 0.263, -0.006, 0.918), (s * 0.263, -0.008, 0.860),
           (s * 0.263, -0.008, 0.853)]
    radii = [(0.070, 0.075), (0.075, 0.078), (0.070, 0.072), (0.064, 0.066), (0.060, 0.062), (0.060, 0.062),
             (0.068, 0.070), (0.068, 0.070), (0.060, 0.062)]
    return pts, radii
def build_sleeves(bm):
    for s in (1, -1):
        pts, radii = arm_path(s)
        path_tube(bm, pts, radii, n=12)

# relaxed hands: flat palm facing the thigh, fingers curling in towards the leg, thumb forward
HAND = [(0.875, 0.000, 0.030, 0.034), (0.82, 0.002, 0.029, 0.040), (0.78, 0.004, 0.031, 0.047), (0.735, 0.006, 0.029, 0.046),
        (0.70, 0.012, 0.025, 0.040), (0.675, 0.018, 0.019, 0.030)]
def build_hands(bm):
    for s in (1, -1):
        rings = [hring(s * (0.263 - 0.006 * (0.875 - z) / 0.2), -0.008 + dy, z, rx, ry, 10) for z, dy, rx, ry in HAND]
        loft(bm, rings)
        path_tube(bm, [(s * 0.258, -0.035, 0.81), (s * 0.252, -0.052, 0.775), (s * 0.248, -0.058, 0.745)],
                  [(0.015, 0.015), (0.013, 0.013), (0.011, 0.011)], n=8)

shell("Camper_Jacket", build_jacket, "jacket", faces=320, voxel=0.010)
shell("Camper_Sleeves", build_sleeves, "jacket", faces=220, voxel=0.010)
shell("Camper_Hands", build_hands, "skin", faces=90, voxel=0.007, relax=3)
report(["Camper_Jacket", "Camper_Sleeves", "Camper_Hands"])

# --- Call 6 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 6: the hoodie (the front showing in the open jacket, and the hood bunched round his neck), the
# T-shirt and drawstrings, the head with its nose, the hair under the beanie, the beanie (folded cuff and crown) and
# the pompom.
import bpy, math
from mathutils import Vector
exec(bpy.data.texts["camper2_lib"].as_string())

def build_hoodie(bm):
    loft(bm, [hring(0, -0.088, z, rx, 0.030, 12) for z, rx in [(0.765, 0.074), (0.80, 0.076), (1.10, 0.076), (1.30, 0.078), (1.37, 0.072)]])

def build_hood(bm):
    pts, radii = [], []
    for k in range(15):                      # an open loop round the neck: from his left front, round the back, to his right front
        a = math.radians(-65 + 310 * k / 14)  # 0 = his left (+X), 90 = back (+Y); the gap is at the front (-90)
        b = (math.sin(a) + 1) / 2             # 0 at the front, 1 at the back
        pts.append((0.105 * math.cos(a), 0.012 + 0.098 * math.sin(a), 1.385 + 0.065 * b))
        r = 0.024 + 0.024 * b
        radii.append((r, r * 1.15))
    path_tube(bm, pts, radii, n=10)
    loft(bm, [hring(0, 0.125, z, rx, ry, 10) for z, rx, ry in [(1.31, 0.05, 0.025), (1.35, 0.10, 0.045), (1.41, 0.11, 0.05), (1.45, 0.08, 0.04)]])

def build_tshirt(bm):
    loft(bm, [hring(0, -0.066, z, rx, 0.018, 8) for z, rx in [(1.33, 0.03), (1.36, 0.045), (1.395, 0.05)]])

def build_strings(bm):
    for s in (1, -1):
        path_tube(bm, [(s * 0.028, -0.112, 1.372), (s * 0.032, -0.121, 1.30), (s * 0.034, -0.122, 1.205)],
                  [(0.0045, 0.0045)] * 3, n=5)
        path_tube(bm, [(s * 0.034, -0.122, 1.21), (s * 0.034, -0.122, 1.185)], [(0.007, 0.007)] * 2, n=6)  # the tips

HEAD = [(1.36, 0.010, 0.052, 0.052), (1.43, 0.012, 0.055, 0.056), (1.45, 0.000, 0.066, 0.075), (1.465, -0.008, 0.078, 0.088),
        (1.50, -0.006, 0.090, 0.100), (1.56, -0.002, 0.098, 0.108), (1.62, 0.002, 0.100, 0.110), (1.68, 0.006, 0.096, 0.106),
        (1.73, 0.008, 0.080, 0.090), (1.765, 0.008, 0.045, 0.050)]
def build_head(bm):
    loft(bm, [hring(0, cy, z, rx, ry, 14) for z, cy, rx, ry in HEAD])
    path_tube(bm, [(0, -0.096, 1.578), (0, -0.118, 1.548), (0, -0.128, 1.532)], [(0.017, 0.014), (0.014, 0.012), (0.007, 0.006)],
              n=6, ref=Vector((1, 0, 0)))

def build_hair(bm):
    loft(bm, [hring(0, 0.030, z, rx, ry, 14) for z, rx, ry in [(1.505, 0.055, 0.055), (1.53, 0.097, 0.094), (1.58, 0.106, 0.104),
                                                              (1.64, 0.104, 0.100), (1.70, 0.090, 0.088)]])

def build_cuff(bm):
    loft(bm, [hring(0, 0.008, z, r, r, 14) for z, r in [(1.605, 0.120), (1.611, 0.131), (1.645, 0.136), (1.685, 0.136), (1.72, 0.130), (1.726, 0.118)]])
def build_crown(bm):
    loft(bm, [hring(0, 0.008, z, r, r, 14) for z, r in [(1.70, 0.120), (1.735, 0.122), (1.76, 0.117), (1.783, 0.102), (1.796, 0.068), (1.80, 0.025)]])
def build_pompom(bm):
    loft(bm, [hring(0, 0.008, 1.81 + 0.04 * math.sin(t), 0.04 * math.cos(t) + 0.002, 0.04 * math.cos(t) + 0.002, 10)
              for t in [math.radians(a) for a in (-80, -50, -20, 10, 40, 70)]])

shell("Camper_Hoodie", build_hoodie, "hoodie", faces=70, voxel=0.009, relax=2)
shell("Camper_Hood", build_hood, "hoodie", faces=150, voxel=0.009)
shell("Camper_TShirt", build_tshirt, "tshirt", faces=16, voxel=0.008, relax=2)
plain("Camper_Strings", build_strings, "string")
shell("Camper_Head", build_head, "skin", faces=150, voxel=0.008, relax=3)
shell("Camper_Hair", build_hair, "hair", faces=60, voxel=0.009)
shell("Camper_BeanieCuff", build_cuff, "beanie", faces=70, voxel=0.009, relax=2)
shell("Camper_BeanieCrown", build_crown, "beanie", faces=60, voxel=0.009, relax=2)
shell("Camper_Pompom", build_pompom, "beanie", faces=28, voxel=0.008, relax=1)
report(["Camper_Hoodie", "Camper_Hood", "Camper_TShirt", "Camper_Strings", "Camper_Head", "Camper_Hair",
        "Camper_BeanieCuff", "Camper_BeanieCrown", "Camper_Pompom"])

# --- Call 7 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 7: the jacket's details, wrapped onto its faceted front so they sit on it: the pointed collar on the
# chest, the two chest pockets with flaps, the two lower pockets and the buttons down his right front.
import bpy, bmesh, math
from mathutils import Vector
exec(bpy.data.texts["camper2_lib"].as_string())
mat("C2_button", "2E2621", 0.6); COL["button"] = ("2E2621", 0.6)
jk = bpy.data.objects["Camper_Jacket"]

def hit(x, z):
    ok, loc, nor, idx = jk.ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)))
    return loc if ok else None

def patch(bm, corners, thick, nx=4, nz=3):
    """A thin piece laid on the jacket front: corners (x, z) as BL, BR, TR, TL, sampled on a grid and pushed out of
    the surface by `thick` along -Y, its back 3 mm inside."""
    (x0, z0), (x1, z1), (x2, z2), (x3, z3) = corners
    front, back = [], []
    for j in range(nz + 1):
        v = j / nz
        rf, rb = [], []
        for i in range(nx + 1):
            u = i / nx
            x = (1 - v) * ((1 - u) * x0 + u * x1) + v * ((1 - u) * x3 + u * x2)
            z = (1 - v) * ((1 - u) * z0 + u * z1) + v * ((1 - u) * z3 + u * z2)
            p = hit(x, z)
            rf.append(bm.verts.new(p + Vector((0, -thick, 0)))); rb.append(bm.verts.new(p + Vector((0, 0.003, 0))))
        front.append(rf); back.append(rb)
    for j in range(nz):
        for i in range(nx):
            bm.faces.new((front[j][i], front[j][i + 1], front[j + 1][i + 1], front[j + 1][i]))
            bm.faces.new((back[j][i], back[j + 1][i], back[j + 1][i + 1], back[j][i + 1]))
    ring_f = [front[0][i] for i in range(nx + 1)] + [front[j][nx] for j in range(1, nz + 1)] + \
             [front[nz][i] for i in range(nx - 1, -1, -1)] + [front[j][0] for j in range(nz - 1, 0, -1)]
    ring_b = [back[0][i] for i in range(nx + 1)] + [back[j][nx] for j in range(1, nz + 1)] + \
             [back[nz][i] for i in range(nx - 1, -1, -1)] + [back[j][0] for j in range(nz - 1, 0, -1)]
    for k in range(len(ring_f)):
        m = (k + 1) % len(ring_f)
        bm.faces.new((ring_f[k], ring_b[k], ring_b[m], ring_f[m]))

def build_collar(bm):
    for s in (1, -1):   # his pointed shirt-style collar lying on the chest beside the opening
        c = [(s * 0.075, 1.262), (s * 0.090, 1.250), (s * 0.150, 1.352), (s * 0.085, 1.392)]
        if s < 0: c = [c[1], c[0], c[3], c[2]]
        patch(bm, c, 0.010, 3, 4)

def build_pockets(bm):
    for s in (1, -1):
        a, b = sorted((s * 0.085, s * 0.165))
        patch(bm, [(a, 1.150), (b, 1.150), (b, 1.232), (a, 1.232)], 0.005)          # chest pockets
        patch(bm, [(a + 0.002, 0.795), (b - 0.002, 0.795), (b - 0.002, 0.935), (a + 0.002, 0.935)], 0.005)   # lower pockets
def build_flaps(bm):
    for s in (1, -1):
        a, b = sorted((s * 0.081, s * 0.169))
        patch(bm, [(a, 1.205), (b, 1.205), (b, 1.248), (a, 1.248)], 0.011, 3, 2)   # the chest flaps, standing proud
        a, b = sorted((s * 0.083, s * 0.167))
        patch(bm, [(a, 0.912), (b, 0.912), (b, 0.940), (a, 0.940)], 0.009, 3, 1)   # the lower flaps

def build_buttons(bm):
    for z in (0.80, 0.97, 1.13):
        p = hit(-0.084, z) + Vector((0, -0.004, 0))
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.008, matrix=__import__("mathutils").Matrix.Translation(p))
    for s in (1, -1):
        p = hit(s * 0.125, 1.217) + Vector((0, -0.012, 0))
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.0065, matrix=__import__("mathutils").Matrix.Translation(p))

plain("Camper_Collar", build_collar, "jacket_dark")
plain("Camper_Pockets", build_pockets, "pocket")
plain("Camper_Flaps", build_flaps, "jacket")
plain("Camper_Buttons", build_buttons, "button")
report(["Camper_Collar", "Camper_Pockets", "Camper_Flaps", "Camper_Buttons"])
tot = sum(sum(len(f.vertices) - 2 for f in o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
print("objects", len([o for o in bpy.data.objects if o.type == "MESH"]), "| total triangles", tot)

# --- Measuring only, after call 7: cut grid crops of the reference (head, torso, legs) to read its landmarks off ----
import bpy, os
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
ns = {}
exec(open(os.path.join(T, "crop.py"), encoding="utf-8").read(), ns)
REF = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\reference\red-beanie-man.jpg"
print(ns["crop"](REF, (1000, 230, 1300, 620), "camper_head.png", step=25, scale=2))
print(ns["crop"](REF, (900, 560, 1400, 1200), "camper_torso.png", step=50))
print(ns["crop"](REF, (920, 1150, 1300, 1660), "camper_legs.png", step=50))
print(ns["SCR"])

# --- Call 8 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 8: solve the reference's camera from landmarks (scaled orthographic, as for raccoon_v2).
import bpy, os, numpy as np
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
REF = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\reference\red-beanie-man.jpg"
ns = {}
for f in ("solve.py", "facecam.py"):
    exec(open(os.path.join(T, f), encoding="utf-8").read(), ns)
L3 = {"pompom": (0, 0.008, 1.81), "nose": (0, -0.128, 1.532), "chin": (0, -0.09, 1.462), "cuff_bot": (0, -0.123, 1.611),
      "fold": (0, -0.122, 1.724), "flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226),
      "pockR_bot": (-0.125, -0.143, 1.15), "pockL_bot": (0.125, -0.143, 1.15), "lowL_top": (0.125, -0.143, 0.935),
      "hemR_in": (-0.068, -0.138, 0.755), "hemL_in": (0.068, -0.138, 0.755), "slvR": (-0.263, -0.008, 0.853),
      "slvL": (0.263, -0.008, 0.853), "jcR": (-0.108, -0.078, 0.183), "jcL": (0.108, -0.078, 0.183),
      "toeR": (-0.108, -0.174, 0.03), "toeL": (0.108, -0.174, 0.03), "tee": (0, -0.084, 1.36)}
L2 = {"pompom": (1165, 280), "nose": (1074, 485), "chin": (1117, 550), "cuff_bot": (1087, 411), "fold": (1087, 359),
      "flapR": (1015, 705), "flapL": (1177, 725), "pockR_bot": (1015, 775), "pockL_bot": (1177, 793), "lowL_top": (1190, 900),
      "hemR_in": (1060, 1045), "hemL_in": (1112, 1060), "slvR": (955, 978), "slvL": (1320, 1025), "jcR": (1068, 1453),
      "jcL": (1223, 1485), "toeR": (970, 1560), "toeL": (1160, 1615), "tee": (1105, 588)}
cam, err = ns["solved_cam"]("RefCam", REF, L3, L2)
X = np.array([L3[k] for k in L2]); U = np.array([L2[k] for k in L2], float)
p, res = ns["solve_cam"](X, U)
R = ns["rodrigues"](p[:3]); s = np.exp(p[3])
view = R[2]   # the camera's viewing axis in world coordinates (sign either way)
print("scale px/m %.1f" % s)
d = -view if view[1] < 0 else view
d = R[2] if np.dot(R[2], [0.5, -0.8, 0.3]) > 0 else -R[2]
yaw = np.degrees(np.arctan2(d[0], -d[1])); elev = np.degrees(np.arcsin(d[2]))
print("towards the eye:", d.round(3), "| yaw from front %.1f deg (towards his left) | elevation %.1f deg" % (yaw, elev))
for k, e in err.items(): print("  %-10s %5.1f px" % (k, e))
print("rms %.1f px" % np.sqrt((np.linalg.norm(res, axis=1) ** 2).mean()))
bpy.context.scene.camera = cam

# --- Measuring only, after call 8: the first comparison render (reference | model | overlay) ------------------------
import bpy, os, numpy as np
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
REF = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\reference\red-beanie-man.jpg"
ns = {}
exec(open(os.path.join(T, "compare.py"), encoding="utf-8").read(), ns)
sc = bpy.context.scene
try: sc.render.engine = "BLENDER_WORKBENCH"
except TypeError as e: print(e)
sh = sc.display.shading
sh.light = "STUDIO"; sh.color_type = "MATERIAL"
objs = [o.name for o in bpy.data.objects if o.type == "MESH"]
print(ns["compare"]("RefCam", REF, objs, (880, 200, 1440, 1680), "camper_v2_cmp1.png", scale=0.5))

# --- Measuring only, after call 8: a perspective solve (85 mm from 7 m: no closer than orthographic, so that's kept) ----
import bpy, os, numpy as np
from mathutils import Matrix
SP = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
ps = {}; exec(open(os.path.join(SP, "persp.py"), encoding="utf-8").read(), ps)
L3 = {"pompom": (0, 0.008, 1.81), "nose": (0, -0.128, 1.532), "chin": (0, -0.09, 1.462), "cuff_bot": (0, -0.123, 1.611),
      "fold": (0, -0.122, 1.724), "flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226),
      "pockR_bot": (-0.125, -0.143, 1.15), "pockL_bot": (0.125, -0.143, 1.15), "lowL_top": (0.125, -0.143, 0.935),
      "hemR_in": (-0.068, -0.138, 0.755), "hemL_in": (0.068, -0.138, 0.755), "slvR": (-0.263, -0.008, 0.853),
      "slvL": (0.263, -0.008, 0.853), "jcR": (-0.108, -0.078, 0.183), "jcL": (0.108, -0.078, 0.183),
      "toeR": (-0.108, -0.174, 0.03), "toeL": (0.108, -0.174, 0.03), "tee": (0, -0.084, 1.36)}
L2 = {"pompom": (1165, 280), "nose": (1074, 485), "chin": (1117, 550), "cuff_bot": (1087, 411), "fold": (1087, 359),
      "flapR": (1015, 705), "flapL": (1177, 725), "pockR_bot": (1015, 775), "pockL_bot": (1177, 793), "lowL_top": (1190, 900),
      "hemR_in": (1060, 1045), "hemL_in": (1112, 1060), "slvR": (955, 978), "slvL": (1320, 1025), "jcR": (1068, 1453),
      "jcL": (1223, 1485), "toeR": (970, 1560), "toeL": (1160, 1615), "tee": (1105, 588)}
keys = list(L2)
X = np.array([L3[k] for k in keys], float); U = np.array([L2[k] for k in keys], float)
for dist in (2.5, 4.0, 7.0):
    p, res = ps["solve_persp"](X, U, 2218, 1888, [0.483, -0.861, 0.157], (0, 0, 0.9), dist=dist, f0=741 * dist)
    R = ps["rod"](p[:3]); c = p[3:6]; f = np.exp(p[6])
    d = c - np.array([0, 0, 0.9]); D = np.linalg.norm(d); d /= D
    print("start %.1f m -> camera at %s, %.2f m away, focal %.0f px (%.0f mm on 36), yaw %.1f, elev %.1f, rms %.1f px" % (
        dist, c.round(2), D, f, f * 36 / 2218, np.degrees(np.arctan2(d[0], -d[1])), np.degrees(np.arcsin(d[2])),
        np.sqrt((np.linalg.norm(res, axis=1) ** 2).mean())))
best = p
print({k: tuple(np.round(r, 0)) for k, r in zip(keys, res)})

# --- Call 9 ---------------------------------------------------------------------------------------------------------
# Camper v2, call 9: the first fit to the reference (call 8) put the model 25 px rms off. Fixes from it:
# a longer face (chin lower, cuff higher), a shorter beanie cuff and crown tipped back, the T-shirt higher, a
# narrower jacket opening, taller lower pockets, four buttons where the reference has them, longer sleeves closer to
# the body, wider ankles and boots turned out a little. Rebuilds the parts that changed.
import bpy, math
from mathutils import Vector, Matrix
exec(bpy.data.texts["camper2_lib"].as_string())
exec(bpy.data.texts["camper2_parts"].as_string()) if "camper2_parts" in bpy.data.texts else None

PARTS = r'''
import math
from mathutils import Vector, Matrix

def sring(cx, cy, z, rx, ry, n=64, p=3.4, notch=None):
    raw = []
    for i in range(721):
        a = 1.5 * math.pi + 2 * math.pi * i / 720
        c, s = math.cos(a), math.sin(a)
        raw.append((rx * math.copysign(abs(c) ** (2 / p), c), ry * math.copysign(abs(s) ** (2 / p), s)))
    L = [0.0]
    for k in range(1, 721):
        L.append(L[-1] + math.hypot(raw[k][0] - raw[k - 1][0], raw[k][1] - raw[k - 1][1]))
    pts, k = [], 0
    for i in range(n):
        t = L[-1] * i / n
        while L[k + 1] < t: k += 1
        f = (t - L[k]) / max(L[k + 1] - L[k], 1e-9)
        x = raw[k][0] + f * (raw[k + 1][0] - raw[k][0]); y = raw[k][1] + f * (raw[k + 1][1] - raw[k][1])
        if notch and y < 0:
            w, d = notch
            y += d * max(0.0, min(1.0, (w - abs(x)) / 0.012))
        pts.append(Vector((cx + x, cy + y, z)))
    return pts

def opening(z):            # half-width of the jacket's open front: 4.2 cm at the hem, 6 cm at the collar
    return 0.042 + 0.018 * max(0.0, min(1.0, (z - 0.77) / (1.30 - 0.77)))

P = dict(hem=0.77, ankle_x=0.115, toe_out=math.radians(12), arm_x=0.245, slv_bot=0.825, hand_tip=0.645,
         cuff_bot=1.625, cuff_top=1.695, crown_top=1.778, beanie_tilt=math.radians(8), pom_r=0.04)
'''
t = bpy.data.texts.get("camper2_parts") or bpy.data.texts.new("camper2_parts"); t.clear(); t.write(PARTS)
exec(PARTS)

# --- jeans and boots ---------------------------------------------------------------------------------------------
def build_jeans(bm):
    loft(bm, [hring(0, 0.005, z, rx, ry, 16) for z, rx, ry in
              [(0.76, 0.15, 0.10), (0.82, 0.172, 0.112), (0.90, 0.178, 0.112), (0.97, 0.172, 0.108)]])
    ax = P["ankle_x"]
    for s in (1, -1):
        xs = lambda z: s * (0.088 + (ax - 0.088) * (0.88 - z) / (0.88 - 0.13))
        zs = [0.88, 0.72, 0.50, 0.32, 0.232, 0.224, 0.214, 0.152, 0.143, 0.13]
        ys = [0.0, 0.0, -0.008, 0.0, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008]
        radii = [(0.088, 0.095), (0.082, 0.088), (0.072, 0.076), (0.069, 0.072), (0.068, 0.070), (0.080, 0.082),
                 (0.084, 0.086), (0.084, 0.086), (0.077, 0.079), (0.050, 0.052)]
        path_tube(bm, [(xs(z), y, z) for z, y in zip(zs, ys)], radii, n=12)

BOOT = [(0.012, -0.050, 0.055, 0.128), (0.03, -0.051, 0.060, 0.132), (0.058, -0.048, 0.061, 0.129),
        (0.085, -0.030, 0.060, 0.110), (0.110, -0.008, 0.058, 0.086), (0.135, 0.004, 0.057, 0.068), (0.165, 0.008, 0.056, 0.064)]
def foot_ring(s, z, cy, rx, ry, n=14):
    """A boot ring round the ankle axis, turned out by toe_out (his right boot to his right, his left to his left)."""
    R = Matrix.Rotation(-s * P["toe_out"], 3, "Z")
    base = Vector((s * P["ankle_x"], 0.008, 0))
    return [base + R @ (p - base) for p in hring(s * P["ankle_x"], 0.008 + cy, z, rx, ry, n)]
def build_boots(bm):
    for s in (1, -1):
        loft(bm, [foot_ring(s, z, cy, rx, ry) for z, cy, rx, ry in BOOT])
def build_soles(bm):
    for s in (1, -1):
        loft(bm, [foot_ring(s, z, -0.050, 0.063, 0.136) for z in (0.0, 0.024)])

# --- jacket, sleeves, hands --------------------------------------------------------------------------------------
def build_jacket(bm):
    rings = [(P["hem"], 0.200, 0.138), (0.82, 0.200, 0.138), (1.00, 0.198, 0.137), (1.20, 0.198, 0.137), (1.30, 0.195, 0.132),
             (1.35, 0.180, 0.122), (1.39, 0.140, 0.105)]
    loft(bm, [sring(0, 0.0, z, rx, ry, notch=(opening(z), 0.030 if z < 1.32 else 0.022)) for z, rx, ry in rings] +
             [sring(0, 0.0, 1.415, 0.100, 0.085)])

def build_sleeves(bm):
    ax, sb = P["arm_x"], P["slv_bot"]
    for s in (1, -1):
        pts = [(s * 0.150, 0.0, 1.300), (s * 0.205, 0.0, 1.290), (s * (ax - 0.012), 0.005, 1.200), (s * (ax - 0.004), 0.010, 1.070),
               (s * ax, 0.000, sb + 0.10), (s * ax, -0.005, sb + 0.067), (s * ax, -0.006, sb + 0.060), (s * ax, -0.008, sb + 0.006),
               (s * ax, -0.008, sb)]
        radii = [(0.072, 0.077), (0.077, 0.080), (0.073, 0.075), (0.067, 0.069), (0.063, 0.065), (0.063, 0.065),
                 (0.071, 0.073), (0.071, 0.073), (0.063, 0.065)]
        path_tube(bm, pts, radii, n=12)

def build_hands(bm):
    top, tip = P["slv_bot"] + 0.02, P["hand_tip"]
    L = top - tip
    prof = [(0.0, 0.000, 0.030, 0.034), (0.27, 0.002, 0.029, 0.040), (0.47, 0.004, 0.031, 0.047), (0.70, 0.006, 0.029, 0.046),
            (0.88, 0.012, 0.025, 0.040), (1.0, 0.018, 0.019, 0.030)]
    for s in (1, -1):
        ax = P["arm_x"]
        rings = [hring(s * (ax - 0.008 * f), -0.008 + dy, top - f * L, rx, ry, 10) for f, dy, rx, ry in prof]
        loft(bm, rings)
        path_tube(bm, [(s * (ax - 0.005), -0.035, top - 0.32 * L), (s * (ax - 0.011), -0.052, top - 0.5 * L),
                       (s * (ax - 0.015), -0.058, top - 0.65 * L)], [(0.015, 0.015), (0.013, 0.013), (0.011, 0.011)], n=8)

# --- hoodie, hood, T-shirt, strings ------------------------------------------------------------------------------
def build_hoodie(bm):
    loft(bm, [hring(0, -0.088, z, rx, 0.030, 12) for z, rx in [(P["hem"] + 0.012, 0.060), (0.82, 0.062), (1.10, 0.068), (1.30, 0.076), (1.37, 0.072)]])
def build_hood(bm):
    pts, radii = [], []
    for k in range(15):
        a = math.radians(-65 + 310 * k / 14)
        b = (math.sin(a) + 1) / 2
        pts.append((0.105 * math.cos(a), 0.012 + 0.098 * math.sin(a), 1.40 + 0.055 * b))
        r = 0.024 + 0.024 * b
        radii.append((r, r * 1.15))
    path_tube(bm, pts, radii, n=10)
    loft(bm, [hring(0, 0.125, z, rx, ry, 10) for z, rx, ry in [(1.31, 0.05, 0.025), (1.35, 0.10, 0.045), (1.41, 0.11, 0.05), (1.45, 0.08, 0.04)]])
def build_tshirt(bm):
    loft(bm, [hring(0, -0.066, z, rx, 0.018, 8) for z, rx in [(1.35, 0.03), (1.385, 0.045), (1.425, 0.05)]])
def build_strings(bm):
    for s in (1, -1):
        path_tube(bm, [(s * 0.028, -0.112, 1.39), (s * 0.032, -0.121, 1.31), (s * 0.034, -0.122, 1.205)], [(0.0045, 0.0045)] * 3, n=5)
        path_tube(bm, [(s * 0.034, -0.122, 1.21), (s * 0.034, -0.122, 1.185)], [(0.007, 0.007)] * 2, n=6)

# --- head, hair, beanie ------------------------------------------------------------------------------------------
HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.012, 0.055, 0.056), (1.425, 0.000, 0.066, 0.075), (1.44, -0.008, 0.078, 0.088),
        (1.48, -0.006, 0.090, 0.100), (1.55, -0.002, 0.098, 0.108), (1.62, 0.002, 0.100, 0.110), (1.68, 0.006, 0.096, 0.106),
        (1.73, 0.008, 0.080, 0.090), (1.76, 0.008, 0.045, 0.050)]
def build_head(bm):
    loft(bm, [hring(0, cy, z, rx, ry, 14) for z, cy, rx, ry in HEAD])
    path_tube(bm, [(0, -0.098, 1.575), (0, -0.118, 1.54), (0, -0.128, 1.523)], [(0.017, 0.014), (0.014, 0.012), (0.007, 0.006)],
              n=6, ref=Vector((1, 0, 0)))
def build_hair(bm):
    # a short band under the cuff at the sides and back, ending in sideburns in front of the ears
    loft(bm, [hring(0, 0.028, z, rx, ry, 14) for z, rx, ry in [(1.555, 0.080, 0.080), (1.575, 0.101, 0.101), (1.64, 0.104, 0.100), (1.68, 0.095, 0.092)]])

def tilt_back(bm):   # the beanie sits tipped back, pivoting on the front of its cuff
    pivot = Vector((0, -0.13, P["cuff_bot"]))
    M = Matrix.Translation(pivot) @ Matrix.Rotation(-P["beanie_tilt"], 4, "X") @ Matrix.Translation(-pivot)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts[:])
import bmesh
def build_cuff(bm):
    b, t = P["cuff_bot"], P["cuff_top"]; h = t - b
    loft(bm, [hring(0, 0.008, b + f * h, r, r, 14) for f, r in [(0, 0.120), (0.06, 0.131), (0.35, 0.136), (0.72, 0.136), (0.96, 0.130), (1.0, 0.118)]])
    tilt_back(bm)
def build_crown(bm):
    t, c = P["cuff_top"], P["crown_top"]; h = c - t
    loft(bm, [hring(0, 0.008, t - 0.012 + f * (h + 0.012), r, r, 14) for f, r in [(0, 0.120), (0.3, 0.123), (0.6, 0.118), (0.82, 0.104), (0.95, 0.072), (1.0, 0.03)]])
    tilt_back(bm)
def build_pompom(bm):
    r = P["pom_r"]; zc = P["crown_top"] + r * 0.8
    loft(bm, [hring(0, 0.008, zc + r * math.sin(a), r * math.cos(a) + 0.002, r * math.cos(a) + 0.002, 10)
              for a in [math.radians(d) for d in (-80, -50, -20, 10, 40, 70)]])
    tilt_back(bm)

for nm, fn, mk, fc, vx, rl in [("Camper_Jeans", build_jeans, "jeans", 320, 0.012, 4), ("Camper_Boots", build_boots, "boot", 170, 0.009, 4),
                               ("Camper_Jacket", build_jacket, "jacket", 320, 0.010, 4), ("Camper_Sleeves", build_sleeves, "jacket", 220, 0.010, 4),
                               ("Camper_Hands", build_hands, "skin", 90, 0.007, 3), ("Camper_Hoodie", build_hoodie, "hoodie", 70, 0.009, 2),
                               ("Camper_Hood", build_hood, "hoodie", 150, 0.009, 4), ("Camper_TShirt", build_tshirt, "tshirt", 16, 0.008, 2),
                               ("Camper_Head", build_head, "skin", 150, 0.008, 3), ("Camper_Hair", build_hair, "hair", 50, 0.008, 3),
                               ("Camper_BeanieCuff", build_cuff, "beanie", 70, 0.009, 2), ("Camper_BeanieCrown", build_crown, "beanie", 60, 0.009, 2),
                               ("Camper_Pompom", build_pompom, "beanie", 28, 0.008, 1)]:
    shell(nm, fn, mk, faces=fc, voxel=vx, relax=rl)
plain("Camper_Soles", build_soles, "sole")
plain("Camper_Strings", build_strings, "string")

# --- the jacket's details, wrapped onto the rebuilt jacket ---------------------------------------------------------
jk = bpy.data.objects["Camper_Jacket"]
def hit(x, z):
    ok, loc, nor, idx = jk.ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)))
    return loc
def patch(bm, corners, thick, nx=4, nz=3):
    (x0, z0), (x1, z1), (x2, z2), (x3, z3) = corners
    front, back = [], []
    for j in range(nz + 1):
        v = j / nz
        rf, rb = [], []
        for i in range(nx + 1):
            u = i / nx
            x = (1 - v) * ((1 - u) * x0 + u * x1) + v * ((1 - u) * x3 + u * x2)
            z = (1 - v) * ((1 - u) * z0 + u * z1) + v * ((1 - u) * z3 + u * z2)
            p = hit(x, z)
            rf.append(bm.verts.new(p + Vector((0, -thick, 0)))); rb.append(bm.verts.new(p + Vector((0, 0.003, 0))))
        front.append(rf); back.append(rb)
    for j in range(nz):
        for i in range(nx):
            bm.faces.new((front[j][i], front[j][i + 1], front[j + 1][i + 1], front[j + 1][i]))
            bm.faces.new((back[j][i], back[j + 1][i], back[j + 1][i + 1], back[j][i + 1]))
    rf_ = [front[0][i] for i in range(nx + 1)] + [front[j][nx] for j in range(1, nz + 1)] + [front[nz][i] for i in range(nx - 1, -1, -1)] + [front[j][0] for j in range(nz - 1, 0, -1)]
    rb_ = [back[0][i] for i in range(nx + 1)] + [back[j][nx] for j in range(1, nz + 1)] + [back[nz][i] for i in range(nx - 1, -1, -1)] + [back[j][0] for j in range(nz - 1, 0, -1)]
    for k in range(len(rf_)):
        m = (k + 1) % len(rf_)
        bm.faces.new((rf_[k], rb_[k], rb_[m], rf_[m]))
def quad(s, a, b, z0, z1):
    lo, hi = sorted((s * a, s * b))
    return [(lo, z0), (hi, z0), (hi, z1), (lo, z1)]
def build_collar(bm):
    for s in (1, -1):
        w = opening(1.30)
        c = [(s * (w + 0.008), 1.262), (s * (w + 0.022), 1.250), (s * 0.150, 1.352), (s * (w + 0.02), 1.392)]
        if s < 0: c = [c[1], c[0], c[3], c[2]]
        patch(bm, c, 0.010, 3, 4)
def build_pockets(bm):
    for s in (1, -1):
        patch(bm, quad(s, 0.085, 0.165, 1.150, 1.232), 0.005)
        patch(bm, quad(s, 0.083, 0.176, 0.800, 0.975), 0.005, 4, 4)
def build_flaps(bm):
    for s in (1, -1):
        patch(bm, quad(s, 0.081, 0.169, 1.205, 1.248), 0.011, 3, 2)
        patch(bm, quad(s, 0.081, 0.178, 0.950, 0.978), 0.009, 3, 1)
def build_buttons(bm):
    for z in (0.784, 0.884, 1.016, 1.136):
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.008, matrix=Matrix.Translation(hit(-(opening(z) + 0.016), z) + Vector((0, -0.004, 0))))
    for s in (1, -1):
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.0065, matrix=Matrix.Translation(hit(s * 0.125, 1.217) + Vector((0, -0.012, 0))))
plain("Camper_Collar", build_collar, "jacket_dark")
plain("Camper_Pockets", build_pockets, "pocket")
plain("Camper_Flaps", build_flaps, "jacket")
# Call 9 stopped here with KeyError: 'button' (call 10 adds the colour and makes the buttons):
# plain("Camper_Buttons", build_buttons, "button")
# names = sorted(o.name for o in bpy.data.objects if o.type == "MESH")
# report(names)
# print("total triangles", sum(sum(len(f.vertices) - 2 for f in bpy.data.objects[n].data.polygons) for n in names))

# --- Call 10 --------------------------------------------------------------------------------------------------------
# Camper v2, call 10: add the button colour to the toolkit's palette (call 7 had only set it locally), then the buttons.
import bpy, bmesh
from mathutils import Vector, Matrix
t = bpy.data.texts["camper2_lib"]
s = t.as_string()
if '"button"' not in s:
    s = s.replace('"sole": ("7A5C3C", 0.8)}', '"sole": ("7A5C3C", 0.8), "button": ("2E2621", 0.6)}')
    t.clear(); t.write(s)
exec(s); exec(bpy.data.texts["camper2_parts"].as_string())
jk = bpy.data.objects["Camper_Jacket"]
def hit(x, z):
    ok, loc, nor, idx = jk.ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)))
    return loc
def build_buttons(bm):
    for z in (0.784, 0.884, 1.016, 1.136):
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.008, matrix=Matrix.Translation(hit(-(opening(z) + 0.016), z) + Vector((0, -0.004, 0))))
    for sd in (1, -1):
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.0065, matrix=Matrix.Translation(hit(sd * 0.125, 1.217) + Vector((0, -0.012, 0))))
plain("Camper_Buttons", build_buttons, "button")
names = sorted(o.name for o in bpy.data.objects if o.type == "MESH")
report(names)
print("total triangles", sum(sum(len(f.vertices) - 2 for f in bpy.data.objects[n].data.polygons) for n in names))

# --- Call 11 --------------------------------------------------------------------------------------------------------
# Camper v2, call 11: tipping the beanie back on the front of its cuff dropped its top 2 cm; pivot on its centre
# instead (front up, back down), and start the cuff 1.8 cm lower so its front edge stays at 1.625 m.
import bpy, bmesh, math
from mathutils import Vector, Matrix
exec(bpy.data.texts["camper2_lib"].as_string())
t = bpy.data.texts["camper2_parts"]; s = t.as_string().replace("cuff_bot=1.625, cuff_top=1.695", "cuff_bot=1.607, cuff_top=1.677")
t.clear(); t.write(s); exec(s)
def tilt_back(bm):
    pivot = Vector((0, 0.008, P["cuff_bot"]))
    M = Matrix.Translation(pivot) @ Matrix.Rotation(-P["beanie_tilt"], 4, "X") @ Matrix.Translation(-pivot)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts[:])
def build_cuff(bm):
    b, t = P["cuff_bot"], P["cuff_top"]; h = t - b
    loft(bm, [hring(0, 0.008, b + f * h, r, r, 14) for f, r in [(0, 0.120), (0.06, 0.131), (0.35, 0.136), (0.72, 0.136), (0.96, 0.130), (1.0, 0.118)]])
    tilt_back(bm)
def build_crown(bm):
    t, c = P["cuff_top"], P["crown_top"]; h = c - t
    loft(bm, [hring(0, 0.008, t - 0.012 + f * (h + 0.012), r, r, 14) for f, r in [(0, 0.120), (0.3, 0.123), (0.6, 0.118), (0.82, 0.104), (0.95, 0.072), (1.0, 0.03)]])
    tilt_back(bm)
def build_pompom(bm):
    r = P["pom_r"]; zc = P["crown_top"] + r * 0.8
    loft(bm, [hring(0, 0.008, zc + r * math.sin(a), r * math.cos(a) + 0.002, r * math.cos(a) + 0.002, 10)
              for a in [math.radians(d) for d in (-80, -50, -20, 10, 40, 70)]])
    tilt_back(bm)
shell("Camper_BeanieCuff", build_cuff, "beanie", faces=70, voxel=0.009, relax=2)
shell("Camper_BeanieCrown", build_crown, "beanie", faces=60, voxel=0.009, relax=2)
shell("Camper_Pompom", build_pompom, "beanie", faces=28, voxel=0.008, relax=1)
report(["Camper_BeanieCuff", "Camper_BeanieCrown", "Camper_Pompom"])
cf = bpy.data.objects["Camper_BeanieCuff"]
fr = min((v.co for v in cf.data.vertices), key=lambda c: c.y)
print("cuff front-bottom area: lowest z near the front", round(min(v.co.z for v in cf.data.vertices if v.co.y < -0.1), 3))

# --- Call 12 --------------------------------------------------------------------------------------------------------
# Camper v2, call 12: the boots in call 9 turned their toes in, not out (wrong sign); turn them out.
import bpy, math
from mathutils import Vector, Matrix
exec(bpy.data.texts["camper2_lib"].as_string()); exec(bpy.data.texts["camper2_parts"].as_string())
BOOT = [(0.012, -0.050, 0.055, 0.128), (0.03, -0.051, 0.060, 0.132), (0.058, -0.048, 0.061, 0.129),
        (0.085, -0.030, 0.060, 0.110), (0.110, -0.008, 0.058, 0.086), (0.135, 0.004, 0.057, 0.068), (0.165, 0.008, 0.056, 0.064)]
def foot_ring(s, z, cy, rx, ry, n=14):
    R = Matrix.Rotation(s * P["toe_out"], 3, "Z")       # +X boot turns its toe (at -Y) towards +X
    base = Vector((s * P["ankle_x"], 0.008, 0))
    return [base + R @ (p - base) for p in hring(s * P["ankle_x"], 0.008 + cy, z, rx, ry, n)]
def build_boots(bm):
    for s in (1, -1):
        loft(bm, [foot_ring(s, z, cy, rx, ry) for z, cy, rx, ry in BOOT])
def build_soles(bm):
    for s in (1, -1):
        loft(bm, [foot_ring(s, z, -0.050, 0.063, 0.136) for z in (0.0, 0.024)])
shell("Camper_Boots", build_boots, "boot", faces=170, voxel=0.009)
plain("Camper_Soles", build_soles, "sole")
b = bpy.data.objects["Camper_Boots"]
toe = min((v.co for v in b.data.vertices if v.co.x > 0), key=lambda c: c.y)
print("his left toe at", tuple(round(c, 3) for c in toe))
report(["Camper_Boots", "Camper_Soles"])

# --- Call 13 --------------------------------------------------------------------------------------------------------
# Camper v2, call 13: re-solve the reference camera with the rebuilt model's landmarks, then render the comparison.
import bpy, os, numpy as np
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
REF = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\reference\red-beanie-man.jpg"
ns = {}
for f in ("solve.py", "facecam.py", "compare.py"):
    exec(open(os.path.join(T, f), encoding="utf-8").read(), ns)
exec(bpy.data.texts["camper2_parts"].as_string())
L3 = {"pompom": (0, 0.036, 1.808), "nose": (0, -0.128, 1.523), "chin": (0, -0.088, 1.44), "cuff_bot": (0, -0.12, 1.623),
      "fold": (0, -0.12, 1.695), "flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226),
      "pockR_bot": (-0.125, -0.143, 1.15), "pockL_bot": (0.125, -0.143, 1.15), "lowL_top": (0.13, -0.143, 0.975),
      "hemR_in": (-0.042, -0.138, 0.77), "hemL_in": (0.042, -0.138, 0.77), "slvR": (-0.245, -0.008, 0.825),
      "slvL": (0.245, -0.008, 0.825), "jcR": (-0.115, -0.078, 0.183), "jcL": (0.115, -0.078, 0.183), "tee": (0, -0.08, 1.395),
      "handR": (-0.237, 0.01, 0.645), "handL": (0.237, 0.01, 0.645)}
for z, v in zip((0.784, 0.884, 1.016, 1.136), (1035, 960, 862, 772)):
    L3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z)
L2 = {"pompom": (1165, 280), "nose": (1074, 485), "chin": (1117, 550), "cuff_bot": (1087, 411), "fold": (1087, 359),
      "flapR": (1015, 705), "flapL": (1177, 725), "pockR_bot": (1015, 775), "pockL_bot": (1177, 793), "lowL_top": (1190, 900),
      "hemR_in": (1060, 1045), "hemL_in": (1112, 1060), "slvR": (955, 978), "slvL": (1320, 1025), "jcR": (1068, 1453),
      "jcL": (1223, 1485), "tee": (1105, 588), "handR": (965, 1090), "handL": (1290, 1140),
      "btn784": (1048, 1035), "btn884": (1048, 960), "btn1016": (1050, 862), "btn1136": (1050, 772)}
cam, err = ns["solved_cam"]("RefCam", REF, L3, L2)
X = np.array([L3[k] for k in L2]); U = np.array([L2[k] for k in L2], float)
p, res = ns["solve_cam"](X, U)
R = ns["rodrigues"](p[:3]); d = R[2] if np.dot(R[2], [0.5, -0.8, 0.3]) > 0 else -R[2]
print("scale %.0f px/m | yaw %.1f | elev %.1f | rms %.1f px" % (np.exp(p[3]), np.degrees(np.arctan2(d[0], -d[1])),
      np.degrees(np.arcsin(d[2])), np.sqrt((np.linalg.norm(res, axis=1) ** 2).mean())))
print(" ".join("%s(%+.0f,%+.0f)" % (k, *r) for k, r in zip(L2, res)))
bpy.context.scene.camera = cam
objs = [o.name for o in bpy.data.objects if o.type == "MESH"]
print(ns["compare"]("RefCam", REF, objs, (880, 200, 1440, 1680), "camper_v2_cmp2.png", scale=0.5))

# --- Call 14 --------------------------------------------------------------------------------------------------------
# Camper v2, call 14: every part's builder now lives in the text block "camper2_parts" with its numbers in P, so a
# change is one edit and build_all(). Fixes from the second fit (call 13, 16 px rms): the face wider at the cheeks
# and jaw, the beanie tipped back further (its pompom sits further back and lower), the arms angling out from
# narrower shoulders to longer sleeves, and slimmer jeans cuffs and boots.
import bpy
PARTS = r'''
import bpy, bmesh, math
from mathutils import Vector, Matrix

P = dict(hem=0.77, ankle_x=0.115, toe_out=math.radians(12), slv_bot=0.805, hand_tip=0.628,
         cuff_bot=1.607, cuff_top=1.677, crown_top=1.772, beanie_tilt=math.radians(13), pom_r=0.043)

def sring(cx, cy, z, rx, ry, n=64, p=3.4, notch=None):
    """A boxy ring (superellipse) sampled evenly from the front centre; notch = (half-width, depth) recesses the
    front between the jacket's open edges."""
    raw = []
    for i in range(721):
        a = 1.5 * math.pi + 2 * math.pi * i / 720
        c, s = math.cos(a), math.sin(a)
        raw.append((rx * math.copysign(abs(c) ** (2 / p), c), ry * math.copysign(abs(s) ** (2 / p), s)))
    L = [0.0]
    for k in range(1, 721):
        L.append(L[-1] + math.hypot(raw[k][0] - raw[k - 1][0], raw[k][1] - raw[k - 1][1]))
    pts, k = [], 0
    for i in range(n):
        t = L[-1] * i / n
        while L[k + 1] < t: k += 1
        f = (t - L[k]) / max(L[k + 1] - L[k], 1e-9)
        x = raw[k][0] + f * (raw[k + 1][0] - raw[k][0]); y = raw[k][1] + f * (raw[k + 1][1] - raw[k][1])
        if notch and y < 0:
            w, d = notch
            y += d * max(0.0, min(1.0, (w - abs(x)) / 0.012))
        pts.append(Vector((cx + x, cy + y, z)))
    return pts

def opening(z):            # half-width of the jacket's open front: 4.2 cm at the hem, 6 cm at the collar
    return 0.042 + 0.018 * max(0.0, min(1.0, (z - 0.77) / (1.30 - 0.77)))

# --- jeans and boots ---
def build_jeans(bm):
    loft(bm, [hring(0, 0.005, z, rx, ry, 16) for z, rx, ry in
              [(0.76, 0.15, 0.10), (0.82, 0.172, 0.112), (0.90, 0.178, 0.112), (0.97, 0.172, 0.108)]])
    ax = P["ankle_x"]
    for s in (1, -1):
        xs = lambda z: s * (0.088 + (ax - 0.088) * (0.88 - z) / (0.88 - 0.13))
        zs = [0.88, 0.72, 0.50, 0.32, 0.232, 0.224, 0.214, 0.170, 0.162, 0.15]
        ys = [0.0, 0.0, -0.008, 0.0, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008]
        radii = [(0.086, 0.092), (0.080, 0.085), (0.070, 0.073), (0.066, 0.068), (0.065, 0.066), (0.072, 0.073),
                 (0.075, 0.076), (0.075, 0.076), (0.070, 0.071), (0.050, 0.052)]
        path_tube(bm, [(xs(z), y, z) for z, y in zip(zs, ys)], radii, n=12)

BOOT = [(0.012, -0.048, 0.051, 0.122), (0.03, -0.049, 0.055, 0.126), (0.058, -0.046, 0.056, 0.123),
        (0.085, -0.028, 0.055, 0.104), (0.110, -0.006, 0.054, 0.082), (0.135, 0.004, 0.053, 0.064), (0.175, 0.008, 0.052, 0.060)]
def foot_ring(s, z, cy, rx, ry, n=14):
    R = Matrix.Rotation(s * P["toe_out"], 3, "Z")       # each toe turned a little outwards
    base = Vector((s * P["ankle_x"], 0.008, 0))
    return [base + R @ (p - base) for p in hring(s * P["ankle_x"], 0.008 + cy, z, rx, ry, n)]
def build_boots(bm):
    for s in (1, -1):
        loft(bm, [foot_ring(s, z, cy, rx, ry) for z, cy, rx, ry in BOOT])
def build_soles(bm):
    for s in (1, -1):
        loft(bm, [foot_ring(s, z, -0.048, 0.058, 0.130) for z in (0.0, 0.024)])

# --- jacket, sleeves, hands ---
def build_jacket(bm):
    rings = [(P["hem"], 0.200, 0.138), (0.82, 0.200, 0.138), (1.00, 0.198, 0.137), (1.20, 0.198, 0.137), (1.30, 0.195, 0.132),
             (1.35, 0.180, 0.122), (1.39, 0.140, 0.105)]
    loft(bm, [sring(0, 0.0, z, rx, ry, notch=(opening(z), 0.030 if z < 1.32 else 0.022)) for z, rx, ry in rings] +
             [sring(0, 0.0, 1.415, 0.100, 0.085)])

ARM_X = [(1.300, 0.150), (1.290, 0.192), (1.200, 0.222), (1.070, 0.240)]       # shoulder to elbow (z, x)
CUFF_X = 0.262                                                              # the sleeve's cuff
def build_sleeves(bm):
    sb = P["slv_bot"]
    for s in (1, -1):
        pts = [(s * x, y, z) for (z, x), y in zip(ARM_X, (0.0, 0.0, 0.005, 0.010))] + \
              [(s * (CUFF_X - 0.008), 0.000, sb + 0.10), (s * CUFF_X, -0.005, sb + 0.067), (s * CUFF_X, -0.006, sb + 0.060),
               (s * CUFF_X, -0.008, sb + 0.006), (s * CUFF_X, -0.008, sb)]
        radii = [(0.072, 0.077), (0.076, 0.079), (0.073, 0.075), (0.067, 0.069), (0.063, 0.065), (0.063, 0.065),
                 (0.070, 0.072), (0.070, 0.072), (0.063, 0.065)]
        path_tube(bm, pts, radii, n=12)

def build_hands(bm):
    top, tip = P["slv_bot"] + 0.02, P["hand_tip"]
    L = top - tip
    prof = [(0.0, 0.000, 0.030, 0.034), (0.27, 0.002, 0.029, 0.040), (0.47, 0.004, 0.031, 0.047), (0.70, 0.006, 0.029, 0.046),
            (0.88, 0.012, 0.025, 0.040), (1.0, 0.018, 0.019, 0.030)]
    for s in (1, -1):
        ax = CUFF_X - 0.004
        loft(bm, [hring(s * (ax - 0.012 * f), -0.008 + dy, top - f * L, rx, ry, 10) for f, dy, rx, ry in prof])
        path_tube(bm, [(s * (ax - 0.005), -0.035, top - 0.32 * L), (s * (ax - 0.012), -0.052, top - 0.5 * L),
                       (s * (ax - 0.017), -0.058, top - 0.65 * L)], [(0.015, 0.015), (0.013, 0.013), (0.011, 0.011)], n=8)

# --- hoodie, hood, T-shirt, strings ---
def build_hoodie(bm):
    loft(bm, [hring(0, -0.088, z, rx, 0.030, 12) for z, rx in [(P["hem"] + 0.012, 0.060), (0.82, 0.062), (1.10, 0.068), (1.30, 0.076), (1.37, 0.072)]])
def build_hood(bm):
    pts, radii = [], []
    for k in range(15):
        a = math.radians(-65 + 310 * k / 14)
        b = (math.sin(a) + 1) / 2
        pts.append((0.105 * math.cos(a), 0.012 + 0.098 * math.sin(a), 1.40 + 0.055 * b))
        r = 0.024 + 0.024 * b
        radii.append((r, r * 1.15))
    path_tube(bm, pts, radii, n=10)
    loft(bm, [hring(0, 0.125, z, rx, ry, 10) for z, rx, ry in [(1.31, 0.05, 0.025), (1.35, 0.10, 0.045), (1.41, 0.11, 0.05), (1.45, 0.08, 0.04)]])
def build_tshirt(bm):
    loft(bm, [hring(0, -0.066, z, rx, 0.018, 8) for z, rx in [(1.35, 0.03), (1.385, 0.045), (1.425, 0.05)]])
def build_strings(bm):
    for s in (1, -1):
        path_tube(bm, [(s * 0.028, -0.112, 1.39), (s * 0.032, -0.121, 1.31), (s * 0.034, -0.122, 1.205)], [(0.0045, 0.0045)] * 3, n=5)
        path_tube(bm, [(s * 0.034, -0.122, 1.21), (s * 0.034, -0.122, 1.185)], [(0.007, 0.007)] * 2, n=6)

# --- head, hair, beanie ---
HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.012, 0.056, 0.058), (1.425, 0.000, 0.072, 0.078), (1.44, -0.008, 0.086, 0.090),
        (1.475, -0.006, 0.100, 0.102), (1.53, -0.002, 0.106, 0.108), (1.60, 0.002, 0.107, 0.111), (1.67, 0.006, 0.102, 0.107),
        (1.72, 0.008, 0.086, 0.092), (1.755, 0.008, 0.050, 0.055)]
def build_head(bm):
    loft(bm, [hring(0, cy, z, rx, ry, 14) for z, cy, rx, ry in HEAD])
    path_tube(bm, [(0, -0.100, 1.575), (0, -0.120, 1.54), (0, -0.130, 1.523)], [(0.018, 0.015), (0.015, 0.012), (0.007, 0.006)],
              n=6, ref=Vector((1, 0, 0)))
def build_hair(bm):     # a short band under the cuff at the sides and back
    loft(bm, [hring(0, 0.028, z, rx, ry, 14) for z, rx, ry in [(1.555, 0.086, 0.084), (1.575, 0.109, 0.104), (1.64, 0.111, 0.103), (1.68, 0.100, 0.094)]])

def tilt_back(bm):      # the beanie sits tipped back on his head, pivoting on its centre
    pivot = Vector((0, 0.008, P["cuff_bot"]))
    M = Matrix.Translation(pivot) @ Matrix.Rotation(-P["beanie_tilt"], 4, "X") @ Matrix.Translation(-pivot)
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts[:])
def build_cuff(bm):
    b, t = P["cuff_bot"], P["cuff_top"]; h = t - b
    loft(bm, [hring(0, 0.008, b + f * h, r, r, 14) for f, r in [(0, 0.122), (0.06, 0.133), (0.35, 0.137), (0.72, 0.138), (0.96, 0.133), (1.0, 0.121)]])
    tilt_back(bm)
def build_crown(bm):
    t, c = P["cuff_top"], P["crown_top"]; h = c - t
    loft(bm, [hring(0, 0.008, t - 0.012 + f * (h + 0.012), r, r, 14) for f, r in [(0, 0.122), (0.3, 0.125), (0.6, 0.121), (0.82, 0.108), (0.95, 0.078), (1.0, 0.035)]])
    tilt_back(bm)
def build_pompom(bm):
    r = P["pom_r"]; zc = P["crown_top"] + r * 0.8
    loft(bm, [hring(0, 0.008, zc + r * math.sin(a), r * math.cos(a) + 0.002, r * math.cos(a) + 0.002, 10)
              for a in [math.radians(d) for d in (-80, -50, -20, 10, 40, 70)]])
    tilt_back(bm)

# --- the jacket's details, wrapped onto its faceted front ---
def hit(x, z):
    ok, loc, nor, idx = bpy.data.objects["Camper_Jacket"].ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)))
    return loc
def patch(bm, corners, thick, nx=4, nz=3):
    (x0, z0), (x1, z1), (x2, z2), (x3, z3) = corners
    front, back = [], []
    for j in range(nz + 1):
        v = j / nz
        rf, rb = [], []
        for i in range(nx + 1):
            u = i / nx
            x = (1 - v) * ((1 - u) * x0 + u * x1) + v * ((1 - u) * x3 + u * x2)
            z = (1 - v) * ((1 - u) * z0 + u * z1) + v * ((1 - u) * z3 + u * z2)
            p = hit(x, z)
            rf.append(bm.verts.new(p + Vector((0, -thick, 0)))); rb.append(bm.verts.new(p + Vector((0, 0.003, 0))))
        front.append(rf); back.append(rb)
    for j in range(nz):
        for i in range(nx):
            bm.faces.new((front[j][i], front[j][i + 1], front[j + 1][i + 1], front[j + 1][i]))
            bm.faces.new((back[j][i], back[j + 1][i], back[j + 1][i + 1], back[j][i + 1]))
    edge = lambda g: [g[0][i] for i in range(nx + 1)] + [g[j][nx] for j in range(1, nz + 1)] + \
                     [g[nz][i] for i in range(nx - 1, -1, -1)] + [g[j][0] for j in range(nz - 1, 0, -1)]
    rf_, rb_ = edge(front), edge(back)
    for k in range(len(rf_)):
        m = (k + 1) % len(rf_)
        bm.faces.new((rf_[k], rb_[k], rb_[m], rf_[m]))
def quad(s, a, b, z0, z1):
    lo, hi = sorted((s * a, s * b))
    return [(lo, z0), (hi, z0), (hi, z1), (lo, z1)]
def build_collar(bm):
    for s in (1, -1):
        w = opening(1.30)
        c = [(s * (w + 0.008), 1.262), (s * (w + 0.022), 1.250), (s * 0.150, 1.352), (s * (w + 0.02), 1.392)]
        if s < 0: c = [c[1], c[0], c[3], c[2]]
        patch(bm, c, 0.010, 3, 4)
def build_pockets(bm):
    for s in (1, -1):
        patch(bm, quad(s, 0.085, 0.165, 1.150, 1.232), 0.005)
        patch(bm, quad(s, 0.083, 0.176, 0.800, 0.975), 0.005, 4, 4)
def build_flaps(bm):
    for s in (1, -1):
        patch(bm, quad(s, 0.081, 0.169, 1.205, 1.248), 0.011, 3, 2)
        patch(bm, quad(s, 0.081, 0.178, 0.950, 0.978), 0.009, 3, 1)
def build_buttons(bm):
    for z in (0.784, 0.884, 1.016, 1.136):
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.008, matrix=Matrix.Translation(hit(-(opening(z) + 0.016), z) + Vector((0, -0.004, 0))))
    for s in (1, -1):
        bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.0065, matrix=Matrix.Translation(hit(s * 0.125, 1.217) + Vector((0, -0.012, 0))))

SHELLS = [("Camper_Jeans", "build_jeans", "jeans", 320, 0.012, 4), ("Camper_Boots", "build_boots", "boot", 170, 0.009, 4),
          ("Camper_Jacket", "build_jacket", "jacket", 320, 0.010, 4), ("Camper_Sleeves", "build_sleeves", "jacket", 220, 0.010, 4),
          ("Camper_Hands", "build_hands", "skin", 90, 0.007, 3), ("Camper_Hoodie", "build_hoodie", "hoodie", 70, 0.009, 2),
          ("Camper_Hood", "build_hood", "hoodie", 150, 0.009, 4), ("Camper_TShirt", "build_tshirt", "tshirt", 16, 0.008, 2),
          ("Camper_Head", "build_head", "skin", 150, 0.008, 3), ("Camper_Hair", "build_hair", "hair", 50, 0.008, 3),
          ("Camper_BeanieCuff", "build_cuff", "beanie", 70, 0.009, 2), ("Camper_BeanieCrown", "build_crown", "beanie", 60, 0.009, 2),
          ("Camper_Pompom", "build_pompom", "beanie", 28, 0.008, 1)]
PLAIN = [("Camper_Soles", "build_soles", "sole"), ("Camper_Strings", "build_strings", "string"),
         ("Camper_Collar", "build_collar", "jacket_dark"), ("Camper_Pockets", "build_pockets", "pocket"),
         ("Camper_Flaps", "build_flaps", "jacket"), ("Camper_Buttons", "build_buttons", "button")]
def build_all(only=None):
    g = globals()
    for nm, fn, mk, fc, vx, rl in SHELLS:
        if only is None or nm in only:
            shell(nm, g[fn], mk, faces=fc, voxel=vx, relax=rl)
    for nm, fn, mk in PLAIN:                  # after the jacket: the details are laid on it
        if only is None or nm in only or (nm in ("Camper_Collar", "Camper_Pockets", "Camper_Flaps", "Camper_Buttons") and "Camper_Jacket" in only):
            plain(nm, g[fn], mk)
'''
t = bpy.data.texts.get("camper2_parts") or bpy.data.texts.new("camper2_parts"); t.clear(); t.write(PARTS)
exec(bpy.data.texts["camper2_lib"].as_string())
exec(PARTS)
build_all()
names = sorted(o.name for o in bpy.data.objects if o.type == "MESH")
report(names)
print("total triangles", sum(sum(len(f.vertices) - 2 for f in bpy.data.objects[n].data.polygons) for n in names))

# --- Call 15 --------------------------------------------------------------------------------------------------------
# Camper v2, call 15: the third fit, with the landmarks moved to where call 14 put them.
import bpy
exec(bpy.data.texts["camper2_parts"].as_string().split("# --- jeans")[0])
L3 = {"pompom": (0, 0.053, 1.801), "nose": (0, -0.130, 1.523), "chin": (0, -0.09, 1.44), "cuff_bot": (0, -0.121, 1.641),
      "fold": (0, -0.106, 1.705), "flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226),
      "pockR_bot": (-0.125, -0.143, 1.15), "pockL_bot": (0.125, -0.143, 1.15), "lowL_top": (0.13, -0.143, 0.975),
      "hemR_in": (-0.042, -0.138, 0.77), "hemL_in": (0.042, -0.138, 0.77), "slvR": (-0.262, -0.008, 0.805),
      "slvL": (0.262, -0.008, 0.805), "jcR": (-0.113, -0.067, 0.193), "jcL": (0.113, -0.067, 0.193), "tee": (0, -0.08, 1.395),
      "handR": (-0.246, 0.01, 0.628), "handL": (0.246, 0.01, 0.628)}
for z in (0.784, 0.884, 1.016, 1.136):
    L3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z)
OUT = "camper_v2_cmp3.png"
exec(open(r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools\fit.py", encoding="utf-8").read())

# --- Call 16 --------------------------------------------------------------------------------------------------------
# Camper v2, call 16: fixes from the third fit (call 15, 14.5 px rms): the jaw tapering to a chin that comes forward
# (the face read as a long block), the pompom further back on the crown, a crisp slightly flared jacket hem (the relax
# had puffed it round), lower sloping shoulders, shorter hands, and the pockets where the reference has them.
import bpy
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:60]
    s = s.replace(old, new)
swap('''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.012, 0.056, 0.058), (1.425, 0.000, 0.072, 0.078), (1.44, -0.008, 0.086, 0.090),
        (1.475, -0.006, 0.100, 0.102), (1.53, -0.002, 0.106, 0.108),''',
     '''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.012, 0.056, 0.058), (1.428, -0.004, 0.058, 0.080), (1.445, -0.010, 0.072, 0.088),
        (1.47, -0.008, 0.090, 0.098), (1.50, -0.005, 0.101, 0.104), (1.54, -0.002, 0.106, 0.108),''')
swap('P = dict(hem=0.77, ankle_x=0.115, toe_out=math.radians(12), slv_bot=0.805, hand_tip=0.628,',
     'P = dict(hem=0.77, ankle_x=0.115, toe_out=math.radians(12), slv_bot=0.805, hand_tip=0.645,')
swap('''    r = P["pom_r"]; zc = P["crown_top"] + r * 0.8
    loft(bm, [hring(0, 0.008, zc''', '''    r = P["pom_r"]; zc = P["crown_top"] + r * 0.6
    loft(bm, [hring(0, 0.03, zc''')
swap('''    rings = [(P["hem"], 0.200, 0.138), (0.82, 0.200, 0.138), (1.00, 0.198, 0.137), (1.20, 0.198, 0.137), (1.30, 0.195, 0.132),
             (1.35, 0.180, 0.122), (1.39, 0.140, 0.105)]''',
     '''    h = P["hem"]
    rings = [(h, 0.206, 0.142), (h + 0.012, 0.205, 0.141), (h + 0.03, 0.201, 0.139), (1.00, 0.198, 0.137), (1.20, 0.198, 0.137),
             (1.29, 0.193, 0.131), (1.34, 0.170, 0.119), (1.385, 0.135, 0.104)]''')
swap('ARM_X = [(1.300, 0.150), (1.290, 0.192), (1.200, 0.222), (1.070, 0.240)]', 'ARM_X = [(1.275, 0.150), (1.262, 0.192), (1.180, 0.222), (1.060, 0.240)]')
swap('patch(bm, quad(s, 0.085, 0.165, 1.150, 1.232), 0.005)', 'patch(bm, quad(s, 0.085, 0.165, 1.135, 1.232), 0.005)')
swap('patch(bm, quad(s, 0.083, 0.176, 0.800, 0.975), 0.005, 4, 4)', 'patch(bm, quad(s, 0.083, 0.176, 0.800, 0.990), 0.005, 4, 4)')
swap('patch(bm, quad(s, 0.081, 0.178, 0.950, 0.978), 0.009, 3, 1)', 'patch(bm, quad(s, 0.081, 0.178, 0.962, 0.992), 0.009, 3, 1)')
swap('("Camper_Jacket", "build_jacket", "jacket", 320, 0.010, 4)', '("Camper_Jacket", "build_jacket", "jacket", 320, 0.009, 2)')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Head", "Camper_Pompom", "Camper_Jacket", "Camper_Sleeves", "Camper_Hands"])
report(["Camper_Head", "Camper_Pompom", "Camper_Jacket", "Camper_Sleeves", "Camper_Hands"])

# --- Call 17 --------------------------------------------------------------------------------------------------------
# Camper v2, call 17: the fourth fit.
import bpy
exec(bpy.data.texts["camper2_parts"].as_string().split("# --- jeans")[0])
L3 = {"pompom": (0, 0.072, 1.788), "nose": (0, -0.130, 1.523), "chin": (0, -0.095, 1.442), "cuff_bot": (0, -0.121, 1.641),
      "fold": (0, -0.106, 1.705), "flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226),
      "pockR_bot": (-0.125, -0.143, 1.135), "pockL_bot": (0.125, -0.143, 1.135), "lowL_top": (0.13, -0.143, 0.99),
      "hemR_in": (-0.042, -0.142, 0.77), "hemL_in": (0.042, -0.142, 0.77), "slvR": (-0.262, -0.008, 0.805),
      "slvL": (0.262, -0.008, 0.805), "jcR": (-0.113, -0.067, 0.193), "jcL": (0.113, -0.067, 0.193), "tee": (0, -0.08, 1.395),
      "handR": (-0.246, 0.01, 0.645), "handL": (0.246, 0.01, 0.645)}
for z in (0.784, 0.884, 1.016, 1.136):
    L3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z)
OUT = "camper_v2_cmp4.png"
exec(open(r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools\fit.py", encoding="utf-8").read())

# --- Measuring only, after call 17: close-up overlays of the head and the jacket ------------------------------------
import bpy, os
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
REF = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\reference\red-beanie-man.jpg"
ns = {}; exec(open(os.path.join(T, "compare.py"), encoding="utf-8").read(), ns)
sh = bpy.context.scene.display.shading
saved = (sh.light, sh.studio_light if hasattr(sh, "studio_light") else None)
sh.light = "STUDIO"
try:
    sh.use_world_space_lighting = True; sh.studiolight_rotate_z = 2.6
except Exception as e: print("rot", e)
objs = [o.name for o in bpy.data.objects if o.type == "MESH"]
print(ns["compare"]("RefCam", REF, objs, (990, 230, 1330, 640), "camper_v2_head4.png", scale=1.0))
print(ns["compare"]("RefCam", REF, objs, (900, 560, 1400, 1200), "camper_v2_torso4.png", scale=1.0))

# --- Call 18 --------------------------------------------------------------------------------------------------------
# Camper v2, call 18: from the close-up overlays (call 17): straighter sleeves (they ballooned at the cuff), no flare
# at the jacket hem (the reference's jacket is straight), and a narrower, taller crown under a bigger pompom.
import bpy
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:60]
    s = s.replace(old, new)
swap('''        radii = [(0.072, 0.077), (0.076, 0.079), (0.073, 0.075), (0.067, 0.069), (0.063, 0.065), (0.063, 0.065),
                 (0.070, 0.072), (0.070, 0.072), (0.063, 0.065)]''',
     '''        radii = [(0.072, 0.077), (0.075, 0.078), (0.071, 0.073), (0.067, 0.069), (0.064, 0.066), (0.064, 0.066),
                 (0.068, 0.070), (0.068, 0.070), (0.062, 0.064)]''')
swap('[(s * (CUFF_X - 0.008), 0.000, sb + 0.10)', '[(s * (CUFF_X - 0.003), 0.000, sb + 0.10)')
swap('rings = [(h, 0.206, 0.142), (h + 0.012, 0.205, 0.141), (h + 0.03, 0.201, 0.139),',
     'rings = [(h, 0.201, 0.139), (h + 0.012, 0.201, 0.139), (h + 0.03, 0.200, 0.138),')
swap('cuff_bot=1.607, cuff_top=1.677, crown_top=1.772, beanie_tilt=math.radians(13), pom_r=0.043)',
     'cuff_bot=1.607, cuff_top=1.677, crown_top=1.785, beanie_tilt=math.radians(13), pom_r=0.047)')
swap('[(0, 0.122), (0.3, 0.125), (0.6, 0.121), (0.82, 0.108), (0.95, 0.078), (1.0, 0.035)]',
     '[(0, 0.119), (0.3, 0.121), (0.6, 0.114), (0.82, 0.098), (0.95, 0.068), (1.0, 0.030)]')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Jacket", "Camper_Sleeves", "Camper_BeanieCrown", "Camper_Pompom"])
report(["Camper_Jacket", "Camper_Sleeves", "Camper_BeanieCrown", "Camper_Pompom"])

# --- Call 19 --------------------------------------------------------------------------------------------------------
# Camper v2, call 19: a lit render through the solved camera, beside the reference (EEVEE, a sun from above the
# camera's left, a grey world for the fill, standard colour). Temporary: the sun and world settings are removed after.
import bpy, os, numpy as np, math
from mathutils import Vector, Euler
REF = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\reference\red-beanie-man.jpg"
OUTD = os.path.join(os.environ["TEMP"], "raccoon_v2")
sc = bpy.context.scene; r = sc.render
saved = dict(engine=r.engine, rx=r.resolution_x, ry=r.resolution_y, pct=r.resolution_percentage, ft=r.film_transparent,
             fp=r.filepath, vt=sc.view_settings.view_transform, world=sc.world)
for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
    try: r.engine = eng; break
    except TypeError: pass
w = bpy.data.worlds.new("_cmp_world"); w.use_nodes = True
bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
bg.inputs[0].default_value = (0.34, 0.34, 0.34, 1); bg.inputs[1].default_value = 1.0
sc.world = w
sun = bpy.data.objects.new("_cmp_sun", bpy.data.lights.new("_cmp_sun", "SUN")); sc.collection.objects.link(sun)
sun.data.energy = 3.2; sun.data.angle = math.radians(8)
sun.rotation_euler = Euler((math.radians(45), 0, math.radians(-20)), "XYZ")
try: sc.view_settings.view_transform = "Standard"
except TypeError as e: print(e)
img = bpy.data.images.load(REF, check_existing=True); W, H = img.size
r.resolution_x, r.resolution_y, r.resolution_percentage = W, H, 50
r.film_transparent = False
r.filepath = os.path.join(OUTD, "_lit.png"); r.image_settings.file_format = "PNG"
bpy.ops.render.render(write_still=True)
ren = bpy.data.images.load(r.filepath, check_existing=False)
a = np.array(ren.pixels[:], np.float32).reshape(ren.size[1], ren.size[0], 4)[::-1]; bpy.data.images.remove(ren)
ref = np.array(img.pixels[:], np.float32).reshape(H, W, 4)[::-1]
yi = (np.arange(H) * a.shape[0] / H).astype(int); xi = (np.arange(W) * a.shape[1] / W).astype(int); a = a[yi][:, xi]
x0, y0, x1, y1 = 880, 200, 1440, 1680
panel = np.concatenate([ref[y0:y1, x0:x1], a[y0:y1, x0:x1]], 1); panel[:, :, 3] = 1
o = bpy.data.images.new("_sbs", panel.shape[1], panel.shape[0], alpha=True); o.pixels[:] = panel[::-1].ravel()
o.filepath_raw = os.path.join(OUTD, "camper_v2_sbs.png"); o.file_format = "PNG"; o.save(); bpy.data.images.remove(o)
# restore
bpy.data.objects.remove(sun); bpy.data.lights.remove(bpy.data.lights["_cmp_sun"])
sc.world = saved["world"]; bpy.data.worlds.remove(w)
r.resolution_x, r.resolution_y, r.resolution_percentage, r.film_transparent, r.filepath = saved["rx"], saved["ry"], saved["pct"], saved["ft"], saved["fp"]
sc.view_settings.view_transform = saved["vt"]
print(os.path.join(OUTD, "camper_v2_sbs.png"), r.engine)

# --- Call 20 --------------------------------------------------------------------------------------------------------
# Camper v2, call 20: from the lit side-by-side (call 19): thinner sleeves set a little closer in, slimmer jeans with
# the rolled cuffs as their own crisp shell, crisper boots, a fuller hood bunched up round the neck with only a small
# V of T-shirt, a smaller collar in the jacket's own colour, and a face wider at the cheeks that tapers to its chin.
import bpy
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
# sleeves
swap('''        radii = [(0.072, 0.077), (0.075, 0.078), (0.071, 0.073), (0.067, 0.069), (0.064, 0.066), (0.064, 0.066),
                 (0.068, 0.070), (0.068, 0.070), (0.062, 0.064)]''',
     '''        radii = [(0.064, 0.068), (0.066, 0.069), (0.062, 0.064), (0.058, 0.060), (0.056, 0.058), (0.056, 0.058),
                 (0.061, 0.063), (0.061, 0.063), (0.055, 0.057)]''')
swap('ARM_X = [(1.275, 0.150), (1.262, 0.192), (1.180, 0.222), (1.060, 0.240)]', 'ARM_X = [(1.275, 0.150), (1.262, 0.190), (1.180, 0.216), (1.060, 0.233)]')
swap('CUFF_X = 0.262 ', 'CUFF_X = 0.254 ')
# jeans: slimmer legs ending inside a separate cuff shell
swap('''        zs = [0.88, 0.72, 0.50, 0.32, 0.232, 0.224, 0.214, 0.170, 0.162, 0.15]
        ys = [0.0, 0.0, -0.008, 0.0, 0.008, 0.008, 0.008, 0.008, 0.008, 0.008]
        radii = [(0.086, 0.092), (0.080, 0.085), (0.070, 0.073), (0.066, 0.068), (0.065, 0.066), (0.072, 0.073),
                 (0.075, 0.076), (0.075, 0.076), (0.070, 0.071), (0.050, 0.052)]
        path_tube(bm, [(xs(z), y, z) for z, y in zip(zs, ys)], radii, n=12)''',
     '''        zs = [0.88, 0.72, 0.50, 0.32, 0.20, 0.16]
        ys = [0.0, 0.0, -0.008, 0.0, 0.008, 0.008]
        radii = [(0.080, 0.086), (0.075, 0.080), (0.066, 0.069), (0.063, 0.065), (0.062, 0.064), (0.058, 0.060)]
        path_tube(bm, [(xs(z), y, z) for z, y in zip(zs, ys)], radii, n=12)
def build_jeans_cuffs(bm):     # the rolled cuffs: a short band round each ankle, a little wider than the leg
    for s in (1, -1):
        x = s * (0.088 + (P["ankle_x"] - 0.088) * (0.88 - 0.19) / 0.75)
        loft(bm, [hring(x, 0.008, z, r, r * 1.02, 12) for z, r in [(0.158, 0.066), (0.162, 0.071), (0.218, 0.071), (0.222, 0.066)]])''')
swap('("Camper_Boots", "build_boots", "boot", 170, 0.009, 4)', '("Camper_JeansCuffs", "build_jeans_cuffs", "jeans", 60, 0.007, 1), ("Camper_Boots", "build_boots", "boot", 170, 0.008, 2)')
# hood fuller and higher at the sides; the T-shirt only a small V
swap('''        pts.append((0.105 * math.cos(a), 0.012 + 0.098 * math.sin(a), 1.40 + 0.055 * b))
        r = 0.024 + 0.024 * b''',
     '''        pts.append((0.108 * math.cos(a), 0.014 + 0.100 * math.sin(a), 1.405 + 0.06 * b))
        r = 0.030 + 0.026 * b''')
swap('''    loft(bm, [hring(0, -0.066, z, rx, 0.018, 8) for z, rx in [(1.35, 0.03), (1.385, 0.045), (1.425, 0.05)]])''',
     '''    loft(bm, [hring(0, -0.07, z, rx, 0.016, 8) for z, rx in [(1.345, 0.012), (1.375, 0.03), (1.42, 0.042)]])''')
# collar: smaller, in the jacket's own colour
swap('''        c = [(s * (w + 0.008), 1.262), (s * (w + 0.022), 1.250), (s * 0.150, 1.352), (s * (w + 0.02), 1.392)]''',
     '''        c = [(s * (w + 0.006), 1.290), (s * (w + 0.018), 1.282), (s * 0.135, 1.356), (s * (w + 0.016), 1.392)]''')
swap('("Camper_Collar", "build_collar", "jacket_dark")', '("Camper_Collar", "build_collar", "jacket")')
# head: wider cheeks, a stronger taper to a narrower chin that comes forward
swap('''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.012, 0.056, 0.058), (1.428, -0.004, 0.058, 0.080), (1.445, -0.010, 0.072, 0.088),
        (1.47, -0.008, 0.090, 0.098), (1.50, -0.005, 0.101, 0.104), (1.54, -0.002, 0.106, 0.108),''',
     '''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.014, 0.058, 0.060), (1.428, -0.004, 0.050, 0.082), (1.445, -0.012, 0.068, 0.090),
        (1.475, -0.010, 0.094, 0.100), (1.51, -0.006, 0.108, 0.106), (1.55, -0.003, 0.112, 0.109),''')
t.clear(); t.write(s)
lib = bpy.data.texts["camper2_lib"]; ls = lib.as_string()
if '"string": ("A9A9AD", 0.8)' in ls:
    ls = ls.replace('"string": ("A9A9AD", 0.8)', '"string": ("9C9CA1", 0.8)'); lib.clear(); lib.write(ls)
exec(ls); exec(s)
build_all(["Camper_Jeans", "Camper_JeansCuffs", "Camper_Boots", "Camper_Jacket", "Camper_Sleeves", "Camper_Hands", "Camper_Hood",
           "Camper_TShirt", "Camper_Head", "Camper_Strings"])
names = sorted(o.name for o in bpy.data.objects if o.type == "MESH")
report(names)
print("total triangles", sum(sum(len(f.vertices) - 2 for f in bpy.data.objects[n].data.polygons) for n in names))

# --- Measuring only, after call 20: the lit side-by-side render of the whole figure and the head --------------------
import bpy
SP = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX = "camper_v2_sbs2.png", (880, 200, 1440, 1680)
exec(open(SP + r"\lit.py", encoding="utf-8").read())
OUT, BOX, SCALE = "camper_v2_sbs2_head.png", (990, 230, 1330, 640), 1.0
exec(open(SP + r"\lit.py", encoding="utf-8").read())

# --- Call 21 --------------------------------------------------------------------------------------------------------
# Camper v2, call 21: from the head close-up (call 20's render): the forehead poked through the tipped-back crown,
# the face was too round at the jaw and its nose too thin, and the cuff's rolled lip and lumpy crown didn't read as
# the reference's crisp band and dome. Also: the soles showing as a darker edge, and the fingers curling in more.
import bpy
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.014, 0.058, 0.060), (1.428, -0.004, 0.050, 0.082), (1.445, -0.012, 0.068, 0.090),
        (1.475, -0.010, 0.094, 0.100), (1.51, -0.006, 0.108, 0.106), (1.55, -0.003, 0.112, 0.109), (1.60, 0.002, 0.107, 0.111), (1.67, 0.006, 0.102, 0.107),
        (1.72, 0.008, 0.086, 0.092), (1.755, 0.008, 0.050, 0.055)]''',
     '''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.014, 0.058, 0.060), (1.428, -0.006, 0.042, 0.082), (1.445, -0.012, 0.060, 0.091),
        (1.475, -0.010, 0.082, 0.101), (1.51, -0.006, 0.098, 0.106), (1.55, -0.003, 0.105, 0.109), (1.60, 0.004, 0.105, 0.109),
        (1.65, 0.016, 0.098, 0.098), (1.70, 0.026, 0.082, 0.080), (1.735, 0.028, 0.048, 0.048)]''')
swap('''    path_tube(bm, [(0, -0.100, 1.575), (0, -0.120, 1.54), (0, -0.130, 1.523)], [(0.018, 0.015), (0.015, 0.012), (0.007, 0.006)],''',
     '''    path_tube(bm, [(0, -0.098, 1.585), (0, -0.124, 1.545), (0, -0.136, 1.522)], [(0.022, 0.016), (0.021, 0.014), (0.010, 0.007)],''')
swap('("Camper_Head", "build_head", "skin", 150, 0.008, 3)', '("Camper_Head", "build_head", "skin", 110, 0.007, 2)')
swap('[(0, 0.122), (0.06, 0.133), (0.35, 0.137), (0.72, 0.138), (0.96, 0.133), (1.0, 0.121)]',
     '[(0, 0.126), (0.04, 0.131), (0.5, 0.134), (0.95, 0.137), (1.0, 0.127)]')
swap('crown_top=1.785,', 'crown_top=1.80,')
swap('[(0, 0.119), (0.3, 0.121), (0.6, 0.114), (0.82, 0.098), (0.95, 0.068), (1.0, 0.030)]',
     '[(0, 0.120), (0.25, 0.122), (0.5, 0.117), (0.72, 0.104), (0.88, 0.080), (0.97, 0.045), (1.0, 0.020)]')
swap('("Camper_BeanieCuff", "build_cuff", "beanie", 70, 0.009, 2), ("Camper_BeanieCrown", "build_crown", "beanie", 60, 0.009, 2)',
     '("Camper_BeanieCuff", "build_cuff", "beanie", 70, 0.008, 1), ("Camper_BeanieCrown", "build_crown", "beanie", 60, 0.008, 1)')
swap('''        loft(bm, [foot_ring(s, z, -0.048, 0.058, 0.130) for z in (0.0, 0.024)])''',
     '''        loft(bm, [foot_ring(s, z, -0.048, 0.061, 0.133) for z in (0.0, 0.03)])''')
swap('''        loft(bm, [hring(s * (ax - 0.012 * f), -0.008 + dy, top - f * L, rx, ry, 10) for f, dy, rx, ry in prof])''',
     '''        loft(bm, [hring(s * (ax - 0.022 * f * f), -0.008 + dy, top - f * L, rx * (1 + 0.15 * f), ry, 10) for f, dy, rx, ry in prof])''')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Head", "Camper_BeanieCuff", "Camper_BeanieCrown", "Camper_Pompom", "Camper_Soles", "Camper_Hands"])
report(["Camper_Head", "Camper_BeanieCuff", "Camper_BeanieCrown", "Camper_Pompom", "Camper_Soles", "Camper_Hands"])
SP = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_sbs3_head.png", (990, 230, 1330, 640), 1.0
exec(open(SP + r"\lit.py", encoding="utf-8").read())

# --- Call 22 --------------------------------------------------------------------------------------------------------
# Camper v2, call 22: the face from the reference: a flatter front (boxier rings), a jaw that stays wide and then
# rounds into the chin, and the nose as a crisp separate wedge (fused in, it smeared into a ridge up to the brow).
import bpy
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.014, 0.058, 0.060), (1.428, -0.006, 0.042, 0.082), (1.445, -0.012, 0.060, 0.091),
        (1.475, -0.010, 0.082, 0.101), (1.51, -0.006, 0.098, 0.106), (1.55, -0.003, 0.105, 0.109), (1.60, 0.004, 0.105, 0.109),''',
     '''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.014, 0.058, 0.060), (1.428, -0.006, 0.050, 0.082), (1.445, -0.012, 0.074, 0.091),
        (1.47, -0.010, 0.090, 0.100), (1.51, -0.006, 0.099, 0.105), (1.55, -0.003, 0.103, 0.108), (1.60, 0.004, 0.104, 0.108),''')
swap('''    loft(bm, [hring(0, cy, z, rx, ry, 14) for z, cy, rx, ry in HEAD])
    path_tube(bm, [(0, -0.098, 1.585), (0, -0.124, 1.545), (0, -0.136, 1.522)], [(0.022, 0.016), (0.021, 0.014), (0.010, 0.007)],
              n=6, ref=Vector((1, 0, 0)))''',
     '''    loft(bm, [sring(0, cy, z, rx, ry, n=28, p=2.5) for z, cy, rx, ry in HEAD])
def build_nose(bm):     # a crisp wedge: narrow at the bridge, widest at the base, its tip pointing forward and down
    v = [bm.verts.new(p) for p in [(0, -0.100, 1.580), (-0.021, -0.101, 1.521), (0.021, -0.101, 1.521), (0, -0.140, 1.527),
                                    (0, -0.096, 1.514)]]
    top, lf, rt, tip, bot = v
    for f in ((top, lf, tip), (top, tip, rt), (lf, bot, tip), (tip, bot, rt), (top, rt, bot, lf)):
        bm.faces.new(f)''')
swap('("Camper_Soles", "build_soles", "sole"),', '("Camper_Soles", "build_soles", "sole"), ("Camper_Nose", "build_nose", "skin"),')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Head", "Camper_Nose"])
report(["Camper_Head", "Camper_Nose"])
SP = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_sbs4_head.png", (990, 230, 1330, 640), 1.0
exec(open(SP + r"\lit.py", encoding="utf-8").read())

# --- Call 23 --------------------------------------------------------------------------------------------------------
# Camper v2, call 23: the reference's face is widest right under the cuff (it sits on the widest part of his head);
# keep the head wide up to the cuff instead of narrowing from 1.60 m.
import bpy
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
old = '''(1.51, -0.006, 0.099, 0.105), (1.55, -0.003, 0.103, 0.108), (1.60, 0.004, 0.104, 0.108),
        (1.65, 0.016, 0.098, 0.098), (1.70, 0.026, 0.082, 0.080), (1.735, 0.028, 0.048, 0.048)]'''
new = '''(1.51, -0.006, 0.101, 0.105), (1.55, -0.003, 0.107, 0.108), (1.60, 0.004, 0.110, 0.108),
        (1.64, 0.010, 0.108, 0.102), (1.68, 0.020, 0.095, 0.090), (1.715, 0.026, 0.070, 0.068), (1.735, 0.028, 0.040, 0.040)]'''
assert s.count(old) == 1
s = s.replace(old, new); t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Head"])
report(["Camper_Head"])
SP = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_sbs5.png", (880, 200, 1440, 1680), 0.5
exec(open(SP + r"\lit.py", encoding="utf-8").read())

# --- Call 24 --------------------------------------------------------------------------------------------------------
# Camper v2, call 24: tidy, save and export. The v1 materials (unused since call 2) are removed, every part is checked
# for an identity transform and flat shading, and the solved reference camera is kept in the file (not exported).
import bpy, os
for m in [m for m in bpy.data.materials if m.users == 0]:
    bpy.data.materials.remove(m)
for me in [me for me in bpy.data.meshes if me.users == 0]:
    bpy.data.meshes.remove(me)
parts = sorted((o for o in bpy.data.objects if o.type == "MESH"), key=lambda o: o.name)
bad = [o.name for o in parts if any(abs(o.matrix_world[i][j] - (1.0 if i == j else 0.0)) > 1e-9 for i in range(4) for j in range(4))]
for o in parts:
    for p in o.data.polygons: p.use_smooth = False
pts = [v.co for o in parts for v in o.data.vertices]
lo = [min(p[i] for p in pts) for i in range(3)]; hi = [max(p[i] for p in pts) for i in range(3)]
tris = sum(len(f.vertices) - 2 for o in parts for f in o.data.polygons)
print("parts", len(parts), "| not identity:", bad, "| size %.3f x %.3f x %.3f m" % tuple(hi[i] - lo[i] for i in range(3)),
      "| bottom Z %.4f | centre X %.4f Y %.4f | triangles %d" % (lo[2], (lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, tris))
print("materials:", sorted(m.name for m in bpy.data.materials))
bpy.ops.wm.save_mainfile()
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("saved", bpy.data.filepath, "| exported", out, os.path.getsize(out), "bytes")

# --- Call 25 --------------------------------------------------------------------------------------------------------
# Camper v2, call 25: the export warned that three meshes "are not valid"; find what's wrong and repair it.
import bpy, bmesh, os
for n in ("Camper_BeanieCuff", "Camper_Head", "Camper_Pompom"):
    me = bpy.data.objects[n].data
    bm = bmesh.new(); bm.from_mesh(me)
    degen = [f for f in bm.faces if f.calc_area() < 1e-10]
    keys = {}
    dup = 0
    for f in bm.faces:
        k = tuple(sorted(v.index for v in f.verts))
        dup += k in keys; keys[k] = 1
    loose = [v for v in bm.verts if not v.link_faces]
    nm = [e for e in bm.edges if not e.is_manifold]
    bm.free()
    before = len(me.polygons)
    changed = me.validate(verbose=False, clean_customdata=False)
    print(n, "| degenerate faces", len(degen), "| duplicate faces", dup, "| loose verts", len(loose), "| non-manifold edges", len(nm),
          "| validate fixed something:", changed, "| faces", before, "->", len(me.polygons))
    for p in me.polygons: p.use_smooth = False

# --- Call 26 --------------------------------------------------------------------------------------------------------
# Camper v2, call 26: the exporter dropped a few collapsed triangles from those three meshes (a face listing the same
# vertex twice, left by the decimate), which left small holes. Fill the holes, then save and export again.
import bpy, bmesh, os
for n in ("Camper_BeanieCuff", "Camper_Head", "Camper_Pompom"):
    me = bpy.data.objects[n].data
    bm = bmesh.new(); bm.from_mesh(me)
    bnd = [e for e in bm.edges if e.is_boundary]
    wire = [e for e in bm.edges if len(e.link_faces) > 2]
    res = bmesh.ops.holes_fill(bm, edges=bnd, sides=8)
    bmesh.ops.triangulate(bm, faces=res["faces"])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    left = [e for e in bm.edges if not e.is_manifold]
    bm.to_mesh(me); bm.free()
    for p in me.polygons: p.use_smooth = False
    print(n, "| boundary edges", len(bnd), "| edges with 3+ faces", len(wire), "| filled", len(res["faces"]), "| non-manifold left", len(left),
          "| valid:", not me.validate(verbose=False), "| tris", sum(len(f.vertices) - 2 for f in me.polygons))
parts = [o for o in bpy.data.objects if o.type == "MESH"]
print("all meshes valid:", all(not o.data.validate(verbose=False) for o in parts),
      "| total triangles", sum(len(f.vertices) - 2 for o in parts for f in o.data.polygons))
bpy.ops.wm.save_mainfile()
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("exported", out, os.path.getsize(out), "bytes")

# --- Measuring only, after call 26 ----------------------------------------------------------------------------------
# Camper v2, measuring only: the final fit and the lit side-by-side of the finished model (renders to %TEMP%\raccoon_v2).
import bpy
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
exec(bpy.data.texts["camper2_parts"].as_string().split("# --- jeans")[0])
L3 = {"pompom": (0, 0.072, 1.80), "nose": (0, -0.140, 1.527), "chin": (0, -0.103, 1.445), "cuff_bot": (0, -0.121, 1.641),
      "fold": (0, -0.106, 1.705), "flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226),
      "pockR_bot": (-0.125, -0.143, 1.135), "pockL_bot": (0.125, -0.143, 1.135), "lowL_top": (0.13, -0.143, 0.99),
      "hemR_in": (-0.042, -0.142, 0.77), "hemL_in": (0.042, -0.142, 0.77), "slvR": (-0.254, -0.008, 0.805),
      "slvL": (0.254, -0.008, 0.805), "jcR": (-0.113, -0.067, 0.19), "jcL": (0.113, -0.067, 0.19), "tee": (0, -0.08, 1.395),
      "handR": (-0.236, 0.01, 0.645), "handL": (0.236, 0.01, 0.645)}
for z in (0.784, 0.884, 1.016, 1.136):
    L3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z)
OUT = "camper_v2_final_overlay.png"
exec(open(TOOLS + r"\fit.py", encoding="utf-8").read())
OUT, BOX, SCALE = "camper_v2_final_sbs.png", (880, 200, 1440, 1680), 0.5
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())

# --- Measuring only, after call 26 ----------------------------------------------------------------------------------
# Camper v2, measuring only: how far is his head turned in the reference? Fit the camera to the body's landmarks
# alone, then solve the head's turn, nod and tilt (about his neck, at 1.40 m) from the head's five landmarks.
import bpy, os, numpy as np
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
ns = {}; exec(open(os.path.join(T, "solve.py"), encoding="utf-8").read(), ns)
exec(bpy.data.texts["camper2_parts"].as_string().split("# --- jeans")[0])
BODY3 = {"flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226), "pockR_bot": (-0.125, -0.143, 1.135),
         "pockL_bot": (0.125, -0.143, 1.135), "lowL_top": (0.13, -0.143, 0.99), "hemR_in": (-0.042, -0.142, 0.77),
         "hemL_in": (0.042, -0.142, 0.77), "slvR": (-0.254, -0.008, 0.805), "slvL": (0.254, -0.008, 0.805),
         "jcR": (-0.113, -0.067, 0.19), "jcL": (0.113, -0.067, 0.19), "tee": (0, -0.08, 1.395),
         "handR": (-0.236, 0.01, 0.645), "handL": (0.236, 0.01, 0.645)}
BODY2 = {"flapR": (1015, 705), "flapL": (1177, 725), "pockR_bot": (1015, 775), "pockL_bot": (1177, 793), "lowL_top": (1190, 900),
         "hemR_in": (1060, 1045), "hemL_in": (1112, 1060), "slvR": (955, 978), "slvL": (1320, 1025), "jcR": (1068, 1453),
         "jcL": (1223, 1485), "tee": (1105, 588), "handR": (965, 1090), "handL": (1290, 1140)}
for z, v in zip((0.784, 0.884, 1.016, 1.136), (1035, 960, 862, 772)):
    BODY3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z); BODY2["btn%.0f" % (z * 1000)] = (1048 if z < 0.9 else 1050, v)
HEAD3 = {"pompom": (0, 0.072, 1.80), "nose": (0, -0.140, 1.527), "chin": (0, -0.103, 1.445), "cuff_bot": (0, -0.121, 1.641),
         "fold": (0, -0.106, 1.705)}
HEAD2 = {"pompom": (1165, 280), "nose": (1074, 485), "chin": (1117, 550), "cuff_bot": (1087, 411), "fold": (1087, 359)}
kb = list(BODY2)
p, res = ns["solve_cam"](np.array([BODY3[k] for k in kb]), np.array([BODY2[k] for k in kb], float))
print("body-only camera: rms %.1f px" % np.sqrt((np.linalg.norm(res, axis=1) ** 2).mean()))
kh = list(HEAD2)
H3 = np.array([HEAD3[k] for k in kh]); H2 = np.array([HEAD2[k] for k in kh], float)
pivot = np.array([0, 0.01, 1.40])
def rot(a):
    cz, sz, cx, sx, cy, sy = np.cos(a[0]), np.sin(a[0]), np.cos(a[1]), np.sin(a[1]), np.cos(a[2]), np.sin(a[2])
    Rz = np.array([[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]); Rx = np.array([[1, 0, 0], [0, cx, -sx], [0, sx, cx]])
    Ry = np.array([[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]])
    return Rz @ Rx @ Ry
def resid(a):
    X = (H3 - pivot) @ rot(a).T + pivot
    return (ns["project"](p, X) - H2).ravel()
print("head as built:", " ".join("%s(%+.0f,%+.0f)" % (k, *r) for k, r in zip(kh, resid(np.zeros(3)).reshape(-1, 2))),
      "| rms %.1f" % np.sqrt((resid(np.zeros(3)) ** 2).reshape(-1, 2).sum(1).mean()))
for free in ((0,), (0, 1, 2)):
    a = np.zeros(3)
    for _ in range(50):
        r = resid(a); J = np.zeros((r.size, 3))
        for i in free:
            d = np.zeros(3); d[i] = 1e-6; J[:, i] = (resid(a + d) - r) / 1e-6
        step = np.linalg.lstsq(J, -r, rcond=None)[0]; a += step
        if np.linalg.norm(step) < 1e-9: break
    r = resid(a).reshape(-1, 2)
    print("free", free, "| turn %.1f deg (negative = to his right), nod %.1f, tilt %.1f" % tuple(np.degrees(a)),
          "| rms %.1f px |" % np.sqrt((r ** 2).sum(1).mean()), " ".join("%s(%+.0f,%+.0f)" % (k, *v) for k, v in zip(kh, r)))

# --- Measuring only, after call 26: the open file, after the connection dropped (the lost call changed nothing) -----
import bpy
s = bpy.data.texts["camper2_parts"].as_string() if "camper2_parts" in bpy.data.texts else ""
print("file:", bpy.data.filepath, "| dirty:", bpy.data.is_dirty, "| objects:", len(bpy.data.objects))
print("head_turn in parts:", "head_turn" in s, "| HEAD_PARTS in parts:", "HEAD_PARTS" in s, "| crown_top=1.78:", "crown_top=1.78," in s)
import re
m = re.search(r"head_turn=[^,]*, head_nod=[^,]*, head_tilt=[^)]*\)", s); print(m.group(0) if m else None)

# --- Call 27 --------------------------------------------------------------------------------------------------------
# Camper v2, call 27: reopen camper.blend (the connection dropped and Blender came back with camper_v1.blend open,
# unchanged); nothing from the dropped call had been applied.
import bpy
assert not bpy.data.is_dirty
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\characters\camper.blend")
s = bpy.data.texts["camper2_parts"].as_string()
print(bpy.data.filepath, "| objects", len(bpy.data.objects), "| head_turn yet:", "head_turn" in s)

# --- Call 28 --------------------------------------------------------------------------------------------------------
# Camper v2, call 28: his head turned like the reference's. The head's parts (head, nose, hair, beanie) are built facing
# forward as before, then turned about his neck (1.40 m) by P's head_turn / head_nod / head_tilt. Before solving those:
# the nose further forward and a little higher, the chin a touch further back, and the pompom lower on a lower crown
# (it sat 3-4 cm above the reference's). This call edits the builders and solves the angles; call 29 builds.
import bpy, os, numpy as np
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('crown_top=1.80, beanie_tilt=math.radians(13), pom_r=0.047)',
     'crown_top=1.78, beanie_tilt=math.radians(13), pom_r=0.047,\n         head_turn=0.0, head_nod=0.0, head_tilt=0.0)')
swap('r = P["pom_r"]; zc = P["crown_top"] + r * 0.6', 'r = P["pom_r"]; zc = P["crown_top"] + r * 0.15')
swap('(1.445, -0.012, 0.074, 0.091)', '(1.445, -0.008, 0.074, 0.088)')
swap('''    v = [bm.verts.new(p) for p in [(0, -0.100, 1.580), (-0.021, -0.101, 1.521), (0.021, -0.101, 1.521), (0, -0.140, 1.527),
                                    (0, -0.096, 1.514)]]''',
     '''    v = [bm.verts.new(p) for p in [(0, -0.100, 1.588), (-0.022, -0.101, 1.527), (0.022, -0.101, 1.527), (0, -0.150, 1.535),
                                    (0, -0.096, 1.519)]]''')
swap('''def build_all(only=None):
    g = globals()
    for nm, fn, mk, fc, vx, rl in SHELLS:
        if only is None or nm in only:
            shell(nm, g[fn], mk, faces=fc, voxel=vx, relax=rl)''',
     '''HEAD_PARTS = ("Camper_Head", "Camper_Nose", "Camper_Hair", "Camper_BeanieCuff", "Camper_BeanieCrown", "Camper_Pompom")
def head_matrix():
    """His head turned about the neck: turn (about Z, negative = to his right), nod (about X), tilt (about Y)."""
    pv = Vector((0, 0.01, 1.40))
    return (Matrix.Translation(pv) @ Matrix.Rotation(P["head_turn"], 4, "Z") @ Matrix.Rotation(P["head_nod"], 4, "X")
            @ Matrix.Rotation(P["head_tilt"], 4, "Y") @ Matrix.Translation(-pv))
def turn_head(nm):
    if nm in HEAD_PARTS:
        me = bpy.data.objects[nm].data; me.transform(head_matrix()); me.update()
def build_all(only=None):
    g = globals()
    for nm, fn, mk, fc, vx, rl in SHELLS:
        if only is None or nm in only:
            shell(nm, g[fn], mk, faces=fc, voxel=vx, relax=rl); turn_head(nm)''')
swap('''            plain(nm, g[fn], mk)
''', '''            plain(nm, g[fn], mk); turn_head(nm)
''')
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)

# --- the camera from the body's landmarks alone, then the head's angles from its own five -------------------------
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
ns = {}; exec(open(os.path.join(T, "solve.py"), encoding="utf-8").read(), ns)
BODY3 = {"flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226), "pockR_bot": (-0.125, -0.143, 1.135),
         "pockL_bot": (0.125, -0.143, 1.135), "lowL_top": (0.13, -0.143, 0.99), "hemR_in": (-0.042, -0.142, 0.77),
         "hemL_in": (0.042, -0.142, 0.77), "slvR": (-0.254, -0.008, 0.805), "slvL": (0.254, -0.008, 0.805),
         "jcR": (-0.113, -0.067, 0.19), "jcL": (0.113, -0.067, 0.19), "tee": (0, -0.08, 1.395),
         "handR": (-0.236, 0.01, 0.645), "handL": (0.236, 0.01, 0.645)}
BODY2 = {"flapR": (1015, 705), "flapL": (1177, 725), "pockR_bot": (1015, 775), "pockL_bot": (1177, 793), "lowL_top": (1190, 900),
         "hemR_in": (1060, 1045), "hemL_in": (1112, 1060), "slvR": (955, 978), "slvL": (1320, 1025), "jcR": (1068, 1453),
         "jcL": (1223, 1485), "tee": (1105, 588), "handR": (965, 1090), "handL": (1290, 1140)}
for z, v in zip((0.784, 0.884, 1.016, 1.136), (1035, 960, 862, 772)):
    BODY3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z); BODY2["btn%.0f" % (z * 1000)] = (1048 if z < 0.9 else 1050, v)
kb = list(BODY2)
pc, _ = ns["solve_cam"](np.array([BODY3[k] for k in kb]), np.array([BODY2[k] for k in kb], float))
def Rz(a): return np.array([[np.cos(a), -np.sin(a), 0], [np.sin(a), np.cos(a), 0], [0, 0, 1]])
def Rx(a): return np.array([[1, 0, 0], [0, np.cos(a), -np.sin(a)], [0, np.sin(a), np.cos(a)]])
def Ry(a): return np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]])
bp = np.array([0, 0.008, P["cuff_bot"]])
def tilted(p):   # a point on the upright beanie, tipped back as tilt_back() does
    return tuple(Rx(-P["beanie_tilt"]) @ (np.array(p) - bp) + bp)
HEAD3 = {"pompom": tilted((0, 0.03, P["crown_top"] + 0.15 * P["pom_r"])), "nose": (0, -0.150, 1.535), "chin": (0, -0.097, 1.445),
         "cuff_bot": tilted((0, 0.008 - 0.133, P["cuff_bot"] + 0.004)), "fold": tilted((0, 0.008 - 0.133, P["cuff_top"]))}
HEAD2 = {"pompom": (1165, 280), "nose": (1074, 485), "chin": (1117, 550), "cuff_bot": (1087, 411), "fold": (1087, 359)}
kh = list(HEAD2); H3 = np.array([HEAD3[k] for k in kh]); H2 = np.array([HEAD2[k] for k in kh], float)
pv = np.array([0, 0.01, 1.40])
def resid(a):
    R = Rz(a[0]) @ Rx(a[1]) @ Ry(a[2])
    return (ns["project"](pc, (H3 - pv) @ R.T + pv) - H2).ravel()
a = np.zeros(3)
for _ in range(60):
    r = resid(a); J = np.zeros((r.size, 3))
    for i in range(3):
        d = np.zeros(3); d[i] = 1e-6; J[:, i] = (resid(a + d) - r) / 1e-6
    step = np.linalg.lstsq(J, -r, rcond=None)[0]; a += step
    if np.linalg.norm(step) < 1e-10: break
r0, r1 = resid(np.zeros(3)).reshape(-1, 2), resid(a).reshape(-1, 2)
print("facing forward: rms %.1f px | turned: rms %.1f px" % (np.sqrt((r0 ** 2).sum(1).mean()), np.sqrt((r1 ** 2).sum(1).mean())))
print("turn %.1f deg to his right, nod %.1f deg down, tilt %.1f deg (top to his left)" % (-np.degrees(a[0]), np.degrees(a[1]), np.degrees(a[2])))
print(" ".join("%s(%+.0f,%+.0f)" % (k, *v) for k, v in zip(kh, r1)))
s = s.replace("head_turn=0.0, head_nod=0.0, head_tilt=0.0)", "head_turn=%.4f, head_nod=%.4f, head_tilt=%.4f)" % tuple(float(x) for x in a))
t.clear(); t.write(s)
print([l.strip() for l in s.splitlines() if "head_turn=" in l])

# --- Call 29 --------------------------------------------------------------------------------------------------------
# Camper v2, call 29: re-solve the head's angles without the chin. The reference's "chin" point is the lowest edge of its
# jaw in a three-quarter view, further back than the chin tip used for the model, so it wasn't the same feature.
import bpy, os, numpy as np
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
ns = {}; exec(open(os.path.join(T, "solve.py"), encoding="utf-8").read(), ns)
BODY3 = {"flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226), "pockR_bot": (-0.125, -0.143, 1.135),
         "pockL_bot": (0.125, -0.143, 1.135), "lowL_top": (0.13, -0.143, 0.99), "hemR_in": (-0.042, -0.142, 0.77),
         "hemL_in": (0.042, -0.142, 0.77), "slvR": (-0.254, -0.008, 0.805), "slvL": (0.254, -0.008, 0.805),
         "jcR": (-0.113, -0.067, 0.19), "jcL": (0.113, -0.067, 0.19), "tee": (0, -0.08, 1.395),
         "handR": (-0.236, 0.01, 0.645), "handL": (0.236, 0.01, 0.645)}
BODY2 = {"flapR": (1015, 705), "flapL": (1177, 725), "pockR_bot": (1015, 775), "pockL_bot": (1177, 793), "lowL_top": (1190, 900),
         "hemR_in": (1060, 1045), "hemL_in": (1112, 1060), "slvR": (955, 978), "slvL": (1320, 1025), "jcR": (1068, 1453),
         "jcL": (1223, 1485), "tee": (1105, 588), "handR": (965, 1090), "handL": (1290, 1140)}
for z, v in zip((0.784, 0.884, 1.016, 1.136), (1035, 960, 862, 772)):
    BODY3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z); BODY2["btn%.0f" % (z * 1000)] = (1048 if z < 0.9 else 1050, v)
kb = list(BODY2)
pc, _ = ns["solve_cam"](np.array([BODY3[k] for k in kb]), np.array([BODY2[k] for k in kb], float))
def Rz(a): return np.array([[np.cos(a), -np.sin(a), 0], [np.sin(a), np.cos(a), 0], [0, 0, 1]])
def Rx(a): return np.array([[1, 0, 0], [0, np.cos(a), -np.sin(a)], [0, np.sin(a), np.cos(a)]])
def Ry(a): return np.array([[np.cos(a), 0, np.sin(a)], [0, 1, 0], [-np.sin(a), 0, np.cos(a)]])
bp = np.array([0, 0.008, P["cuff_bot"]])
def tilted(p): return tuple(Rx(-P["beanie_tilt"]) @ (np.array(p) - bp) + bp)
HEAD3 = {"pompom": tilted((0, 0.03, P["crown_top"] + 0.15 * P["pom_r"])), "nose": (0, -0.150, 1.535),
         "cuff_bot": tilted((0, 0.008 - 0.133, P["cuff_bot"] + 0.004)), "fold": tilted((0, 0.008 - 0.133, P["cuff_top"]))}
HEAD2 = {"pompom": (1165, 280), "nose": (1074, 485), "cuff_bot": (1087, 411), "fold": (1087, 359)}
kh = list(HEAD2); H3 = np.array([HEAD3[k] for k in kh]); H2 = np.array([HEAD2[k] for k in kh], float)
pv = np.array([0, 0.01, 1.40])
def resid(a):
    R = Rz(a[0]) @ Rx(a[1]) @ Ry(a[2])
    return (ns["project"](pc, (H3 - pv) @ R.T + pv) - H2).ravel()
a = np.zeros(3)
for _ in range(60):
    r = resid(a); J = np.zeros((r.size, 3))
    for i in range(3):
        d = np.zeros(3); d[i] = 1e-6; J[:, i] = (resid(a + d) - r) / 1e-6
    step = np.linalg.lstsq(J, -r, rcond=None)[0]; a += step
    if np.linalg.norm(step) < 1e-10: break
r1 = resid(a).reshape(-1, 2)
print("turn %.1f deg to his right, nod %.1f deg down, tilt %.1f deg (top to his left) | rms %.1f px" % (
    -np.degrees(a[0]), np.degrees(a[1]), np.degrees(a[2]), np.sqrt((r1 ** 2).sum(1).mean())))
print(" ".join("%s(%+.0f,%+.0f)" % (k, *v) for k, v in zip(kh, r1)))
import re
s = re.sub(r"head_turn=[-0-9.]+, head_nod=[-0-9.]+, head_tilt=[-0-9.]+\)", "head_turn=%.4f, head_nod=%.4f, head_tilt=%.4f)" % tuple(float(x) for x in a), s)
t.clear(); t.write(s)
print([l.strip() for l in s.splitlines() if "head_turn=" in l])

# --- Call 30 --------------------------------------------------------------------------------------------------------
# Camper v2, call 30: build the head's parts with the new nose, chin and pompom, turned 9 deg to his right, nodded 1.5 deg
# and tilted 2.7 deg (call 29's angles).
import bpy
exec(bpy.data.texts["camper2_lib"].as_string()); exec(bpy.data.texts["camper2_parts"].as_string())
build_all(list(HEAD_PARTS))
report(list(HEAD_PARTS))
print("total triangles", sum(sum(len(f.vertices) - 2 for f in o.data.polygons) for o in bpy.data.objects if o.type == "MESH"))

# --- Measuring only, after call 30 ----------------------------------------------------------------------------------
# Camper v2, measuring only: refit RefCam to the body's landmarks alone (the head's are now turned), then the overlay
# and the lit side-by-sides of the whole figure and the head.
import bpy
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
exec(bpy.data.texts["camper2_parts"].as_string().split("# --- jeans")[0])
L3 = {"flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226), "pockR_bot": (-0.125, -0.143, 1.135),
      "pockL_bot": (0.125, -0.143, 1.135), "lowL_top": (0.13, -0.143, 0.99), "hemR_in": (-0.042, -0.142, 0.77),
      "hemL_in": (0.042, -0.142, 0.77), "slvR": (-0.254, -0.008, 0.805), "slvL": (0.254, -0.008, 0.805),
      "jcR": (-0.113, -0.067, 0.19), "jcL": (0.113, -0.067, 0.19), "tee": (0, -0.08, 1.395),
      "handR": (-0.236, 0.01, 0.645), "handL": (0.236, 0.01, 0.645)}
for z in (0.784, 0.884, 1.016, 1.136):
    L3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z)
OUT = "camper_v2_turned_overlay.png"
exec(open(TOOLS + r"\fit.py", encoding="utf-8").read())
OUT, BOX, SCALE = "camper_v2_turned_sbs.png", (880, 200, 1440, 1680), 0.5
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())
OUT, BOX, SCALE = "camper_v2_turned_head.png", (990, 230, 1330, 640), 1.0
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())

# --- Call 31 --------------------------------------------------------------------------------------------------------
# Camper v2, call 31: check, save and export the turned head (as in call 24), repairing any mesh the exporter would flag.
import bpy, os
parts = sorted((o for o in bpy.data.objects if o.type == "MESH"), key=lambda o: o.name)
fixed = [o.name for o in parts if o.data.validate(verbose=False)]
for o in parts:
    for p in o.data.polygons: p.use_smooth = False
pts = [v.co for o in parts for v in o.data.vertices]
lo = [min(p[i] for p in pts) for i in range(3)]; hi = [max(p[i] for p in pts) for i in range(3)]
print("parts", len(parts), "| meshes validate() had to fix:", fixed, "| size %.3f x %.3f x %.3f m" % tuple(hi[i] - lo[i] for i in range(3)),
      "| bottom Z %.4f | triangles %d" % (lo[2], sum(len(f.vertices) - 2 for o in parts for f in o.data.polygons)))
bpy.ops.wm.save_mainfile()
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("saved", bpy.data.filepath, "| exported", out, os.path.getsize(out), "bytes")

# --- Call 32 --------------------------------------------------------------------------------------------------------
# Camper v2, call 32: back to camper.blend (beanie_dropped.blend was open and saved; the first try at the jaw and neck
# stopped on its file check before changing anything).
import bpy
assert not bpy.data.is_dirty, bpy.data.filepath
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\characters\camper.blend")
print(bpy.data.filepath, "| objects", len(bpy.data.objects), "| head turn set:", "head_turn=-0.1563" in bpy.data.texts["camper2_parts"].as_string())

# --- Call 33 --------------------------------------------------------------------------------------------------------
# Camper v2, call 33: from my look at the turned head ("no chin no neck like in therefernece"). The reference's face ends
# in a clear jaw edge that slopes up from a chin to below the ear, with a neck showing between it and the hood. So:
# the head's underside is cut flat along that jaw line, with a small chin at its point and the jaw narrowing towards
# it; the neck is its own part (fused into the head it smoothed away); and the hood opens wider and sits lower at the
# front, with the T-shirt's V lower, so the neck shows under the chin.
import bpy
assert bpy.data.filepath.endswith(r"assets\characters\camper.blend"), bpy.data.filepath
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('''HEAD = [(1.36, 0.010, 0.052, 0.052), (1.41, 0.014, 0.058, 0.060), (1.428, -0.006, 0.050, 0.082), (1.445, -0.008, 0.074, 0.088),
        (1.47, -0.010, 0.090, 0.100),''',
     '''HEAD = [(1.415, -0.010, 0.076, 0.094), (1.445, -0.010, 0.082, 0.098),
        (1.47, -0.010, 0.092, 0.101),''')
swap('''    loft(bm, [sring(0, cy, z, rx, ry, n=28, p=2.5) for z, cy, rx, ry in HEAD])''',
     '''    rings = []
    for z, cy, rx, ry in HEAD:
        k = 0.38 if z < 1.46 else (0.2 if z < 1.49 else 0.0)        # the jaw narrows towards the chin
        ring = sring(0, cy, z, rx, ry, n=28, p=2.5)
        for p in ring:
            p.x *= 1 - k * max(0.0, cy - p.y) / ry
        rings.append(ring)
    loft(bm, rings)
    loft(bm, [hring(0, -0.097, 1.452 + 0.022 * f, 0.032 * w, 0.020 * w, 10) for f, w in      # the chin
              [(-0.9, 0.45), (-0.5, 0.85), (0, 1.0), (0.5, 0.85), (0.9, 0.45)]])
    for v in bm.verts:                       # the jaw: a plane from the chin (y -0.10, 1.435 m) up to below the ear
        v.co.z = max(v.co.z, JAW_Z + (v.co.y + 0.10) * JAW_SLOPE)
JAW_Z, JAW_SLOPE = 1.435, 0.54
def build_neck(bm):
    loft(bm, [hring(0, -0.004, z, 0.050, 0.048, 12) for z in (1.33, 1.42, 1.50)])''')
swap('("Camper_Head", "build_head", "skin", 110, 0.007, 2)',
     '("Camper_Head", "build_head", "skin", 110, 0.007, 2), ("Camper_Neck", "build_neck", "skin", 30, 0.007, 2)')
swap('''        a = math.radians(-65 + 310 * k / 14)''', '''        a = math.radians(-42 + 264 * k / 14)''')
swap('''        pts.append((0.108 * math.cos(a), 0.014 + 0.100 * math.sin(a), 1.405 + 0.06 * b))''',
     '''        pts.append((0.108 * math.cos(a), 0.014 + 0.100 * math.sin(a), 1.385 + 0.08 * b))''')
swap('''    loft(bm, [hring(0, -0.07, z, rx, 0.016, 8) for z, rx in [(1.345, 0.012), (1.375, 0.03), (1.42, 0.042)]])''',
     '''    loft(bm, [hring(0, -0.068, z, rx, 0.016, 8) for z, rx in [(1.33, 0.012), (1.365, 0.032), (1.398, 0.048)]])''')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Head", "Camper_Neck", "Camper_Hood", "Camper_TShirt"])
report(["Camper_Head", "Camper_Neck", "Camper_Hood", "Camper_TShirt"])

# --- Measuring only, after call 33 ----------------------------------------------------------------------------------
# Camper v2, measuring only: the head close-up beside the reference, lit, and a closer look from the front and side.
import bpy
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_jaw_head.png", (990, 230, 1330, 640), 1.0
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())

# --- Call 34 --------------------------------------------------------------------------------------------------------
# Camper v2, call 34: the jacket's top was a lid at 1.415 m, in front of the neck, so from the reference's camera its
# brown top hid the neck and T-shirt under the chin. It now closes lower (1.365 m) round the neck. The reference's jaw is
# also broader than call 33's: less narrowing towards a wider chin.
import bpy
assert bpy.data.filepath.endswith(r"assets\characters\camper.blend"), bpy.data.filepath
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('''             (1.29, 0.193, 0.131), (1.34, 0.170, 0.119), (1.385, 0.135, 0.104)]''',
     '''             (1.29, 0.193, 0.131), (1.34, 0.170, 0.119)]''')
swap('''             [sring(0, 0.0, 1.415, 0.100, 0.085)])''', '''             [sring(0, 0.0, 1.365, 0.120, 0.095)])''')
swap('''        k = 0.38 if z < 1.46 else (0.2 if z < 1.49 else 0.0)        # the jaw narrows towards the chin''',
     '''        k = 0.22 if z < 1.46 else (0.1 if z < 1.49 else 0.0)        # the jaw narrows towards the chin''')
swap('''    loft(bm, [hring(0, -0.097, 1.452 + 0.022 * f, 0.032 * w, 0.020 * w, 10) for f, w in      # the chin''',
     '''    loft(bm, [hring(0, -0.097, 1.452 + 0.022 * f, 0.042 * w, 0.020 * w, 10) for f, w in      # the chin''')
swap('''    loft(bm, [hring(0, -0.068, z, rx, 0.016, 8) for z, rx in [(1.33, 0.012), (1.365, 0.032), (1.398, 0.048)]])''',
     '''    loft(bm, [hring(0, -0.060, z, rx, 0.012, 8) for z, rx in [(1.34, 0.012), (1.37, 0.030), (1.40, 0.046)]])''')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Jacket", "Camper_Head", "Camper_TShirt"])
report(["Camper_Jacket", "Camper_Head", "Camper_TShirt", "Camper_Collar"])
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_jaw2_head.png", (990, 230, 1330, 640), 1.0
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())

# --- Call 35 --------------------------------------------------------------------------------------------------------
# Camper v2, call 35: the neck forward and wider (the chin hid it: its front was 6.6 cm behind the chin's), the jaw
# 7 mm higher, the T-shirt's V a little lower, so the neck shows between them as in the reference. The collar's top
# corners were above call 34's lower jacket, so their rays missed it and those points fell to the origin: the collar
# now stops below the jacket's top, and a miss stops the build instead of passing.
import bpy
assert bpy.data.filepath.endswith(r"assets\characters\camper.blend"), bpy.data.filepath
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('''    loft(bm, [hring(0, -0.004, z, 0.050, 0.048, 12) for z in (1.33, 1.42, 1.50)])''',
     '''    loft(bm, [hring(0, -0.018, z, 0.054, 0.050, 12) for z in (1.33, 1.42, 1.50)])''')
swap('JAW_Z, JAW_SLOPE = 1.435, 0.54', 'JAW_Z, JAW_SLOPE = 1.442, 0.54')
swap('''    loft(bm, [hring(0, -0.060, z, rx, 0.012, 8) for z, rx in [(1.34, 0.012), (1.37, 0.030), (1.40, 0.046)]])''',
     '''    loft(bm, [hring(0, -0.063, z, rx, 0.012, 8) for z, rx in [(1.33, 0.012), (1.36, 0.030), (1.388, 0.048)]])''')
swap('''        c = [(s * (w + 0.006), 1.290), (s * (w + 0.018), 1.282), (s * 0.135, 1.356), (s * (w + 0.016), 1.392)]''',
     '''        c = [(s * (w + 0.006), 1.270), (s * (w + 0.018), 1.262), (s * 0.135, 1.335), (s * (w + 0.016), 1.352)]''')
swap('''    ok, loc, nor, idx = bpy.data.objects["Camper_Jacket"].ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)))
    return loc''', '''    ok, loc, nor, idx = bpy.data.objects["Camper_Jacket"].ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)))
    assert ok, ("missed the jacket", x, z)
    return loc''')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Neck", "Camper_Head", "Camper_TShirt", "Camper_Collar"])
report(["Camper_Neck", "Camper_Head", "Camper_TShirt", "Camper_Collar"])
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_jaw3_head.png", (990, 230, 1330, 640), 1.0
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())

# --- Call 36 --------------------------------------------------------------------------------------------------------
# Camper v2, call 36: beside the reference (call 35's close-up) the face was about 10% too long and a little narrow:
# the jaw and chin 1.4 cm higher (more neck shows), and the cheeks and temples 4-5 mm wider.
import bpy
assert bpy.data.filepath.endswith(r"assets\characters\camper.blend"), bpy.data.filepath
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('''HEAD = [(1.415, -0.010, 0.076, 0.094), (1.445, -0.010, 0.082, 0.098),
        (1.47, -0.010, 0.092, 0.101), (1.51, -0.006, 0.101, 0.105), (1.55, -0.003, 0.107, 0.108), (1.60, 0.004, 0.110, 0.108),
        (1.64, 0.010, 0.108, 0.102),''',
     '''HEAD = [(1.43, -0.010, 0.080, 0.094), (1.46, -0.010, 0.088, 0.098),
        (1.485, -0.010, 0.097, 0.101), (1.52, -0.006, 0.106, 0.105), (1.56, -0.003, 0.112, 0.108), (1.60, 0.004, 0.114, 0.108),
        (1.64, 0.010, 0.111, 0.102),''')
swap('''        k = 0.22 if z < 1.46 else (0.1 if z < 1.49 else 0.0)        # the jaw narrows towards the chin''',
     '''        k = 0.22 if z < 1.475 else (0.1 if z < 1.50 else 0.0)       # the jaw narrows towards the chin''')
swap('''    loft(bm, [hring(0, -0.097, 1.452 + 0.022 * f,''', '''    loft(bm, [hring(0, -0.097, 1.466 + 0.022 * f,''')
swap('JAW_Z, JAW_SLOPE = 1.442, 0.54', 'JAW_Z, JAW_SLOPE = 1.456, 0.54')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Head"])
report(["Camper_Head", "Camper_BeanieCuff", "Camper_Hair"])
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_jaw4_head.png", (990, 230, 1330, 640), 1.0
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())

# --- Call 37 --------------------------------------------------------------------------------------------------------
# Camper v2, call 37: beside the reference (call 36), the neck showed a little long and thin and the lower face narrowed
# too much: the jaw fuller (less narrowing), the neck a touch wider, and the T-shirt's V and the hood's front 1 cm higher.
import bpy
assert bpy.data.filepath.endswith(r"assets\characters\camper.blend"), bpy.data.filepath
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('HEAD = [(1.43, -0.010, 0.080, 0.094), (1.46, -0.010, 0.088, 0.098),\n        (1.485, -0.010, 0.097, 0.101),',
     'HEAD = [(1.43, -0.010, 0.086, 0.094), (1.46, -0.010, 0.094, 0.098),\n        (1.485, -0.010, 0.102, 0.101),')
swap('''        k = 0.22 if z < 1.475 else (0.1 if z < 1.50 else 0.0)       # the jaw narrows towards the chin''',
     '''        k = 0.14 if z < 1.475 else (0.06 if z < 1.50 else 0.0)      # the jaw narrows towards the chin''')
swap('''    loft(bm, [hring(0, -0.018, z, 0.054, 0.050, 12) for z in (1.33, 1.42, 1.50)])''',
     '''    loft(bm, [hring(0, -0.018, z, 0.058, 0.052, 12) for z in (1.33, 1.42, 1.50)])''')
swap('''        pts.append((0.108 * math.cos(a), 0.014 + 0.100 * math.sin(a), 1.385 + 0.08 * b))''',
     '''        pts.append((0.108 * math.cos(a), 0.014 + 0.100 * math.sin(a), 1.395 + 0.075 * b))''')
swap('''    loft(bm, [hring(0, -0.063, z, rx, 0.012, 8) for z, rx in [(1.33, 0.012), (1.36, 0.030), (1.388, 0.048)]])''',
     '''    loft(bm, [hring(0, -0.064, z, rx, 0.012, 8) for z, rx in [(1.34, 0.012), (1.37, 0.030), (1.398, 0.050)]])''')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Head", "Camper_Neck", "Camper_Hood", "Camper_TShirt"])
report(["Camper_Head", "Camper_Neck", "Camper_Hood", "Camper_TShirt"])
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_jaw5_head.png", (990, 230, 1330, 640), 1.0
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())

# --- Call 38 --------------------------------------------------------------------------------------------------------
# Camper v2, call 38: call 35's wider opening split the hood into two lumps beside the neck, floating above the lowered
# jacket. The hood is one collar again, open only in a V at the front (60 deg), sitting on the jacket's top: its front
# ends low and thin, its sides and back fuller and higher.
import bpy
assert bpy.data.filepath.endswith(r"assets\characters\camper.blend"), bpy.data.filepath
t = bpy.data.texts["camper2_parts"]; s = t.as_string()
def swap(old, new):
    global s
    assert s.count(old) == 1, old[:70]
    s = s.replace(old, new)
swap('''        a = math.radians(-42 + 264 * k / 14)
        b = (math.sin(a) + 1) / 2
        pts.append((0.108 * math.cos(a), 0.014 + 0.100 * math.sin(a), 1.395 + 0.075 * b))
        r = 0.030 + 0.026 * b''',
     '''        a = math.radians(-60 + 300 * k / 14)
        b = (math.sin(a) + 1) / 2
        pts.append((0.106 * math.cos(a), 0.010 + 0.098 * math.sin(a), 1.39 + 0.045 * b))
        r = 0.026 + 0.028 * b''')
t.clear(); t.write(s)
exec(bpy.data.texts["camper2_lib"].as_string()); exec(s)
build_all(["Camper_Hood"])
report(["Camper_Hood", "Camper_Jacket", "Camper_Neck", "Camper_TShirt"])

# --- Measuring only, after call 38 ----------------------------------------------------------------------------------
# Camper v2, measuring only: the lit side-by-sides (whole figure and head) after the jaw, neck and hood changes.
import bpy
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
OUT, BOX, SCALE = "camper_v2_neck_sbs.png", (880, 200, 1440, 1680), 0.5
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())
OUT, BOX, SCALE = "camper_v2_neck_head.png", (990, 230, 1330, 640), 1.0
exec(open(TOOLS + r"\lit.py", encoding="utf-8").read())

# --- Call 39 --------------------------------------------------------------------------------------------------------
# Camper v2, call 39: check, save and export (as in call 31), and the overlay of the finished model on the reference.
import bpy, os
assert bpy.data.filepath.endswith(r"assets\characters\camper.blend"), bpy.data.filepath
parts = sorted((o for o in bpy.data.objects if o.type == "MESH"), key=lambda o: o.name)
fixed = [o.name for o in parts if o.data.validate(verbose=False)]
for o in parts:
    for p in o.data.polygons: p.use_smooth = False
pts = [v.co for o in parts for v in o.data.vertices]
lo = [min(p[i] for p in pts) for i in range(3)]; hi = [max(p[i] for p in pts) for i in range(3)]
print("parts", len(parts), "| validate() fixed:", fixed, "| size %.3f x %.3f x %.3f m" % tuple(hi[i] - lo[i] for i in range(3)),
      "| bottom Z %.4f | triangles %d" % (lo[2], sum(len(f.vertices) - 2 for o in parts for f in o.data.polygons)))
bpy.ops.wm.save_mainfile()
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("saved", bpy.data.filepath, "| exported", out, os.path.getsize(out), "bytes")
TOOLS = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\camper\tools"
exec(bpy.data.texts["camper2_parts"].as_string().split("# --- jeans")[0])
L3 = {"flapR": (-0.125, -0.15, 1.226), "flapL": (0.125, -0.15, 1.226), "pockR_bot": (-0.125, -0.143, 1.135),
      "pockL_bot": (0.125, -0.143, 1.135), "lowL_top": (0.13, -0.143, 0.99), "hemR_in": (-0.042, -0.142, 0.77),
      "hemL_in": (0.042, -0.142, 0.77), "slvR": (-0.254, -0.008, 0.805), "slvL": (0.254, -0.008, 0.805),
      "jcR": (-0.113, -0.067, 0.19), "jcL": (0.113, -0.067, 0.19), "tee": (0, -0.08, 1.395),
      "handR": (-0.236, 0.01, 0.645), "handL": (0.236, 0.01, 0.645)}
for z in (0.784, 0.884, 1.016, 1.136):
    L3["btn%.0f" % (z * 1000)] = (-(opening(z) + 0.016), -0.142, z)
OUT = "camper_v2_neck_overlay.png"
exec(open(TOOLS + r"\fit.py", encoding="utf-8").read())
