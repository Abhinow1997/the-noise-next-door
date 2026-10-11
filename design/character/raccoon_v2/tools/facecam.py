# Fits an orthographic camera to 2D landmarks in a reference image and sets it up with the
# image as its background, for overlay comparisons. Call fit_cam(name, image_path, L3, L2).
import bpy, numpy as np
from mathutils import Matrix, Vector


def fit_cam(name, image_path, L3, L2, opacity=0.5):
    img = bpy.data.images.load(image_path, check_existing=True)
    W, Hh = img.size
    keys = list(L2)
    X = np.array([[*L3[k], 1] for k in keys])
    U = np.array([L2[k] for k in keys], float)
    P = np.linalg.lstsq(X, U, rcond=None)[0]
    r1, r2 = P[:3, 0], P[:3, 1]
    s = (np.linalg.norm(r1) + np.linalg.norm(r2)) / 2
    a = r1 / np.linalg.norm(r1)
    b = r2 - (r2 @ a) * a
    b /= np.linalg.norm(b)
    # Rigid (scaled-orthographic) refit of the translation.
    proj = np.stack([s * X[:, :3] @ a, s * X[:, :3] @ b], 1)
    t = (U - proj).mean(0)
    err = np.linalg.norm(proj + t - U, axis=1)
    xa, ya = Vector(a), Vector(-b)            # image v runs down; camera y runs up
    za = xa.cross(ya)
    c0 = sum((Vector(L3[k]) for k in keys), Vector()) / len(keys)
    u0, v0 = s * (Vector(a) @ c0) + t[0], s * (Vector(b) @ c0) + t[1]
    q = c0 + Vector(a) * ((W / 2 - u0) / s) + Vector(b) * ((Hh / 2 - v0) / s)
    cam = bpy.data.objects.get(name)
    if cam is None:
        cam = bpy.data.objects.new(name, bpy.data.cameras.new(name))
        bpy.context.scene.collection.objects.link(cam)
    cd = cam.data
    cd.type = "ORTHO"
    cd.ortho_scale = max(W, Hh) / s
    cd.sensor_fit = "AUTO"
    rot = Matrix((xa, ya, za)).transposed().to_4x4()
    cam.matrix_world = Matrix.Translation(q + za * 3.0) @ rot
    cd.clip_end = 10
    cd.show_background_images = True
    cd.background_images.clear()
    bg = cd.background_images.new()
    bg.image = img
    bg.alpha = opacity
    bg.display_depth = "FRONT"
    bg.frame_method = "FIT"
    return cam, dict(zip(keys, err.round(1))), (W, Hh)


def solved_cam(name, image_path, L3, L2):
    """Like fit_cam, but with the Gauss-Newton scaled-orthographic solve (solve.py)."""
    img = bpy.data.images.load(image_path, check_existing=True)
    W, Hh = img.size
    keys = list(L2)
    X = np.array([L3[k] for k in keys], float)
    U = np.array([L2[k] for k in keys], float)
    p, res = solve_cam(X, U)
    R = rodrigues(p[:3])
    s, t = np.exp(p[3]), p[4:6]
    a, b = R[0], R[1]
    xa, ya = Vector(a), Vector(-b)
    za = xa.cross(ya)
    c0 = Vector(X.mean(0))
    u0, v0 = s * (Vector(a) @ c0) + t[0], s * (Vector(b) @ c0) + t[1]
    q = c0 + Vector(a) * ((W / 2 - u0) / s) + Vector(b) * ((Hh / 2 - v0) / s)
    cam = bpy.data.objects.get(name)
    if cam is None:
        cam = bpy.data.objects.new(name, bpy.data.cameras.new(name))
        bpy.context.scene.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = max(W, Hh) / s
    cam.data.clip_end = 10
    cam.matrix_world = Matrix.Translation(q + za * 3.0) @ Matrix((xa, ya, za)).transposed().to_4x4()
    return cam, dict(zip(keys, np.linalg.norm(res, axis=1).round(1)))
