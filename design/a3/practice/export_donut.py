# The donut: the code Claude Code ran in my Blender through the MCP on 14 Oct 2026 to put it in the
# asset room and then make it life size. The donut started as my practice from the Blender tutorial:
# I made the torus by hand, and Claude Code added the icing and sprinkles at my request (see
# BLENDER-NOTES.md). I may use it in the game later. With its smoothing modifiers applied it has
# 35,144 triangles.
#
# Part 1 is the first export (18:00, "also add the donut in this"), at the practice size, 0.33 m across.
# Part 2 is the life-size copy and its export (18:07, after "the donot is a bit big ... i might use it
# later in the game"). The tutorial file on disk wasn't changed by either part.

import bpy, os, math
from mathutils import Vector, Matrix

# ---------------------------------------------------------------------------------------------
# Part 1 (18:00): export only the donut, its icing and its sprinkles from the practice file.
# Superseded by part 2, which replaced assets/practice/donut.glb. Kept as a record.
# ---------------------------------------------------------------------------------------------
# assert bpy.data.filepath.endswith(r"design\a3\practice\donot-and-cup-v1.blend")
# names = ("Torus.001", "Icing", "Sprinkles")
# for o in bpy.data.objects:
#     o.select_set(o.name in names)
# bpy.ops.export_scene.gltf(filepath=r"...\assets\practice\donut.glb", export_format='GLB', export_yup=True,
#                           use_selection=True, export_apply=True, export_cameras=False, export_lights=False,
#                           export_materials='EXPORT', export_animations=False, export_skins=False, export_morph=False)
# Result: 0.3272 x 0.3285 x 0.1089 m, bottom Z 0.0023, 35,144 triangles.

# ---------------------------------------------------------------------------------------------
# Part 2, step 1 (18:05): "Save As" the open practice file to assets/practice/donut.blend, so the
# tutorial file on disk isn't touched, and keep only the donut, its icing and its sprinkles.
# ---------------------------------------------------------------------------------------------
assert bpy.data.filepath.endswith(r"design\a3\practice\donot-and-cup-v1.blend") and not bpy.data.is_dirty
bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\practice\donut.blend")
keep = {"Torus.001", "Icing", "Sprinkles"}
for o in list(bpy.data.objects):
    if o.name not in keep:
        bpy.data.objects.remove(o)

# ---------------------------------------------------------------------------------------------
# Part 2, step 2 (18:06): life size, 10 cm across like a real donut. Rotation and scale applied,
# its base on the floor at the origin, the icing's Solidify thickness scaled to match. Renamed
# Donut_Dough / Donut_Icing / Donut_Sprinkles.
# ---------------------------------------------------------------------------------------------
dough, icing, spr = (bpy.data.objects[n] for n in ("Torus.001", "Icing", "Sprinkles"))
parts = (dough, icing, spr)

def bounds():
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in parts:
        e = o.evaluated_get(dg); me = e.to_mesh()
        pts += [e.matrix_world @ v.co for v in me.vertices]; e.to_mesh_clear()
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])

bpy.context.view_layer.update()
lo, hi = bounds()
s = 0.10 / (hi.x - lo.x)
for c in (icing, spr):                                   # unparent, keeping where they are
    mw = c.matrix_world.copy(); c.parent = None; c.matrix_world = mw
pivot = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
S = Matrix.Scale(s, 4) @ Matrix.Translation(-pivot)       # bottom centre to the origin, then scale about it
for o in parts:
    o.matrix_world = S @ o.matrix_world
icing.modifiers["Solidify"].thickness *= s
for o in bpy.data.objects:
    o.select_set(o in parts)
bpy.context.view_layer.objects.active = dough
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
for c in (icing, spr):                                   # parent them back to the dough
    c.parent = dough
    c.matrix_parent_inverse = dough.matrix_world.inverted()
dough.name = dough.data.name = "Donut_Dough"
icing.name = icing.data.name = "Donut_Icing"
spr.name = spr.data.name = "Donut_Sprinkles"
for o in bpy.data.objects:
    o.select_set(False)
bpy.ops.wm.save_mainfile()
# Result: scale factor 0.3056 | size (0.1, 0.1004, 0.0333) | bottom Z 0.0 | centred | 35,144 triangles
#         | icing Solidify 0.00153 | rotation 0 and scale 1 on all three

# ---------------------------------------------------------------------------------------------
# Part 2, step 3 (18:07): export to assets/practice/donut.glb, replacing the big one.
# ---------------------------------------------------------------------------------------------
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("exported:", out, "|", os.path.getsize(out), "bytes")
