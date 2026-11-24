#!/usr/bin/env python3
"""Draw the pitch film's end card (media/B10.png) in Brutalist's cream-and-ink palette.

Run with the toolkit's Python (it has Pillow), from the repo root:
    python3 pitch/tools/make_end_card.py --revision "<commit> (<date>)[ and <commit> (<date>)]"

It's the author's own card, not the toolkit's @NikBearBrown outro: the course forbids the
instructor's name, persona and credit line.
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

PITCH = Path(__file__).resolve().parents[1]
ART_HOME = PITCH.parents[1] / "brutalist.art"
SERIF = ART_HOME / "runtime/fonts/EB_Garamond/static/EBGaramond-Regular.ttf"
PAGE, INK, ACCENT, MUTED = "#F2F0E9", "#3D3929", "#D97757", "#6B6150"
W, H = 3840, 2160


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(SERIF), size)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--revision", required=True,
                    help="the commit (or commits, each with its date) the gameplay was recorded at")
    ap.add_argument("--recorded", default="", help="the date the takes were recorded, if not given with --revision")
    a = ap.parse_args()

    img = Image.new("RGB", (W, H), PAGE)
    d = ImageDraw.Draw(img)
    x = 300
    d.text((x, 520), "The Noise Next Door", font=font(220), fill=INK)
    d.rectangle((x, 830, x + 360, 842), fill=ACCENT)
    d.text((x, 900), "Final project pitch · CSYE 7270 · Fall 2026", font=font(96), fill=INK)
    d.text((x, 1040), "Abhinav Gangurde · github.com/Abhinow1997/the-noise-next-door", font=font(96), fill=INK)
    lines = [
        f"Gameplay: real play, recorded by the author" + (f" on {a.recorded}" if a.recorded else "")
        + f" at {a.revision}, Godot 4.7.2.",
        "Boards: Brutalist's GodotDesignBoard, quoting GDD.md v1.0 (19 Oct 2026) exactly.",
        "Narration: Kokoro am_onyx, an AI voice reading the author's script.",
        "Storyboard panel: drawn in code by Claude Code. What's proposed is labelled proposed.",
        "Campers: Simple girl, Lowpoly man and chubby boy by TiZeta (Blend Swap), CC BY 3.0.",
        "The moth: a sprite sheet the author generated with Google Gemini. Full credits: pitch/SOURCES.md.",
    ]
    for i, line in enumerate(lines):
        d.text((x, 1340 + i * 110), line, font=font(70), fill=MUTED)
        right = d.textbbox((x, 0), line, font=font(70))[2]
        if right > W - W // 20:
            raise SystemExit(f"line {i + 1} runs past the title-safe edge ({right} > {W - W // 20} px): {line}")
    out = PITCH / "media" / "B10.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(out)


if __name__ == "__main__":
    main()
