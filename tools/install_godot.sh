#!/usr/bin/env bash
# Installs the Godot editor binary used by this project (idempotent).
# Usage: tools/install_godot.sh [--templates]
#   --templates  also download export templates (~1 GB, only needed for local exports)
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
GODOT_DIR="${GODOT_DIR:-/home/user/tools}"
GODOT_BIN="$GODOT_DIR/godot"
BASE_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable"

mkdir -p "$GODOT_DIR"

if [[ -x "$GODOT_BIN" ]] && "$GODOT_BIN" --version 2>/dev/null | grep -q "^${GODOT_VERSION}\.stable"; then
	echo "Godot ${GODOT_VERSION} already installed at $GODOT_BIN"
else
	echo "Downloading Godot ${GODOT_VERSION}..."
	tmp="$(mktemp -d)"
	curl -fsSL --retry 4 --retry-delay 2 -o "$tmp/godot.zip" "$BASE_URL/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"
	unzip -q -o "$tmp/godot.zip" -d "$tmp"
	mv -f "$tmp/Godot_v${GODOT_VERSION}-stable_linux.x86_64" "$GODOT_BIN"
	chmod +x "$GODOT_BIN"
	rm -rf "$tmp"
	echo "Installed: $("$GODOT_BIN" --version)"
fi

if [[ "${1:-}" == "--templates" ]]; then
	tdir="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"
	if [[ -f "$tdir/version.txt" ]]; then
		echo "Export templates already installed at $tdir"
	else
		echo "Downloading export templates..."
		tmp="$(mktemp -d)"
		curl -fsSL --retry 4 --retry-delay 2 -o "$tmp/t.tpz" "$BASE_URL/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
		mkdir -p "$tdir"
		unzip -q -o "$tmp/t.tpz" -d "$tmp"
		mv -f "$tmp/templates/"* "$tdir/"
		rm -rf "$tmp"
		echo "Templates installed at $tdir"
	fi
fi
