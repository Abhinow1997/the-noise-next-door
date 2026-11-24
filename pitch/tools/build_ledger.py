#!/usr/bin/env python3
"""Build the pitch reel's GDD evidence ledger (gdd-evidence.json) for Brutalist's godot-gdd check.

Run from the repo root:  python pitch/tools/build_ledger.py

- Copies each excerpt into its beat's GodotDesignBoard props from GDD.md's own lines
  (beat["gdd_excerpt_lines"] = [first, last], one-based), so the quote on screen is exact.
- Maps every top-level "## " section of GDD.md to the beats that narrate it
  (beat["gdd_sections"]), or to a written exclusion below.
- Hashes GDD.md and every evidence file. Standard library only.
"""
import hashlib
import json
from pathlib import Path

PITCH = Path(__file__).resolve().parents[1]
GDD = PITCH.parent / "GDD.md"

# Sections no beat narrates, and why (godot-gdd: "an explicit, reasoned exclusion").
EXCLUSIONS = {
    "8. Graphics and styling": (
        "Shown, not explained. Every gameplay beat shows the low-poly night look and the fixed "
        "three-quarter camera, but the pitch's seven questions don't ask about style, so no beat "
        "narrates section 8."),
    "9. Music and sound effects": (
        "Left out. The film is narrated and the game's sound is muted under the voice. The music "
        "and effects are credited in SOURCES.md, not pitched."),
    "Provenance": (
        "Not narrated. Who made what is credited on the end card and in pitch/SOURCES.md."),
}

# Evidence inside the reel: path (relative to pitch/), how it was made, and what it supports.
EVIDENCE = [
    ("evidence/a7-baseline-SUMMARY.txt",
     "Copied unchanged from logs/a7-baseline-final/SUMMARY.txt: every test through scripts/run-test.sh "
     "in a fresh clone of 160c0eb with no .godot, headless, Godot 4.7.2, 22 Nov 2026",
     "B06: the tests rerun from a fresh clone. All passed except cost_effects.gd (1 of 4 checks fails, "
     "as it has since before Assignment 7)"),
    ("evidence/jump_pins_60fps.log",
     "Copied unchanged from logs/a7-baseline-final/jump_pins_60fps.log",
     "B06: the jump's 26 pins passed"),
    ("evidence/test_jump_edges_60fps.log",
     "Copied unchanged from logs/a7-baseline-final/test_jump_edges_60fps.log (30 and 144 fps are in the summary)",
     "B06: the jump's edge tests, 238 checks at 60 fps"),
    ("stage/jump-r1.png",
     "Copied unchanged from captures/sheets/jump-r1.png: tools/make_strip_sheets.gd's sheet of a windowed "
     "Movie Maker capture of previews/jump_preview.tscn at 30 fps, 1280 x 720 (a fixture, tag a7)",
     "B06's image: the jump on the rig, frame by frame"),
    ("stage/11-barking-up-the-wrong-tree.svg",
     "Copied unchanged from design/storyboard/: a storyboard thumbnail drawn in code by Claude Code "
     "(make_thumbnails.py), Oct 2026",
     "B08's image, labelled CONSTRUCTED: the town's dogs, which don't exist in the game"),
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    lines = GDD.read_text(encoding="utf-8").splitlines()
    headings = [line[3:].strip() for line in lines if line.startswith("## ")]
    sheet_path = PITCH / "beat_sheet.json"
    sheet = json.loads(sheet_path.read_text(encoding="utf-8"))

    excerpts = []
    for beat in sheet["beats"]:
        span = beat.get("gdd_excerpt_lines")
        if not span:
            continue
        first, last = span
        text = "\n".join(lines[first - 1:last])
        beat["shot"]["remotion"]["props"]["excerpt"] = text
        excerpts.append({"beat_id": beat["beat_id"], "start_line": first, "end_line": last, "text": text})

    sections = []
    for heading in headings:
        ids = [b["beat_id"] for b in sheet["beats"] if heading in b.get("gdd_sections", [])]
        if ids:
            sections.append({"heading": heading, "beat_ids": ids})
        elif heading in EXCLUSIONS:
            sections.append({"heading": heading, "exclusion": EXCLUSIONS[heading]})
        else:
            raise SystemExit(f"GDD section '{heading}' has no beat and no exclusion")

    evidence = []
    for rel, method, supports in EVIDENCE:
        evidence.append({"path": rel, "sha256": sha256(PITCH / rel), "method": method, "supports": supports})

    ledger = {
        "schema_version": 1,
        "document": {"path": "../GDD.md", "version": "1.0, 19 Oct 2026", "sha256": sha256(GDD)},
        "sections": sections,
        "excerpts": excerpts,
        "evidence": evidence,
    }
    sheet["metadata"]["gdd"]["sha256"] = ledger["document"]["sha256"]
    (PITCH / "gdd-evidence.json").write_text(json.dumps(ledger, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    sheet_path.write_text(json.dumps(sheet, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")

    titles = {b["beat_id"]: (b.get("shot", {}).get("remotion", {}).get("props", {}).get("title")
                             or b.get("shot", {}).get("capture", {}).get("shows", "")) for b in sheet["beats"]}
    md = ["# GDD coverage: The Noise Next Door, final project pitch", "",
          f"Written by `tools/build_ledger.py` from `gdd-evidence.json`. GDD.md v1.0, SHA-256 `{ledger['document']['sha256']}`.",
          "Every top-level section of the GDD is narrated by a beat, or left out for the reason given.", "",
          "| GDD section | Beats | Or left out, because |", "|---|---|---|"]
    for s in sections:
        md.append(f"| {s['heading']} | {', '.join(s.get('beat_ids', []))} | {s.get('exclusion', '')} |")
    md += ["", "## Exact excerpts on the boards", "", "| Beat | Board | GDD lines |", "|---|---|---|"]
    for e in excerpts:
        md.append(f"| {e['beat_id']} | {titles[e['beat_id']]} | {e['start_line']}–{e['end_line']} |")
    (PITCH / "GDD-COVERAGE.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    print(f"ledger: {len(sections)} sections, {len(excerpts)} excerpts, {len(evidence)} evidence files")


if __name__ == "__main__":
    main()
