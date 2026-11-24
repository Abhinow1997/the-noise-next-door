#!/usr/bin/env python3
"""Cut the pitch film's gameplay clips from the author's takes: screen recordings of the game
played at real speed (capture/<take>.mp4, or .avi).

Run from the repo root, with ffmpeg on the PATH:
    python pitch/tools/cut_clips.py [--reel pitch]

Reads <reel>/capture/clips.json:
    {"revision": "<commit>", "recorded": "<date>",
     "takes": {"run-01": {"crop": "1280:715:2:39",        (optional: w:h:x:y of the game in the recording)
                          "revision": "<commit>", "recorded": "<date>"}},   (optional: this take's own)
     "segments": [{"beat": "B00", "take": "run-01", "start": 3.0, "end": 17.8, "note": ""}, ...]}
A beat with several segments gets them in order, each labelled. A take's own revision and date,
when it has them, label its segments in place of the plan's.

For each gameplay beat it writes <reel>/media/<beat>.mp4:
- each segment at its real speed (never retimed), 30 fps;
- the game's picture at 80 % (1536 x 864), inside the 5 % title-safe box, on a dark matte: the
  toolkit's documented presentation for gameplay (skills/make/godot-trailer, "Traps already met");
- under it, in the matte, the label "REAL PLAY · screen recording · human input · <revision> ·
  recorded <date>" at 40 px, with the segment's note on a second line. So the label never covers
  the game's own task notes, and it's at the toolkit's type floor (GATE T);
- if the action is shorter than the beat's narration, the last frame held for the rest,
  labelled "HELD FRAME";
- no audio: the game's sound is muted under the narration.
It writes each gameplay beat's `qc` declaration into beat_sheet.json, from the label it draws
(see declare_qc), and prints each take's and each clip's SHA-256, for FACTCHECK.md.
"""
import argparse
import hashlib
import json
import os
import subprocess
import tempfile
from pathlib import Path

FPS = 30
W, H = 1920, 1080
# The game's picture: 80 %, 16:9, its top on the title-safe line (y 54), centred across.
GAME_W, GAME_H = 1536, 864
GAME_X, GAME_Y = (W - GAME_W) // 2, 54
MATTE = "0b0d10"
# The label, in the matte under the picture, lined up with its left edge. At 40 px Inter Medium a
# line's glyphs run from y+10 (capitals) to y+47 (descenders), so the second line's bottom is on
# the title-safe line (1026), and the first line's top is 19 px under the picture (918).
SIZE = 40
X = GAME_X
Y2 = 979             # the note, if the segment has one
Y = Y2 - 52          # "REAL PLAY · screen recording · human input · <revision> · recorded <date>"
# The toolkit checkout beside this repo, for its bundled font. Paths inside filters stay
# relative to the reel: ffmpeg's filter parser splits a Windows "C:\..." path.
FONT_FILE = Path(__file__).resolve().parents[3] / "brutalist.art/runtime/fonts/Inter/static/Inter_28pt-Medium.ttf"
FONT = ""


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(cmd, cwd):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"ffmpeg failed: {' '.join(cmd)}\n{r.stderr[-1500:]}")


def text_filter(textfile: str, x: int, y: int, enable: str = "", box: bool = False) -> str:
    f = f"drawtext=fontfile={FONT}:textfile={textfile}:x={x}:y={y}:fontsize={SIZE}:fontcolor=white"
    if box:
        f += ":box=1:boxcolor=black@0.7:boxborderw=10"
    return f + (f":enable='{enable}'" if enable else "")


def label_boxes(lines) -> list:
    """Each label line's region, normalized: the whole line, on the matte, with a margin."""
    from PIL import ImageFont
    font = ImageFont.truetype(str(FONT_FILE), SIZE)
    boxes = []
    for label, text, y in lines:
        width = font.getlength(text)
        if X + width > W - 96:
            raise SystemExit(f"label line runs past the title-safe edge: {text}")
        box = [(X - 8) / W, (y + 2) / H, (X + width + 8) / W, (y + 53) / H]
        boxes.append({"label": label, "box": [round(v, 4) for v in box]})
    return boxes


def lines_for(segs, label: str, label2) -> list:
    lines = [("REAL PLAY label", f"{label} · {label2(segs[0]['take'])}", Y)]
    notes = {s["note"] for s in segs if s.get("note")}
    if len(notes) > 1:
        raise SystemExit(f"{segs[0]['beat']}: one note a beat, not {sorted(notes)}")
    if notes:
        lines.append(("note", notes.pop(), Y2))
    return lines


def declare_qc(reel: Path, sheet: dict, beats: dict, label: str, label2) -> None:
    """Write each gameplay beat's QC declaration into the beat sheet, from the labels drawn here.

    - typography_regions: GATE T checks the film's own type, the label in the matte, and not the
      game's picture or its HUD (the game's own text, at its own size);
    - contrast_regions: GATE V and GATE T measure the label's contrast there, since the night scene
      above it is dark by design.
    The picture sits inside the title-safe box, so nothing here waives edge-bleed."""
    for beat in sheet["beats"]:
        segs = beats.get(beat["beat_id"])
        if not segs:
            continue
        regions = label_boxes(lines_for(segs, label, label2))
        beat["qc"] = {
            "typography_regions": regions,
            "typography_fill": f"#{MATTE}",
            "typography_reason": ("The picture is the game as played, at 80 % inside the title-safe box, and "
                                  "its HUD is the game's own text at its own size. The film's own type on this "
                                  "beat is the label in the matte under the picture: these are its lines, "
                                  "measured from the font and size tools/cut_clips.py draws them with."),
            "contrast_regions": regions,
            "contrast_reason": ("The picture is the game's night scene, dark by design; the text a viewer "
                                "must read here is the burned-in label, white on the matte, measured there."),
        }
    path = reel / "beat_sheet.json"
    path.write_text(json.dumps(sheet, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--reel", default="pitch")
    reel = Path(ap.parse_args().reel).resolve()
    global FONT
    FONT = os.path.relpath(FONT_FILE, reel).replace("\\", "/")
    plan = json.loads((reel / "capture" / "clips.json").read_text(encoding="utf-8"))
    sheet = json.loads((reel / "beat_sheet.json").read_text(encoding="utf-8"))
    durations = {b["beat_id"]: float(b["actual_duration_s"]) for b in sheet["beats"] if "actual_duration_s" in b}
    label = "REAL PLAY · screen recording · human input"

    def label2(take: str) -> str:
        own = plan.get("takes", {}).get(take, {})
        return f"{own.get('revision', plan['revision'])} · recorded {own.get('recorded', plan['recorded'])}"

    beats = {}
    for seg in plan["segments"]:
        beats.setdefault(seg["beat"], []).append(seg)
    declare_qc(reel, sheet, beats, label, label2)

    takes = {}
    for take in sorted({s["take"] for s in plan["segments"]}):
        found = [p for ext in (".mp4", ".avi", ".mkv") if (p := reel / "capture" / f"{take}{ext}").is_file()]
        if not found:
            raise SystemExit(f"no capture/{take}.mp4 (or .avi, .mkv)")
        takes[take] = found[0]
        print(f"take {found[0].name} sha256 {sha256(found[0])}")

    (reel / "media").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=reel) as tmp:
        work = Path(tmp)
        rel = work.name  # filters use paths relative to the reel
        (work / "held.txt").write_text("HELD FRAME", encoding="utf-8")
        for beat, segs in beats.items():
            texts = []
            for i, (_, text, y) in enumerate(lines_for(segs, label, label2)):
                (work / f"{beat}-line{i}.txt").write_text(text, encoding="utf-8")
                texts.append(text_filter(f"{rel}/{beat}-line{i}.txt", X, y))
            parts = []
            for i, seg in enumerate(segs):
                # A screen recording's box can take in the window's title bar: crop each take to the game.
                crop = plan.get("takes", {}).get(seg["take"], {}).get("crop")
                vf = ([f"crop={crop}"] if crop else []) + [
                    f"fps={FPS}", f"scale={GAME_W}:{GAME_H}:force_original_aspect_ratio=decrease:flags=lanczos",
                    f"pad={GAME_W}:{GAME_H}:(ow-iw)/2:(oh-ih)/2:color=0x{MATTE}",
                    f"pad={W}:{H}:{GAME_X}:{GAME_Y}:color=0x{MATTE}", "setsar=1"] + texts
                part = work / f"{beat}-{i}.mp4"
                run(["ffmpeg", "-v", "error", "-y", "-ss", f"{seg['start']:.3f}", "-to", f"{seg['end']:.3f}",
                     "-i", f"capture/{takes[seg['take']].name}", "-vf", ",".join(vf), "-an",
                     "-c:v", "libx264", "-crf", "16", "-pix_fmt", "yuv420p", str(part)], reel)
                parts.append(part)
            listing = work / f"{beat}.txt"
            listing.write_text("".join(f"file '{p.name}'\n" for p in parts), encoding="utf-8")
            action = sum(s["end"] - s["start"] for s in segs)
            total = max(durations[beat], action)
            hold = total - action
            vf = f"tpad=stop_mode=clone:stop_duration={hold:.3f}" if hold > 0 else "null"
            if hold > 0:
                vf += "," + text_filter(f"{rel}/held.txt", GAME_X + 14, GAME_Y + 14, f"gte(t,{action:.3f})", box=True)
            out = reel / "media" / f"{beat}.mp4"
            run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(listing),
                 "-vf", vf, "-frames:v", str(round(total * FPS)), "-an",
                 "-c:v", "libx264", "-crf", "16", "-pix_fmt", "yuv420p", "-r", str(FPS), str(out)], reel)
            print(f"{beat}: {action:.2f} s of play, {hold:.2f} s held, media/{beat}.mp4 sha256 {sha256(out)}")


if __name__ == "__main__":
    main()
