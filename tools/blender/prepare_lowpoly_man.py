# The low-poly man: the author's download, "Lowpoly man" by TiZeta (Blend Swap 66412, made for Blender 2.65 in 2013;
# Creative Commons Attribution 3.0, so TiZeta must be credited), made ready for the game on 23 Oct 2026 at the
# author's request: "ok lets create the same like we have done for the chubby guy for this guy as well and add him in
# the assets and charaters". He's by the same artist as the chubby man, with the same rig, so he's done the same way
# (tools/blender/prepare_chubby.py): a slim man in a ribbed grey sweater, flared jeans and black shoes, blond.
#
# Claude Code wrote this and ran it in a background Blender with the file's scripts switched off (it has none). It
# opens the download as it came, design/downloads/lowpoly_man/simpleMan2.6.blend, and:
#   - keeps his mesh ("uomo") and his rig (20 bones, all deforming, named in Italian as the chubby man's: root; bacino
#     pelvis, addome belly, schiena back, collo neck, testa head; bicipite upper arm, avambraccio forearm, mano hand;
#     gamba thigh, polpaccio shin, piede foot, avampiede toes; the _R bones are his left), and leaves out the camera
#     and the light. His walk ("walkLikeMan") is left out too: his animations are made new, as the chubby man's were
#     (it's still in the download);
#   - gives his material his own painted texture again (OMO1.PNG, 1024 x 1024, packed in the file), which the 2013
#     file linked the old way, so as it came it didn't show or export;
#   - gives his skin, his head, neck, ears and hands, the camper's flat skin colour in a material of its own, so his
#     painted face (eyes, brows, mouth and stubble) goes; his clothes, hair and shoes keep TiZeta's texture;
#   - evens out the front of his face, which flattens his nose too, as the chubby man's was;
#   - gives him chunky, arched cartoon eyebrows, a darker shade of his blond hair, the only thing on his face;
#   - stands him on the ground with the middle of his feet at the origin, facing the front (-Y in Blender, +Z in
#     Godot), at HEIGHT metres tall, in his own standing pose;
#   - runs tools/blender/animate_lowpoly_man.py, which keys walk, run, bend and take_away;
# then saves assets/characters/lowpoly_man.blend and exports assets/characters/lowpoly_man.glb. He doesn't wear the
# camper's red beanie: the chubby man is the camper. Otherwise his shape and smooth shading are as TiZeta made them.
#
# Run it from the repository's folder (Windows, Git Bash); set LOWPOLY_MAN_OUT to a path without an extension to write
# the .blend and .glb somewhere else (a test):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --disable-autoexec --factory-startup \
#       --python-exit-code 1 design/downloads/lowpoly_man/simpleMan2.6.blend --python tools/blender/prepare_lowpoly_man.py

import bpy, bmesh, colorsys, math, os
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE = os.path.join(REPO, "design", "downloads", "lowpoly_man", "simpleMan2.6.blend")
OUT = os.environ.get("LOWPOLY_MAN_OUT") or os.path.join(REPO, "assets", "characters", "lowpoly_man")

# The camper's figure is 1.78 m and the chubby man 1.72 m; a slim man a little taller.
HEIGHT = 1.80
ROUGHNESS = 0.85        # matte, like the game's other characters
SKIN, SKIN_ROUGHNESS = "C99C85", 0.6   # the camper's skin (camper.blend's C2_skin), as on the chubby man
FACE_SMOOTH_PASSES = 6  # his face's shape (mouth, brow, nose) evened out
# his cartoon eyebrows: height of their inner ends, gap from the middle, length, thickness, arch (m), colour
BROW = dict(z=1.682, gap=0.011, length=0.038, thick=0.010, arch=0.007, colour="6B4F2A", roughness=0.9)


def only(*objects):
    bpy.context.view_layer.update()
    for o in bpy.context.selected_objects:
        o.select_set(False)
    for o in objects:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]


def lin_rgb(h):
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


def flat_material(name, hexc, roughness):
    m = bpy.data.materials.new(name)
    if m.node_tree is None:
        m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    c = lin_rgb(hexc)
    b.inputs["Base Color"].default_value = (*c, 1.0)
    b.inputs["Roughness"].default_value = roughness
    m.diffuse_color = (*c, 1.0)
    return m


assert os.path.abspath(bpy.data.filepath) == os.path.abspath(SOURCE), bpy.data.filepath
rig = bpy.data.objects["Armature"]
body = bpy.data.objects["uomo"]
if bpy.context.mode != "OBJECT":       # the file was saved in Pose mode
    bpy.ops.object.mode_set(mode="OBJECT")

# --- Him alone, at rest ------------------------------------------------------------------------------------------
for ob in list(bpy.data.objects):
    if ob not in (rig, body):
        bpy.data.objects.remove(ob)
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)
rig.animation_data_clear()
for pb in rig.pose.bones:
    pb.location = (0, 0, 0); pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = (1, 0, 0, 0); pb.scale = (1, 1, 1)
rig.data.pose_position = "POSE"

# --- His texture, wired in again ---------------------------------------------------------------------------------
image = bpy.data.images["OMO1.PNG"]
mat = body.data.materials[0]
mat.name = "LowpolyMan"
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

# --- His skin in the game's style: his head, neck, ears and hands in the camper's flat skin colour, so the painted
# face goes. The skin is the texture's islands (pieces of the picture) whose middle colour is skin -----------------
body.data.materials.append(flat_material("LowpolyMan_Skin", SKIN, SKIN_ROUGHNESS))
W, H = image.size
pixels = list(image.pixels)
def texel(uv):
    x = min(W - 1, max(0, int(uv.x * W))); y = min(H - 1, max(0, int(uv.y * H)))
    i = (y * W + x) * 4
    return pixels[i:i + 3]
bm = bmesh.new(); bm.from_mesh(body.data)
uvl = bm.loops.layers.uv.active
loose = [v for v in bm.verts if not v.link_faces]
bmesh.ops.delete(bm, geom=loose, context="VERTS")
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
skin_faces, hair_cols = 0, []
for isl in islands:
    cols = sorted((texel(sum((l[uvl].uv for l in f.loops), Vector((0, 0))) / len(f.loops)) for f in isl), key=lambda c: sum(c))
    hue, sat, val = colorsys.rgb_to_hsv(*cols[len(cols) // 2])
    if hue < 0.1 and 0.2 < sat < 0.6 and val > 0.5:
        for f in isl:
            f.material_index = 1
        skin_faces += len(isl)
bm.to_mesh(body.data); bm.free(); body.data.update()
print("SKIN %d of %d faces in the camper's skin colour (%d islands); %d loose points taken off" % (
    skin_faces, len(body.data.polygons), len(islands), len(loose)))

# --- On the ground, centred on his feet, at his height: the rig and his mesh moved and scaled together ----------
ws = [body.matrix_world @ v.co for v in body.data.vertices]
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
rig.name = "LowpolyMan_rig"
rig.data.name = "LowpolyMan_rig"
body.name = "LowpolyMan"
body.data.name = "LowpolyMan"

# --- A smoother face: the front of his head evened out, which also flattens his nose --------------------------------
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

# --- Cartoon eyebrows, and nothing else on his face: each a chain of flattened blobs laid along an arch on his face,
# full at the inner end and tapering outwards, fused into one smooth shape and moved by his head ---------------------
bm = bmesh.new(); bm.from_mesh(body.data)
bm.normal_update()
dl = bm.verts.layers.deform.active
bvh = BVHTree.FromBMesh(bm)
def on_face(x, z, out):
    """The point on his face straight in front of (x, z), lifted `out` along the face's normal there, and the normal."""
    loc, nor, i, d = bvh.ray_cast(Vector((x, -1.0, z)), Vector((0, 1, 0)))
    return loc + nor * out, nor
def flat_on(nor, k):
    """A squash to k of its size along nor: his forehead slopes back, so the brows lie on it rather than stand off."""
    M = Matrix.Identity(3)
    for r in range(3):
        for c in range(3):
            M[r][c] -= (1 - k) * nor[r] * nor[c]
    return M.to_4x4()
hb = bmesh.new()
for side in (1, -1):                       # his left brow (+X), then his right
    n = 15
    for i in range(n):
        t = i / (n - 1)                    # 0 at the inner end, 1 at the outer end
        x = side * (BROW["gap"] + BROW["length"] * t)
        z = BROW["z"] + BROW["arch"] * math.sin(math.pi * min(1.0, t * 1.15)) - 0.004 * t   # arched, the outer end a bit lower
        r = BROW["thick"] * (0.75 + 0.3 * math.sin(math.pi * min(1.0, t / 0.7))) * (1.0 - 0.5 * t ** 1.6)
        at, nor = on_face(x, z, BROW["thick"] * 0.35)
        bmesh.ops.create_uvsphere(hb, u_segments=10, v_segments=6, radius=r,
                                  matrix=Matrix.Translation(at) @ flat_on(nor, 0.55))
me_hi = bpy.data.meshes.new("_brows"); hb.to_mesh(me_hi); hb.free()
tmp = bpy.data.objects.new("_brows", me_hi); bpy.context.scene.collection.objects.link(tmp)
rem = tmp.modifiers.new("Remesh", "REMESH"); rem.mode = "VOXEL"; rem.voxel_size = 0.0012; rem.adaptivity = 0.0
sm = tmp.modifiers.new("Relax", "LAPLACIANSMOOTH"); sm.iterations = 4; sm.lambda_factor = 1.0; sm.use_volume_preserve = True
n_hi = len(tmp.evaluated_get(bpy.context.evaluated_depsgraph_get()).data.polygons)
dec = tmp.modifiers.new("Facets", "DECIMATE"); dec.decimate_type = "COLLAPSE"; dec.ratio = min(1.0, 150 / max(n_hi, 1))
dec.use_symmetry = True; dec.symmetry_axis = "X"; dec.use_collapse_triangulate = True
lo_me = bpy.data.meshes.new_from_object(tmp.evaluated_get(bpy.context.evaluated_depsgraph_get()))
bpy.data.objects.remove(tmp); bpy.data.meshes.remove(me_hi)
body.data.materials.append(flat_material("LowpolyMan_Brows", BROW["colour"], BROW["roughness"]))
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

# --- What he is now ------------------------------------------------------------------------------------------------
ws = [body.matrix_world @ v.co for v in body.data.vertices]
size = Vector((max(w.x for w in ws) - min(w.x for w in ws), max(w.y for w in ws) - min(w.y for w in ws),
               max(w.z for w in ws) - min(w.z for w in ws)))
print("LOWPOLY MAN", sum(len(p.vertices) - 2 for p in body.data.polygons), "triangles,", len(rig.data.bones), "bones,",
      "size %.3f x %.3f x %.3f m, lowest %.3f" % (tuple(size) + (min(w.z for w in ws),)))

# --- His animations: tools/blender/animate_lowpoly_man.py keys walk, run, bend and take_away (with the chubby man's
# solver, the same rig), and holds the .glb's export settings -------------------------------------------------------
ANIM = os.path.join(os.path.dirname(os.path.abspath(__file__)), "animate_lowpoly_man.py")
anim_src = open(ANIM, encoding="utf-8").read()
bpy.data.texts.new("lowpoly_man_animate").write(anim_src)
A = {"__name__": "lowpoly_man_animate", "__file__": ANIM}
exec(compile(anim_src, ANIM, "exec"), A)
A["animate"](rig, body)
bpy.ops.wm.save_as_mainfile(filepath=OUT + ".blend", compress=True)
A["export_glb"](rig, OUT + ".glb")
print("SAVED", OUT + ".blend", "| EXPORTED", OUT + ".glb", os.path.getsize(OUT + ".glb"), "bytes")
