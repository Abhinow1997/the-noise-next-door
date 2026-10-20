# Rebuilds the mesh of object "Raccoon" in raccoon_v2.blend (left half; a Mirror modifier
# makes the right). Parameters come in a PARAMS dict (build_all.py). The final model uses:
# face_head = FaceWork's head placed on the neck; body_v3 = the body built from the
# design's proportions; fuse = body and legs merged into one piece (voxel remesh, relax,
# decimate to big facets). The other branches are earlier versions, kept for reference.
import bpy, bmesh, math
from mathutils import Vector

P = globals().get("PARAMS", {})
HEAD_SCALE = P.get("head_scale", 1.3)
HEAD_LIFT = P.get("head_lift", 0.03)
BODY_WIDTH = P.get("body_width", 1.2)
LEG_THICK = P.get("leg_thick", 1.25)
EAR_SCALE = P.get("ear_scale", 1.5)

ob = bpy.data.objects["Raccoon"]
me = ob.data
MATS = ['R_Fur', 'R_Cream', 'R_Mask', 'R_EarInner', 'R_Black', 'R_Nose', 'R_Eye']
me.materials.clear()
for m in MATS:
    me.materials.append(bpy.data.materials[m])
FUR, CREAM, MASK, EARIN, BLACK, NOSE, EYE = range(7)

bm = bmesh.new()


def orient(f, outward):
    f.normal_update()
    if f.normal.dot(outward) < 0:
        f.normal_flip()


def tube(rings, centres, closed, mat_fn, cap_start=True, cap_end=True):
    vs = [[bm.verts.new(p) for p in r] for r in rings]
    n = len(rings[0])
    for k in range(len(rings) - 1):
        for i in (range(n) if closed else range(n - 1)):
            j = (i + 1) % n
            f = bm.faces.new((vs[k][i], vs[k][j], vs[k + 1][j], vs[k + 1][i]))
            cen = f.calc_center_median()
            axis = centres[k].lerp(centres[k + 1], 0.5)
            orient(f, cen - (axis if closed else Vector((0, axis.y, axis.z))))
            f.material_index = mat_fn(k, i, cen)
    for idx, nb, on in ((0, 1, cap_start), (-1, -2, cap_end)):
        if on:
            f = bm.faces.new(vs[idx])
            orient(f, centres[idx] - centres[nb])
            f.material_index = mat_fn(0 if idx == 0 else len(rings) - 2, -1, f.calc_center_median())
    return vs


def half_ring(y, c, hh, hw, n):
    out = []
    for i in range(n):
        t = math.radians(-90 + 180 * i / (n - 1))
        out.append(Vector((0.0 if i in (0, n - 1) else hw * math.cos(t), y, c + hh * math.sin(t))))
    return out


def half_tube(stations, n, mat_fn, tweak=None, **kw):
    rings = [half_ring(*s, n) for s in stations]
    if tweak:
        for k, r in enumerate(rings):
            tweak(k, r)
    return tube(rings, [Vector((0, s[0], s[1])) for s in stations], False, mat_fn, **kw)


def ring_xy(cx, cy, z, rx, ry, n=8, off=math.pi / 8):
    return [Vector((cx + rx * math.cos(off + 2 * math.pi * i / n), cy + ry * math.sin(off + 2 * math.pi * i / n), z)) for i in range(n)]


def ring_xz(cx, y, cz, rx, rz, n=8, off=math.pi / 8):
    return [Vector((cx + rx * math.cos(off + 2 * math.pi * i / n), y, cz + rz * math.sin(off + 2 * math.pi * i / n))) for i in range(n)]


def station_at(stations, y):
    """Interpolated (c, hh, hw) at y along a half tube."""
    for a, b in zip(stations, stations[1:]):
        if min(a[0], b[0]) <= y <= max(a[0], b[0]):
            t = (y - a[0]) / (b[0] - a[0])
            return [a[i] + (b[i] - a[i]) * t for i in (1, 2, 3)]
    return list(stations[-1][1:])


def surface(stations, y, theta_deg, inset=0.0):
    c, hh, hw = station_at(stations, y)
    t = math.radians(theta_deg)
    return Vector(((hw - inset) * math.cos(t), y, c + (hh - inset) * math.sin(t)))


# --- Body: rump -> neck (y, centre z, half height, half width) --------------------------
# Chunkier than the blockout: a high hump over the hind legs, a round rump, a deep chest.
BODY = [(0.50, 0.45, 0.07, 0.07), (0.465, 0.455, 0.165, 0.15), (0.40, 0.45, 0.225, 0.19),
        (0.30, 0.452, 0.27, 0.215), (0.17, 0.452, 0.282, 0.22), (0.03, 0.43, 0.247, 0.21),
        (-0.09, 0.40, 0.215, 0.19), (-0.18, 0.415, 0.17, 0.155), (-0.24, 0.44, 0.13, 0.12)]
BODY = [(y, c, hh, hw * BODY_WIDTH) for (y, c, hh, hw) in BODY]
ROUGH = []   # vertices that get the hand-cut jitter at the end
FACE_HEAD = P.get("face_head")   # (k, at): use FaceWork's measured head instead of the loft head
BODY_V3 = P.get("body_v3", False)
FUSE = BODY_V3 and P.get("fuse", False)   # body and legs merged into one flowing piece
if not BODY_V3:
    ROUGH += [v for r in half_tube(BODY, 6, lambda k, i, c: FUR, cap_end=bool(FACE_HEAD) or P.get("no_head", False)) for v in r]
else:
    # Proportions from the reference design, not traced outlines: a boulder-like body,
    # deepest and widest at the hips, the back arching over the hind legs and sloping in
    # one line down to a low-carried head; the belly hangs low so only the lower legs
    # show; length about 1.3x depth, depth about 1.7x head height. (build_all.py passes
    # a leaner rear in PARAMS["body3"].)
    # (y, top z, bottom z, half width)
    BODY3 = P.get("body3", [
        (0.56, 0.585, 0.43, 0.09),
        (0.515, 0.665, 0.30, 0.20),
        (0.43, 0.725, 0.215, 0.275),
        (0.31, 0.770, 0.175, 0.305),
        (0.17, 0.765, 0.17, 0.30),
        (0.03, 0.74, 0.18, 0.28),
        (-0.08, 0.72, 0.19, 0.26),
        # A thick neck: the shoulder fur wraps round the back of the skull and the back
        # line runs straight on into the crown, so the head grows out of the body.
        (-0.17, 0.70, 0.21, 0.245),
        (-0.225, 0.70, 0.27, 0.25),
        (-0.285, 0.675, 0.345, 0.225)])
    BULGE = P.get("bulge", 0.12)

    def body_ring(y, top, bot, hw, n=7):
        c, hh = (top + bot) / 2, (top - bot) / 2
        out = []
        for i in range(n):
            t = -90 + 180 * i / (n - 1)
            r = math.radians(t)
            # Fullest a little below the middle, like a sitting bean bag.
            k = 1 + BULGE * math.exp(-((t + 25) / 38) ** 2)
            out.append(Vector((0.0 if i in (0, n - 1) else hw * k * math.cos(r), y, c + hh * math.sin(r))))
        return out

    if FUSE:
        MAIN_BM, bm = bm, bmesh.new()
    rings = [body_ring(*st) for st in BODY3]
    vs3 = tube(rings, [Vector((0, st[0], (st[1] + st[2]) / 2)) for st in BODY3], False, lambda k, i, c: FUR,
               cap_end=True)
    if FUSE:
        FUSE_BM, bm = bm, MAIN_BM
    else:
        ROUGH += [v for r in vs3 for v in r]

# --- Head: back of skull -> nose, scaled about the neck --------------------------------
HEAD0 = [(-0.17, 0.42, 0.15, 0.13), (-0.24, 0.45, 0.16, 0.165), (-0.30, 0.445, 0.155, 0.19),
         (-0.36, 0.435, 0.135, 0.175), (-0.41, 0.42, 0.105, 0.13), (-0.455, 0.40, 0.065, 0.07),
         (-0.485, 0.39, 0.035, 0.038)]
NECK = Vector((0, -0.17, 0.42))
HEAD = [(NECK.y + (y - NECK.y) * HEAD_SCALE, NECK.z + HEAD_LIFT + (c - NECK.z) * HEAD_SCALE,
         hh * HEAD_SCALE, hw * HEAD_SCALE) for (y, c, hh, hw) in HEAD0]
# The neck ring stays body-sized so the head doesn't swallow the shoulders.
HEAD[0] = (HEAD0[0][0], HEAD0[0][1], HEAD0[0][2], HEAD0[0][3])
# The snout tip keeps its size, so a bigger head gets a pointier muzzle, not a bigger nose.
SNOUT = P.get("snout", 0.85)
for k in (len(HEAD) - 2, len(HEAD) - 1):
    y, c, hh, hw = HEAD[k]
    HEAD[k] = (y, c, HEAD0[k][2] * SNOUT, HEAD0[k][3] * SNOUT)


def head_mat(k, i, cen):
    if i == -1:
        return FUR if k == 0 else NOSE
    s, s2 = HEAD[k], HEAD[k + 1]
    cz, hh, hw = (s[1] + s2[1]) / 2, (s[2] + s2[2]) / 2, (s[3] + s2[3]) / 2
    th = math.degrees(math.atan2((cen.z - cz) / hh, cen.x / hw))
    if k == 0:
        return CREAM if th < -60 else FUR
    if k == 1:   # cheek tufts behind the mask
        return FUR if th > 30 else CREAM
    if k == 2:   # eyes: grey crown, cream brow, dark mask, cream jaw
        return FUR if th > 68 else CREAM if th > 35 else MASK if th > -30 else CREAM
    if k == 3:
        return FUR if th > 70 else CREAM if th > 40 else MASK if th > -20 else CREAM
    if k == 4:   # snout: grey bridge, mask down the sides, cream muzzle
        return FUR if th > 60 else MASK if th > 15 else CREAM
    return NOSE if th > -5 else CREAM


TUFT = P.get("tuft", 0.055)


def cheek_tufts(k, ring):
    """Pointed cream cheek fur at the widest part of the face, swept back."""
    if k == 1:
        ring[3] += Vector((TUFT * 0.55, 0.03, -0.01))
        ring[2] += Vector((TUFT * 0.25, 0.01, 0.0))
    if k == 2:
        ring[3] += Vector((TUFT, 0.045, -0.015))
        ring[2] += Vector((TUFT * 0.4, 0.02, 0.0))
        ring[4] += Vector((TUFT * 0.15, 0.0, 0.0))


LOFT_HEAD = not (FACE_HEAD or P.get("no_head", False))
if LOFT_HEAD:
    head_vs = half_tube(HEAD, 9, head_mat, tweak=cheek_tufts)
    ROUGH += [v for r in head_vs[1:-1] for v in r]

# --- Tail: one ring per band ------------------------------------------------------------
TAIL = [(0.40, 0.47, 0.075, 0.075), (0.47, 0.46, 0.085, 0.085), (0.525, 0.45, 0.092, 0.092),
        (0.58, 0.435, 0.096, 0.096), (0.635, 0.42, 0.096, 0.096), (0.69, 0.405, 0.094, 0.094),
        (0.745, 0.395, 0.09, 0.09), (0.80, 0.39, 0.082, 0.082), (0.855, 0.39, 0.065, 0.065),
        (0.91, 0.39, 0.03, 0.03)]
TAIL_THICK = P.get("tail_thick", 1.25)
TAIL = [(y, c, hh * TAIL_THICK, hw * TAIL_THICK) for (y, c, hh, hw) in TAIL]
if BODY_V3:
    # Thick (about 40% of body depth), set high on the rump, about half the body's length,
    # nine bands from grey at the root to a black tip.
    TAIL = []
    root, tip = Vector((0.0, 0.46, 0.54)), Vector((0.0, 1.06, 0.40))
    radii = P.get("tail_radii", [0.085, 0.11, 0.122, 0.126, 0.125, 0.12, 0.112, 0.10, 0.085, 0.06])
    for k, r in enumerate(radii):
        u = k / (len(radii) - 1)
        p = root.lerp(tip, u) + Vector((0, 0, 0.05 * math.sin(math.pi * u)))
        TAIL.append((p.y, p.z, r * 0.97, r))
    TAIL.append((tip.y + 0.035, tip.z + 0.005, 0.03, 0.03))
    band = lambda k, i, c: BLACK if (i == -1 and k > 0) or k >= len(TAIL) - 3 or (k >= 1 and k % 2 == 0) else FUR
    tail_vs = half_tube(TAIL, 7, band)
else:
    tail_vs = half_tube(TAIL, 6, lambda k, i, c: BLACK if (i == -1 and k > 0) or (k >= 1 and k % 2 == 0) or k == 8 else FUR)


# --- Legs (left side) ------------------------------------------------------------------
def leg(rings_spec, paw_spec):
    global bm
    rings = [ring_xy(x, y, z, rx * LEG_THICK, ry * LEG_THICK) for (x, y, z, rx, ry) in rings_spec]
    if FUSE:
        keep, bm = bm, FUSE_BM
    tube(rings, [Vector((x, y, z)) for (x, y, z, rx, ry) in rings_spec], True, lambda k, i, c: FUR)
    if FUSE:
        bm = keep
    prings = []
    for (x, y, rx, rz) in paw_spec:
        rx, rz = rx * LEG_THICK, rz * LEG_THICK ** 0.5
        prings.append(ring_xz(x, y, rz * math.cos(math.pi / 8), rx, rz))
    tube(prings, [Vector((x, y, 0.02)) for (x, y, rx, rz) in paw_spec], True, lambda k, i, c: BLACK)


FX, BX = P.get("front_x", 0.125), P.get("back_x", 0.14)
if BODY_V3:
    # Front legs: slim, under the chest, emerging from the low belly line.
    FX, BX = 0.15, 0.19
    FY, BY = P.get("front_y", -0.07), P.get("back_y", -0.04)   # stance: legs under shoulders and hips
    def at(spec, dy):
        return [(x, y + dy) + tuple(rest) for (x, y, *rest) in spec]
    # Front legs: a full upper arm out of the chest, slimming to the wrist, the paw a
    # little ahead of the shoulder.
    leg(at([(FX, -0.10, 0.36, 0.075, 0.08), (FX + 0.005, -0.105, 0.24, 0.066, 0.07),
            (FX, -0.12, 0.13, 0.046, 0.05), (FX, -0.135, 0.055, 0.04, 0.045)], FY),
        at([(FX, -0.10, 0.045, 0.03), (FX + 0.002, -0.165, 0.05, 0.028), (FX + 0.004, -0.22, 0.04, 0.019)], FY))
    # Hind legs: a big thigh flaring out of the haunch, the shin angled back to the heel,
    # a long black foot. THIGH: (x offset from BX, half width) of the top two rings,
    # which make the haunch.
    (T0X, T0R), (T1X, T1R) = P.get("thigh", ((0.0, 0.11), (0.015, 0.095)))
    leg(at([(BX + T0X, 0.29, 0.40, T0R, 0.13), (BX + T1X, 0.30, 0.26, T1R, 0.11),
            (BX + 0.005, 0.33, 0.14, 0.05, 0.055), (BX, 0.37, 0.055, 0.042, 0.046)], BY),
        at([(BX, 0.385, 0.046, 0.03), (BX + 0.002, 0.30, 0.052, 0.028), (BX + 0.004, 0.215, 0.042, 0.019)], BY))
if not BODY_V3:
  leg([(FX, -0.12, 0.40, 0.075, 0.085), (FX, -0.12, 0.25, 0.066, 0.072),
     (FX - 0.003, -0.115, 0.15, 0.056, 0.06), (FX, -0.12, 0.06, 0.047, 0.052)],
    [(FX, -0.08, 0.05, 0.032), (FX + 0.002, -0.14, 0.056, 0.03), (FX + 0.003, -0.195, 0.045, 0.02)])
  leg([(BX, 0.30, 0.42, 0.10, 0.12), (BX + 0.005, 0.31, 0.27, 0.095, 0.11),
     (BX + 0.003, 0.29, 0.17, 0.066, 0.072), (BX, 0.33, 0.07, 0.05, 0.056)],
    [(BX, 0.37, 0.052, 0.032), (BX + 0.001, 0.29, 0.058, 0.03), (BX + 0.002, 0.22, 0.046, 0.02)])

# --- Fuse body and legs: mirror to a closed whole, voxel-remesh so the limbs grow out of
# the body, relax the joints, then decimate back to big flat facets (the hand-cut low-poly
# look), keeping the left half for the mirror modifier.
if FUSE:
    bmesh.ops.mirror(FUSE_BM, geom=FUSE_BM.verts[:] + FUSE_BM.edges[:] + FUSE_BM.faces[:], axis="X",
                     merge_dist=1e-4)
    bmesh.ops.recalc_face_normals(FUSE_BM, faces=FUSE_BM.faces[:])
    fme = bpy.data.meshes.new("fuse_tmp")
    FUSE_BM.to_mesh(fme)
    FUSE_BM.free()
    fob = bpy.data.objects.new("fuse_tmp", fme)
    bpy.context.scene.collection.objects.link(fob)
    rem = fob.modifiers.new("Remesh", "REMESH")
    rem.mode = "VOXEL"
    rem.voxel_size = P.get("voxel", 0.011)
    rem.adaptivity = 0.0
    sm = fob.modifiers.new("Relax", "LAPLACIANSMOOTH")
    sm.iterations = P.get("relax_iter", 6)
    sm.lambda_factor = P.get("relax", 1.2)
    sm.use_volume_preserve = True
    dg = bpy.context.evaluated_depsgraph_get()
    n_hi = len(fob.evaluated_get(dg).data.polygons)
    dec = fob.modifiers.new("Facets", "DECIMATE")
    dec.decimate_type = "COLLAPSE"
    dec.ratio = P.get("facets", 760) / max(n_hi, 1)
    dec.use_symmetry = True
    dec.symmetry_axis = "X"
    dec.use_collapse_triangulate = True
    dg = bpy.context.evaluated_depsgraph_get()
    ev = fob.evaluated_get(dg)
    lo = bpy.data.meshes.new_from_object(ev)
    bpy.data.objects.remove(fob)
    bpy.data.meshes.remove(fme)
    lbm = bmesh.new()
    lbm.from_mesh(lo)
    bpy.data.meshes.remove(lo)
    bmesh.ops.bisect_plane(lbm, geom=lbm.verts[:] + lbm.edges[:] + lbm.faces[:], plane_co=(0, 0, 0),
                           plane_no=(1, 0, 0), clear_inner=True)
    # The cut leaves a few loose edges on the centre line; drop them.
    bmesh.ops.delete(lbm, geom=[e for e in lbm.edges if not e.link_faces], context="EDGES")
    bmesh.ops.delete(lbm, geom=[v for v in lbm.verts if not v.link_faces], context="VERTS")
    for v in lbm.verts:
        if abs(v.co.x) < 1e-4:
            v.co.x = 0.0
    for f in lbm.faces:
        f.material_index = FUR
    tmp = bpy.data.meshes.new("fuse_half")
    lbm.to_mesh(tmp)
    lbm.free()
    bm.from_mesh(tmp)
    bpy.data.meshes.remove(tmp)
    print("fused body+legs:", n_hi, "->", P.get("facets", 760), "faces (whole)")

if LOFT_HEAD:
    # --- Left ear: a rounded, fairly upright slab; cream rim, dark inside, grey back -------
    ear_y = HEAD[1][0] - 0.005
    base = surface(HEAD, ear_y, 60, inset=0.02)
    w, h, d = 0.048 * EAR_SCALE, 0.088 * EAR_SCALE, 0.03 * EAR_SCALE
    up = Vector((0.28, 0.05, 1)).normalized()           # a slight outward lean
    side = Vector((1, 0, -0.28)).normalized()
    OUTLINE = [(-1, 0), (-0.8, 0.6), (-0.3, 1.0), (0.2, 1.02), (0.75, 0.62), (1, 0)]
    front_pts = [base + side * (u * w) + up * (v * h) + Vector((0, -d / 2, 0)) for u, v in OUTLINE]
    back_pts = [base + side * (u * w * 0.85) + up * (v * h * 0.92) + Vector((0, d / 2, 0)) for u, v in OUTLINE]
    cen = sum(front_pts, Vector()) / len(front_pts)
    inner_pts = [cen.lerp(p, 0.62) + Vector((0, 0.004, 0)) for p in front_pts]
    F = [bm.verts.new(p) for p in front_pts]
    B = [bm.verts.new(p) for p in back_pts]
    I = [bm.verts.new(p) for p in inner_pts]
    ear_mid = (cen + sum(back_pts, Vector()) / len(back_pts)) / 2
    n = len(OUTLINE)


    def ear_face(verts, mat, outward=None):
        f = bm.faces.new(verts)
        orient(f, outward if outward is not None else f.calc_center_median() - ear_mid)
        f.material_index = mat


    front = Vector((0, -1, 0))
    for i in range(n):
        j = (i + 1) % n
        ear_face([F[i], F[j], I[j], I[i]], CREAM, front)        # rim
        ear_face([F[i], B[i], B[j], F[j]], FUR)                 # edge
    ear_face(I, EARIN, front)
    ear_face(B, FUR, Vector((0, 1, 0)))

    # --- Left eye: in the mask, between the brow and the cheek -----------------------------
    eye_y = (HEAD[2][0] + HEAD[3][0]) / 2
    eye_c = surface(HEAD, eye_y, 12, inset=0.012)
    eye = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=0.024 * HEAD_SCALE ** 0.5)
    for v in eye['verts']:
        v.co = Vector((v.co.x * 0.6, v.co.y, v.co.z)) + eye_c
    for f in {f for v in eye['verts'] for f in v.link_faces}:
        f.material_index = EYE

# --- The measured head (FaceWork), left half, placed on the neck ----------------------
if FACE_HEAD:
    from mathutils import Matrix
    k, at = FACE_HEAD
    T = Matrix.Translation(Vector(at)) @ Matrix.Scale(k, 4) @ Matrix.Translation(-Vector((0.0, -0.257, 0.493)))
    fme = bpy.data.objects["FaceWork"].data.copy()
    fme.transform(T)
    fbm = bmesh.new()
    fbm.from_mesh(fme)
    bpy.data.meshes.remove(fme)
    bmesh.ops.delete(fbm, geom=[v for v in fbm.verts if v.co.x < -1e-5], context="VERTS")
    names = [m.name for m in bpy.data.objects["FaceWork"].data.materials]
    for f in fbm.faces:
        f.material_index = MATS.index(names[f.material_index])
    for v in fbm.verts:
        if abs(v.co.x) < 1e-5:
            v.co.x = 0.0
    tmp = bpy.data.meshes.new("tmp_face")
    fbm.to_mesh(tmp)
    fbm.free()
    bm.from_mesh(tmp)
    bpy.data.meshes.remove(tmp)

# Hand-cut look: nudge each vertex a little so the facets aren't machine-even. Vertices on
# the centre line only move along it, so the mirror still closes.
import random
rng = random.Random(P.get("seed", 7))
J = P.get("jitter", 0.009)
for v in ROUGH:
    dx = 0.0 if abs(v.co.x) < 1e-6 else rng.uniform(-J, J)
    v.co += Vector((dx, rng.uniform(-J, J) * 0.6, rng.uniform(-J, J)))
bm.normal_update()

bm.to_mesh(me)
bm.free()
for p in me.polygons:
    p.use_smooth = False
me.update()
if not ob.modifiers.get("Mirror"):
    mir = ob.modifiers.new("Mirror", "MIRROR")
    mir.use_clip = True
    mir.use_mirror_merge = True
print("verts", len(me.vertices), "faces", len(me.polygons), "head", [tuple(round(x, 3) for x in s) for s in HEAD[1:3]])
