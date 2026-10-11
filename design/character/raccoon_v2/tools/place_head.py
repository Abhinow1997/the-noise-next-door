# Places a copy of FaceWork on the new body ("FacePlaced": scale k about the back of the
# skull, moved to `at`) and makes "BodyCam_<img>" = the face camera carried along, so the
# whole raccoon can be compared with the reference at the head's measured scale.
import bpy
from mathutils import Matrix, Vector

PIVOT = Vector((0.0, -0.257, 0.493))   # back-centre of FaceWork's skull


def head_matrix(k, at):
    return Matrix.Translation(Vector(at)) @ Matrix.Scale(k, 4) @ Matrix.Translation(-PIVOT)


def place(k, at, cams=("idle", "standing")):
    T = head_matrix(k, at)
    fp = bpy.data.objects.get("FacePlaced")
    if fp is None:
        fp = bpy.data.objects.new("FacePlaced", bpy.data.objects["FaceWork"].data)
        bpy.data.collections["Raccoon v2"].objects.link(fp)
    fp.data = bpy.data.objects["FaceWork"].data
    fp.matrix_world = T
    for c in cams:
        src = bpy.data.objects["FaceCam_" + c]
        name = "BodyCam_" + c
        cam = bpy.data.objects.get(name)
        if cam is None:
            cam = bpy.data.objects.new(name, src.data.copy())
            bpy.context.scene.collection.objects.link(cam)
        cam.data.ortho_scale = src.data.ortho_scale * k
        loc, rot, _ = src.matrix_world.decompose()
        cam.matrix_world = Matrix.Translation(T @ loc) @ rot.to_matrix().to_4x4()
    return fp
