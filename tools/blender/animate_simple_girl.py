# The simple girl's animations (TiZeta's "Simple girl", Blend Swap 66413, CC-BY 3.0; made game-ready by
# prepare_simple_girl.py): walk, run, bend and take_away, as the two men have. Asked for on 23 Oct 2026: "added one
# more its a girl now do the same for her model".
#
# She has the low-poly man's rig (TiZeta's 20 bones, named in Italian, in the same places), so like his
# (animate_lowpoly_man.py) this uses tools/blender/animate_chubby.py as it is, its pose solver and its gaits, and only
# gives it her numbers: her steps scaled to her legs, a little more sway in her hips, her arms close to her sides, and
# for bend and take away the low-poly man's poses, fitted to her size. Claude Code wrote it; nothing here is TiZeta's
# walk ("cammina", still in design/downloads/simple_girl/simple_girl2.6.blend). Every action is keyed on every frame
# at 25 fps:
#   walk       28 frames, looping: an easy stroll, 0.58 m steps, 1.04 m/s at 1x
#   run        16 frames, looping: the chase, leaning in with her arms pumping, 1.07 m steps, 3.33 m/s at 1x
#   bend       72 frames: hands onto her knees, peers ahead and down, tilts her head one way and the other, stands up
#   take_away  72 frames: stoops, grabs with her right hand at TAKE_GRIP (the raccoon's mouth), two tugs, yanks it free
#              and rocks back on her heels, straightens up holding it at her chest in both hands, shakes her head;
#              she ends there, holding it
#   dance      64 frames, looping (added 23 Oct 2026 for the campsite): the chubby man's step-touch with her own
#              arms (DANCE below)
#   scared, cower  (added 23 Oct 2026, the campers' reactions) as animate_chubby.py has them: she's always scared
# All in place, facing -Y (+Z in Godot): the game moves her and plays walk and run at speed / their speed above.
#
# prepare_simple_girl.py ends by running this file. On its own, it re-keys the four actions on the saved .blend, saves
# it and exports the .glb (SIMPLE_GIRL_OUT, a path without an extension, works on a test copy instead):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --disable-autoexec \
#       --python-exit-code 1 --python tools/blender/animate_simple_girl.py

import bpy, os
from mathutils import Vector

_CHUBBY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "animate_chubby.py")
L = {"__name__": "animate_chubby_lib", "__file__": _CHUBBY}
exec(compile(open(_CHUBBY, encoding="utf-8").read(), _CHUBBY, "exec"), L)
Keys, REST = L["Keys"], L["REST"]

TAKE_GRIP = Vector((-0.10, -0.35, 0.30))    # where she takes the item: the raccoon's mouth (rig space, metres)

# her legs (hip to ankle, 0.79 m) are 0.935 of the low-poly man's: his steps and bounce at her size, with a little more
# turn and dip in her hips and her arms in closer
WALK = dict(frames=28, stride=1.16, duty=0.60, flat=0.11, heel_off=0.40, strike=15.0, off=-32.0,
            d0=-0.316, lift=0.040, lift_early=0.8,
            bob=0.014, bob_low=0.04, drop=-0.020, sway=0.022, sway_lag=0.02,
            yaw=6.0, list=4.5, roll=0.5, tilt=2.0, lean=2.0, lean_bob=0.6, twist=4.0, chest=1.0, look=4.0,
            arm_swing=17.0, arm_bias=-2.0, arm_lag=0.04, arm_in=5.0, arm_out=2.0,
            elbow=14.0, elbow_fwd=10.0, elbow_back=0.0, wrist=4.0)
RUN = dict(frames=16, stride=2.13, duty=0.36, flat=0.06, heel_off=0.20, strike=9.0, off=-40.0,
           d0=-0.302, lift=0.178, lift_early=0.65,
           bob=0.026, bob_low=0.14, drop=-0.051, sway=0.010, sway_lag=0.10,
           yaw=8.0, list=3.0, roll=0.5, tilt=6.0, lean=14.0, lean_bob=1.5, twist=9.0, chest=2.0, look=0.0,
           arm_swing=44.0, arm_bias=-4.0, arm_lag=0.03, arm_in=14.0, arm_out=3.0,
           elbow=82.0, elbow_fwd=8.0, elbow_back=-15.0, wrist=4.0)
# her dance (23 Oct 2026, the campsite): the step-touch at her size with more hip, both hands up over her head,
# swaying from side to side over the four beats
_arm = L["_arm"]
DANCE = dict(L["DANCE"], step=0.15, bounce=0.03, pop=8.0, yaw=9.0,
             arms={"l": _arm(sw=-15.0, out=145.0, out_amp=14.0, el=35.0, el_amp=8.0, period=4.0, phase=0.0),
                   "r": _arm(sw=-15.0, out=145.0, out_amp=14.0, el=35.0, el_amp=8.0, period=4.0, phase=2.0)})

# Her reactions (scared and the rest, 23 Oct 2026): her arms are long enough to put her hands up without
# turning them out, as the chubby man's are
REACT = dict(L["REACT"], hands_out=18.0, hands_twist=0.0)


def clips(body):
    """bend and take_away: the low-poly man's poses at her size, with the hand places measured on her (the front of her
    knees and of her chest). Like his, her arms are short for her legs, so she leans well over and her hands go just
    above her knees."""
    knee = {}
    for k, sd in body.side.items():
        x = body.tail(sd["thigh"]).x
        z = body.tail(sd["thigh"]).z + 0.11
        knee[k] = (sd["thigh"], Vector((x, body.front(x, z) - 0.012, z)),
                   (Vector((-sd["s"] * 0.25, -0.75, -0.6)), Vector((0, 0.3, -1))))       # fingers over the knee, palm down
    chest = body.front(0.0, 1.07)                          # the front of her chest, where she holds the item
    hold_r = ("schiena", Vector((-0.042, chest - 0.10, 1.07)), (Vector((0.85, -0.2, 0.45)), Vector((0.2, 0.1, 1.0))))
    hold_l = ("schiena", Vector((0.070, chest - 0.09, 1.04)), (Vector((-0.8, -0.35, 0.45)), Vector((-0.9, 0, 0.2))))
    up_r = ("schiena", Vector((-0.11, chest - 0.02, 1.23)), (Vector((0.4, -0.2, 0.9)), Vector((0.9, 0.2, 0.2))))
    reach = ("world", TAKE_GRIP, (Vector((0.05, -0.55, -0.83)), Vector((0.95, 0.1, -0.1))))
    tug = lambda dy, dz: ("world", TAKE_GRIP + Vector((0, dy, dz)), (Vector((0.05, -0.45, -0.89)), Vector((0.95, 0.1, -0.1))))
    bend = Keys(REST, [
        (0, {}),
        (5, dict(pel=Vector((0, 0.005, -0.004)), tum_p=-2.0, head_p=-3.0)),          # a breath in, about to look
        (17, dict(pel=Vector((0, 0.12, -0.16)), hips_p=26.0, tum_p=55.0, chest_p=10.0, neck_p=-22.0, head_p=24.0,
                  knee_out=6.0, l_ik=1.0, r_ik=1.0, l_pole_w=1.0, r_pole_w=1.0, l_at=knee["l"], r_at=knee["r"])),
        (22, dict(pel=Vector((0, 0.11, -0.17)), tum_p=57.0, head_p=25.0)),               # settles
        (32, dict(pel=Vector((0, 0.09, -0.18)), tum_p=62.0, neck_p=-26.0, head_p=29.0, head_r=-16.0,   # leans in, her
                  head_y=-6.0)),                                                          # head on one side
        (40, dict(head_r=-17.0)),
        (48, dict(head_r=15.0, head_y=6.0, head_p=28.0)),                                  # and the other
        (55, dict(head_r=14.0)),
        (60, dict(pel=Vector((0, 0.11, -0.17)), tum_p=57.0, neck_p=-22.0, head_p=24.0, head_r=0.0, head_y=0.0)),
        (72, dict(REST)),
    ])
    take = Keys(REST, [
        (0, {}),
        (4, dict(pel=Vector((0, -0.005, -0.004)), tum_p=-3.0, head_p=6.0)),         # sees it, draws back a touch
        (13, dict(pel=Vector((-0.04, 0.07, -0.36)), hips_p=24.0, hips_y=-6.0, tum_p=70.0, tum_y=-10.0, tum_r=-6.0,
                  chest_p=10.0, neck_p=-16.0, head_p=48.0, head_y=-8.0, knee_out=10.0,
                  r_ik=1.0, r_pole_w=0.8, r_at=reach, l_ik=1.0, l_pole_w=1.0, l_at=knee["l"])),     # stoops and reaches
        (21, dict(pel=Vector((-0.04, 0.09, -0.34)), tum_p=64.0, r_at=tug(0.07, 0.03))),            # tug
        (25, dict(pel=Vector((-0.04, 0.07, -0.36)), tum_p=67.0, r_at=tug(0.02, 0.0))),             # it pulls back
        (30, dict(pel=Vector((-0.04, 0.10, -0.33)), tum_p=63.0, r_at=tug(0.09, 0.04))),            # tug
        (33, dict(pel=Vector((-0.04, 0.08, -0.35)), tum_p=66.0, r_at=tug(0.04, 0.01))),
        (38, dict(pel=Vector((-0.02, 0.09, -0.07)), hips_p=6.0, hips_y=-2.0, tum_p=4.0, tum_y=-4.0, tum_r=0.0,
                  chest_p=-6.0, neck_p=-2.0, head_p=-10.0, head_y=0.0, knee_out=4.0, l_toe=14.0, r_toe=14.0,
                  r_at=up_r, l_ik=0.0, l_pole_w=0.0, l_at=("fk",), l_sw=25.0, l_el=30.0)),          # free: she rocks back
        (44, dict(pel=Vector((0, 0.02, -0.02)), hips_p=0.0, hips_y=0.0, tum_p=2.0, tum_y=0.0, chest_p=-2.0, head_p=0.0,
                  knee_out=0.0, l_toe=0.0, r_toe=0.0, l_sw=-10.0, l_el=40.0)),                     # catches her balance
        (52, dict(pel=Vector((0, 0.0, -0.01)), tum_p=4.0, neck_p=4.0, head_p=22.0,                # holds it to her chest,
                  r_at=hold_r, r_pole_w=0.3, l_ik=1.0, l_pole_w=0.3, l_at=hold_l,                   # looking down at him
                  l_sw=0.0, l_el=0.0)),
        (56, dict(head_y=13.0)),                                                                  # shakes her head
        (60, dict(head_y=-12.0)),
        (64, dict(head_y=9.0)),
        (68, dict(head_y=0.0, head_p=18.0, tum_p=1.0)),
        (72, dict(head_p=16.0)),
    ])
    return bend, take


def animate(rig, body, only=None, log=print):
    """animate_chubby.animate with her numbers."""
    L["WALK"], L["RUN"], L["clips"], L["DANCE"] = WALK, RUN, clips, DANCE
    L["REACT"] = REACT
    L["CLIPS"] = [("walk", WALK["frames"], True), ("run", RUN["frames"], True), ("bend", 72, False), ("take_away", 72, False),
                  ("dance", DANCE["frames"], True)] + [("scared", 30, False), ("cower", 50, True)]
    return L["animate"](rig, body, only=only, log=log)


export_glb = L["export_glb"]


if __name__ == "__main__":
    REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    OUT = os.environ.get("SIMPLE_GIRL_OUT") or os.path.join(REPO, "assets", "characters", "simple_girl")
    bpy.ops.wm.open_mainfile(filepath=OUT + ".blend", load_ui=False, use_scripts=False)
    rig, body = bpy.data.objects["SimpleGirl_rig"], bpy.data.objects["SimpleGirl"]
    src = open(__file__, encoding="utf-8").read()
    t = bpy.data.texts.get("simple_girl_animate") or bpy.data.texts.new("simple_girl_animate")
    t.clear(); t.write(src)
    animate(rig, body)
    bpy.ops.wm.save_as_mainfile(filepath=OUT + ".blend", compress=True)
    export_glb(rig, OUT + ".glb")
    print("SAVED", OUT + ".blend", "| EXPORTED", OUT + ".glb", os.path.getsize(OUT + ".glb"), "bytes")
