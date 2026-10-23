# The table: the author's download, "Table with laptop, radio and documents" (Blend Swap 92671, made for Blender 2.79
# in 2018; CC0, but marked fan art, so never for commercial use), made ready for the game on 21 Oct 2026 at the
# author's request: "one more zip free of free assest add them in as well like the tent". Asked how, since it's fan
# art, the author chose "Flat colours, no pictures": the map and photos, probably someone else's pictures, become plain
# paper, and none of the download's pictures go into the repo.
#
# Like prepare_tent.py, Claude Code wrote this and ran it in a background Blender with the file's scripts switched off.
# It opens the download, or the copy of it kept in the repo, design/downloads/table/TABLE_no_pictures.blend, and:
#   - takes out the four pictures packed in the file (the table, laptop and radio textures, and the map-and-photos
#     sheet); opened on the download itself, it first keeps that copy without them;
#   - gives every part flat colours instead (COLORS): a pale table top on grey metal legs, a dark laptop with a slate
#     screen, a dark radio, and plain paper where the map, the documents and the photos were (PAPERS, placed where
#     they lie in the sheet's picture);
#   - makes it lighter and faceted: the table simplified to about TABLE_TRIANGLES triangles, everything flat-shaded;
#   - joins it into one object, turned so the table's long side and the laptop's keyboard face the front (-Y in
#     Blender, +Z in Godot), stands it on the ground with the middle of its feet at the origin, and scales it so the
#     table is TABLE_HEIGHT metres tall;
# then saves assets/props/table_with_laptop.blend and exports assets/props/table_with_laptop.glb.
#
# Run it from the repository's folder (Windows, Git Bash):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --disable-autoexec --factory-startup \
#       --python-exit-code 1 design/downloads/table/TABLE_no_pictures.blend --python tools/blender/prepare_table.py

import bpy, bmesh, os, math
from mathutils import Vector, Matrix

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_COPY = os.path.join(REPO, "design", "downloads", "table", "TABLE_no_pictures.blend")
BLEND_OUT = os.path.join(REPO, "assets", "props", "table_with_laptop.blend")
GLB_OUT = os.path.join(REPO, "assets", "props", "table_with_laptop.glb")

# A desk is about 0.74 m tall; the laptop's open lid stands a little higher.
TABLE_HEIGHT = 0.74
TABLE_TRIANGLES = 700
# The table top: faces whose middle is above this share of the table's height.
TOP_FROM = 0.85
COLORS = {"top": "d6d2c6", "legs": "7b8086", "laptop": "303236", "screen": "3d4859", "radio": "2a2c2f"}
# The laptop's screen: the lid face that faces the keyboard (found by the file's measurements: face 11).
SCREEN_FACE = 11
# The papers on the table, as corners in the 512 x 512 picture of the map-and-photos sheet (x right, y down), from the
# bottom of the pile up, each with its colour: the documents, the two photos (under the map's edge), and the map.
PAPERS = [
    ("Paper_Documents", "ece8dd", [(82, 210), (150, 212), (152, 372), (88, 364)]),
    ("Paper_Sheet", "a9b19c", [(78, 256), (96, 254), (100, 360), (84, 362)]),
    ("Paper_Photo", "c4bca9", [(360, 200), (432, 205), (428, 256), (358, 252)]),
    ("Paper_Photo_Dark", "8f8f8a", [(380, 255), (446, 270), (418, 326), (388, 312)]),
    ("Paper_Map", "e3dcc6", [(107, 183), (335, 116), (382, 312), (160, 378)]),
]
PAPER_STEP = 0.004        # each paper this much above the one under it, in the file's units


def flat_material(name, hex_color):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    srgb = [int(hex_color[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    linear = [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in srgb]
    bsdf.inputs["Base Color"].default_value = (*linear, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.diffuse_color = (*linear, 1.0)
    return mat


def triangles(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def world_box(ob):
    ws = [ob.matrix_world @ v.co for v in ob.data.vertices]
    return (Vector((min(w.x for w in ws), min(w.y for w in ws), min(w.z for w in ws))),
            Vector((max(w.x for w in ws), max(w.y for w in ws), max(w.z for w in ws))))


# --- Take the pictures out -------------------------------------------------------------------------------------------
# Where the sheet's picture lies on the table: its corners' places and picture coordinates (u, v), before it goes.
sheet = bpy.data.objects["MAP AND PHOTOS"]
uv_layer = sheet.data.uv_layers.active.data
corners = [(sheet.matrix_world @ sheet.data.vertices[sheet.data.loops[li].vertex_index].co, Vector(uv_layer[li].uv))
           for li in sheet.data.polygons[0].loop_indices]
for mat in bpy.data.materials:
    if mat.use_nodes and mat.node_tree:
        for node in [n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE"]:
            mat.node_tree.nodes.remove(node)
for image in list(bpy.data.images):
    bpy.data.images.remove(image)
if os.path.abspath(bpy.data.filepath) != os.path.abspath(SOURCE_COPY):
    os.makedirs(os.path.dirname(SOURCE_COPY), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_COPY, copy=True, compress=True)
    print("KEPT the download without its pictures:", SOURCE_COPY)


# --- Plain paper where the map, documents and photos were --------------------------------------------------------
# The sheet's picture coordinates map onto the table near enough as an affine map (its corners are square to it):
# solve x, y = a*u + b*v + c from three corners, and check it against the fourth.
def affine_from(ps):
    (p0, t0), (p1, t1), (p2, t2) = ps[:3]
    m = Matrix(((t0.x, t0.y, 1), (t1.x, t1.y, 1), (t2.x, t2.y, 1)))
    inv = m.inverted()
    cx = inv @ Vector((p0.x, p1.x, p2.x))
    cy = inv @ Vector((p0.y, p1.y, p2.y))
    return lambda t: Vector((cx[0] * t.x + cx[1] * t.y + cx[2], cy[0] * t.x + cy[1] * t.y + cy[2]))


to_table = affine_from(corners)
miss = (to_table(corners[3][1]) - corners[3][0].xy).length
print("SHEET mapping: the fourth corner lands %.3f units off" % miss)
paper_z = corners[0][0].z
bpy.data.objects.remove(sheet)
paper_mesh = bpy.data.meshes.new("Papers")
bm = bmesh.new()
for layer, (name, color, pixels) in enumerate(PAPERS):
    mat = flat_material(name, color)
    paper_mesh.materials.append(mat)
    z = paper_z + PAPER_STEP * (layer + 1)
    verts = [bm.verts.new((*to_table(Vector((x / 512.0, 1.0 - y / 512.0))), z)) for x, y in pixels]
    face = bm.faces.new(verts)
    face.material_index = layer
    face.normal_update()
    if face.normal.z < 0:
        face.normal_flip()
bm.to_mesh(paper_mesh)
bm.free()
papers = bpy.data.objects.new("Papers", paper_mesh)
bpy.context.scene.collection.objects.link(papers)

# --- Flat colours -------------------------------------------------------------------------------------------------
mats = {key: flat_material("Table_" + key.capitalize(), COLORS[key]) for key in COLORS}
table = bpy.data.objects["TABLE"]
laptop = bpy.data.objects["LAPTOP"]
radio = bpy.data.objects["RADIO"]
for ob, keys in ((table, ("top", "legs")), (laptop, ("laptop", "screen")), (radio, ("radio",))):
    ob.data.materials.clear()
    for key in keys:
        ob.data.materials.append(mats[key])
for p in laptop.data.polygons:
    p.material_index = 1 if p.index == SCREEN_FACE else 0
for p in radio.data.polygons:
    p.material_index = 0

# --- The table lighter, then everything flat-shaded ---------------------------------------------------------------
bpy.context.view_layer.objects.active = table
dec = table.modifiers.new("Decimate", "DECIMATE")
dec.decimate_type = "COLLAPSE"
dec.ratio = TABLE_TRIANGLES / triangles(table)
dec.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier=dec.name)
lo, hi = world_box(table)
top_from = lo.z + TOP_FROM * (hi.z - lo.z)
for p in table.data.polygons:
    p.material_index = 0 if (table.matrix_world @ p.center).z > top_from else 1
for ob in (table, laptop, radio, papers):
    for p in ob.data.polygons:
        p.use_smooth = False
    print("PART", ob.name, triangles(ob), "triangles")

# --- One object, turned to the front, on the ground, at game size -------------------------------------------------
feet_mid = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
table_height = hi.z - lo.z
bpy.ops.object.select_all(action="DESELECT")
for ob in (table, laptop, radio, papers):
    ob.select_set(True)
bpy.context.view_layer.objects.active = table
bpy.ops.object.join()
whole = bpy.context.view_layer.objects.active
whole.name = "TableWithLaptop"
whole.data.name = "TableWithLaptop"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# In the file the table's long side runs along Y and the laptop's keyboard faces -X: a quarter turn brings both round
# to face -Y, the front.
turn = Matrix.Rotation(math.radians(90), 4, "Z")
scale = TABLE_HEIGHT / table_height
for v in whole.data.vertices:
    v.co = (turn @ (v.co - feet_mid)) * scale
whole.data.update()
box = world_box(whole)
print("TABLE", triangles(whole), "triangles, size %.3f x %.3f x %.3f m" % tuple(box[1] - box[0]),
      "materials", [s.material.name for s in whole.material_slots])
for mat in list(bpy.data.materials):
    if mat.users == 0:
        bpy.data.materials.remove(mat)

bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT, compress=True)
bpy.ops.export_scene.gltf(filepath=GLB_OUT, export_format="GLB", export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials="EXPORT",
                          export_animations=False, export_skins=False, export_morph=False)
print("SAVED", BLEND_OUT, "| EXPORTED", GLB_OUT, os.path.getsize(GLB_OUT), "bytes")
