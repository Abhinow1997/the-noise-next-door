#!/usr/bin/env python3
"""Storyboard thumbnails for STORYBOARD.md, drawn as SVG.

Run:  python make_thumbnails.py
Writes the numbered panels (01-….svg, 1600x900, 16:9) and storyboard-sheet.svg next to this file.
Panels are numbered by their place in PANELS, so reordering that list renumbers them.

Every panel is built from the same character and set functions, so the cast and
the campsite layout stay the same from panel to panel. Drawn by Claude (in code)
from the shot list in STORYBOARD.md: to change a shot, edit its panel function
and run the script again.
"""

import math
import random
from pathlib import Path

W, H = 1600, 900
HERE = Path(__file__).resolve().parent
FONT_HAND = "'Segoe Print', 'Comic Sans MS', 'Chalkboard SE', cursive"
FONT_UI = "'Segoe UI', 'Helvetica Neue', Arial, sans-serif"

# Night forest and firelight from CONCEPT.md. The raccoon follows the Gemini style
# reference. Red is kept for the beanie only, so it reads as the story's thread.
P = {
    "sky_top": "#1d2150", "sky_low": "#3a3a78", "moon": "#f4edd2", "star": "#e6e4ff",
    "ground": "#2b474c", "clearing": "#36463f", "grass": "#40665f", "foliage": "#1f3f47", "foliage2": "#264c52",
    "trunk": "#4a3a33", "trunk_dark": "#2e2629", "bark": "#3a2d2a", "hole": "#100b0e",
    "fire": "#ff9f1c", "fire_core": "#ffd166", "glow": "#ffb347", "bulb": "#ffd98a", "wire": "#101722",
    "tent": "#c9a26b", "tent_dark": "#9a7748", "speaker": "#2a2b35", "cone": "#5a5d74",
    "cooler": "#3f88a8", "cooler_lid": "#e8e2d2", "thermos": "#5f8f7f", "pack": "#8f8a3c", "pack_dark": "#6b672e",
    "grill": "#30333b", "log": "#6b4a36", "log_end": "#c89b6a", "stone": "#6c6f78",
    "car": "#2f8f8a", "car_wood": "#9a6b3c", "glass": "#9fc4d4", "tire": "#1c1f26", "van": "#e8873a", "van_top": "#f1e6cf",
    "racc": "#a39e9a", "racc_dark": "#827d78", "racc_light": "#bdb8b2", "cream": "#efe8d2", "mask": "#35322f",
    "eye": "#141313", "beanie": "#d7263d", "beanie_dark": "#a51c2e",
    "skin": "#e6b48f", "hair": "#4a3426", "jacket": "#e0b03c", "jeans": "#3f5a86", "shoe": "#2a2526",
    "outline": "#151b26", "shadow": "#0b1018", "white": "#ffffff", "paper": "#f6efdc", "ink": "#3a3330",
    "spark": "#ffe066", "fx": "#f2efe6", "dust": "#cfc6b4", "beam": "#fff5c8", "sweat": "#9fd3ff",
    "brick": "#6b4f4f", "brick_line": "#553d3e", "asphalt": "#474b54", "neon_pink": "#ff5fa2", "neon_cyan": "#4de3ff",
    "bin": "#9aa3ab", "bin_dark": "#6f7880", "bungee": "#e3a51a", "street": "#f4f7ff",
    "carrier": "#d9d3c2", "carrier_dark": "#a8a191", "sausage": "#c47a5a", "trash": "#24302f",
}

# Where things stand at the party, in metres (x to the right, z toward the camera).
CAMP = {
    "tree": (-7.0, -0.8), "fire": (0.0, 0.0), "log": (-1.3, 1.25), "backpack": (-2.65, 1.55),
    "cooler": (1.75, 1.7), "speaker": (3.4, -0.6), "tent": (5.4, -2.7), "grill": (-3.5, -2.4), "car": (1.6, -5.7),
}
CROWD = [
    dict(at=(1.25, -1.45), shirt="#9b8fc9", hair="#2d2a3a", pose="dance"),
    dict(at=(-1.45, -1.6), shirt="#e48a6a", hair="#5a3d33", pose="dance2"),
    dict(at=(2.55, 0.35), shirt="#8fb59a", hair="#2f2a24", pose="dance"),
]
NEW_CROWD = [  # the new group in the epilogue
    dict(at=(1.1, -1.5), shirt="#f0c35a", hair="#1f1d24", pose="dance2"),
    dict(at=(-1.5, -1.4), shirt="#6fb7d6", hair="#7a4b2e", pose="dance"),
    dict(at=(2.6, 0.3), shirt="#c98fb5", hair="#3b2a20", pose="dance2"),
]
TASKS = [
    ("marshmallows", "steal the marshmallows"),
    ("cocoa", "spill the cocoa"),
    ("sock", "a sock for a marshmallow"),
    ("speaker", "music off"),
    ("tent", "collapse the tent"),
]
TOWN_TASKS = [  # the town jobs from CONCEPT.md
    ("dumpster", "raid the diner dumpster"),
    ("bungee", "beat the bungee-corded bin"),
    ("barbecue", "steal from the block party barbecue"),
]
# The diner's neon cup sign, drawn the same wherever it appears.
NEON_CUP = "M 290 20 L 296 70 Q 300 80 312 80 L 338 80 Q 350 80 352 70 L 358 20 Z M 358 30 Q 378 30 378 45 Q 378 60 356 60"


# --- SVG helpers ---------------------------------------------------------------

def num(v):
    if isinstance(v, float):
        s = f"{v:.3f}".rstrip("0").rstrip(".")
        return "0" if s in ("-0", "") else s
    return str(v)


def tag(name, content=None, **kw):
    attrs = []
    for key, value in kw.items():
        if value is None:
            continue
        key = key.rstrip("_").replace("_", "-")
        attrs.append(f'{key}="{num(value) if isinstance(value, (int, float)) else value}"')
    head = f"<{name} {' '.join(attrs)}" if attrs else f"<{name}"
    return f"{head}/>" if content is None else f"{head}>{content}</{name}>"


def g(*children, **kw):
    return tag("g", "".join(children), **kw)


def place(x, y, s=1.0, rot=0.0, flip=1):
    t = f"translate({num(x)} {num(y)})"
    if rot:
        t += f" rotate({num(rot)})"
    if s != 1 or flip != 1:
        t += f" scale({num(s * flip)} {num(s)})"
    return t


def ol(width):
    return dict(stroke=P["outline"], stroke_width=width, stroke_linejoin="round")


def circle(cx, cy, r, fill, **kw):
    return tag("circle", cx=cx, cy=cy, r=r, fill=fill, **kw)


def ellipse(cx, cy, rx, ry, fill, rot=0.0, **kw):
    if rot:
        kw["transform"] = f"rotate({num(rot)} {num(cx)} {num(cy)})"
    return tag("ellipse", cx=cx, cy=cy, rx=rx, ry=ry, fill=fill, **kw)


def rect(x, y, w, h, fill, rx=0, **kw):
    return tag("rect", x=x, y=y, width=w, height=h, rx=rx or None, fill=fill, **kw)


def path(d, fill="none", **kw):
    return tag("path", d=d, fill=fill, **kw)


def poly(points, fill, **kw):
    return tag("polygon", points=" ".join(f"{num(x)},{num(y)}" for x, y in points), fill=fill, **kw)


def line(x1, y1, x2, y2, stroke, width, **kw):
    return tag("line", x1=x1, y1=y1, x2=x2, y2=y2, stroke=stroke, stroke_width=width, stroke_linecap="round", **kw)


def text(x, y, content, size, fill, family=FONT_UI, anchor="middle", weight=None):
    safe = content.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return tag("text", safe, x=x, y=y, font_size=size, fill=fill, font_family=family, text_anchor=anchor,
               font_weight=weight)


def shade(color, f):
    h = color.lstrip("#")
    rgb = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return "#{:02x}{:02x}{:02x}".format(*(max(0, min(255, round(c * f))) for c in rgb))


def depth(items):
    """Draws (z, svg) items back to front."""
    return "".join(svg for _, svg in sorted(items, key=lambda item: item[0]))


class Defs:
    """Gradients and clip paths for one panel; ids carry the panel prefix so the contact sheet can merge them."""

    def __init__(self, pid):
        self.pid, self.items = pid, []

    def radial(self, name, color, opacity, edge=None, edge_opacity=0.0):
        gid = f"{self.pid}-{name}"
        self.items.append(
            f'<radialGradient id="{gid}"><stop offset="0" stop-color="{color}" stop-opacity="{num(opacity)}"/>'
            f'<stop offset="1" stop-color="{edge or color}" stop-opacity="{num(edge_opacity)}"/></radialGradient>')
        return f"url(#{gid})"

    def vertical(self, name, top, bottom):
        gid = f"{self.pid}-{name}"
        self.items.append(
            f'<linearGradient id="{gid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/>'
            f'<stop offset="1" stop-color="{bottom}"/></linearGradient>')
        return f"url(#{gid})"

    def clip(self, name, shape):
        cid = f"{self.pid}-{name}"
        self.items.append(f'<clipPath id="{cid}">{shape}</clipPath>')
        return f"url(#{cid})"

    def svg(self):
        return f"<defs>{''.join(self.items)}</defs>" if self.items else ""


class Cam:
    """The tilted 3/4 game camera: metres on the ground (x right, z toward us) to screen pixels."""

    def __init__(self, fx, fz, k, cy=H * 0.55, depth=0.62):
        self.fx, self.fz, self.k, self.cy, self.depth = fx, fz, k, cy, depth

    def at(self, x, z):
        return W / 2 + (x - self.fx) * self.k, self.cy + (z - self.fz) * self.k * self.depth

    @property
    def person(self):
        return self.k * 0.0064

    @property
    def racc(self):
        return self.k * 0.0034


# --- Slapstick motion language ---------------------------------------------------

def speed_lines(x, y, angle, length=70, count=4, spacing=16, color=P["fx"], width=4, opacity=0.85):
    """Lines streaming away from (x, y) toward `angle` (degrees on screen, 0 = right, 90 = down)."""
    ux, uy = math.cos(math.radians(angle)), math.sin(math.radians(angle))
    px, py = -uy, ux
    out = []
    for i in range(count):
        off = (i - (count - 1) / 2) * spacing
        reach = length * (0.6 + 0.2 * (i % 3))
        sx, sy = x + px * off, y + py * off
        out.append(line(sx, sy, sx + ux * reach, sy + uy * reach, color, width, opacity=opacity))
    return "".join(out)


def burst(x, y, r=26, color=P["spark"], points=8, ink=True):
    pts = []
    for i in range(points * 2):
        a = math.pi * i / points - math.pi / 2
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr))
    return poly(pts, color, **(ol(2.5) if ink else {}))


def pop_lines(x, y, r=40, count=7, start=-160, end=-20, color=P["fx"], width=4):
    out = []
    for i in range(count):
        a = math.radians(start + (end - start) * i / max(1, count - 1))
        out.append(line(x + math.cos(a) * r, y + math.sin(a) * r,
                        x + math.cos(a) * (r + 20), y + math.sin(a) * (r + 20), color, width))
    return "".join(out)


def bounce_marks(x, y, w=90, color=P["fx"], width=4):
    out = []
    for side in (-1, 1):
        for i, r in enumerate((14, 24)):
            cx = x + side * (w + i * 16)
            out.append(path(f"M {num(cx)} {num(y - r)} Q {num(cx + side * r * 0.8)} {num(y)} {num(cx)} {num(y + r)}",
                            stroke=color, stroke_width=width, stroke_linecap="round"))
    return "".join(out)


def dust(x, y, s=1.0, opacity=0.8):
    blobs = [(0, 0, 22), (24, -8, 17), (-22, -4, 16), (8, -20, 15), (38, 4, 12)]
    return g(*[circle(bx, by, r, P["dust"], **ol(2.5)) for bx, by, r in blobs],
             transform=place(x, y, s), opacity=opacity)


def vibration(x, y, r0=30, count=3, gap=18, a0=-60, a1=60, color=P["fx"], width=4, opacity=0.9):
    out = []
    for i in range(count):
        r = r0 + i * gap
        p0 = (x + r * math.cos(math.radians(a0)), y + r * math.sin(math.radians(a0)))
        p1 = (x + r * math.cos(math.radians(a1)), y + r * math.sin(math.radians(a1)))
        out.append(path(f"M {num(p0[0])} {num(p0[1])} A {num(r)} {num(r)} 0 0 1 {num(p1[0])} {num(p1[1])}",
                        stroke=color, stroke_width=width, stroke_linecap="round", opacity=opacity))
    return "".join(out)


def arrow(points, color=P["spark"], width=6, dash=None, head=22, opacity=0.95):
    """A smooth arrow through `points`, with its head on the last point."""
    d = f"M {num(points[0][0])} {num(points[0][1])}"
    if len(points) == 2:
        d += f" L {num(points[1][0])} {num(points[1][1])}"
    for i in range(1, len(points) - 1):
        end = points[-1] if i == len(points) - 2 else (
            (points[i][0] + points[i + 1][0]) / 2, (points[i][1] + points[i + 1][1]) / 2)
        d += f" Q {num(points[i][0])} {num(points[i][1])} {num(end[0])} {num(end[1])}"
    (ex, ey), (px, py) = points[-1], points[-2]
    a = math.atan2(ey - py, ex - px)
    left = (ex - head * math.cos(a - 0.45), ey - head * math.sin(a - 0.45))
    right = (ex - head * math.cos(a + 0.45), ey - head * math.sin(a + 0.45))
    return g(path(d, stroke=color, stroke_width=width, stroke_linecap="round", stroke_dasharray=dash),
             poly([(ex, ey), left, right], color), opacity=opacity)


def wisp(points, color=P["fx"], width=4, opacity=0.8):
    """A wavy, dotted smell or swipe trail through `points`."""
    d = f"M {num(points[0][0])} {num(points[0][1])}"
    for i in range(1, len(points)):
        (x0, y0), (x1, y1) = points[i - 1], points[i]
        mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        nx, ny = -(y1 - y0), x1 - x0
        n = math.hypot(nx, ny) or 1
        bump = 16 if i % 2 else -16
        d += f" Q {num(mx + nx / n * bump)} {num(my + ny / n * bump)} {num(x1)} {num(y1)}"
    return path(d, stroke=color, stroke_width=width, stroke_linecap="round", stroke_dasharray="2 12",
                opacity=opacity)


def note(x, y, s=1.0, color=P["bulb"], rot=0.0, double=False):
    parts = [ellipse(0, 0, 9, 6.5, color, rot=-20), rect(6.5, -34, 3.4, 34, color)]
    if double:
        parts += [ellipse(24, -6, 9, 6.5, color, rot=-20), rect(30.5, -40, 3.4, 34, color),
                  poly([(6.5, -34), (33.9, -40), (33.9, -33), (6.5, -27)], color)]
    else:
        parts.append(path("M 9.9 -34 Q 23 -26 18 -12 Q 17 -22 9.9 -24 Z", color))
    return g(*parts, transform=place(x, y, s, rot))


def sweat(x, y, s=1.0):
    return path(f"M {num(x)} {num(y - 14 * s)} Q {num(x - 8 * s)} {num(y)} {num(x)} {num(y + 6 * s)} "
                f"Q {num(x + 8 * s)} {num(y)} {num(x)} {num(y - 14 * s)} Z", P["sweat"], **ol(2.5))


def freeze_marks(x, y, r, color=P["fx"]):
    out = []
    for a in (-150, -120, -60, -30, 200, 340):
        rad = math.radians(a)
        out.append(line(x + math.cos(rad) * r, y + math.sin(rad) * r,
                        x + math.cos(rad) * (r + 14), y + math.sin(rad) * (r + 14), color, 3.5))
    return "".join(out)


def iris(cx, cy, r):
    return path(f"M 0 0 H {W} V {H} H 0 Z M {num(cx - r)} {num(cy)} A {num(r)} {num(r)} 0 1 0 {num(cx + r)} {num(cy)} "
                f"A {num(r)} {num(r)} 0 1 0 {num(cx - r)} {num(cy)} Z", "#06070b", fill_rule="evenodd")


# --- The raccoon -----------------------------------------------------------------

def dirv(angle):
    """Limb direction: 0 = straight down, 90 = forward (or outward), 180 = straight up."""
    r = math.radians(angle)
    return math.sin(r), math.cos(r)


def limb(x, y, segments, width, color, sw, side=1):
    points = [(x, y)]
    for angle, length in segments:
        dx, dy = dirv(angle)
        x, y = x + dx * length * side, y + dy * length
        points.append((x, y))
    d = "M " + " L ".join(f"{num(px)} {num(py)}" for px, py in points)
    svg = (path(d, stroke=P["outline"], stroke_width=width + 2 * sw, stroke_linecap="round", stroke_linejoin="round")
           + path(d, stroke=color, stroke_width=width, stroke_linecap="round", stroke_linejoin="round"))
    return svg, points[-1]


def ringed_tail(d, width, sw, tip):
    return (path(d, stroke=P["outline"], stroke_width=width + 2 * sw, stroke_linecap="round")
            + path(d, stroke=P["racc_light"], stroke_width=width, stroke_linecap="round")
            + path(d, stroke=P["mask"], stroke_width=width, stroke_dasharray=f"{num(width * 0.36)} {num(width * 0.36)}",
                   stroke_dashoffset=num(-width * 0.5))
            + circle(tip[0], tip[1], width / 2, P["mask"], **ol(sw)))


def ear(x, y, rot, fill, sw, scale=1.0):
    return g(path("M -13 8 Q -7 -30 1 -31 Q 9 -30 13 8 Z", fill, **ol(sw)),
             path("M -6 5 Q -2 -17 1 -18 Q 5 -17 6 5 Z", P["mask"]),
             transform=f"translate({num(x)} {num(y)}) rotate({num(rot)}) scale({num(scale)})")


RACCOON_POSES = {
    # body: degrees the front tips up around the hip; legs: (far hind, near hind, far front, near front),
    # 0 = straight down, + = swung forward; head and tail: degrees up; lift: hop height.
    "stand":    dict(body=0, legs=(6, -6, 4, -4), head=0, tail=10, lift=0, leg=78),
    "walk":     dict(body=0, legs=(26, -20, -18, 26), head=0, tail=16, lift=0, leg=78),
    "run":      dict(body=-4, legs=(-62, -42, 72, 52), head=-4, tail=-6, lift=24, leg=80),
    "rear":     dict(body=58, legs=(2, -10, 36, 52), head=-50, tail=-30, lift=0, leg=80),
    "startled": dict(body=22, legs=(-40, 36, 148, 104), head=-12, tail=46, lift=80, leg=76),
    "slink":    dict(body=-6, legs=(44, -18, -26, 32), head=10, tail=-14, lift=-22, leg=60),
}


def raccoon(x, y, s=1.0, facing=1, pose="stand", beanie=False, held=None, eyes="open", mouth=None,
            spiky=False, rot=0.0, shadow=True, double_take=False, sweating=False):
    """Side view, facing right before `facing` flips it. (x, y) is the ground under the body."""
    pz = RACCOON_POSES[pose]
    sw = 3.2 / s
    o = ol(sw)
    hip, shoulder, neck = (-52, -84), (56, -84), (84, -128)
    far_hind, near_hind, far_front, near_front = pz["legs"]

    def leg(ax, ay, angle, width, color):
        svg, (ex, ey) = limb(ax, ay, [(angle, pz["leg"])], width, color, sw)
        dx, dy = dirv(angle)
        return svg + ellipse(ex + 5 + dx * 4, ey + dy * 4, width * 0.62, width * 0.38, P["mask"], **o)

    tail = g(ringed_tail("M -88 -112 Q -168 -152 -230 -124", 46, sw, (-230, -124)),
             transform=f"rotate({num(pz['tail'])} -88 -112)")

    spikes = ""
    if spiky:
        ring = []
        for i in range(40):
            a = math.tau * i / 40
            k = 1.17 if i % 2 == 0 else 0.98
            ring.append((math.cos(a) * 100 * k, -104 + math.sin(a) * 58 * k))
        spikes = poly(ring, P["racc"], **o)
    body = (ellipse(0, -104, 100, 58, P["racc"], **o)
            + path("M -100 -104 A 100 58 0 0 0 100 -104 Q 0 -80 -100 -104 Z", P["racc_dark"])
            + ellipse(0, -104, 100, 58, "none", **o)
            + ellipse(66, -92, 24, 24, P["cream"]))

    if eyes == "wide":
        eye = circle(128, -154, 13, P["white"], **o) + circle(131, -154, 5.5, P["eye"])
    elif eyes == "closed":
        eye = path("M 117 -151 Q 127 -143 137 -151", stroke=P["cream"], stroke_width=3.5, stroke_linecap="round")
    else:
        eye = circle(128, -152, 6.5, P["eye"]) + circle(130.5, -154.5, 2.3, P["white"])
    mouth_svg = ""
    if mouth == "grin":
        mouth_svg = path("M 140 -114 Q 154 -103 167 -117", stroke=P["outline"], stroke_width=sw * 1.1,
                         stroke_linecap="round")
    elif mouth == "o":
        mouth_svg = ellipse(156, -112, 6, 7, P["mask"], **o)

    head = []
    if not beanie:
        head.append(ear(86, -184, -24, P["racc_dark"], sw))
    head += [circle(106, -148, 44, P["racc"], **o)]
    if not beanie:
        head.append(ear(116, -190, 10, P["racc"], sw))
    head += [ellipse(122, -168, 30, 9, P["cream"], rot=-14), ellipse(124, -150, 32, 15, P["mask"], rot=-8),
             ellipse(142, -128, 33, 19, P["cream"], rot=-6, **o), ellipse(173, -134, 9, 7, P["mask"], **o),
             eye, mouth_svg]
    if beanie:
        head += [path("M 62 -160 Q 60 -222 110 -224 Q 160 -222 154 -160 Z", P["beanie"], **o),
                 path("M 58 -168 Q 108 -186 158 -168 L 160 -150 Q 108 -170 56 -150 Z", P["beanie_dark"], **o),
                 circle(112, -230, 12, P["beanie"], **o),
                 ear(78, -200, -34, P["racc_dark"], sw, 0.8), ear(148, -204, 30, P["racc"], sw, 0.8)]
    if sweating:
        head.append(sweat(66, -200, 1.4))
    head_inner = "".join(head)

    held_svg = ""
    if held == "bag":
        held_svg = g(rect(-8, -2, 46, 56, "#f6eef2", rx=10, **o), rect(-8, 18, 46, 8, "#f2b8c8"),
                     circle(8, -2, 9, P["white"], **o), circle(25, -5, 9, P["white"], **o),
                     transform="translate(156 -112) rotate(16)")
    elif held == "beanie":
        held_svg = g(path("M -26 2 Q -26 -38 4 -38 Q 32 -36 30 2 Z", P["beanie"], **o),
                     rect(-29, -6, 62, 13, P["beanie_dark"], rx=5, **o), circle(4, -42, 8, P["beanie"], **o),
                     transform="translate(170 -104) rotate(28)")
    elif held == "plug":
        held_svg = g(rect(0, -9, 28, 18, "#3a3d46", rx=4, **o), rect(28, -7, 12, 4, "#c8ccd4"),
                     rect(28, 3, 12, 4, "#c8ccd4"), transform="translate(166 -118) rotate(8)")
    elif held == "sausage":
        held_svg = ellipse(170, -110, 26, 12, P["sausage"], rot=-10, **o)

    ghosts = ""
    if double_take:
        ghosts = (g(head_inner, opacity=0.28, transform="translate(-36 10) rotate(-14 84 -128)")
                  + g(head_inner, opacity=0.28, transform="translate(30 -8) rotate(12 84 -128)"))
    head_group = g(ghosts, head_inner, held_svg, transform=f"rotate({num(-pz['head'])} {neck[0]} {neck[1]})")

    body_rot = f"rotate({num(-pz['body'])} {hip[0]} {hip[1]})"
    lifted = g(tail,
               leg(hip[0] + 8, hip[1] - 2, far_hind, 28, P["racc_dark"]),
               g(leg(shoulder[0] + 8, shoulder[1] - 2, far_front, 24, P["racc_dark"]), spikes, body,
                 transform=body_rot),
               leg(hip[0], hip[1], near_hind, 30, P["racc"]),
               g(leg(shoulder[0], shoulder[1], near_front, 26, P["racc"]), head_group, transform=body_rot),
               transform=f"translate(0 {num(-pz['lift'])})" if pz["lift"] else None)
    shadow_svg = ellipse(0, 3, 120, 15, P["shadow"], opacity=0.45) if shadow else ""
    return g(shadow_svg, lifted, transform=place(x, y, s, rot, facing))


def raccoon_mouth(x, y, s, facing, pose):
    """Where raccoon() puts a held thing on screen, for strings tied to it (unrotated raccoons only)."""
    pz = RACCOON_POSES[pose]
    px, py = 170, -110
    for angle, (cx, cy) in ((-pz["head"], (84, -128)), (-pz["body"], (-52, -84))):
        a = math.radians(angle)
        px, py = (cx + (px - cx) * math.cos(a) - (py - cy) * math.sin(a),
                  cy + (px - cx) * math.sin(a) + (py - cy) * math.cos(a))
    return x + px * s * facing, y + (py - pz["lift"]) * s


def beanie_shapes(o):
    """The red beanie from the front, on a head of radius 50 centred on (0, 0)."""
    return [path("M -49 -20 Q -50 -76 0 -78 Q 50 -76 49 -20 Z", P["beanie"], **o),
            path("M -53 -26 Q 0 -46 53 -26 L 53 -12 Q 0 -32 -53 -12 Z", P["beanie_dark"], **o),
            circle(0, -84, 12, P["beanie"], **o)]


def raccoon_face(x, y, s=1.0, eyes="open", mouth=None, beanie=False, rot=0.0, hat_pop=0):
    """Front view of the head, used for close-ups. `hat_pop` lifts the beanie off his head in surprise."""
    sw = 3.2 / s
    o = ol(sw)
    worn = beanie and not hat_pop

    def face_ear(side):
        return g(path("M -15 8 Q -7 -36 1 -37 Q 9 -36 15 8 Z", P["racc"], **o),
                 path("M -7 5 Q -2 -22 1 -23 Q 5 -22 7 5 Z", P["mask"]),
                 transform=f"translate({num(side * 34)} {-60 if worn else -40}) rotate({num(side * 20)})")

    parts = [] if worn else [face_ear(-1), face_ear(1)]
    parts += [circle(0, 0, 50, P["racc"], **o), ellipse(0, 12, 42, 34, P["cream"]), ellipse(0, -16, 10, 26, P["racc"])]
    for side in (-1, 1):
        parts.append(ellipse(side * 21, -2, 18, 12, P["mask"], rot=side * 16))
    parts += [ellipse(0, 24, 21, 15, P["cream"], **o), ellipse(0, 15, 8.5, 6.5, P["mask"], **o)]
    for side in (-1, 1):
        ex = side * 21
        if eyes == "wide":
            parts += [circle(ex, -3, 11, P["white"], **o), circle(ex + side * 1.5, -3, 5, P["eye"])]
        elif eyes == "closed":
            parts.append(path(f"M {ex - 8} -2 Q {ex} 5 {ex + 8} -2", stroke=P["cream"], stroke_width=3.5,
                              stroke_linecap="round"))
        elif eyes == "sly":
            parts += [circle(ex, -1, 8.5, P["white"], **o), circle(ex + side * 1.5, 1, 4.5, P["eye"]),
                      path(f"M {ex - 9.5} -1 A 9.5 9.5 0 0 1 {ex + 9.5} -1 Z", P["racc"], **o)]
        else:
            parts += [circle(ex, -2, 5.5, P["eye"]), circle(ex + 1.8, -4, 2, P["white"])]
    if mouth == "grin":
        parts.append(path("M -14 30 Q 0 43 14 30", stroke=P["outline"], stroke_width=sw, stroke_linecap="round"))
    elif mouth == "o":
        parts.append(ellipse(0, 34, 5, 6, P["mask"], **o))
    elif mouth == "smirk":
        parts.append(path("M -11 31 Q 3 39 14 27", stroke=P["outline"], stroke_width=sw, stroke_linecap="round"))
    elif mouth == "marshmallow":
        parts.append(rect(-14, 24, 28, 20, P["white"], rx=7, **o))
    if worn:
        parts += beanie_shapes(o) + [face_ear(-1), face_ear(1)]
    elif beanie:
        parts.append(g(*beanie_shapes(o), transform=f"translate(0 {num(-hat_pop)}) rotate(-12)"))
    return g(*parts, transform=place(x, y, s, rot))


def raccoon_back(x, y, s=1.0):
    """Seen from behind, peeking over the rim of his hole."""
    sw = 3.2 / s
    o = ol(sw)
    parts = [ellipse(0, 140, 98, 70, P["racc"], **o)]
    for side in (-1, 1):
        parts.append(g(path("M -15 8 Q -7 -36 1 -37 Q 9 -36 15 8 Z", P["racc"], **o),
                       path("M -8 4 Q -3 -24 1 -25 Q 5 -24 8 4 Z", P["racc_dark"]),
                       transform=f"translate({side * 34} -42) rotate({side * 18})"))
    parts += [circle(0, 0, 52, P["racc"], **o), ellipse(0, -8, 13, 34, P["racc_dark"], opacity=0.55)]
    for side in (-1, 1):
        parts.append(ellipse(side * 80, 96, 26, 15, P["mask"], **o))
    return g(*parts, transform=place(x, y, s))


def raccoon_over_shoulder(x, y, s=1.0):
    """The last shot: back to us, head turned round to grin at the camera, beanie on, paws rubbing."""
    sw = 3.2 / s
    o = ol(sw)
    parts = [ellipse(0, 140, 98, 70, P["racc"], **o)]
    for side in (-1, 1):
        px = side * 26
        parts += [ellipse(px, 92, 24, 15, P["mask"], rot=side * 30, **o)]
    parts.append(vibration(0, 92, 40, 2, 16, -150, -30, width=4))
    parts.append(raccoon_face(-6, -6, 1.02, eyes="sly", mouth="grin", beanie=True, rot=-8))
    return g(*parts, transform=place(x, y, s))


def raccoon_curled(x, y, s=1.0, eyes="wide"):
    """Curled up asleep in his hole, head on his tail."""
    sw = 3.2 / s
    o = ol(sw)
    parts = [ellipse(0, -64, 120, 66, P["racc"], **o),
             path("M -120 -64 A 120 66 0 0 0 120 -64 Q 0 -36 -120 -64 Z", P["racc_dark"]),
             ellipse(0, -64, 120, 66, "none", **o),
             ellipse(-74, -6, 22, 12, P["mask"], **o), ellipse(8, -4, 22, 12, P["mask"], **o)]
    tail_d = "M -104 -42 Q -64 14 30 4 Q 92 -2 118 -40"
    parts.append(ringed_tail(tail_d, 44, sw, (118, -40)))
    parts += [ellipse(26, -34, 18, 11, P["mask"], **o), ellipse(118, -34, 18, 11, P["mask"], **o)]
    parts.append(raccoon_face(72, -86, 0.95, eyes=eyes, mouth="o"))
    return g(*parts, transform=place(x, y, s))


# --- People ------------------------------------------------------------------------

PERSON_POSES = {
    # Side view. tilt: torso lean forward; hip: hip height; legs and arms: ((upper, lower) back, (upper, lower) front),
    # angles are directions (0 = down, 90 = forward, 180 = up, negative = backward).
    "stand": dict(tilt=0, hip=88, legs=((-4, -2), (4, 2)), arms=((-12, -6), (12, 18))),
    "sit":   dict(tilt=6, hip=46, legs=((82, 4), (92, 10)), arms=((30, 70), (78, 86))),
    "lunge": dict(tilt=22, hip=92, legs=((-40, -70), (40, 10)), arms=((-64, -30), (70, 60))),
    "trip":  dict(tilt=66, hip=96, legs=((-74, -128), (32, 6)), arms=((124, 150), (106, 130))),
    "chase": dict(tilt=18, hip=86, legs=((-48, -100), (58, 8)), arms=((-36, -12), (164, 146))),
    "reel":  dict(tilt=-26, hip=86, legs=((-18, -8), (28, 10)), arms=((-118, -150), (104, 160))),
    "kneel": dict(tilt=20, hip=56, legs=((-4, -92), (92, 4)), arms=((136, 160), (64, 76))),
    "yank":  dict(tilt=-14, hip=88, legs=((-10, -4), (30, 8)), arms=((150, 172), (84, 96))),
    "flip":  dict(tilt=-6, hip=88, legs=((-6, -2), (6, 2)), arms=((-14, -8), (140, 168))),
    "peek":  dict(tilt=12, hip=88, legs=((-4, -2), (4, 2)), arms=((-10, -4), (40, 150))),
    "limbo": dict(tilt=-58, hip=58, legs=((40, -20), (72, -8)), arms=((-70, -50), (-40, -20))),
}

FRONT_POSES = {
    # Front view. Angles: 0 = down, 90 = outward, 180 = up; (left, right).
    "stand":   dict(sway=0, legs=((6, 0), (6, 0)), arms=((12, 6), (12, 6))),
    "dance":   dict(sway=8, legs=((8, 0), (34, -10)), arms=((140, 172), (118, 160))),
    "dance2":  dict(sway=-8, legs=((30, -8), (6, 0)), arms=((96, 128), (150, 186))),
    "freeze":  dict(sway=0, legs=((6, 0), (86, 10)), arms=((90, 96), (124, 152))),
    "freeze2": dict(sway=6, legs=((20, 0), (20, 0)), arms=((168, 176), (60, 20))),
    "shrug":   dict(sway=0, legs=((6, 0), (6, 0)), arms=((30, 128), (30, 128))),
}


def hand_prop(kind, hand, angle, sw):
    hx, hy = hand
    o = ol(sw)
    dx, dy = dirv(angle)
    if kind in ("stick", "stick_drop"):
        sx, sy = dirv(angle + 12)
        tip = (hx + sx * 112, hy + sy * 112)
        out = line(hx, hy, tip[0], tip[1], "#8a6a4a", 4.5)
        if kind == "stick":
            out += ellipse(tip[0], tip[1], 9, 7, "#fff8ec", **o)
        else:
            out += (ellipse(tip[0] + 4, tip[1] + 58, 9, 7, "#fff8ec", **o)
                    + speed_lines(tip[0] + 4, tip[1] + 44, -90, 30, 3, 8, width=3))
        return out
    if kind == "phone_light":
        a1, a2 = dirv(angle - 13), dirv(angle + 13)
        beam = poly([(hx, hy), (hx + a1[0] * 640, hy + a1[1] * 640), (hx + a2[0] * 640, hy + a2[1] * 640)],
                    P["beam"], opacity=0.3)
        return beam + rect(hx - 6, hy - 10, 12, 20, "#22252c", rx=3, **o)
    if kind == "pan":
        end = (hx + dx * 30, hy + dy * 30)
        pan = (hx + dx * 64, hy + dy * 64)
        return (line(hx, hy, end[0], end[1], "#22252c", 7) + ellipse(pan[0], pan[1], 32, 26, "#2c2f36", **o)
                + ellipse(pan[0], pan[1], 22, 17, "#454a54"))
    if kind == "phone_photo":
        return g(rect(-18, -32, 36, 64, "#22252c", rx=6, **o), rect(-14, -26, 28, 50, "#cfe6f2", rx=3),
                 raccoon_face(0, -2, 0.2, beanie=True, mouth="smirk"), transform=f"translate({num(hx)} {num(hy - 26)})")
    if kind == "net":
        # A long-handled catch net, held up with the hoop at the top.
        rx_, ry_ = hx + dx * 150, hy + dy * 150
        pole = (hx - dx * 26, hy - dy * 26, hx + dx * 136, hy + dy * 136)
        mesh = "".join(line(rx_ + i * 10, ry_ + 4, rx_ + i * 5, ry_ + 56, "#c8ccd4", 2) for i in (-2, -1, 0, 1, 2))
        return (line(*pole, P["outline"], 6 + 2 * sw) + line(*pole, "#8a6a4a", 6)
                + path(f"M {num(rx_ - 30)} {num(ry_)} Q {num(rx_ - 22)} {num(ry_ + 72)} {num(rx_ + 4)} {num(ry_ + 64)} "
                       f"Q {num(rx_ + 26)} {num(ry_ + 42)} {num(rx_ + 30)} {num(ry_)} Z", "#e8e2d2", opacity=0.35)
                + mesh + ellipse(rx_, ry_, 32, 13, "none", stroke=P["outline"], stroke_width=5 + 2 * sw)
                + ellipse(rx_, ry_, 32, 13, "none", stroke="#c8ccd4", stroke_width=5))
    if kind == "spatula":
        tip = (hx + dx * 42, hy + dy * 42)
        return (line(hx, hy, tip[0], tip[1], "#22252c", 6)
                + g(rect(-13, -9, 26, 18, "#9aa0a8", rx=3, **o),
                    transform=f"translate({num(tip[0])} {num(tip[1])}) rotate({num(math.degrees(math.atan2(dy, dx)) + 90)})"))
    if kind == "bag":
        # A bag of marshmallows, like the one from the campsite.
        return g(rect(-15, -40, 30, 40, "#f6eef2", rx=7, **o), rect(-15, -26, 30, 6, "#f2b8c8"),
                 circle(-5, -40, 7, P["white"], **o), circle(7, -42, 7, P["white"], **o),
                 transform=f"translate({num(hx)} {num(hy + 10)})")
    return ""


def person(x, y, s=1.0, facing=1, shirt=P["jacket"], pants=P["jeans"], hair=P["hair"], skin=P["skin"],
           beanie=False, pose="stand", face="smile", prop=None, prop2=None, beard=False, messy=False,
           rot=0.0, shadow=True, cap=None, badge=False):
    """Side view, facing right before `facing` flips it. (x, y) is the ground under the feet.
    `beard` adds a short rounded beard; `cap` is the colour of a peaked cap; `badge` pins a badge to the chest."""
    pz = PERSON_POSES[pose]
    sw = 3.0 / s
    o = ol(sw)
    hip = (0.0, -pz["hip"])
    t = math.radians(pz["tilt"])
    up = (math.sin(t), -math.cos(t))
    shoulder = (hip[0] + up[0] * 62, hip[1] + up[1] * 62)
    hx, hy = shoulder[0] + up[0] * 30 + 4, shoulder[1] + up[1] * 30
    (bl1, bl2), (fl1, fl2) = pz["legs"]
    (ba1, ba2), (fa1, fa2) = pz["arms"]
    back_leg, bfoot = limb(hip[0] - 4, hip[1], [(bl1, 44), (bl2, 44)], 21, shade(pants, 0.82), sw)
    front_leg, ffoot = limb(hip[0] + 4, hip[1], [(fl1, 44), (fl2, 44)], 22, pants, sw)
    back_arm, bhand = limb(shoulder[0] - 2, shoulder[1] + 4, [(ba1, 34), (ba2, 32)], 15, shade(shirt, 0.82), sw)
    front_arm, fhand = limb(shoulder[0] + 2, shoulder[1] + 4, [(fa1, 34), (fa2, 32)], 16, shirt, sw)
    torso_d = f"M {num(hip[0])} {num(hip[1])} L {num(shoulder[0])} {num(shoulder[1])}"
    torso = (path(torso_d, stroke=P["outline"], stroke_width=46 + 2 * sw, stroke_linecap="round")
             + path(torso_d, stroke=shirt, stroke_width=46, stroke_linecap="round"))

    head = [circle(hx, hy, 22, skin, **o),
            path(f"M {num(hx - 22)} {num(hy + 4)} Q {num(hx - 26)} {num(hy - 24)} {num(hx)} {num(hy - 24)} "
                 f"Q {num(hx + 20)} {num(hy - 24)} {num(hx + 22)} {num(hy - 8)} Q {num(hx + 6)} {num(hy - 14)} "
                 f"{num(hx - 4)} {num(hy - 6)} Q {num(hx - 12)} {num(hy + 8)} {num(hx - 22)} {num(hy + 4)} Z", hair, **o),
            circle(hx + 21, hy + 3, 4.2, skin, **o)]
    if beard:
        head.append(path(f"M {num(hx - 10)} {num(hy + 2)} Q {num(hx - 12)} {num(hy + 24)} {num(hx + 4)} {num(hy + 28)} "
                         f"Q {num(hx + 20)} {num(hy + 28)} {num(hx + 22)} {num(hy + 12)} Q {num(hx + 12)} {num(hy + 18)} "
                         f"{num(hx + 2)} {num(hy + 14)} Q {num(hx - 4)} {num(hy + 10)} {num(hx - 10)} {num(hy + 2)} Z", hair, **o))
    if messy:
        for dx_, dy_ in ((-14, -22), (-4, -26), (8, -24), (16, -18)):
            head.append(line(hx + dx_, hy + dy_, hx + dx_ * 1.4, hy + dy_ * 1.5, hair, 4))
    if face == "laugh":
        head += [path(f"M {num(hx + 6)} {num(hy - 3)} Q {num(hx + 10)} {num(hy - 7)} {num(hx + 14)} {num(hy - 3)}",
                      stroke=P["outline"], stroke_width=2.4),
                 path(f"M {num(hx + 7)} {num(hy + 9)} Q {num(hx + 13)} {num(hy + 20)} {num(hx + 19)} {num(hy + 9)} Z",
                      P["outline"])]
    else:
        head.append(circle(hx + 10, hy - 3, 3 if face == "o" else 2.6, P["outline"]))
        if face == "o":
            head.append(ellipse(hx + 14, hy + 12, 4, 5, P["outline"]))
        elif face == "grit":
            head += [path(f"M {num(hx + 7)} {num(hy + 12)} L {num(hx + 10)} {num(hy + 9)} L {num(hx + 13)} {num(hy + 12)} "
                          f"L {num(hx + 16)} {num(hy + 9)} L {num(hx + 19)} {num(hy + 12)}", stroke=P["outline"],
                          stroke_width=2.4),
                     line(hx + 5, hy - 10, hx + 15, hy - 6, P["outline"], 2.6)]
        else:
            head.append(path(f"M {num(hx + 8)} {num(hy + 11)} Q {num(hx + 13)} {num(hy + 15)} {num(hx + 18)} {num(hy + 10)}",
                             stroke=P["outline"], stroke_width=2.4))
    if beanie:
        head += [path(f"M {num(hx - 21)} {num(hy - 6)} Q {num(hx - 20)} {num(hy - 37)} {num(hx + 2)} {num(hy - 37)} "
                      f"Q {num(hx + 22)} {num(hy - 35)} {num(hx + 22)} {num(hy - 6)} Z", P["beanie"], **o),
                 rect(hx - 23, hy - 13, 47, 11, P["beanie_dark"], rx=4, **o),
                 circle(hx + 1, hy - 41, 7, P["beanie"], **o)]
    if cap:
        head += [path(f"M {num(hx - 22)} {num(hy - 8)} Q {num(hx - 21)} {num(hy - 34)} {num(hx + 1)} {num(hy - 33)} "
                      f"Q {num(hx + 22)} {num(hy - 33)} {num(hx + 23)} {num(hy - 8)} Z", cap, **o),
                 path(f"M {num(hx + 4)} {num(hy - 13)} L {num(hx + 38)} {num(hy - 11)} Q {num(hx + 43)} {num(hy - 7)} "
                      f"{num(hx + 37)} {num(hy - 6)} L {num(hx + 4)} {num(hy - 7)} Z", shade(cap, 0.75), **o)]
    badge_svg = ""
    if badge:
        badge_svg = circle(hip[0] + up[0] * 42 + 12, hip[1] + up[1] * 42, 6.5, P["spark"], **o)

    parts = [ellipse(0, 2, 40, 9, P["shadow"], opacity=0.45) if shadow else "", back_arm,
             circle(bhand[0], bhand[1], 7.5, skin, **o)]
    if prop2:
        parts.append(hand_prop(prop2, bhand, ba2, sw))
    parts += [back_leg, front_leg, ellipse(bfoot[0] + 7, bfoot[1] + 2, 13, 7, P["shoe"], **o),
              ellipse(ffoot[0] + 7, ffoot[1] + 2, 13, 7, P["shoe"], **o), torso, badge_svg, "".join(head), front_arm,
              circle(fhand[0], fhand[1], 8, skin, **o)]
    if prop:
        parts.append(hand_prop(prop, fhand, fa2, sw))
    return g(*parts, transform=place(x, y, s, rot, facing))


def person_hand(x, y, s, facing, pose, which="front"):
    """Where person() puts a hand on screen, for things held on a string."""
    pz = PERSON_POSES[pose]
    t = math.radians(pz["tilt"])
    up = (math.sin(t), -math.cos(t))
    hx, hy = up[0] * 62 + (2 if which == "front" else -2), -pz["hip"] + up[1] * 62 + 4
    for angle, length in zip(pz["arms"][1 if which == "front" else 0], (34, 32)):
        dx, dy = dirv(angle)
        hx, hy = hx + dx * length, hy + dy * length
    return x + hx * s * facing, y + hy * s


def person_front(x, y, s=1.0, shirt="#9b8fc9", pants=P["jeans"], hair=P["hair"], skin=P["skin"], pose="stand",
                 face="laugh", back=False, rot=0.0, shadow=True):
    """Front view (or back view with `back`), for dancers and bystanders."""
    pz = FRONT_POSES[pose]
    sw = 3.0 / s
    o = ol(sw)
    sway = pz["sway"]
    parts = [ellipse(0, 2, 34, 8, P["shadow"], opacity=0.45) if shadow else ""]
    for side, (a1, a2) in zip((-1, 1), pz["legs"]):
        leg_svg, foot = limb(side * 11 + sway * 0.3, -88, [(a1, 44), (a2, 44)], 21, pants, sw, side)
        parts += [leg_svg, ellipse(foot[0] + side * 4, foot[1] + 2, 12, 7, P["shoe"], **o)]
    torso_d = f"M {num(sway * 0.6)} -88 L {num(sway)} -146"
    parts += [path(torso_d, stroke=P["outline"], stroke_width=52 + 2 * sw, stroke_linecap="round"),
              path(torso_d, stroke=shirt, stroke_width=52, stroke_linecap="round")]
    for side, (a1, a2) in zip((-1, 1), pz["arms"]):
        arm_svg, hand = limb(side * 24 + sway, -144, [(a1, 34), (a2, 30)], 15, shirt, sw, side)
        parts += [arm_svg, circle(hand[0], hand[1], 7.5, skin, **o)]
    hx, hy = sway * 1.1, -178
    if back:
        parts += [circle(hx, hy, 23, hair, **o), circle(hx - 22, hy + 2, 5, skin, **o), circle(hx + 22, hy + 2, 5, skin, **o)]
    else:
        parts += [circle(hx, hy, 23, skin, **o),
                  path(f"M {num(hx - 23)} {num(hy - 2)} Q {num(hx - 22)} {num(hy - 28)} {num(hx)} {num(hy - 26)} "
                       f"Q {num(hx + 22)} {num(hy - 28)} {num(hx + 23)} {num(hy - 2)} Q {num(hx + 8)} {num(hy - 14)} "
                       f"{num(hx - 23)} {num(hy - 2)} Z", hair, **o)]
        if face == "laugh":
            parts += [path(f"M {num(hx - 12)} {num(hy - 2)} Q {num(hx - 8)} {num(hy - 6)} {num(hx - 4)} {num(hy - 2)}",
                           stroke=P["outline"], stroke_width=2.4),
                      path(f"M {num(hx + 4)} {num(hy - 2)} Q {num(hx + 8)} {num(hy - 6)} {num(hx + 12)} {num(hy - 2)}",
                           stroke=P["outline"], stroke_width=2.4),
                      path(f"M {num(hx - 8)} {num(hy + 7)} Q {num(hx)} {num(hy + 18)} {num(hx + 8)} {num(hy + 7)} Z",
                           P["outline"])]
        else:
            parts += [circle(hx - 8, hy - 2, 3, P["outline"]), circle(hx + 8, hy - 2, 3, P["outline"])]
            if face == "o":
                parts.append(ellipse(hx, hy + 11, 4.5, 5.5, P["outline"]))
            elif face == "meh":
                parts += [line(hx - 6, hy + 10, hx + 6, hy + 10, P["outline"], 2.4),
                          line(hx - 13, hy - 12, hx - 4, hy - 14, P["outline"], 2.4),
                          line(hx + 4, hy - 14, hx + 13, hy - 12, P["outline"], 2.4)]
            else:
                parts.append(path(f"M {num(hx - 7)} {num(hy + 8)} Q {num(hx)} {num(hy + 14)} {num(hx + 7)} {num(hy + 8)}",
                                  stroke=P["outline"], stroke_width=2.4))
    return g(*parts, transform=place(x, y, s, rot))


def camper(x, y, s, pose, facing=1, beanie=True, face="smile", prop=None, prop2=None, messy=False, shadow=True,
           shirt=P["jacket"], hair=P["hair"]):
    """The camper whose red beanie the raccoon ends up wearing, and who brings him home: the other main character."""
    return person(x, y, s, facing=facing, shirt=shirt, hair=hair, beanie=beanie, pose=pose, face=face, prop=prop,
                  prop2=prop2, beard=True, messy=messy, shadow=shadow)


# --- The party set -----------------------------------------------------------------

def tuft(x, y, s):
    return path(f"M {num(x - 6 * s)} {num(y)} L {num(x - 3 * s)} {num(y - 9 * s)} M {num(x)} {num(y)} "
                f"L {num(x + s)} {num(y - 12 * s)} M {num(x + 6 * s)} {num(y)} L {num(x + 4 * s)} {num(y - 8 * s)}",
                stroke=P["grass"], stroke_width=num(2.2 * s), stroke_linecap="round")


def back_tree(x, y, k, hv, i):
    trunk_w, trunk_h = 0.45 * k, 2.2 * k * hv
    fol = P["foliage"] if i % 2 else P["foliage2"]
    out = [rect(x - trunk_w / 2, y - trunk_h, trunk_w, trunk_h + 2, P["trunk_dark"])]
    for bx, by, r in ((0, -1.2, 1.5), (-1.1, -0.5, 1.15), (1.1, -0.6, 1.2), (0.2, -2.3, 1.15), (-0.6, -1.9, 1.0)):
        out.append(circle(x + bx * k, y - trunk_h + by * k * hv, r * k, fol))
    return "".join(out)


def his_tree(x, y, k, hv=0.8, hole_h=2.6, top=6.5):
    """The raccoon's tree: the same silhouette everywhere it appears."""
    w = 0.8 * k
    sw = max(2.0, 0.03 * k)
    o = ol(sw)
    trunk_top = y - top * k * hv
    out = [ellipse(x + 0.3 * k, y + 2, 1.0 * k, 0.28 * k, P["shadow"], opacity=0.45),
           path(f"M {num(x - w * 0.9)} {num(y + 2)} Q {num(x - w * 0.55)} {num(y - 0.2 * k)} {num(x - w * 0.5)} {num(y - 0.6 * k)} "
                f"L {num(x - w * 0.46)} {num(trunk_top)} L {num(x + w * 0.46)} {num(trunk_top)} "
                f"L {num(x + w * 0.5)} {num(y - 0.6 * k)} Q {num(x + w * 0.6)} {num(y - 0.2 * k)} {num(x + w * 0.95)} {num(y + 2)} Z",
                P["trunk"], **o)]
    for i, dx in enumerate((-0.28, -0.05, 0.2, 0.36)):
        out.append(path(f"M {num(x + dx * w)} {num(y - 0.3 * k)} q {num(0.04 * k)} {num(-1.2 * k * hv)} 0 {num(-2.2 * k * hv)}",
                        stroke=P["bark"], stroke_width=max(2, 0.03 * k), stroke_linecap="round"))
    hy = y - hole_h * k * hv
    out += [ellipse(x + 0.02 * k, hy, 0.27 * k, 0.36 * k * hv, shade(P["trunk"], 0.7), **o),
            ellipse(x + 0.04 * k, hy + 0.02 * k, 0.2 * k, 0.29 * k * hv, P["hole"])]
    for bx, by, r in ((0, -0.4, 1.7), (-1.3, 0.3, 1.3), (1.3, 0.2, 1.35), (-0.5, -1.6, 1.3), (0.8, -1.4, 1.2)):
        out.append(circle(x + bx * k, trunk_top + by * k * hv, r * k, P["foliage2"] if bx > 0 else P["foliage"]))
    return "".join(out)


def campfire(x, y, k, hv=0.8, lit=True):
    sw = max(1.6, 0.025 * k)
    o = ol(sw)
    out = []
    for i in range(9):
        a = math.tau * i / 9
        out.append(ellipse(x + math.cos(a) * 0.55 * k, y + math.sin(a) * 0.36 * k, 0.12 * k, 0.08 * k, P["stone"], **o))
    for (x1, y1, x2, y2) in ((-0.45, 0.08, 0.42, -0.12), (-0.4, -0.12, 0.46, 0.1)):
        out.append(line(x + x1 * k, y + y1 * k, x + x2 * k, y + y2 * k, P["outline"], 0.17 * k + 2 * sw))
        out.append(line(x + x1 * k, y + y1 * k, x + x2 * k, y + y2 * k, P["log"], 0.17 * k))
    if lit:
        for fx, h, w, col in ((-0.14, 0.62, 0.2, P["fire"]), (0.16, 0.5, 0.18, P["fire"]), (0.0, 0.82, 0.24, P["fire"]),
                              (0.0, 0.45, 0.13, P["fire_core"]), (-0.12, 0.3, 0.09, P["fire_core"])):
            bx, by = x + fx * k, y - 0.02 * k
            top = by - h * k * hv
            out.append(path(f"M {num(bx)} {num(by)} Q {num(bx - w * k)} {num(by - h * k * hv * 0.4)} {num(bx)} {num(top)} "
                            f"Q {num(bx + w * k)} {num(by - h * k * hv * 0.4)} {num(bx)} {num(by)} Z", col))
        for sx, sy in ((-0.2, 1.1), (0.25, 1.25), (0.05, 1.45)):
            out.append(circle(x + sx * k, y - sy * k * hv, 0.03 * k, P["fire_core"]))
    return "".join(out)


def tent(x, y, k, hv=0.8):
    sw = max(1.8, 0.03 * k)
    o = ol(sw)
    half, height, deep = 1.15 * k, 1.65 * k * hv, 1.7 * k
    ax, ay = x, y - height
    out = [ellipse(x + 0.6 * k, y + 0.05 * k, 1.9 * k, 0.45 * k, P["shadow"], opacity=0.4),
           poly([(ax, ay), (ax + deep * 0.62, ay - deep * 0.38), (x + half + deep * 0.62, y - deep * 0.38), (x + half, y)],
                P["tent_dark"], **o),
           poly([(x - half, y), (ax, ay), (x + half, y)], P["tent"], **o),
           poly([(x - 0.42 * k, y), (ax, ay + 0.25 * k * hv), (x + 0.42 * k, y)], "#5b4630", **o)]
    for side in (-1, 1):
        px = x + side * (half + 0.9 * k)
        out += [line(ax + side * 0.05 * k, ay + 0.1 * k, px, y + 0.15 * k, "#d8cfb5", max(1.2, 0.012 * k)),
                line(px, y + 0.15 * k, px, y + 0.05 * k, P["outline"], max(2, 0.02 * k))]
    return "".join(out)


def speaker(x, y, k, hv=0.8, state="on"):
    sw = max(1.8, 0.03 * k)
    o = ol(sw)
    w, h, top = 0.62 * k, 0.95 * k * hv, 0.18 * k
    out = [ellipse(x, y + 0.03 * k, 0.5 * k, 0.15 * k, P["shadow"], opacity=0.45),
           poly([(x - w / 2, y - h), (x - w / 2 + top, y - h - top * 0.6), (x + w / 2 + top, y - h - top * 0.6),
                 (x + w / 2 + top, y - top * 0.6), (x + w / 2, y)], shade(P["speaker"], 0.75), **o),
           rect(x - w / 2, y - h, w, h, P["speaker"], rx=0.04 * k, **o),
           circle(x, y - h * 0.7, 0.11 * k, P["cone"], **o), circle(x, y - h * 0.3, 0.19 * k, P["cone"], **o),
           circle(x, y - h * 0.3, 0.07 * k, shade(P["cone"], 0.7))]
    s = k / 95 * 1.3
    if state == "on":
        for i, (dx, dy, r) in enumerate(((-0.55, 0.45, -12), (0.3, 0.8, 10), (-0.1, 1.25, -6))):
            out.append(note(x + dx * k, y - h - dy * k * hv, s, P["bulb"], r, double=(i == 1)))
        out.append(vibration(x + w / 2, y - h * 0.4, 0.25 * k, 3, 0.14 * k, -50, 50, P["bulb"], max(2, 0.03 * k), 0.8))
    elif state == "off":
        for dx, dy, r in ((-0.75, 0.55, 160), (0.65, 0.3, 200), (-0.15, 0.95, 175)):
            nx, ny = x + dx * k, y - h - dy * k * hv
            out.append(speed_lines(nx, ny - 0.2 * k, -90, 0.18 * k, 2, 0.07 * k, P["bulb"], 3, 0.7))
            out.append(note(nx, ny, s * 0.75, P["bulb"], r))
        out.append(burst(x - w / 2 - 0.05 * k, y - 0.12 * k, 0.16 * k))
    return "".join(out)


def cooler(x, y, k, hv=0.8, thermos=True):
    sw = max(1.8, 0.03 * k)
    o = ol(sw)
    w, h, top = 0.9 * k, 0.5 * k * hv, 0.22 * k
    out = [ellipse(x + 0.08 * k, y + 0.03 * k, 0.62 * k, 0.16 * k, P["shadow"], opacity=0.45),
           rect(x - w / 2, y - h, w, h, P["cooler"], rx=0.05 * k, **o),
           poly([(x - w / 2, y - h), (x - w / 2 + top * 0.5, y - h - top * 0.55), (x + w / 2 + top * 0.5, y - h - top * 0.55),
                 (x + w / 2, y - h)], P["cooler_lid"], **o),
           rect(x - 0.12 * k, y - h * 0.62, 0.24 * k, 0.06 * k, shade(P["cooler"], 0.7), rx=0.02 * k)]
    if thermos:
        tx, tb = x + 0.18 * k, y - h - top * 0.25
        tw, th = 0.13 * k, 0.4 * k * hv
        out += [rect(tx - tw / 2, tb - th, tw, th, P["thermos"], rx=0.03 * k, **o),
                rect(tx - tw * 0.6, tb - th - 0.07 * k, tw * 1.2, 0.08 * k, shade(P["thermos"], 0.7), rx=0.02 * k, **o)]
    return "".join(out)


def backpack(x, y, k, hv=0.8, state="closed"):
    sw = max(1.8, 0.03 * k)
    o = ol(sw)
    w, h = 0.5 * k, 0.62 * k * hv
    out = [ellipse(x, y + 0.03 * k, 0.36 * k, 0.1 * k, P["shadow"], opacity=0.45),
           rect(x - w / 2, y - h, w, h, P["pack"], rx=0.14 * k, **o),
           rect(x - w * 0.36, y - h * 0.45, w * 0.72, h * 0.36, P["pack_dark"], rx=0.06 * k, **o),
           path(f"M {num(x + w / 2)} {num(y - h * 0.8)} q {num(0.1 * k)} {num(0.2 * k)} 0 {num(0.45 * k * hv)}",
                stroke=P["pack_dark"], stroke_width=max(3, 0.05 * k), stroke_linecap="round")]
    zip_y = y - h + 0.1 * k * hv
    if state == "open":
        out += [ellipse(x, zip_y, w * 0.38, 0.07 * k, "#2a2618", **o),
                rect(x - 0.12 * k, zip_y - 0.2 * k, 0.24 * k, 0.24 * k, "#f6eef2", rx=0.05 * k, **o),
                circle(x - 0.05 * k, zip_y - 0.2 * k, 0.05 * k, P["white"], **o),
                circle(x + 0.06 * k, zip_y - 0.22 * k, 0.05 * k, P["white"], **o)]
    else:
        out.append(line(x - w * 0.36, zip_y, x + w * 0.36, zip_y, "#d9d2a0", max(2, 0.025 * k),
                        stroke_dasharray=f"{num(0.03 * k)} {num(0.03 * k)}"))
    return "".join(out)


def grill(x, y, k, hv=0.8):
    sw = max(1.8, 0.03 * k)
    o = ol(sw)
    bowl_y = y - 0.8 * k * hv
    out = [ellipse(x, y + 0.03 * k, 0.4 * k, 0.12 * k, P["shadow"], opacity=0.45)]
    for dx in (-0.22, 0.0, 0.22):
        out.append(line(x + dx * k * 0.7, bowl_y, x + dx * k, y, P["outline"], max(3, 0.04 * k)))
    out += [path(f"M {num(x - 0.34 * k)} {num(bowl_y)} A {num(0.34 * k)} {num(0.3 * k * hv)} 0 0 0 {num(x + 0.34 * k)} {num(bowl_y)} Z",
                 P["grill"], **o),
            ellipse(x, bowl_y, 0.34 * k, 0.1 * k, "#454852", **o)]
    for dx in (-0.14, 0.0, 0.14):
        out.append(line(x + dx * k - 0.08 * k, bowl_y + dx * 0.1 * k, x + dx * k + 0.08 * k, bowl_y + dx * 0.1 * k - 0.02 * k,
                        "#a5603e", max(4, 0.06 * k)))
    for i in range(2):
        out.append(path(f"M {num(x + (i - 0.5) * 0.15 * k)} {num(bowl_y - 0.1 * k)} q {num(-0.08 * k)} {num(-0.2 * k)} 0 {num(-0.4 * k)} "
                        f"q {num(0.08 * k)} {num(-0.2 * k)} 0 {num(-0.4 * k)}", stroke=P["fx"], stroke_width=max(2, 0.025 * k),
                        stroke_linecap="round", opacity=0.45))
    return "".join(out)


def log_seat(x, y, k, hv=0.8):
    sw = max(1.8, 0.03 * k)
    o = ol(sw)
    length, r = 1.8 * k, 0.2 * k * hv
    return (ellipse(x, y + 0.04 * k, length * 0.55, 0.12 * k, P["shadow"], opacity=0.45)
            + rect(x - length / 2, y - 2 * r, length, 2 * r, P["log"], rx=r, **o)
            + ellipse(x + length / 2 - r * 0.6, y - r, r * 0.65, r * 0.95, P["log_end"], **o)
            + line(x - length * 0.3, y - r, x + length * 0.15, y - r * 1.2, shade(P["log"], 0.75), max(2, 0.025 * k)))


def string_lights(x1, y1, x2, y2, sag, k, defs, bulbs=18, poles=None):
    cx, cy = (x1 + x2) / 2, (y1 + y2) / 2 + 2 * sag
    out = []
    if poles:
        for (px, py, gy) in poles:
            out.append(line(px, py, px, gy, P["outline"], max(3, 0.05 * k)))
    out.append(path(f"M {num(x1)} {num(y1)} Q {num(cx)} {num(cy)} {num(x2)} {num(y2)}", stroke=P["wire"],
                    stroke_width=max(1.5, 0.02 * k)))
    halo = defs.radial("bulb", P["bulb"], 0.6)
    for i in range(1, bulbs):
        t = i / bulbs
        bx = (1 - t) ** 2 * x1 + 2 * (1 - t) * t * cx + t * t * x2
        by = (1 - t) ** 2 * y1 + 2 * (1 - t) * t * cy + t * t * y2 + 0.05 * k
        out += [circle(bx, by, 0.17 * k, halo), circle(bx, by, 0.05 * k, P["bulb"])]
    return "".join(out)


def wagon(x, y, k, hv=0.8, facing=1, lights=False):
    """The campers' teal station wagon: parked at the party, then the car that drives him home."""
    sw = max(1.8, 0.03 * k)
    o = ol(sw)

    def p(mx, my):
        return f"{num(x + mx * k * facing)} {num(y - my * k * hv)}"

    out = [ellipse(x, y, 2.6 * k, 0.32 * k * hv, P["shadow"], opacity=0.45)]
    if lights:
        hx, hy = x + 2.32 * k * facing, y - 0.66 * k * hv
        out.append(poly([(hx, hy - 0.05 * k), (hx + 6.0 * k * facing, hy - 0.9 * k), (hx + 6.0 * k * facing, hy + 0.9 * k)],
                        P["beam"], opacity=0.22))
    out += [path(f"M {p(-2.3, 0.3)} L {p(-2.3, 0.85)} L {p(-1.95, 1.42)} L {p(0.9, 1.42)} L {p(1.6, 0.95)} "
                 f"L {p(2.3, 0.85)} L {p(2.35, 0.3)} Z", P["car"], **o),
            path(f"M {p(-1.85, 0.95)} L {p(-1.75, 1.32)} L {p(-0.75, 1.32)} L {p(-0.75, 0.95)} Z", P["glass"], **o),
            path(f"M {p(-0.6, 0.95)} L {p(-0.6, 1.32)} L {p(0.4, 1.32)} L {p(0.4, 0.95)} Z", P["glass"], **o),
            path(f"M {p(0.55, 0.95)} L {p(0.55, 1.32)} L {p(0.85, 1.32)} L {p(1.4, 0.95)} Z", P["glass"], **o),
            path(f"M {p(-2.25, 0.5)} L {p(-2.25, 0.78)} L {p(1.5, 0.78)} L {p(1.5, 0.5)} Z", P["car_wood"], **o)]
    for wx in (-1.45, 1.45):
        cx, cy = x + wx * k * facing, y - 0.3 * k * hv
        out += [ellipse(cx, cy, 0.36 * k, 0.36 * k * hv, P["tire"], **o), ellipse(cx, cy, 0.15 * k, 0.15 * k * hv, "#9aa0a8", **o)]
    out += [ellipse(x + 2.3 * k * facing, y - 0.66 * k * hv, 0.09 * k, 0.12 * k * hv, "#fff4c4", **o),
            rect(x - 2.36 * k * facing - (0.06 * k if facing > 0 else 0), y - 0.75 * k * hv, 0.06 * k, 0.2 * k * hv, "#f0a24a", **o)]
    return "".join(out)


def van(x, y, k, hv=0.8, facing=1, body=P["van"], top=P["van_top"], cargo=False):
    """The new campers' van in the epilogue. With `cargo` it's the animal-control van: no back windows, paw logo."""
    sw = max(1.8, 0.03 * k)
    o = ol(sw)

    def p(mx, my):
        return f"{num(x + mx * k * facing)} {num(y - my * k * hv)}"

    out = [ellipse(x, y, 2.5 * k, 0.32 * k * hv, P["shadow"], opacity=0.45),
           path(f"M {p(-2.2, 0.3)} L {p(-2.2, 1.9)} Q {p(-2.2, 2.05)} {p(-2.0, 2.05)} L {p(1.9, 2.05)} Q {p(2.25, 2.05)} {p(2.25, 1.7)} "
                f"L {p(2.3, 0.3)} Z", body, **o),
           path(f"M {p(-2.2, 1.2)} L {p(-2.2, 1.9)} Q {p(-2.2, 2.05)} {p(-2.0, 2.05)} L {p(1.9, 2.05)} Q {p(2.25, 2.05)} {p(2.25, 1.7)} "
                f"L {p(2.26, 1.2)} Z", top, **o)]
    for wx in (1.0,) if cargo else (-1.7, -0.8, 0.1, 1.0):
        out.append(path(f"M {p(wx, 1.35)} L {p(wx, 1.85)} L {p(wx + 0.7, 1.85)} L {p(wx + 0.7, 1.35)} Z", P["glass"], **o))
    if cargo:
        out.append(paw_logo(x - 0.55 * k * facing, y - 1.55 * k * hv, k / 48))
    for wx in (-1.4, 1.4):
        cx, cy = x + wx * k * facing, y - 0.3 * k * hv
        out += [ellipse(cx, cy, 0.36 * k, 0.36 * k * hv, P["tire"], **o), ellipse(cx, cy, 0.15 * k, 0.15 * k * hv, "#9aa0a8", **o)]
    return "".join(out)


def party(cam, defs, *, crowd=CROWD, camper_pose="roast", backpack_state="closed", speaker_state="on",
          vehicle="wagon", tree=True, new_camper=False):
    """The party at its fixed layout, seen through the game camera. Returns (background, depth items)."""
    k, hv = cam.k, 0.8
    fx, fy = cam.at(*CAMP["fire"])
    bg = [rect(0, 0, W, H, P["ground"]),
          ellipse(fx, fy + 0.3 * k * cam.depth, 5.4 * k, 3.4 * k * cam.depth, P["clearing"]),
          ellipse(fx, fy, 7.0 * k, 7.0 * k * cam.depth, defs.radial("fireglow", P["glow"], 0.38))]
    rng = random.Random(11)
    for _ in range(170):
        sx, sy = cam.at(rng.uniform(-13, 13), rng.uniform(-8, 6))
        if -10 < sx < W + 10 and -10 < sy < H + 10:
            bg.append(tuft(sx, sy, k / 95))
    for i, x in enumerate((-12, -9.4, -6.6, -3.9, -1.1, 1.8, 4.6, 7.4, 10.2, 12.8)):
        sx, sy = cam.at(x, -7.4 + (0.5 if i % 2 else 0))
        bg.append(back_tree(sx, sy, k, hv, i))

    items = []
    a, b = cam.at(-8.6, -4.6), cam.at(8.6, -4.6)
    lift = 2.7 * k * hv
    items.append((-4.6, string_lights(a[0], a[1] - lift, b[0], b[1] - lift, 0.5 * k, k, defs,
                                      poles=[(a[0], a[1] - lift, a[1]), (b[0], b[1] - lift, b[1])])))
    vx, vy = cam.at(*CAMP["car"])
    items.append((CAMP["car"][1], wagon(vx, vy, k, hv) if vehicle == "wagon" else van(vx, vy, k, hv)))
    for name, fn in (("tent", tent), ("grill", grill), ("log", log_seat)):
        px, py = cam.at(*CAMP[name])
        items.append((CAMP[name][1], fn(px, py, k, hv)))
    sx, sy = cam.at(*CAMP["speaker"])
    items.append((CAMP["speaker"][1], speaker(sx, sy, k, hv, speaker_state)))
    items.append((0.0, campfire(fx, fy, k, hv)))
    cx, cy = cam.at(*CAMP["cooler"])
    items.append((CAMP["cooler"][1], cooler(cx, cy, k, hv)))
    bx, by = cam.at(*CAMP["backpack"])
    items.append((CAMP["backpack"][1], backpack(bx, by, k, hv, backpack_state)))
    if tree:
        tx, ty = cam.at(*CAMP["tree"])
        items.append((CAMP["tree"][1], his_tree(tx, ty, k, hv)))
    for c in crowd:
        px, py = cam.at(*c["at"])
        items.append((c["at"][1], person_front(px, py, cam.person, shirt=c["shirt"], hair=c["hair"], pose=c["pose"],
                                               back=c.get("back", False), face=c.get("face", "laugh"))))
    if camper_pose == "roast":
        px, py = cam.at(CAMP["log"][0] + 0.15, CAMP["log"][1] + 0.02)
        if new_camper:
            items.append((CAMP["log"][1] + 0.01, person(px, py, cam.person, shirt="#6fb7d6", hair="#2c2a33", pose="sit",
                                                        face="laugh", prop="stick", shadow=False)))
        else:
            items.append((CAMP["log"][1] + 0.01, camper(px, py, cam.person, "sit", face="laugh", prop="stick", shadow=False)))
    return "".join(bg), items


# --- The to-do list ----------------------------------------------------------------

def doodle(kind, iw=4.0):
    """Ink doodles for the task cards, in a box about 80 units wide."""
    ink = dict(stroke=P["ink"], stroke_width=iw, stroke_linejoin="round", stroke_linecap="round")
    if kind == "marshmallows":
        return (path("M -30 -18 Q -32 40 0 42 Q 32 40 30 -18 Z", "#fbe9ef", **ink)
                + path("M -18 -18 L -8 -32 L 0 -22 L 8 -32 L 18 -18", **ink)
                + rect(-20, 0, 16, 14, P["white"], rx=5, **ink) + rect(2, 10, 16, 14, P["white"], rx=5, **ink))
    if kind == "cocoa":
        return (rect(-30, -14, 44, 48, "#e9dcc2", rx=6, **ink) + path("M 14 -4 Q 34 -4 34 10 Q 34 24 14 22", **ink)
                + ellipse(-8, -12, 19, 5, "#7a5236") + path("M -18 -24 q -6 -8 0 -16 M -4 -26 q -6 -8 0 -16", **ink)
                + circle(30, -30, 4, "#7a5236") + circle(38, -18, 3, "#7a5236"))
    if kind == "sock":
        return (path("M -36 -36 L -12 -36 L -12 6 Q -12 22 4 24 L 18 24 Q 30 24 30 36 Q 30 44 18 44 L -8 44 "
                     "Q -36 44 -36 16 Z", "#e8e2f0", **ink)
                + line(-36, -26, -12, -26, P["ink"], iw) + rect(16, -36, 20, 16, P["white"], rx=6, **ink)
                + path("M 4 -14 Q 22 -4 26 6", **ink) + path("M 20 2 L 26 6 L 28 -1", **ink))
    if kind == "speaker":
        # Music off: the speaker unplugged, and a crossed-out note.
        return (rect(-38, -38, 40, 70, "#3a3d4a", rx=6, **ink) + circle(-18, -18, 8, "#7a7f99", **ink)
                + circle(-18, 12, 12, "#7a7f99", **ink) + path("M 2 26 Q 26 26 30 4", **ink)
                + rect(26, -8, 14, 12, "#3a3d4a", rx=2, **ink)
                + ellipse(17, -24, 6.5, 5, P["ink"], rot=-20) + line(22.5, -26, 22.5, -46, P["ink"], iw * 0.8)
                + path("M 22.5 -46 Q 32 -42 30 -33", **ink) + line(8, -48, 40, -18, P["ink"], iw))
    if kind == "tent":
        return (g(path("M -36 34 L 2 -30 L 36 34 Z", "#e2c79a", **ink), path("M 2 -30 L 2 34", **ink),
                  transform="rotate(-14)")
                + path("M -30 -36 q 6 -6 12 0 M 22 -38 q 6 -6 12 0", **ink))
    if kind == "dumpster":
        # The diner dumpster, lid up, a fish bone poking out.
        return (path("M -38 -4 L -28 -32 L 40 -24 L 36 -4 Z", "#9cc2a8", **ink)
                + path("M -36 -4 L 36 -4 L 30 38 L -30 38 Z", "#7fa58c", **ink)
                + line(-20, -12, 12, -22, P["ink"], iw) + line(-8, -24, -4, -10, P["ink"], iw * 0.7)
                + line(2, -28, 4, -14, P["ink"], iw * 0.7) + path("M 12 -22 L 24 -32 L 24 -14 Z", P["paper"], **ink)
                + path("M -26 -40 q -6 -8 0 -16 M -10 -44 q -6 -8 0 -16", **ink))
    if kind == "bungee":
        # A bin strapped shut with a bungee cord.
        return (rect(-28, -16, 56, 54, "#c4ccd3", rx=6, **ink) + line(-28, 6, 28, 6, P["ink"], iw * 0.7)
                + ellipse(0, -18, 34, 10, "#dfe5ea", **ink) + rect(-9, -32, 18, 9, "#c4ccd3", rx=3, **ink)
                + path("M -34 14 Q -6 -52 34 2", stroke=P["ink"], stroke_width=iw * 2.6, stroke_linecap="round")
                + path("M -34 14 Q -6 -52 34 2", stroke=P["bungee"], stroke_width=iw * 1.4, stroke_linecap="round"))
    if kind == "barbecue":
        # A grill with a string of sausages and smoke.
        return (path("M -34 -4 A 34 26 0 0 0 34 -4 Z", "#3a3d4a", **ink) + line(-36, -4, 36, -4, P["ink"], iw)
                + line(-16, 18, -24, 40, P["ink"], iw) + line(16, 18, 24, 40, P["ink"], iw) + line(0, 22, 0, 40, P["ink"], iw)
                + path("M -28 -10 Q -20 -22 -10 -10 Q 0 -22 10 -10 Q 20 -22 30 -10", stroke=P["ink"],
                       stroke_width=iw * 3.2, stroke_linecap="round")
                + path("M -28 -10 Q -20 -22 -10 -10 Q 0 -22 10 -10 Q 20 -22 30 -10", stroke=P["sausage"],
                       stroke_width=iw * 2, stroke_linecap="round")
                + path("M -10 -28 q -6 -8 0 -16 M 8 -30 q -6 -8 0 -16", **ink))
    return ""


def card(cx, cy, kind, s=1.0, done=False, active=False):
    parts = []
    if active:
        parts.append(rect(-58, -58, 116, 116, "none", rx=18, stroke=P["glow"], stroke_width=9, opacity=0.95))
    parts += [rect(-48, -48, 96, 96, P["paper"], rx=12, **ol(3 / s)), g(doodle(kind), transform="scale(0.72)"),
              circle(34, -34, 9, P["paper"], stroke=P["ink"], stroke_width=3)]
    if done:
        parts += [path("M 28 -35 L 33 -29 L 42 -42", stroke=P["ink"], stroke_width=4, stroke_linecap="round",
                       stroke_linejoin="round"),
                  path("M -38 10 L 30 -18 M -36 24 L 34 -6 M -30 36 L 36 6", stroke=P["ink"], stroke_width=5,
                       stroke_linecap="round", opacity=0.85)]
    return g(*parts, transform=place(cx, cy, s))


def hud(done=(), active=None, slide=False, tasks=TASKS):
    """The to-do cards along the top right of the game screen."""
    s, size, gap = 0.6, 96 * 0.6, 12
    n = len(tasks)
    x0, y0 = W - 36 - n * size - (n - 1) * gap, 30
    out = []
    for i, (kind, _) in enumerate(tasks):
        x = x0 + i * (size + gap) + (18 * (n - 1 - i) if slide else 0)
        out.append(card(x + size / 2, y0 + size / 2, kind, s, done=kind in done, active=kind == active))
    if slide:
        out.append(speed_lines(W - 20, y0 + size / 2, 0, 40, 4, 12, width=3))
    return "".join(out)


def acorn(x, y, s=1.0, rot=0.0):
    o = ol(2.4 / s)
    return g(ellipse(0, 6, 10, 13, "#c9955a", **o), path("M -12 0 Q -12 -12 0 -12 Q 12 -12 12 0 Z", "#6e4b31", **o),
             line(0, -12, 2, -18, "#6e4b31", 3), transform=place(x, y, s, rot))


def cricket(x, y, s=1.0, flip=1):
    o = ol(1.6 / s)
    return g(ellipse(0, 0, 14, 6, "#5c7a4a", **o), circle(13, -1, 4.5, "#5c7a4a", **o),
             line(-4, 3, -14, 12, P["outline"], 1.8), line(2, 4, -2, 12, P["outline"], 1.8),
             line(-6, -2, -20, 10, P["outline"], 2), line(15, -4, 26, -14, P["outline"], 1.4),
             vibration(26, -12, 8, 2, 7, -60, 40, width=2), transform=place(x, y, s, 0, flip))


# --- Panels --------------------------------------------------------------------------

def panel_good_vibrations(pid):
    """Good vibrations: asleep in his hole, the bass bounces him awake."""
    d = Defs(pid)
    out = [rect(0, 0, W, H, "#22181a"), ellipse(1180, 250, 900, 700, d.radial("spill", "#ff9d5c", 0.32))]
    for r in (1100, 960, 820, 680):
        out.append(ellipse(520, 1040, r, r * 0.6, "none", stroke="#2e2120", stroke_width=12))
    out.append(ellipse(620, 900, 690, 130, "#3b2a20"))
    rng = random.Random(3)
    for _ in range(46):
        x, y = rng.uniform(30, 1250), rng.uniform(800, 892)
        out.append(line(x, y, x + rng.uniform(-30, 30), y + rng.uniform(-8, 8), "#5a4330", 4))

    ox, oy, rx, ry = 1190, 255, 255, 180
    out += [ellipse(ox, oy, rx + 34, ry + 34, "#3d2c25", **ol(4)),
            ellipse(ox, oy, rx, ry, d.radial("outside", "#ffd08a", 1.0, "#6a4a8a", 1.0))]
    halo = d.radial("bulb", P["bulb"], 0.65)
    outside = []
    for i in range(9):
        t = i / 8
        bx, by = ox - 215 + 430 * t, oy - 80 + 70 * (1 - (2 * t - 1) ** 2)
        outside += [circle(bx, by, 24, halo), circle(bx, by, 7, P["bulb"])]
    for sx, pose in ((1070, "dance"), (1185, "dance2"), (1300, "dance")):
        outside.append(person_front(sx, 470, 0.7, shirt="#2a2036", pants="#2a2036", hair="#2a2036", skin="#2a2036",
                                    pose=pose, back=True, shadow=False))
    out.append(g(*outside, clip_path=d.clip("open", ellipse(ox, oy, rx, ry, "#000"))))
    for x, y, r in ((1000, 360, -16), (900, 300, 12), (820, 395, -8)):
        out.append(note(x, y, 1.6, P["bulb"], r))
    out += [vibration(70, 520, 50, 3, 30, -50, 50), vibration(460, 60, 40, 3, 26, 30, 150),
            vibration(1540, 640, 40, 3, 26, 130, 230)]
    for i, (ax, ay) in enumerate(((1060, 846), (1100, 852), (1140, 846), (1080, 826), (1122, 826), (1166, 852), (1101, 806))):
        out.append(acorn(ax, ay, 1.5, (i * 37) % 60 - 30))

    rx0, ry0 = 600, 760
    out += [ellipse(rx0 + 40, 862, 250, 26, P["shadow"], opacity=0.5), bounce_marks(rx0 + 40, 830, 250),
            raccoon_curled(rx0, ry0, 1.9, eyes="wide")]
    for ax, ay, r in ((880, 560, 30), (980, 470, -20), (1060, 610, 10), (520, 520, -40)):
        out += [acorn(ax, ay, 1.5, r), speed_lines(ax, ay + 26, 90, 30, 2, 12, width=3)]
    head_x, head_y = rx0 + 72 * 1.9, ry0 - 86 * 1.9 - 95
    out += [burst(head_x, head_y - 8, 34), acorn(head_x + 6, head_y - 30, 1.5, -25),
            pop_lines(head_x, ry0 - 86 * 1.9, 110, 7, -170, -10)]
    return d.svg(), "".join(out)


def tree_hole_frame():
    """Bark around the opening of his hole, filling the lower-left foreground."""
    bark = path("M 0 340 Q 90 470 160 600 Q 250 760 470 840 Q 640 895 760 900 L 0 900 Z", P["trunk"], **ol(5))
    lines = "".join(path(f"M {x} {y} q 30 40 70 70", stroke=P["bark"], stroke_width=8, stroke_linecap="round")
                    for x, y in ((30, 520), (90, 650), (180, 760), (60, 760), (320, 840)))
    lip = path("M 0 340 Q 90 470 160 600 Q 250 760 470 840 Q 640 895 760 900", stroke=P["hole"], stroke_width=16)
    leaves = "".join(circle(x, y, r, P["foliage"]) for x, y, r in ((-40, -30, 190), (150, -60, 150), (-60, 170, 140)))
    return leaves + bark + lines + lip


def panel_party_below(pid, epilogue=False):
    """Party below: he peeks out at the party under his tree. The epilogue reuses this framing."""
    d = Defs(pid)
    cam = Cam(1.0, -1.5, 70, cy=H * 0.4)
    bg, items = party(cam, d, crowd=NEW_CROWD if epilogue else CROWD, vehicle="van" if epilogue else "wagon",
                      tree=False, new_camper=epilogue)
    out = [bg, depth(items), tree_hole_frame()]
    if epilogue:
        out.append(raccoon_over_shoulder(330, 690, 2.0))
        out.append(iris(560, 540, 560))
    else:
        gx, gy = cam.at(*CAMP["grill"])
        out += [wisp([(gx + 10, gy - 70), (gx - 20, gy + 60), (gx - 60, gy + 170), (430, 560)], width=5),
                raccoon_back(330, 700, 2.0), pop_lines(330, 700, 130, 5, -60, 10, width=5)]
    return d.svg(), "".join(out)


def panel_dropping_in(pid):
    """Dropping in: he slides down his trunk into the party; the to-do cards slide in."""
    d = Defs(pid)
    cam = Cam(-1.7, -0.8, 88)
    bg, items = party(cam, d)
    tx, ty = cam.at(*CAMP["tree"])
    s = cam.racc * 1.15
    rx, ry = tx - 104 * s, ty - 120
    items.append((CAMP["tree"][1] + 0.02,
                  speed_lines(tx, ry - 230 * s - 10, -90, 80, 4, 16)
                  + raccoon(rx, ry, s, pose="stand", rot=90, shadow=False, eyes="wide", mouth="grin")))
    out = [bg, depth(items), dust(tx + 40, ty + 4, 0.9), arrow([(tx + 70, ty - 150), (tx + 120, ty - 40), (tx + 150, ty + 20)],
                                                                width=5, dash="10 10"),
           hud(slide=True)]
    return d.svg(), "".join(out)


def panel_things_to_do(pid):
    """Things to do: the to-do list close up; his paw picks a task."""
    d = Defs(pid)
    out = [rect(0, 0, W, H, "#1b2238")]
    rng = random.Random(5)
    for _ in range(46):
        out.append(circle(rng.uniform(0, W), rng.uniform(0, H), rng.uniform(20, 75),
                          rng.choice([P["bulb"], "#ff9d5c", "#8fb5ff", "#c98fb5"]), opacity=round(rng.uniform(0.08, 0.24), 2)))
    sheet = [rect(-440, -390, 880, 780, P["paper"], rx=18, **ol(4)),
             rect(-80, -414, 160, 44, "#e8dcc0", rx=6, opacity=0.92, transform="rotate(-3)"),
             g(path("M 0 8 Q -14 8 -14 -4 Q -14 -14 0 -12 Q 14 -14 14 -4 Q 14 8 0 8 Z", P["ink"]),
               circle(-15, -22, 6, P["ink"]), circle(-5, -28, 6, P["ink"]), circle(6, -28, 6, P["ink"]), circle(16, -22, 6, P["ink"]),
               transform="translate(-360 -320) scale(1.4)"),
             g(path("M -40 -6 Q -20 -22 0 -8 Q 20 -22 40 -6 Q 22 10 0 2 Q -22 10 -40 -6 Z", P["ink"]),
               circle(-18, -6, 5, P["paper"]), circle(18, -6, 5, P["paper"]), transform="translate(-250 -322) scale(1.3)")]
    for i, (kind, label) in enumerate(TASKS):
        y = -230 + i * 128
        sheet += [circle(-372, y, 22, P["paper"], stroke=P["ink"], stroke_width=4),
                  g(doodle(kind, 4.5), transform=f"translate(-270 {y}) scale(0.95)"),
                  text(-195, y + 16, label, 46, P["ink"], FONT_HAND, "start"),
                  line(-400, y + 62, 400, y + 62, "#d9cdb2", 3, stroke_dasharray="6 10")]
    out.append(g(*sheet, transform="translate(800 470) rotate(-2)"))
    out.append(g(rect(-200, -9, 400, 18, "#f2c14e", rx=3, **ol(3)), poly([(200, -9), (240, 0), (200, 9)], "#e8cfa5", **ol(3)),
                 rect(-222, -9, 26, 18, "#e8a0a0", rx=3, **ol(3)), transform="translate(1240 810) rotate(-28)"))
    # His paw taps the fourth task's checkbox.
    out += [line(250, 990, 372, 740, P["outline"], 72), line(250, 990, 372, 740, P["racc_dark"], 64),
            pointing_paw(400, 698, -55, 1.6), vibration(440, 640, 30, 2, 16, -170, -60, P["spark"], 5)]
    return d.svg(), "".join(out)


def pointing_paw(x, y, rot, s=1.0):
    """A raccoon's hand-like paw, index finger out along +x to (44, 0)."""
    o = ol(3.5 / s)
    parts = [ellipse(-30, 0, 34, 28, P["mask"], **o)]
    for fy, length, a in ((-20, 24, -38), (14, 26, 22), (24, 20, 46)):
        parts.append(g(rect(0, -6, length, 12, P["mask"], rx=6, **o), transform=f"translate(-12 {fy}) rotate({a})"))
    parts.append(rect(-10, -7, 54, 14, P["mask"], rx=7, **o))
    return g(*parts, transform=place(x, y, s, rot))


def panel_paws_on_the_zipper(pid):
    """Paws on the zipper: he works the backpack zipper while the party has its back to him."""
    d = Defs(pid)
    cam = Cam(-2.3, 1.0, 185, cy=H * 0.56)
    crowd = CROWD + [dict(at=(-3.75, 0.55), shirt="#c98fb5", hair="#3b2a20", pose="dance", back=True)]
    bg, items = party(cam, d, crowd=crowd, backpack_state="open")
    rx, ry = cam.at(-3.08, 1.66)
    s = cam.racc
    items.append((1.66, raccoon(rx, ry, s, pose="rear", eyes="wide", sweating=True)
                  + freeze_marks(rx + 30 * s, ry - 190 * s, 70 * s)))
    ex, ey = cam.at(-3.75, 0.55)
    whoosh = (arrow([(ex + 60, ey - 300), (ex + 150, ey - 250), (ex + 170, ey - 170)], color=P["fx"], width=5, dash="4 12", head=16)
              + speed_lines(ex + 40, ey - 300, 200, 40, 3, 12, width=3))
    out = [bg, depth(items), whoosh, hud(active="marshmallows")]
    return d.svg(), "".join(out)


def panel_music_off(pid):
    """Music off: he yanks the plug; the party freezes mid-move."""
    d = Defs(pid)
    cam = Cam(2.3, -0.7, 185, cy=H * 0.56)
    crowd = [dict(at=(1.0, -2.0), shirt="#9b8fc9", hair="#2d2a3a", pose="freeze", face="o"),
             dict(at=(2.75, -2.35), shirt="#e48a6a", hair="#5a3d33", pose="freeze2", face="o"),
             dict(at=(4.6, -1.5), shirt="#8fb59a", hair="#2f2a24", pose="freeze", face="o")]
    bg, items = party(cam, d, crowd=crowd, speaker_state="off", camper_pose=None)
    sx, sy = cam.at(*CAMP["speaker"])
    rx, ry = cam.at(1.6, 0.3)
    s = cam.racc
    mouth = (rx - 166 * s, ry - 100 * s)
    cord = path(f"M {num(sx - 0.31 * cam.k)} {num(sy - 0.12 * cam.k)} Q {num((sx + mouth[0]) / 2)} {num(sy + 70)} "
                f"{num(mouth[0])} {num(mouth[1])}", stroke="#1d1f26", stroke_width=7, stroke_linecap="round")
    items.append((0.3, cord + raccoon(rx, ry, s, facing=-1, pose="slink", held="plug", eyes="open", mouth=None)))
    qx, qy = cam.at(0.55, 0.9)
    items.append((0.9, person(qx, qy, cam.person, facing=-1, shirt="#6fb7d6", hair="#2c2a33", pose="stand", face="o",
                              prop="stick_drop")))
    for fx_, fz_ in ((1.0, -2.0), (2.75, -2.35), (4.6, -1.5)):
        px, py = cam.at(fx_, fz_)
        items.append((fz_ + 0.01, freeze_marks(px, py - 1.2 * cam.person * 160, 40)))
    out = [bg, depth(items)]
    for cx, cy in ((260, 820), (1300, 790), (930, 868)):
        out.append(cricket(cx, cy, 1.3))
    out += [hud(done=("speaker",), active="speaker"), burst(W - 36 - 96 * 0.6 * 1.5 - 12 * 1, 30 + 96 * 0.6 + 6, 18)]
    return d.svg(), "".join(out)


def panel_busted(pid):
    """Busted: with the music off, the bag's crinkle gives him away; the camper looms in with his phone light."""
    d = Defs(pid)
    out = [rect(0, 0, W, H, d.vertical("sky", P["sky_top"], P["sky_low"]))]
    rng = random.Random(8)
    for _ in range(60):
        out.append(circle(rng.uniform(0, W), rng.uniform(0, 420), rng.uniform(1.2, 2.6), P["star"], opacity=0.8))
    out += [poly([(1240, 742), (1440, 470), (1640, 742)], "#2a2a4a"),
            string_lights(-40, 130, 1640, 60, 70, 220, d, bulbs=16),
            ellipse(-60, 760, 760, 520, d.radial("fire", P["glow"], 0.55)),
            path("M 0 742 Q 800 720 1600 742 L 1600 900 L 0 900 Z", P["ground"]),
            ellipse(-60, 820, 700, 200, d.radial("fireground", P["glow"], 0.35))]
    out.append(cooler(1276, 862, 280, hv=1.0))
    out.append(speed_lines(1170, 280, 0, 120, 4, 26))
    out.append(camper(900, 1027, 4.0, "lunge", facing=-1, face="o", prop="phone_light"))
    out.append(burst(1194, 742, 30))
    rx, ry = 330, 850
    out.append(raccoon(rx, ry, 1.1, pose="startled", spiky=True, eyes="wide", mouth="o", double_take=True))
    out += [pop_lines(rx + 120, ry - 300, 90, 7, -170, -10, width=5),
            arrow([(rx + 150, ry - 250), (rx + 170, ry - 400), (440, 400)], color=P["fx"], width=5, dash="4 12", head=16),
            g(rect(-30, -38, 60, 76, "#f6eef2", rx=12, **ol(3)), rect(-30, -6, 60, 10, "#f2b8c8"),
              transform="translate(420 330) rotate(-28)"),
            # Crinkle: in the quiet, the bag is the loudest thing at the party.
            vibration(420, 330, 56, 3, 16, -50, 30, P["fx"], 5), vibration(420, 330, 56, 3, 16, 150, 230, P["fx"], 5)]
    for mx, my, r in ((350, 260, 20), (500, 290, -30), (470, 220, 50), (330, 360, 10), (530, 380, -12)):
        out.append(rect(mx - 11, my - 9, 22, 18, P["white"], rx=6, transform=f"rotate({r} {mx} {my})", **ol(2.5)))
    return d.svg(), "".join(out)


def panel_the_red_beanie(pid):
    """The red beanie: the getaway after the bust; partiers trip and bonk; he swipes the camper's beanie and bolts."""
    d = Defs(pid)
    out = [rect(0, 0, W, H, d.vertical("sky", P["sky_top"], P["sky_low"])), circle(1320, 150, 58, P["moon"]),
           circle(1320, 150, 110, d.radial("moon", P["moon"], 0.25))]
    rng = random.Random(9)
    for _ in range(50):
        out.append(circle(rng.uniform(0, W), rng.uniform(0, 420), rng.uniform(1.2, 2.5), P["star"], opacity=0.8))
    hills = "M 0 560 " + " ".join(f"Q {x + 60} {500 + (x * 7) % 50} {x + 120} 560" for x in range(0, 1600, 120)) + " L 1600 640 L 0 640 Z"
    out += [path(hills, "#18323a"), rect(0, 600, W, 300, P["ground"]),
            ellipse(80, 660, 520, 320, d.radial("fire", P["glow"], 0.5)),
            path("M 0 780 Q 800 740 1600 790 L 1600 840 Q 800 790 0 830 Z", P["clearing"]),
            tent(130, 720, 150, hv=1.0)]
    for x in (1390, 1470, 1545):
        out.append(rect(x, 300, 46, 560, P["trunk_dark"]))
    out.append(circle(1500, 300, 230, P["foliage"]))
    out += [line(230, 610, 470, 812, "#d8cfb5", 4), line(470, 812, 470, 790, P["outline"], 5),
            person(300, 800, 1.2, facing=1, shirt="#8fb59a", hair="#2f2a24", pose="trip", face="o", rot=-6),
            burst(420, 790, 22)]
    out += [person(575, 830, 1.3, facing=1, shirt="#9b8fc9", hair="#2d2a3a", pose="reel", face="o"),
            person(690, 830, 1.3, facing=-1, shirt="#e48a6a", hair="#5a3d33", pose="reel", face="o"),
            burst(632, 588, 30)]
    cx, cy = 930, 836
    out += [path(f"M {cx + 60} {cy - 330} Q {cx + 230} {cy - 260} {cx + 200} {cy - 40}", stroke=P["fx"], stroke_width=6,
                 stroke_dasharray="18 12", stroke_linecap="round", opacity=0.8),
            camper(cx, cy, 1.45, "chase", facing=1, beanie=False, face="grit", prop="pan", messy=True)]
    rx, ry = 1290, 846
    out += [wisp([(cx + 40, cy - 330), (1120, 560), (rx + 136, ry - 106)], color=P["spark"], width=5),
            dust(rx - 210, ry - 10, 0.8), dust(rx - 330, ry, 0.6),
            speed_lines(rx - 120, ry - 90, 180, 100, 4, 20),
            raccoon(rx, ry, 0.8, facing=1, pose="run", held="beanie", eyes="open")]
    return d.svg(), "".join(out)


def trash_bag(x, y, s=1.0, rot=0.0):
    """A knotted bin bag. (x, y) is the ground under it."""
    o = ol(3 / s)
    return g(path("M -40 0 Q -50 -50 -14 -62 Q 0 -66 14 -62 Q 50 -50 40 0 Z", P["trash"], **o),
             path("M -10 -62 L -18 -82 L 0 -71 L 18 -84 L 10 -62 Z", P["trash"], **o),
             path("M -26 -38 Q -22 -52 -8 -55", stroke="#5d7a75", stroke_width=5, stroke_linecap="round"),
             transform=place(x, y, s, rot))


def car_front(x, y, s, color):
    """A town car coming head-on with its headlights on. (x, y) is the road under its front."""
    o = ol(3 / s)
    beams = (poly([(-52, -44), (-660, 420), (-80, 420)], P["beam"], opacity=0.16)
             + poly([(52, -44), (80, 420), (660, 420)], P["beam"], opacity=0.16))
    return g(beams, rect(-74, -64, 148, 52, color, rx=14, **o),
             path("M -54 -64 L -40 -100 L 40 -100 L 54 -64 Z", P["glass"], **o),
             rect(-82, -28, 164, 16, shade(color, 0.7), rx=6, **o),
             circle(-52, -44, 12, "#fff4c4", **o), circle(52, -44, 12, "#fff4c4", **o),
             rect(-66, -14, 24, 16, P["tire"], rx=4), rect(42, -14, 24, 16, P["tire"], rx=4),
             transform=place(x, y, s))


def panel_edge_of_town(pid):
    """Edge of town: out of the trees at his height; the town roars, but there are trash bags everywhere."""
    d = Defs(pid)
    hz = 560  # the horizon, at his eye height; the road runs off towards (980, hz)
    out = [rect(0, 0, W, H, d.vertical("sky", P["sky_top"], "#4a3f72")),
           ellipse(1180, hz, 980, 300, d.radial("glow", "#ffb36b", 0.42))]
    rng = random.Random(14)
    for _ in range(36):
        out.append(circle(rng.uniform(0, 620), rng.uniform(0, 400), rng.uniform(1.2, 2.4), P["star"], opacity=0.8))
    # The town along the horizon, and its water tower.
    for hx_, hw, hh, col in ((600, 120, 70, "#2c3358"), (720, 150, 96, "#323a62"), (870, 90, 60, "#2c3358"),
                             (1420, 130, 80, "#323a62")):
        out.append(rect(hx_, hz - hh, hw, hh, col))
        for wx in range(int(hx_) + 16, int(hx_ + hw) - 24, 36):
            out.append(rect(wx, hz - hh + 20, 14, 18, "#ffe7a8", opacity=0.85))
    tower = "#262c4a"
    out += [line(1494, hz, 1506, 420, tower, 10), line(1550, hz, 1538, 420, tower, 10),
            rect(1464, 330, 116, 92, tower, rx=22), poly([(1460, 340), (1522, 292), (1584, 340)], tower),
            ellipse(790, 468, 130, 70, d.radial("siren", "#4d8dff", 0.55)), circle(790, 470, 7, "#9cc4ff")]
    # Verge, road and sidewalk.
    out += [poly([(0, hz), (965, hz), (300, H), (0, H)], P["ground"]),
            poly([(995, hz), (W, hz), (W, H), (1300, H)], "#4b5059"),
            poly([(300, H), (965, hz), (995, hz), (1300, H)], P["asphalt"]),
            line(800, H, 980, hz, "#d9c36a", 7, stroke_dasharray="46 34", opacity=0.8)]
    for _ in range(40):
        tx, ty = rng.uniform(0, 700), rng.uniform(hz + 10, H)
        if tx < 965 - 665 * (ty - hz) / 340 - 20:
            out.append(tuft(tx, ty, 1.0 + (ty - hz) / 200))
    # The diner from the alley, its neon cup buzzing on the roof.
    out += [rect(1080, 500, 340, 112, "#5a6476", **ol(3)), rect(1072, 492, 356, 18, "#3f4757", **ol(3))]
    for wx in (1096, 1166, 1236, 1306):
        out.append(rect(wx, 524, 56, 46, "#ffe7a8", **ol(2.5)))
    out += [rect(1366, 530, 40, 82, "#3f4757", **ol(2.5)),
            g(path(NEON_CUP, stroke=P["neon_pink"], stroke_width=16, opacity=0.25), path(NEON_CUP, stroke=P["neon_pink"], stroke_width=5),
              transform="translate(1250 438) scale(0.8) translate(-334 -50)"),
            path("M 1310 400 l 9 -7 l 0 12 l 9 -7 M 1180 404 l -9 -7 l 0 12 l -9 -7", stroke=P["neon_pink"], stroke_width=3,
                 stroke_linecap="round")]
    for sx, sy, h in ((1150, 618, 96), (1300, 690, 200), (1560, 880, 430)):
        arm = sx - h * 0.18
        out += [poly([(arm, sy - h), (arm - h * 0.42, sy), (arm + h * 0.42, sy)], P["street"], opacity=0.1),
                line(sx, sy, sx, sy - h, "#3a3e46", max(3, h * 0.035)), line(sx, sy - h, arm, sy - h, "#3a3e46", max(3, h * 0.03)),
                ellipse(arm, sy - h + 2, h * 0.07, h * 0.025, P["street"])]
    for bx, by, s, n in ((1060, 614, 0.3, 2), (1190, 680, 0.55, 3)):
        for i in range(n):
            out.append(trash_bag(bx + (i - (n - 1) / 2) * 70 * s, by - (i % 2) * 14 * s, s, (i * 23) % 30 - 15))
    out += [car_front(905, 700, 0.62, "#e8b84a"), vibration(842, 640, 22, 3, 16, 160, 220, P["fx"], 4)]
    out.append(bin_can(1270, 772, 110))
    for bx, by, s, n in ((1420, 846, 1.05, 3), (470, 886, 0.95, 2)):
        for i in range(n):
            out.append(trash_bag(bx + (i - (n - 1) / 2) * 70 * s, by - (i % 2) * 14 * s, s, (i * 23) % 30 - 15))

    # The forest he came out of, still and dark, with fireflies.
    fly = d.radial("fly", "#e9ff8a", 0.6)
    out += [rect(-20, 0, 90, 900, P["trunk_dark"]), rect(150, 0, 54, 880, P["trunk_dark"])]
    for fx, fy, r in ((40, 40, 230), (260, 10, 170), (-60, 330, 200), (390, -50, 150)):
        out.append(circle(fx, fy, r, P["foliage"]))
    for fx, fy in ((230, 380), (90, 540), (320, 300), (40, 700)):
        out += [circle(fx, fy, 16, fly), circle(fx, fy, 3.5, "#f4ffb8")]
    out.append(ellipse(150, 870, 170, 64, P["foliage2"]))

    # He stops at the edge: the noise rolls in, and so does the smell.
    rx, ry, rs = 250, 856, 0.85
    mx, my = raccoon_mouth(rx, ry, rs, 1, "rear")
    out += [wisp([(470, 800), (430, 740), (mx + 50, my + 6), (mx + 8, my)], width=5),
            raccoon(rx, ry, rs, pose="rear", beanie=True, eyes="wide", mouth="grin"),
            vibration(mx + 10, my - 70, 40, 3, 18, -60, 30, P["fx"], 4)]
    return d.svg(), "".join(out)


def bin_can(x, y, k, lid=True, bungee=True):
    sw = max(2, 0.03 * k)
    o = ol(sw)
    w, h = 0.6 * k, 0.72 * k
    out = [ellipse(x, y + 4, w * 0.7, 0.12 * k, P["shadow"], opacity=0.45),
           rect(x - w / 2, y - h, w, h, P["bin"], rx=0.04 * k, **o)]
    for f in (0.3, 0.62):
        out.append(line(x - w / 2 + 4, y - h * f, x + w / 2 - 4, y - h * f, P["bin_dark"], max(2, 0.025 * k)))
    if lid:
        out += [ellipse(x, y - h, w * 0.56, 0.12 * k, P["bin"], **o), rect(x - 0.08 * k, y - h - 0.09 * k, 0.16 * k, 0.05 * k, P["bin_dark"], **o)]
        if bungee:
            out += [path(f"M {num(x - w / 2)} {num(y - h * 0.6)} Q {num(x)} {num(y - h - 0.2 * k)} {num(x + w / 2)} {num(y - h * 0.6)}",
                         stroke=P["bungee"], stroke_width=max(3, 0.04 * k), stroke_linecap="round")]
    else:
        out.append(ellipse(x, y - h, w * 0.56, 0.12 * k, "#23262c", **o))
    return "".join(out)


def panel_the_masked_bandit(pid):
    """The masked bandit: in town, a bungee twangs the bin lid into the air; phones come out."""
    d = Defs(pid)
    out = [rect(0, 0, W, 330, P["brick"])]
    for row, y in enumerate(range(0, 330, 26)):
        out.append(line(0, y, W, y, P["brick_line"], 3))
        for x in range(-60 + (30 if row % 2 else 0), W, 60):
            out.append(line(x, y, x, y + 26, P["brick_line"], 3))
    out += [rect(250, 110, 150, 222, "#4a3a3a", **ol(4)), rect(292, 140, 66, 46, "#ffe7a8", **ol(3)),
            circle(325, 96, 9, "#ffe7a8"), poly([(325, 100), (240, 330), (410, 330)], "#ffe7a8", opacity=0.12)]
    out += [path(NEON_CUP, stroke=P["neon_pink"], stroke_width=16, opacity=0.25), path(NEON_CUP, stroke=P["neon_pink"], stroke_width=5),
            path("M 310 12 q -8 -10 0 -20 M 330 12 q -8 -10 0 -20", stroke=P["neon_cyan"], stroke_width=5, stroke_linecap="round")]
    for wx in (880, 1110):
        out.append(rect(wx, 26, 150, 112, "#ffe7a8", **ol(4)))
    out += [watcher(955, 96, "#6fb7d6", P["hair"]), watcher(1185, 96, "#c98fb5", "#2c2a33", flip=-1)]
    for wx in (880, 1110):
        out.append(rect(wx - 8, 134, 166, 14, "#5a4545", **ol(3)))
    out += [burst(1000, 34, 26, P["white"]), burst(1140, 34, 26, P["white"]),
            rect(0, 330, W, 570, P["asphalt"]), rect(0, 330, W, 18, "#2f3238"),
            path("M 120 600 l 60 30 l -20 40 l 80 20", stroke="#3a3e46", stroke_width=5),
            ellipse(1100, 760, 140, 34, "#5d6878", opacity=0.6)]
    out += [rect(50, 380, 270, 150, "#56715f", rx=6, **ol(4)), rect(40, 362, 290, 30, "#466251", rx=6, **ol(4))]
    for bx_, by_ in ((360, 540), (410, 520), (390, 500)):
        out.append(ellipse(bx_, by_, 46, 34, "#22252b", **ol(3)))
    out += [bin_can(620, 520, 150), bin_can(1020, 520, 150)]
    out.append(poly([(1430, 250), (1180, 900), (1600, 900), (1600, 500)], P["street"], opacity=0.14))
    out.append(bin_can(820, 520, 150, lid=False))
    rx, ry = 820, 420
    out += [path(f"M {num(820 - 45)} {num(520 - 65)} Q 760 360 {num(rx + 40)} {num(ry - 60)}", stroke=P["bungee"], stroke_width=7,
                 stroke_linecap="round"),
            vibration(770, 410, 20, 3, 14, 150, 260, P["spark"], 4),
            raccoon(rx, ry, 0.55, pose="rear", beanie=True, eyes="wide", mouth="grin", shadow=False)]
    out += [g(ellipse(0, 0, 54, 18, P["bin"], **ol(3)), rect(-10, -14, 20, 8, P["bin_dark"], **ol(2)), transform="translate(520 200) rotate(-24)"),
            vibration(520, 200, 70, 2, 18, 120, 240, P["fx"], 4), speed_lines(600, 260, 30, 160, 4, 16)]
    out += [rect(1420, 230, 18, 670, "#3a3e46", **ol(3)), rect(1380, 220, 100, 26, "#3a3e46", rx=6, **ol(3)),
            ellipse(1430, 250, 34, 12, P["street"]),
            rect(1370, 520, 120, 150, P["paper"], **ol(3)), rect(1400, 512, 60, 16, "#e8dcc0", opacity=0.9),
            raccoon_face(1430, 600, 0.62, beanie=True, mouth="smirk"),
            hud(done=("dumpster",), active="bungee", tasks=TOWN_TASKS)]
    return d.svg(), "".join(out)


def watcher(x, y, shirt, hair, flip=1):
    """Someone leaning out of a window, phone held up to snap the bandit."""
    o = ol(3)
    parts = [ellipse(0, 40, 46, 30, shirt, **o), circle(0, 0, 24, P["skin"], **o),
             path("M -24 -2 Q -22 -28 0 -26 Q 22 -28 24 -2 Q 8 -14 -24 -2 Z", hair, **o),
             circle(-8, 0, 3, P["outline"]), circle(8, 0, 3, P["outline"]), ellipse(0, 11, 4.5, 5.5, P["outline"])]
    arm, hand = limb(30, 30, [(160, 30), (170, 28)], 13, shirt, 3)
    parts += [arm, circle(hand[0], hand[1], 7, P["skin"], **o), rect(hand[0] - 9, hand[1] - 30, 18, 30, "#22252c", rx=4, **o)]
    return g(*parts, transform=place(x, y, 1.0, 0, flip))


def emoji(x, y, r, mood):
    """A round yellow reaction face: 'shock' or 'laugh'."""
    o = ol(2)
    out = [circle(x, y, r, "#ffd166", **o)]
    if mood == "shock":
        out += [circle(x - r * 0.36, y - r * 0.2, r * 0.15, P["outline"]), circle(x + r * 0.36, y - r * 0.2, r * 0.15, P["outline"]),
                ellipse(x, y + r * 0.4, r * 0.2, r * 0.27, P["outline"])]
    else:
        for side in (-1, 1):
            ex = x + side * r * 0.36
            out.append(path(f"M {num(ex - r * 0.18)} {num(y - r * 0.12)} Q {num(ex)} {num(y - r * 0.42)} {num(ex + r * 0.18)} "
                            f"{num(y - r * 0.12)}", stroke=P["outline"], stroke_width=2.5, stroke_linecap="round"))
        out += [path(f"M {num(x - r * 0.5)} {num(y + r * 0.08)} Q {num(x)} {num(y + r * 0.8)} {num(x + r * 0.5)} {num(y + r * 0.08)} Z",
                     P["outline"]),
                ellipse(x - r * 0.82, y + r * 0.05, r * 0.14, r * 0.22, P["sweat"])]
    return "".join(out)


def avatar(x, y, color, r=22):
    """A chat avatar: a coloured circle with a head and shoulders, and no name."""
    return (circle(x, y, r, color, **ol(2.5)) + circle(x, y - r * 0.22, r * 0.36, P["skin"])
            + path(f"M {num(x - r * 0.62)} {num(y + r * 0.7)} Q {num(x)} {num(y - r * 0.05)} {num(x + r * 0.62)} {num(y + r * 0.7)} Z",
                   shade(color, 0.7)))


def panel_the_group_chat(pid):
    """The group chat: a neighbour's phone fills up with photos of the bandit, while he sits on the fence outside."""
    d = Defs(pid)
    out = [rect(0, 0, W, H, "#3b2c3c"), ellipse(140, 300, 560, 560, d.radial("lamp", "#ffcf8a", 0.32))]
    # Through the window: the bandit himself, on the back fence, by a bin he has already tipped over.
    wx0, wy0, ww, wh = 960, 80, 580, 560
    out += [rect(wx0, wy0, ww, wh, d.vertical("night", P["sky_top"], "#3a3f7a"), **ol(6)), circle(1452, 168, 40, P["moon"])]
    rng = random.Random(15)
    for _ in range(26):
        out.append(circle(rng.uniform(wx0 + 10, wx0 + ww - 10), rng.uniform(wy0 + 10, wy0 + 300), rng.uniform(1.2, 2.2),
                          P["star"], opacity=0.8))
    out.append(rect(wx0 + 3, wy0 + 470, ww - 6, wh - 473, P["ground"]))
    for fx in range(wx0 + 6, wx0 + ww - 30, 46):
        out.append(path(f"M {fx} {wy0 + 500} L {fx} {wy0 + 360} L {fx + 19} {wy0 + 344} L {fx + 38} {wy0 + 360} L {fx + 38} {wy0 + 500} Z",
                        "#6b5a4a", **ol(2.5)))
    out += [rect(wx0 + 3, wy0 + 388, ww - 6, 14, "#57493c"),
            bin_can(wx0 + 470, wy0 + 548, 90, lid=False),
            g(ellipse(0, 0, 34, 11, P["bin"], **ol(2.5)), transform=f"translate({wx0 + 390} {wy0 + 540}) rotate(14)"),
            raccoon(wx0 + 330, wy0 + 346, 0.42, facing=-1, pose="stand", beanie=True, mouth="grin", shadow=False),
            line(wx0 + 200, wy0, wx0 + 200, wy0 + wh, "#5a4450", 14), line(wx0, wy0 + 210, wx0 + ww, wy0 + 210, "#5a4450", 14),
            rect(wx0, wy0, ww, wh, "none", stroke="#5a4450", stroke_width=20),
            rect(wx0 - 24, wy0 + wh - 4, ww + 48, 26, "#5a4450", **ol(3)),
            path(f"M {wx0 - 40} {wy0 - 30} Q {wx0 + 30} {wy0 + 280} {wx0 - 10} {wy0 + wh + 20} L {wx0 - 80} {wy0 + wh + 20} "
                 f"L {wx0 - 80} {wy0 - 30} Z", "#7a5a6a", **ol(3))]

    # The phone, filling the frame. No words in the chat: only photos, emoji and faces.
    phone = [rect(-236, -420, 472, 840, "#22252c", rx=48, **ol(4)), rect(-212, -382, 424, 762, "#eef1f6", rx=26),
             rect(-212, -382, 424, 66, "#d9dee8", rx=26), rect(-212, -340, 424, 24, "#d9dee8"),
             avatar(-176, -349, "#9b8fc9", 16), avatar(-150, -349, "#4fb3a9", 16), avatar(-124, -349, "#f0a24a", 16)]
    for i in range(3):
        phone.append(circle(150 + i * 14, -349, 4, "#8a90a0"))
    # A photo of him in the diner dumpster.
    photo = [rect(-152, -300, 240, 124, P["white"], rx=16, **ol(2.5)), rect(-142, -290, 220, 104, "#2b3346", rx=10),
             raccoon_face(-30, -244, 0.42, eyes="wide"), rect(-112, -226, 164, 40, "#56715f", **ol(2)),
             rect(-120, -234, 180, 12, "#466251", **ol(2)), burst(46, -272, 12, P["white"])]
    phone += [avatar(-184, -250, "#9b8fc9")] + photo
    # Your reaction.
    phone += [rect(78, -164, 120, 58, "#8fc1e8", rx=18, **ol(2.5)), emoji(108, -135, 18, "shock"), emoji(166, -135, 18, "shock")]
    # The photo that goes round town: him in the beanie. A thumb goes to share it.
    phone += [avatar(-184, 30, "#4fb3a9"), rect(-152, -88, 290, 170, P["white"], rx=16, **ol(2.5)),
              rect(-142, -78, 270, 150, "#cfe6f2", rx=10), raccoon_face(-7, 4, 0.82, beanie=True, mouth="smirk"),
              burst(100, -56, 14, P["white"])]
    for i, mood in enumerate(("laugh", "laugh", "shock", "laugh")):
        phone.append(emoji(-118 + i * 34, 96, 15, mood))
    phone += [circle(176, -8, 22, "#d9dee8", **ol(2.5)),
              path("M 166 0 Q 168 -16 184 -16 M 178 -24 L 186 -16 L 178 -8", stroke=P["ink"], stroke_width=3.5,
                   stroke_linecap="round", stroke_linejoin="round")]
    # Someone has sent the animal-control van. Someone else is typing.
    phone += [avatar(-184, 196, "#f0a24a"), rect(-152, 132, 236, 112, P["white"], rx=16, **ol(2.5)),
              rect(-142, 142, 216, 92, "#2b3346", rx=10),
              g(van(0, 0, 22, hv=1.0, body="#e9e5da", top=P["carrier"], cargo=True), transform="translate(-34 222)"),
              avatar(-184, 302, "#8fb59a"), rect(-152, 280, 92, 44, P["white"], rx=22, **ol(2.5))]
    for i in range(3):
        phone.append(circle(-128 + i * 22, 302, 6, "#8a90a0"))
    phone += [rect(-198, 340, 396, 32, "#ffffff", rx=16, **ol(2)),
              # The neighbour's hand: fingers round the left edge, thumb reaching for the share button.
              ellipse(170, 560, 230, 150, P["skin"], **ol(4))]
    for fy in (100, 168, 236):
        phone.append(rect(-262, fy, 58, 54, P["skin"], rx=26, **ol(3.5)))
    phone += [path("M 280 470 Q 240 210 198 50", stroke=P["outline"], stroke_width=78, stroke_linecap="round"),
              path("M 280 470 Q 240 210 198 50", stroke=P["skin"], stroke_width=70, stroke_linecap="round"),
              ellipse(201, 64, 20, 28, "#f3cfb3", rot=-14),
              vibration(-250, -240, 30, 3, 18, 150, 210, P["fx"], 5), vibration(250, -300, 30, 3, 18, -30, 30, P["fx"], 5)]
    out.append(g(*phone, transform="translate(560 470) rotate(-5)"))
    return d.svg(), "".join(out)


def paw_logo(x, y, s=1.0, color=P["mask"]):
    """The animal-control paw print, on the carrier and the van."""
    return g(path("M 0 8 Q -10 8 -10 -2 Q -10 -10 0 -9 Q 10 -10 10 -2 Q 10 8 0 8 Z", color),
             circle(-10, -16, 4.5, color), circle(-3, -21, 4.5, color), circle(5, -21, 4.5, color),
             circle(12, -16, 4.5, color), transform=place(x, y, s))


def carrier(x, y, s=1.0):
    o = ol(3 / s)
    parts = [rect(-90, -110, 180, 110, P["carrier"], rx=16, **o), rect(-90, -110, 180, 30, P["carrier_dark"], rx=16, **o),
             rect(-30, -132, 60, 24, P["carrier_dark"], rx=10, **o), paw_logo(30, -45, 1.4),
             rect(-90, -100, 14, 92, "#1c1f26"),
             g(rect(0, 0, 18, 96, "#8a8f98", **o), *[line(4, y_, 14, y_, "#4a4f58", 3) for y_ in range(12, 92, 14)],
               transform="translate(-94 -102) rotate(-48)")]
    return g(*parts, transform=place(x, y, s))


def carrier_front(x, y, s, defs, inside=""):
    """The same carrier from the front, its door shut. `inside` is drawn behind the bars, in the carrier's
    own units: the door opening runs from (-82, -162) to (82, -18)."""
    o = ol(3 / s)
    opening = dict(x=-82, y=-162, width=164, height=144, rx=12)
    bars = "".join(line(bx, -162, bx, -18, P["outline"], 10) + line(bx, -162, bx, -18, "#9aa0a8", 6)
                   for bx in (-56, -28, 0, 28, 56))
    vents = "".join(line(124, -134 + i * 24, 166, -157 + i * 24, shade(P["carrier_dark"], 0.7), 6) for i in range(3))
    parts = [poly([(110, -180), (182, -220), (182, -40), (110, -2)], P["carrier_dark"], **o), vents,
             g(paw_logo(0, 0, 1.5), transform="translate(150 -84) skewY(-29) scale(0.75 1)"),
             poly([(-106, -180), (-34, -220), (182, -220), (110, -180)], P["carrier"], **o),
             path("M 6 -200 Q 42 -258 78 -200", stroke=P["outline"], stroke_width=20, stroke_linecap="round"),
             path("M 6 -200 Q 42 -258 78 -200", stroke=P["carrier_dark"], stroke_width=13, stroke_linecap="round"),
             rect(-110, -182, 220, 182, P["carrier"], rx=18, **o),
             rect(-110, -182, 220, 16, P["carrier_dark"], rx=8, **o),
             tag("rect", fill=P["hole"], **opening),
             g(inside, clip_path=defs.clip("door", tag("rect", **opening))),
             bars,
             tag("rect", fill="none", stroke=P["outline"], stroke_width=15, **opening),
             tag("rect", fill="none", stroke="#9aa0a8", stroke_width=10, **opening),
             rect(74, -106, 22, 32, "#9aa0a8", rx=4, **o)]
    return g(*parts, transform=place(x, y, s))


def bunting(x1, y1, x2, y2, sag, flags=18, size=34):
    """A string of pennants across the street. None of them is red: red belongs to the beanie."""
    cx, cy = (x1 + x2) / 2, (y1 + y2) / 2 + 2 * sag
    colors = (P["bulb"], "#4fb3a9", "#9b8fc9", "#f0a24a", "#8fc1e8")

    def at(t):
        return ((1 - t) ** 2 * x1 + 2 * (1 - t) * t * cx + t * t * x2,
                (1 - t) ** 2 * y1 + 2 * (1 - t) * t * cy + t * t * y2)

    out = [path(f"M {num(x1)} {num(y1)} Q {num(cx)} {num(cy)} {num(x2)} {num(y2)}", stroke=P["wire"], stroke_width=3)]
    for i in range(flags):
        (ax, ay), (bx, by) = at((i + 0.12) / flags), at((i + 0.88) / flags)
        out.append(poly([(ax, ay), (bx, by), ((ax + bx) / 2, (ay + by) / 2 + size)], colors[i % len(colors)], **ol(2)))
    return "".join(out)


def snack_table(x, y, w, s=1.0):
    """A block-party table under a gingham cloth, with a pie, a cake and a punch bowl. (x, y) is the ground at its middle."""
    o = ol(3 / s)
    left, top = -w / 2, -170
    out = [ellipse(0, 4, w * 0.56, 16, P["shadow"], opacity=0.45)]
    for lx in (left + 34, left + w - 34):
        out.append(line(lx, top + 120, lx, 0, P["outline"], 9))
    out.append(rect(left, top, w, 128, "#e3ebf6", **o))
    out += [rect(sx, top + 2, 18, 124, "#7d9bd1", opacity=0.4) for sx in range(int(left) + 12, int(left + w) - 18, 42)]
    out += [rect(left + 2, sy, w - 4, 16, "#7d9bd1", opacity=0.4) for sy in range(int(top) + 14, int(top) + 120, 40)]
    px, cx, bx = left + 74, left + 176, left + w - 96
    out += [ellipse(px, top - 8, 54, 15, "#b9773e", **o), ellipse(px, top - 12, 46, 11, "#e2b06a")]
    for i in (-2, -1, 0, 1, 2):
        out.append(line(px + i * 15 - 8, top - 20, px + i * 15 + 8, top - 4, "#b9773e", 4))
    out += [rect(cx - 42, top - 82, 84, 82, "#f6e3c2", rx=8, **o), rect(cx - 42, top - 46, 84, 10, "#fbe9ef"),
            path(f"M {num(cx - 42)} {num(top - 70)} Q {num(cx - 30)} {num(top - 54)} {num(cx - 18)} {num(top - 70)} "
                 f"Q {num(cx - 6)} {num(top - 54)} {num(cx + 6)} {num(top - 70)} Q {num(cx + 18)} {num(top - 54)} "
                 f"{num(cx + 30)} {num(top - 70)} Q {num(cx + 38)} {num(top - 58)} {num(cx + 42)} {num(top - 70)} "
                 f"L {num(cx + 42)} {num(top - 74)} Q {num(cx + 42)} {num(top - 82)} {num(cx + 34)} {num(top - 82)} "
                 f"L {num(cx - 34)} {num(top - 82)} Q {num(cx - 42)} {num(top - 82)} {num(cx - 42)} {num(top - 74)} Z",
                 "#fbe9ef", **o)]
    for i, col in enumerate(("#4fb3a9", P["bulb"], "#9b8fc9", "#8fc1e8")):
        out.append(rect(cx - 30 + i * 18, top - 30 + (i % 2) * 10, 8, 4, col))
    out += [path(f"M {num(bx - 56)} {num(top - 52)} Q {num(bx - 50)} {num(top + 2)} {num(bx)} {num(top + 2)} "
                 f"Q {num(bx + 50)} {num(top + 2)} {num(bx + 56)} {num(top - 52)} Z", P["glass"], **o),
            ellipse(bx, top - 52, 56, 11, "#f0a24a", **o), line(bx + 20, top - 54, bx + 40, top - 104, "#9aa0a8", 6)]
    for i in range(3):
        out.append(rect(bx + 72 + i * 22 - (60 if i == 2 else 0), top - 34 - (36 if i == 2 else 0), 18, 32, "#f6efdc", rx=3, **o))
    return g(*out, transform=place(x, y, s))


def balloon(x, y, color, tie):
    """A party balloon at (x, y) on a string tied at `tie`."""
    return (path(f"M {num(x)} {num(y + 42)} Q {num(x - 14)} {num((y + tie[1]) / 2)} {num(tie[0])} {num(tie[1])}",
                 stroke="#e8e2d2", stroke_width=2.5)
            + ellipse(x, y, 30, 38, color, **ol(3)) + poly([(x - 6, y + 45), (x + 6, y + 45), (x, y + 37)], color, **ol(2))
            + ellipse(x - 10, y - 14, 6, 11, P["white"], opacity=0.45))


def dachshund(x, y, s=1.0, facing=1, rot=0.0):
    """The sausage dog, one of the town's three dogs (see CHARACTER-SHEET.md), at full stretch. (x, y) is the ground under it."""
    sw = 3 / s
    o = ol(sw)
    coat, dark = "#b0703e", "#8a5530"
    parts = [ellipse(0, 3, 76, 9, P["shadow"], opacity=0.45)]
    for lx, a, col in ((-46, -40, dark), (40, 50, dark), (-34, 30, coat), (54, -30, coat)):
        parts.append(limb(lx, -24, [(a, 24)], 13, col, sw)[0])
    tail = "M -62 -36 Q -88 -46 -96 -64"
    parts += [path(tail, stroke=P["outline"], stroke_width=9 + 2 * sw, stroke_linecap="round"),
              path(tail, stroke=coat, stroke_width=9, stroke_linecap="round"),
              ellipse(0, -34, 66, 19, coat, **o), ellipse(50, -42, 7, 16, "#4fb3a9", rot=20, **o),
              ellipse(72, -50, 26, 19, coat, **o), ellipse(98, -44, 17, 11, coat, **o), circle(112, -46, 5, P["outline"]),
              ellipse(58, -54, 11, 24, dark, rot=62, **o), circle(78, -57, 3.6, P["outline"]),
              path("M 96 -34 Q 101 -20 93 -16 Q 88 -22 92 -34 Z", "#f09ab0", **o)]
    return g(*parts, transform=place(x, y, s, rot, facing))


def sausage_string(p0, p1, p2, count, size=15):
    """Linked sausages along the curve from p0 to p2 (p1 is its control point)."""
    out = [path(f"M {num(p0[0])} {num(p0[1])} Q {num(p1[0])} {num(p1[1])} {num(p2[0])} {num(p2[1])}",
                stroke=P["outline"], stroke_width=3)]
    for i in range(count):
        t = (i + 0.5) / count
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        dx = (1 - t) * (p1[0] - p0[0]) + t * (p2[0] - p1[0])
        dy = (1 - t) * (p1[1] - p0[1]) + t * (p2[1] - p1[1])
        out.append(ellipse(x, y, size, size * 0.55, P["sausage"], rot=math.degrees(math.atan2(dy, dx)), **ol(2.5)))
    return "".join(out)


def burger(x, y, s=1.0, rot=0.0):
    o = ol(2.5 / s)
    return g(path("M -24 -4 Q -24 -24 0 -24 Q 24 -24 24 -4 Z", "#e2b06a", **o), rect(-26, -4, 52, 8, "#6fa35a", rx=4, **o),
             rect(-24, 4, 48, 10, "#7a4a2e", rx=4, **o), path("M -24 14 L 24 14 Q 24 24 0 24 Q -24 24 -24 14 Z", "#e2b06a", **o),
             transform=place(x, y, s, rot))


def panel_the_barbecue_heist(pid):
    """The barbecue heist: the whole block party watches a burger flip; he runs off with a string of sausages."""
    d = Defs(pid)
    cam = Cam(0.0, 0.0, 170, cy=H * 0.58)
    # The same houses as the trap, seen from the game camera: their fronts along the top.
    out = [rect(0, 0, W, H, P["asphalt"])]
    for hx_, hw, col in ((-30, 290, "#3b4566"), (260, 250, "#4a4060"), (510, 300, "#35505a"), (810, 270, "#4b4a63"),
                         (1080, 290, "#3e5466"), (1370, 260, "#4a4060")):
        out += [rect(hx_, -10, hw, 196, col, **ol(3)), rect(hx_ + hw / 2 - 28, 70, 56, 116, shade(col, 0.72), **ol(3))]
        for wx in (hx_ + hw * 0.12, hx_ + hw * 0.66):
            out.append(rect(wx, 40, hw * 0.22, 70, "#ffe7a8", **ol(3)))
    out += [rect(0, 186, W, 70, "#59606c", **ol(3)), rect(0, 252, W, 12, "#363a44"),
            string_lights(-40, 22, 1640, 12, 18, 110, d, bulbs=22), bunting(-40, 56, 1640, 46, 20, flags=24, size=30)]

    # At the back, the officer peeks over the snack table with a bag of marshmallows.
    out += [person(1300, 236, 0.9, facing=-1, shirt="#b9a66f", pants="#4b5233", hair="#3b2a20", pose="peek", face="smile",
                   prop="bag", cap="#5e6b3a", badge=True, shadow=False),
            snack_table(1250, 300, 380, 0.62)]
    for x_, z_, shirt, hair, pose in ((-1.7, -2.15, "#c98fb5", "#3b2a20", "freeze2"), (-0.6, -2.3, "#6fb7d6", "#2c2a33", "stand")):
        px, py = cam.at(x_, z_)
        out.append(person_front(px, py, cam.person, shirt=shirt, hair=hair, pose=pose, face="o"))

    # Chalk drawings and confetti on the street.
    chalk = dict(stroke="#f4e9a8", stroke_width=6, opacity=0.5)
    out += [circle(300, 790, 42, "none", **chalk)]
    for i in range(10):
        a = math.tau * i / 10
        out.append(line(300 + math.cos(a) * 58, 790 + math.sin(a) * 58, 300 + math.cos(a) * 80, 790 + math.sin(a) * 80,
                        "#f4e9a8", 6, opacity=0.5))
    for i in range(5):
        a = math.tau * i / 5
        out.append(circle(560 + math.cos(a) * 22, 850 + math.sin(a) * 22, 16, "none", **chalk))
    rng = random.Random(16)
    for _ in range(40):
        cx_, cy_ = rng.uniform(0, W), rng.uniform(300, H)
        out.append(rect(cx_, cy_, 9, 5, rng.choice((P["bulb"], "#4fb3a9", "#9b8fc9", "#f0a24a")),
                        transform=f"rotate({rng.randint(0, 180)} {num(cx_)} {num(cy_)})", opacity=0.8))

    # The grill master flips a burger sky-high, and every eye goes up with it.
    gx, gy = cam.at(-3.0, -0.5)
    mx, my = cam.at(-3.8, -0.8)
    hand = person_hand(mx, my, cam.person, 1, "flip")
    out += [grill(gx, gy, cam.k, 0.8),
            person(mx, my, cam.person, facing=1, shirt="#8fb59a", hair="#2f2a24", pose="flip", face="laugh", prop="spatula"),
            path(f"M {num(hand[0] + 30)} {num(hand[1] - 40)} Q {num(hand[0] + 70)} {num(hand[1] - 150)} {num(hand[0] + 120)} "
                 f"{num(hand[1] - 120)}", stroke=P["fx"], stroke_width=5, stroke_dasharray="4 12", stroke_linecap="round"),
            burger(hand[0] + 140, hand[1] - 110, 1.3, 40), pop_lines(hand[0] + 140, hand[1] - 110, 46, 6, -170, -10, width=4)]

    # Meanwhile he's away with the sausages: a kid limbos under the string and a sausage dog leaps for it.
    kx, ky = cam.at(0.0, 1.0)
    dx_, dy_ = cam.at(1.1, 2.15)
    rx, ry = cam.at(2.9, 1.95)
    s = cam.racc
    start = (gx + 0.36 * cam.k, gy - 0.66 * cam.k)
    end = raccoon_mouth(rx, ry, s, 1, "run")
    out += [person(kx, ky, cam.person * 0.72, facing=1, shirt="#f0c35a", hair="#4a3426", pose="limbo", face="laugh"),
            dachshund(dx_, dy_ - 30, 0.62, 1, -18), speed_lines(dx_ - 70, dy_ - 60, 180, 50, 3, 12, width=3),
            sausage_string(start, (760, 540), end, 28, 15),
            dust(rx - 150 * s - 30, ry - 6, 0.6), speed_lines(rx - 130 * s, ry - 90 * s, 180, 90, 4, 14),
            raccoon(rx, ry, s, facing=1, pose="run", beanie=True, held="sausage", eyes="open"),
            hud(done=("dumpster", "bungee"), active="barbecue", tasks=TOWN_TASKS)]
    return d.svg(), "".join(out)


def panel_the_marshmallow_trap(pid):
    """The marshmallow trap: at the block party a marshmallow trail leads into a carrier, and the door slams shut."""
    d = Defs(pid)
    out = [rect(0, 0, W, H, d.vertical("sky", P["sky_top"], P["sky_low"]))]
    rng = random.Random(10)
    for _ in range(36):
        out.append(circle(rng.uniform(0, W), rng.uniform(0, 160), rng.uniform(1.2, 2.4), P["star"], opacity=0.8))

    # The houses along the street. Two neighbours lean out of their windows with their phones.
    houses = ((-30, 290, 330, "#3b4566", True, None), (260, 250, 290, "#4a4060", False, None),
              (510, 300, 360, "#35505a", True, ("#6fb7d6", P["hair"], 1)),
              (810, 270, 300, "#4b4a63", False, ("#c98fb5", "#2c2a33", -1)),
              (1080, 290, 350, "#3e5466", True, None), (1370, 260, 310, "#4a4060", False, None))
    flashes = []
    for hx_, hw, hh, col, gable, neighbour in houses:
        top, roof = 560 - hh, shade(col, 0.72)
        if gable:
            out.append(poly([(hx_ - 14, top), (hx_ + hw / 2, top - 84), (hx_ + hw + 14, top)], roof, **ol(3)))
        out.append(rect(hx_, top, hw, hh, col, **ol(3)))
        if not gable:
            out.append(rect(hx_ - 8, top - 16, hw + 16, 20, roof, **ol(3)))
        out.append(rect(hx_ + hw / 2 - 28, 440, 56, 120, roof, **ol(3)))
        if neighbour:
            wx, wy = hx_ + hw / 2 - 75, top + 40
            out += [rect(wx, wy, 150, 112, "#ffe7a8", **ol(4)), watcher(wx + 75, wy + 70, *neighbour),
                    rect(wx - 8, wy + 108, 166, 14, roof, **ol(3))]
            flashes.append(burst(wx + 75 + 45 * neighbour[2], wy + 8, 24, P["white"]))
        else:
            for wx in (hx_ + hw * 0.12, hx_ + hw * 0.66):
                out.append(rect(wx, top + 40, hw * 0.22, 76, "#ffe7a8" if rng.random() < 0.6 else "#262c44", **ol(3)))
    out += flashes
    out += [string_lights(-40, 66, 1640, 46, 30, 110, d, bulbs=22), bunting(-40, 112, 1640, 96, 34, flags=24, size=36),
            rect(0, 560, W, 38, "#59606c", **ol(3)), rect(0, 596, W, 12, "#363a44"), rect(0, 606, W, 294, P["asphalt"])]
    # His poster on the lamppost, under the street light.
    out += [poly([(1548, 236), (1260, 900), (1600, 900), (1600, 300)], P["street"], opacity=0.1),
            rect(1539, 226, 18, 372, "#3a3e46", **ol(3)), rect(1500, 214, 98, 24, "#3a3e46", rx=6, **ol(3)),
            ellipse(1548, 240, 32, 10, P["street"]),
            rect(1488, 380, 112, 140, P["paper"], **ol(3)), raccoon_face(1544, 458, 0.58, beanie=True, mouth="smirk")]
    out.append(van(130, 650, 86, hv=1.0, body="#e9e5da", top=P["carrier"], cargo=True))

    # The officer pops up from behind the snack table, yanking the string, net held high.
    ox, oy, os_ = 1262, 872, 2.2
    out += [person(ox, oy, os_, facing=-1, shirt="#b9a66f", pants="#4b5233", hair="#3b2a20", pose="yank", face="laugh",
                   prop2="net", cap="#5e6b3a", badge=True, shadow=False),
            snack_table(1190, 884, 440),
            balloon(1410, 530, "#4fb3a9", (1398, 714)), balloon(1462, 566, P["bulb"], (1404, 714)),
            balloon(1384, 580, "#9b8fc9", (1394, 714))]
    hand = person_hand(ox, oy, os_, -1, "yank")
    sx, sy, sa = 905, 600, -32
    tail = (sx + 62 * math.cos(math.radians(sa)), sy + 62 * math.sin(math.radians(sa)))
    out += [line(tail[0], tail[1], hand[0], hand[1], "#d8cfb5", 3.5),
            path(f"M 640 584 Q 760 480 {num(sx - 54)} {num(sy + 18)}", stroke=P["fx"], stroke_width=5,
                 stroke_dasharray="4 12", stroke_linecap="round", opacity=0.85),
            speed_lines(sx - 64, sy + 30, 168, 50, 3, 14, width=3),
            g(line(-62, 0, 62, 0, P["outline"], 15), line(-62, 0, 62, 0, "#8a6a4a", 9), transform=f"translate({sx} {sy}) rotate({sa})"),
            vibration(sx, sy, 78, 2, 16, 200, 250, P["fx"], 4), vibration(sx, sy, 78, 2, 16, 20, 70, P["fx"], 4)]

    # The carrier hops as the door slams. Inside: eyes wide, a marshmallow in his teeth, beanie popping up.
    cx, cy, cs = 500, 834, 1.55
    face = raccoon_face(0, -62, 0.8, eyes="wide", mouth="marshmallow", beanie=True, hat_pop=26)
    out += [ellipse(cx + 40 * cs, 852, 150 * cs, 17, P["shadow"], opacity=0.45),
            carrier_front(cx, cy, cs, d, face),
            burst(cx + 86 * cs, cy - 90 * cs, 30),
            pop_lines(cx + 36 * cs, cy - 200 * cs, 110, 7, -165, -15, width=5),
            vibration(cx - 112 * cs, cy - 90 * cs, 26, 3, 16, 145, 215, P["fx"], 5),
            dust(cx - 104 * cs, 850, 0.55), dust(cx + 170 * cs, 846, 0.55)]

    # The trail he followed.
    for mx, my, r in ((96, 880, 14), (196, 866, -18), (282, 856, 8)):
        out.append(rect(mx - 13, my - 10, 26, 20, P["white"], rx=7, transform=f"rotate({r} {mx} {my})", **ol(2.5)))
    out.append(wisp([(0, 852), (96, 862), (196, 848), (282, 838), (372, 800)], width=5))
    return d.svg(), "".join(out)


def panel_home_at_last(pid):
    """Home at last: the beanie camper lets him out under his tree; he scurries up to his hole."""
    d = Defs(pid)
    out = [rect(0, 0, W, H, d.vertical("sky", "#191d48", "#3f4384")), circle(1350, 140, 62, P["moon"]),
           circle(1350, 140, 140, d.radial("moon", P["moon"], 0.25))]
    rng = random.Random(12)
    for _ in range(60):
        out.append(circle(rng.uniform(0, W), rng.uniform(0, 460), rng.uniform(1.2, 2.5), P["star"], opacity=0.8))
    hills = "M 0 600 " + " ".join(f"Q {x + 70} {540 + (x * 11) % 40} {x + 140} 600" for x in range(0, 1680, 140)) + " L 1600 660 L 0 660 Z"
    out += [path(hills, "#18323a"), rect(0, 640, W, 260, P["ground"]),
            path("M 420 900 Q 700 760 1100 760 L 1600 760 L 1600 820 L 1100 820 Q 760 830 560 900 Z", P["clearing"]),
            his_tree(290, 890, 120, hv=1.0, hole_h=4.6, top=8.0)]
    out.append(wagon(1290, 880, 150, hv=1.0, facing=-1, lights=True))
    out += [person_front(1095, 878, 1.45, shirt="#9b8fc9", hair="#2d2a3a", pose="shrug", face="meh"),
            carrier(700, 860, 1.0),
            camper(890, 872, 1.55, "kneel", facing=-1, beanie=False, face="smile", prop2="phone_photo")]
    rx, ry = 520, 790
    out += [vibration(rx + 30, ry - 40, 70, 2, 18, 120, 300, P["fx"], 4),
            raccoon(rx, ry, 0.62, facing=-1, pose="run", beanie=True, eyes="open", mouth="grin", rot=-30, shadow=False),
            arrow([(rx - 120, ry - 20), (330, 800), (300, 520), (300, 400)], color=P["fx"], width=5, dash="4 12", head=18)]
    for cx, cy, f in ((150, 880, 1), (1010, 892, -1), (640, 888, 1)):
        out.append(cricket(cx, cy, 1.4, f))
    return d.svg(), "".join(out)


def panel_here_we_go_again(pid):
    """Here we go again: panel 2's framing, a new party, the beanie goes on, iris out on his grin."""
    return panel_party_below(pid, epilogue=True)


PANELS = [
    ("good-vibrations", "Good vibrations", "close-up · eye level", "design", panel_good_vibrations),
    ("party-below", "Party below", "wide · high, over the shoulder", "design", panel_party_below),
    ("dropping-in", "Dropping in", "wide · high 3/4", "gameplay", panel_dropping_in),
    ("things-to-do", "Things to do", "close-up · eye level", "gameplay UI", panel_things_to_do),
    ("paws-on-the-zipper", "Paws on the zipper", "medium · high 3/4", "gameplay", panel_paws_on_the_zipper),
    ("music-off", "Music off", "medium · high 3/4", "gameplay", panel_music_off),
    ("busted", "Busted", "medium · low angle", "design", panel_busted),
    ("the-red-beanie", "The red beanie", "wide · eye level, side-on", "design", panel_the_red_beanie),
    ("edge-of-town", "Edge of town", "wide · low angle, at his height", "design", panel_edge_of_town),
    ("the-masked-bandit", "The masked bandit", "wide · high 3/4", "gameplay", panel_the_masked_bandit),
    ("the-group-chat", "The group chat", "close-up · eye level", "design", panel_the_group_chat),
    ("the-barbecue-heist", "The barbecue heist", "medium · high 3/4", "gameplay", panel_the_barbecue_heist),
    ("the-marshmallow-trap", "The marshmallow trap", "medium · eye level, side-on", "design", panel_the_marshmallow_trap),
    ("home-at-last", "Home at last", "wide · eye level", "design", panel_home_at_last),
    ("here-we-go-again", "Here we go again", "wide · high, over the shoulder", "design", panel_here_we_go_again),
]


def write_sheet(rendered):
    cols, cw, ch, gap, margin, cap, head = 3, 480, 270, 28, 40, 60, 110
    rows = math.ceil(len(rendered) / cols)
    sw_, sh_ = margin * 2 + cols * cw + (cols - 1) * gap, head + rows * (ch + cap) + (rows - 1) * gap + margin
    parts = [rect(0, 0, sw_, sh_, "#ece8de"),
             text(margin, 62, "The Noise Next Door · storyboard", 40, "#262624", FONT_UI, "start", "700"),
             text(margin, 94, f"Whole story in {len(rendered)} panels · 16:9 · no dialogue: the story is told through actions and events",
                  20, "#5a5853", FONT_UI, "start"),
             f'<defs><clipPath id="frame"><rect width="{W}" height="{H}"/></clipPath></defs>']
    for i, (n, title, shot, view, defs, body) in enumerate(rendered):
        r, c = divmod(i, cols)
        x, y = margin + c * (cw + gap), head + r * (ch + cap + gap)
        parts += [g(g(defs, body, clip_path="url(#frame)"), transform=f"translate({x} {y}) scale(0.3)"),
                  rect(x, y, cw, ch, "none", stroke="#262624", stroke_width=2),
                  text(x, y + ch + 26, f"{n}. {title}", 20, "#262624", FONT_UI, "start", "700"),
                  text(x, y + ch + 50, f"{shot} · {view}", 16, "#5a5853", FONT_UI, "start")]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {sw_} {sh_}" width="{sw_}" height="{sh_}">'
           f"<title>The Noise Next Door storyboard</title>{''.join(parts)}</svg>")
    (HERE / "storyboard-sheet.svg").write_text(svg, encoding="utf-8")


def main():
    rendered = []
    for n, (slug, title, shot, view, fn) in enumerate(PANELS, 1):
        defs, body = fn(f"p{n:02d}")
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">'
               f"<title>{n}. {title}</title>{defs}{body}</svg>")
        (HERE / f"{n:02d}-{slug}.svg").write_text(svg, encoding="utf-8")
        rendered.append((n, title, shot, view, defs, body))
    write_sheet(rendered)
    print(f"Wrote {len(PANELS)} panels and storyboard-sheet.svg to {HERE}")


if __name__ == "__main__":
    main()
