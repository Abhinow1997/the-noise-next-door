# Scaled-orthographic camera solve (rotation, scale, 2D offset) by Gauss-Newton.
import numpy as np


def rodrigues(w):
    th = np.linalg.norm(w)
    if th < 1e-12:
        return np.eye(3)
    k = w / th
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    return np.eye(3) + np.sin(th) * K + (1 - np.cos(th)) * K @ K


def from_matrix(R):
    th = np.arccos(np.clip((np.trace(R) - 1) / 2, -1, 1))
    if th < 1e-9:
        return np.zeros(3)
    return th / (2 * np.sin(th)) * np.array([R[2, 1] - R[1, 2], R[0, 2] - R[2, 0], R[1, 0] - R[0, 1]])


def project(p, X):
    R = rodrigues(p[:3])
    return np.exp(p[3]) * (X @ R[:2].T) + p[4:6]


def solve_cam(X, U, iters=60):
    X, U = np.asarray(X, float), np.asarray(U, float)
    A = np.c_[X, np.ones(len(X))]
    P = np.linalg.lstsq(A, U, rcond=None)[0]
    r1, r2 = P[:3, 0], P[:3, 1]
    s = (np.linalg.norm(r1) + np.linalg.norm(r2)) / 2
    a = r1 / np.linalg.norm(r1)
    b = r2 - (r2 @ a) * a
    b /= np.linalg.norm(b)
    R = np.stack([a, b, np.cross(a, b)])
    p = np.r_[from_matrix(R), np.log(s), (U - s * X @ R[:2].T).mean(0)]
    for _ in range(iters):
        r = (project(p, X) - U).ravel()
        J = np.zeros((r.size, 6))
        for i in range(6):
            dp = np.zeros(6)
            dp[i] = 1e-6
            J[:, i] = ((project(p + dp, X) - U).ravel() - r) / 1e-6
        step = np.linalg.lstsq(J, -r, rcond=None)[0]
        p = p + step
        if np.linalg.norm(step) < 1e-10:
            break
    res = project(p, X) - U
    return p, res
