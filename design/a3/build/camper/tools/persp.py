# A perspective camera solve (rotation, position, focal length; principal point at the image centre) by
# Gauss-Newton, for references rendered with a perspective camera. Starts from the scaled-orthographic solve.
import numpy as np


def rod(w):
    th = np.linalg.norm(w)
    if th < 1e-12:
        return np.eye(3)
    k = w / th
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    return np.eye(3) + np.sin(th) * K + (1 - np.cos(th)) * K @ K


def unrod(R):
    th = np.arccos(np.clip((np.trace(R) - 1) / 2, -1, 1))
    if th < 1e-9:
        return np.zeros(3)
    return th / (2 * np.sin(th)) * np.array([R[2, 1] - R[1, 2], R[0, 2] - R[2, 0], R[1, 0] - R[0, 1]])


def proj(p, X, cx, cy):
    R = rod(p[:3]); c = p[3:6]; f = np.exp(p[6])
    Xc = (X - c) @ R.T
    z = -Xc[:, 2]
    return np.stack([cx + f * Xc[:, 0] / z, cy - f * Xc[:, 1] / z], 1)


def solve_persp(X, U, W, H, d_eye, centre, dist=4.0, f0=None, iters=200, fix_f=None):
    """d_eye: unit vector from the subject towards the camera (from the orthographic solve)."""
    X, U = np.asarray(X, float), np.asarray(U, float)
    cx, cy = W / 2, H / 2
    d = np.asarray(d_eye, float); d /= np.linalg.norm(d)
    za = d                                   # camera +Z points back towards the eye
    xa = np.cross([0, 0, 1], za); xa /= np.linalg.norm(xa)
    ya = np.cross(za, xa)
    R = np.stack([xa, ya, za])
    c = np.asarray(centre, float) + d * dist
    p = np.r_[unrod(R), c, np.log(f0 if f0 else 750 * dist)]
    lam = 1e-3
    def resid(q):
        if fix_f is not None:
            q = q.copy(); q[6] = np.log(fix_f)
        return (proj(q, X, cx, cy) - U).ravel()
    r = resid(p)
    for _ in range(iters):
        J = np.zeros((r.size, 7))
        for i in range(7):
            dp = np.zeros(7); dp[i] = 1e-6
            J[:, i] = (resid(p + dp) - r) / 1e-6
        if fix_f is not None:
            J[:, 6] = 0
        A = J.T @ J; g = J.T @ r
        step = np.linalg.solve(A + lam * np.diag(np.diag(A) + 1e-9), -g)
        r2 = resid(p + step)
        if (r2 ** 2).sum() < (r ** 2).sum():
            p, r, lam = p + step, r2, lam * 0.3
        else:
            lam *= 10
        if np.linalg.norm(step) < 1e-10:
            break
    if fix_f is not None:
        p[6] = np.log(fix_f)
    return p, (proj(p, X, cx, cy) - U)


def make_cam(bpy, Matrix, name, p, W):
    R = rod(p[:3]); c = p[3:6]; f = np.exp(p[6])
    cam = bpy.data.objects.get(name)
    if cam is None:
        cam = bpy.data.objects.new(name, bpy.data.cameras.new(name))
        bpy.context.scene.collection.objects.link(cam)
    cd = cam.data
    cd.type = "PERSP"; cd.sensor_fit = "AUTO"; cd.sensor_width = 36.0
    cd.lens = f * 36.0 / W
    cd.shift_x = cd.shift_y = 0.0
    cd.clip_start = 0.05; cd.clip_end = 100
    M = Matrix([[*R[0], 0], [*R[1], 0], [*R[2], 0], [0, 0, 0, 1]]).transposed()
    M[0][3], M[1][3], M[2][3] = c
    cam.matrix_world = M
    return cam
