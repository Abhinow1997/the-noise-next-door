#!/usr/bin/env python3
"""Time the pitch's GodotDesignBoard cards to the narration, after generate_audio_kokoro.py.

Run from the repo root:  python pitch/tools/set_timing.py

Each board lasts as long as its beat's measured narration (actual_duration_s). Each card lights
when its phrase is reached, placed by the phrase's share of the narration's characters: an
estimate within about half a second, not a word clock (align.py would need a Whisper model
download).

A beat with "tail_hold_s" (the end card) gets that much silence appended to its narration file,
so the card holds past the last word; its measured length then includes the hold, as Brutalist's
compiler requires (a beat's length must match its audio within 0.15 s). It isn't padded twice.
Standard library only, plus ffmpeg and ffprobe on the PATH.
"""
import json
import subprocess
from pathlib import Path

PITCH = Path(__file__).resolve().parents[1]


def probe(path: Path) -> float:
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                          str(path)], capture_output=True, text=True, check=True).stdout
    return float(out.strip())


def hold_tail(beat: dict) -> None:
    mp3 = PITCH / beat["audio_file"]
    duration = probe(mp3)
    if abs(beat.get("tail_applied_s", -1) - duration) < 0.01:
        return  # this file already carries its hold
    padded = mp3.with_name(mp3.stem + "-hold.mp3")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(mp3), "-af", f"apad=pad_dur={beat['tail_hold_s']}",
                    "-c:a", "libmp3lame", "-q:a", "2", str(padded)], check=True)
    padded.replace(mp3)
    beat["tail_applied_s"] = probe(mp3)
    beat["actual_duration_s"] = round(beat["tail_applied_s"], 2)
    print(beat["beat_id"], f"held {beat['tail_hold_s']} s past the last word: {beat['actual_duration_s']} s")

# Per board: the phrase each card lights on, in card order.
CUES = {
    "B01": ["Level one now runs", "the chase out of the camp", "The city, the block", "the ride home"],
    "B04": ["Goose Game makes", "Here you can", "Stray puts", "Here, the people"],
    "B06": ["Shaders", "headless tests"],
    "B07": ["Out: save states", "First:", "That test will show"],
    "B08": ["Scope", "So level one"],
}


# B06's board holds the jump strip (stage/jump-r1.png): ten frames of the raccoon from the game, with
# no text, at x 1676-3628, y 653-1176 of the 4K render. GATE T read his stripes and shadow as
# low-contrast type, so B06 declares every region of the board but the strip (a margin round it) as
# its typography. Written here, before remotion_scenes.py, which keeps what it reads at its start.
_SW, _SH = 3840, 2160
_X0, _Y0, _X1, _Y1 = 1660, 625, 3640, 1195


def _box(x0, y0, x1, y1):
    return [round(x0 / _SW, 4), round(y0 / _SH, 4), round(x1 / _SW, 4), round(y1 / _SH, 4)]


QC = {
    "B06": {
        "typography_regions": [
            {"label": "above the strip: the title, the left card's top, the status bar, the strip's caption",
             "box": _box(0, 0, _SW, _Y0)},
            {"label": "below the strip: the cards, the left card's foot, the source line, the name",
             "box": _box(0, _Y1, _SW, _SH)},
            {"label": "left of the strip: the left card", "box": _box(0, _Y0, _X0, _Y1)},
            {"label": "right of the strip: the margin", "box": _box(_X1, _Y0, _SW, _Y1)}],
        "typography_fill": "#F2F0E9",
        "typography_reason": ("Everything on the board but the jump strip, stage/jump-r1.png: ten frames of the "
                              "raccoon's jump from the game, at x 1676-3628, y 653-1176 of the 4K render. The "
                              "strip has no text; GATE T read his stripes and shadow as low-contrast type. "
                              "Every word on the board is checked."),
    },
}


def main() -> None:
    path = PITCH / "beat_sheet.json"
    sheet = json.loads(path.read_text(encoding="utf-8"))
    for beat in sheet["beats"]:
        if beat["beat_id"] in QC:
            beat["qc"] = QC[beat["beat_id"]]
        if beat.get("tail_hold_s"):
            hold_tail(beat)
        props = beat.get("shot", {}).get("remotion", {}).get("props")
        if props is None:
            continue
        duration = float(beat["actual_duration_s"])
        text = beat["narration_text"]
        cues = []
        for card, phrase in enumerate(CUES[beat["beat_id"]]):
            at = text.index(phrase)
            cues.append({"at": round(duration * at / len(text), 2), "card": card})
        props["cues"] = cues
        props["durationSeconds"] = duration
        print(beat["beat_id"], duration, [c["at"] for c in cues])
    path.write_text(json.dumps(sheet, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
