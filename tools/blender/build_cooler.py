# The cooler: every execute_blender_code body Claude Code ran in my Blender through the MCP,
# in the order it ran, for Assignment 3 (see ASSET-PLAN.md section 3, CHANGE-BRIEF.md v1 and v4).
# Built on 14 Oct 2026, from about 17:29.
#
# Don't run this file directly: call 3 saves over assets/props/cooler.blend. To test that it
# rebuilds the cooler, run a copy that saves somewhere else.

import bpy, math
from mathutils import Vector

# --- Call 1, step 0a: session only, so it's not re-run here --------------------------------
# It checked the open file (the pizza slice) for unsaved changes. There were none, so nothing was saved.

# --- Call 2, step 0b: a new, empty file (no cube, camera or light) -------------------------
bpy.ops.wm.read_homefile(use_empty=True)

# --- Call 3, step 0c: metric units at scale 1.0, then save as the cooler's own file ----------
u = bpy.context.scene.unit_settings
u.system = 'METRIC'
u.scale_length = 1.0
u.length_unit = 'METERS'
bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\props\cooler.blend")
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

# --- Call 4, part 1: Cooler_Body, a cube 0.54 x 0.34 x 0.28 m, Z 0 to 0.28, blue #3B7DBF (my choice) ---
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.14))
o = bpy.context.active_object
o.name = o.data.name = "Cooler_Body"
o.scale = (0.54, 0.34, 0.28)
o.data.materials.append(material("Cooler_Blue", "3B7DBF", 0.5))
check()
# Result: Cooler_Body | dims (0.54, 0.34, 0.28) | X -0.27 to 0.27 | Y -0.17 to 0.17 | Z 0.0 to 0.28

# --- Call 5, part 2: Cooler_Lid, a cube 0.58 x 0.36 x 0.05 m, Z 0.28 to 0.33, overhanging by 0.02 m, white #F2F2EE
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.305))
o = bpy.context.active_object
o.name = o.data.name = "Cooler_Lid"
o.scale = (0.58, 0.36, 0.05)
o.data.materials.append(material("Cooler_White", "F2F2EE", 0.45))
check()
# Result: Cooler_Lid | X -0.29 to 0.29 | Y -0.18 to 0.18 | Z 0.28 to 0.33

# --- Call 6, part 3: Cooler_PostL, a cube 0.025 x 0.025 x 0.02 m, Z 0.33 to 0.35, at X -0.14, grey #8A8F94
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(-0.14, 0.0, 0.34))
o = bpy.context.active_object
o.name = o.data.name = "Cooler_PostL"
o.scale = (0.025, 0.025, 0.02)
o.data.materials.append(material("Cooler_Grey", "8A8F94", 0.4))
check()

# --- Call 7, part 4: Cooler_PostR, the same cube at X +0.14 ------------------------------------
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.14, 0.0, 0.34))
o = bpy.context.active_object
o.name = o.data.name = "Cooler_PostR"
o.scale = (0.025, 0.025, 0.02)
o.data.materials.append(bpy.data.materials["Cooler_Grey"])
check()

# --- Call 8, part 5: Cooler_Handle, an 8-sided cylinder along X, 0.30 m long x 0.02 m across, Z 0.34 to 0.36
bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.01, depth=0.30, location=(0.0, 0.0, 0.35),
                                    rotation=(0.0, math.radians(90), 0.0))
o = bpy.context.active_object
o.name = o.data.name = "Cooler_Handle"
for p in o.data.polygons:
    p.use_smooth = len(p.vertices) == 4          # the round side is smooth, the two 8-sided ends stay flat
o.data.materials.append(bpy.data.materials["Cooler_Grey"])
check()
# Result: Cooler_Handle | X -0.15 to 0.15 | Y -0.01 to 0.01 | Z 0.34 to 0.36 (its ends sit inside the posts)

# --- Call 9, last step: apply rotation and scale on every part, check the whole cooler, save -----
for ob in bpy.data.objects:
    ob.select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects["Cooler_Body"]
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
bpy.context.view_layer.update()
pts = [ob.matrix_world @ v.co for ob in bpy.data.objects for v in ob.data.vertices]
lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
tris = {ob.name: sum(len(p.vertices) - 2 for p in ob.data.polygons) for ob in bpy.data.objects}
for ob in sorted(bpy.data.objects, key=lambda ob: ob.name):
    print(ob.name, "| rot", tuple(round(r, 4) for r in ob.rotation_euler), "| scale", tuple(round(s, 4) for s in ob.scale), "| tris", tris[ob.name])
print("WHOLE COOLER | size", tuple(round(hi[i] - lo[i], 4) for i in range(3)), "| bottom Z", round(lo.z, 4),
      "| centre XY", (round((lo.x + hi.x) / 2, 4), round((lo.y + hi.y) / 2, 4)), "| shapes", len(bpy.data.objects), "| triangles", sum(tris.values()), "of 150")
for ob in bpy.data.objects:
    ob.select_set(False)
bpy.ops.wm.save_mainfile()
print("saved", bpy.data.filepath)
# Result on 14 Oct: WHOLE COOLER | size (0.58, 0.36, 0.36) | bottom Z 0.0 | centre XY (0.0, 0.0) | shapes 5 | triangles 76 of 150


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
