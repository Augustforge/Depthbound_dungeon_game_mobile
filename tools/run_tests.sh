#!/usr/bin/env bash
# Runs all unit tests headless. Usage: tools/run_tests.sh [filter]
set -uo pipefail
source "$(dirname "$0")/godot_env.sh"
# Re-import so newly added class_name scripts are registered.
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --import >/dev/null 2>&1 || true
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" res://tests/test_runner.tscn -- --filter="${1:-}" 2>&1 | grep -v -E "^ALSA lib|audio_driver_alsa|All audio drivers failed|servers/audio/audio_server" 
exit "${PIPESTATUS[0]}"
