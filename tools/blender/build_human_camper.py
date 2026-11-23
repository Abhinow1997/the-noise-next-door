# The camper, on the man: the male from "Human Basic Shapes- male and female basemesh" by Josephbburg (Blend Swap
# 72307, Creative Commons Attribution 3.0, so Josephbburg must be credited), as made game-ready in
# assets/characters/humans.blend, dressed as the game's camper (assets/characters/camper.blend, Claude Code's model of
# design/reference/red-beanie-man.jpg) and kept rigged, so he can be posed and animated as the camper. Made on
# 21 Oct 2026 at the author's request: "we have a model named human in our assest i want you to work with the man's
# model and make it like the camper with beanie we have using blender".
#
# Claude Code built him in the author's Blender 5.2 through the MCP; this script is that work as one run, written
# afterwards from the calls (the test pose, the looks and the side-by-side with the camper are left out). It:
#   - stands the man like the camper (shoulders down, arms hanging a little out, elbows soft, fingers loosely curled,
#     legs a little apart, toes out) and makes that his rig's rest pose, so he stands that way in Godot. The download's
#     walk and run cycles (in humans.blend) are left out: without the rig's IK they don't play (the arms stay out in
#     front and the legs don't step), and a new rest pose breaks them anyway;
#   - copies the camper's clothes onto him, each part moved to fit his body as measured in that pose: the jacket,
#     hoodie, hood, T-shirt, strings, collar, pockets, flaps and buttons with his torso (0.095 m back, 0.08-0.10 m
#     higher); the jeans, cuffs, boots and soles along his legs; the sleeves along his arms (1.12x longer); the beanie,
#     pompom, hair and nose to his head (0.85x, the camper's head turn taken out first);
#   - then (added that night, CLOTHES) makes his jacket's body, its sleeves, the hood and the hoodie's front again for
#     him instead, in the camper's style, and moves the pockets, flaps, buttons, lapels and strings onto them;
#   - takes away his body wherever the clothes cover it, keeping his head and neck (the neck a little fuller) and his
#     hands, which are fused, relaxed and cut to big flat facets like the camper's parts;
#   - gives every part the bone weights of the nearest point on his own body (sleeves from his arms, jeans and boots
#     from his legs, the jacket and the rest from his torso, the beanie, hair and nose all to his head);
#   - centres him, rig and all, on the middle of his boots;
#   - then (added later the same evening) gives the jeans smooth weights of their own round the hips and knees, and
#     lets the lower jacket and hoodie go partway with his thighs, the pockets, flaps, buttons and collar moving as the
#     jacket under them; and (with the new clothes) gives the jacket, sleeves, hood, hoodie, strings and T-shirt
#     weights from one field over his body (garment_weights), the hoodie's front then moving as the jacket;
#   - then (added later still) runs tools/blender/animate_human_camper.py for his animations (walk, run, bend,
#     take_away), saves assets/characters/human_camper.blend and exports assets/characters/human_camper.glb
#     (+Y up, his 62 deforming bones, the four actions sampled on every frame).
# 22 parts with the rig, 8,810 triangles (4,467 with the camper's own jacket), 0.635 x 0.306 x 1.854 m to the top of
# the pompom, facing -Y (+Z in Godot).
#
# Run it from the repository's folder (Windows, Git Bash); set HUMAN_CAMPER_OUT to a path without an extension to
# write the .blend and .glb somewhere else (a test):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --disable-autoexec \
#       --python-exit-code 1 --python tools/blender/build_human_camper.py

import bpy, bmesh, math, os
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HUMANS = os.path.join(REPO, "assets", "characters", "humans.blend")
CAMPER = os.path.join(REPO, "assets", "characters", "camper.blend")
OUT = os.environ.get("HUMAN_CAMPER_OUT") or os.path.join(REPO, "assets", "characters", "human_camper")

# The camper's stance, from the man's T-pose (degrees).
STAND = dict(clav=6.0, arm=78.0, elbow=10.0, curl=(12, 20, 16), thumb=12, leg_out=1.6, toe_out=9.0)
# The camper's head parts are turned 9 degrees to his right about his neck (camper2_parts' head_matrix); undone here.
CAMPER_HEAD_TURN = dict(turn=-0.1563, nod=0.0264, tilt=0.0474, pivot=(0, 0.01, 1.40))

POSE_LIB = r'''
import bpy, math
from mathutils import Vector, Matrix
def turn(r, name, axis, deg):
    """Turn a pose bone by `deg` about a world axis through its posed head (the rig sits at the identity)."""
    bpy.context.view_layer.update()
    pb = r.pose.bones[name]
    p = pb.head.copy()
    pb.matrix = Matrix.Translation(p) @ Matrix.Rotation(math.radians(deg), 4, axis) @ Matrix.Translation(-p) @ pb.matrix
    bpy.context.view_layer.update()

def stand(r, P):
    """The camper's stance from the T-pose: shoulders down, arms hanging a little out from the body with the elbows
    soft and the hands turned in, the fingers loosely curled, the legs a little apart with the toes turned out."""
    for pb in r.pose.bones:
        pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = (1, 0, 0, 0); pb.location = (0, 0, 0); pb.scale = (1, 1, 1)
    for s, sd, cl in ((1, "l", "R"), (-1, "r", "L")):      # s: +1 his left (+X), -1 his right
        turn(r, "chest_" + cl, "Y", s * P["clav"])
        turn(r, "Hum_" + sd, "Y", s * P["arm"])
        turn(r, "Hum_" + sd + ".001", "X", -P["elbow"])
        for f in ("pink", "ring", "mid", "point"):
            for k, c in zip(("", ".001", ".002"), P["curl"]):
                turn(r, "%s_%s%s" % (f, sd, k), "Y", s * c)
        turn(r, "thumb_" + sd, "X", -P["thumb"]); turn(r, "thumb_" + sd + ".001", "X", -P["thumb"])
        turn(r, "thigh_" + sd, "Y", -s * P["leg_out"])
        turn(r, "thigh_" + sd, "Z", s * P["toe_out"])
'''

LIB = r'''
import bpy, math
from mathutils import Vector, Matrix

# --- where the camper's clothes go on the man (camper.blend -> his standing rest pose) -------------------------
# Measured on the man in his standing pose: torso and neck centred at y 0.085-0.10, shoulder line 1.455, chin 1.555,
# head widest (r 0.095) at 1.67, centred at y 0.0635, top 1.778; leg line x 0.105, y 0.105-0.111; arm bones below.
W = dict(torso_dy=0.095,                 # the camper's torso is centred on y 0, the man's ~0.095 behind it
         torso_z=[(0.0, 0.08), (0.88, 0.08), (0.97, 0.10), (9.0, 0.10)],    # camper z -> added height
         leg_z=[(0.0, 0.0), (0.23, 0.24), (0.50, 0.575), (0.88, 0.96)],    # camper z -> man z, below the crotch
         jeans_blend=(0.80, 0.90),       # the jeans go from the legs' warp to the torso's over this height
         arm_top=1.262, arm_bot=0.805, arm_top_h=1.362, arm_bot_h=0.85,     # the sleeve from shoulder to cuff
         head_anchor=(Vector((0, 0.008, 1.607)), Vector((0, 0.0635, 1.67))), head_k=0.85,
         boot_toe_out=math.radians(12))
# the camper's leg and arm lines (from camper2_parts) and the man's (his bones in the standing rest pose)
def camper_leg(z):
    x = 0.088 + (0.115 - 0.088) * (0.88 - z) / (0.88 - 0.13)
    y = interp([(0.16, 0.008), (0.20, 0.008), (0.32, 0.0), (0.50, -0.008), (0.72, 0.0), (0.88, 0.0)], z)
    return x, y
CAMPER_ARM = [(0.805, 0.254, -0.008), (0.811, 0.254, -0.008), (0.865, 0.254, -0.006), (0.872, 0.254, -0.005),
              (0.905, 0.251, 0.0), (1.060, 0.233, 0.010), (1.180, 0.216, 0.005), (1.262, 0.190, 0.0)]

def interp(table, z):
    """Piecewise-linear lookup in [(z, value), ...] sorted by z, held flat past the ends."""
    if z <= table[0][0]: return table[0][1]
    for (z0, a), (z1, b) in zip(table, table[1:]):
        if z <= z1:
            f = (z - z0) / (z1 - z0); return a + f * (b - a)
    return table[-1][1]
def interp3(table, z):
    """The same for [(z, x, y), ...]: returns (x, y)."""
    return interp([(t[0], t[1]) for t in table], z), interp([(t[0], t[2]) for t in table], z)
def smooth(a, b, z):
    t = max(0.0, min(1.0, (z - a) / (b - a))); return t * t * (3 - 2 * t)

def bone_line(rig, names):
    """The man's limb line as [(z, x, y)] from the heads and the last tail of the bones, lowest first (his left side)."""
    pts = [rig.data.bones[n].head_local for n in names] + [rig.data.bones[names[-1]].tail_local]
    return sorted((p.z, p.x, p.y) for p in pts)

def warp_torso(v):
    return Vector((v.x, v.y + W["torso_dy"], v.z + interp(W["torso_z"], v.z)))

def warp_leg(v, man_leg):
    s = 1 if v.x >= 0 else -1
    zh = interp(W["leg_z"], v.z)
    xc, yc = camper_leg(v.z)
    xh, yh = interp3(man_leg, zh)
    f = min(1.0, abs(v.x) / xc)                       # no shift on the centre line, so the two legs stay joined
    return Vector((v.x + s * (xh - xc) * f, v.y + (yh - yc), zh))

def warp_jeans(v, man_leg):
    a, b = W["jeans_blend"]
    w = smooth(a, b, v.z)
    return warp_leg(v, man_leg).lerp(warp_torso(v), w)

def warp_boot(v, man_leg, foot_yaw):
    """Boots and soles: moved from the camper's ankle to the man's, turned to his foot's heading, heights kept."""
    s = 1 if v.x >= 0 else -1
    ca = Vector((s * 0.115, 0.008, 0.0))
    xh, yh = interp3(man_leg, 0.13)
    ha = Vector((s * xh, yh, 0.0))
    R = Matrix.Rotation(s * (foot_yaw - W["boot_toe_out"]), 3, "Z")
    return ha + R @ (v - ca)

def warp_arm(v, man_arm):
    s = 1 if v.x >= 0 else -1
    t, b, th, bh = W["arm_top"], W["arm_bot"], W["arm_top_h"], W["arm_bot_h"]
    zh = th + (v.z - t) if v.z >= t else th + (v.z - t) * (th - bh) / (t - b)
    xc, yc = interp3(CAMPER_ARM, v.z)
    xh, yh = interp3(man_arm, zh)
    return Vector((v.x + s * (xh - xc), v.y + (yh - yc), zh))

def warp_head(v):
    (ca, ha), k = W["head_anchor"], W["head_k"]
    return ha + (v - ca) * k

def warped_copy(src_name, new_name, fn, coll):
    """A copy of one of the camper's parts, every vertex moved by fn (world space; the parts sit at the identity)."""
    src = bpy.data.objects[src_name]
    assert src.matrix_world == Matrix.Identity(4), src_name
    old = bpy.data.objects.get(new_name)
    if old:
        me0 = old.data; bpy.data.objects.remove(old); bpy.data.meshes.remove(me0)
    me = src.data.copy(); me.name = new_name
    for vt in me.vertices:
        vt.co = fn(vt.co.copy())
    me.update()
    ob = bpy.data.objects.new(new_name, me); coll.objects.link(ob)
    return ob
'''

SKIN = r'''
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.interpolate import poly_3d_calc

def dominant_names(src):
    names = {g.index: g.name for g in src.vertex_groups}
    return [names[max(v.groups, key=lambda g: g.weight).group] if v.groups else None for v in src.data.vertices]

def skin_from_body(target, src, allow=None, remap=None, only=None, max_bones=4):
    """Give `target` the bone weights of the nearest point on the man's own body (`src`, his full skinned body at
    rest): the weights of that face's corners, blended by where the point falls in it. allow(name) limits which of
    his faces are searched (by each face's strongest bone); remap moves one bone's weight to another; only=bone gives
    every vertex to that one bone."""
    for g in list(target.vertex_groups): target.vertex_groups.remove(g)
    if only:
        g = target.vertex_groups.new(name=only); g.add(range(len(target.data.vertices)), 1.0, "REPLACE"); return
    names = {g.index: g.name for g in src.vertex_groups}
    dom = dominant_names(src)
    faces = [p for p in src.data.polygons if allow is None or all(dom[i] is not None and allow(dom[i]) for i in p.vertices)]
    verts = [v.co.copy() for v in src.data.vertices]
    bvh = BVHTree.FromPolygons(verts, [tuple(p.vertices) for p in faces])
    vw = [{names[g.group]: g.weight for g in v.groups} for v in src.data.vertices]
    out = {}
    for v in target.data.vertices:
        loc, nor, fi, dist = bvh.find_nearest(v.co)
        poly = faces[fi]
        ws = poly_3d_calc([verts[i] for i in poly.vertices], loc)
        acc = {}
        for i, w in zip(poly.vertices, ws):
            for n, x in vw[i].items():
                n = (remap or {}).get(n, n)
                if n is None: continue
                acc[n] = acc.get(n, 0.0) + w * x
        top = sorted(acc.items(), key=lambda kv: -kv[1])[:max_bones]
        s = sum(x for _, x in top) or 1.0
        out[v.index] = [(n, x / s) for n, x in top if x > 1e-4]
    for vi, lst in out.items():
        for n, x in lst:
            g = target.vertex_groups.get(n) or target.vertex_groups.new(name=n)
            g.add([vi], x, "REPLACE")
'''

# Added 21 Oct 2026, 20:10-20:30, at the author's request after a test of hard poses ("yes fix the animations jackets
# and hips"): the jeans get smooth weights of their own instead of the ones taken from his low-detail body, and the
# lower jacket and hoodie go partway with his thighs, so a raised knee lifts the jacket instead of coming through it.
WEIGHTS = r'''
import bpy
from mathutils import Vector

def set_weights(ob, table):
    """Replace ob's bone weights with table[i] = {bone: weight} (normalised, tiny ones dropped)."""
    for g in list(ob.vertex_groups): ob.vertex_groups.remove(g)
    for i, w in enumerate(table):
        s = sum(w.values()) or 1.0
        for n, x in w.items():
            if x / s > 1e-4:
                g = ob.vertex_groups.get(n) or ob.vertex_groups.new(name=n)
                g.add([i], x / s, "REPLACE")

def weights_of(ob):
    names = {g.index: g.name for g in ob.vertex_groups}
    return [{names[g.group]: g.weight for g in v.groups} for v in ob.data.vertices]

def jeans_weights(ob):
    """Smooth weights for the jeans: the hips into each thigh over 15 cm round the hip joints, each thigh into its shin
    over 13 cm round the knee; the two legs shared across the crotch (4 cm either side), apart below it."""
    table = []
    for v in ob.data.vertices:
        x, y, z = v.co
        band = 0.012 + (0.04 - 0.012) * smooth(0.88, 0.97, z)
        sl = smooth(-band, band, x); sr = 1.0 - sl
        a = smooth(1.05, 0.90, z)          # 0 hips .. 1 legs
        k = smooth(0.64, 0.51, z)          # 0 thigh .. 1 shin
        table.append({"hips": 1 - a, "thigh_l": a * (1 - k) * sl, "thigh_r": a * (1 - k) * sr,
                      "thigh_l.001": a * k * sl, "thigh_r.001": a * k * sr})
    set_weights(ob, table)

def chain_at(p, pts):
    """The point on the polyline pts nearest p: (how far along it from pts[0], how far from it)."""
    best, acc = None, 0.0
    for a, b in zip(pts, pts[1:]):
        ab = b - a; L = ab.length
        t = max(0.0, min(1.0, (p - a).dot(ab) / (L * L)))
        d = (p - (a + ab * t)).length
        if best is None or d < best[1]:
            best = (acc + t * L, d)
        acc += L
    return best

def garment_weights(rig, ob, kind):
    """Weights for the new clothes from where each vertex is, one field for all of them, so where the jacket's body
    and a sleeve meet at the shoulder they move together. kind: "body" (the jacket's body), "sleeve", "hood",
    "hoodie", "strings" or "tshirt".
    - The arm takes the sleeve from just below his shoulder joint, and the jacket's body only at the outer edge of the
      shoulder (none of its side below the armpit); the elbow is shared over 10 cm.
    - The collarbones take the top of his shoulders; the neck a little of the collar and the top of the hood.
    - The rest hangs from his chest, as a jacket hangs from the shoulders: the hips take a share only low down, up to
      45% at the jacket's hem (60% for the hoodie, which is closer to him), so bending doesn't fold it at the waist."""
    B = rig.data.bones
    table = []
    for v in ob.data.vertices:
        p = v.co; x, z = p.x, p.z
        sd = "l" if x >= 0 else "r"; cl = "chest_R" if x >= 0 else "chest_L"
        S, E, W = B["Hum_" + sd].head_local, B["Hum_" + sd + ".001"].head_local, B["Hum_" + sd + ".001"].tail_local
        t = (p - S).dot((E - S).normalized())         # how far down his upper arm, from the shoulder joint
        lat = smooth(0.165, 0.215, abs(x))             # out at the edge of his shoulder
        if kind == "sleeve":
            a = smooth(-0.03, 0.06, t) * (lat + (1 - lat) * smooth(0.04, 0.14, t))
        elif kind == "body":
            a = smooth(-0.03, 0.06, t) * lat * (1 - smooth(0.08, 0.15, t))
        else:
            a = 0.0
        k = smooth((E - S).length - 0.05, (E - S).length + 0.05, chain_at(p, [S, E, W])[0])
        w = {"Hum_" + sd: a * (1 - k), "Hum_" + sd + ".001": a * k}
        rest = 1.0 - a
        clav = 0.6 * smooth(0.08, 0.17, abs(x)) * smooth(1.33, 1.42, z)
        hips = {"hoodie": 0.60, "strings": 0.0, "tshirt": 0.0, "hood": 0.0}.get(kind, 0.45) * smooth(1.24, 0.87, z)
        collar = 0.15 * smooth(1.45, 1.48, z) * (1 - smooth(0.06, 0.10, abs(x)))
        neck = {"hood": 0.20 * smooth(1.48, 1.54, z), "tshirt": 0.30}.get(kind, collar)
        w[cl] = rest * clav
        w["hips"] = rest * (1 - clav) * hips
        w["neck"] = rest * neck
        w["chest"] = rest - w[cl] - w["hips"] - w["neck"]
        table.append(w)
    set_weights(ob, table)

def follow_thighs(ob, hip_y, front=0.65, back=0.30, top=1.00, hem=0.86):
    """Let the lower part of a top (the jacket, the hoodie) go partway with each thigh: none above `top`, up to `front`
    at the hem in front of the hip joints and `back` behind them, shared smoothly between the legs across the middle."""
    old = weights_of(ob)
    table = []
    for v, w in zip(ob.data.vertices, old):
        x, y, z = v.co
        t = smooth(top, hem, z) * (front + (back - front) * smooth(hip_y - 0.05, hip_y + 0.05, y))
        sl = smooth(-0.06, 0.06, x)
        nw = {n: x_ * (1 - t) for n, x_ in w.items()}
        nw["thigh_l"] = nw.get("thigh_l", 0.0) + t * sl
        nw["thigh_r"] = nw.get("thigh_r", 0.0) + t * (1 - sl)
        table.append(nw)
    set_weights(ob, table)
'''

# Test poses for the clothes, kept in the file as the text block "hcamper_test_poses" (they aren't animations):
# exec it after "hcamper_pose", then pose(rig, "climb" | "run" | "bend" | "sit") and reset(rig).
TEST_POSES = r'''
def reset(rig):
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = (1, 0, 0, 0); pb.location = (0, 0, 0); pb.scale = (1, 1, 1)
    bpy.context.view_layer.update()
# test poses for the clothes (degrees about world axes through each bone's head; X+ swings a limb backwards)
STRESS = {
    "climb": [("Hum_l", "Y", -80), ("Hum_r", "X", -100), ("thigh_l", "X", -70), ("thigh_l.001", "X", 80), ("chest", "X", -12)],
    "run": [("thigh_l", "X", -45), ("thigh_l.001", "X", 70), ("thigh_r", "X", 30), ("thigh_r.001", "X", 60),
            ("Hum_l", "X", 45), ("Hum_l.001", "X", -70), ("Hum_r", "X", -50), ("Hum_r.001", "X", -80), ("chest", "X", -15)],
    "bend": [("hips", "X", 55), ("thigh_l", "X", -45), ("thigh_r", "X", -45), ("thigh_l.001", "X", 25), ("thigh_r.001", "X", 25),
             ("tum", "X", 10), ("chest", "X", 20), ("Hum_l", "X", -15), ("Hum_r", "X", -15), ("head", "X", -25)],
    "sit": [("thigh_l", "X", -88), ("thigh_r", "X", -88), ("thigh_l.001", "X", 88), ("thigh_r.001", "X", 88)],
}
def pose(rig, name):
    reset(rig)
    for n, ax, d in STRESS[name]: turn(rig, n, ax, d)
'''


# Added 21 Oct 2026, from about 22:30, at the author's request once the animations were done ("ok the animations look good
# but the clothes damnnn its bad the way it looks"; of what Claude listed they picked "Jacket is a stiff box", "Hood and
# hoodie" and "Shoulders and sleeves", and "Both" for how they look standing and how they move): the jacket's body, its
# sleeves, the hood and the hoodie's front are made again for him in the camper's style (lofted, fused with a voxel
# remesh, relaxed and cut to flat facets), instead of being the camper's own moved onto him. The old jacket had almost
# no vertices between its hem and waist, so it folded like a box; the new parts have evenly spread facets. The jacket's
# shoulders are squared and the sleeves set into them with turned-up cuffs, as in design/reference/red-beanie-man.jpg;
# the hood lies bunched round his neck, rising behind it; the hoodie's front fills the jacket's opening. The pockets,
# flaps, buttons, lapels and strings are moved onto them. (Their weights are in WEIGHTS, garment_weights.)
CLOTHES = r'''
import bpy, bmesh, math
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

CY = 0.095                         # his torso's centre line (y), before he's centred on his boots
B = rig.data.bones


def sring(cx, cy, z, rx, ry, n=56, p=3.0, notch=None):
    """A boxy ring (superellipse) sampled evenly from the front centre; notch = (half-width, depth) sets the front
    back between the jacket's open edges."""
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


def opening(z):                    # half-width of the open front: 4.4 cm at the hem, 6.2 cm at the collar
    return 0.044 + 0.018 * smooth(0.86, 1.38, z)


# the jacket's body: (height, half-width, half-depth, centre y offset); square at the shoulders, straight below
JACKET = [(0.855, 0.190, 0.136, 0.0), (0.875, 0.190, 0.136, 0.0), (0.95, 0.187, 0.135, 0.0), (1.05, 0.183, 0.133, 0.0),
          (1.15, 0.182, 0.132, 0.0), (1.24, 0.186, 0.132, 0.0), (1.31, 0.195, 0.131, -0.002), (1.36, 0.206, 0.128, -0.004),
          (1.405, 0.214, 0.122, -0.004), (1.435, 0.205, 0.112, -0.002), (1.455, 0.170, 0.098, 0.0), (1.468, 0.120, 0.086, 0.004)]


def build_jacket_body(bm):
    rings = []
    for z, rx, ry, dy in JACKET:
        notch = (opening(z), 0.030 if z < 1.40 else 0.020) if z < 1.45 else None
        rings.append(sring(0, CY + dy, z, rx, ry, notch=notch))
    rings.append(sring(0, CY + 0.006, 1.478, 0.085, 0.072))
    loft(bm, rings)


def arm_points(s):
    """His arm's line at rest, shoulder to wrist (the bones' joints)."""
    sd = "l" if s > 0 else "r"
    S, E, W = B["Hum_%s" % sd].head_local, B["Hum_%s.001" % sd].head_local, B["Hum_%s.001" % sd].tail_local
    return S, E, W


def build_sleeves(bm):
    for s in (1, -1):
        S, E, W = arm_points(s)
        up = (S - E).normalized()
        out = Vector((s, 0, 0))
        top = S + up * 0.035 + out * 0.008          # the shoulder cap, a little above and outside the joint
        pts = [top, S + up * 0.005, S.lerp(E, 0.35), S.lerp(E, 0.75), E, E.lerp(W, 0.35), E.lerp(W, 0.75),
               W + (E - W).normalized() * 0.045, W + (E - W).normalized() * 0.040, W + (E - W).normalized() * 0.006, W - (E - W).normalized() * 0.004]
        radii = [(0.050, 0.055), (0.064, 0.066), (0.061, 0.063), (0.058, 0.060), (0.057, 0.059), (0.055, 0.057), (0.053, 0.055),
                 (0.053, 0.055), (0.060, 0.062), (0.061, 0.063), (0.056, 0.058)]
        path_tube(bm, pts, radii, n=14, ref=Vector((0, 1, 0)))


def build_hood(bm):
    """The hood, down: bunched round the base of his neck, thin at the front where it meets the strings, and rising
    behind his neck in a soft heap up to his hairline, as in the reference."""
    pts, radii = [], []
    nc = Vector((0, 0.078, 1.466))                 # round his neck's base
    for k in range(19):
        a = math.radians(-64 + 308 * k / 18)       # from the front left round the back to the front right
        b = max(0.0, math.sin(a)) ** 1.3           # 0 at the front and sides, 1 at the back
        rx, ry = 0.086 + 0.016 * b, 0.074 + 0.040 * b
        pts.append(nc + Vector((rx * math.cos(a), ry * math.sin(a), 0.008 + 0.050 * b)))
        radii.append((0.020 + 0.024 * b, 0.019 + 0.044 * b))     # (out from the neck, up and down)
    path_tube(bm, pts, radii, n=10, ref=Vector((0, 0, 1)))


def build_hoodie(bm):
    """The hoodie's front, seen in the jacket's opening: a shallow panel just in front of the jacket's recessed front,
    reaching under its edges, with a ring every 5 cm so it bends with the jacket."""
    rings = []
    for k in range(13):
        z = 0.850 + (1.43 - 0.850) * k / 12
        ry_j = interp([(r[0], r[2]) for r in JACKET], z)
        yr = CY - ry_j + (0.030 if z < 1.40 else 0.020)          # the jacket's recessed front
        rings.append(hring(0, yr + 0.012, z, opening(z) + 0.022, 0.022, 12))
    loft(bm, rings)


def replace(name, ob):
    old = bpy.data.objects.get(name)
    if old and old is not ob:
        me0 = old.data; bpy.data.objects.remove(old); bpy.data.meshes.remove(me0)
    ob.name = name; ob.data.name = name
    for c in list(ob.users_collection): c.objects.unlink(ob)
    coll.objects.link(ob)
    return ob


def ray_y(bvh, x, z):
    """Where a line straight back from in front of him, at (x, z), first meets a surface (its y), or None."""
    hit = bvh.ray_cast(Vector((x, -1.0, z)), Vector((0, 1, 0)), 3.0)[0]
    return hit.y if hit else None


def surface(ob):
    me = ob.data
    return BVHTree.FromPolygons([v.co.copy() for v in me.vertices], [tuple(p.vertices) for p in me.polygons])


def jacket_rx(z):
    return interp([(r[0], r[1]) for r in JACKET], z)


def split_long(ob, longest=0.06):
    """Split every edge longer than `longest` until none is: the facets look the same (the new triangles lie in them)
    but there are enough corners for the cloth to bend. Decimating leaves the flattest parts, like the jacket's front,
    in triangles up to 17 cm long, which can't follow a raised thigh while the pockets on them do."""
    bm = bmesh.new(); bm.from_mesh(ob.data)
    for _ in range(6):
        long = [e for e in bm.edges if e.calc_length() > longest]
        if not long: break
        bmesh.ops.subdivide_edges(bm, edges=long, cuts=1)
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 3])
    bm.to_mesh(ob.data); bm.free(); ob.data.update()
    for p in ob.data.polygons: p.use_smooth = False


OLD = {n: surface(bpy.data.objects[n]) for n in ("HC_Jacket", "HC_Hoodie")}
OLD_RX = 0.200                                     # the old jacket's half-width (it was the same all the way down)
jacket = replace("HC_Jacket", shell("HC_Jacket_new", build_jacket_body, "jacket", 700, 0.008, 2))
sleeves = replace("HC_Sleeves", shell("HC_Sleeves_new", build_sleeves, "jacket", 480, 0.008, 2))
hood = replace("HC_Hood", shell("HC_Hood_new", build_hood, "hoodie", 200, 0.008, 3))
hoodie = replace("HC_Hoodie", plain("HC_Hoodie_new", build_hoodie, "hoodie"))
for ob in (jacket, sleeves, hood):
    split_long(ob)


# the pockets, flaps, buttons and lapels moved onto the new jacket (and the strings onto the new hoodie): drawn in a
# little towards the middle where the jacket is narrower, then each piece laid on a plane fitted to the jacket under it
# and brought forward just clear of its facets (following each facet made the pockets ripple), each vertex the same
# depth off that plane as it was off the old jacket
def pieces(me):
    """The vertex indices of each separate piece of a mesh."""
    adj = {i: set() for i in range(len(me.vertices))}
    for e in me.edges:
        i, j = e.vertices; adj[i].add(j); adj[j].add(i)
    seen, out = set(), []
    for i in adj:
        if i in seen: continue
        seen.add(i); stack, part = [i], []
        while stack:
            j = stack.pop(); part.append(j)
            for k in adj[j] - seen:
                seen.add(k); stack.append(k)
        out.append(part)
    return out


def plane_over(bvh, xs, zs):
    """y = a x + b z + c fitted to the surface under the box xs x zs, moved forward until no part of it is in front."""
    pts = []
    for i in range(7):
        for j in range(7):
            x = xs[0] + (xs[1] - xs[0]) * i / 6; z = zs[0] + (zs[1] - zs[0]) * j / 6
            y = ray_y(bvh, x, z)
            if y is not None: pts.append((x, z, y))
    n = len(pts)
    A = Matrix(((sum(p[0] * p[0] for p in pts), sum(p[0] * p[1] for p in pts), sum(p[0] for p in pts)),
                (sum(p[0] * p[1] for p in pts), sum(p[1] * p[1] for p in pts), sum(p[1] for p in pts)),
                (sum(p[0] for p in pts), sum(p[1] for p in pts), n)))
    r = Vector((sum(p[0] * p[2] for p in pts), sum(p[1] * p[2] for p in pts), sum(p[2] for p in pts)))
    a, b, c = 0.0, 0.0, sum(p[2] for p in pts) / n  # a piece too small to tilt (a button) stays level
    if min(xs[1] - xs[0], zs[1] - zs[0]) > 0.02:
        a, b, c = A.inverted() @ r
    c -= max(0.0, max(a * x + b * z + c - y for x, z, y in pts))
    return lambda x, z: a * x + b * z + c


NEW = {"HC_Jacket": surface(jacket), "HC_Hoodie": surface(hoodie)}
for name, on in (("HC_Pockets", "HC_Jacket"), ("HC_Flaps", "HC_Jacket"), ("HC_Buttons", "HC_Jacket"), ("HC_Collar", "HC_Jacket"),
                 ("HC_Strings", "HC_Hoodie")):
    me = bpy.data.objects[name].data
    for part in pieces(me):
        moved = []
        for i in part:
            c = me.vertices[i].co
            k = jacket_rx(c.z) / OLD_RX if on == "HC_Jacket" else 1.0
            x = c.x * k if abs(c.x) > opening(c.z) + 0.01 else c.x
            yo = ray_y(OLD[on], c.x, c.z)
            moved.append((i, x, c.y - yo if yo is not None else None))
        xs = (min(m[1] for m in moved), max(m[1] for m in moved))
        zs = (min(me.vertices[i].co.z for i in part), max(me.vertices[i].co.z for i in part))
        under = plane_over(NEW[on], xs, zs)
        for i, x, off in moved:
            c = me.vertices[i].co
            if off is not None:
                c.y = under(x, c.z) + off
            c.x = x
    me.update()
'''


def text(name, body):
    t = bpy.data.texts.get(name) or bpy.data.texts.new(name)
    t.clear(); t.write(body)


def only(*objects):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]


# --- The man, on his own ----------------------------------------------------------------------------------------
bpy.ops.wm.open_mainfile(filepath=HUMANS, load_ui=False, use_scripts=False)
for n in ("Human_Female", "Human_Female_rig"):
    o = bpy.data.objects[n]; d = o.data; bpy.data.objects.remove(o)
    if d.users == 0:
        (bpy.data.meshes if isinstance(d, bpy.types.Mesh) else bpy.data.armatures).remove(d)
rig = bpy.data.objects["Human_Male_rig"]; body = bpy.data.objects["Human_Male"]
rig.animation_data.action = None
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)

# --- The camper's parts and toolkit, from camper.blend (the toolkit's palette is reused) --------------------------
with bpy.data.libraries.load(CAMPER, link=False) as (src, dst):
    dst.objects = [n for n in src.objects if n.startswith("Camper_")]
    dst.texts = [n for n in src.texts if n.startswith("camper2")]
ref = bpy.data.collections.new("CamperRef"); bpy.context.scene.collection.children.link(ref)
for o in dst.objects:
    ref.objects.link(o)

# --- Stood like the camper, and that made his rest pose -----------------------------------------------------------
text("hcamper_pose", POSE_LIB); exec(POSE_LIB)
rig.data.pose_position = "POSE"
stand(rig, STAND)
only(body)
bpy.ops.object.modifier_apply(modifier=next(md for md in body.modifiers if md.type == "ARMATURE").name)
only(rig)
bpy.ops.object.mode_set(mode="POSE"); bpy.ops.pose.armature_apply(selected=False); bpy.ops.object.mode_set(mode="OBJECT")
md = body.modifiers.new("Armature", "ARMATURE"); md.object = rig

# --- The camper's clothes moved onto him --------------------------------------------------------------------------
text("hcamper_lib", LIB); exec(LIB)
coll = bpy.data.collections.new("HumanCamper"); bpy.context.scene.collection.children.link(coll)
man_leg = bone_line(rig, ["thigh_l", "thigh_l.001"])
man_arm = bone_line(rig, ["Hum_l", "Hum_l.001", "Hum_l.002"])
fb = rig.data.bones["FOOT_L"]; d = fb.tail_local - fb.head_local
foot_yaw = math.atan2(d.x, -d.y)
pv = Vector(CAMPER_HEAD_TURN["pivot"])
HT = (Matrix.Translation(pv) @ Matrix.Rotation(CAMPER_HEAD_TURN["turn"], 4, "Z") @ Matrix.Rotation(CAMPER_HEAD_TURN["nod"], 4, "X")
      @ Matrix.Rotation(CAMPER_HEAD_TURN["tilt"], 4, "Y") @ Matrix.Translation(-pv))
HTi = HT.inverted()
PARTS = {"Jacket": "torso", "Hoodie": "torso", "Hood": "torso", "TShirt": "torso", "Strings": "torso", "Collar": "torso",
         "Pockets": "torso", "Flaps": "torso", "Buttons": "torso", "Sleeves": "arm", "Jeans": "jeans", "JeansCuffs": "leg",
         "Boots": "boot", "Soles": "boot", "BeanieCuff": "head", "BeanieCrown": "head", "Pompom": "head", "Nose": "head"}
FN = {"torso": warp_torso, "arm": lambda v: warp_arm(v, man_arm), "jeans": lambda v: warp_jeans(v, man_leg),
      "leg": lambda v: warp_leg(v, man_leg), "boot": lambda v: warp_boot(v, man_leg, foot_yaw),
      "head": lambda v: warp_head((HTi @ v.to_4d()).to_3d())}
for part, kind in PARTS.items():
    warped_copy("Camper_" + part, "HC_" + part, FN[kind], coll)

# --- His body: the camper's skin colour; covered parts taken away; neck fuller; hands in the camper's style --------
exec(bpy.data.texts["camper2_lib"].as_string())
body.data.materials.clear(); body.data.materials.append(M("skin"))
full = body.copy(); full.data = body.data.copy(); full.name = "_BodyFull"; full.data.name = "_BodyFull"
bpy.context.scene.collection.objects.link(full)     # his whole body, kept for the weights
names = {g.index: g.name for g in body.vertex_groups}
HAND = ("Hum_l.002", "Hum_r.002", "HAND2", "thumb", "pink", "ring", "mid_", "point")
def dominant(v):
    return names[max(v.groups, key=lambda g: g.weight).group] if v.groups else None
hand_v, head_v = set(), set()
for v in body.data.vertices:
    dn = dominant(v); c = v.co
    if dn and any(dn.startswith(h) for h in HAND) and c.z < 0.95: hand_v.add(v.index)
    if c.z > 1.465 and (c.z > 1.535 or math.hypot(c.x, c.y - 0.085) < 0.075): head_v.add(v.index)
keep_i = {p.index for p in body.data.polygons
          if all(i in hand_v for i in p.vertices) or all(i in head_v for i in p.vertices)}
bm = bmesh.new(); bm.from_mesh(body.data)
bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep_i], context="FACES")
bm.to_mesh(body.data); bm.free(); body.data.update()
for v in body.data.vertices:                         # his neck a little fuller (r ~0.047 -> ~0.055), easing off under the jaw
    c = v.co
    if 1.455 < c.z < 1.565:
        dv = Vector((c.x, c.y - 0.085))
        if dv.length < 0.075:
            k = 1.0 + 0.17 * (1.0 - smooth(1.53, 1.562, c.z))
            c.x = dv.x * k; c.y = 0.085 + dv.y * k
body.data.update()
# his hands: taken out of the body, closed at the wrist, fused, relaxed and cut to big flat facets
hand_v = {v.index for v in body.data.vertices if v.co.z < 0.95 and v.groups and any(dominant(v).startswith(h) for h in HAND)}
bm = bmesh.new(); bm.from_mesh(body.data)
hand_f = [f for f in bm.faces if all(v.index in hand_v for v in f.verts)]
hb = bmesh.new(); vmap = {}
for f in hand_f:
    for v in f.verts:
        if v not in vmap: vmap[v] = hb.verts.new(v.co)
    hb.faces.new([vmap[v] for v in f.verts])
bmesh.ops.delete(bm, geom=hand_f, context="FACES")
bm.to_mesh(body.data); bm.free(); body.data.update()
bmesh.ops.remove_doubles(hb, verts=hb.verts[:], dist=0.0005)
bmesh.ops.holes_fill(hb, edges=[e for e in hb.edges if e.is_boundary], sides=0)
bmesh.ops.recalc_face_normals(hb, faces=hb.faces[:])
hme = bpy.data.meshes.new("HC_Hands_src"); hb.to_mesh(hme); hb.free()
hands = bpy.data.objects.new("HC_Hands", hme); coll.objects.link(hands)
dp = hands.modifiers.new("Inflate", "DISPLACE"); dp.strength = 0.0018; dp.mid_level = 0.0; dp.direction = "NORMAL"
rem = hands.modifiers.new("Remesh", "REMESH"); rem.mode = "VOXEL"; rem.voxel_size = 0.0065; rem.adaptivity = 0.0
sm = hands.modifiers.new("Relax", "LAPLACIANSMOOTH"); sm.iterations = 3; sm.lambda_factor = 1.0; sm.use_volume_preserve = True
n_hi = len(hands.evaluated_get(bpy.context.evaluated_depsgraph_get()).data.polygons)
dec = hands.modifiers.new("Facets", "DECIMATE"); dec.decimate_type = "COLLAPSE"; dec.ratio = min(1.0, 150 / max(n_hi, 1))
dec.use_symmetry = True; dec.symmetry_axis = "X"; dec.use_collapse_triangulate = True
lo = bpy.data.meshes.new_from_object(hands.evaluated_get(bpy.context.evaluated_depsgraph_get()))
hands.modifiers.clear(); hands.data = lo; lo.name = "HC_Hands"
bpy.data.meshes.remove(hme)
lo.materials.clear(); lo.materials.append(M("skin"))
for p in lo.polygons: p.use_smooth = False

# --- His hair: the camper's band under the cuff, pushed out where his head is fuller (the front stays inside) ------
hair = warped_copy("Camper_Hair", "HC_Hair", FN["head"], coll)
bvh = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
AX = Vector((0, 0.0635))
for v in hair.data.vertices:
    c = v.co
    dv = Vector((c.x, c.y)) - AX
    dirn = Vector((dv.x, dv.y, 0)).normalized()
    if dirn.y < -0.25:
        continue
    hit = bvh.ray_cast(Vector((AX.x, AX.y, c.z)), dirn, 0.3)[0]
    if hit is None: continue
    need = (Vector((hit.x, hit.y)) - AX).length + 0.007
    if dv.length < need:
        nd = dv.normalized() * need; c.x, c.y = AX.x + nd.x, AX.y + nd.y
hair.data.update()

# --- His jacket, sleeves, hood and hoodie, made again for him (CLOTHES, above) --------------------------------------
text("hcamper_clothes", CLOTHES); exec(CLOTHES)

# --- Every part skinned to his rig, from his own body's weights -----------------------------------------------------
text("hcamper_skin", SKIN); exec(SKIN)
FINGERS = ("HAND2", "thumb", "pink", "ring", "mid_", "point")
torso = lambda n: n in ("hips", "tum", "chest", "neck", "head", "000", "chest_L", "chest_R") or n.startswith("thigh")
arm = lambda n: n.startswith(("chest_L", "chest_R", "Hum_"))
leg = lambda n: n in ("hips", "tum", "000") or n.startswith(("thigh", "FOOT"))
foot = lambda n: n.startswith(("FOOT", "thigh_l.001", "thigh_r.001"))
hand = lambda n: n.startswith(FINGERS) or n.startswith(("Hum_l.00", "Hum_r.00"))
# "000" is a group in his file with no bone (his pelvis): its weight goes to the hips
TORSO_MAP = {"000": "hips", "thigh_l": "hips", "thigh_r": "hips", "thigh_l.001": "hips", "thigh_r.001": "hips", "head": "neck"}
ARM_MAP = {n + s: "Hum_%s.002" % s[-1] for n in FINGERS for s in ("_l", "_r")}
ARM_MAP.update({"%s_%s.%03d" % (n, s, k): "Hum_%s.002" % s for n in FINGERS for s in "lr" for k in (1, 2, 3)})
PLAN = {"Jacket": (torso, TORSO_MAP, None), "Hoodie": (torso, TORSO_MAP, None), "Hood": (torso, TORSO_MAP, None),
        "TShirt": (torso, TORSO_MAP, None), "Strings": (torso, TORSO_MAP, None), "Collar": (torso, TORSO_MAP, None),
        "Pockets": (torso, TORSO_MAP, None), "Flaps": (torso, TORSO_MAP, None), "Buttons": (torso, TORSO_MAP, None),
        "Sleeves": (arm, ARM_MAP, None), "Jeans": (leg, {"000": "hips"}, None), "JeansCuffs": (leg, None, None),
        "Boots": (foot, None, None), "Soles": (foot, None, None), "Hands": (hand, None, None),
        "Hair": (None, None, "head"), "BeanieCuff": (None, None, "head"), "BeanieCrown": (None, None, "head"),
        "Pompom": (None, None, "head"), "Nose": (None, None, "head")}
for part, (allow, remap, one) in PLAN.items():
    ob = bpy.data.objects["HC_" + part]
    skin_from_body(ob, full, allow=allow, remap=remap, only=one)
    ob.parent = rig; ob.matrix_parent_inverse.identity()
    md = ob.modifiers.new("Armature", "ARMATURE"); md.object = rig
body.parent = rig

# --- Tidied, named, centred on his feet --------------------------------------------------------------------------
for o in list(ref.objects):
    me = o.data; bpy.data.objects.remove(o)
    if me.users == 0: bpy.data.meshes.remove(me)
bpy.data.collections.remove(ref)
me = full.data; bpy.data.objects.remove(full); bpy.data.meshes.remove(me)
mat = bpy.data.materials.get("Human_Clay")
if mat and mat.users == 0: bpy.data.materials.remove(mat)
rig.name = "HumanCamper_rig"; rig.data.name = "HumanCamper_rig"
body.name = "HumanCamper_Body"; body.data.name = "HumanCamper_Body"
for o in list(coll.objects):
    if o.name.startswith("HC_"):
        o.name = "HumanCamper_" + o.name[3:]; o.data.name = o.name
for o in (body, rig):
    for c in list(o.users_collection):
        if c is not coll: c.objects.unlink(o)
    if o.name not in coll.objects: coll.objects.link(o)
parts = [o for o in coll.objects if o.type == "MESH"]
ws = [v.co for o in parts if o.name in ("HumanCamper_Boots", "HumanCamper_Soles") for v in o.data.vertices]
mid = Vector(((min(p.x for p in ws) + max(p.x for p in ws)) / 2, (min(p.y for p in ws) + max(p.y for p in ws)) / 2, 0))
for o in parts:
    o.data.transform(Matrix.Translation(-mid)); o.data.update()
# the bones moved with them, all at once: moving each bone's head and tail in edit mode moves a joint shared by
# connected bones two or three times (the first version did that, and every pose turned about the wrong points)
before = {b.name: (b.head_local.copy(), b.tail_local.copy()) for b in rig.data.bones}
rig.data.transform(Matrix.Translation(-mid))
for b in rig.data.bones:
    h, t = before[b.name]
    assert (b.head_local - (h - mid)).length < 1e-5 and (b.tail_local - (t - mid)).length < 1e-5, b.name
# and each joint still sits inside its limb: the knee, elbow and the head's pivot within the part round them
for bone, part, side in (("thigh_l.001", "HumanCamper_Jeans", 1), ("Hum_l.001", "HumanCamper_Sleeves", 1), ("head", "HumanCamper_Body", 0)):
    p = rig.data.bones[bone].head_local
    ring = [v.co for v in bpy.data.objects[part].data.vertices if abs(v.co.z - p.z) < 0.03 and (side == 0 or v.co.x * side > 0)]
    assert min(v.x for v in ring) < p.x < max(v.x for v in ring) and min(v.y for v in ring) < p.y < max(v.y for v in ring), (bone, tuple(p))

# --- The jeans' own weights, and the lower jacket and hoodie going partway with his thighs ------------------------
text("hcamper_weights", WEIGHTS); exec(WEIGHTS)
text("hcamper_test_poses", TEST_POSES)
O = bpy.data.objects
hip_y = rig.data.bones["thigh_l"].head_local.y
jeans_weights(O["HumanCamper_Jeans"])
for n, kind in (("Jacket", "body"), ("Sleeves", "sleeve"), ("Hood", "hood"), ("Hoodie", "hoodie"), ("Strings", "strings"),
                ("TShirt", "tshirt")):
    garment_weights(rig, O["HumanCamper_" + n], kind)
follow_thighs(O["HumanCamper_Jacket"], hip_y, top=1.10)      # over a longer stretch, so it bends gently under its pockets
for n in ("HumanCamper_Pockets", "HumanCamper_Flaps", "HumanCamper_Buttons", "HumanCamper_Collar", "HumanCamper_Hoodie"):
    skin_from_body(O[n], O["HumanCamper_Jacket"])     # the details and the hoodie's front move as the jacket under them

tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in parts)
ws = [v.co for o in parts for v in o.data.vertices]
print("HUMAN CAMPER", len(parts), "parts,", tris, "triangles, size %.3f x %.3f x %.3f m, lowest %.4f, feet moved by (%.4f, %.4f)" % (
    max(p.x for p in ws) - min(p.x for p in ws), max(p.y for p in ws) - min(p.y for p in ws),
    max(p.z for p in ws) - min(p.z for p in ws), min(p.z for p in ws), -mid.x, -mid.y))
# --- His animations (added 21 Oct 2026, from 20:35, at the author's request: "this human needs to walk, run(chase),
# bend and take away"): tools/blender/animate_human_camper.py keys walk, run, bend and take_away and holds the .glb's
# export settings, the ones this script used before (+Y up, deforming bones, skinned) with the animations turned on ---
ANIM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "animate_human_camper.py")
anim_src = open(ANIM, encoding="utf-8").read()
text("hcamper_animate", anim_src)
A = {"__name__": "hcamper_animate", "__file__": ANIM}
exec(compile(anim_src, ANIM, "exec"), A)
A["animate"](rig)
bpy.ops.wm.save_as_mainfile(filepath=OUT + ".blend", compress=True)
A["export_glb"](rig, OUT + ".glb")
print("SAVED", OUT + ".blend", "| EXPORTED", OUT + ".glb", os.path.getsize(OUT + ".glb"), "bytes")
