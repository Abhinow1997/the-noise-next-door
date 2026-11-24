# The Noise Next Door: final project pitch

CSYE 7270 · Fall 2026 · Assignment 8 · Draft v1, 24 Nov 2026

| | |
|---|---|
| **Name** | Abhinav Gangurde (GitHub: Abhinow1997) |
| **Working title** | The Noise Next Door |
| **Target role** | Gameplay programmer |
| **Stack** | Godot 4.7.2 stable, GDScript, Forward+; desktop exports for Windows and macOS (proposed: no export exists yet) |
| **Runtime** | 3 min 0.8 s (180.83 s), measured on the final |
| **The film** | `the-noise-next-door-pitch.mp4`, 1920 × 1080, 24 fps, SHA-256 `3f792689624318f9c4e86a3197d4bfa356562184532cea1ebddfb12bd0e8f9aa`, from Brutalist's `art final` (24 Nov 2026; its receipt, `.verified.json`, says "ready"). Link: pending my upload |
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

The rendered film, the takes, the narration audio and the rendered boards stay out of GitHub (`.gitignore`). They're in the course media storage, linked above.

## How to rebuild the film

[BUILD-PROMPT.md](BUILD-PROMPT.md): set up Brutalist once, then run its section 2 from the repo root.
