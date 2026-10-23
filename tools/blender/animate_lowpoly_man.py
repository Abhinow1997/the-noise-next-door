# The low-poly man's animations (TiZeta's "Lowpoly man", Blend Swap 66412, CC-BY 3.0; made game-ready by
# prepare_lowpoly_man.py): walk, run, bend and take_away, as the chubby man has. Asked for on 23 Oct 2026: "ok lets
# create the same like we have done for the chubby guy for this guy as well and add him in the assets and charaters".
#
# He has the chubby man's rig (TiZeta's 20 bones, named in Italian), so this uses tools/blender/animate_chubby.py as it
# is, its pose solver and its gaits, and only gives it a slim man's numbers: his steps scaled to his legs, his arms
# close to his sides, and for bend and take away the poses the rigged camper (animate_human_camper.py) had, bending at
# the waist rather than round a belly. Claude Code wrote it; nothing here is TiZeta's walk ("walkLikeMan", still in
# design/downloads/lowpoly_man/simpleMan2.6.blend). Every action is keyed on every frame at 25 fps:
#   walk       28 frames, looping: an easy stroll, 0.62 m steps, 1.10 m/s at 1x
#   run        16 frames, looping: the chase, leaning in with his arms pumping, 1.14 m steps, 3.56 m/s at 1x
#   bend       72 frames: hands onto his knees, peers ahead and down, tilts his head one way and the other, stands up
#   take_away  72 frames: stoops, grabs with his right hand at TAKE_GRIP (the raccoon's mouth), two tugs, yanks it free
#              and rocks back on his heels, straightens up holding it at his chest in both hands, shakes his head;
#              he ends there, holding it
#   dance      64 frames, looping (added 23 Oct 2026 for the campsite): the chubby man's step-touch with his own
#              arms (DANCE below)
#   scared, guard, shoo  (added 23 Oct 2026, the campers' reactions) as animate_chubby.py has them
# All in place, facing -Y (+Z in Godot): the game moves him and plays walk and run at speed / their speed above.
#
# prepare_lowpoly_man.py ends by running this file. On its own, it re-keys the four actions on the saved .blend, saves
# it and exports the .glb (LOWPOLY_MAN_OUT, a path without an extension, works on a test copy instead):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --factory-startup --disable-autoexec \
#       --python-exit-code 1 --python tools/blender/animate_lowpoly_man.py

import bpy, os
from mathutils import Vector

_CHUBBY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "animate_chubby.py")
L = {"__name__": "animate_chubby_lib", "__file__": _CHUBBY}
exec(compile(open(_CHUBBY, encoding="utf-8").read(), _CHUBBY, "exec"), L)
Keys, REST = L["Keys"], L["REST"]

TAKE_GRIP = Vector((-0.10, -0.37, 0.30))    # where he takes the item: the raccoon's mouth (rig space, metres)

# his legs (hip to ankle, 0.84 m) are 0.95 of the rigged camper's: the camper's steps and bounce at his size
WALK = dict(frames=28, stride=1.24, duty=0.60, flat=0.11, heel_off=0.40, strike=16.0, off=-34.0,
            d0=-0.338, lift=0.043, lift_early=0.8,
            bob=0.015, bob_low=0.04, drop=-0.021, sway=0.021, sway_lag=0.02,
            yaw=5.0, list=3.5, roll=0.5, tilt=2.0, lean=3.0, lean_bob=0.6, twist=4.0, chest=1.0, look=4.0,
            arm_swing=19.0, arm_bias=-2.0, arm_lag=0.04, arm_in=4.0, arm_out=3.0,
            elbow=10.0, elbow_fwd=10.0, elbow_back=0.0, wrist=3.0)
RUN = dict(frames=16, stride=2.28, duty=0.36, flat=0.06, heel_off=0.20, strike=9.0, off=-40.0,
           d0=-0.323, lift=0.19, lift_early=0.65,
           bob=0.028, bob_low=0.14, drop=-0.055, sway=0.011, sway_lag=0.10,
           yaw=8.0, list=3.0, roll=0.5, tilt=6.0, lean=15.0, lean_bob=1.5, twist=9.0, chest=2.0, look=0.0,
           arm_swing=45.0, arm_bias=-4.0, arm_lag=0.03, arm_in=12.0, arm_out=4.0,
           elbow=80.0, elbow_fwd=8.0, elbow_back=-15.0, wrist=4.0)
# his dance (23 Oct 2026, the campsite): the chubby man's step-touch a little wider, his right fist punching up from
# his shoulder on every beat, his left arm bent and swinging
_arm = L["_arm"]
DANCE = dict(L["DANCE"], step=0.18, bounce=0.04, pop=5.0,
             arms={"l": _arm(sw=-30.0, sw_amp=20.0, out=16.0, el=90.0, el_amp=10.0, phase=0.0, inward=-20.0),
                   "r": _arm(sw=-120.0, sw_amp=-25.0, out=45.0, el=45.0, el_amp=-25.0, period=1.0)})

# His reactions (scared and the rest, 23 Oct 2026): his arms are long enough to put his hands up without
# turning them out, as the chubby man's are
REACT = dict(L["REACT"], hands_out=18.0, hands_twist=0.0)


def clips(body):
    """bend and take_away for a slim man: the rigged camper's poses, with the hand places measured on him (the front of
    his knees and of his chest). His arms are short for his long legs, so he leans further than the camper did and his
    hands go just above his knees."""
    knee = {}
    for k, sd in body.side.items():
        x = body.tail(sd["thigh"]).x
        z = body.tail(sd["thigh"]).z + 0.12
        knee[k] = (sd["thigh"], Vector((x, body.front(x, z) - 0.012, z)),
                   (Vector((-sd["s"] * 0.25, -0.75, -0.6)), Vector((0, 0.3, -1))))       # fingers over the knee, palm down
    chest = body.front(0.0, 1.15)                          # the front of his chest, where he holds the item
    hold_r = ("schiena", Vector((-0.045, chest - 0.11, 1.15)), (Vector((0.85, -0.2, 0.45)), Vector((0.2, 0.1, 1.0))))
    hold_l = ("schiena", Vector((0.075, chest - 0.10, 1.12)), (Vector((-0.8, -0.35, 0.45)), Vector((-0.9, 0, 0.2))))
    up_r = ("schiena", Vector((-0.12, chest - 0.02, 1.32)), (Vector((0.4, -0.2, 0.9)), Vector((0.9, 0.2, 0.2))))
    reach = ("world", TAKE_GRIP, (Vector((0.05, -0.55, -0.83)), Vector((0.95, 0.1, -0.1))))
    tug = lambda dy, dz: ("world", TAKE_GRIP + Vector((0, dy, dz)), (Vector((0.05, -0.45, -0.89)), Vector((0.95, 0.1, -0.1))))
    bend = Keys(REST, [
        (0, {}),
        (5, dict(pel=Vector((0, 0.005, -0.004)), tum_p=-2.0, head_p=-3.0)),          # a breath in, about to look
        (17, dict(pel=Vector((0, 0.13, -0.17)), hips_p=26.0, tum_p=55.0, chest_p=10.0, neck_p=-22.0, head_p=24.0,
                  knee_out=8.0, l_ik=1.0, r_ik=1.0, l_pole_w=1.0, r_pole_w=1.0, l_at=knee["l"], r_at=knee["r"])),
        (22, dict(pel=Vector((0, 0.12, -0.18)), tum_p=57.0, head_p=25.0)),               # settles
        (32, dict(pel=Vector((0, 0.10, -0.19)), tum_p=62.0, neck_p=-26.0, head_p=29.0, head_r=-16.0,   # leans in, his
                  head_y=-6.0)),                                                          # head on one side
        (40, dict(head_r=-17.0)),
        (48, dict(head_r=15.0, head_y=6.0, head_p=28.0)),                                  # and the other
        (55, dict(head_r=14.0)),
        (60, dict(pel=Vector((0, 0.12, -0.18)), tum_p=57.0, neck_p=-22.0, head_p=24.0, head_r=0.0, head_y=0.0)),
        (72, dict(REST)),
    ])
    take = Keys(REST, [
        (0, {}),
        (4, dict(pel=Vector((0, -0.005, -0.004)), tum_p=-3.0, head_p=6.0)),         # sees it, draws back a touch
        (13, dict(pel=Vector((-0.04, 0.07, -0.38)), hips_p=24.0, hips_y=-6.0, tum_p=70.0, tum_y=-10.0, tum_r=-6.0,
                  chest_p=10.0, neck_p=-16.0, head_p=48.0, head_y=-8.0, knee_out=10.0,
                  r_ik=1.0, r_pole_w=0.8, r_at=reach, l_ik=1.0, l_pole_w=1.0, l_at=knee["l"])),     # stoops and reaches
        (21, dict(pel=Vector((-0.04, 0.09, -0.36)), tum_p=64.0, r_at=tug(0.07, 0.03))),            # tug
        (25, dict(pel=Vector((-0.04, 0.07, -0.38)), tum_p=67.0, r_at=tug(0.02, 0.0))),             # it pulls back
        (30, dict(pel=Vector((-0.04, 0.10, -0.35)), tum_p=63.0, r_at=tug(0.09, 0.04))),            # tug
        (33, dict(pel=Vector((-0.04, 0.08, -0.37)), tum_p=66.0, r_at=tug(0.04, 0.01))),
        (38, dict(pel=Vector((-0.02, 0.10, -0.08)), hips_p=6.0, hips_y=-2.0, tum_p=4.0, tum_y=-4.0, tum_r=0.0,
                  chest_p=-6.0, neck_p=-2.0, head_p=-10.0, head_y=0.0, knee_out=4.0, l_toe=14.0, r_toe=14.0,
                  r_at=up_r, l_ik=0.0, l_pole_w=0.0, l_at=("fk",), l_sw=25.0, l_el=30.0)),          # free: he rocks back
        (44, dict(pel=Vector((0, 0.02, -0.02)), hips_p=0.0, hips_y=0.0, tum_p=2.0, tum_y=0.0, chest_p=-2.0, head_p=0.0,
                  knee_out=0.0, l_toe=0.0, r_toe=0.0, l_sw=-10.0, l_el=40.0)),                     # catches his balance
        (52, dict(pel=Vector((0, 0.0, -0.01)), tum_p=4.0, neck_p=4.0, head_p=22.0,                # holds it to his chest,
                  r_at=hold_r, r_pole_w=0.3, l_ik=1.0, l_pole_w=0.3, l_at=hold_l,                   # looking down at him
                  l_sw=0.0, l_el=0.0)),
        (56, dict(head_y=13.0)),                                                                  # shakes his head
        (60, dict(head_y=-12.0)),
        (64, dict(head_y=9.0)),
        (68, dict(head_y=0.0, head_p=18.0, tum_p=1.0)),
        (72, dict(head_p=16.0)),
    ])
    return bend, take


def animate(rig, body, only=None, log=print):
    """animate_chubby.animate with his numbers."""
    L["WALK"], L["RUN"], L["clips"], L["DANCE"] = WALK, RUN, clips, DANCE
    L["REACT"] = REACT
    L["CLIPS"] = [("walk", WALK["frames"], True), ("run", RUN["frames"], True), ("bend", 72, False), ("take_away", 72, False),
                  ("dance", DANCE["frames"], True)] + L["REACT_CLIPS"]
    return L["animate"](rig, body, only=only, log=log)


export_glb = L["export_glb"]


if __name__ == "__main__":
    REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    OUT = os.environ.get("LOWPOLY_MAN_OUT") or os.path.join(REPO, "assets", "characters", "lowpoly_man")
    bpy.ops.wm.open_mainfile(filepath=OUT + ".blend", load_ui=False, use_scripts=False)
    rig, body = bpy.data.objects["LowpolyMan_rig"], bpy.data.objects["LowpolyMan"]
    src = open(__file__, encoding="utf-8").read()
    t = bpy.data.texts.get("lowpoly_man_animate") or bpy.data.texts.new("lowpoly_man_animate")
    t.clear(); t.write(src)
    animate(rig, body)
    bpy.ops.wm.save_as_mainfile(filepath=OUT + ".blend", compress=True)
    export_glb(rig, OUT + ".glb")
    print("SAVED", OUT + ".blend", "| EXPORTED", OUT + ".glb", os.path.getsize(OUT + ".glb"), "bytes")
