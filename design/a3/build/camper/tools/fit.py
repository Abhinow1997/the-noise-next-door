# Fits the reference camera to the camper's landmarks and renders reference | model | overlay.
# exec() in Blender with L3 (model landmarks, metres) and OUT (file name) defined.
import bpy, os, numpy as np
T = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\character\raccoon_v2\tools"
REF = r"C:\Users\dotbix\Work\Gamedev\the-noise-next-door\design\reference\red-beanie-man.jpg"
ns = {}
for f in ("solve.py", "facecam.py", "compare.py"):
    exec(open(os.path.join(T, f), encoding="utf-8").read(), ns)
# the reference's landmarks (pixels in the 2218 x 1888 original), read off grid crops
L2 = {"pompom": (1165, 280), "nose": (1074, 485), "chin": (1117, 550), "cuff_bot": (1087, 411), "fold": (1087, 359),
      "flapR": (1015, 705), "flapL": (1177, 725), "pockR_bot": (1015, 775), "pockL_bot": (1177, 793), "lowL_top": (1190, 900),
      "hemR_in": (1060, 1045), "hemL_in": (1112, 1060), "slvR": (955, 978), "slvL": (1320, 1025), "jcR": (1068, 1453),
      "jcL": (1223, 1485), "tee": (1105, 588), "handR": (965, 1090), "handL": (1290, 1140),
      "btn784": (1048, 1035), "btn884": (1048, 960), "btn1016": (1050, 862), "btn1136": (1050, 772)}
keys = [k for k in L2 if k in L3]
cam, err = ns["solved_cam"]("RefCam", REF, {k: L3[k] for k in keys}, {k: L2[k] for k in keys})
X = np.array([L3[k] for k in keys]); U = np.array([L2[k] for k in keys], float)
p, res = ns["solve_cam"](X, U)
R = ns["rodrigues"](p[:3]); d = R[2] if np.dot(R[2], [0.5, -0.8, 0.3]) > 0 else -R[2]
FIT = dict(scale=np.exp(p[3]), yaw=np.degrees(np.arctan2(d[0], -d[1])), elev=np.degrees(np.arcsin(d[2])),
           rms=np.sqrt((np.linalg.norm(res, axis=1) ** 2).mean()))
print("scale %(scale).0f px/m | yaw %(yaw).1f | elev %(elev).1f | rms %(rms).1f px" % FIT)
print(" ".join("%s(%+.0f,%+.0f)" % (k, *r) for k, r in zip(keys, res)))
bpy.context.scene.camera = cam
sc = bpy.context.scene
try: sc.render.engine = "BLENDER_WORKBENCH"
except TypeError as e: print(e)
sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "MATERIAL"
objs = [o.name for o in bpy.data.objects if o.type == "MESH" and not o.hide_render]
print(ns["compare"]("RefCam", REF, objs, (880, 200, 1440, 1680), OUT, scale=0.5))
