#!/usr/bin/env bash
# Copy the pitch's board images into Brutalist's Remotion public folder, where GodotDesignBoard's
# `image` prop (staticFile) looks for them. Run from the repo root:  bash pitch/tools/stage.sh
# ART_HOME defaults to the toolkit checkout beside this repo.
set -euo pipefail
ART_HOME="${ART_HOME:-$(cd "$(dirname "$0")/../../../brutalist.art" && pwd)}"
DEST="$ART_HOME/runtime/remotion/public/the-noise-next-door-pitch"
mkdir -p "$DEST"
cp "$(dirname "$0")/../stage/"* "$DEST/"
ls "$DEST"
