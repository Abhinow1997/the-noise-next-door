# Keyframes the raccoon's looping actions on RaccoonRig: idle, walk, run, sneak, bored,
# sleep, climb. Each is a function of the loop phase u in [0, 1), sampled every frame, so
# the last frame matches the first. Run inside Blender: exec(open(path).read()).
# World axes: +X his left, -Y forward (he faces -Y), +Z up. In place: the game moves him.
import bpy, math
from mathutils import Matrix, Quaternion, Vector

rig = bpy.data.objects["RaccoonRig"]
PB = rig.pose.bones
TAU = math.tau
ONLY = globals().get("ONLY")          # optional set of action names to (re)build

# Paw rest points (the IK targets' heads).
PAW = {
    "hand_ik.L": Vector((0.15, -0.205, 0.05)), "hand_ik.R": Vector((-0.15, -0.205, 0.05)),
    "foot_ik.L": Vector((0.19, 0.33, 0.055)), "foot_ik.R": Vector((-0.19, 0.33, 0.055)),
}
FK = ["pelvis", "spine", "chest", "neck", "head", "tail1", "tail2", "tail3", "tail4",
      "ear.L", "ear.R", "eye.L", "eye.R"]


def wrot(bone, *turns):
    """Rotation of `bone` as a sequence of (world axis, angle) turns, in its local frame."""
    M = PB[bone].bone.matrix_local.to_3x3()
    R = Matrix.Identity(3)
    for axis, ang in turns:
        R = Matrix.Rotation(ang, 3, axis) @ R
    return (M.inverted() @ R @ M).to_quaternion()


def wloc(bone, offset):
    """A world-space offset as the bone's local location."""
    M = PB[bone].bone.matrix_local.to_3x3()
    return M.inverted() @ Vector(offset)


X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))


def ease(t):
    t = min(max(t, 0.0), 1.0)
    return t * t * (3 - 2 * t)


def gait(p, stride, lift, duty):
    """Paw offset (dy, dz) for leg phase p: on the ground for `duty` of the cycle moving
    back, then a lifted swing forward."""
    p %= 1.0
    if p < duty:
        return -stride / 2 + stride * p / duty, 0.0
    s = (p - duty) / (1 - duty)
    return stride / 2 - stride * ease(s), lift * math.sin(math.pi * s)


def mirror_side(name):
    return name.replace(".L", ".R") if name.endswith(".L") else name.replace(".R", ".L")


class Pose:
    """One frame's pose: rotations (world turns) for FK bones, offsets for paws/pelvis."""

    def __init__(self):
        self.rot = {}
        self.paw = {k: Vector() for k in PAW}
        self.pelvis = Vector()
        self.scale = {}
        # Paws placed relative to a bone after the body has moved: {ik: (bone, offset)}.
        self.rel = {}
        # Paw pitch (radians, positive = toes down), carried to the paws by their controls.
        self.paw_pitch = {k: 0.0 for k in PAW}

    def turn(self, bone, axis, ang):
        self.rot.setdefault(bone, []).append((axis, ang))


def apply(pose, frame):
    for b in FK:
        pb = PB[b]
        pb.rotation_quaternion = wrot(b, *pose.rot.get(b, []))
        pb.keyframe_insert("rotation_quaternion", frame=frame)
        if b.startswith("eye") or b == "spine" or b == "chest":
            pb.scale = pose.scale.get(b, (1, 1, 1))
            pb.keyframe_insert("scale", frame=frame)
    PB["pelvis"].location = wloc("pelvis", pose.pelvis)
    PB["pelvis"].keyframe_insert("location", frame=frame)
    if pose.rel:
        for k in PAW:
            PB[k].location = (0, 0, 0)
        bpy.context.view_layer.update()
        for k, (bone, off) in pose.rel.items():
            pose.paw[k] = PB[bone].matrix.translation + Vector(off) - PAW[k]
    for k, rest in PAW.items():
        PB[k].location = wloc(k, pose.paw[k])
        PB[k].keyframe_insert("location", frame=frame)
        PB[k].rotation_quaternion = wrot(k, (X, pose.paw_pitch[k]))
        PB[k].keyframe_insert("rotation_quaternion", frame=frame)


def make(name, frames, fn):
    if ONLY and name not in ONLY:
        return
    act = bpy.data.actions.get(name)
    if act:
        bpy.data.actions.remove(act)
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    rig.animation_data_create()
    rig.animation_data.action = act
    for b in PB:
        b.location = (0, 0, 0)
        b.rotation_quaternion = Quaternion()
        b.scale = (1, 1, 1)
    for f in range(frames + 1):
        pose = Pose()
        fn(f / frames, pose)
        apply(pose, f)
    act.use_frame_range = True
    act.frame_start, act.frame_end = 0, frames
    act.use_cyclic = True
    print("action", name, frames, "frames")


# --- Shared bits ----------------------------------------------------------------------

def tail_curve(pose, lift, side, curl=0.0, wave=0.0, u=0.0, speed=1.0):
    """Tail: `lift` raises it (radians at the root, spread down the chain), `side` swings
    it (positive to his left), `curl` bends the end segments further, `wave` ripples."""
    for i, b in enumerate(["tail1", "tail2", "tail3", "tail4"]):
        k = [0.45, 0.25, 0.18, 0.12][i]
        ripple = wave * math.sin(TAU * speed * u - i * 0.9)
        pose.turn(b, X, lift * k + curl * i / 3)
        pose.turn(b, Z, -(side * k + ripple * 0.35))


def breathe(pose, u, cycles, amount=0.02):
    s = 1 + amount * math.sin(TAU * cycles * u)
    pose.scale["chest"] = (s, 1, s)
    pose.scale["spine"] = (s, 1, s)


def eyes(pose, open_amount):
    for e in ("eye.L", "eye.R"):
        pose.scale[e] = (1, max(open_amount, 0.08), 1)


# --- Idle: standing, breathing, glancing about, tail curled up behind ---------------------

def idle(u, pose):
    breathe(pose, u, 2)
    look = math.sin(TAU * u) * 0.32 + math.sin(TAU * 2 * u + 1.0) * 0.08
    pose.turn("neck", Z, look * 0.4)
    pose.turn("head", Z, look * 0.6)
    pose.turn("head", Y, math.sin(TAU * u + 0.5) * 0.08)       # a curious head tilt
    pose.turn("head", X, -0.05 + 0.04 * math.sin(TAU * 2 * u))
    pose.pelvis = Vector((0, 0, 0.004 * math.sin(TAU * 2 * u)))
    tail_curve(pose, 1.25, 0.15 * math.sin(TAU * u), curl=0.35, wave=0.25, u=u, speed=2)
    # An ear flick partway through.
    f = max(0.0, 1 - abs(u - 0.62) / 0.03)
    pose.turn("ear.L", X, 0.5 * f)
    blink = max(0.0, 1 - abs(u - 0.3) / 0.02)
    eyes(pose, 1 - blink)


# --- Walk: a trot ------------------------------------------------------------------------
# Diagonal pairs: front-left + hind-right down for u in [0, 0.6), front-right + hind-left
# down for u in [0.5, 1.1); all four feet are down briefly at the handovers (u ~ 0.05 and
# ~ 0.55). The body is highest at the handovers and lowest mid-support (u ~ 0.3, ~ 0.8);
# the hip drops on the side whose hind leg is swinging and the shoulders tip the other
# way; the head stays level; the tail sways with the hips, a beat behind.
WALK = dict(stride=0.26, duty=0.60, lift_h=0.05, lift_f=0.065,
            phase={"hand_ik.L": 0.0, "foot_ik.R": 0.0, "hand_ik.R": 0.5, "foot_ik.L": 0.5})


def walk_leg(p, front):
    """(dy, dz, pitch) for one leg at leg phase p: planted and moving back, rolling onto
    the toes to push off; then a swing that lifts and tucks the paw and reaches forward
    to land flat."""
    st, duty = WALK["stride"], WALK["duty"]
    p %= 1.0
    if p < duty:
        t = p / duty
        roll = max(0.0, (t - 0.75) / 0.25)
        return -st / 2 + st * t, 0.008 * roll, 0.35 * roll
    s = (p - duty) / (1 - duty)
    reach = ease(min(s * 1.1, 1.0)) if front else ease(s)
    lift = (WALK["lift_f"] if front else WALK["lift_h"]) * math.sin(math.pi * s)
    tuck = (0.7 if front else 0.4) * math.sin(math.pi * min(s * 1.4, 1.0))
    settle = 1 if s < 0.75 else (1 - s) / 0.25        # flat again by touchdown
    return st / 2 - st * reach, lift, 0.35 * (1 - s) * (s < 0.3) + tuck * settle


def walk(u, pose):
    for k, p in WALK["phase"].items():
        dy, dz, pitch = walk_leg(u + p, k.startswith("hand"))
        pose.paw[k] = Vector((0, dy, dz))
        pose.paw_pitch[k] = pitch
    rise = math.cos(2 * TAU * (u - 0.05))             # highs at the handovers
    hip = math.cos(TAU * (u - 0.30))                  # +1 left hip down (hind-left swinging)
    pose.pelvis = Vector((-0.006 * hip, 0, -0.008 + 0.012 * rise))   # weight onto the planted hind leg
    pose.turn("pelvis", Y, 0.05 * hip)                # hip drop
    pose.turn("pelvis", Z, 0.025 * hip)               # hips swing a little with the stride
    pose.turn("spine", Y, -0.045 * hip)               # shoulders tip the other way
    pose.turn("chest", Y, -0.045 * hip)
    pose.turn("chest", Z, -0.035 * hip)               # shoulders swing against the hips
    pose.turn("neck", Y, 0.04 * hip)                  # head stays level ...
    pose.turn("neck", Z, 0.02 * hip)
    pose.turn("neck", X, -0.025 * rise)               # ... and steady against the bounce
    pose.turn("head", X, 0.02 * math.cos(2 * TAU * (u - 0.15)))   # a small nod, just behind
    sway = math.cos(TAU * (u - 0.40))                 # tail follows the hips a beat late
    tail_curve(pose, 0.38 + 0.05 * rise, 0.16 * sway, wave=0.10, u=u)
    breathe(pose, u, 2, 0.01)


# --- Run: a lope ------------------------------------------------------------------------
# Hind feet land together at u = 0 (body bunched, back arched, paws close under him),
# push off by u ~ 0.45; the front feet reach out and land at u ~ 0.5 (body stretched
# flat), push off by u ~ 0.95. The body rises in the two moments with no foot down
# (u ~ 0.47 and ~ 0.97) and dips while a pair is planted; it rocks nose-up as the front
# feet push off and nose-down as they land. Head and tail counter the rocking.
RUN = dict(stride=0.46, duty=0.40, lift_h=0.09, lift_f=0.13,
           phase={"foot_ik.L": 0.0, "foot_ik.R": 0.06, "hand_ik.L": 0.50, "hand_ik.R": 0.56})


def run_leg(p, front):
    """(dy, dz, pitch) for one leg at leg phase p: planted and moving back, rolling onto
    the toes as it pushes off; then a swing that tucks the paw and (front legs) reaches
    out early."""
    st, duty = RUN["stride"], RUN["duty"]
    p %= 1.0
    if p < duty:
        t = p / duty
        roll = max(0.0, (t - 0.7) / 0.3)                 # heel lifts at the end of the push
        return -st / 2 + st * t, 0.012 * roll, 0.5 * roll
    s = (p - duty) / (1 - duty)
    reach = 1 - (1 - s) ** 2.2 if front else ease(s)  # front paws shoot forward early
    lift = (RUN["lift_f"] if front else RUN["lift_h"]) * math.sin(math.pi * min(s * 1.15, 1.0))
    tuck = (1.2 if front else 0.7) * math.sin(math.pi * min(s * 1.3, 1.0))
    return st / 2 - st * reach, lift, 0.5 * (1 - s) + tuck * (1 if s < 0.8 else (1 - s) / 0.2)


def run(u, pose):
    for k, p in RUN["phase"].items():
        dy, dz, pitch = run_leg(u + p, k.startswith("hand"))
        pose.paw[k] = Vector((0, dy, dz))
        pose.paw_pitch[k] = pitch
    # Timed off the foot contacts: hind feet down u in [0.94, 0.40), front feet down
    # u in [0.44, 0.90); no foot down around u = 0.42 and u = 0.92.
    gather = math.cos(TAU * (u - 0.96))                # +1 bunched as the hind feet land
    rise = math.cos(2 * TAU * (u - 0.42))              # highs with no foot down, lows mid-support
    nose_up = math.cos(TAU * (u - 0.92))               # +1 just after the front feet push off
    pose.pelvis = Vector((0, -0.02 * gather, -0.035 + 0.03 * rise))
    # Arched when bunched: the hip segment tips up at the front, the back and shoulders
    # tip down; stretched flat (slightly hollow) when extended. Plus the whole-body rock.
    pose.turn("pelvis", X, -0.12 * gather - 0.07 * nose_up)
    pose.turn("spine", X, 0.11 * gather)
    pose.turn("chest", X, 0.07 * gather)
    # The neck undoes the arch and the rock, so the head stays steady and low.
    pose.turn("neck", X, 0.12 - 0.06 * gather + 0.05 * nose_up)
    pose.turn("head", X, -0.14 + 0.02 * nose_up)
    for e in ("ear.L", "ear.R"):
        pose.turn(e, X, -0.4)                          # ears back
    lag = math.cos(TAU * (u - 0.06))                   # the tail follows a beat behind
    tail_curve(pose, 0.12 + 0.16 * lag, 0.0, curl=-0.05 * lag, wave=0.0, u=u)
    breathe(pose, u, 2, 0.02)


# --- Sneak: a stalk, one paw at a time ----------------------------------------------------
# Lateral sequence, three paws always down. Swings: hind-left u in [0.78, 1.0), front-left
# [0.03, 0.25), hind-right [0.28, 0.50), front-right [0.53, 0.75). Each step lifts and
# curls the paw, holds it, then reaches out and sets it down softly, toes first. The body
# stays low and shifts its weight away from the lifting paw, settling a little as each
# paw lands; the head holds still on its target; ears pricked; the tail low and straight
# with only the tip twitching.
SNEAK = dict(stride=0.16, duty=0.78, lift_h=0.05, lift_f=0.075, crouch=-0.085,
             phase={"foot_ik.L": 0.0, "hand_ik.L": 0.75, "foot_ik.R": 0.5, "hand_ik.R": 0.25})


def stalk_leg(p, front):
    """(dy, dz, pitch, swing) at leg phase p; swing is 0..1 through the step, else None."""
    st, duty = SNEAK["stride"], SNEAK["duty"]
    p %= 1.0
    if p < duty:
        return -st / 2 + st * p / duty, 0.0, 0.0, None
    s = (p - duty) / (1 - duty)
    lift_h = SNEAK["lift_f"] if front else SNEAK["lift_h"]
    up = ease(s / 0.3) if s < 0.6 else ease((1 - s) / 0.4)      # lift, hold, set down
    fwd = 0.15 * ease(s / 0.55) + 0.85 * ease((s - 0.45) / 0.55)  # creeps, then reaches
    curl = (1.0 if front else 0.5) * (ease(s / 0.3) if s < 0.55 else ease((0.85 - s) / 0.3))
    toes_first = 0.18 * math.sin(math.pi * max(0.0, (s - 0.8) / 0.2))
    return st / 2 - st * fwd, lift_h * up, curl + toes_first, s


def sneak(u, pose):
    shift = Vector()
    hip = shoulder = settle = 0.0
    for k, p in SNEAK["phase"].items():
        front = k.startswith("hand")
        side = 1.0 if k.endswith(".L") else -1.0
        dy, dz, pitch, s = stalk_leg(u + p, front)
        pose.paw[k] = Vector((0, dy, dz))
        pose.paw_pitch[k] = pitch
        if s is not None:
            w = math.sin(math.pi * s)                  # weight comes off this paw
            shift.x -= side * 0.010 * w
            shift.y += (0.006 if front else -0.006) * w
            if front:
                shoulder += side * w
            else:
                hip += side * w
        # A small settle just after the paw lands (the start of its stance).
        q = (u + p) % 1.0
        if q < 0.12:
            settle += math.sin(math.pi * q / 0.12)
    pose.pelvis = Vector((shift.x, shift.y, SNEAK["crouch"] - 0.004 * settle))
    pose.turn("pelvis", Y, 0.035 * hip)               # hip drops as a hind paw lifts
    pose.turn("chest", Y, -0.035 * hip - 0.04 * shoulder)   # shoulder rises with a front paw
    pose.turn("spine", Z, 0.02 * (hip - shoulder))
    # Head low and locked on: the neck undoes the body's roll and sway.
    pose.turn("neck", X, 0.28)
    pose.turn("neck", Y, 0.04 * shoulder)
    pose.turn("neck", Z, -0.02 * (hip - shoulder))
    pose.turn("head", X, -0.22)
    for e in ("ear.L", "ear.R"):
        pose.turn(e, X, 0.12)                          # pricked forward, alert
    # Tail low and straight; only the tip twitches.
    twitch = math.sin(TAU * 3 * u) * max(0.0, math.sin(TAU * u)) ** 2
    for i, b in enumerate(["tail1", "tail2", "tail3", "tail4"]):
        pose.turn(b, X, [-0.18, 0.04, 0.03, 0.02][i])
        pose.turn(b, Z, [0.0, 0.0, 0.08, 0.16][i] * twitch)
    eyes(pose, 0.7)
    breathe(pose, u, 2, 0.008)


# --- Bored: sitting up, scratching behind an ear, droopy eyes ------------------------------

def bored(u, pose):
    sit = 1.05
    pose.turn("pelvis", X, -sit)                     # rear down, chest up
    pose.pelvis = Vector((0, -0.05, -0.145))
    pose.turn("neck", X, 0.55)
    pose.turn("head", X, 0.15)
    pose.turn("head", Y, 0.25)                       # a lazy tilt
    pose.turn("head", Z, -0.25)
    breathe(pose, u, 1.5, 0.025)
    eyes(pose, 0.5)
    # Hind feet out in front, soles forward.
    pose.paw["foot_ik.L"] = Vector((0.03, -0.30, -0.01))
    pose.paw["foot_ik.R"] = Vector((-0.03, -0.30, -0.01))
    # Left paw up behind the ear, scratching; right paw resting on the belly.
    scratch = math.sin(TAU * 6 * u) * (0.5 + 0.5 * math.cos(TAU * u))
    pose.rel["hand_ik.L"] = ("ear.L", (0.03, 0.05 + 0.015 * scratch, -0.03 + 0.02 * scratch))
    pose.rel["hand_ik.R"] = ("spine", (0.07, -0.17, 0.0))
    pose.turn("ear.L", X, -0.2 - 0.1 * scratch)
    tail_curve(pose, 1.0, -0.6, wave=0.05, u=u)        # lying on the ground to one side


# --- Sleep: curled in a ball, head on the paws, tail wrapped round the front ---------------

P_SLEEP = globals().get("P_SLEEP", {})


def sleep(u, pose):
    curl = P_SLEEP.get("curl", 0.66)
    for b, k in (("pelvis", 0.8), ("spine", 1.0), ("chest", 1.0), ("neck", 0.8), ("head", 0.6)):
        pose.turn(b, Z, curl * k)
    pose.pelvis = Vector((0, 0, P_SLEEP.get("drop", -0.10)))
    pose.turn("neck", X, 0.25)
    pose.turn("head", X, P_SLEEP.get("chin", 0.18))  # chin resting on the tail
    pose.turn("head", Y, 0.2)
    for e in ("ear.L", "ear.R"):
        pose.turn(e, X, -0.3)
    # Legs folded under.
    pose.rel["hand_ik.L"] = ("head", (0.06, -0.12, -0.16))
    pose.rel["hand_ik.R"] = ("head", (-0.02, -0.16, -0.17))
    pose.paw["foot_ik.L"] = Vector((-0.02, -0.12, 0.10))
    pose.paw["foot_ik.R"] = Vector((0.10, -0.14, 0.10))
    for i, b in enumerate(["tail1", "tail2", "tail3", "tail4"]):
        pose.turn(b, X, P_SLEEP.get("tail_down", -0.36) if i == 0 else 0.03)
        pose.turn(b, Z, -P_SLEEP.get("tail", [0.75, 0.55, 0.5, 0.5])[i])   # round the front, under his chin
    breathe(pose, u, 1, 0.035)
    eyes(pose, 0.0)


# --- Climb: belly to the trunk (the game turns him), paws spread to grip -------------------

def climb(u, pose):
    phase = {"hand_ik.L": 0.0, "foot_ik.R": 0.0, "hand_ik.R": 0.5, "foot_ik.L": 0.5}
    for k, p in phase.items():
        dy, dz = gait(u + p, 0.22, 0.05, 0.55)
        side = 0.07 if k.endswith(".L") else -0.07
        pose.paw[k] = Vector((side, dy, dz - 0.045))     # round the trunk's curve
    pose.pelvis = Vector((0, 0, -0.06 + 0.01 * math.cos(TAU * 2 * u)))
    pose.turn("pelvis", Y, 0.05 * math.sin(TAU * u))
    pose.turn("neck", X, -0.15)                        # looking up the trunk
    pose.turn("head", X, -0.1)
    tail_curve(pose, -0.35, 0.06 * math.sin(TAU * u), wave=0.06, u=u)


make("idle", 96, idle)
make("walk", 24, walk)
make("run", 16, run)
make("sneak", 48, sneak)
make("bored", 96, bored)
make("sleep", 96, sleep)
make("climb", 24, climb)

# Leave the rig on its rest pose with no action, and park each action in the NLA so the
# exporter can find them all.
ad = rig.animation_data
ad.action = None
for t in list(ad.nla_tracks):
    ad.nla_tracks.remove(t)
for name in ("idle", "walk", "run", "sneak", "bored", "sleep", "climb"):
    act = bpy.data.actions.get(name)
    if act:
        tr = ad.nla_tracks.new()
        tr.name = name
        tr.strips.new(name, 0, act)
        tr.mute = True
for b in PB:
    b.location = (0, 0, 0)
    b.rotation_quaternion = Quaternion()
    b.scale = (1, 1, 1)
