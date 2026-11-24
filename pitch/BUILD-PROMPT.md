# Build prompt: The Noise Next Door, final project pitch

`pitch/` · Assignment 8 · Draft v0, 23 Nov 2026

The commands that rebuild the film from this folder, and the one Claude Code prompt that runs them. Everything is local and free: no keys, accounts or uploads. The gameplay takes are the one thing a command can't remake. They're real play, recorded by me (SHOTLIST.md), and kept with their SHA-256s in the course media storage (README.md).

## 1. The toolkit, once

Brutalist lives beside this repo, as `../brutalist.art` from the repo root. These are the steps as run on Windows 11 in Git Bash, 23 Nov 2026 (FRICTIONAL.md has why each one is needed):

```bash
cd ..   # the folder holding the-noise-next-door
mkdir brutalist.art && cd brutalist.art && git init -q
git fetch --depth 1 https://github.com/nikbearbrown/brutalist.art 3a6d3979dad53998659cf02385e7c9fefbe09d83
git checkout -q FETCH_HEAD   # the commit this film was built with
git apply ../the-noise-next-door/pitch/tools/brutalist-local.patch
py -3.12 -m venv .venv
source ../the-noise-next-door/pitch/tools/windows/env.sh   # Windows only: a python3 for the venv, UTF-8
./setup --install
python3 -m pip install "av==18.0.0"   # only where Smart App Control blocks PyAV 18.1.1's DLL
./setup   # every row ready except "Manim equation beats" (LaTeX), which this film doesn't use
```

On macOS or Linux, skip `env.sh` and activate the venv (`source .venv/bin/activate`). The fetch by commit wasn't run here, since the toolkit was cloned at that commit. A full `git clone` then `git checkout 3a6d397` gets the same files.

FFmpeg on Windows: `winget install --id Gyan.FFmpeg -e --source winget`.

## 2. The film

From the repo root, with `source pitch/tools/windows/env.sh` (Windows) and `ART=../brutalist.art`:

```bash
python pitch/tools/build_ledger.py                                   # GDD excerpts + gdd-evidence.json
(cd $ART && python3 runtime/scripts/generate_audio_kokoro.py ../the-noise-next-door/pitch)   # narration, the clock
python pitch/tools/set_timing.py                                     # boards last as long as their narration
bash pitch/tools/stage.sh                                            # board images into Remotion's public/
(cd $ART && python3 runtime/scripts/remotion_scenes.py ../the-noise-next-door/pitch --force)  # the five boards
python pitch/tools/cut_clips.py                                      # gameplay clips from capture/run-0N.mp4
python3 pitch/tools/make_end_card.py --revision "370f62d (23 Nov 2026) and 263ac50 (24 Nov 2026)"
(cd $ART && ./art godot-gdd --check ../the-noise-next-door/pitch --gdd ../the-noise-next-door/GDD.md)
(cd $ART && ./art run ../the-noise-next-door/pitch --height 1080)    # review cut, beside the reel
(cd $ART && ./art final ../the-noise-next-door/pitch --height 1080 --out ../the-noise-next-door/pitch/exports)
(cd $ART && ./art godot-gdd --check ../the-noise-next-door/pitch --gdd ../the-noise-next-door/GDD.md)
```

- **The height** is 1080, not the toolkit's default 2160. The gameplay is captured at the game's own 1280 × 720, and a 4K master would only enlarge it.
- **A final writes** `<slug>.mp4` and its `.verified.json` receipt to `pitch/exports/`. They stay out of GitHub.

## 3. The prompt

Paste into Claude Code from the repo root:

> Rebuild the pitch film in `pitch/` with Brutalist's godot-gdd route, following `pitch/BUILD-PROMPT.md` section 2 in order. The toolkit is at `../brutalist.art`; source `pitch/tools/windows/env.sh` first on Windows. The takes are in `pitch/capture/`, and their SHA-256s are in `pitch/FACTCHECK.md`: stop if any differs. Don't edit the game, `GDD.md`, the narration or the takes. After the final, run the godot-gdd check again. Then read the frames the toolkit's QC sampled, and the final's contact sheet, against the visual QC rubric, and report every gate's result. Never publish, upload or commit.
