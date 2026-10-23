# The camper's first four animations, on his rig in assets/characters/human_camper.blend (made by
# build_human_camper.py): walk, run, bend and take_away. Asked for on 21 Oct 2026 at 20:09, when the author chose this
# rigged camper for the game: "this human needs to walk, run(chase), bend and take away these are the main one others
# will comin as we go". Claude Code asked what "take away" and "bend" mean and the author picked (about 20:35), from
# options Claude wrote: "Snatch it back" (he bends, takes the item out of the raccoon's mouth, straightens up and holds
# it close; GDD 0.9: when he's caught "humans take back what he carries") and "Look down at the raccoon" (he bends
# forward with his hands on his knees and peers at the raccoon's level, holds it, then straightens up).
# At 20:33, in another session, the author had chosen to animate him through a Rigify control rig, baked onto these
# bones; that reached this work once it was done, and at 21:15 the author kept it as it is: "Keep these, Rigify later".
#
# Claude Code wrote this; nothing here is the download's animation (its walk and run need the IK that
# prepare_humans.py takes out, and were made for the T-pose). Every action is keyed on every frame at 24 fps from a
# pose worked out in this file:
#   - the legs are solved, not posed by hand: each boot is placed (planted, rolling heel to toe, or swinging) and the
#     thigh and shin are turned to reach it, the knee pointing the way his toes do, so the feet don't slide;
#   - the arms are posed by angle in the walk and run, and solved to a point in the other two (the hands on his knees,
#     the right hand at the raccoon's mouth, both hands holding the item at his chest);
#   - the beats of bend and take_away are key poses, eased through with a monotone cubic (no overshoot).
#   walk       28 frames, looping: an easy stroll, 0.65 m steps, 1.11 m/s at 1x
#   run        16 frames, looping: the chase, leaning in with his arms pumping, 1.2 m steps, 3.60 m/s at 1x
#   bend       72 frames: hands onto his knees, peers ahead and down, tilts his head one way and the other, stands up
#   take_away  72 frames: stoops, grabs with his right hand at TAKE_GRIP (the raccoon's mouth), two tugs, yanks it free
#              and rocks back on his heels, straightens up holding it at his chest in both hands, shakes his head;
#              he ends there, holding it (the game decides what comes next)
# All in place, facing -Y (+Z in Godot): the game moves him and plays walk and run at speed / their speed above.
# For take_away the raccoon's mouth goes at TAKE_GRIP, which is (-0.10, 0.30, 0.37) from his feet in Godot's axes. The
# item is in his right hand from frame 16 (0.67 s): in Godot, a BoneAttachment3D on "Hum_r.002" with the item at
# (-0.0107, 0.0917, -0.0199) puts it there (measured in Godot 4.7.2; the bone's axes are the same as in Blender).
#
# Run it after build_human_camper.py, which ends by running this file (the build gives the whole .blend and .glb).
# On its own, it re-keys the four actions on the saved .blend, saves it and exports the .glb (Windows, Git Bash, from
# the repository's folder; HUMAN_CAMPER_OUT, a path without an extension, works on a test copy instead):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --disable-autoexec \
#       --python-exit-code 1 --python tools/blender/animate_human_camper.py

import bpy, math, os
from mathutils import Matrix, Quaternion, Vector

FPS = 24
TOE_OUT = 9.0             # degrees his toes turn out at rest (STAND["toe_out"] in the build): the way his knees point
TAKE_GRIP = Vector((-0.10, -0.37, 0.30))    # where he takes the item: the raccoon's mouth (rig space, metres)
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

    SIDES = {"l": dict(s=1, sh="chest_R", arm="Hum_l", thigh="thigh_l", foot="FOOT_L", f="_l"),
             "r": dict(s=-1, sh="chest_L", arm="Hum_r", thigh="thigh_r", foot="FOOT_R", f="_r")}

    def __init__(self, rig):
        self.rig = rig
        self.B = rig.data.bones
        self.rest = {b.name: b.matrix_local.copy() for b in self.B}
        self.keyed = [b.name for b in self.B if b.use_deform or b.name == "hips_rot"]
        self.order = []
        todo = [b for b in self.B if b.parent is None]
        while todo:
            b = todo.pop(0); self.order.append(b.name); todo += list(b.children)
        soles = bpy.data.objects["HumanCamper_Soles"].data.vertices
        self.side = {}
        for k, sd in self.SIDES.items():
            s = sd["s"]; a, th = sd["arm"], sd["thigh"]
            low = [v.co for v in soles if v.co.x * s > 0 and v.co.z < 0.004]
            heel = max(low, key=lambda c: c.y).copy(); toe = min(low, key=lambda c: c.y).copy()
            heel.z = toe.z = 0.0
            fwd = (toe - heel); fwd.z = 0; fwd.normalize()
            S, E, W = self.head(a), self.head(a + ".001"), self.tail(a + ".001")
            D = (W - S).normalized(); Q = (E - S) - D * (E - S).dot(D)
            arm_n = Q.normalized().cross(D).normalized()
            leg_q = rot(Z, s * TOE_OUT) @ Vector((0, -1, 0))
            leg_n = leg_q.cross((self.tail(th + ".001") - self.head(th)).normalized()).normalized()
            hand = self.rest[a + ".002"].to_3x3()
            palm_n = (Vector((-s, 0, 0)) - hand.col[1] * hand.col[1].dot(Vector((-s, 0, 0)))).normalized()
            self.side[k] = dict(sd, heel=heel, toe=toe, fwd=fwd, lat=fwd.cross(Z).normalized(),
                                arm_n=arm_n, arm_q=Q.normalized(), leg_q=leg_q, leg_n=leg_n,
                                palm=Vector((s * 0.250, -0.050, 0.770)), palm_n=palm_n,
                                ankle=self.tail(th + ".001"),
                                fingers=[f + sd["f"] + x for f in ("pink", "ring", "mid", "point")
                                         for x in ("", ".001", ".002")])

    def head(self, n): return self.rest[n].translation.copy()
    def tail(self, n): return self.rest[n] @ Vector((0, self.B[n].length, 0))

    # --- forward kinematics with Blender's own rules (inherit rotation off for tum, the feet and hips_rot) ---------
    def fk(self, P, n, R=None):
        """Bone n's matrix from its parent's, its local rotation being R (a rotation in rest rig axes, carried by
        the parent; a bone that doesn't inherit rotation takes it as an absolute turn)."""
        b = self.B[n]
        basis = Matrix.Identity(4)
        if R is not None:
            M = self.rest[n].to_3x3()
            basis = (M.inverted() @ R @ M).to_4x4()
        if b.parent:
            return b.convert_local_to_pose(basis, b.matrix_local, parent_matrix=P[b.parent.name],
                                           parent_matrix_local=b.parent.matrix_local)
        return b.convert_local_to_pose(basis, b.matrix_local)

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
        """A boot's transform from rest: tipped toes-up by pitch degrees (negative: heel up) about its heel's or toe's
        edge on the ground, then moved by shift."""
        sd = self.side[k]
        p = sd["heel"] if pivot == "heel" else sd["toe"]
        R = Matrix.Rotation(math.radians(pitch), 4, sd["lat"])
        return Matrix.Translation(shift + p) @ R @ Matrix.Translation(-p)

    def solve(self, pose):
        """pose: pel (Vector, the pelvis moved), turns {bone: [(axis, deg)]} (local, see fk), head_world (absolute
        turns for the head), feet {k: transform from rest}, knee_out (deg), arms {k: dict(target=fn(P)->(point,
        rotation or None), pole=Vector)} for solved arms, curl {k: deg}, thumb {k: deg}. Returns (P, the worst
        shortfall)."""
        T = pose.get("turns", {})
        def R(n):
            M = Matrix.Identity(3)
            for axis, deg in T.get(n, []):
                M = rot(axis, deg) @ M
            return M
        P = {}
        short = 0.0
        P["Bone"] = self.fk(P, "Bone")
        P["hips_rot"] = Matrix.Translation(pose.get("pel", Vector())) @ self.fk(P, "hips_rot")
        P["hips"] = self.fk(P, "hips", R("hips"))
        hipR = self.delta(P, "hips").to_3x3()
        feet = pose.get("feet", {})
        for k, sd in self.side.items():
            F = feet.get(k, Matrix.Identity(4))
            pole = hipR @ rot(Z, sd["s"] * pose.get("knee_out", 0.0)) @ sd["leg_q"]
            short = max(short, self.ik(P, sd["thigh"], sd["thigh"] + ".001", F @ sd["ankle"], pole, sd["leg_n"]))
            for n in (sd["foot"], sd["foot"] + ".001"):
                P[n] = F @ self.rest[n]
        for n in ("tum", "chest", "neck"):
            P[n] = self.fk(P, n, R(n))
        P["head"] = self.fk(P, "head", R("head"))
        if "head_world" in pose:
            Rw = Matrix.Identity(3)
            for axis, deg in pose["head_world"]:
                Rw = rot(axis, deg) @ Rw
            M = (Rw @ self.rest["head"].to_3x3()).to_4x4(); M.translation = P["head"].translation
            P["head"] = M
        arms = pose.get("arms", {})
        for k, sd in self.side.items():
            a = sd["arm"]
            P[sd["sh"]] = self.fk(P, sd["sh"], R(sd["sh"]))
            for n in (a, a + ".001", a + ".002"):
                P[n] = self.fk(P, n, R(n))
            if k in arms:
                point, Rh = arms[k]["target"](P)
                if Rh is None:
                    Rh = self.delta(P, a + ".002").to_3x3()
                wrist = point - Rh @ (sd["palm"] - self.head(a + ".002"))
                short = max(short, self.ik(P, a, a + ".001", wrist, arms[k]["pole"], sd["arm_n"]))
                M = (Rh @ self.rest[a + ".002"].to_3x3()).to_4x4()
                M.translation = P[a + ".001"] @ Vector((0, self.B[a + ".001"].length, 0))
                P[a + ".002"] = M
        curl, thumb = pose.get("curl", {}), pose.get("thumb", {})
        for n in self.order:
            if n in P or not self.B[n].use_deform:
                continue
            k = next((k for k in "lr" if n.endswith(tuple("_" + k + x for x in ("", ".001", ".002", ".003")))), None)
            Rn = R(n)
            if k and n in self.side[k]["fingers"] and curl.get(k):
                Rn = Matrix.Rotation(math.radians(curl[k]), 3, self.curl_axis(n)) @ Rn
            if k and n.startswith("thumb") and thumb.get(k):
                Rn = Matrix.Rotation(math.radians(thumb[k]), 3, self.curl_axis(n)) @ Rn
            P[n] = self.fk(P, n, Rn)
        return P, short

    def curl_axis(self, n):
        """The axis a finger bone curls about, in rest rig axes: across the finger, towards the palm."""
        k = "l" if "_l" in n else "r"
        sd = self.side[k]
        d = (self.tail(n) - self.head(n)).normalized()
        return d.cross(sd["palm_n"]).normalized()

    def channels(self, P):
        """Every keyed bone's local (location, rotation) for the matrices in P."""
        out = {}
        for n in self.keyed:
            b = self.B[n]
            if n not in P:
                P[n] = self.fk(P, n)
            if b.parent:
                L = b.convert_local_to_pose(P[n], b.matrix_local, parent_matrix=P[b.parent.name],
                                            parent_matrix_local=b.parent.matrix_local, invert=True)
            else:
                L = b.convert_local_to_pose(P[n], b.matrix_local, invert=True)
            out[n] = (L.to_translation(), L.to_quaternion().normalized())
        return out


# --- the walk and the run: each boot's path over a step cycle -----------------------------------------------------
def gait_foot(body, k, p, g):
    """Where boot k is at leg phase p (0 = the heel touching down) for the gait g. On the ground (p < duty) the boot
    goes back at the body's speed, first rolling flat about its heel, then flat, then tipping onto its toe; in the air
    it swings forward, lifting, and comes round to land heel first."""
    stride, duty = g["stride"], g["duty"]
    back = Vector((0, 1, 0))                               # a planted foot goes straight back under him
    d0 = g["d0"]
    def on_ground(q):
        dist = d0 + stride * q
        if q < g["flat"]:
            return body.foot(k, g["strike"] * (1 - ease(q / g["flat"])) if g["flat"] > 0 else 0, "heel", back * dist)
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
    """One frame of a looping gait at cycle phase u; the left heel lands at u = 0, the right at u = 0.5."""
    c, s2 = math.cos(math.tau * u), math.sin(math.tau * u)
    pose = dict(turns={}, feet={}, arms={}, curl={}, thumb={})
    t = pose["turns"]
    def turn(n, axis, deg): t.setdefault(n, []).append((axis, deg))
    pose["feet"]["l"] = gait_foot(body, "l", u, g)
    pose["feet"]["r"] = gait_foot(body, "r", u + 0.5, g)
    bob = g["bob"] * math.cos(2 * math.tau * (u - g["bob_low"]) + math.pi)    # low at bob_low and bob_low + 0.5
    pose["pel"] = Vector((g["sway"] * math.sin(math.tau * (u - g["sway_lag"])), g["pel_y"], g["drop"] + bob))
    turn("hips", Z, -g["yaw"] * c)                          # the leg going forward takes its hip forward
    turn("hips", Y, -g["list"] * s2)                        # the hip over the swinging leg dips
    turn("hips", X, g["tilt"])
    turn("tum", X, g["lean"] + g["lean_bob"] * math.cos(2 * math.tau * (u - g["bob_low"])))
    turn("tum", Z, g["twist"] * c)                          # shoulders against the hips
    turn("tum", Y, g["list"] * 0.5 * s2)
    turn("chest", X, g["chest"])
    turn("chest", Z, g["twist"] * 0.6 * c)
    turn("neck", X, -0.3 * g["lean"])
    pose["head_world"] = [(Z, 0.0), (X, g["look"])]         # the head steady, looking where he's going
    for k, sd in body.side.items():
        s = sd["s"]
        ph = u + (0.0 if k == "l" else 0.5)                 # this arm comes forward with the other leg
        fwd = math.cos(math.tau * (ph - 0.5 - g["arm_lag"]))       # +1 at full forward
        sw = g["arm_bias"] - g["arm_swing"] * fwd
        turn(sd["sh"], Y, -s * g["shrug"] * max(0.0, fwd))
        turn(sd["arm"], Z, -s * g["arm_in"])
        turn(sd["arm"], Y, -s * g["arm_out"])
        turn(sd["arm"], X, sw)
        turn(sd["arm"] + ".001", sd["arm_n"],
             g["elbow"] + g["elbow_fwd"] * max(0.0, fwd) + g["elbow_back"] * max(0.0, -fwd))
        lag = math.cos(math.tau * (ph - 0.5 - g["arm_lag"] - 0.08))
        turn(sd["arm"] + ".002", sd["arm_n"], g["wrist"] * lag)
        pose["curl"][k] = g["curl"]; pose["thumb"][k] = g["curl"] * 0.6
    return pose


WALK = dict(frames=28, stride=1.30, duty=0.60, flat=0.11, heel_off=0.40, strike=16.0, off=-34.0,
            d0=-0.355, lift=0.045, lift_early=0.8,
            bob=0.016, bob_low=0.04, drop=-0.022, sway=0.022, sway_lag=0.02, pel_y=0.0,
            yaw=5.0, list=3.5, tilt=2.0, lean=3.0, lean_bob=0.6, twist=4.0, chest=1.0, look=4.0,
            arm_swing=19.0, arm_bias=-2.0, arm_lag=0.04, arm_in=4.0, arm_out=3.0, shrug=1.5,
            elbow=10.0, elbow_fwd=10.0, elbow_back=0.0, wrist=3.0, curl=0.0)
RUN = dict(frames=16, stride=2.40, duty=0.36, flat=0.06, heel_off=0.20, strike=9.0, off=-40.0,
           d0=-0.34, lift=0.20, lift_early=0.65,
           bob=0.030, bob_low=0.14, drop=-0.058, sway=0.012, sway_lag=0.10, pel_y=0.0,
           yaw=8.0, list=3.0, tilt=6.0, lean=15.0, lean_bob=1.5, twist=9.0, chest=2.0, look=0.0,
           arm_swing=45.0, arm_bias=-4.0, arm_lag=0.03, arm_in=12.0, arm_out=4.0, shrug=4.0,
           elbow=80.0, elbow_fwd=8.0, elbow_back=-15.0, wrist=4.0, curl=55.0)


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
            l_curl=0.0, r_curl=0.0, l_ik=0.0, r_ik=0.0, l_pole_w=0.0, r_pole_w=0.0,
            l_sw=0.0, r_sw=0.0, l_el=0.0, r_el=0.0, l_pro=0.0, r_pro=0.0,
            l_at=("fk",), r_at=("fk",))
# a hand's place: ("fk",) as the arm hangs; (bone, rest point, (finger dir, palm dir)): the rest-pose point and the
# way the hand faces, both carried by that bone; ("world", point, (finger dir, palm dir)): fixed in the rig's space


def hand_rot(body, k, fingers, palm):
    """The hand's turn from rest that points its fingers along `fingers` with its palm facing `palm`."""
    sd = body.side[k]
    M = body.rest[sd["arm"] + ".002"].to_3x3()
    y0, n0 = M.col[1].normalized(), sd["palm_n"]
    A = Matrix((n0, y0, n0.cross(y0))).transposed()
    y1 = fingers.normalized(); n1 = palm - y1 * palm.dot(y1); n1.normalize()
    Bm = Matrix((n1, y1, n1.cross(y1))).transposed()
    return Bm @ A.transposed()


def resolve(body, P, k, at):
    """A hand place (see REST) on this frame: (point, hand rotation from rest or None for the arm's own)."""
    sd = body.side[k]
    if at[0] == "fk":
        D = body.delta(P, sd["arm"] + ".002")
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
    pose = dict(turns={}, feet={}, arms={}, curl={}, thumb={})
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
        pose["curl"][k] = g(k + "_curl"); pose["thumb"][k] = g(k + "_curl") * 0.7
        turn(sd["sh"], Z, -sd["s"] * g(k + "_pro"))                 # the shoulder reaching forward
        turn(sd["sh"], Y, sd["s"] * 0.4 * g(k + "_pro"))              # and down
        for n, axis, name in ((sd["arm"], X, "_sw"), (sd["arm"] + ".001", sd["arm_n"], "_el")):
            turn(n, axis, g(k + name))
        w, pw = g(k + "_ik"), g(k + "_pole_w")
        if w <= 0 and not any(a[0] != "fk" for a in keys.each(k + "_at")):
            continue
        def target(P, k=k, w=w, pw=pw):
            pts = [resolve(body, P, k, at) for at in keys.each(k + "_at")]
            point = Vector([pchip(keys.frames, [p[0][i] for p in pts], f) for i in range(3)])
            q = [p[1].to_quaternion() for p in pts]
            for i in range(1, len(q)):
                if q[i].dot(q[i - 1]) < 0: q[i].negate()
            qv = Quaternion([pchip(keys.frames, [x[i] for x in q], f) for i in range(4)]).normalized()
            fk_pt, fk_R = resolve(body, P, k, ("fk",))
            return fk_pt.lerp(point, w), fk_R.to_quaternion().slerp(qv, w).to_matrix()
        sd_ = body.side[k]
        # the elbow: as it hangs at rest (back), swung out and back by pole_w for the reaching poses
        pole = (sd_["arm_q"] * (1 - pw) + Vector((sd_["s"] * 0.75, 0.55, 0.25)) * pw).normalized()
        pose["arms"][k] = dict(target=target, pole=pole)
    return pose


def knee_point(k, up=0.06, out=0.0):
    """A point just above and in front of the knee, on the thigh, in rest-pose terms (for a hand on the knee)."""
    s = 1 if k == "l" else -1
    return Vector((s * (0.104 + out), -0.058, 0.575 + up))


# a hand on each knee: fingers forward and down over it, palm down
BEND_HAND = {k: ("thigh_" + k, knee_point(k), (Vector((-s * 0.25, -0.75, -0.6)), Vector((0, 0.3, -1))))
             for k, s in (("l", 1), ("r", -1))}
BEND = Keys(REST, [
    (0, {}),
    (5, dict(pel=Vector((0, 0.005, -0.004)), tum_p=-2.0, head_p=-3.0)),    # a breath in, about to look
    (17, dict(pel=Vector((0, 0.13, -0.17)), hips_p=26.0, tum_p=48.0, chest_p=10.0, neck_p=-22.0, head_p=24.0,
              knee_out=8.0, l_ik=1.0, r_ik=1.0, l_pole_w=1.0, r_pole_w=1.0, l_at=BEND_HAND["l"], r_at=BEND_HAND["r"],
              l_curl=18.0, r_curl=18.0)),
    (22, dict(pel=Vector((0, 0.12, -0.18)), tum_p=50.0, head_p=25.0)),                         # settles
    (32, dict(pel=Vector((0, 0.10, -0.19)), tum_p=55.0, neck_p=-26.0, head_p=29.0, head_r=-16.0,   # leans in, his
              head_y=-6.0)),                                                                    # head on one side
    (40, dict(head_r=-17.0)),
    (48, dict(head_r=15.0, head_y=6.0, head_p=28.0)),                                              # and the other
    (55, dict(head_r=14.0)),
    (60, dict(pel=Vector((0, 0.12, -0.18)), tum_p=50.0, neck_p=-22.0, head_p=24.0, head_r=0.0, head_y=0.0)),
    (72, dict(REST)),
])

R_REACH = ("world", TAKE_GRIP, (Vector((0.05, -0.55, -0.83)), Vector((0.95, 0.1, -0.1))))
R_TUG = lambda dy, dz: ("world", TAKE_GRIP + Vector((0, dy, dz)),
                        (Vector((0.05, -0.45, -0.89)), Vector((0.95, 0.1, -0.1))))
HOLD_R = ("chest", Vector((-0.045, -0.215, 1.15)), (Vector((0.85, -0.2, 0.45)), Vector((0.2, 0.1, 1.0))))
HOLD_L = ("chest", Vector((0.075, -0.205, 1.12)), (Vector((-0.8, -0.35, 0.45)), Vector((-0.9, 0, 0.2))))
LEFT_KNEE = BEND_HAND["l"]
TAKE = Keys(REST, [
    (0, {}),
    (4, dict(pel=Vector((0, -0.005, -0.004)), tum_p=-3.0, head_p=6.0)),    # sees it, draws back a touch
    (13, dict(pel=Vector((-0.04, 0.07, -0.34)), hips_p=24.0, hips_y=-6.0, tum_p=64.0, tum_y=-10.0, tum_r=-6.0,
              chest_p=10.0, neck_p=-16.0, head_p=48.0, head_y=-8.0, knee_out=10.0,
              r_ik=1.0, r_pole_w=0.8, r_at=R_REACH, r_curl=-10.0, r_pro=24.0,
              l_ik=1.0, l_pole_w=1.0, l_at=LEFT_KNEE, l_curl=15.0)),                              # stoops and reaches
    (16, dict(r_curl=62.0)),                                                                      # grabs
    (21, dict(pel=Vector((-0.04, 0.09, -0.32)), tum_p=58.0, r_pro=14.0, r_at=R_TUG(0.07, 0.03))),  # tug
    (25, dict(pel=Vector((-0.04, 0.07, -0.34)), tum_p=61.0, r_pro=22.0, r_at=R_TUG(0.02, 0.0))),   # it pulls back
    (30, dict(pel=Vector((-0.04, 0.10, -0.31)), tum_p=57.0, r_pro=10.0, r_at=R_TUG(0.09, 0.04))),  # tug
    (33, dict(pel=Vector((-0.04, 0.08, -0.33)), tum_p=60.0, r_pro=18.0, r_at=R_TUG(0.04, 0.01))),
    (38, dict(pel=Vector((-0.02, 0.10, -0.08)), hips_p=6.0, hips_y=-2.0, tum_p=4.0, tum_y=-4.0, tum_r=0.0,
              chest_p=-6.0, neck_p=-2.0, head_p=-10.0, head_y=0.0, knee_out=4.0, l_toe=14.0, r_toe=14.0, r_pro=-6.0,
              r_at=("chest", Vector((-0.12, -0.12, 1.32)), (Vector((0.4, -0.2, 0.9)), Vector((0.9, 0.2, 0.2)))),
              l_ik=0.0, l_pole_w=0.0, l_at=("fk",), l_curl=0.0, l_sw=25.0, l_el=30.0)),   # free: he rocks back
    (44, dict(pel=Vector((0, 0.02, -0.02)), hips_p=0.0, hips_y=0.0, tum_p=2.0, tum_y=0.0, chest_p=-2.0, head_p=0.0,
              knee_out=0.0, l_toe=0.0, r_toe=0.0, r_pro=0.0, l_sw=-10.0, l_el=40.0)),   # catches his balance
    (52, dict(pel=Vector((0, 0.0, -0.01)), tum_p=4.0, neck_p=4.0, head_p=22.0,           # holds it to his chest,
              r_at=HOLD_R, r_pole_w=0.3, l_ik=1.0, l_pole_w=0.3, l_at=HOLD_L, l_curl=30.0,   # looking down at him
              l_sw=0.0, l_el=0.0)),
    (56, dict(head_y=13.0)),                                                                      # shakes his head
    (60, dict(head_y=-12.0)),
    (64, dict(head_y=9.0)),
    (68, dict(head_y=0.0, head_p=18.0, tum_p=1.0)),
    (72, dict(head_p=16.0)),
])

CLIPS = [("walk", WALK["frames"], True), ("run", RUN["frames"], True), ("bend", 72, False), ("take_away", 72, False)]


def pose_at(body, name, f, frames):
    if name == "walk": return cycle_pose(body, f / frames, WALK)
    if name == "run": return cycle_pose(body, f / frames, RUN)
    if name == "bend": return keyed_pose(body, BEND, f)
    return keyed_pose(body, TAKE, f)


def animate(rig, only=None, log=print):
    """Key the four actions on rig (replacing any of the same names), each parked in a muted NLA track so the glTF
    exporter finds them all; the rig is left at rest with no action."""
    body = Body(rig)
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
            P, short = body.solve(pose_at(body, name, f % frames if loop else f, frames))
            worst = max(worst, short)
            for n, (loc, q) in body.channels(P).items():
                if n in prev and q.dot(prev[n]) < 0:
                    q.negate()
                prev[n] = q
                pb = PB[n]
                pb.rotation_mode = "QUATERNION"
                pb.rotation_quaternion = q
                pb.keyframe_insert("rotation_quaternion", frame=f, group=n)
                if not body.B[n].use_connect:
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
    return body


# The .glb: as the build's export (+Y up, his 62 deforming bones, skinned), now with the four actions, sampled on
# every frame.
EXPORT = dict(export_format="GLB", export_yup=True, use_selection=True, export_apply=False, export_cameras=False,
              export_lights=False, export_materials="EXPORT", export_skins=True, export_def_bones=True,
              export_morph=False, export_animations=True, export_animation_mode="ACTIONS",
              export_force_sampling=True, export_frame_step=1, export_optimize_animation_size=False,
              export_anim_single_armature=True, export_reset_pose_bones=True, export_current_frame=False)


def export_glb(rig, path):
    parts = [o for o in rig.users_collection[0].objects if o.type == "MESH"]
    for o in bpy.context.view_layer.objects:
        o.select_set(o is rig or o in parts)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=path, **EXPORT)


if __name__ == "__main__":
    REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    OUT = os.environ.get("HUMAN_CAMPER_OUT") or os.path.join(REPO, "assets", "characters", "human_camper")
    bpy.ops.wm.open_mainfile(filepath=OUT + ".blend", load_ui=False, use_scripts=False)
    rig = bpy.data.objects["HumanCamper_rig"]
    src = open(__file__, encoding="utf-8").read()
    t = bpy.data.texts.get("hcamper_animate") or bpy.data.texts.new("hcamper_animate")
    t.clear(); t.write(src)
    animate(rig)
    bpy.ops.wm.save_as_mainfile(filepath=OUT + ".blend", compress=True)
    export_glb(rig, OUT + ".glb")
    print("SAVED", OUT + ".blend", "| EXPORTED", OUT + ".glb", os.path.getsize(OUT + ".glb"), "bytes")
