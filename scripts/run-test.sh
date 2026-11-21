#!/usr/bin/env bash
# scripts/run-test.sh <test-file.gd | --flag-test> <fps|realtime> [timeout-seconds]
# The course's Assignment 7 wrapper, merged with this repository's by Claude Code (21 Nov 2026).
# As the course's:
# - <fps> runs with --fixed-fps <fps>; `realtime` runs without it, for tests that wait on audio;
# - the third argument is the timeout in seconds, 120 by default;
# - the log is logs/<name>_<fps>fps.log, or logs/<name>_realtime.log;
# - the exit status is 1 if the log has SHADER ERROR, SCRIPT ERROR or Failed loading resource
#   (a scene, clip or sheet that won't load), and 124 if the test hung.
# Where this repository's differs:
# - the Godot project is the repository root, so --path . (the course's has --path godot);
# - Godot is found from GODOT, then `godot` on the PATH, then the two places the .bat launchers look;
# - an argument that starts with -- runs main.tscn with that flag (`-- --camp-test`) instead of a
#   tests/ script.
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
if grep -qE "SHADER ERROR|SCRIPT ERROR|Failed loading resource" "$log"; then status=1; fi
exit $status
