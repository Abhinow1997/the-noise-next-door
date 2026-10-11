# Measures the near (his right, -X) ear from idle.jpg in FaceWork's frame:
# - the base ends A (front) and B (back, low) lie on the skull: ray-cast onto the head;
# - the tip C from the near/far tip pair in both references (symmetry gives depth);
# - the rest of the rim outline: rays intersected with the plane through A, B, C.
import bpy, bmesh, numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

IDLE_RIM = [(1405, 892), (1396, 840), (1398, 790), (1407, 745), (1442, 720), (1482, 737), (1524, 785)]
TIPS = {"FaceCam_idle": ((1442, 720), (1785, 675)), "FaceCam_standing": ((1250, 277), (1525, 229))}
SIZE = {"FaceCam_idle": (2048, 2048), "FaceCam_standing": (2400, 1792)}


def ray(cam_name, uv):
    cam = bpy.data.objects[cam_name]
    W, H = SIZE[cam_name]
    s = cam.data.ortho_scale / max(W, H)
    x = (uv[0] - W / 2) * s
    y = (H / 2 - uv[1]) * s
    M = cam.matrix_world
    o = M @ Vector((x, y, 0))
    d = -(M.to_3x3() @ Vector((0, 0, 1))).normalized()
    return o, d


def head_tree():
    fw = bpy.data.objects["FaceWork"]
    bm = bmesh.new()
    bm.from_mesh(fw.data)
    # the skull is the island with the nose material
    nose = fw.data.materials.find("R_Nose")
    start = next(f for f in bm.faces if f.material_index == nose)
    seen, st = {start}, [start]
    while st:
        g = st.pop()
        for e in g.edges:
            for h in e.link_faces:
                if h not in seen:
                    seen.add(h)
                    st.append(h)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f not in seen], context="FACES")
    t = BVHTree.FromBMesh(bm)
    bm.free()
    return t


def project_rows(cam_name):
    """u = a.X + cu, v = b.X + cv for the orthographic camera."""
    cam = bpy.data.objects[cam_name]
    W, H = SIZE[cam_name]
    s = max(W, H) / cam.data.ortho_scale
    M = cam.matrix_world
    xa = M.to_3x3() @ Vector((1, 0, 0))
    ya = M.to_3x3() @ Vector((0, 1, 0))
    o = M.translation
    return s * xa, W / 2 - s * xa.dot(o), -s * ya, H / 2 + s * ya.dot(o)


def solve_tip():
    rows, rhs = [], []
    for cam, (near, far) in TIPS.items():
        a, cu, b, cv = project_rows(cam)
        for (u, v), sx in ((near, 1), (far, -1)):
            # point is (sx * X, Y, Z) with X < 0 for the near ear
            rows.append([a.x * sx, a.y, a.z]); rhs.append(u - cu)
            rows.append([b.x * sx, b.y, b.z]); rhs.append(v - cv)
    X = np.linalg.lstsq(np.array(rows), np.array(rhs), rcond=None)[0]
    return Vector(X)


def measure():
    tree = head_tree()
    hits = {}
    for i in (0, len(IDLE_RIM) - 1):
        o, d = ray("FaceCam_idle", IDLE_RIM[i])
        loc, nrm, _, dist = tree.ray_cast(o, d)
        hits[i] = loc
    A, B = hits[len(IDLE_RIM) - 1], hits[0]
    C = solve_tip()
    n = (A - B).cross(C - B).normalized()
    pts = []
    for uv in IDLE_RIM:
        o, d = ray("FaceCam_idle", uv)
        t = (B - o).dot(n) / d.dot(n)
        pts.append(o + d * t)
    pts[0], pts[-1] = B, A
    return pts, C, n
