#!/usr/bin/env bash
# Imports the project headless and fails if any script has a parse/compile error.
set -uo pipefail
source "$(dirname "$0")/godot_env.sh"
log="$(mktemp)"
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --import >"$log" 2>&1
status=$?
if grep -E "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script|ERROR: .*\.gd" "$log" >/dev/null; then
	grep -E -A3 "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script|ERROR: .*\.gd" "$log"
	echo "godot_check: FAILED"
	exit 1
fi
echo "godot_check: OK (import exit $status)"
