# The pizza slice: every execute_blender_code body Claude Code ran in my Blender through the MCP,
# in the order it ran, for Assignment 3 (see ASSET-PLAN.md section 2 and CHANGE-BRIEF.md v1).
# Built on 14 Oct 2026, from about 16:10.
#
# Don't run this file directly: call 3 saves over assets/props/pizza_slice.blend. To test that it
# rebuilds the slice, run a copy that saves somewhere else.
# My hand edit in Blender's window isn't in here (see BLENDER-NOTES.md).

import bpy, math
from mathutils import Matrix, Vector

# --- Call 1, step 0a: session only, so it's not re-run here --------------------------------
# It checked the open file (the s'more) for unsaved changes. There were none, so nothing was saved.

# --- Call 2, step 0b: a new, empty file (no cube, camera or light) -------------------------
bpy.ops.wm.read_homefile(use_empty=True)

# --- Call 3, step 0c: metric units at scale 1.0, then save as the pizza slice's own file ------
u = bpy.context.scene.unit_settings
u.system = 'METRIC'
u.scale_length = 1.0
u.length_unit = 'METERS'
bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\props\pizza_slice.blend")
print("file:", bpy.data.filepath)
print("objects:", len(bpy.data.objects), "| units:", u.system, u.scale_length, u.length_unit)

# --- Shared by the calls below (each call defined them itself) -------------------------------
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

def check():
    bpy.context.view_layer.update()
    for ob in sorted(bpy.data.objects, key=lambda ob: ob.name):
        ws = [ob.matrix_world @ v.co for v in ob.data.vertices]
        print(ob.name, "| dims", tuple(round(d, 4) for d in ob.dimensions), "| loc", tuple(round(c, 4) for c in ob.location),
              "| rot(deg)", tuple(round(math.degrees(r), 1) for r in ob.rotation_euler), "| scale", tuple(round(s, 4) for s in ob.scale),
              "| X", round(min(p.x for p in ws), 4), "to", round(max(p.x for p in ws), 4),
              "| Y", round(min(p.y for p in ws), 4), "to", round(max(p.y for p in ws), 4),
              "| Z", round(min(p.z for p in ws), 4), "to", round(max(p.z for p in ws), 4))

# --- Call 4, part 1: Pizza_Base, a 3-sided cylinder (a triangular prism), one corner turned to -Y,
# stretched into the wedge: 0.15 wide at the back x 0.19 long x 0.008 thick, tip at Y -0.10, back at
# Y +0.09, Z 0 to 0.008. Cheese #F2C14E.
bpy.ops.mesh.primitive_cylinder_add(vertices=3, radius=1.0, depth=1.0, location=(0.0, 0.0, 0.0))
o = bpy.context.active_object
o.name = o.data.name = "Pizza_Base"
v0 = o.data.vertices[0].co
o.data.transform(Matrix.Rotation(math.radians(-90) - math.atan2(v0.y, v0.x), 4, 'Z'))   # one corner to -Y
o.data.update()
# The triangle now runs from y = -1 (the tip) to y = +0.5 (the back), 1.732 wide: stretch it to the wedge.
o.scale = (0.15 / math.sqrt(3), 0.19 / 1.5, 0.008)
o.location = (0.0, 0.09 - 0.5 * 0.19 / 1.5, 0.004)
o.data.materials.append(material("Pizza_Cheese", "F2C14E", 0.5))
check()
tip = min((o.matrix_world @ v.co for v in o.data.vertices), key=lambda p: p.y)
print("tip at", tuple(round(c, 4) for c in tip))
# Result: Pizza_Base | dims (0.15, 0.19, 0.008) | X -0.075 to 0.075 | Y -0.1 to 0.09 | Z 0.0 to 0.008 | tip at (0, -0.1, 0)

# --- Call 5, part 2: Pizza_Crust, an 8-sided cylinder lying along X, 0.15 long x 0.02 across, centre at
# Y +0.09 (back at Y +0.10), Z 0 to 0.02. Soft sides, flat ends. Crust #D9A55B.
bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.01, depth=0.15, location=(0.0, 0.09, 0.01),
                                    rotation=(0.0, math.radians(90), 0.0))
o = bpy.context.active_object
o.name = o.data.name = "Pizza_Crust"
for p in o.data.polygons:
    p.use_smooth = len(p.vertices) == 4          # the round side is smooth, the two 8-sided ends stay flat
o.data.materials.append(material("Pizza_Crust", "D9A55B", 0.75))
bpy.context.view_layer.update()
low = min((o.matrix_world @ v.co).z for v in o.data.vertices)
o.location.z -= low                                   # rest it exactly on Z 0
check()
print("crust moved by", round(-low, 5), "m to rest on the floor")
# Result: Pizza_Crust | X -0.075 to 0.075 | Y 0.08 to 0.1 | Z 0.0 to 0.02 | moved by 0.0

# --- Call 6, part 3: Pizza_Pepperoni1, a flat 10-sided cylinder, 0.03 across x 0.002 thick, on the cheese
# (Z 0.008 to 0.010) at X 0, Y -0.02. Pepperoni #B23A2E.
def on_cheese(o):
    ws = [o.matrix_world @ v.co for v in o.data.vertices]
    print(o.name, "| on the cheese:", all(abs(p.x) <= 0.075 * (p.y + 0.10) / 0.19 + 1e-9 for p in ws),
          "| clear of the crust (front edge Y 0.08):", max(p.y for p in ws) < 0.08)

bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.015, depth=0.002, location=(0.0, -0.02, 0.009))
o = bpy.context.active_object
o.name = o.data.name = "Pizza_Pepperoni1"
o.data.materials.append(material("Pizza_Pepperoni", "B23A2E", 0.45))
check(); on_cheese(o)

# --- Call 7, part 4: Pizza_Pepperoni2, the same at X -0.025, Y +0.04 ------------------------------
bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.015, depth=0.002, location=(-0.025, 0.04, 0.009))
o = bpy.context.active_object
o.name = o.data.name = "Pizza_Pepperoni2"
o.data.materials.append(bpy.data.materials["Pizza_Pepperoni"])
check(); on_cheese(o)

# --- Call 8, part 5: Pizza_Pepperoni3, the same at X +0.025, Y +0.045 -----------------------------
bpy.ops.mesh.primitive_cylinder_add(vertices=10, radius=0.015, depth=0.002, location=(0.025, 0.045, 0.009))
o = bpy.context.active_object
o.name = o.data.name = "Pizza_Pepperoni3"
o.data.materials.append(bpy.data.materials["Pizza_Pepperoni"])
check(); on_cheese(o)
import itertools
peps = [bpy.data.objects[n] for n in ("Pizza_Pepperoni1", "Pizza_Pepperoni2", "Pizza_Pepperoni3")]
print("pepperoni gaps (m):", [round((a.location.xy - b.location.xy).length - 0.03, 4) for a, b in itertools.combinations(peps, 2)])
# Result: all three on the cheese and clear of the crust; gaps 0.035, 0.0396, 0.0202 m

# --- Call 9, last step: apply rotation and scale on every part, check the whole slice, save -------
for ob in bpy.data.objects:
    ob.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Pizza_Base"]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.context.view_layer.update()
pts = [ob.matrix_world @ v.co for ob in bpy.data.objects for v in ob.data.vertices]
lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
tris = {ob.name: sum(len(p.vertices) - 2 for p in ob.data.polygons) for ob in bpy.data.objects}
for ob in sorted(bpy.data.objects, key=lambda ob: ob.name):
    print(ob.name, "| rot", tuple(round(r, 4) for r in ob.rotation_euler), "| scale", tuple(round(s, 4) for s in ob.scale), "| tris", tris[ob.name])
print("WHOLE PIZZA SLICE | size", tuple(round(hi[i] - lo[i], 4) for i in range(3)), "| bottom Z", round(lo.z, 4),
      "| centre XY", (round((lo.x + hi.x) / 2, 4), round((lo.y + hi.y) / 2, 4)), "| shapes", len(bpy.data.objects), "| triangles", sum(tris.values()), "of 200")
for ob in bpy.data.objects:
    ob.select_set(False)
bpy.ops.wm.save_mainfile()
print("saved", bpy.data.filepath)
# Result on 14 Oct: WHOLE PIZZA SLICE | size (0.15, 0.2, 0.02) | bottom Z 0.0 | centre XY (0.0, 0.0) | shapes 5 | triangles 144 of 200


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
