#!/usr/bin/env bash
# scripts/run-test.sh <test-file.gd | --flag-test> <fps>
# The course's Assignment 5 wrapper, adapted for this repository by Claude Code:
# - the Godot project is the repository root, so --path . (the course's has --path godot);
# - Godot isn't on the PATH on the author's machine, so it is found from GODOT, then `godot`,
#   then the two places the .bat launchers look;
# - the earlier checks run inside the main scene from a flag (`-- --sound-test`), so an
#   argument that starts with -- runs main.tscn with that flag instead of a tests/ script.
# Exit status 124 means the test hung.
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
godot="${GODOT:-$(command -v godot || true)}"
for g in ../Godot/Godot_v4.7.2-stable_win64_console.exe "$LOCALAPPDATA/Programs/Godot/Godot_v4.7.2-stable_win64_console.exe"; do
	if [ -z "$godot" ] && [ -f "$g" ]; then godot="$g"; fi
done
if [ -z "$godot" ]; then echo "Godot not found: set GODOT to its executable"; exit 1; fi
mkdir -p logs
if [[ "$1" == --* ]]; then
	log="logs/${1#--}_${2}fps.log"
	timeout 120 "$godot" --headless --path . --fixed-fps "$2" -- "$1" 2>&1 | tee "$log"
else
	log="logs/$(basename "$1" .gd)_${2}fps.log"
	timeout 120 "$godot" --headless --path . --script "res://tests/$1" --fixed-fps "$2" 2>&1 | tee "$log"
fi
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
exit $status
