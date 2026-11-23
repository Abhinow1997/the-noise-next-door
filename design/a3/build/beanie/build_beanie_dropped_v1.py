# The camper's beanie, dropped and crumpled on the ground: every execute_blender_code body Claude Code ran in my Blender
# through the MCP on 14 Oct 2026 (about 18:36-18:38), after I asked for "the crumppled down on the ground benie model".
# It starts as the same beanie as the camper's (folded brim, revolved body, pompom), then it's tipped onto its side,
# squashed like a soft knit hat, its crown curled to one side and lightly wrinkled (a fixed noise seed). Its open end has
# a darker inside, and its round pompom rests on the floor. 3 parts, 136 triangles, about 0.28 x 0.27 x 0.10 m.
#
# This is v1. v2, rebuilt in the camper v2's faceted style at my request, is tools/blender/build_beanie_dropped.py;
# v1's file is kept beside this one as beanie_dropped_v1.blend.
#
# Don't run this file directly: call 2 saves over assets/props/beanie_dropped.blend. Calls 3 and 4 were replaced by
# call 5 and are kept, commented out, as the record of what changed.

import bpy, bmesh, math
from mathutils import Vector, Matrix, noise

# --- Call 1: a new, empty file (the camper had just been saved and exported) -------------------------------------
bpy.ops.wm.read_homefile(use_empty=True)

# --- Call 2: units, save as assets/props/beanie_dropped.blend, the red material, and the beanie standing upright ----
u = bpy.context.scene.unit_settings
u.system = 'METRIC'; u.scale_length = 1.0; u.length_unit = 'METERS'
bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\props\beanie_dropped.blend")

def lin(h):
    c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)

def flat(name, hexc, rough):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    if m.node_tree is None:
        try: m.use_nodes = True
        except Exception: pass
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    s = {x.identifier: x for x in bsdf.inputs}
    s["Base Color"].default_value = (*lin(hexc), 1.0); s["Roughness"].default_value = rough
    m.diffuse_color = (*lin(hexc), 1.0)
    return m

def upright_beanie(red, inside=None):
    """The camper's beanie, standing as on his head: brim 0..0.065, body up to 0.222 (call 2 built it without
    the darker inside; calls 4 and 5 rebuilt it with one)."""
    bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.12, depth=0.065, location=(0, 0, 0.0325))
    brim = bpy.context.active_object; brim.name = brim.data.name = "Beanie_Brim"; brim.data.materials.append(red)
    if inside:
        brim.data.materials.append(inside)
    profile = [(0.112, 0.055), (0.110, 0.135), (0.095, 0.19), (0.060, 0.215)]
    N = 10
    bm = bmesh.new()
    rings = [[bm.verts.new((r * math.cos(2 * math.pi * j / N), r * math.sin(2 * math.pi * j / N), z)) for j in range(N)] for r, z in profile]
    top = bm.verts.new((0, 0, 0.222)); bot = bm.verts.new((0, 0, 0.055))
    for a, c in zip(rings, rings[1:]):
        for j in range(N):
            bm.faces.new((a[j], a[(j + 1) % N], c[(j + 1) % N], c[j]))
    for j in range(N):
        bm.faces.new((rings[-1][j], rings[-1][(j + 1) % N], top))
        bm.faces.new((rings[0][(j + 1) % N], rings[0][j], bot))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new("Beanie_Body"); bm.to_mesh(me); bm.free()
    body = bpy.data.objects.new("Beanie_Body", me); bpy.context.scene.collection.objects.link(body); me.materials.append(red)
    return brim, body

red = flat("Beanie_Red", "AC453B", 0.9)
upright_beanie(red)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=0.036, location=(0, 0, 0.25))
pom = bpy.context.active_object; pom.name = pom.data.name = "Beanie_Pompom"; pom.data.materials.append(red)
bpy.ops.wm.save_mainfile()

# --- Call 3 (replaced): the first crumple. Tipped, squashed to a third, curled, wrinkled; but the pompom was squashed
# flat with the rest and set apart, and the whole thing read as a red blob. --------------------------------------------
# for o in (brim, body, pom): mesh into world space; rotate 90 deg about X; z = z * 0.33 + 0.12 * 0.33; curl
#   a = 0.6 * max(0, -y) / 0.29 about Z; wrinkles 0.004 / 0.004 / 0.007 (not on the pompom); underside clamped to Z 0;
#   pompom dropped to the floor; centred. Result: 0.281 x 0.242 x 0.08 m, 136 triangles.

# --- Call 4 (replaced): rebuilt with a darker inside on the open end and a round pompom, but the brim was squashed
# less (0.55) than the body (0.38), so from behind the cuff stood up like a separate disc. Otherwise as call 5. -------

# --- Call 5: the final crumple. The brim and body squashed by the same 0.42; the open end darker and facing the front;
# the crown curled, wrinkles (fixed seed); the round pompom resting on the floor against the crown -------------------
for n in ("Beanie_Brim", "Beanie_Body", "Beanie_Pompom"):
    o = bpy.data.objects.get(n)
    if o:
        me = o.data; bpy.data.objects.remove(o); bpy.data.meshes.remove(me)
inside = flat("Beanie_Inside", "5E2622", 0.95)
brim, body = upright_beanie(red, inside)
bpy.context.view_layer.update()
for p in brim.data.polygons:
    if len(p.vertices) > 4 and p.normal.z < -0.9:
        p.material_index = 1                              # the open end, darker as if you see inside
tip = Matrix.Rotation(math.radians(90), 4, 'X')           # crown from +Z to -Y
turn = Matrix.Rotation(math.radians(180), 4, 'Z')         # then the open end faces the front (-Y)
seed = Vector((4.2, 1.7, 8.3))
SQUASH = 0.42
for o, wrinkle in ((brim, 0.002), (body, 0.005)):
    me = o.data
    me.transform(tip)
    for v in me.vertices:
        p = v.co
        p.z = p.z * SQUASH + 0.12 * SQUASH
        a = 0.6 * max(0.0, -p.y) / 0.29
        x, y = p.x, p.y
        p.x = x * math.cos(a) - y * math.sin(a); p.y = x * math.sin(a) + y * math.cos(a)
        p += Vector((wrinkle * noise.noise(p * 40 + seed), wrinkle * noise.noise(p * 40 + seed * 2),
                     1.6 * wrinkle * noise.noise(p * 35 + seed * 3)))
    me.transform(turn)
    me.update()
low = min(v.co.z for o in (brim, body) for v in o.data.vertices)
for o in (brim, body):
    for v in o.data.vertices:
        v.co.z = max(0.0, v.co.z - low)
    o.data.update()
crown = max((v.co for v in body.data.vertices), key=lambda c: c.y)
r = 0.036
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=r, location=(crown.x, crown.y + r * 0.6, r))
pom = bpy.context.active_object; pom.name = pom.data.name = "Beanie_Pompom"; pom.data.materials.append(red)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
parts = (brim, body, pom)
pts = [v.co.copy() for o in parts for v in o.data.vertices]
cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2; cy = (min(p.y for p in pts) + max(p.y for p in pts)) / 2
for o in parts:
    o.data.transform(Matrix.Translation((-cx, -cy, 0)))
    o.matrix_world = Matrix.Identity(4)
    for p in o.data.polygons: p.use_smooth = False
bpy.ops.wm.save_mainfile()
# Result: 0.277 x 0.304 x 0.102 m, bottom Z 0, 136 triangles

# --- Call 6: close the gap between the cuff and the body (curling the crown slanted the body's open end, and the
# brim stopped short of it): slide the brim 3 cm along +Y, then centre again --------------------------------------
brim.data.transform(Matrix.Translation((0, 0.03, 0)))
pts = [v.co.copy() for o in parts for v in o.data.vertices]
cx = (min(p.x for p in pts) + max(p.x for p in pts)) / 2; cy = (min(p.y for p in pts) + max(p.y for p in pts)) / 2
for o in parts:
    o.data.transform(Matrix.Translation((-cx, -cy, 0))); o.data.update()
pts = [v.co for o in parts for v in o.data.vertices]
lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
print("DROPPED BEANIE | size", tuple(round(hi[i] - lo[i], 3) for i in range(3)), "| bottom Z", round(lo.z, 4),
      "| triangles", sum(len(p.vertices) - 2 for o in parts for p in o.data.polygons))
bpy.ops.wm.save_mainfile()
# Result: 0.277 x 0.274 x 0.102 m, bottom Z 0, 136 triangles

# --- Call 7: export to assets/props/beanie_dropped.glb ---------------------------------------------------------
import os
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("exported:", out, "|", os.path.getsize(out), "bytes")
