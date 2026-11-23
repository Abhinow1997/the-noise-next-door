# The chubby man: the author's download, "chubby boy" by TiZeta (Blend Swap 66415, made for Blender 2.65 in 2013;
# Creative Commons Attribution 3.0, so TiZeta must be credited), made ready for the game on 22 Oct 2026 at the
# author's request: "make the chubby boy game-ready like the humans: keep the download with its licence in
# design/downloads, scale him to game size on the ground, export a .glb with his walk, and log him with TiZeta's
# credit". Despite the file's name he's a grown man (moustache, red sweater, jeans), so he's sized as one.
#
# Like prepare_humans.py, Claude Code wrote this and ran it in a background Blender with the file's scripts switched
# off (it has none). It opens the download as it came, design/downloads/chubby/chubby.blend, and:
#   - keeps his mesh and his rig (20 bones, all deforming, named in Italian: root; bacino pelvis, addome belly,
#     schiena back, collo neck, testa head; bicipite upper arm, avambraccio forearm, mano hand; gamba thigh,
#     polpaccio shin, piede foot, avampiede toes; _L and _R), and leaves out the camera, the light and an empty text;
#   - keeps his walk ("cammina", 25 frames at 25 fps, walking on the spot), renamed "walk", and leaves out the file's
#     two other actions, a one-frame "idle" pose and an empty "bake";
#   - gives his material his own painted texture again (cicciotto.png, 1024 x 1024, packed in the file): the 2013
#     file linked it the old way, which Blender no longer reads, so as it came the texture didn't show or export;
#   - (added at the author's next request) gives his skin, his head, neck, ears and hands, the camper's flat skin colour
#     in a material of its own, so his painted face goes; takes off his moustache (a separate little piece); keeps his
#     own modelled nose. His clothes, hair and shoes keep TiZeta's texture;
#   - (and at the one after that) evens out the front of his face, which flattens his small nose too; a bigger red
#     nose was tried and, at the author's word, taken off again, so he has no nose;
#   - (and then) gives him chunky, arched cartoon eyebrows, the only thing on his face;
#   - (when the author made him the camper) puts the camper's red beanie and pompom from camper.blend on him, as a
#     part of its own on his head bone (ChubbyBoy_Beanie), so the game can hide it when he loses it;
#   - stands him on the ground with the middle of his feet at the origin, facing the front (-Y in Blender, +Z in
#     Godot), at HEIGHT metres tall, in his own standing pose, with his walk's root movement scaled with him;
#   - (for his animations) runs tools/blender/animate_chubby.py, which keys walk (in place of TiZeta's), run, bend
#     and take_away;
# then saves assets/characters/chubby_boy.blend and exports assets/characters/chubby_boy.glb. Otherwise his shape and
# smooth shading are as TiZeta made them.
#
# Run it from the repository's folder (Windows, Git Bash); set CHUBBY_OUT to a path without an extension to write
# the .blend and .glb somewhere else (a test):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --disable-autoexec --factory-startup \
#       --python-exit-code 1 design/downloads/chubby/chubby.blend --python tools/blender/prepare_chubby.py

import bpy, bmesh, colorsys, math, os
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE = os.path.join(REPO, "design", "downloads", "chubby", "chubby.blend")
OUT = os.environ.get("CHUBBY_OUT") or os.path.join(REPO, "assets", "characters", "chubby_boy")

# The camper's figure is 1.78 m; a stocky man a little shorter.
HEIGHT = 1.72
ROUGHNESS = 0.85        # matte, like the game's other characters
SKIN, SKIN_ROUGHNESS = "C99C85", 0.6   # the camper's skin (camper.blend's C2_skin)
SKIN_FLAT = False       # True cuts his skin to flat facets like the camper's, but that shows his modelled mouth and
                        # brow as hard edges; smooth (like his clothes) leaves a clean face with just his nose
FACE_SMOOTH_PASSES = 6  # his face's shape (mouth, brow, his own small nose) evened out
# his cartoon eyebrows: height of their inner ends, gap from the middle, length, thickness, arch (m), colour
BROW = dict(z=1.628, gap=0.011, length=0.040, thick=0.011, arch=0.008, colour="3E2A1E", roughness=0.9)
# the camper's beanie (camper.blend), fitted to his head: (camper's cuff centre, where it goes on him), scale x y z
CAMPER = os.path.join(REPO, "assets", "characters", "camper.blend")
BEANIE_PARTS = ("Camper_BeanieCuff", "Camper_BeanieCrown", "Camper_Pompom")
CAMPER_HEAD_TURN = dict(turn=-0.1563, nod=0.0264, tilt=0.0474, pivot=(0, 0.01, 1.40))   # camper2_parts' head_matrix
BEANIE = dict(anchor=(Vector((0, 0.008, 1.607)), Vector((0, -0.004, 1.637))), scale=(0.90, 1.0, 0.85),
              colour="AC453B", roughness=0.9)                                          # the camper's C2_beanie


def only(*objects):
    bpy.context.view_layer.update()
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]


def fcurves(action):
    try:
        return list(action.fcurves)
    except AttributeError:             # layered actions (Blender 4.4 and later)
        return [fc for layer in action.layers for strip in layer.strips for cb in strip.channelbags for fc in cb.fcurves]


def pose_matrices(rig, frame):
    bpy.context.scene.frame_set(frame)
    return {pb.name: pb.matrix.copy() for pb in rig.pose.bones}


assert os.path.abspath(bpy.data.filepath) == os.path.abspath(SOURCE), bpy.data.filepath
rig = bpy.data.objects["Armature"]
body = bpy.data.objects["maglia"]
if bpy.context.mode != "OBJECT":       # the file was saved in Pose mode
    bpy.ops.object.mode_set(mode="OBJECT")

# --- Him alone, with his walk --------------------------------------------------------------------------------------
for ob in list(bpy.data.objects):
    if ob not in (rig, body):
        bpy.data.objects.remove(ob)
for t in list(bpy.data.texts):
    bpy.data.texts.remove(t)
walk = bpy.data.actions["cammina"]
for a in list(bpy.data.actions):
    if a is not walk:
        bpy.data.actions.remove(a)
walk.name = "walk"
walk.use_fake_user = True
rig.animation_data.action = walk
if hasattr(rig.animation_data, "action_slot") and rig.animation_data.action_slot is None and len(walk.slots):
    rig.animation_data.action_slot = walk.slots[0]
rig.data.pose_position = "POSE"

# --- His texture, wired in again ---------------------------------------------------------------------------------
image = bpy.data.images["cicciotto.png"]
mat = body.data.materials[0]
mat.name = "ChubbyBoy"
nt = mat.node_tree
nt.nodes.clear()
out = nt.nodes.new("ShaderNodeOutputMaterial")
bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = image
tex.location, bsdf.location, out.location = (-400, 0), (-100, 0), (200, 0)
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
bsdf.inputs["Roughness"].default_value = ROUGHNESS
nt.nodes.active = tex

# --- His skin in the game's style (added 22 Oct 2026, 01:02, at the author's request: "update the model to match the
# man's skin to the game's style also remove the face features only keep or create nose just the skin nothing to
# clothes"): his head, neck, ears and hands in the camper's flat skin colour, so the painted eyes, brows and mouth go;
# his moustache (a little separate piece in front of his mouth) taken off; his own modelled nose kept. His clothes,
# hair and shoes keep TiZeta's texture.
skin = bpy.data.materials.new("ChubbyBoy_Skin")
snt = skin.node_tree if skin.node_tree else None
if snt is None:
    skin.use_nodes = True; snt = skin.node_tree
sb = next(n for n in snt.nodes if n.type == "BSDF_PRINCIPLED")
srgb = [int(SKIN[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
lin = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
sb.inputs["Base Color"].default_value = (*lin, 1.0)
sb.inputs["Roughness"].default_value = SKIN_ROUGHNESS
skin.diffuse_color = (*lin, 1.0)
body.data.materials.append(skin)

W, H = image.size
pixels = list(image.pixels)
def texel(uv):
    x = min(W - 1, max(0, int(uv.x * W))); y = min(H - 1, max(0, int(uv.y * H)))
    i = (y * W + x) * 4
    return pixels[i:i + 3]
gnames = {g.index: g.name for g in body.vertex_groups}
bm = bmesh.new(); bm.from_mesh(body.data)
uvl = bm.loops.layers.uv.active
dl = bm.verts.layers.deform.active
# the moustache: a separate piece of the mesh, small, moved only by his head; then the loose points with no faces
pieces, seen = [], set()
for v in bm.verts:
    if v in seen: continue
    stack, piece = [v], []
    seen.add(v)
    while stack:
        u = stack.pop(); piece.append(u)
        for e in u.link_edges:
            w = e.other_vert(u)
            if w not in seen: seen.add(w); stack.append(w)
    pieces.append(piece)
def head_only(v):
    return v[dl] and gnames[max(v[dl].items(), key=lambda kv: kv[1])[0]] == "testa"
moustache = [p for p in pieces if 3 < len(p) < 30 and all(head_only(v) for v in p)]
assert len(moustache) == 1, [len(p) for p in moustache]
loose = [v for p in pieces if len(p) <= 3 for v in p if not v.link_faces]
bmesh.ops.delete(bm, geom=moustache[0] + loose, context="VERTS")
# the skin: the texture's islands (pieces of the picture) whose middle colour is skin, not the hair, cloth or shoes
def uvkey(l): return (round(l[uvl].uv.x, 5), round(l[uvl].uv.y, 5))
islands, seen = [], set()
for f in bm.faces:
    if f in seen: continue
    stack, isl = [f], []
    seen.add(f)
    while stack:
        g = stack.pop(); isl.append(g)
        for l in g.loops:
            for lo in l.edge.link_loops:
                h = lo.face
                if h not in seen and {uvkey(l), uvkey(l.link_loop_next)} == {uvkey(lo), uvkey(lo.link_loop_next)}:
                    seen.add(h); stack.append(h)
    islands.append(isl)
skin_faces = 0
for isl in islands:
    cols = sorted((texel(sum((l[uvl].uv for l in f.loops), Vector((0, 0))) / len(f.loops)) for f in isl), key=lambda c: sum(c))
    hue, sat, val = colorsys.rgb_to_hsv(*cols[len(cols) // 2])
    if hue < 0.1 and 0.25 < sat < 0.6 and val > 0.6:
        for f in isl:
            f.material_index = 1
            f.smooth = not SKIN_FLAT
        skin_faces += len(isl)
bm.to_mesh(body.data); bm.free(); body.data.update()
print("SKIN %d faces in the camper's skin colour; moustache (%d points) and %d loose points taken off" % (
    skin_faces, len(moustache[0]), len(loose)))

# --- On the ground, centred on his feet, at his height: the rig and his mesh moved and scaled together ----------
ws = [body.matrix_world @ v.co for v in body.data.vertices]          # his rest shape, not the walk's pose
lo = Vector((min(w.x for w in ws), min(w.y for w in ws), min(w.z for w in ws)))
hi = Vector((max(w.x for w in ws), max(w.y for w in ws), max(w.z for w in ws)))
feet = [w for w in ws if w.z < lo.z + 0.03 * (hi.z - lo.z)]
mid = Vector(((min(w.x for w in feet) + max(w.x for w in feet)) / 2, (min(w.y for w in feet) + max(w.y for w in feet)) / 2, lo.z))
s = HEIGHT / (hi.z - lo.z)
body.parent = rig
only(rig, body)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
rig.location = -mid * s
rig.scale = (s, s, s)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# the walk's bone movements (the root's bob and sway) were in the old size's units
for fc in fcurves(walk):
    if fc.data_path.endswith(".location"):
        for k in fc.keyframe_points:
            k.co[1] *= s; k.handle_left[1] *= s; k.handle_right[1] *= s
        fc.update()
rig.name = "ChubbyBoy_rig"
rig.data.name = "ChubbyBoy_rig"
body.name = "ChubbyBoy"
body.data.name = "ChubbyBoy"


def lowest_while_walking():
    out = []
    for f in range(start, end + 1):
        bpy.context.scene.frame_set(f)
        ev = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
        out.append(min((body.matrix_world @ v.co).z for v in ev.data.vertices))
    bpy.context.scene.frame_set(start)
    return out


# --- His walk brought down to the ground: as it came, its root is keyed so high that he never touches it -----------
start, end = (int(round(f)) for f in walk.frame_range)
drop = min(lowest_while_walking())
local = rig.data.bones["root"].matrix_local.to_3x3().inverted() @ Vector((0, 0, -drop))   # in the root bone's axes
for fc in fcurves(walk):
    if fc.data_path == 'pose.bones["root"].location':
        for k in fc.keyframe_points:
            d = local[fc.array_index]
            k.co[1] += d; k.handle_left[1] += d; k.handle_right[1] += d
        fc.update()

# --- A smoother face (added 22 Oct 2026, 01:08, at the author's request: "make the face smother and have a bigger
# nose a bit red"): the front of his head evened out, which also flattens his own small nose. A bigger, round, slightly
# red nose was made too, then taken off at the author's word, "noo its too big remvoe the nose", so he has none ------
bm = bmesh.new(); bm.from_mesh(body.data)
dl = bm.verts.layers.deform.active
gi = {g.name: g.index for g in body.vertex_groups}
def on_head(v):
    w = v[dl]
    return w and max(w.items(), key=lambda kv: kv[1])[0] in (gi["testa"], gi["collo"])
head_skin = {v for f in bm.faces if f.material_index == 1 and all(on_head(v) for v in f.verts) for v in f.verts}
cy = (min(v.co.y for v in head_skin) + max(v.co.y for v in head_skin)) / 2
# the face: the front half of his head's skin, away from his ears; points shared with his hair or collar stay put
face = [v for v in head_skin if v.co.y < cy - 0.02 and abs(v.co.x) < 0.075 and all(f.material_index == 1 for f in v.link_faces)]
for _ in range(FACE_SMOOTH_PASSES):
    bmesh.ops.smooth_vert(bm, verts=face, factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
bm.normal_update()
bm.to_mesh(body.data); bm.free(); body.data.update()
print("FACE %d points evened out" % len(face))

# --- Cartoon eyebrows, and nothing else on his face (added 22 Oct 2026, 01:15, at the author's request: "can we have
# cartoon like eyebrows only eye brows"): each a chain of flattened blobs laid along an arch on his face, full at the
# inner end and tapering outwards, fused into one smooth shape and moved by his head ---------------------------------
def lin_rgb(h):
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]

bm = bmesh.new(); bm.from_mesh(body.data)
bm.normal_update()
dl = bm.verts.layers.deform.active
bvh = BVHTree.FromBMesh(bm)
def on_face(x, z, out):
    """The point on his face straight in front of (x, z), lifted `out` along the face's normal there."""
    loc, nor, i, d = bvh.ray_cast(Vector((x, -1.0, z)), Vector((0, 1, 0)))
    return loc + nor * out
hi = bmesh.new()
for s in (1, -1):                          # his left brow (+X), then his right
    n = 15
    for i in range(n):
        t = i / (n - 1)                    # 0 at the inner end, 1 at the outer end
        x = s * (BROW["gap"] + BROW["length"] * t)
        z = BROW["z"] + BROW["arch"] * math.sin(math.pi * min(1.0, t * 1.15)) - 0.004 * t   # arched, the outer end a bit lower
        r = BROW["thick"] * (0.75 + 0.3 * math.sin(math.pi * min(1.0, t / 0.7))) * (1.0 - 0.5 * t ** 1.6)
        bmesh.ops.create_uvsphere(hi, u_segments=10, v_segments=6, radius=r,
                                  matrix=Matrix.Translation(on_face(x, z, BROW["thick"] * 0.35)) @ Matrix.Diagonal((1.0, 0.55, 1.0, 1.0)))
me_hi = bpy.data.meshes.new("_brows"); hi.to_mesh(me_hi); hi.free()
tmp = bpy.data.objects.new("_brows", me_hi); bpy.context.scene.collection.objects.link(tmp)
rem = tmp.modifiers.new("Remesh", "REMESH"); rem.mode = "VOXEL"; rem.voxel_size = 0.0012; rem.adaptivity = 0.0
sm = tmp.modifiers.new("Relax", "LAPLACIANSMOOTH"); sm.iterations = 4; sm.lambda_factor = 1.0; sm.use_volume_preserve = True
n_hi = len(tmp.evaluated_get(bpy.context.evaluated_depsgraph_get()).data.polygons)
dec = tmp.modifiers.new("Facets", "DECIMATE"); dec.decimate_type = "COLLAPSE"; dec.ratio = min(1.0, 150 / max(n_hi, 1))
dec.use_symmetry = True; dec.symmetry_axis = "X"; dec.use_collapse_triangulate = True
lo_me = bpy.data.meshes.new_from_object(tmp.evaluated_get(bpy.context.evaluated_depsgraph_get()))
bpy.data.objects.remove(tmp); bpy.data.meshes.remove(me_hi)
brow_mat = bpy.data.materials.new("ChubbyBoy_Brows")
if brow_mat.node_tree is None:
    brow_mat.use_nodes = True
bb = next(nd for nd in brow_mat.node_tree.nodes if nd.type == "BSDF_PRINCIPLED")
bc = lin_rgb(BROW["colour"])
bb.inputs["Base Color"].default_value = (*bc, 1.0)
bb.inputs["Roughness"].default_value = BROW["roughness"]
brow_mat.diffuse_color = (*bc, 1.0)
body.data.materials.append(brow_mat)
brow_index = len(body.data.materials) - 1
head_group = body.vertex_groups["testa"].index
vmap = {}
for v in lo_me.vertices:
    nv = bm.verts.new(v.co); nv[dl][head_group] = 1.0; vmap[v.index] = nv
brow_tris = 0
for p in lo_me.polygons:
    vs = [vmap[i] for i in p.vertices]
    if len(set(vs)) < 3 or bm.faces.get(vs) is not None:     # the decimate can leave a doubled face
        continue
    f = bm.faces.new(vs); f.material_index = brow_index; f.smooth = True; brow_tris += 1
bpy.data.meshes.remove(lo_me)
bm.to_mesh(body.data); bm.free(); body.data.update()
print("BROWS %d triangles, #%s" % (brow_tris, BROW["colour"]))

# --- The camper's red beanie (added 22 Oct 2026, 01:28, when the author made him the camper: "Yes, give the chubby man
# the camper's red beanie with its pompom, on his head bone, so he can lose it like in the story"): the cuff, crown and
# pompom from camper.blend, as they are there (big flat facets, the camper's red), turned back to face the front, then
# fitted to his head: 90% as wide, as deep, 85% as tall, its cuff just above his eyebrows and tipped back as the
# camper wears it. It's a part of its own, ChubbyBoy_Beanie, all on his head bone, so the game can hide it when he
# loses it (assets/props/beanie_dropped.glb is the same beanie crumpled on the ground) ------------------------------
with bpy.data.libraries.load(CAMPER, link=False) as (src, dst):
    dst.objects = [n for n in src.objects if n in BEANIE_PARTS]
pv = Vector(CAMPER_HEAD_TURN["pivot"])
HT = (Matrix.Translation(pv) @ Matrix.Rotation(CAMPER_HEAD_TURN["turn"], 4, "Z") @ Matrix.Rotation(CAMPER_HEAD_TURN["nod"], 4, "X")
      @ Matrix.Rotation(CAMPER_HEAD_TURN["tilt"], 4, "Y") @ Matrix.Translation(-pv))
(cam_anchor, his_anchor), fit = BEANIE["anchor"], BEANIE["scale"]
FIT = Matrix.Translation(his_anchor) @ Matrix.Diagonal((*fit, 1.0)) @ Matrix.Translation(-cam_anchor) @ HT.inverted()
bm = bmesh.new()
for o in sorted(dst.objects, key=lambda o: o.name):
    me = o.data.copy(); me.transform(FIT); bm.from_mesh(me)
    camper_me = o.data
    bpy.data.objects.remove(o); bpy.data.meshes.remove(me)
    if camper_me.users == 0: bpy.data.meshes.remove(camper_me)
for m in [m for m in bpy.data.materials if m.name.startswith("C2_") and m.users == 0]:
    bpy.data.materials.remove(m)
for f in bm.faces:
    f.smooth = False; f.material_index = 0
beanie_me = bpy.data.meshes.new("ChubbyBoy_Beanie"); bm.to_mesh(beanie_me); bm.free()
beanie_mat = bpy.data.materials.new("ChubbyBoy_Beanie")
if beanie_mat.node_tree is None:
    beanie_mat.use_nodes = True
eb = next(nd for nd in beanie_mat.node_tree.nodes if nd.type == "BSDF_PRINCIPLED")
ec = lin_rgb(BEANIE["colour"])
eb.inputs["Base Color"].default_value = (*ec, 1.0)
eb.inputs["Roughness"].default_value = BEANIE["roughness"]
beanie_mat.diffuse_color = (*ec, 1.0)
beanie_me.materials.append(beanie_mat)
beanie = bpy.data.objects.new("ChubbyBoy_Beanie", beanie_me)
for c in body.users_collection:
    c.objects.link(beanie)
beanie.parent = rig
beanie.vertex_groups.new(name="testa").add(range(len(beanie_me.vertices)), 1.0, "REPLACE")
beanie.modifiers.new("Armature", "ARMATURE").object = rig
# nothing of his head or hair may show through it: every point his head bone moves that's more than 1.2 cm above the
# cuff's lower edge on its side must have the beanie between it and the outside (his brows and the hair at the rim show)
bvh = BVHTree.FromPolygons([v.co.copy() for v in beanie_me.vertices], [tuple(p.vertices) for p in beanie_me.polygons])   # at rest, as his head is
bws = [v.co for v in beanie_me.vertices]
cuff_low = min(w.z for w in bws)
mid = Vector((sum(w.x for w in bws) / len(bws), sum(w.y for w in bws) / len(bws), 0))
def lowest_edge(angle):                   # the beanie's lowest point in this direction (within 10 degrees)
    near = [w.z for w in bws if abs(math.remainder(math.atan2(w.y - mid.y, w.x - mid.x) - angle, 2 * math.pi)) < math.radians(10)]
    return min(near) if near else cuff_low
outside = 0
for v in body.data.vertices:
    if not v.groups or body.vertex_groups[max(v.groups, key=lambda g: g.weight).group].name != "testa":
        continue
    a = math.atan2(v.co.y - mid.y, v.co.x - mid.x)
    if v.co.z > lowest_edge(a) + 0.012:
        out = Vector((math.cos(a), math.sin(a), 0))     # looking in from outside, the beanie must come before the point
        outside += bvh.ray_cast(v.co + out * 0.5, -out, 0.5)[0] is None
beanie_tris = sum(len(p.vertices) - 2 for p in beanie_me.polygons)
print("BEANIE %d triangles, %.3f x %.3f x %.3f m, its lowest edge at %.3f m, %d of his head's points poking out" % (
    beanie_tris, max(w.x for w in bws) - min(w.x for w in bws), max(w.y for w in bws) - min(w.y for w in bws),
    max(w.z for w in bws) - min(w.z for w in bws), cuff_low, outside))

# --- What he is now ------------------------------------------------------------------------------------------------
ws = [body.matrix_world @ v.co for v in body.data.vertices]
size = Vector((max(w.x for w in ws) - min(w.x for w in ws), max(w.y for w in ws) - min(w.y for w in ws),
               max(w.z for w in ws) - min(w.z for w in ws)))
first, last = pose_matrices(rig, start), pose_matrices(rig, end)
seam = max((first[n].translation - last[n].translation).length for n in first)
low = lowest_while_walking()
print("walk lowered by %.4f m" % drop)
print("CHUBBY", sum(len(p.vertices) - 2 for p in body.data.polygons), "triangles,", len(rig.data.bones), "bones,",
      "size %.3f x %.3f x %.3f m, lowest %.3f" % (tuple(size) + (min(w.z for w in ws),)),
      "| walk frames %d-%d at %d fps, first and last poses %.4f m apart," % (start, end, bpy.context.scene.render.fps, seam),
      "lowest point while walking %.3f..%.3f m" % (min(low), max(low)))

# --- His animations (added 22 Oct 2026, from 01:40, when the author made him the camper: "work on creating the
# animations for this model"): tools/blender/animate_chubby.py keys walk (in place of TiZeta's, measured above, whose
# feet slide), run, bend and take_away, and holds the .glb's export settings, the ones used here before with every
# frame sampled ---------------------------------------------------------------------------------------------------
ANIM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "animate_chubby.py")
anim_src = open(ANIM, encoding="utf-8").read()
bpy.data.texts.new("chubby_animate").write(anim_src)
A = {"__name__": "chubby_animate", "__file__": ANIM}
exec(compile(anim_src, ANIM, "exec"), A)
A["animate"](rig, body)
bpy.ops.wm.save_as_mainfile(filepath=OUT + ".blend", compress=True)
A["export_glb"](rig, OUT + ".glb")
print("SAVED", OUT + ".blend", "| EXPORTED", OUT + ".glb", os.path.getsize(OUT + ".glb"), "bytes")
