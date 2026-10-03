#!/usr/bin/env bash
# Runs all unit tests headless. Usage: tools/run_tests.sh [filter]
# Fails if any test fails OR any script error is printed (runtime errors do not stop GDScript).
set -uo pipefail
source "$(dirname "$0")/godot_env.sh"
# Re-import so newly added class_name scripts are registered.
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --import >/dev/null 2>&1 || true
log="$(mktemp)"
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" res://tests/test_runner.tscn -- --nosave --filter="${1:-}" 2>&1 \
	| grep -v -E "^ALSA lib|audio_driver_alsa|All audio drivers failed|servers/audio/audio_server" | tee "$log"
status="${PIPESTATUS[0]}"
if grep -q -E "SCRIPT ERROR|Parse Error" "$log"; then
	echo "run_tests: script errors detected -> FAIL"
	exit 1
fi
exit "$status"
