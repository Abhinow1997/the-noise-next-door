# The camper's animations, on the chubby man (TiZeta's "chubby boy", Blend Swap 66415, CC-BY 3.0; made game-ready by
# prepare_chubby.py): walk, run, bend and take_away. Asked for on 22 Oct 2026 at 01:21, when the author chose him as the
# game's camper: "ok i like how this one looks this is our camper now we will work with this as the main npc log the
# model in and work on creating the animations for this model"; the four are the ones asked for the last camper on
# 21 Oct ("this human needs to walk, run(chase), bend and take away"), with what the author chose then: "Snatch it
# back" for take away, "Look down at the raccoon" for bend.
#
# Claude Code wrote this, the same way as tools/blender/animate_human_camper.py, on his own rig (20 bones, named in
# Italian; TiZeta named the sides as seen from in front, so the _R bones are his left, +X). His walk replaces TiZeta's
# "cammina": as it came, its standing foot slid back unevenly (from 8 mm to 9 cm a frame) and neither foot quite
# reached the ground, so in the game, moving at a steady speed, he would skate. (The original is still in
# design/downloads/chubby/chubby.blend.) Every action is keyed on every frame at 25 fps from a pose worked out here:
#   - the legs are solved, not posed by hand: each shoe is placed (planted, rolling heel to toe, or swinging) and the
#     thigh and shin are turned to reach it, the knee pointing the way his toes do, so the feet don't slide;
#   - the arms are posed by angle in the walk and run, and solved to a point in the other two;
#   - the beats of bend and take_away are key poses, eased through with a monotone cubic (no overshoot);
#   - his belly sets the bend and the stoop: more knee, his knees spread round it, less lean than the last camper's.
#   walk       28 frames, looping: an easy, rolling stroll, 0.57 m steps, 1.02 m/s at 1x
#   run        16 frames, looping: the chase, leaning in with his arms pumping, 1.05 m steps, 3.28 m/s at 1x
#   bend       72 frames: hands onto his knees, peers ahead and down, tilts his head one way and the other, stands up
#   take_away  72 frames: squats, grabs with his right hand at TAKE_GRIP (the raccoon's mouth), two tugs, yanks it free
#              and rocks back on his heels, straightens up holding it at his belly in both hands, shakes his head;
#              he ends there, holding it (the game decides what comes next)
#   dance      64 frames, looping (added 23 Oct 2026 for the campsite): a step-touch over four beats, fists up, see DANCE
#   hammer     25 frames, looping (the same day): squatting, knocks a tent peg in with a mallet, see hammer_clip
# All in place, facing -Y (+Z in Godot): the game moves him and plays walk and run at speed / their speed above.
#
# prepare_chubby.py ends by running this file (the build gives the whole .blend and .glb). On its own, it re-keys the
# four actions on the saved .blend, saves it and exports the .glb (Windows, Git Bash, from the repository's folder;
# CHUBBY_OUT, a path without an extension, works on a test copy instead):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --disable-autoexec \
#       --python-exit-code 1 --python tools/blender/animate_chubby.py

import bpy, math, os
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

FPS = 25
TAKE_GRIP = Vector((-0.16, -0.33, 0.31))    # where he takes the item: the raccoon's mouth (rig space, metres)
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
# Turns are in degrees about rig axes: +X tips a bone's top forward (a limb hanging down swings back), +Y tips it to
# his left, +Z turns it to his left. He faces -Y, his left is +X.


def clamp(t, a=0.0, b=1.0):
    return a if t < a else b if t > b else t


def ease(t):
    t = clamp(t); return t * t * (3 - 2 * t)


def rot(axis, deg):
    return Matrix.Rotation(math.radians(deg), 3, axis)


def hermite(p0, p1, m0, m1, s):
    s2, s3 = s * s, s * s * s
    return (2 * s3 - 3 * s2 + 1) * p0 + (s3 - 2 * s2 + s) * m0 + (-2 * s3 + 3 * s2) * p1 + (s3 - s2) * m1


def pchip(ts, vs, t):
    """Monotone cubic through (ts[i], vs[i]): it eases into and out of every highest and lowest key and never
    overshoots, so a pose held over two keys stays still. Flat at both ends."""
    if t <= ts[0]: return vs[0]
    if t >= ts[-1]: return vs[-1]
    n = len(ts)
    h = [ts[k + 1] - ts[k] for k in range(n - 1)]
    d = [(vs[k + 1] - vs[k]) / h[k] for k in range(n - 1)]
    m = [0.0] * n
    for k in range(1, n - 1):
        if d[k - 1] * d[k] > 0:
            w1, w2 = 2 * h[k] + h[k - 1], h[k] + 2 * h[k - 1]
            m[k] = (w1 + w2) / (w1 / d[k - 1] + w2 / d[k])
    i = max(k for k in range(n - 1) if ts[k] <= t)
    s = (t - ts[i]) / h[i]
    return hermite(vs[i], vs[i + 1], m[i] * h[i], m[i + 1] * h[i], s)


class Body:
    """His rig's rest measurements, and the pose solver: a pose (a dict, see solve) becomes every bone's matrix in rig
    space, worked out here rather than by Blender, then each bone's local channels."""

    # TiZeta's _R bones are on his left (+X)
    SIDES = {"l": dict(s=1, arm="bicipite_R", fore="avambraccio_R", hand="mano_R", thigh="gamba_R", shin="polpaccio_R",
                       foot="piede_R", toes="avampiede_R"),
             "r": dict(s=-1, arm="bicipite_L", fore="avambraccio_L", hand="mano_L", thigh="gamba_L", shin="polpaccio_L",
                       foot="piede_L", toes="avampiede_L")}

    def __init__(self, rig, body):
        self.rig = rig
        self.B = rig.data.bones
        self.rest = {b.name: b.matrix_local.copy() for b in self.B}
        self.keyed = [b.name for b in self.B if b.use_deform]
        me = body.data
        names = {g.index: g.name for g in body.vertex_groups}
        def owner(v):
            return names[max(v.groups, key=lambda g: g.weight).group] if v.groups else None
        self.surface = BVHTree.FromPolygons([v.co.copy() for v in me.vertices], [tuple(p.vertices) for p in me.polygons])
        self.side = {}
        for k, sd in self.SIDES.items():
            s = sd["s"]
            low = [v.co for v in me.vertices if owner(v) in (sd["foot"], sd["toes"]) and v.co.z < 0.012]
            heel = max(low, key=lambda c: c.y).copy(); toe = min(low, key=lambda c: c.y).copy()
            heel.z = toe.z = 0.0
            fwd = toe - heel; fwd.z = 0; fwd.normalize()
            S, E, W = self.head(sd["arm"]), self.head(sd["fore"]), self.tail(sd["fore"])
            D = (W - S).normalized(); Q = (E - S) - D * (E - S).dot(D)
            arm_n = Q.normalized().cross(D).normalized()
            fb = self.tail(sd["foot"]) - self.head(sd["foot"])
            toe_out = math.degrees(math.atan2(s * fb.x, -fb.y))
            leg_q = rot(Z, s * toe_out) @ Vector((0, -1, 0))
            leg_n = leg_q.cross((self.tail(sd["shin"]) - self.head(sd["thigh"])).normalized()).normalized()
            hand = self.rest[sd["hand"]].to_3x3()
            palm_n = (Vector((-s, 0, 0)) - hand.col[1] * hand.col[1].dot(Vector((-s, 0, 0)))).normalized()
            hv = [v.co for v in me.vertices if owner(v) == sd["hand"]]
            self.side[k] = dict(sd, heel=heel, toe=toe, fwd=fwd, lat=fwd.cross(Z).normalized(), toe_out=toe_out,
                                arm_n=arm_n, arm_q=Q.normalized(), leg_q=leg_q, leg_n=leg_n,
                                palm=sum(hv, Vector()) / len(hv), palm_n=palm_n, ankle=self.tail(sd["shin"]))

    def head(self, n): return self.rest[n].translation.copy()
    def tail(self, n): return self.rest[n] @ Vector((0, self.B[n].length, 0))

    def front(self, x, z):
        """How far forward his body reaches at (x, z) at rest (the y of its front)."""
        hit = self.surface.ray_cast(Vector((x, -1.0, z)), Vector((0, 1, 0)), 3.0)[0]
        return hit.y

    def fk(self, P, n, R=None):
        """Bone n's matrix from its parent's, its local rotation being R (a rotation in rest rig axes, carried by
        the parent)."""
        b = self.B[n]
        basis = Matrix.Identity(4)
        if R is not None:
            M = self.rest[n].to_3x3()
            basis = (M.inverted() @ R @ M).to_4x4()
        if b.parent:
            return b.convert_local_to_pose(basis, b.matrix_local, parent_matrix=P[b.parent.name],
                                           parent_matrix_local=b.parent.matrix_local)
        return b.convert_local_to_pose(basis, b.matrix_local)

    def absolute(self, P, n, R):
        """Bone n where its parent puts it, but turned by R from rest regardless of how its parent has turned."""
        M = (R @ self.rest[n].to_3x3()).to_4x4(); M.translation = self.fk(P, n).translation
        return M

    def delta(self, P, n):
        """How bone n has moved from rest, as one rig-space transform."""
        return P[n] @ self.rest[n].inverted()

    @staticmethod
    def frame(pos, ydir, hinge, hinge_local):
        """A bone matrix at pos, its length along ydir and its rest hinge axis (local) turned onto hinge."""
        y = ydir.normalized()
        a = hinge - y * hinge.dot(y); a.normalize()
        al = hinge_local - Vector((0, 1, 0)) * hinge_local.y; al.normalize()
        W = Matrix((a, y, a.cross(y))).transposed()
        L = Matrix((al, Vector((0, 1, 0)), al.cross(Vector((0, 1, 0))))).transposed()
        M = (W @ L.transposed()).to_4x4(); M.translation = pos
        return M

    def ik(self, P, upper, lower, target, pole, n_rest):
        """Two-bone reach: upper's head stays, lower's tail goes to target (or as near as the bones reach), the middle
        joint bending towards pole as a true hinge. Returns how far short it fell."""
        root = self.fk(P, upper).translation
        l1, l2 = self.B[upper].length, self.B[lower].length
        D = target - root; d0 = D.length
        d = clamp(d0, abs(l1 - l2) + 1e-4, (l1 + l2) * 0.99999)
        Dn = D.normalized()
        Q = pole - Dn * pole.dot(Dn); Q.normalize()
        a = math.acos(clamp((l1 * l1 + d * d - l2 * l2) / (2 * l1 * d), -1, 1))
        mid = root + l1 * (math.cos(a) * Dn + math.sin(a) * Q)
        end = root + Dn * d
        n = Q.cross(Dn).normalized()
        for b, p, q in ((upper, root, mid), (lower, mid, end)):
            P[b] = self.frame(p, q - p, n, self.rest[b].to_3x3().transposed() @ n_rest)
        return max(0.0, d0 - d)

    def foot(self, k, pitch=0.0, pivot="heel", shift=Vector()):
        """A shoe's transform from rest: tipped toes-up by pitch degrees (negative: heel up) about its heel's or toe's
        edge on the ground, then moved by shift."""
        sd = self.side[k]
        p = sd["heel"] if pivot == "heel" else sd["toe"]
        R = Matrix.Rotation(math.radians(pitch), 4, sd["lat"])
        return Matrix.Translation(shift + p) @ R @ Matrix.Translation(-p)

    def solve(self, pose):
        """pose: pel (Vector, his root moved), turns {bone: [(axis, deg)]} (local, see fk; the belly's are absolute,
        like the last camper's waist), head_world (absolute turns for the head), feet {k: transform from rest},
        knee_out (deg), arms {k: dict(target=fn(P)->(point, rotation or None), pole=Vector)} for solved arms.
        Returns (P, the worst shortfall)."""
        T = pose.get("turns", {})
        def R(n):
            M = Matrix.Identity(3)
            for axis, deg in T.get(n, []):
                M = rot(axis, deg) @ M
            return M
        P = {}
        short = 0.0
        P["root"] = Matrix.Translation(pose.get("pel", Vector())) @ self.fk(P, "root")
        P["bacino"] = self.fk(P, "bacino", R("hips"))
        hipR = self.delta(P, "bacino").to_3x3()
        feet = pose.get("feet", {})
        for k, sd in self.side.items():
            F = feet.get(k, Matrix.Identity(4))
            pole = hipR @ rot(Z, sd["s"] * pose.get("knee_out", 0.0)) @ sd["leg_q"]
            short = max(short, self.ik(P, sd["thigh"], sd["shin"], F @ sd["ankle"], pole, sd["leg_n"]))
            for n in (sd["foot"], sd["toes"]):
                P[n] = F @ self.rest[n]
        P["addome"] = self.absolute(P, "addome", R("tum"))
        P["schiena"] = self.fk(P, "schiena", R("chest"))
        P["collo"] = self.fk(P, "collo", R("neck"))
        Rw = Matrix.Identity(3)
        for axis, deg in pose.get("head_world", []):
            Rw = rot(axis, deg) @ Rw
        P["testa"] = self.absolute(P, "testa", Rw)
        arms = pose.get("arms", {})
        for k, sd in self.side.items():
            a, fo, h = sd["arm"], sd["fore"], sd["hand"]
            P[a] = self.fk(P, a, R("arm_" + k))
            P[fo] = self.fk(P, fo, R("fore_" + k))
            P[h] = self.fk(P, h, R("hand_" + k))
            if k in arms:
                point, Rh = arms[k]["target"](P)
                if Rh is None:
                    Rh = self.delta(P, h).to_3x3()
                wrist = point - Rh @ (sd["palm"] - self.head(h))
                short = max(short, self.ik(P, a, fo, wrist, arms[k]["pole"], sd["arm_n"]))
                M = (Rh @ self.rest[h].to_3x3()).to_4x4()
                M.translation = P[fo] @ Vector((0, self.B[fo].length, 0))
                P[h] = M
        return P, short

    def channels(self, P):
        """Every keyed bone's local (location, rotation) for the matrices in P."""
        out = {}
        for n in self.keyed:
            b = self.B[n]
            if b.parent:
                L = b.convert_local_to_pose(P[n], b.matrix_local, parent_matrix=P[b.parent.name],
                                            parent_matrix_local=b.parent.matrix_local, invert=True)
            else:
                L = b.convert_local_to_pose(P[n], b.matrix_local, invert=True)
            out[n] = (L.to_translation(), L.to_quaternion().normalized())
        return out


# --- the walk and the run: each shoe's path over a step cycle -------------------------------------------------------
def gait_foot(body, k, p, g):
    """Where shoe k is at leg phase p (0 = the heel touching down) for the gait g. On the ground (p < duty) the shoe
    goes back at the body's speed, first rolling flat about its heel, then flat, then tipping onto its toe; in the air
    it swings forward, lifting, and comes round to land heel first."""
    stride, duty = g["stride"], g["duty"]
    back = Vector((0, 1, 0))                               # a planted foot goes straight back under him
    d0 = g["d0"]
    def on_ground(q):
        dist = d0 + stride * q
        if q < g["flat"]:
            return body.foot(k, g["strike"] * (1 - ease(q / g["flat"])), "heel", back * dist)
        if q < g["heel_off"]:
            return body.foot(k, 0.0, "heel", back * dist)
        f = (q - g["heel_off"]) / (duty - g["heel_off"])
        return body.foot(k, g["off"] * (f * f * (3 - 2 * f) * 0.5 + f * 0.5), "toe", back * dist)
    p %= 1.0
    if p < duty:
        return on_ground(p)
    s = (p - duty) / (1 - duty)
    sd = body.side[k]
    mid = (sd["heel"] + sd["toe"]) / 2
    A, Bm = on_ground(duty - 1e-4), body.foot(k, g["strike"], "heel", back * d0)
    a, b = A @ mid, Bm @ mid
    span = 1 - duty
    vy = stride * span                                     # the planted speed, in this swing's time
    y = hermite(a.dot(back), b.dot(back), vy, vy, s)
    z = a.z + (b.z - a.z) * ease(s) + g["lift"] * math.sin(math.pi * s ** g["lift_early"])
    spin = 0.5 * g["off"] / (duty - g["heel_off"])         # how fast it was tipping as it left the ground
    pitch = hermite(g["off"], g["strike"], spin * span, 0.0, s)
    side = mid - back * mid.dot(back); side.z = 0
    c = side + back * y + Vector((0, 0, z))
    Rm = Matrix.Rotation(math.radians(pitch), 4, sd["lat"])
    return Matrix.Translation(c) @ Rm @ Matrix.Translation(-mid)


def cycle_pose(body, u, g):
    """One frame of a looping gait at cycle phase u; his left heel lands at u = 0, his right at u = 0.5."""
    c, s2 = math.cos(math.tau * u), math.sin(math.tau * u)
    pose = dict(turns={}, feet={}, arms={})
    t = pose["turns"]
    def turn(n, axis, deg): t.setdefault(n, []).append((axis, deg))
    pose["feet"]["l"] = gait_foot(body, "l", u, g)
    pose["feet"]["r"] = gait_foot(body, "r", u + 0.5, g)
    bob = g["bob"] * math.cos(2 * math.tau * (u - g["bob_low"]) + math.pi)    # low at bob_low and bob_low + 0.5
    pose["pel"] = Vector((g["sway"] * math.sin(math.tau * (u - g["sway_lag"])), 0.0, g["drop"] + bob))
    turn("hips", Z, -g["yaw"] * c)                          # the leg going forward takes its hip forward
    turn("hips", Y, -g["list"] * s2)                        # the hip over the swinging leg dips
    turn("hips", X, g["tilt"])
    turn("tum", X, g["lean"] + g["lean_bob"] * math.cos(2 * math.tau * (u - g["bob_low"])))
    turn("tum", Z, g["twist"] * c)                          # shoulders against the hips
    turn("tum", Y, g["list"] * g["roll"] * s2)              # his body rolls over the standing leg
    turn("chest", X, g["chest"])
    turn("chest", Z, g["twist"] * 0.6 * c)
    turn("neck", X, -0.3 * g["lean"])
    pose["head_world"] = [(Z, 0.0), (X, g["look"])]         # the head steady, looking where he's going
    for k, sd in body.side.items():
        s = sd["s"]
        ph = u + (0.0 if k == "l" else 0.5)                 # this arm comes forward with the other leg
        fwd = math.cos(math.tau * (ph - 0.5 - g["arm_lag"]))       # +1 at full forward
        sw = g["arm_bias"] - g["arm_swing"] * fwd
        turn("arm_" + k, Z, -s * g["arm_in"])
        turn("arm_" + k, Y, -s * g["arm_out"])               # out from his sides, round his belly
        turn("arm_" + k, X, sw)
        turn("fore_" + k, sd["arm_n"],
             g["elbow"] + g["elbow_fwd"] * max(0.0, fwd) + g["elbow_back"] * max(0.0, -fwd))
        lag = math.cos(math.tau * (ph - 0.5 - g["arm_lag"] - 0.08))
        turn("hand_" + k, sd["arm_n"], g["wrist"] * lag)
    return pose


# his legs (hip to ankle) are 0.88 of the last camper's: the steps and the bounce are his size
WALK = dict(frames=28, stride=1.14, duty=0.60, flat=0.11, heel_off=0.40, strike=14.0, off=-30.0,
            d0=-0.31, lift=0.040, lift_early=0.8,
            bob=0.016, bob_low=0.04, drop=-0.020, sway=0.030, sway_lag=0.02,
            yaw=5.0, list=4.5, roll=0.7, tilt=2.0, lean=2.0, lean_bob=0.6, twist=4.0, chest=0.0, look=3.0,
            arm_swing=17.0, arm_bias=-1.0, arm_lag=0.05, arm_in=2.0, arm_out=8.0,
            elbow=12.0, elbow_fwd=10.0, elbow_back=0.0, wrist=3.0)
RUN = dict(frames=16, stride=2.10, duty=0.36, flat=0.06, heel_off=0.20, strike=9.0, off=-38.0,
           d0=-0.30, lift=0.17, lift_early=0.65,
           bob=0.026, bob_low=0.14, drop=-0.050, sway=0.020, sway_lag=0.10,
           yaw=8.0, list=3.5, roll=0.5, tilt=5.0, lean=14.0, lean_bob=1.5, twist=8.0, chest=2.0, look=0.0,
           arm_swing=42.0, arm_bias=-4.0, arm_lag=0.03, arm_in=10.0, arm_out=12.0,
           elbow=80.0, elbow_fwd=8.0, elbow_back=-15.0, wrist=4.0)


# --- bend and take_away: key poses ---------------------------------------------------------------------------------
class Keys:
    """Key poses at frames: each key lists only what changes, everything else carrying on from the key before.
    Numbers (and Vectors) are eased through with pchip; hand places are resolved on each frame first (see
    keyed_pose)."""

    def __init__(self, first, keys):
        self.frames, self.vals = [], []
        cur = dict(first)
        for f, change in keys:
            cur = dict(cur); cur.update(change)
            self.frames.append(f); self.vals.append(cur)

    def get(self, name, f):
        vs = [v[name] for v in self.vals]
        if isinstance(vs[0], Vector):
            return Vector([pchip(self.frames, [v[i] for v in vs], f) for i in range(3)])
        return pchip(self.frames, vs, f)

    def each(self, name):
        return [v[name] for v in self.vals]


REST = dict(pel=Vector(), hips_p=0.0, hips_r=0.0, hips_y=0.0, tum_p=0.0, tum_r=0.0, tum_y=0.0, chest_p=0.0,
            neck_p=0.0, head_p=0.0, head_r=0.0, head_y=0.0, knee_out=0.0, l_toe=0.0, r_toe=0.0,
            l_ik=0.0, r_ik=0.0, l_pole_w=0.0, r_pole_w=0.0, l_sw=0.0, r_sw=0.0, l_el=0.0, r_el=0.0,
            l_at=("fk",), r_at=("fk",))
# a hand's place: ("fk",) as the arm hangs; (bone, rest point, (finger dir, palm dir)): the rest-pose point and the
# way the hand faces, both carried by that bone; ("world", point, (finger dir, palm dir)): fixed in the rig's space


def hand_rot(body, k, fingers, palm):
    """The hand's turn from rest that points its fingers along `fingers` with its palm facing `palm`."""
    sd = body.side[k]
    M = body.rest[sd["hand"]].to_3x3()
    y0, n0 = M.col[1].normalized(), sd["palm_n"]
    A = Matrix((n0, y0, n0.cross(y0))).transposed()
    y1 = fingers.normalized(); n1 = palm - y1 * palm.dot(y1); n1.normalize()
    Bm = Matrix((n1, y1, n1.cross(y1))).transposed()
    return Bm @ A.transposed()


def resolve(body, P, k, at):
    """A hand place (see REST) on this frame: (point, hand rotation from rest or None for the arm's own)."""
    sd = body.side[k]
    if at[0] == "fk":
        D = body.delta(P, sd["hand"])
        return D @ sd["palm"], D.to_3x3()
    _, pt, (fing, palm) = at
    Rh = hand_rot(body, k, fing, palm)
    if at[0] == "world":
        return Vector(pt), Rh
    D = body.delta(P, at[0])
    return D @ Vector(pt), D.to_3x3() @ Rh


def keyed_pose(body, keys, f):
    """One frame of a key-posed clip."""
    g = lambda n: keys.get(n, f)
    pose = dict(turns={}, feet={}, arms={})
    t = pose["turns"]
    def turn(n, axis, deg):
        if deg: t.setdefault(n, []).append((axis, deg))
    pose["pel"] = g("pel")
    turn("hips", Z, g("hips_y")); turn("hips", Y, g("hips_r")); turn("hips", X, g("hips_p"))
    turn("tum", Z, g("tum_y")); turn("tum", Y, g("tum_r")); turn("tum", X, g("tum_p"))
    turn("chest", X, g("chest_p")); turn("neck", X, g("neck_p"))
    pose["head_world"] = [(Y, g("head_r")), (X, g("head_p")), (Z, g("head_y"))]
    pose["knee_out"] = g("knee_out")
    for k, sd in body.side.items():
        pose["feet"][k] = body.foot(k, g(k + "_toe"), "heel")
        turn("arm_" + k, X, g(k + "_sw"))
        turn("fore_" + k, sd["arm_n"], g(k + "_el"))
        w, pw = g(k + "_ik"), g(k + "_pole_w")
        if w <= 0 and not any(a[0] != "fk" for a in keys.each(k + "_at")):
            continue
        def target(P, k=k, w=w):
            pts = [resolve(body, P, k, at) for at in keys.each(k + "_at")]
            point = Vector([pchip(keys.frames, [p[0][i] for p in pts], f) for i in range(3)])
            q = [p[1].to_quaternion() for p in pts]
            for i in range(1, len(q)):
                if q[i].dot(q[i - 1]) < 0: q[i].negate()
            qv = Quaternion([pchip(keys.frames, [x[i] for x in q], f) for i in range(4)]).normalized()
            fk_pt, fk_R = resolve(body, P, k, ("fk",))
            return fk_pt.lerp(point, w), fk_R.to_quaternion().slerp(qv, w).to_matrix()
        # the elbow: as it hangs at rest (back), swung out and back by pole_w for the reaching poses
        pole = (sd["arm_q"] * (1 - pw) + Vector((sd["s"] * 0.75, 0.55, 0.25)) * pw).normalized()
        pose["arms"][k] = dict(target=target, pole=pole)
    return pose


def clips(body):
    """bend and take_away for his shape: the hand places are measured on him (the front of his knees, his belly)."""
    knee = {}
    for k, sd in body.side.items():
        x = body.tail(sd["thigh"]).x
        z = body.tail(sd["thigh"]).z + 0.07
        knee[k] = (sd["thigh"], Vector((x, body.front(x, z) - 0.012, z)),
                   (Vector((-sd["s"] * 0.25, -0.75, -0.6)), Vector((0, 0.3, -1))))       # fingers over the knee, palm down
    belly = body.front(0.0, 1.10)                          # the front of his belly, where he holds the item
    hold_r = ("schiena", Vector((-0.045, belly - 0.075, 1.13)), (Vector((0.85, -0.2, 0.45)), Vector((0.2, 0.1, 1.0))))
    hold_l = ("schiena", Vector((0.080, belly - 0.065, 1.10)), (Vector((-0.8, -0.35, 0.45)), Vector((-0.9, 0, 0.2))))
    up_r = ("schiena", Vector((-0.13, belly + 0.02, 1.30)), (Vector((0.4, -0.2, 0.9)), Vector((0.9, 0.2, 0.2))))
    reach = ("world", TAKE_GRIP, (Vector((0.05, -0.55, -0.83)), Vector((0.95, 0.1, -0.1))))
    tug = lambda dy, dz: ("world", TAKE_GRIP + Vector((0, dy, dz)), (Vector((0.05, -0.45, -0.89)), Vector((0.95, 0.1, -0.1))))
    bend = Keys(REST, [
        (0, {}),
        (5, dict(pel=Vector((0, 0.005, -0.004)), tum_p=-2.0, head_p=-3.0)),          # a breath in, about to look
        (17, dict(pel=Vector((0, 0.11, -0.20)), hips_p=18.0, tum_p=34.0, chest_p=6.0, neck_p=-16.0, head_p=20.0,
                  knee_out=16.0, l_ik=1.0, r_ik=1.0, l_pole_w=1.0, r_pole_w=1.0, l_at=knee["l"], r_at=knee["r"])),
        (22, dict(pel=Vector((0, 0.10, -0.21)), tum_p=36.0, head_p=21.0)),               # settles
        (32, dict(pel=Vector((0, 0.09, -0.22)), tum_p=40.0, neck_p=-20.0, head_p=25.0, head_r=-16.0,   # leans in, his
                  head_y=-6.0)),                                                          # head on one side
        (40, dict(head_r=-17.0)),
        (48, dict(head_r=15.0, head_y=6.0, head_p=24.0)),                                  # and the other
        (55, dict(head_r=14.0)),
        (60, dict(pel=Vector((0, 0.10, -0.21)), tum_p=36.0, neck_p=-16.0, head_p=20.0, head_r=0.0, head_y=0.0)),
        (72, dict(REST)),
    ])
    take = Keys(REST, [
        (0, {}),
        (4, dict(pel=Vector((0, -0.005, -0.004)), tum_p=-3.0, head_p=6.0)),         # sees it, draws back a touch
        (13, dict(pel=Vector((-0.05, 0.12, -0.36)), hips_p=22.0, hips_y=-6.0, tum_p=56.0, tum_y=-12.0, tum_r=-10.0,
                  chest_p=10.0, neck_p=-16.0, head_p=48.0, head_y=-8.0, knee_out=34.0,
                  r_ik=1.0, r_pole_w=0.8, r_at=reach, l_ik=1.0, l_pole_w=1.0, l_at=knee["l"])),     # squats and reaches
        (21, dict(pel=Vector((-0.05, 0.14, -0.34)), tum_p=52.0, r_at=tug(0.07, 0.03))),            # tug
        (25, dict(pel=Vector((-0.05, 0.12, -0.36)), tum_p=55.0, r_at=tug(0.02, 0.0))),             # it pulls back
        (30, dict(pel=Vector((-0.05, 0.15, -0.33)), tum_p=51.0, r_at=tug(0.09, 0.04))),            # tug
        (33, dict(pel=Vector((-0.05, 0.13, -0.35)), tum_p=54.0, r_at=tug(0.04, 0.01))),
        (38, dict(pel=Vector((-0.02, 0.10, -0.08)), hips_p=4.0, hips_y=-2.0, tum_p=3.0, tum_y=-4.0, tum_r=0.0,
                  chest_p=-6.0, neck_p=-2.0, head_p=-10.0, head_y=0.0, knee_out=6.0, l_toe=14.0, r_toe=14.0,
                  r_at=up_r, l_ik=0.0, l_pole_w=0.0, l_at=("fk",), l_sw=25.0, l_el=30.0)),          # free: he rocks back
        (44, dict(pel=Vector((0, 0.02, -0.02)), hips_p=0.0, hips_y=0.0, tum_p=2.0, tum_y=0.0, chest_p=-2.0, head_p=0.0,
                  knee_out=0.0, l_toe=0.0, r_toe=0.0, l_sw=-10.0, l_el=40.0)),                     # catches his balance
        (52, dict(pel=Vector((0, 0.0, -0.01)), tum_p=4.0, neck_p=4.0, head_p=24.0,                # holds it to him,
                  r_at=hold_r, r_pole_w=0.3, l_ik=1.0, l_pole_w=0.3, l_at=hold_l,                   # looking down at him
                  l_sw=0.0, l_el=0.0)),
        (56, dict(head_y=13.0)),                                                                  # shakes his head
        (60, dict(head_y=-12.0)),
        (64, dict(head_y=9.0)),
        (68, dict(head_y=0.0, head_p=20.0, tum_p=1.0)),
        (72, dict(head_p=18.0)),
    ])
    return bend, take


# --- dance and hammer: the campsite (23 Oct 2026) --------------------------------------------------------------------
# Asked for with the level 1 campsite: "they are setting tents and partying". Two more loops, in place like the rest:
#   dance   64 frames, looping: a step-touch, out to his right and back over four beats, landing on each beat with a
#           bounce in his knees, his hips popping and his arms grooving (each of the three has his or her own arms);
#           four beats in 64 frames is 93.75 beats a minute, and the game plays it a touch slower to land on the
#           level music's 91.9
#   hammer  25 frames, looping (one blow a second): squatting at a tent peg, he raises the mallet in his right hand and
#           knocks the peg in, his left hand on his knee; the game puts the mallet in his hand (mallet_grip prints
#           where) and the peg at HAMMER_PEG
def _arm(sw=-15.0, sw_amp=0.0, out=8.0, out_amp=0.0, el=90.0, el_amp=0.0, phase=0.0, period=2.0, inward=0.0,
         wrist=0.0):
    """An arm's part in the dance: its swing forward (sw, negative raises it in front), out to the side (out) and its
    elbow (el), each moving by its _amp over `period` beats from `phase`; the elbow pumps once a beat."""
    return dict(sw=sw, sw_amp=sw_amp, out=out, out_amp=out_amp, el=el, el_amp=el_amp, phase=phase, period=period,
                inward=inward, wrist=wrist)


# the camper's dance: elbows bent, his forearms swinging in turn, a big bounce round his belly
DANCE = dict(frames=64, beats=4, step=0.16, lift=0.05, bounce=0.035, drop=-0.035, pop=4.0, yaw=7.0, twist=-6.0,
             lean=4.0, nod=5.0, look=-2.0,
             arms={"l": _arm(sw=-30.0, sw_amp=18.0, out=24.0, el=85.0, el_amp=12.0, phase=0.0, inward=-30.0),
                   "r": _arm(sw=-30.0, sw_amp=18.0, out=24.0, el=85.0, el_amp=12.0, phase=1.0, inward=-30.0)})


def dance_pose(body, u, d):
    """One frame of the dance at loop phase u: over d["beats"] beats his right foot steps out to his right, his left
    closes up to it, his left steps back and his right closes, each step landing on a beat; his knees give on every
    beat, his hips pop to one side and the other, and his arms do as d["arms"] says."""
    n = d["beats"]
    t = (u % 1.0) * n                                       # in beats
    w = d["step"]
    # each foot's steps: (the beat it lands on, from, to), across (x, his left +); a step takes half a beat
    steps = {"r": [(1.0, 0.0, -w), (4.0, -w, 0.0)], "l": [(2.0, 0.0, -w), (3.0, -w, 0.0)]}
    pose = dict(turns={}, feet={}, arms={})
    tt = pose["turns"]
    def turn(nm, axis, deg): tt.setdefault(nm, []).append((axis, deg))
    xs = {}
    for k, moves in steps.items():
        x, up = moves[0][1], 0.0
        for land, a, b in moves:
            if t >= land:
                x = b
            elif t >= land - 0.5:
                s = (t - land + 0.5) / 0.5
                x, up = a + (b - a) * ease(s), math.sin(math.pi * s)
                break
            else:
                break
        xs[k] = x
        pose["feet"][k] = body.foot(k, -8.0 * up, "toe", Vector((x, 0.0, d["lift"] * up)))
    beat = math.cos(math.tau * t)                           # +1 on each beat
    pose["pel"] = Vector(((xs["l"] + xs["r"]) / 2, 0.0, d["drop"] - d["bounce"] * (0.5 + 0.5 * beat)))
    pop = math.cos(math.pi * t)                             # one side on the even beats, the other on the odd
    turn("hips", Y, d["pop"] * pop)
    turn("hips", Z, d["yaw"] * math.sin(math.pi * t))
    turn("tum", Z, d["twist"] * math.sin(math.pi * t))
    turn("tum", Y, -0.6 * d["pop"] * pop)
    turn("tum", X, d["lean"])
    turn("neck", X, d["nod"] * (0.5 + 0.5 * beat))
    pose["head_world"] = [(Z, 0.0), (X, d["look"])]
    for k, sd in body.side.items():
        s, a = sd["s"], d["arms"][k]
        c = math.cos(math.tau * (t + a["phase"]) / a["period"])
        turn("arm_" + k, Z, -s * a["inward"])
        turn("arm_" + k, Y, -s * (a["out"] + a["out_amp"] * c))
        turn("arm_" + k, X, a["sw"] + a["sw_amp"] * c)
        turn("fore_" + k, sd["arm_n"], a["el"] + a["el_amp"] * beat)
        turn("hand_" + k, sd["arm_n"], a["wrist"])
    return pose


HAMMER_FRAMES = 25
HAMMER_PEG = Vector((-0.28, -0.52, 0.08))   # the top of the peg he knocks in, outside his right foot (rig space, m)
# The mallet the game puts in his hand: its handle's length and how much of it sticks out behind his hand, and its
# head's length and radius. Its handle runs along his hand, from his wrist towards his fingers; its head lies across
# the end of it, thumb side to little-finger side.
MALLET = dict(handle=0.32, grip=0.05, head=0.11, head_r=0.04)


def hammer_clip(body):
    """The hammer loop for his shape: squatting as he does to take something, his left hand on his left knee; his
    right hand comes up, cocks back and brings the mallet down on HAMMER_PEG, the head's face landing flat on it, then
    lifts again. Where the hand is and which way its fingers point say where the head lands (see MALLET)."""
    sd = body.side["l"]
    x = body.tail(sd["thigh"]).x
    z = body.tail(sd["thigh"]).z + 0.07
    knee = (sd["thigh"], Vector((x, body.front(x, z) - 0.012, z)),
            (Vector((-0.25, -0.75, -0.6)), Vector((0, 0.3, -1))))
    palm = Vector((1.0, 0.0, 0.0))                          # his right palm faces in, to his left
    # the blow: the handle points forward and a little down, so the head's lower face sits on the peg
    handle = Vector((0.0, -0.82, -0.57)).normalized()
    across = palm.cross(handle).normalized()                # the head's axis
    if across.z < 0:
        across.negate()
    hit_hand = HAMMER_PEG + across * (MALLET["head"] / 2) - handle * (MALLET["handle"] - MALLET["grip"])
    hit = ("world", hit_hand, (handle, palm))
    bounce = ("world", hit_hand + Vector((0, 0.02, 0.06)), (Vector((0.0, -0.95, -0.2)), palm))
    # raised: out to his right of his belly, the mallet upright, then cocked back over his shoulder
    up = ("world", Vector((hit_hand.x - 0.06, hit_hand.y - 0.04, 0.62)), (Vector((0.0, 0.2, 0.98)), palm))
    cock = ("world", Vector((hit_hand.x - 0.07, hit_hand.y + 0.03, 0.70)), (Vector((0.0, 0.6, 0.8)), palm))
    squat = dict(pel=Vector((-0.04, 0.12, -0.38)), hips_p=22.0, hips_y=-6.0, tum_p=50.0, tum_y=-10.0, tum_r=-8.0,
                 chest_p=8.0, neck_p=-14.0, head_p=40.0, head_y=-6.0, knee_out=34.0,
                 r_ik=1.0, r_pole_w=0.6, l_ik=1.0, l_pole_w=1.0, l_at=knee)
    return Keys(REST, [
        (0, dict(squat, r_at=up)),
        (6, dict(r_at=cock, tum_p=47.0, head_p=38.0)),                                # winds up
        (10, dict(r_at=hit, tum_p=62.0, head_p=44.0, pel=Vector((-0.04, 0.14, -0.40)))),   # the blow
        (13, dict(r_at=bounce, tum_p=59.0, pel=Vector((-0.04, 0.135, -0.395)))),     # the mallet bounces off
        (HAMMER_FRAMES, dict(squat, r_at=up)),
    ])


def mallet_grip(body, log=print):
    """Where the game puts the mallet, in his right hand bone's own space (as the .glb keeps it): the middle of his
    palm, the handle along +Y, and the head's axis (thumb to little finger)."""
    sd = body.side["r"]
    M = body.rest[sd["hand"]]
    grip = M.inverted() @ sd["palm"]
    across = M.to_3x3().inverted() @ sd["palm_n"].cross(M.to_3x3().col[1].normalized())
    log("mallet: bone %s, palm (%.4f, %.4f, %.4f), head across (%.4f, %.4f, %.4f)" % (
        (sd["hand"],) + tuple(grip) + tuple(across.normalized())))
    return sd["hand"], grip, across.normalized()


CLIPS = [("walk", WALK["frames"], True), ("run", RUN["frames"], True), ("bend", 72, False), ("take_away", 72, False),
         ("dance", DANCE["frames"], True), ("hammer", HAMMER_FRAMES, True)]


def animate(rig, body, only=None, log=print):
    """Key the actions in CLIPS on rig (replacing any of the same names, TiZeta's walk among them), each parked in a
    muted NLA track so the glTF exporter finds them all; the rig is left at rest with no action."""
    for pb in rig.pose.bones:
        pb.location = (0, 0, 0); pb.rotation_mode = "QUATERNION"; pb.rotation_quaternion = (1, 0, 0, 0); pb.scale = (1, 1, 1)
    b = Body(rig, body)
    bend, take = clips(b)
    poses = {"walk": lambda f, n: cycle_pose(b, f / n, WALK), "run": lambda f, n: cycle_pose(b, f / n, RUN),
             "bend": lambda f, n: keyed_pose(b, bend, f), "take_away": lambda f, n: keyed_pose(b, take, f),
             "dance": lambda f, n: dance_pose(b, f / n, DANCE)}
    if any(name == "hammer" for name, _, _ in CLIPS) and (not only or "hammer" in only):
        hammer = hammer_clip(b)
        poses["hammer"] = lambda f, n: keyed_pose(b, hammer, f)
        mallet_grip(b, log)
    ad = rig.animation_data or rig.animation_data_create()
    ad.action = None
    for t in list(ad.nla_tracks):
        ad.nla_tracks.remove(t)
    PB = rig.pose.bones
    for name, frames, loop in CLIPS:
        if only and name not in only:
            continue
        old = bpy.data.actions.get(name)
        if old:
            bpy.data.actions.remove(old)
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        ad.action = act
        prev, worst = {}, 0.0
        for f in range(frames + 1):
            P, short = b.solve(poses[name](f % frames if loop else f, frames))
            worst = max(worst, short)
            for n, (loc, q) in b.channels(P).items():
                if n in prev and q.dot(prev[n]) < 0:
                    q.negate()
                prev[n] = q
                pb = PB[n]
                pb.rotation_quaternion = q
                pb.keyframe_insert("rotation_quaternion", frame=f, group=n)
                if not b.B[n].use_connect:
                    pb.location = loc
                    pb.keyframe_insert("location", frame=f, group=n)
        act.use_frame_range = True
        act.frame_start, act.frame_end = 0, frames
        act.use_cyclic = loop
        log("action %-9s %3d frames%s, limbs short of their targets by at most %.1f mm" % (
            name, frames, " (loops)" if loop else "", worst * 1000))
    ad.action = None
    for name, frames, loop in CLIPS:
        act = bpy.data.actions.get(name)
        if act:
            tr = ad.nla_tracks.new(); tr.name = name
            tr.strips.new(name, 0, act); tr.mute = True
    for pb in PB:
        pb.location = (0, 0, 0); pb.rotation_quaternion = (1, 0, 0, 0); pb.scale = (1, 1, 1)
    bpy.context.scene.render.fps = FPS
    bpy.context.scene.frame_set(0)
    return b


# The .glb: as prepare_chubby.py exported him (+Y up, his texture, his 20 bones, skinned, his body and his beanie), with
# the four actions sampled on every frame.
EXPORT = dict(export_format="GLB", export_yup=True, use_selection=True, export_apply=False, export_cameras=False,
              export_lights=False, export_materials="EXPORT", export_image_format="AUTO", export_skins=True,
              export_def_bones=True, export_morph=False, export_animations=True, export_animation_mode="ACTIONS",
              export_force_sampling=True, export_frame_step=1, export_optimize_animation_size=False,
              export_anim_single_armature=True, export_reset_pose_bones=True, export_current_frame=False)


def export_glb(rig, path):
    parts = [o for o in bpy.data.objects if o.parent is rig]            # his body and his beanie
    for o in bpy.context.view_layer.objects:
        o.select_set(o is rig or o in parts)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=path, **EXPORT)


if __name__ == "__main__":
    REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    OUT = os.environ.get("CHUBBY_OUT") or os.path.join(REPO, "assets", "characters", "chubby_boy")
    bpy.ops.wm.open_mainfile(filepath=OUT + ".blend", load_ui=False, use_scripts=False)
    rig, body = bpy.data.objects["ChubbyBoy_rig"], bpy.data.objects["ChubbyBoy"]
    src = open(__file__, encoding="utf-8").read()
    t = bpy.data.texts.get("chubby_animate") or bpy.data.texts.new("chubby_animate")
    t.clear(); t.write(src)
    animate(rig, body)
    bpy.ops.wm.save_as_mainfile(filepath=OUT + ".blend", compress=True)
    export_glb(rig, OUT + ".glb")
    print("SAVED", OUT + ".blend", "| EXPORTED", OUT + ".glb", os.path.getsize(OUT + ".glb"), "bytes")
