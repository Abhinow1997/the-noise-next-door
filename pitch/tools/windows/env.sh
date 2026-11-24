# Source in Git Bash before running Brutalist on Windows:  source pitch/tools/windows/env.sh
# - Brutalist's scripts call `python3`, which on Windows is the Microsoft Store stub; bin/python3
#   runs the toolkit's own venv instead (ART_HOME/.venv, made with `py -3.12 -m venv .venv`).
# - PYTHONUTF8 keeps its UTF-8 files and output from tripping on the cp1252 default.
# - winget's FFmpeg is on PATH in a new shell; FFMPEG_BIN adds it to an older one.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "${FFMPEG_BIN:-}" ] && ! command -v ffmpeg >/dev/null 2>&1; then
  FFMPEG_BIN="$(ls -d "${LOCALAPPDATA:-}"/Microsoft/WinGet/Packages/Gyan.FFmpeg*/ffmpeg-*/bin 2>/dev/null | head -1)"
fi
export ART_HOME="${ART_HOME:-$(cd "$HERE/../../../../brutalist.art" && pwd)}"
export PATH="$HERE/bin:$ART_HOME/.venv/Scripts:${FFMPEG_BIN:+$FFMPEG_BIN:}$PATH"
export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8
