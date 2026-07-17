#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot}"

"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --editor --quit
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --quit-after 2
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --rendering-method gl_compatibility --quit-after 2
"$GODOT_BIN" --headless -d --path "$PROJECT_ROOT" \
  -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
