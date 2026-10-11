# 3D landmarks of a symmetric head object (facing -Y), and the 2D ones measured in the
# references. "near" is his right side (-X), which faces the camera in these images.
import bpy
from mathutils import Vector

REF2D = {
    "idle.jpg": {"eye_near": (1620, 1012), "eye_far": (1771, 981), "nose": (1805, 1120),
                 "ear_near": (1450, 725), "ear_far": (1785, 675), "cheek_near": (1315, 1038)},
    "standing.jpg": {"eye_near": (1437, 488), "eye_far": (1560, 463), "nose": (1605, 552),
                     "ear_near": (1250, 280), "ear_far": (1535, 235), "cheek_near": (1190, 570)},
}


def landmarks(ob_name, mw=None):
    ob = bpy.data.objects[ob_name]
    M = mw if mw is not None else ob.matrix_world
    vs = [M @ v.co for v in ob.data.vertices]
    me = ob.data
    eye_idx = {i for p in me.polygons if me.materials[p.material_index].name == "R_Eye" for i in p.vertices}
    ear_idx = {i for p in me.polygons if me.materials[p.material_index].name == "R_EarInner" for i in p.vertices}
    def mean(ids):
        ids = list(ids)
        return sum((vs[i] for i in ids), Vector()) / len(ids)
    eyeR = mean(i for i in eye_idx if vs[i].x < 0)
    eyeL = mean(i for i in eye_idx if vs[i].x > 0)
    ear_side = lambda s: max((vs[i] for i in range(len(vs)) if s * vs[i].x > 0.05 and vs[i].z > 0.5 and vs[i].y > -0.45), key=lambda v: v.z)
    head_ids = [i for i in range(len(vs)) if i not in eye_idx]
    nose = min((vs[i] for i in head_ids), key=lambda v: v.y)
    cheek = min((vs[i] for i in head_ids if vs[i].z > 0.3 and vs[i].y < -0.3), key=lambda v: v.x)
    return {"eye_near": eyeR, "eye_far": eyeL, "nose": nose, "ear_near": ear_side(-1),
            "ear_far": ear_side(1), "cheek_near": cheek}
