#!/usr/bin/env bash
# Sourced by other tools: resolves the Godot binary and the project root.
GODOT_BIN="${GODOT_BIN:-/home/user/tools/godot}"
if [[ ! -x "$GODOT_BIN" ]]; then
	if command -v godot >/dev/null 2>&1; then
		GODOT_BIN="$(command -v godot)"
	else
		echo "Godot not found. Run tools/install_godot.sh first." >&2
		exit 1
	fi
fi
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GODOT_BIN PROJECT_ROOT
