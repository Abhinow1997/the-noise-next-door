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
