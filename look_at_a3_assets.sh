#!/bin/sh
# Look at the Assignment 3 assets in Godot 4.7.2 on macOS or Linux: run `sh look_at_a3_assets.sh` from anywhere.
# It does what "Look at the A3 assets.bat" does on Windows: it imports the models, then opens the asset room
# (asset_room/asset_room.tscn), where each asset has a label with its size as Godot measures it (W x D x H, metres).
# Godot is found from the GODOT variable, then `godot` or `godot4` on the PATH, then /Applications/Godot.app.
# Anything after the script's name goes on to the scene, e.g. `sh look_at_a3_assets.sh -- --view=camper`.
cd "$(dirname "$0")" || exit 1
G="${GODOT:-}"
[ -z "$G" ] && G="$(command -v godot || command -v godot4 || true)"
[ -z "$G" ] && [ -x /Applications/Godot.app/Contents/MacOS/Godot ] && G=/Applications/Godot.app/Contents/MacOS/Godot
if [ -z "$G" ]; then
    echo "Could not find Godot 4.7.2. Set GODOT to the path of its executable, e.g. GODOT=/path/to/godot sh $0"
    exit 1
fi
echo "Importing the models..."
"$G" --headless --path . --import || { echo "The import failed. See the messages above."; exit 1; }
exec "$G" --path . res://asset_room/asset_room.tscn "$@"
