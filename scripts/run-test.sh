#!/usr/bin/env bash
# scripts/run-test.sh <test-file.gd | --flag-test> <fps|realtime> [timeout-seconds]
# The course's Assignment 6 wrapper, merged with this repository's by Claude Code (7 Nov 2026).
# From the course's, new in Assignment 6:
# - `realtime` in place of a frame rate runs without --fixed-fps, for tests that wait on audio
#   (timers follow game time and fire correctly at a fixed rate, but audio plays on the clock);
#   its log is <name>_realtime.log;
# - an optional third argument sets the timeout in seconds (120 by default), for the cost script.
# Kept from this repository's Assignment 5 wrapper:
# - the Godot project is the repository root, so --path . (the course's has --path godot);
# - Godot isn't on the PATH on the author's machine, so it is found from GODOT, then `godot`,
#   then the two places the .bat launchers look;
# - the earlier checks run inside the main scene from a flag (`-- --sound-test`), so an
#   argument that starts with -- runs main.tscn with that flag instead of a tests/ script.
# The exit status is 1 if the log has SHADER ERROR or SCRIPT ERROR, and 124 if the test hung.
set -o pipefail
cd "$(dirname "$0")/.." || exit 1
godot="${GODOT:-$(command -v godot || true)}"
for g in ../Godot/Godot_v4.7.2-stable_win64_console.exe "$LOCALAPPDATA/Programs/Godot/Godot_v4.7.2-stable_win64_console.exe"; do
	if [ -z "$godot" ] && [ -f "$g" ]; then godot="$g"; fi
done
if [ -z "$godot" ]; then echo "Godot not found: set GODOT to its executable"; exit 1; fi
mkdir -p logs
if [ "$2" = "realtime" ]; then
	fps_args=(); tag="realtime"
else
	fps_args=(--fixed-fps "$2"); tag="${2}fps"
fi
if [[ "$1" == --* ]]; then
	log="logs/${1#--}_${tag}.log"
	timeout "${3:-120}" "$godot" --headless --path . "${fps_args[@]}" -- "$1" 2>&1 | tee "$log"
else
	log="logs/$(basename "$1" .gd)_${tag}.log"
	timeout "${3:-120}" "$godot" --headless --path . --script "res://tests/$1" "${fps_args[@]}" 2>&1 | tee "$log"
fi
status=$?
if grep -qE "SHADER ERROR|SCRIPT ERROR" "$log"; then status=1; fi
exit $status
