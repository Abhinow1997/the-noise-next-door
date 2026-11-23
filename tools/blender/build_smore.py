# The s'more: every execute_blender_code body Claude Code ran in my Blender through the MCP,
# in the order it ran, for Assignment 3 (see ASSET-PLAN.md section 1 and CHANGE-BRIEF.md v1).
# Built on 14 Oct 2026. Calls that failed are kept, commented out and marked.
#
# To rebuild without the window (Git Bash, from the repo root):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup \
#       --python-exit-code 1 --python tools/blender/build_smore.py
# My hand edit in Blender's window isn't in here (see BLENDER-NOTES.md).

import bpy

# --- Call 1 (14:39), step 0a: session only, so it's not re-run here ------------------------
# It saved the practice file that was open in my Blender, the same as Ctrl+S.
#
# print("saving:", bpy.data.filepath)
# bpy.ops.wm.save_mainfile()
# print("saved:", bpy.data.filepath, "| unsaved changes left:", bpy.data.is_dirty)

# --- Call 2, step 0b: a new, empty file (no cube, camera or light) -------------------------
bpy.ops.wm.read_homefile(use_empty=True)

# --- Call 3, step 0c: FAILED ----------------------------------------------------------------
# "Cannot open file ...\assets\props\smore.blend@ for writing: No such file or directory".
# The assets/props/ folder didn't exist yet. Claude made it, plus smore.blend.import
# (importer="skip"), outside Blender, then re-ran this as call 4.

# --- Call 4, step 0c (retry): metric units at scale 1.0, then save as the s'more's own file ---
u = bpy.context.scene.unit_settings
u.system = 'METRIC'
u.scale_length = 1.0
u.length_unit = 'METERS'
bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\props\smore.blend")
print("file:", bpy.data.filepath)
print("objects:", len(bpy.data.objects), "| units:", u.system, u.scale_length, u.length_unit)

# --- Shared by the steps below: hex colour to linear, and a flat-colour material ----------
def lin(h):
    c = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c)

def material(name, hexc, rough=0.6):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    if m.node_tree is None:
        try: m.use_nodes = True
        except Exception: pass
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    sock = {s.identifier: s for s in bsdf.inputs}
    sock["Base Color"].default_value = (*lin(hexc), 1.0)
    sock["Roughness"].default_value = rough
    m.diffuse_color = (*lin(hexc), 1.0)       # the Solid view colour
    m.roughness = rough
    return m

# --- Call 5, step 1: Smore_CrackerBottom, a cube 0.065 x 0.065 x 0.008 m, Z 0 to 0.008, tan #C8955A
# (Each call defined lin() and material() itself; they're shared above so this file runs as one.)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.004))
o = bpy.context.active_object
o.name = o.data.name = "Smore_CrackerBottom"
o.scale = (0.065, 0.065, 0.008)
o.data.materials.append(material("Smore_Cracker", "C8955A", 0.7))
print(o.name, "dimensions", tuple(round(d, 4) for d in o.dimensions), "faces", len(o.data.polygons))
# It printed dimensions (1.0, 1.0, 1.0): o.dimensions hadn't updated yet. The check below reads them after an update.

# --- Call 6, read-only, run again after every step: exact dimensions, location, bottom and top ----
def check():
    bpy.context.view_layer.update()
    for o in sorted(bpy.data.objects, key=lambda o: o.name):
        zs = [(o.matrix_world @ v.co).z for v in o.data.vertices]
        print(o.name, "| dims", tuple(round(d, 4) for d in o.dimensions), "| loc", tuple(round(c, 4) for c in o.location),
              "| rot", tuple(round(r, 4) for r in o.rotation_euler), "| scale", tuple(round(s, 4) for s in o.scale),
              "| Z", round(min(zs), 4), "to", round(max(zs), 4))
check()

# --- Call 7, step 2: Smore_Chocolate, a thin cube 0.045 x 0.03 x 0.004 m, Z 0.008 to 0.012, dark brown #4A2C1D
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.010))
o = bpy.context.active_object
o.name = o.data.name = "Smore_Chocolate"
o.scale = (0.045, 0.03, 0.004)
o.data.materials.append(material("Smore_Chocolate", "4A2C1D", 0.45))
check()

# --- Call 8, step 3: Smore_Marshmallow, a 12-sided cylinder, diameter 0.045 m x 0.02 m, Z 0.012 to 0.032, off-white #F4EEE0
bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.0225, depth=0.02, location=(0.0, 0.0, 0.022))
o = bpy.context.active_object
o.name = o.data.name = "Smore_Marshmallow"
o.data.materials.append(material("Smore_Marshmallow", "F4EEE0", 0.8))
check()
print("marshmallow faces:", len(o.data.polygons), "sides:", sorted({len(p.vertices) for p in o.data.polygons}))

# --- Call 9, step 4: Smore_CrackerTop, a cube 0.065 x 0.065 x 0.008 m, Z 0.032 to 0.04, the same tan material as step 1
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.036))
o = bpy.context.active_object
o.name = o.data.name = "Smore_CrackerTop"
o.scale = (0.065, 0.065, 0.008)
o.data.materials.append(bpy.data.materials["Smore_Cracker"])
check()

# --- Call 10, last step: apply rotation and scale on every part, check the whole s'more, save ----
from mathutils import Vector
for ob in bpy.data.objects:
    ob.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Smore_CrackerBottom"]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.context.view_layer.update()

pts = [ob.matrix_world @ v.co for ob in bpy.data.objects for v in ob.data.vertices]
lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
tris = {ob.name: sum(len(p.vertices) - 2 for p in ob.data.polygons) for ob in bpy.data.objects}
for ob in sorted(bpy.data.objects, key=lambda ob: ob.name):
    print(ob.name, "| dims", tuple(round(d, 4) for d in ob.dimensions), "| rot", tuple(round(r, 4) for r in ob.rotation_euler),
          "| scale", tuple(round(s, 4) for s in ob.scale), "| tris", tris[ob.name])
print("WHOLE S'MORE | size", tuple(round(hi[i] - lo[i], 4) for i in range(3)), "| bottom Z", round(lo.z, 4),
      "| centre XY", (round((lo.x + hi.x) / 2, 4), round((lo.y + hi.y) / 2, 4)), "| triangles", sum(tris.values()), "of 100")
for ob in bpy.data.objects:
    ob.select_set(False)
bpy.ops.wm.save_mainfile()
print("saved", bpy.data.filepath, "| unsaved:", bpy.data.is_dirty)
# Result on 14 Oct: WHOLE S'MORE | size (0.065, 0.065, 0.04) | bottom Z 0.0 | centre XY (0.0, 0.0) | triangles 80 of 100


# =============================================================================================
# v2 (14 Oct 2026, 15:01-15:05): rebuilt after my first look ("the smores doesn't feel like more
# does it", 14:56) and my decision (14:59). See CHANGE-BRIEF.md "Revised in v2". Running this whole
# file builds v1 above, then replaces it with v2 below.
# =============================================================================================
import math

# --- v2 call A: keep the v1 s'more as a "before" copy, then remove its parts ------------------
# The copy is session only, so it's not re-run here (it would overwrite the kept v1 file):
# bpy.ops.wm.save_as_mainfile(filepath=r"...\design\a3\build\smore\smore_v1.blend", copy=True)
for name in ("Smore_CrackerBottom", "Smore_Chocolate", "Smore_Marshmallow", "Smore_CrackerTop"):
    o = bpy.data.objects.get(name)
    if o:
        me = o.data
        bpy.data.objects.remove(o)
        if me.users == 0: bpy.data.meshes.remove(me)
print("objects left:", [o.name for o in bpy.data.objects], "| materials kept:", [m.name for m in bpy.data.materials])

# --- v2 call B (part 1): Smore_CrackerBottom, a cube 0.065 x 0.065 x 0.006 m, Z 0 to 0.006 ----------
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.003))
o = bpy.context.active_object
o.name = o.data.name = "Smore_CrackerBottom"
o.scale = (0.065, 0.065, 0.006)
o.data.materials.append(bpy.data.materials["Smore_Cracker"])
check()

# --- v2 call C (part 2): Smore_Chocolate, a cube 0.055 x 0.05 x 0.005 m, turned 8 degrees, Z 0.006 to 0.011
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.002, 0.002, 0.0085))
o = bpy.context.active_object
o.name = o.data.name = "Smore_Chocolate"
o.scale = (0.055, 0.05, 0.005)
o.rotation_euler = (0.0, 0.0, math.radians(8))
o.data.materials.append(bpy.data.materials["Smore_Chocolate"])
check()

# --- v2 call D (part 3): Smore_Marshmallow, a UV sphere (12 x 6) squashed to 0.072 x 0.068 x 0.018 m,
# smooth shaded, lightly toasted cream #F3E6CC (v1's material, recoloured)
m = bpy.data.materials["Smore_Marshmallow"]
bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
{s.identifier: s for s in bsdf.inputs}["Base Color"].default_value = (*lin("F3E6CC"), 1.0)
m.diffuse_color = (*lin("F3E6CC"), 1.0)
bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6, radius=1.0, location=(0.001, -0.001, 0.0175))
o = bpy.context.active_object
o.name = o.data.name = "Smore_Marshmallow"
o.scale = (0.036, 0.034, 0.009)
for p in o.data.polygons:
    p.use_smooth = True
o.data.materials.append(m)
check()
print("marshmallow triangles:", sum(len(p.vertices) - 2 for p in o.data.polygons))

# --- v2 call E (part 4): Smore_CrackerTop, a cube 0.065 x 0.065 x 0.006 m, twisted 12, tilted about 2 degrees
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.003, -0.002, 0.0285))
o = bpy.context.active_object
o.name = o.data.name = "Smore_CrackerTop"
o.scale = (0.065, 0.065, 0.006)
o.rotation_euler = (math.radians(2.0), math.radians(-1.5), math.radians(12.0))
o.data.materials.append(bpy.data.materials["Smore_Cracker"])
check()

# --- v2 call F (part 5): Marshmallow_Standing, a 12-sided cylinder, diameter 0.033 x 0.03 m, white #F7F3EA
bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.0165, depth=0.03, location=(0.068, 0.022, 0.015))
o = bpy.context.active_object
o.name = o.data.name = "Marshmallow_Standing"
for p in o.data.polygons:
    p.use_smooth = len(p.vertices) == 4          # the sides are smooth, the two 12-sided ends stay flat
o.data.materials.append(material("Marshmallow_Plain", "F7F3EA", 0.85))
check()

# --- v2 call G (part 6): Marshmallow_Lying, the same cylinder on its side, turned 35 degrees, resting on Z 0
bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.0165, depth=0.03, location=(0.072, -0.022, 0.0165),
                                    rotation=(math.radians(90), 0.0, math.radians(35)))
o = bpy.context.active_object
o.name = o.data.name = "Marshmallow_Lying"
for p in o.data.polygons:
    p.use_smooth = len(p.vertices) == 4
o.data.materials.append(bpy.data.materials["Marshmallow_Plain"])
bpy.context.view_layer.update()
low = min((o.matrix_world @ v.co).z for v in o.data.vertices)
o.location.z -= low
check()
print("lying marshmallow moved by", round(-low + 0.0, 5), "m to touch the floor")

# --- v2 call H (last step): apply rotation and scale, centre the asset on the origin, count, save ----
for ob in bpy.data.objects:
    ob.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Smore_CrackerBottom"]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.context.view_layer.update()

def bounds():
    pts = [ob.matrix_world @ v.co for ob in bpy.data.objects for v in ob.data.vertices]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])

lo, hi = bounds()
shift = Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))
for ob in bpy.data.objects:
    ob.location += shift
bpy.context.view_layer.update()
lo, hi = bounds()
tris = {ob.name: sum(len(p.vertices) - 2 for p in ob.data.polygons) for ob in bpy.data.objects}
for ob in sorted(bpy.data.objects, key=lambda ob: ob.name):
    print(ob.name, "| rot", tuple(round(r, 4) for r in ob.rotation_euler), "| scale", tuple(round(s, 4) for s in ob.scale), "| tris", tris[ob.name])
print("shifted by", tuple(round(c, 4) for c in shift))
print("WHOLE S'MORE v2 | size", tuple(round(hi[i] - lo[i], 4) for i in range(3)), "| bottom Z", round(lo.z, 4),
      "| centre XY", (round((lo.x + hi.x) / 2, 4), round((lo.y + hi.y) / 2, 4)), "| shapes", len(bpy.data.objects), "| triangles", sum(tris.values()), "of 250")
for ob in bpy.data.objects:
    ob.select_set(False)
bpy.ops.wm.save_mainfile()
print("saved", bpy.data.filepath)
# Result on 14 Oct: WHOLE S'MORE v2 | size (0.1297, 0.0823, 0.0335) | bottom Z 0.0 | centre XY (0.0, 0.0) | shapes 6 | triangles 244 of 250


# =============================================================================================
# v3 (14 Oct 2026, about 15:53-15:55): the crackers' groove and dots, after I asked (15:49)
# "add some indentations and textures to the biscuits". Textures aren't allowed (flat colours only),
# so these are geometry plus a second flat colour. See CHANGE-BRIEF.md "Revised in v3".
# =============================================================================================
import bmesh

# --- v3 call A: check nothing changed since v2 and keep a v2 copy -----------------------------
# The copy is session only, so it's not re-run here:
# bpy.ops.wm.save_as_mainfile(filepath=r"...\design\a3\build\smore\smore_v2.blend", copy=True)

# --- v3 call B: Smore_CrackerTop, a 6 x 6 grid on its top face, a 0.8 mm snap groove down the middle,
# and 8 dots (2 columns x 4 rows) inset 3.5 mm and pressed 0.7 mm in, in darker flat tan #9C6A36
o = bpy.data.objects["Smore_CrackerTop"]
me = o.data
bm = bmesh.new(); bm.from_mesh(me)
bm.faces.ensure_lookup_table()
top = max(bm.faces, key=lambda f: f.normal.z)
n = top.normal.copy()
corners = [l.vert.co.copy() for l in top.loops]
c0 = corners[0]
a1 = corners[1] - c0; L1 = a1.length; a1.normalize()
a2 = corners[3] - c0; L2 = a2.length; a2.normalize()
def uv(p):
    d = p - c0
    return d.dot(a1) / L1, d.dot(a2) / L2

bmesh.ops.subdivide_edges(bm, edges=list(top.edges), cuts=5, use_grid_fill=True)
bm.normal_update()
grid = [f for f in bm.faces if f.normal.dot(n) > 0.999 and abs((f.calc_center_median() - c0).dot(n)) < 1e-6]
print("grid faces on top:", len(grid))
dots = []
for f in grid:
    u, v = uv(f.calc_center_median())
    if int(u * 6) in (1, 4) and int(v * 6) in (1, 2, 3, 4):
        dots.append(f)
for v in {v for f in grid for v in f.verts}:                 # the snap groove down the middle
    if abs(uv(v.co)[0] - 0.5) < 1e-4:
        v.co -= n * 0.0008
bmesh.ops.inset_individual(bm, faces=dots, thickness=0.0035, depth=-0.0007, use_even_offset=True)
if len(me.materials) < 2:
    me.materials.append(material("Smore_CrackerDot", "9C6A36", 0.8))
for f in dots:
    f.material_index = 1
bm.to_mesh(me); bm.free(); me.update()
print("dots:", len(dots), "| faces:", len(me.polygons), "| triangles:", sum(len(p.vertices) - 2 for p in me.polygons))

# --- v3 call C: Smore_CrackerBottom, its underside split in two, the middle line pressed 0.8 mm up ---
o = bpy.data.objects["Smore_CrackerBottom"]
me = o.data
bm = bmesh.new(); bm.from_mesh(me)
bm.faces.ensure_lookup_table()
bottom = min(bm.faces, key=lambda f: f.normal.z)
loop_edges = [l.edge for l in bottom.loops]
e0, e2 = loop_edges[0], loop_edges[2]
mids = [(e.verts[0].co + e.verts[1].co) / 2 for e in (e0, e2)]
bmesh.ops.subdivide_edges(bm, edges=[e0, e2], cuts=1, use_grid_fill=True)
moved = 0
for v in bm.verts:
    if any((v.co - m).length < 1e-7 for m in mids):
        v.co.z += 0.0008
        moved += 1
bm.to_mesh(me); bm.free(); me.update()
print(o.name, "| groove verts moved:", moved, "| triangles", sum(len(p.vertices) - 2 for p in me.polygons))

# --- v3 call D: check the whole s'more against brief v3, then save -----------------------------
bpy.context.view_layer.update()
lo, hi = bounds()
tris = {ob.name: sum(len(p.vertices) - 2 for p in ob.data.polygons) for ob in bpy.data.objects}
print("WHOLE S'MORE v3 | size", tuple(round(hi[i] - lo[i], 4) for i in range(3)), "| bottom Z", round(lo.z, 4),
      "| centre XY", (round((lo.x + hi.x) / 2, 4), round((lo.y + hi.y) / 2, 4)), "| shapes", len(bpy.data.objects), "| triangles", sum(tris.values()), "of 420")
bpy.ops.wm.save_mainfile()
print("saved", bpy.data.filepath)
# Result on 14 Oct: WHOLE S'MORE v3 | size (0.1297, 0.0823, 0.0335) | bottom Z 0.0 | centre XY (0.0, 0.0) | shapes 6 | triangles 402 of 420


# =============================================================================================
# Export (14 Oct 2026, about 17:45): binary glTF next to the .blend, as <asset>.glb.
# +Y Up on (the default), modifiers applied, no cameras, lights, animations, skins or shape keys.
# In my session the .blend was opened (or saved) first, then this ran. It writes next to whatever
# file is open, so a rebuild into another folder exports there too.
# =============================================================================================
import os
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("exported:", out, "|", os.path.getsize(out), "bytes")
