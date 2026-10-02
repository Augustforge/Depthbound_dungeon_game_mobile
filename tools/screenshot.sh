#!/usr/bin/env bash
# Renders a scene with the Compatibility renderer under Xvfb and saves one frame.
# Usage: tools/screenshot.sh res://path/scene.tscn out.png [frames=45] [extra user args...]
set -uo pipefail
source "$(dirname "$0")/godot_env.sh"
scene="${1:?scene path}"
out="${2:?output png}"
frames="${3:-45}"
shift 3 2>/dev/null || shift $#
out_abs="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"
log="$(mktemp)"
timeout 180 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT_BIN" --path "$PROJECT_ROOT" \
	--rendering-driver opengl3 --resolution 1920x1080 "$scene" -- \
	--screenshot="$out_abs" --frames="$frames" "$@" 2>&1 \
	| grep -v -E "^ALSA lib|audio_driver_alsa|All audio drivers failed|servers/audio/audio_server|set_use_vsync|gl_manager_x11|V-Sync" | awk '!seen[$0]++' | head -60 | tee "$log"
ls -la "$out_abs"
if grep -q -E "SHADER ERROR|SCRIPT ERROR|Parse Error" "$log"; then
	echo "screenshot: errors detected"
	exit 1
fi
