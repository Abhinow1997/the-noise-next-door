# The camper: every execute_blender_code body Claude Code ran in my Blender through the MCP, in order, on 14 Oct 2026
# (about 18:20-18:36), after I asked: "we also have the reference of the man from the previous assignment make his model
# for me no animations but jus the man with benie model". He's matched to design/reference/red-beanie-man.jpg
# (REF-CAMPER): colours clustered from his own pixels, proportions from his silhouette rows, and the height from
# CHARACTER-SHEET.md (1.75 m to the top of his head, the raccoon's back about at his thigh). Where the reference and the
# sheet differ, the reference wins: brown jacket (the sheet says mustard), faceless with a nose and no beard (the sheet
# says dot eyes and a short beard). Basic shapes, flat colours, no rig or animation. 42 parts, 1,140 triangles,
# 0.665 x 0.349 x 1.871 m (1.871 m to the top of the pompom), facing -Y like the other assets.
#
# This is v1, which I rejected as blocky ("like a minecraft tree"); v2, rebuilt in raccoon_v2's style, is
# tools/blender/build_camper.py, and v1's file is kept beside this one as camper_v1.blend.
#
# Don't run this file directly: call 2 saves over assets/characters/camper.blend. To test that it rebuilds him, run a
# copy that saves somewhere else. Calls that were replaced later are kept, in order, so the record shows the changes.

import bpy, bmesh, math
from mathutils import Vector, Matrix

# --- Call 1: a new, empty file (the open file, donut.blend, had nothing unsaved) ---------------------------------
bpy.ops.wm.read_homefile(use_empty=True)

# --- Call 2: metric units, save as assets/characters/camper.blend, and the helpers below (stored in the file as the
# text block "camper_helpers", which every later call ran first) --------------------------------------------------
u = bpy.context.scene.unit_settings
u.system = 'METRIC'; u.scale_length = 1.0; u.length_unit = 'METERS'
bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\characters\camper.blend")

def lin(h):
    c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)

def mat(name, hexc, rough=0.85):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    if m.node_tree is None:
        try: m.use_nodes = True
        except Exception: pass
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    sock = {s.identifier: s for s in bsdf.inputs}
    sock["Base Color"].default_value = (*lin(hexc), 1.0)
    sock["Roughness"].default_value = rough
    m.diffuse_color = (*lin(hexc), 1.0)
    m.roughness = rough
    return m

# colours measured from design/reference/red-beanie-man.jpg (clustered from his own pixels)
SKIN = lambda: mat("Camper_Skin", "C99C85", 0.6)
HAIR = lambda: mat("Camper_Hair", "3A2E26", 0.9)
BEANIE = lambda: mat("Camper_Beanie", "AC453B", 0.9)
JACKET = lambda: mat("Camper_Jacket", "554739", 0.85)
JACKET_DARK = lambda: mat("Camper_JacketDark", "463A2F", 0.85)
POCKET = lambda: mat("Camper_Pocket", "605142", 0.85)
HOODIE = lambda: mat("Camper_Hoodie", "66686C", 0.9)
TSHIRT = lambda: mat("Camper_Tshirt", "D8D8D8", 0.9)
STRING = lambda: mat("Camper_String", "A9A9AD", 0.8)
JEANS = lambda: mat("Camper_Jeans", "33363B", 0.85)
CUFF = lambda: mat("Camper_JeansCuff", "3D4146", 0.85)
BOOT = lambda: mat("Camper_Boot", "AF8758", 0.7)
SOLE = lambda: mat("Camper_Sole", "6E5236", 0.8)

def _finish(o, name, m, smooth=False):
    o.name = o.data.name = name
    o.data.materials.append(m)
    for p in o.data.polygons:
        p.use_smooth = smooth
    return o

def box(name, size, loc, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    o = bpy.context.active_object; o.scale = size
    return _finish(o, name, m)

def cyl(name, r, depth, loc, m, verts=8, rot=(0, 0, 0), r_top=None):
    if r_top is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r_top, depth=depth, location=loc, rotation=rot)
    return _finish(bpy.context.active_object, name, m)

def ball(name, dims, loc, m, seg=10, rings=6, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=1.0, location=loc, rotation=rot)
    o = bpy.context.active_object; o.scale = (dims[0] / 2, dims[1] / 2, dims[2] / 2)
    return _finish(o, name, m)

def ico(name, r, loc, m, subdiv=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=r, location=loc)
    return _finish(bpy.context.active_object, name, m)

def torus(name, R, r, loc, m, major=12, minor=6, rot=(0, 0, 0), scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_torus_add(major_segments=major, minor_segments=minor, major_radius=R, minor_radius=r, location=loc, rotation=rot)
    o = bpy.context.active_object; o.scale = scale
    return _finish(o, name, m)

def report(names):
    bpy.context.view_layer.update()
    for n in names:
        o = bpy.data.objects[n]
        ws = [o.matrix_world @ v.co for v in o.data.vertices]
        print(n, "| X %.3f..%.3f | Y %.3f..%.3f | Z %.3f..%.3f | tris %d" % (
            min(p.x for p in ws), max(p.x for p in ws), min(p.y for p in ws), max(p.y for p in ws),
            min(p.z for p in ws), max(p.z for p in ws), sum(len(f.vertices) - 2 for f in o.data.polygons)))

def remove(*names):
    for n in names:
        o = bpy.data.objects[n]; me = o.data
        bpy.data.objects.remove(o); bpy.data.meshes.remove(me)

# --- Call 3: the boots: a darker sole, a tan body with the toe forward, a shaft at the heel; feet turned out 5 degrees
for side, sx in (("L", 1), ("R", -1)):
    a = math.radians(5) * sx
    box("Camper_Sole" + side, (0.12, 0.27, 0.025), (0.10 * sx, -0.03, 0.0125), SOLE(), rot=(0, 0, a))
    box("Camper_Boot" + side, (0.11, 0.24, 0.085), (0.10 * sx, -0.035, 0.0675), BOOT(), rot=(0, 0, a))
    box("Camper_BootShaft" + side, (0.105, 0.13, 0.07), (0.10 * sx + 0.002 * sx, 0.025, 0.135), BOOT(), rot=(0, 0, a))

# --- Call 4: tapered 8-sided jeans legs (0.15 to 0.82 m), rolled cuffs, the hips --------------------------------
for side, sx in (("L", 1), ("R", -1)):
    cyl("Camper_Leg" + side, 0.07, 0.67, (0.095 * sx, 0.0, 0.485), JEANS(), verts=8, r_top=0.085)
    cyl("Camper_LegCuff" + side, 0.082, 0.07, (0.095 * sx, 0.0, 0.18), CUFF(), verts=8)
box("Camper_Hips", (0.36, 0.22, 0.16), (0.0, 0.0, 0.84), JEANS())

# --- Call 5: the torso: an 8-sided jacket body (replaced in call 6), front panels open over a grey hoodie strip,
# the T-shirt at the neck, drawstrings, collar lapels and four pockets ---------------------------------------------
o = cyl("Camper_Jacket", 1.0, 1.0, (0.0, 0.0, 1.08), JACKET(), verts=8, rot=(0, 0, math.radians(22.5)))
o.scale = (0.225, 0.135, 0.64)
box("Camper_Hoodie", (0.17, 0.03, 0.58), (0.0, -0.118, 1.09), HOODIE())
box("Camper_Tshirt", (0.075, 0.02, 0.06), (0.0, -0.13, 1.355), TSHIRT())
for side, sx in (("L", 1), ("R", -1)):
    box("Camper_JacketFront" + side, (0.10, 0.03, 0.62), (0.12 * sx, -0.12, 1.08), JACKET())
    box("Camper_Collar" + side, (0.085, 0.025, 0.07), (0.075 * sx, -0.12, 1.395), JACKET_DARK(),
        rot=(math.radians(-15), math.radians(-25) * sx, 0))
    box("Camper_ChestFlap" + side, (0.085, 0.012, 0.035), (0.125 * sx, -0.14, 1.20), JACKET_DARK())
    box("Camper_Pocket" + side, (0.105, 0.010, 0.11), (0.125 * sx, -0.139, 0.90), POCKET())
    box("Camper_Drawstring" + side, (0.007, 0.007, 0.12), (0.03 * sx, -0.136, 1.27), STRING())

# --- Call 6: the jacket body as a box instead: the octagon's flat front was only 0.17 m wide, and the lower pockets
# hung over its angled sides ---------------------------------------------------------------------------------------
remove("Camper_Jacket")
box("Camper_Jacket", (0.42, 0.26, 0.64), (0.0, 0.0, 1.08), JACKET())

# --- Call 7: shoulders and arms (the sleeves, cuffs and hands were made longer in call 10) -----------------------
for side, sx in (("L", 1), ("R", -1)):
    tilt = -0.07 * sx
    ball("Camper_Shoulder" + side, (0.15, 0.20, 0.13), (0.215 * sx, 0.0, 1.345), JACKET(), seg=8, rings=5)
    cyl("Camper_Sleeve" + side, 0.058, 0.44, (0.245 * sx, 0.0, 1.15), JACKET(), verts=8, r_top=0.072, rot=(0, tilt, 0))
    cyl("Camper_SleeveCuff" + side, 0.066, 0.05, (0.259 * sx, 0.0, 0.935), JACKET_DARK(), verts=8, rot=(0, tilt, 0))
    box("Camper_Hand" + side, (0.055, 0.09, 0.12), (0.264 * sx, -0.005, 0.85), SKIN(), rot=(0, tilt, 0))

# --- Call 8: neck, the hood round it, the faceless head with a nose, and the hair (hair and hood redone in 11-12) --
cyl("Camper_Neck", 0.055, 0.10, (0.0, 0.0, 1.44), SKIN(), verts=8)
torus("Camper_Hood", 0.11, 0.045, (0.0, 0.02, 1.43), HOODIE(), major=12, minor=6, scale=(1.0, 1.0, 0.8))
box("Camper_HoodBack", (0.20, 0.07, 0.13), (0.0, 0.105, 1.475), HOODIE(), rot=(math.radians(-12), 0, 0))
ball("Camper_Head", (0.19, 0.22, 0.28), (0.0, 0.0, 1.60), SKIN(), seg=12, rings=8)
box("Camper_Nose", (0.03, 0.04, 0.055), (0.0, -0.115, 1.555), SKIN(), rot=(math.radians(-12), 0, 0))
box("Camper_HairBack", (0.18, 0.07, 0.10), (0.0, 0.078, 1.565), HAIR())
for side, sx in (("L", 1), ("R", -1)):
    box("Camper_Sideburn" + side, (0.025, 0.06, 0.07), (0.093 * sx, 0.0, 1.555), HAIR())

# --- Call 9: the beanie: a folded 10-sided brim, a body revolved from a profile, a faceted pompom -----------------
cyl("Camper_BeanieBrim", 0.12, 0.065, (0.0, 0.0, 1.6175), BEANIE(), verts=10)
profile = [(0.112, 1.64), (0.110, 1.72), (0.095, 1.775), (0.060, 1.80)]
N = 10
bm = bmesh.new()
rings = [[bm.verts.new((r * math.cos(2 * math.pi * j / N), r * math.sin(2 * math.pi * j / N), z)) for j in range(N)] for r, z in profile]
top = bm.verts.new((0, 0, 1.807)); bottom = bm.verts.new((0, 0, 1.64))
for a, b in zip(rings, rings[1:]):
    for j in range(N):
        bm.faces.new((a[j], a[(j + 1) % N], b[(j + 1) % N], b[j]))
for j in range(N):
    bm.faces.new((rings[-1][j], rings[-1][(j + 1) % N], top))
    bm.faces.new((rings[0][(j + 1) % N], rings[0][j], bottom))
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
me = bpy.data.meshes.new("Camper_Beanie"); bm.to_mesh(me); bm.free()
o = bpy.data.objects.new("Camper_Beanie", me); bpy.context.scene.collection.objects.link(o)
me.materials.append(BEANIE())
ico("Camper_Pompom", 0.036, (0.0, 0.0, 1.835), BEANIE(), subdiv=1)

# --- Call 10: after comparing with the reference: longer arms (his hands hang below the jacket hem, to about
# 0.65 m), and the hood ring lower, under the chin -------------------------------------------------------------------
for side in ("L", "R"):
    remove("Camper_Sleeve" + side, "Camper_SleeveCuff" + side, "Camper_Hand" + side)
for side, sx in (("L", 1), ("R", -1)):
    tilt = -0.07 * sx
    cyl("Camper_Sleeve" + side, 0.058, 0.57, (0.245 * sx, 0.0, 1.085), JACKET(), verts=8, r_top=0.072, rot=(0, tilt, 0))
    cyl("Camper_SleeveCuff" + side, 0.066, 0.05, (0.265 * sx, 0.0, 0.805), JACKET_DARK(), verts=8, rot=(0, tilt, 0))
    box("Camper_Hand" + side, (0.055, 0.09, 0.13), (0.27 * sx, -0.005, 0.715), SKIN(), rot=(0, tilt, 0))
bpy.data.objects["Camper_Hood"].location = (0.0, 0.03, 1.405)

# --- Call 11: after the side view: the hair as a bit of dark at the temples under the brim, and the hood's back lower
remove("Camper_SideburnL", "Camper_SideburnR", "Camper_HairBack", "Camper_HoodBack")
box("Camper_HairBack", (0.19, 0.08, 0.075), (0.0, 0.07, 1.55), HAIR())
for side, sx in (("L", 1), ("R", -1)):
    box("Camper_Sideburn" + side, (0.02, 0.07, 0.045), (0.094 * sx, 0.012, 1.565), HAIR())
box("Camper_HoodBack", (0.20, 0.06, 0.085), (0.0, 0.11, 1.445), HOODIE())

# --- Call 12: no separate box for the hood's back; the hood ring tilts 16 degrees, rising at the back of the neck --
remove("Camper_HoodBack")
hood = bpy.data.objects["Camper_Hood"]
hood.rotation_euler = (0.28, 0.0, 0.0)
hood.location = (0.0, 0.03, 1.415)

# --- Call 13: apply rotation and scale on every part, check the whole figure, save --------------------------------
for o in bpy.data.objects:
    o.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Camper_Jacket"]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.context.view_layer.update()
pts = [o.matrix_world @ v.co for o in bpy.data.objects for v in o.data.vertices]
lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
tris = sum(len(p.vertices) - 2 for o in bpy.data.objects for p in o.data.polygons)
print("CAMPER | parts", len(bpy.data.objects), "| size", tuple(round(hi[i] - lo[i], 3) for i in range(3)), "| bottom Z", round(lo.z, 4),
      "| centre X", round((lo.x + hi.x) / 2, 4), "| top of the pompom", round(hi.z, 3), "| triangles", tris)
for o in bpy.data.objects:
    o.select_set(False)
bpy.ops.wm.save_mainfile()
# Result on 14 Oct: parts 42 | size (0.665, 0.349, 1.871) | bottom Z 0.0 | centre X 0.0 | triangles 1140

# --- Call 14: export to assets/characters/camper.glb -----------------------------------------------------------
import os
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("exported:", out, "|", os.path.getsize(out), "bytes")
