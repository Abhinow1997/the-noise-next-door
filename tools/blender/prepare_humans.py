# The humans: the author's download, "Human Basic Shapes- male and female basemesh" by Josephbburg (Blend Swap 72307,
# made for Blender 2.69 in 2014; Creative Commons Attribution 3.0, so Josephbburg must be credited), made ready for the
# game on 21 Oct 2026 at the author's request: "now added humans as well", like the tent and the table.
#
# Like prepare_tent.py, Claude Code wrote this and ran it in a background Blender with the file's scripts switched off.
# It opens the download, or the copy of it kept in the repo, design/downloads/humans/Master_upload_no_pictures.blend,
# and:
#   - takes out the three big pictures packed in the file (bump, shadow and shine maps for a character that isn't in
#     it); opened on the download itself, it first keeps that copy without them, since the download is over GitHub's
#     25 MB limit for this course;
#   - keeps the male and the female, each with the deforming bones of its rig, so they can be posed and animated later
#     as the game's people (the NPCs); it leaves out the androgynous mesh (it has no rig), the rigs' control shapes,
#     their helper objects, and the rigs' constraints;
#   - fixes each body's proportions as the author of the file left them set (its shape keys), mirrors it whole, and
#     makes it lighter and faceted: simplified to about TRIANGLES triangles and flat-shaded, in one flat clay colour
#     (COLOR), as plain figures like the file's own;
#   - stands each on the ground with the middle of its feet at the origin, facing the front (-Y in Blender, +Z in
#     Godot), in its T-pose, scaled so the male is MALE_HEIGHT and the female FEMALE_HEIGHT metres tall;
# then saves assets/characters/humans.blend and exports assets/characters/human_male.glb and human_female.glb.
#
# Run it from the repository's folder (Windows, Git Bash):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --disable-autoexec --factory-startup \
#       --python-exit-code 1 design/downloads/humans/Master_upload_no_pictures.blend --python tools/blender/prepare_humans.py

import bpy, os
from mathutils import Vector

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE_COPY = os.path.join(REPO, "design", "downloads", "humans", "Master_upload_no_pictures.blend")
BLEND_OUT = os.path.join(REPO, "assets", "characters", "humans.blend")
GLB_OUT = os.path.join(REPO, "assets", "characters", "human_%s.glb")

# The camper (camper.glb) is 1.78 m; a woman of average height is a little shorter.
MALE_HEIGHT = 1.78
FEMALE_HEIGHT = 1.68
TRIANGLES = 1800
COLOR = "c4b3a2"
# Each figure: its mesh, its rig, its height, and the name it's exported under.
HUMANS = [("Male_basemesh", "Male_armature", MALE_HEIGHT, "male"),
          ("Female_basemesh", "Female_bones", FEMALE_HEIGHT, "female")]


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


def only(*objects):
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objects:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]


# Everything visible and selectable: in the 2014 file most of it sits on hidden layers.
for coll in bpy.data.collections:
    coll.hide_viewport = False
    coll.hide_select = False
for lc in bpy.context.view_layer.layer_collection.children:
    lc.exclude = False
    lc.hide_viewport = False
for ob in bpy.data.objects:
    ob.hide_set(False)
    ob.hide_viewport = False
    ob.hide_select = False

# --- Take the pictures out --------------------------------------------------------------------------------------
for mat in bpy.data.materials:
    if mat.use_nodes and mat.node_tree:
        for node in [n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE"]:
            mat.node_tree.nodes.remove(node)
    for slot in getattr(mat, "texture_slots", []) or []:
        pass
for tex in list(bpy.data.textures):
    bpy.data.textures.remove(tex)
for image in list(bpy.data.images):
    bpy.data.images.remove(image)
if os.path.abspath(bpy.data.filepath) != os.path.abspath(SOURCE_COPY):
    os.makedirs(os.path.dirname(SOURCE_COPY), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=SOURCE_COPY, copy=True, compress=True)
    print("KEPT the download without its pictures:", SOURCE_COPY)

# --- Keep only the male and the female, with their rigs ---------------------------------------------------------
keep = {name for mesh, rig, _, _ in HUMANS for name in (mesh, rig)}
for ob in list(bpy.data.objects):
    if ob.name not in keep:
        bpy.data.objects.remove(ob)
for mesh_name, rig_name, _, _ in HUMANS:
    rig = bpy.data.objects[rig_name]
    for pb in rig.pose.bones:
        for con in list(pb.constraints):
            pb.constraints.remove(con)
        pb.custom_shape = None
    rig.data.pose_position = "REST"
    # Each figure stands on its own; the female's mesh is parented to her rig, the male's to his.
    mesh = bpy.data.objects[mesh_name]
    mesh.parent = rig
mat = flat_material("Human_Clay", COLOR)

for mesh_name, rig_name, height, label in HUMANS:
    mesh = bpy.data.objects[mesh_name]
    rig = bpy.data.objects[rig_name]
    only(mesh)
    # Its proportions as the file left them, fixed into the mesh.
    if mesh.data.shape_keys:
        bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
    # Mirrored whole; no smoothing; simplified; flat-shaded; one flat colour. The rig's modifier stays, last.
    for m in list(mesh.modifiers):
        if m.type == "SUBSURF":
            mesh.modifiers.remove(m)
    for m in list(mesh.modifiers):
        if m.type == "MIRROR":
            bpy.ops.object.modifier_apply(modifier=m.name)
    dec = mesh.modifiers.new("Decimate", "DECIMATE")
    dec.decimate_type = "COLLAPSE"
    dec.ratio = min(1.0, TRIANGLES / triangles(mesh))
    dec.use_collapse_triangulate = True
    bpy.ops.object.modifier_move_to_index(modifier=dec.name, index=0)
    bpy.ops.object.modifier_apply(modifier=dec.name)
    for p in mesh.data.polygons:
        p.use_smooth = False
    mesh.data.materials.clear()
    mesh.data.materials.append(mat)
    for m in mesh.modifiers:
        if m.type == "ARMATURE":
            m.object = rig

    # On the ground, centred on its feet, at its height: the rig and its mesh moved and scaled together.
    dg = bpy.context.evaluated_depsgraph_get()
    ws = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
    lo = Vector((min(w.x for w in ws), min(w.y for w in ws), min(w.z for w in ws)))
    hi = Vector((max(w.x for w in ws), max(w.y for w in ws), max(w.z for w in ws)))
    feet = [w for w in ws if w.z < lo.z + 0.03 * (hi.z - lo.z)]
    mid = Vector(((min(w.x for w in feet) + max(w.x for w in feet)) / 2, (min(w.y for w in feet) + max(w.y for w in feet)) / 2, lo.z))
    s = height / (hi.z - lo.z)
    only(rig, mesh)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    rig.location = -mid * s
    rig.scale = (s, s, s)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    rig.name = "Human_%s_rig" % label.capitalize()
    mesh.name = "Human_%s" % label.capitalize()
    ws = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
    size = Vector((max(w.x for w in ws) - min(w.x for w in ws), max(w.y for w in ws) - min(w.y for w in ws),
                   max(w.z for w in ws) - min(w.z for w in ws)))
    print("HUMAN", label, triangles(mesh), "triangles,", sum(1 for b in rig.data.bones if b.use_deform), "deforming bones,",
          "size %.3f x %.3f x %.3f m" % tuple(size), "lowest %.3f" % min(w.z for w in ws))

bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT, compress=True)
for mesh_name, rig_name, height, label in HUMANS:
    rig = bpy.data.objects["Human_%s_rig" % label.capitalize()]
    mesh = bpy.data.objects["Human_%s" % label.capitalize()]
    only(rig, mesh)
    path = GLB_OUT % label
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, use_selection=True,
                              export_apply=False, export_cameras=False, export_lights=False, export_materials="EXPORT",
                              export_animations=False, export_skins=True, export_def_bones=True, export_morph=False)
    print("EXPORTED", path, os.path.getsize(path), "bytes")
print("SAVED", BLEND_OUT)
