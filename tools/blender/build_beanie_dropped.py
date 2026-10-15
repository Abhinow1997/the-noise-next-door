# The camper's beanie, dropped, v2: every execute_blender_code body Claude Code ran in my Blender through the MCP, in
# order, on 14 Oct 2026 (about 19:30-19:32), after I asked for it in the camper's new style: "yes the beanie as well
# should het he same style". It's the camper v2's own beanie (the same cuff, crown and pompom profiles), crumpled the way
# v1 was -- tipped onto its side, squashed to 0.42, its crown curled and wrinkled with a fixed noise seed, the open end
# facing the front with a dark inside -- and only then fused with a voxel remesh, relaxed and decimated to flat facets
# (no mirror symmetry, since it's crumpled), flat-shaded. 4 parts (cuff, crown, the dark inside, pompom), 368 triangles,
# 0.278 x 0.255 x 0.108 m.
#
# v1 is kept as design/a3/build/beanie/beanie_dropped_v1.blend with its record, build_beanie_dropped_v1.py.
#
# Don't run this file directly: call 1 copies the camper's toolkit (the text block "camper2_lib") from the open file,
# so assets/characters/camper.blend must be open first; it then opens assets/props/beanie_dropped.blend, writes
# design/a3/build/beanie/beanie_dropped_v1.blend, and calls 2-3 save over the beanie.

# --- Call 1 ---------------------------------------------------------------------------------------------------------
# Beanie v2, call 1: open beanie_dropped.blend (camper.blend is saved), keep v1 as design/a3/build/beanie/beanie_dropped_v1.blend,
# clear its objects, and bring over the camper's toolkit (the text block "camper2_lib") so the hat is built the same way.
import bpy, os
assert not bpy.data.is_dirty, bpy.data.filepath
LIB = bpy.data.texts["camper2_lib"].as_string()
bpy.ops.wm.open_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\assets\props\beanie_dropped.blend")
os.makedirs(r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\beanie", exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\a3\build\beanie\beanie_dropped_v1.blend", copy=True)
n = len(bpy.data.objects)
for o in list(bpy.data.objects):
    me = o.data; bpy.data.objects.remove(o)
    if me and me.users == 0: bpy.data.meshes.remove(me)
t = bpy.data.texts.get("camper2_lib") or bpy.data.texts.new("camper2_lib"); t.clear(); t.write(LIB)
print(bpy.data.filepath, "| v1 kept with", n, "parts | objects left", len(bpy.data.objects),
      "| materials", sorted(m.name for m in bpy.data.materials))

# --- Call 2 ---------------------------------------------------------------------------------------------------------
# Beanie v2, call 2: the camper's beanie (the same cuff, crown and pompom profiles, untilted), crumpled as v1 was --
# tipped onto its side, squashed to 0.42, its crown curled and wrinkled (fixed noise seed), the open end facing the front
# with a dark inside -- and only then fused, relaxed and decimated to flat facets, so it matches the camper's style.
# The lowest 6 mm are flattened where it rests on the ground.
import bpy, bmesh, math
from mathutils import Vector, Matrix, noise
exec(bpy.data.texts["camper2_lib"].as_string())
RED, INSIDE = bpy.data.materials["Beanie_Red"], bpy.data.materials["Beanie_Inside"]
CUFF_H, CROWN_TOP, POM_R = 0.070, 0.173, 0.047          # the camper's: cuff 1.607-1.677 m, crown to 1.78 m
SQUASH, SEED = 0.42, Vector((4.2, 1.7, 8.3))
TIP, TURN = Matrix.Rotation(math.radians(90), 3, "X"), Matrix.Rotation(math.radians(180), 3, "Z")

def crumple(p, wrinkle):
    p = TIP @ Vector(p)                                    # crown from +Z to -Y
    p.z = p.z * SQUASH + 0.12 * SQUASH                     # squashed flat, as a soft hat lies
    a = 0.6 * max(0.0, -p.y) / 0.2                         # the crown curls round to one side
    x, y = p.x, p.y
    p.x = x * math.cos(a) - y * math.sin(a); p.y = x * math.sin(a) + y * math.cos(a)
    p += Vector((wrinkle * noise.noise(p * 40 + SEED), wrinkle * noise.noise(p * 40 + SEED * 2),
                 1.6 * wrinkle * noise.noise(p * 35 + SEED * 3)))
    p = TURN @ p                                           # the open end faces the front (-Y)
    p.z = max(p.z, -0.001)                                 # a flat patch where it rests
    return p

def deform(bm, wrinkle):
    for v in bm.verts:
        v.co = crumple(v.co, wrinkle)

def build_cuff(bm):
    loft(bm, [hring(0, 0, f * CUFF_H, r, r, 14) for f, r in [(0, 0.126), (0.04, 0.131), (0.5, 0.134), (0.95, 0.137), (1.0, 0.127)]])
    deform(bm, 0.004)
def build_crown(bm):
    h = CROWN_TOP - CUFF_H
    loft(bm, [hring(0, 0, CUFF_H - 0.012 + f * (h + 0.012), r, r, 14) for f, r in
              [(0, 0.120), (0.25, 0.122), (0.5, 0.117), (0.72, 0.104), (0.88, 0.080), (0.97, 0.045), (1.0, 0.020)]])
    deform(bm, 0.008)
def build_inside(bm):      # the dark inside, seen through the open end: a thin disc just proud of the cuff's opening
    loft(bm, [hring(0, 0, z, 0.112, 0.112, 14) for z in (-0.004, -0.001)])
    deform(bm, 0.004)

def as_beanie(ob, m):
    ob.data.materials.clear(); ob.data.materials.append(m)
    return ob
as_beanie(shell("Beanie_Cuff", build_cuff, "beanie", faces=70, voxel=0.008, relax=1, sym=False), RED)
as_beanie(shell("Beanie_Crown", build_crown, "beanie", faces=60, voxel=0.008, relax=1, sym=False), RED)
as_beanie(plain("Beanie_Inside", build_inside, "beanie"), INSIDE)

# the round pompom rests on the ground against the curled crown's tip
bpy.context.view_layer.update()
crown = bpy.data.objects["Beanie_Crown"]
tip = max((v.co for v in crown.data.vertices), key=lambda c: c.y)
def build_pompom(bm):
    loft(bm, [hring(tip.x, tip.y + POM_R * 0.6, POM_R + POM_R * math.sin(a), POM_R * math.cos(a) + 0.002, POM_R * math.cos(a) + 0.002, 10)
              for a in [math.radians(d) for d in (-80, -50, -20, 10, 40, 70)]])
as_beanie(shell("Beanie_Pompom", build_pompom, "beanie", faces=28, voxel=0.008, relax=1, sym=False), RED)
c2 = bpy.data.materials.get("C2_beanie")
if c2 and c2.users == 0: bpy.data.materials.remove(c2)

# on the floor, centred, flat-shaded
parts = [bpy.data.objects[n] for n in ("Beanie_Cuff", "Beanie_Crown", "Beanie_Inside", "Beanie_Pompom")]
pts = [v.co for o in parts for v in o.data.vertices]
lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
shift = Matrix.Translation((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))
for o in parts:
    o.data.transform(shift); o.data.update()
    for p in o.data.polygons: p.use_smooth = False
pts = [v.co for o in parts for v in o.data.vertices]
lo = Vector([min(p[i] for p in pts) for i in range(3)]); hi = Vector([max(p[i] for p in pts) for i in range(3)])
print("DROPPED BEANIE v2 | size", tuple(round(hi[i] - lo[i], 3) for i in range(3)), "| bottom Z", round(lo.z, 4),
      "| triangles", sum(len(p.vertices) - 2 for o in parts for p in o.data.polygons),
      "| per part", {o.name: sum(len(p.vertices) - 2 for p in o.data.polygons) for o in parts},
      "| materials", sorted(m.name for m in bpy.data.materials))

# --- Call 3 ---------------------------------------------------------------------------------------------------------
# Beanie v2, call 3: check, save and export to assets/props/beanie_dropped.glb.
import bpy, os
parts = [o for o in bpy.data.objects if o.type == "MESH"]
fixed = [o.name for o in parts if o.data.validate(verbose=False)]
bad = [o.name for o in parts if any(abs(o.matrix_world[i][j] - (1.0 if i == j else 0.0)) > 1e-9 for i in range(4) for j in range(4))]
for o in parts:
    for p in o.data.polygons: p.use_smooth = False
print("parts", sorted(o.name for o in parts), "| validate() fixed:", fixed, "| not identity:", bad,
      "| triangles", sum(len(f.vertices) - 2 for o in parts for f in o.data.polygons))
bpy.ops.wm.save_mainfile()
out = os.path.splitext(bpy.data.filepath)[0] + ".glb"
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_yup=True, use_selection=False,
                          export_apply=True, export_cameras=False, export_lights=False, export_materials='EXPORT',
                          export_animations=False, export_skins=False, export_morph=False)
print("saved", bpy.data.filepath, "| exported", out, os.path.getsize(out), "bytes")
