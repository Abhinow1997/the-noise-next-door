# Weights each part of the Raccoon mesh (left half) to its own bones; the mirror modifier
# copies .L weights to the right side. Blender's automatic weights bled between parts and
# failed on the fused body, so every weight here is set by rule.
import bpy, bmesh
from mathutils import Vector
ob = bpy.data.objects["Raccoon"]
me = ob.data
bm = bmesh.new()
bm.from_mesh(me)
mat = lambda f: me.materials[f.material_index].name
seen, islands = set(), []
for f in bm.faces:
    if f.index in seen:
        continue
    st, isl = [f], []
    seen.add(f.index)
    while st:
        g = st.pop()
        isl.append(g)
        for e in g.edges:
            for h in e.link_faces:
                if h.index not in seen:
                    seen.add(h.index)
                    st.append(h)
    islands.append(isl)


def classify(isl):
    mats = {mat(f) for f in isl}
    vs = {v for f in isl for v in f.verts}
    c = sum((v.co for v in vs), Vector()) / len(vs)
    if "R_Eye" in mats:
        return "eye", vs
    if "R_EarInner" in mats and c.z > 0.55:
        return "ear", vs
    if mats == {"R_Black"} and c.x > 0.05 and c.z < 0.06:
        return ("paw_front" if c.y < 0 else "paw_hind"), vs
    if c.x > 0.08 and c.z < 0.35:
        return ("leg_front" if c.y < 0 else "leg_hind"), vs
    if c.y > 0.55:
        return "tail", vs
    if c.y < -0.25:
        return "head", vs
    return "body", vs


def along(y, stops):
    stops = sorted(stops)
    if y <= stops[0][0]:
        return {stops[0][1]: 1.0}
    if y >= stops[-1][0]:
        return {stops[-1][1]: 1.0}
    for (y0, b0), (y1, b1) in zip(stops, stops[1:]):
        if y0 <= y <= y1:
            t = (y - y0) / (y1 - y0)
            return {b0: 1 - t, b1: t}


def by_height(z, top, low, joint, band=0.04):
    t = min(max((joint + band - z) / (2 * band), 0), 1)
    return {top: 1 - t, low: t}


parts = [classify(i) for i in islands]
print(sorted((p, len(v)) for p, v in parts))
# The fused body+legs piece: the core follows the spine; vertices near a leg's bone chain
# belong to that leg, fading out where the leg grows from the body; inside a leg the
# weight blends between its bones at the joints.
from mathutils.geometry import intersect_point_line
LEGS = {
    "front": ([Vector((0.15, -0.17, 0.37)), Vector((0.15, -0.18, 0.20)), Vector((0.15, -0.205, 0.05))],
              ["upperarm.L", "forearm.L"], "hand.L", (0.33, 0.21)),
    "hind": ([Vector((0.19, 0.25, 0.40)), Vector((0.19, 0.27, 0.18)), Vector((0.19, 0.33, 0.055))],
             ["thigh.L", "shin.L"], "foot.L", (0.34, 0.22)),
}
R_IN, R_OUT = 0.085, 0.16


def seg_dist(p, a, b):
    q, t = intersect_point_line(p, a, b)
    t = min(max(t, 0.0), 1.0)
    return (p - a.lerp(b, t)).length, t


def smooth(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3 - 2 * x)


def fused_weights(co):
    core = along(co.y, [(0.30, "pelvis"), (0.07, "spine"), (-0.10, "chest"), (-0.20, "neck")])
    best = None
    for name, (pts, bones, paw, (z_body, z_leg)) in LEGS.items():
        ds = [seg_dist(co, pts[i], pts[i + 1]) for i in range(len(pts) - 1)]
        d = min(x[0] for x in ds)
        m = smooth((R_OUT - d) / (R_OUT - R_IN)) * smooth((z_body - co.z) / (z_body - z_leg))
        if m > 1e-3 and (best is None or m > best[0]):
            best = (m, ds, bones, paw)
    if best is None:
        return core
    m, ds, bones, paw = best
    inv = [1.0 / (x[0] + 0.02) ** 3 for x in ds]
    tot = sum(inv)
    w = {k: v * (1 - m) for k, v in core.items()}
    for b, x in zip(bones, inv):
        w[b] = w.get(b, 0) + m * x / tot
    if co.z < 0.075:   # the wrist/ankle rides with the paw
        f = min((0.075 - co.z) / 0.04, 1.0) * 0.5
        lower = bones[-1]
        moved = w.get(lower, 0) * f
        w[lower] = w.get(lower, 0) - moved
        w[paw] = w.get(paw, 0) + moved
    return w


AUTO = {}
for p, vs in parts:
    if p == "body":
        for v in vs:
            AUTO[v.index] = fused_weights(v.co.copy())
W = {}
for p, vs in parts:
    for v in vs:
        co = v.co
        if p == "body":
            w = AUTO[v.index]
            tot = sum(w.values())
            w = {k: x / tot for k, x in w.items()}
        elif p == "head":
            w = along(co.y, [(-0.19, "neck"), (-0.26, "head")])
        elif p == "tail":
            w = along(co.y, [(0.47, "pelvis"), (0.56, "tail1"), (0.70, "tail2"), (0.84, "tail3"), (0.99, "tail4")])
        elif p == "leg_front":
            w = by_height(co.z, "upperarm.L", "forearm.L", 0.20)
            if co.z < 0.07:
                w = {"forearm.L": 1 - (0.07 - co.z) / 0.04 * 0.5, "hand.L": (0.07 - co.z) / 0.04 * 0.5}
        elif p == "leg_hind":
            w = by_height(co.z, "thigh.L", "shin.L", 0.18)
            if co.z < 0.08:
                w = {"shin.L": 1 - (0.08 - co.z) / 0.04 * 0.5, "foot.L": (0.08 - co.z) / 0.04 * 0.5}
        elif p == "paw_front":
            w = {"hand.L": 1.0}
        elif p == "paw_hind":
            w = {"foot.L": 1.0}
        elif p == "ear":
            w = {"ear.L": 1.0}
        elif p == "eye":
            w = {"eye.L": 1.0}
        else:
            w = {"head": 1.0}
        W[v.index] = {k: x for k, x in w.items() if x > 1e-4}
bm.free()
for vg in ob.vertex_groups:
    vg.remove(range(len(me.vertices)))
for vi, w in W.items():
    for name, x in w.items():
        ob.vertex_groups[name].add([vi], x, "REPLACE")
print("weighted", len(W), "of", len(me.vertices))
