# The tent: the author's download, "Tent" by SSimpossible (Blend Swap 5010, CC0, made for Blender 2.56 in 2011),
# made ready for the game on 21 Oct 2026 at the author's request: "Yes, get the tent ready for the game: a non-red
# colour, lighter and faceted, game size, exported as .glb and logged."
#
# Unlike the other scripts here, this one isn't a record of MCP calls: Claude Code wrote it and ran it in a background
# Blender, with the file's own scripts switched off. It opens the download as it came
# (design/downloads/tent/ssimpossible_tent.blend), and:
#   - leaves out what isn't the tent: the ground plane, the camera and the two lights;
#   - recolours it, since red is kept for the beanie (STORYBOARD.md, Continuity): ochre walls and fly, a cream patch
#     on top, a muted blue door and trim, a grey groundsheet, dark poles and pale cord guy ropes (COLORS);
#   - makes it lighter and faceted, like the game's other models: each part's smoothing (subdivision, 2 or 3 levels)
#     is cut to one level, then the part is simplified to about TARGETS[part] triangles and flat-shaded;
#     the guy ropes become thin four-sided cords;
#   - joins it into one object, stands its lowest point on the ground with the middle of its floor at the origin, and
#     scales it to HEIGHT metres tall, with the door facing the front (-Y in Blender, +Z in Godot);
# then saves assets/props/tent.blend and exports assets/props/tent.glb.
#
# Run it from the repository's folder (Windows, Git Bash):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --disable-autoexec --factory-startup \
#       --python-exit-code 1 design/downloads/tent/ssimpossible_tent.blend --python tools/blender/prepare_tent.py

import bpy, os
from mathutils import Vector

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BLEND_OUT = os.path.join(REPO, "assets", "props", "tent.blend")
GLB_OUT = os.path.join(REPO, "assets", "props", "tent.glb")

# A small two-person dome tent: about two and a half times the raccoon's height at the game's size (0.8).
HEIGHT = 1.2
LEAVE_OUT = ("Plane.002", "Camera", "Sun", "Sun.001")
# The file's materials (what each one is on) and their new colours, in sRGB; the ropes get one of their own.
COLORS = {
    "Material.003": ("Tent_Ochre", "c99a3a"),      # the walls, the fly sheet and (in the file) the ropes: red
    "Material.001": ("Tent_Grey", "8a8a86"),       # the groundsheet band and the fly's edges: grey
    "Material.002": ("Tent_Blue", "55658a"),       # the door and its trim: blue
    "Material.004": ("Tent_Cream", "e3dcc8"),      # the patch on top of the fly: white
    "Material.005": ("Tent_Pole", "2e2f33"),       # the four poles: black
    "Material.006": ("Tent_LightGrey", "b9b9b3"),  # inside the body: light grey
}
ROPE = ("Tent_Rope", "cfc6ae")
# About how many triangles each part keeps (the ropes are a few dozen each).
TARGETS = {"Cube": 420, "Plane": 380, "Plane.001": 150, "Plane.003": 90, "Plane.005": 90, "Plane.006": 140,
           "Plane.004": 110, "Cube.001": 40, "Cube.002": 40, "Cube.003": 40, "Cube.004": 40}


def flat_material(name, hex_color):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    color = Vector(int(hex_color[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in color]
    bsdf.inputs["Base Color"].default_value = (*linear, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*linear, 1.0)
    return mat


def triangles(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def apply_all(ob):
    bpy.context.view_layer.objects.active = ob
    for m in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)


# --- Leave out what isn't the tent --------------------------------------------------------------------------------
for name in LEAVE_OUT:
    ob = bpy.data.objects.get(name)
    if ob:
        bpy.data.objects.remove(ob)

# --- Recolour -----------------------------------------------------------------------------------------------------
new = {old: flat_material(*COLORS[old]) for old in COLORS}
rope_mat = flat_material(*ROPE)
for ob in bpy.data.objects:
    for slot in ob.material_slots:
        if slot.material and slot.material.name in new:
            slot.material = new[slot.material.name]
        elif slot.material is None:
            # The door panels have an empty first slot; anything on it would come out white.
            slot.material = new["Material.003"]

# --- The guy ropes: thin four-sided cords, then meshes ----------------------------------------------------------
for ob in [o for o in bpy.data.objects if o.type == "CURVE"]:
    ob.data.bevel_resolution = 0
    ob.data.resolution_u = 2
    for slot in ob.material_slots:
        slot.material = rope_mat
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.convert(target="MESH")

# --- Each part: one level of smoothing, simplified, flat-shaded ----------------------------------------------------
for ob in [o for o in bpy.data.objects if o.type == "MESH"]:
    for m in ob.modifiers:
        if m.type == "SUBSURF":
            m.levels = 1
            m.render_levels = 1
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    apply_all(ob)
    target = TARGETS.get(ob.name)
    if target and triangles(ob) > target:
        dec = ob.modifiers.new("Decimate", "DECIMATE")
        dec.decimate_type = "COLLAPSE"
        dec.ratio = target / triangles(ob)
        dec.use_collapse_triangulate = True
        apply_all(ob)
    for p in ob.data.polygons:
        p.use_smooth = False
    print("PART", ob.name, triangles(ob), "triangles")

# --- One object, on the ground, at game size ------------------------------------------------------------------------
# The floor's middle is the body's (the ropes reach out to one side), taken before the parts are joined.
body = [bpy.data.objects["Cube"].matrix_world @ v.co for v in bpy.data.objects["Cube"].data.vertices]
floor_mid = Vector(((min(v.x for v in body) + max(v.x for v in body)) / 2, (min(v.y for v in body) + max(v.y for v in body)) / 2))
bpy.ops.object.select_all(action="SELECT")
bpy.context.view_layer.objects.active = bpy.data.objects["Cube"]
bpy.ops.object.join()
tent = bpy.context.view_layer.objects.active
tent.name = "Tent"
tent.data.name = "Tent"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
verts = [v.co.copy() for v in tent.data.vertices]
lo = Vector((min(v.x for v in verts), min(v.y for v in verts), min(v.z for v in verts)))
hi = Vector((max(v.x for v in verts), max(v.y for v in verts), max(v.z for v in verts)))
mid = Vector((floor_mid.x, floor_mid.y, lo.z))
scale = HEIGHT / (hi.z - lo.z)
for v in tent.data.vertices:
    v.co = (v.co - mid) * scale
tent.data.update()
size = (hi - lo) * scale
for mat in list(bpy.data.materials):
    if mat.users == 0:
        bpy.data.materials.remove(mat)
print("TENT", triangles(tent), "triangles,", len(tent.data.vertices), "vertices, size %.3f x %.3f x %.3f m" % tuple(size),
      "materials", [s.material.name for s in tent.material_slots])

bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT, compress=True)
bpy.ops.export_scene.gltf(filepath=GLB_OUT, export_format="GLB", export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials="EXPORT",
                          export_animations=False, export_skins=False, export_morph=False)
print("SAVED", BLEND_OUT, "| EXPORTED", GLB_OUT, os.path.getsize(GLB_OUT), "bytes")
