# The Noise Next Door: final project pitch

CSYE 7270 · Fall 2026 · Assignment 8 · Draft v1, 24 Nov 2026

| | |
|---|---|
| **Name** | Abhinav Gangurde (GitHub: Abhinow1997) |
| **Working title** | The Noise Next Door |
| **Target role** | Gameplay programmer |
| **Stack** | Godot 4.7.2 stable, GDScript, Forward+; desktop exports for Windows and macOS (proposed: no export exists yet) |
| **Runtime** | 3 min 0.7 s (180.67 s), measured on the final |
| **The film** | `the-noise-next-door-pitch.mp4`, 1920 × 1080, 24 fps, SHA-256 `087666b3876864cdfdda2ff7bc607d2e7272602249b967baba9fe3e767cd2ff8`, from Brutalist's `art final` (24 Nov 2026; its receipt, `.verified.json`, says "ready"). **[Watch it on Northeastern OneDrive](https://northeastern-my.sharepoint.com/:v:/g/personal/gangurde_a_northeastern_edu/IQBrOAZAAhC-RanXUVRysjaiAc-PeF7L9brwQhDnPbFP02U?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=5wSF5G)** (sign in with a Northeastern account) |
| **Footage** | Real play, screen-recorded by me: run-01 at `370f62d` (23 Nov 2026), run-02 and run-03 at `263ac50` (24 Nov 2026). FACTCHECK.md has each take's SHA-256 |

A short pitch for the whole game, made with Brutalist's `godot-gdd` route. The narration is an AI voice (Kokoro `am_onyx`) reading my script as me. The boards quote my design document exactly. Everything not built yet is labelled proposed.

## What's here

| File | What it is |
|---|---|
| [PROJECT-BRIEF.md](PROJECT-BRIEF.md) | The seven questions answered, then what exists today (with tags and commits) and what will exist |
| [beat_sheet.json](beat_sheet.json) | The narration and the visual plan, beat by beat, with each body beat's design status |
| [SHOTLIST.md](SHOTLIST.md) | The gameplay takes: how they're recorded, and which beat uses what |
| [FACTCHECK.md](FACTCHECK.md) | Every claim the film makes, its source, and its verdict |
| [PROMPTS.md](PROMPTS.md) | What generated anything in the film, and my directions to Claude Code |
| [SOURCES.md](SOURCES.md) | What I used and made, what Claude Code contributed, and every third-party asset with its licence |
| [BUILD-PROMPT.md](BUILD-PROMPT.md) | The commands and the Claude Code prompt that rebuild the film |
| [FRICTIONAL.md](FRICTIONAL.md) | The dated log of making it |
| [GDD-COVERAGE.md](GDD-COVERAGE.md), [gdd-evidence.json](gdd-evidence.json), [evidence/](evidence/), [stage/](stage/) | Which beat narrates each GDD section, the godot-gdd ledger, and the files it hashes |
| `_qc/`, `TYPECHECK.md`, the `.verified.json` receipt | The toolkit's gate reports, written by the final render |
| [tools/](tools/) | The scripts that build the reel, the toolkit's local patch, and the Windows shim |

The assignment keeps the rendered film, and every file over 25 MB, out of GitHub. So the film and the three takes stay out of it (`.gitignore`) and are on Northeastern OneDrive. The links open for anyone in Northeastern University, after signing in with a Northeastern account (checked 24 Nov 2026: a visitor who isn't signed in is sent to the sign-in page).

| File | SHA-256 | Link |
|---|---|---|
| `the-noise-next-door-pitch.mp4`: the film | `087666b3876864cdfdda2ff7bc607d2e7272602249b967baba9fe3e767cd2ff8` | [OneDrive](https://northeastern-my.sharepoint.com/:v:/g/personal/gangurde_a_northeastern_edu/IQBrOAZAAhC-RanXUVRysjaiAc-PeF7L9brwQhDnPbFP02U?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=5wSF5G) |
| `the-noise-next-door-pitch.verified.json`: Brutalist's receipt for it | (its own record of the film's SHA-256) | [OneDrive](https://northeastern-my.sharepoint.com/:u:/g/personal/gangurde_a_northeastern_edu/IQA7us0GMOrESpXkbVe87HbTAbuVZielvj6IX-9sIcyTZc4?e=vIQHWc) |
| `run-01.mp4`: the take from the title screen to the tutorial's end (23 Nov, `370f62d`) | `ac65a4fe5f0567cfdfb383269df12ef595f1ed07d77636f9ff3497d06712e0c0` | [OneDrive](https://northeastern-my.sharepoint.com/:v:/g/personal/gangurde_a_northeastern_edu/IQC6h6_TxLstSbnfoIUHTXcNAZmdBvtjSsMa8OoczSwrbJA?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=aWlGgf) |
| `run-02.mp4`: the tent and Scare a camper (24 Nov, `263ac50`) | `bec67e6135a18165165c5162bf5da2b6c7b9363782c2ebdbfaa768e80cb64a03` | [OneDrive](https://northeastern-my.sharepoint.com/:v:/g/personal/gangurde_a_northeastern_edu/IQBf4dxYwdmQSp5RTUKAz5qiATc5QSrDvGXwUYOVmrJYVf8?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=Ghzi7f) |
| `run-03.mp4`: the cake to the chase (24 Nov, `263ac50`) | `8f0b700c1aaae41a5c060a858c246fba4f95fa828932059d71b8df2b47521660` | [OneDrive](https://northeastern-my.sharepoint.com/:v:/g/personal/gangurde_a_northeastern_edu/IQD5RIi85GNZQ5tU5wdbVk3EAb9BmVoFJraVQCmmGSkMPVo?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=q1sEv2) |

The narration audio, the clips and the rendered boards aren't uploaded: BUILD-PROMPT.md remakes them from this folder and the takes.

## How to rebuild the film

[BUILD-PROMPT.md](BUILD-PROMPT.md): set up Brutalist once, then run its section 2 from the repo root.
