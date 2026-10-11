# Builds the head in object "FaceWork" from the first raccoon's head (raccoon.blend's
# Head_Mesh and eyes, kept in raccoon_v2.blend's "Old model (guide)" collection),
# straightened and reshaped toward design/reference/raccoon/idle.jpg and standing.jpg:
# eyes, cheeks and nose moved by a two-view landmark solve, a longer snout, bigger eyes,
# a cream chin, a painted smile (two plane cuts through the muzzle), the back of the
# skull rounded into the neck, and forward-facing ear flaps traced from idle.jpg.
# Rebuilds from the old head every run. Parameters come in a FACE dict (build_all.py).
import bpy, bmesh, math
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

P = globals().get("FACE", {})
SNOUT_FWD = P.get("snout_fwd", 0.012)
SNOUT_NARROW = P.get("snout_narrow", 0.88)
EYE_SCALE = P.get("eye_scale", 1.3)
EYE_LIFT = P.get("eye_lift", 0.004)
EAR = P.get("ear", dict(base=(0.142, -0.381, 0.545), w=0.046, h=0.096, d=0.022, yaw=15, lean=-0.08))

H = bpy.data.objects["Head"]
S = Matrix.Rotation(-H.rotation_euler.z, 4, "Z")
MATS = ["R_Fur", "R_Cream", "R_Mask", "R_EarInner", "R_Black", "R_Nose", "R_Eye"]
FUR, CREAM, MASK, EARIN, BLACK, NOSE, EYE = range(7)

bm = bmesh.new()
for n in ["Head_Mesh", "Eye_L", "Eye_R"]:
    o = bpy.data.objects[n]
    me = o.data.copy()
    me.transform(S @ o.matrix_world)
    for p in me.polygons:
        p.material_index = MATS.index(me.materials[p.material_index].name)
    bm.from_mesh(me)
    bpy.data.meshes.remove(me)
bm.verts.ensure_lookup_table()


def mirror_pair(v):
    return [w for w in bm.verts if (Vector((-w.co.x, w.co.y, w.co.z)) - v.co).length < 1e-4 and w is not v]


def island_of(f0):
    seen, st = {f0}, [f0]
    while st:
        g = st.pop()
        for e in g.edges:
            for h in e.link_faces:
                if h not in seen:
                    seen.add(h)
                    st.append(h)
    return seen


head_faces = max((island_of(f) for f in bm.faces), key=len)
head_verts = {v for f in head_faces for v in f.verts}

# --- Snout: a little longer and narrower ----------------------------------------------
for v in head_verts:
    if v.co.y < -0.50:
        t = min((-0.50 - v.co.y) / 0.05, 1.0)
        v.co.y -= SNOUT_FWD * t
        v.co.x *= 1 - (1 - SNOUT_NARROW) * t
# Cheeks slightly narrower and further back, nose a little higher (two-view landmark solve).
CHEEK = P.get("cheek", (-0.009, 0.006, -0.007))
NOSE_UP = P.get("nose_up", 0.007)
for v in head_verts:
    if abs(v.co.x) > 0.15:
        t = min((abs(v.co.x) - 0.15) / 0.075, 1.0)
        sx = 1 if v.co.x > 0 else -1
        v.co += Vector((CHEEK[0] * sx * t, CHEEK[1] * t, CHEEK[2] * t))
    if v.co.y < -0.505:
        v.co.z += NOSE_UP * min((-0.505 - v.co.y) / 0.04, 1.0)
# Round off the flat back of the skull, so it slides into the neck fur without a ledge.
for v in head_verts:
    if v.co.y > -0.335 and v.co.z > 0.56:
        t = min((v.co.y + 0.335) / 0.02, 1.0)
        v.co.z -= 0.03 * t
        v.co.y -= 0.015 * t
# A deeper lower jaw under the smile.
for v in head_verts:
    if abs(v.co.x) < 1e-4 and abs(v.co.y + 0.519) < 0.004 and abs(v.co.z - 0.366) < 0.004:
        v.co.z -= 0.014
        v.co.y -= 0.004
    if abs(abs(v.co.x) - 0.030) < 0.004 and abs(v.co.y + 0.523) < 0.006 and abs(v.co.z - 0.380) < 0.004:
        v.co.z -= 0.008

# --- Eyes: bigger and a touch higher ----------------------------------------------------
for f0 in [f for f in bm.faces if f.material_index == EYE]:
    pass
eye_islands = []
done = set()
for f in bm.faces:
    if f.material_index == EYE and f not in done:
        isl = island_of(f)
        done |= isl
        eye_islands.append({v for g in isl for v in g.verts})
EYE_IN, EYE_BACK = P.get("eye_in", 0.006), P.get("eye_back", 0.005)
bm.normal_update()
_head_tree = BVHTree.FromPolygons([v.co.copy() for v in bm.verts], [[v.index for v in f.verts] for f in head_faces])
for vs in eye_islands:
    c = sum((v.co for v in vs), Vector()) / len(vs)
    sx = 1 if c.x > 0 else -1
    target = c + Vector((-EYE_IN * sx, EYE_BACK, EYE_LIFT))
    # Re-seat the eye on the face so it sits the same depth into the mask as before.
    depth = (c - _head_tree.find_nearest(c)[0]).length * (1 if True else 0)
    loc, nrm, _, _ = _head_tree.find_nearest(target)
    new_c = loc + nrm * depth * 0.6
    for v in vs:
        v.co = new_c + (v.co - c) * EYE_SCALE

# --- Chin: cream under the smile, like the references ------------------------------
for f in head_faces:
    c = f.calc_center_median()
    if f.material_index == FUR and c.y < -0.47 and c.z < 0.372:
        f.material_index = CREAM

# --- Smile, painted: two planes through the mouth corners (from idle.jpg) cut the
# muzzle faces; the wedge between them, thickest under the nose, is coloured dark.
SMILE = P.get("smile", dict(corner=(0.055, -0.497, 0.389), top=(0.0, -0.535, 0.383),
                            bottom=(0.0, -0.531, 0.371)))
if SMILE:
    cl = Vector(SMILE["corner"])
    cr = Vector((-cl.x, cl.y, cl.z))
    planes = []
    for key in ("top", "bottom"):
        f_pt = Vector(SMILE[key])
        nrm = (cr - cl).cross(f_pt - cl).normalized()
        if nrm.z < 0:
            nrm = -nrm
        planes.append(nrm)
    in_region = lambda co: co.y < cl.y + 0.004 and abs(co.x) < cl.x + 0.006 and co.z < 0.42
    for nrm in planes:
        geom = [v for v in bm.verts if v in head_verts or True]
        faces = [f for f in bm.faces if f in head_faces and in_region(f.calc_center_median())]
        edges = list({e for f in faces for e in f.edges})
        verts = list({v for f in faces for v in f.verts})
        res = bmesh.ops.bisect_plane(bm, geom=verts + edges + faces, plane_co=cl, plane_no=nrm)
        # New faces from the cut belong to the head too.
        head_faces = set(head_faces) | {f for g in res["geom"] if isinstance(g, bmesh.types.BMEdge) for f in g.link_faces}
        head_faces |= {f for f in bm.faces if f.material_index in (FUR, CREAM, MASK, NOSE) and in_region(f.calc_center_median())}
    up_n, low_n = planes
    for f in bm.faces:
        c = f.calc_center_median()
        if f.material_index in (CREAM, FUR) and in_region(c) and (c - cl).dot(up_n) < 0 < (c - cl).dot(low_n):
            f.material_index = MASK
    head_verts = {v for f in head_faces for v in f.verts}

# --- Mouth: a dark smile on the cream muzzle, just proud of the surface ----------------
bm.normal_update()
tree = BVHTree.FromBMesh(bm)


def on_surface(p, lift=0.0025):
    loc, nrm, _, _ = tree.find_nearest(Vector(p))
    return loc + nrm * lift


def mouth_side(sx):
    # An open smile: top edge under the nose, back to a corner on the cheek, lower lip below.
    pts = [(0.0, -0.538, 0.383), (0.034 * sx, -0.523, 0.385), (0.070 * sx, -0.478, 0.390),
           (0.040 * sx, -0.517, 0.358), (0.0, -0.534, 0.350)]
    vs = [bm.verts.new(on_surface(p, 0.004)) for p in pts]
    return vs


if P.get("mouth", False):   # the wedge read as teeth; off unless asked for
    ml, mr = mouth_side(1), mouth_side(-1)
    for vs in (ml, mr):
        for quad in ((vs[0], vs[1], vs[3], vs[4]), (vs[1], vs[2], vs[3])):
            f = bm.faces.new(quad)
            f.normal_update()
            if f.normal.y > 0:
                f.normal_flip()
            f.material_index = MASK
    bmesh.ops.remove_doubles(bm, verts=ml + mr, dist=1e-4)

# --- Ears: forward-facing flaps on the top-outer corner of the skull, measured from
# idle.jpg (ear_measure.py). The rim runs from the back-low base end B over the tip to
# the front base end A on the crown; inside is a darker triangle; the base sinks into
# the skull. EAR_PTS is the near (-X) ear, from B to A.
EAR_PTS = [Vector(p) for p in P.get("ear_pts", [
    (-0.159, -0.383, 0.545), (-0.169, -0.384, 0.578), (-0.171, -0.387, 0.609),
    (-0.167, -0.389, 0.636), (-0.142, -0.392, 0.649), (-0.110, -0.393, 0.635),
    (-0.074, -0.393, 0.601)])]
RIM = P.get("rim", 0.014)
THICK = P.get("ear_thick", 0.02)
CUP = P.get("ear_cup", 0.006)


def ear_flap(sx):
    pts = [Vector((-p.x * sx, p.y, p.z)) for p in EAR_PTS]   # sx=1: the +X (left) ear
    A, B = pts[-1], pts[0]
    n = (A - B).cross(pts[len(pts) // 2] - B).normalized()
    if n.y > 0:
        n = -n                                   # front faces forward
    # Sink the base into the skull, toward the head's centre line.
    inward = Vector((-sx * 0.7, 0.3, -0.6)).normalized()
    base_mid = (A + B) / 2 + inward * 0.03
    A_in, B_in = A + inward * 0.012, B + inward * 0.012
    outline = [B_in] + pts[1:-1] + [A_in]
    cen = sum(outline, Vector()) / len(outline)
    inner = []
    for i, p in enumerate(outline):
        if i in (0, len(outline) - 1):
            q = p + (base_mid - p).normalized() * RIM
        else:
            q = p + (cen - p).normalized() * RIM
        inner.append(q - n * CUP)
    F = [bm.verts.new(p) for p in outline]
    I = [bm.verts.new(p) for p in inner]
    Bk = [bm.verts.new(cen + (p - cen) * 0.92 - n * THICK) for p in outline]
    M = bm.verts.new(base_mid)
    Mb = bm.verts.new(base_mid - n * THICK)
    mid = cen - n * THICK / 2

    def face(vs, mat, outward=None):
        f = bm.faces.new(vs)
        f.normal_update()
        o = outward if outward is not None else f.calc_center_median() - mid
        if f.normal.dot(o) < 0:
            f.normal_flip()
        f.material_index = mat

    for i in range(len(outline) - 1):
        face([F[i], F[i + 1], I[i + 1], I[i]], CREAM, n)          # rim
        face([F[i], F[i + 1], Bk[i + 1], Bk[i]], FUR)             # outer edge
    face(I + [M], EARIN, n)                                        # inside, down to the base
    face([F[0], I[0], M], EARIN, n)
    face([I[-1], F[-1], M], EARIN, n)
    face(Bk + [Mb], FUR, -n)                                       # back
    face([F[-1], M, Mb, Bk[-1]], FUR)                              # base, buried
    face([M, F[0], Bk[0], Mb], FUR)


ear_flap(1)
ear_flap(-1)

me = bpy.data.objects["FaceWork"].data
me.materials.clear()
for m in MATS:
    me.materials.append(bpy.data.materials[m])
bm.to_mesh(me)
bm.free()
for p in me.polygons:
    p.use_smooth = False
me.update()
print("FaceWork", len(me.vertices), "verts", len(me.polygons), "faces")
