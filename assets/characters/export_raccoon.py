"""Exports the raccoon in raccoon.blend to raccoon.glb, ready for the game.

Run it from the repo root after changing the .blend:

    blender -b assets/characters/raccoon.blend --python assets/characters/export_raccoon.py

Nothing is saved back to the .blend. The game version differs from the reference
pose in a few ways, so it animates well:
- The head turns 20 degrees toward the camera in the reference; here it looks
  straight ahead, and the neck is centred to match.
- The tail sweeps toward the camera in the reference; here it runs straight back.
- The trowel is left out, since he carries game items in his mouth. A "Mouth"
  point marks where its handle was.
- Each leg is one mesh, and every moving part has its origin at its joint (hips,
  neck, tail base, eye centres), so scripts/raccoon_model.gd can swing them.
- TailCurled is the same tail wrapped round his left side, for sleeping.

He faces -Z in Godot, like the raccoon built in code, with his feet at y = 0.
"""

import math
import os

import bmesh
import bpy
from mathutils import Matrix, Vector

OUT = os.path.join(os.path.dirname(bpy.data.filepath), "raccoon.glb")
UP = Vector((0, 0, 1))

# The source objects by their names in the .blend. They're renamed (in memory only)
# so the exported parts can take their names.
SRC = {ob.name: ob for ob in bpy.data.objects}
for datablock in list(bpy.data.objects) + list(bpy.data.meshes):
    datablock.name = "src_" + datablock.name

# The head's symmetry plane passes through the origin, so turning the head about
# the vertical axis there both straightens it and centres it.
STRAIGHTEN = Matrix.Rotation(-SRC["Head"].rotation_euler.z, 4, "Z")
# He faces -Y in the .blend. Turned round to face +Y, he faces -Z once glTF
# converts to Y-up.
TURN = Matrix.Rotation(math.pi, 4, "Z")
# While asleep the game lowers his body this far, so the curled tail is built
# this far above the floor.
SLEEP_DROP = 0.17


def world_mesh(name, pre=Matrix()):
    """A copy of an object's mesh in world space, transformed by `pre`."""
    ob = SRC[name]
    me = ob.data.copy()
    me.transform(pre @ ob.matrix_world)
    return me


def joined_mesh(name, parts):
    """One mesh made of several objects' meshes, keeping their materials."""
    mats = []
    bm = bmesh.new()
    for part in parts:
        me = world_mesh(part)
        for poly in me.polygons:
            mat = me.materials[poly.material_index]
            if mat not in mats:
                mats.append(mat)
            poly.material_index = mats.index(mat)
        bm.from_mesh(me)
        bpy.data.meshes.remove(me)
    out = bpy.data.meshes.new(name)
    bm.to_mesh(out)
    bm.free()
    for mat in mats:
        out.materials.append(mat)
    return out


def centroid(points):
    points = list(points)
    return sum(points, Vector()) / len(points)


def rings(me, sides=6):
    """The tail and legs are built ring by ring, `sides` vertices per ring."""
    return [list(range(k, k + sides)) for k in range(0, len(me.vertices), sides)]


def top_ring_centre(me):
    """The centre of the highest ring of a leg: its hip or shoulder."""
    centres = [centroid(me.vertices[i].co for i in ring) for ring in rings(me)]
    return max(centres, key=lambda c: c.z)


def tangents(centres, min_step=0.03):
    """Direction of a tube at each ring, skipping rings that nearly coincide."""
    out = []
    for k in range(len(centres)):
        i, j = max(k - 1, 0), min(k + 1, len(centres) - 1)
        while (centres[j] - centres[i]).length < min_step and j < len(centres) - 1:
            j += 1
        out.append((centres[j] - centres[i]).normalized())
    return out


def frame(t):
    """Side, up and along axes for a ring facing `t`, with up kept as level as possible."""
    u = (UP - UP.dot(t) * t).normalized()
    return t.cross(u), u, t


def arc_lengths(points):
    out = [0.0]
    for a, b in zip(points, points[1:]):
        out.append(out[-1] + (b - a).length)
    return out


def retarget(me, new_centres):
    """Moves each ring of a tube to a new centre line, keeping its cross-section
    (and so the faceting and the bands) unchanged."""
    ring_list = rings(me)
    old_centres = [centroid(me.vertices[i].co for i in ring) for ring in ring_list]
    for ring, c0, t0, c1, t1 in zip(ring_list, old_centres, tangents(old_centres),
                                    new_centres, tangents(new_centres)):
        s0, u0, _ = frame(t0)
        s1, u1, _ = frame(t1)
        for i in ring:
            o = me.vertices[i].co - c0
            me.vertices[i].co = c1 + s1 * o.dot(s0) + u1 * o.dot(u0) + t1 * o.dot(t0)


def straight_tail(centres):
    """The same tail with its sideways sweep taken out: each ring keeps its height
    and its distance from the base along the ground."""
    base = centres[0]
    out = [base.copy()]
    along = 0.0
    for a, b in zip(centres, centres[1:]):
        along += (b - a).to_2d().length
        out.append(Vector((base.x, base.y + along, b.z)))
    return out


def curled_tail(me, centres, radius=0.18, flank_end=0.05):
    """The tail wrapped round his left side (+X here) on the floor: a half circle
    behind his rump, then straight forward along his flank, stretched to fit."""
    base = centres[0]
    half = math.pi * radius
    total = half + (base.y - flank_end)
    lengths = arc_lengths(centres)
    out = []
    for ring, centre, t, s in zip(rings(me), centres, tangents(centres), lengths):
        s = s / lengths[-1] * total
        if s <= half:
            a = s / radius
            x = base.x + radius - radius * math.cos(a)
            y = base.y + radius * math.sin(a)
        else:
            x = base.x + 2 * radius
            y = base.y - (s - half)
        # Rest the ring's underside on the floor of the sleeping pose.
        _, u, _ = frame(t)
        half_height = max((me.vertices[i].co - centre).dot(u) for i in ring)
        floor = SLEEP_DROP + half_height + 0.005
        blend = s / total / 0.3
        blend = 1.0 if blend >= 1.0 else blend * blend * (3 - 2 * blend)
        out.append(Vector((x, y, centre.z + (floor - centre.z) * blend)))
    return out


def centre_rings(me):
    """The front body rings lean toward the turned head; centre every ring on x = 0."""
    by_y = {}
    for v in me.vertices:
        by_y.setdefault(round(v.co.y, 4), []).append(v)
    for verts in by_y.values():
        xs = [v.co.x for v in verts]
        mid = (min(xs) + max(xs)) / 2
        for v in verts:
            v.co.x -= mid


# --- Build the game version, in the .blend's frame first ------------------------

col = bpy.data.collections.new("GameExport")
bpy.context.scene.collection.children.link(col)
placed = []
# Each new object's world position, turned round.
where = {}


def add(name, data, at, parent=None):
    """Adds an object at world point `at` (the .blend's frame). Mesh data is moved
    so the object's origin sits there, then everything is turned round."""
    at_final = TURN @ at
    if data is not None:
        data.name = name
        data.transform(TURN)
        data.transform(Matrix.Translation(-at_final))
    ob = bpy.data.objects.new(name, data)
    col.objects.link(ob)
    ob.parent = parent
    ob.location = at_final - (where[parent.name] if parent else Vector())
    where[name] = at_final
    placed.append(ob)
    return ob


root = add("Raccoon", None, Vector())

body_mesh = world_mesh("Body")
centre_rings(body_mesh)
body = add("Body", body_mesh, Vector(), root)

head_mesh = world_mesh("Head_Mesh", STRAIGHTEN)
back = max(v.co.y for v in head_mesh.vertices)
neck = Vector((0.0, back - 0.035, (STRAIGHTEN @ SRC["Head"].matrix_world.translation).z))
head = add("Head", None, neck, body)
add("HeadMesh", head_mesh, neck, head)
for side in ("L", "R"):
    add("Ear" + side, world_mesh("Ear_" + side, STRAIGHTEN), neck, head)
    eye = world_mesh("Eye_" + side, STRAIGHTEN)
    add("Eye" + side, eye, centroid(v.co for v in eye.vertices), head)
handle = world_mesh("Trowel_Handle", STRAIGHTEN)
mouth = centroid(v.co for v in handle.vertices)
bpy.data.meshes.remove(handle)
add("Mouth", None, Vector((0.0, mouth.y, mouth.z)), head)

tail_mesh = world_mesh("Tail")
tail_centres = [centroid(tail_mesh.vertices[i].co for i in ring) for ring in rings(tail_mesh)]
base = tail_centres[0]
straight = straight_tail(tail_centres)
retarget(tail_mesh, straight)
curled_mesh = tail_mesh.copy()
retarget(curled_mesh, curled_tail(curled_mesh, straight))
add("Tail", tail_mesh, base, body)
add("TailCurled", curled_mesh, base, body)

LEGS = {
    "LegFL": ["Leg_LF_Upper", "Leg_LF", "Paw_LF"],
    "LegFR": ["Leg_RF", "Paw_RF"],
    "LegBL": ["Leg_LR", "Paw_LR"],
    "LegBR": ["Leg_RR", "Paw_RR"],
}
for name, parts in LEGS.items():
    hip = top_ring_centre(SRC[parts[0]].data)
    hip = SRC[parts[0]].matrix_world @ hip
    add(name, joined_mesh(name, parts), hip, root)

# --- Export ----------------------------------------------------------------------

for ob in bpy.context.view_layer.objects:
    ob.select_set(ob in placed)

options = dict(
    filepath=OUT,
    export_format="GLB",
    use_selection=True,
    export_apply=True,
    export_yup=True,
    export_texcoords=False,
    export_normals=True,
    export_tangents=False,
    export_materials="EXPORT",
    export_cameras=False,
    export_lights=False,
    export_animations=False,
    export_skins=False,
    export_morph=False,
    export_extras=False,
)
known = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
bpy.ops.export_scene.gltf(**{k: v for k, v in options.items() if k in known})

print("Exported", OUT)
for ob in placed:
    # In Godot's axes (x, z, -y).
    p = where[ob.name]
    print("  %-10s at (%.3f, %.3f, %.3f)" % (ob.name, p.x, p.z, -p.y))
