#!/bin/bash
# SessionStart hook for Claude Code on the web: installs Godot, the GDScript linter and imports
# the project so tools/run_tests.sh and gdlint work right away.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	exit 0
fi

cd "$CLAUDE_PROJECT_DIR"
tools/install_godot.sh
pip install -q "gdtoolkit==4.*" 2>/dev/null || pip install -q --break-system-packages "gdtoolkit==4.*"
/home/user/tools/godot --headless --path . --import >/dev/null 2>&1 || true
echo 'export GODOT_BIN=/home/user/tools/godot' >> "${CLAUDE_ENV_FILE:-/dev/null}"
